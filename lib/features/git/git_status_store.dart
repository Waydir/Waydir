import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:signals/signals.dart';

import '../../core/logging/app_logger.dart';
import '../../i18n/strings.g.dart';

enum RepoState { clean, merging, rebasing, cherryPicking, reverting, bisecting }

enum CheckoutOutcome { ok, needsStash, failed }

class CheckoutResult {
  final CheckoutOutcome outcome;
  final String? message;

  const CheckoutResult(this.outcome, this.message);
}

class StashEntry {
  /// Stash index (`stash@{index}`).
  final int index;
  final String message;
  final String branch;

  const StashEntry({
    required this.index,
    required this.message,
    required this.branch,
  });
}

class GitStatus {
  final String root;
  final String branch;
  final bool detached;
  final int staged;
  final int unstaged;
  final int untracked;

  /// Line-level diff vs HEAD (staged + unstaged tracked changes). These are
  /// the real `git diff --shortstat` numbers, so `+`/`-` mean inserted/
  /// deleted lines — not "modified files", which would mislead as red.
  final int insertions;
  final int deletions;
  final int ahead;
  final int behind;
  final int stash;
  final RepoState state;

  const GitStatus({
    required this.root,
    required this.branch,
    required this.detached,
    required this.staged,
    required this.unstaged,
    required this.untracked,
    required this.insertions,
    required this.deletions,
    required this.ahead,
    required this.behind,
    required this.stash,
    required this.state,
  });

  bool get hasChanges => staged > 0 || unstaged > 0 || untracked > 0;
}

class GitStatusStore {
  final status = signal<GitStatus?>(null);

  Timer? _debounce;
  int _token = 0;
  bool _loading = false;
  bool _pending = false;
  String? _lastPath;

  void watchPath(String path) {
    _debounce?.cancel();
    if (path.isEmpty) {
      _lastPath = null;
      status.value = null;

      return;
    }
    _lastPath = path;
    // Coarser than the directory watcher's own debounce: in a file manager a
    // single user action (extract, paste, build) fans out into many fs
    // events; coalesce them so we don't spawn a git burst per event.
    _debounce = Timer(const Duration(milliseconds: 500), () {
      refresh(path);
    });
  }

  /// Refreshes the most recently watched path (e.g. on window focus regain),
  /// without needing the caller to know it.
  Future<void> refreshCurrent() {
    final path = _lastPath ?? status.value?.root;
    if (path == null) return Future.value();

    return refresh(path);
  }

  Future<void> refresh(String path) async {
    _lastPath = path;
    if (_loading) {
      // Collapse overlapping refreshes into a single trailing run so rapid
      // navigation can't stack concurrent multi-process git loads.
      _pending = true;

      return;
    }
    _loading = true;
    try {
      final token = ++_token;
      final next = await _load(path);
      if (token == _token) status.value = next;
    } finally {
      _loading = false;
      if (_pending) {
        _pending = false;
        unawaited(refresh(_lastPath ?? path));
      }
    }
  }

  /// Local branch names, current branch first.
  Future<List<String>> branches() async {
    final root = status.value?.root;
    if (root == null) return const [];
    final result = await _git(root, [
      'for-each-ref',
      '--format=%(refname:short)',
      '--sort=-committerdate',
      'refs/heads',
    ]);
    if (result == null || result.exitCode != 0) return const [];
    final names = result.stdout
        .toString()
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final current = status.value?.branch;
    if (current != null && names.remove(current)) names.insert(0, current);

    return names;
  }

  /// Checks out [branch].
  Future<CheckoutResult> checkout(String branch) async {
    final root = status.value?.root;
    if (root == null) {
      return CheckoutResult(CheckoutOutcome.failed, t.git.noRepository);
    }
    final result = await _git(root, ['checkout', branch]);
    if (result == null) {
      return CheckoutResult(CheckoutOutcome.failed, t.git.gitCheckoutFailed);
    }
    if (result.exitCode != 0) {
      final err = result.stderr.toString().trim();
      if (err.contains('overwritten by checkout') ||
          err.contains('commit your changes or stash them') ||
          err.contains('Please commit your changes or stash')) {
        return const CheckoutResult(CheckoutOutcome.needsStash, null);
      }

      return CheckoutResult(
        CheckoutOutcome.failed,
        err.isEmpty ? t.git.gitCheckoutFailed : err,
      );
    }
    await refresh(root);

    return const CheckoutResult(CheckoutOutcome.ok, null);
  }

  /// Stashes all changes (including untracked), then checks out [branch].
  /// The stash is left in place so it can be restored on the original branch.
  /// Returns an error message on failure, null on success.
  Future<String?> stashAndCheckout(String branch) async {
    final root = status.value?.root;
    if (root == null) return t.git.noRepository;
    final stashResult = await _git(root, [
      'stash',
      'push',
      '--include-untracked',
      '-m',
      'waydir: auto-stash before switching to $branch',
    ]);
    if (stashResult == null || stashResult.exitCode != 0) {
      final err = stashResult?.stderr.toString().trim();

      return (err == null || err.isEmpty) ? t.git.gitStashFailed : err;
    }
    final result = await checkout(branch);
    if (result.outcome == CheckoutOutcome.ok) return null;
    // Changes are safely stashed but we did not switch — make that explicit
    // so the user knows where their work went.
    final why = result.message ?? t.git.gitCheckoutFailed;

    return t.git.changesStashedSwitchFailed(message: why);
  }

  Future<GitStatus?> _load(String path) async {
    // Cheap filesystem gate: most directories a file manager visits are not
    // repos, so avoid spawning git at all unless a `.git` is found upward.
    if (!_hasGitUpward(path)) return null;

    final rootResult = await _git(path, ['rev-parse', '--show-toplevel']);
    if (rootResult == null || rootResult.exitCode != 0) return null;
    final root = rootResult.stdout.toString().trim();
    if (root.isEmpty) return null;

    final statusResult = await _git(root, [
      'status',
      '--porcelain=v1',
      '--branch',
    ]);
    if (statusResult == null || statusResult.exitCode != 0) return null;

    var staged = 0;
    var unstaged = 0;
    var untracked = 0;
    var ahead = 0;
    var behind = 0;
    var branch = 'detached';
    var detached = true;

    final lines = statusResult.stdout.toString().split('\n');
    for (final line in lines) {
      if (line.isEmpty) continue;
      if (line.startsWith('## ')) {
        // Branch comes from the porcelain header — saves a separate
        // `rev-parse` spawn per refresh.
        final (b, d) = _parseBranchHeader(line);
        branch = b;
        detached = d;
        final counts = _parseAheadBehind(line);
        ahead = counts.$1;
        behind = counts.$2;
        continue;
      }
      if (line.startsWith('??')) {
        untracked++;
        continue;
      }
      if (line.length < 2) continue;
      if (line.codeUnitAt(0) != 32) staged++;
      if (line.codeUnitAt(1) != 32) unstaged++;
    }

    final (insertions, deletions) = await _diffStat(root);
    final stash = await _stashCount(root);
    final state = await _repoState(root);

    return GitStatus(
      root: root,
      branch: branch,
      detached: detached,
      staged: staged,
      unstaged: unstaged,
      untracked: untracked,
      insertions: insertions,
      deletions: deletions,
      ahead: ahead,
      behind: behind,
      stash: stash,
      state: state,
    );
  }

  /// Real inserted/deleted line counts vs HEAD (covers staged + unstaged
  /// tracked changes). Untracked files have no diff vs HEAD by design.
  Future<(int, int)> _diffStat(String root) async {
    final result = await _git(root, ['diff', '--shortstat', 'HEAD']);
    if (result == null || result.exitCode != 0) return (0, 0);
    final text = result.stdout.toString();
    final ins = RegExp(r'(\d+) insertion').firstMatch(text);
    final del = RegExp(r'(\d+) deletion').firstMatch(text);

    return (
      ins == null ? 0 : int.tryParse(ins.group(1)!) ?? 0,
      del == null ? 0 : int.tryParse(del.group(1)!) ?? 0,
    );
  }

  bool _hasGitUpward(String path) {
    if (path.isEmpty) return false;
    if (!p.isAbsolute(path)) return false;
    var dir = Directory(path);
    for (var i = 0; i < 64; i++) {
      final marker = '${dir.path}${Platform.pathSeparator}.git';
      if (FileSystemEntity.typeSync(marker) != FileSystemEntityType.notFound) {
        return true;
      }
      final parent = dir.parent;
      if (parent.path == dir.path) return false;
      dir = parent;
    }

    return false;
  }

  /// Parses a porcelain `## ` header into `(branchName, isDetached)`.
  (String, bool) _parseBranchHeader(String line) {
    final body = line.substring(3).trim();
    if (body.startsWith('HEAD (no branch)')) return ('detached', true);
    if (body.startsWith('No commits yet on ')) {
      return (body.substring('No commits yet on '.length).trim(), false);
    }
    // "main...origin/main [ahead 1]" -> "main"
    final name = body.split('...').first.split(' ').first.trim();

    return name.isEmpty ? ('detached', true) : (name, false);
  }

  /// All stash entries, newest first (index 0 is the latest).
  Future<List<StashEntry>> stashes() async {
    final root = status.value?.root;
    if (root == null) return const [];
    final result = await _git(root, ['stash', 'list', '--format=%gd%x1f%gs']);
    if (result == null || result.exitCode != 0) return const [];
    final entries = <StashEntry>[];
    for (final line in result.stdout.toString().split('\n')) {
      if (line.isEmpty) continue;
      final parts = line.split('\x1f');
      if (parts.length < 2) continue;
      final idxMatch = RegExp(r'stash@\{(\d+)\}').firstMatch(parts.first);
      if (idxMatch == null) continue;
      final index = int.tryParse(idxMatch.group(1)!) ?? 0;
      // %gs looks like "WIP on main: 1a2b3c msg" or "On main: msg".
      final raw = parts[1].trim();
      final branchMatch = RegExp(r'^(?:WIP on|On) ([^:]+):').firstMatch(raw);
      entries.add(
        StashEntry(
          index: index,
          message: raw,
          branch: branchMatch?.group(1)?.trim() ?? '',
        ),
      );
    }

    return entries;
  }

  /// Pops `stash@{index}` (apply + drop). Error message on failure, else null.
  Future<String?> popStash(int index) => _stashOp(['pop', 'stash@{$index}']);

  /// Applies `stash@{index}` without dropping it.
  Future<String?> applyStash(int index) =>
      _stashOp(['apply', 'stash@{$index}']);

  /// Drops `stash@{index}` without applying it.
  Future<String?> dropStash(int index) => _stashOp(['drop', 'stash@{$index}']);

  Future<String?> _stashOp(List<String> args) async {
    final root = status.value?.root;
    if (root == null) return t.git.noRepository;
    final result = await _git(root, ['stash', ...args]);
    if (result == null) return t.git.gitStashFailed;
    if (result.exitCode != 0) {
      final err = result.stderr.toString().trim();

      return err.isEmpty ? t.git.gitStashFailed : err;
    }
    await refresh(root);

    return null;
  }

  Future<int> _stashCount(String root) async {
    final result = await _git(root, [
      'rev-list',
      '--walk-reflogs',
      '--count',
      'refs/stash',
    ]);
    if (result == null || result.exitCode != 0) return 0;

    return int.tryParse(result.stdout.toString().trim()) ?? 0;
  }

  Future<RepoState> _repoState(String root) async {
    final gitDirResult = await _git(root, ['rev-parse', '--git-dir']);
    if (gitDirResult == null || gitDirResult.exitCode != 0) {
      return RepoState.clean;
    }
    var gitDir = gitDirResult.stdout.toString().trim();
    if (gitDir.isEmpty) return RepoState.clean;
    if (!_isAbsolute(gitDir)) {
      gitDir = '$root${Platform.pathSeparator}$gitDir';
    }
    bool exists(String name) =>
        FileSystemEntity.typeSync('$gitDir${Platform.pathSeparator}$name') !=
        FileSystemEntityType.notFound;

    if (exists('rebase-merge') || exists('rebase-apply')) {
      return RepoState.rebasing;
    }
    if (exists('MERGE_HEAD')) return RepoState.merging;
    if (exists('CHERRY_PICK_HEAD')) return RepoState.cherryPicking;
    if (exists('REVERT_HEAD')) return RepoState.reverting;
    if (exists('BISECT_LOG')) return RepoState.bisecting;

    return RepoState.clean;
  }

  bool _isAbsolute(String path) =>
      path.startsWith('/') || RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path);

  (int, int) _parseAheadBehind(String line) {
    var ahead = 0;
    var behind = 0;
    final aheadMatch = RegExp(r'ahead (\d+)').firstMatch(line);
    final behindMatch = RegExp(r'behind (\d+)').firstMatch(line);
    if (aheadMatch != null) ahead = int.tryParse(aheadMatch.group(1)!) ?? 0;
    if (behindMatch != null) behind = int.tryParse(behindMatch.group(1)!) ?? 0;

    return (ahead, behind);
  }

  Future<ProcessResult?> _git(
    String workingDirectory,
    List<String> args,
  ) async {
    Process? proc;
    try {
      proc = await Process.start('git', ['-C', workingDirectory, ...args]);
      final p = proc;
      final stdoutF = p.stdout.transform(systemEncoding.decoder).join();
      final stderrF = p.stderr.transform(systemEncoding.decoder).join();
      var timedOut = false;
      final exitCode = await p.exitCode.timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          timedOut = true;
          // Unlike Future.timeout alone, this actually reaps the child so
          // slow `git status` calls can't pile up orphaned processes.
          p.kill(ProcessSignal.sigkill);

          return -1;
        },
      );
      if (timedOut) {
        unawaited(
          stdoutF.catchError((e, st) {
            log.warn(
              'git',
              'failed to drain timed-out git stdout',
              error: e,
              stack: st,
            );

            return '';
          }),
        );
        unawaited(
          stderrF.catchError((e, st) {
            log.warn(
              'git',
              'failed to drain timed-out git stderr',
              error: e,
              stack: st,
            );

            return '';
          }),
        );

        return null;
      }

      return ProcessResult(p.pid, exitCode, await stdoutF, await stderrF);
    } on Object {
      proc?.kill(ProcessSignal.sigkill);

      return null;
    }
  }

  void dispose() {
    _debounce?.cancel();
  }
}
