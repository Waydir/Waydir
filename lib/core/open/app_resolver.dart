import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path/path.dart' as p;

import '../../i18n/strings.g.dart';
import '../logging/app_logger.dart';
import '../platform/win32_attributes.dart';
import 'app_entry.dart';
import 'desktop_entry.dart';
import 'icon_resolver.dart';
import 'mime_resolver.dart';

/// Thrown by [AppResolver.setDefault] when the platform cannot set a default
/// programmatically (e.g. macOS without `duti`, or Windows' protected
/// UserChoice). UI surfaces this as a disabled/explained control.
class SetDefaultUnsupported implements Exception {
  final String reason;
  const SetDefaultUnsupported(this.reason);
  @override
  String toString() => reason;
}

/// Platform abstraction for discovering and launching applications that can
/// open a given file type.
abstract class AppResolver {
  /// Applications associated with [mime]/[path], default first.
  Future<List<AppEntry>> appsFor(MimeType mime, String path);

  /// All launchable applications on the system, for the "choose another
  /// application" case. May be empty when enumeration is unsupported.
  Future<List<AppEntry>> allApps();

  Future<AppEntry?> defaultFor(MimeType mime, String path);

  /// Launches [app] with [paths]. Detached; never blocks the UI.
  Future<void> launch(AppEntry app, List<String> paths);

  /// Makes [app] the default handler for [mime]. Throws
  /// [SetDefaultUnsupported] when not possible on this platform.
  Future<void> setDefault(AppEntry app, MimeType mime);

  /// True when [setDefault] can work on this platform/environment.
  Future<bool> canSetDefault();

  factory AppResolver.platform() {
    if (Platform.isLinux) return LinuxAppResolver();
    if (Platform.isMacOS) return MacAppResolver();
    if (Platform.isWindows) return WindowsAppResolver();
    return _NullAppResolver();
  }
}

class _NullAppResolver implements AppResolver {
  @override
  Future<List<AppEntry>> appsFor(MimeType mime, String path) async => [];
  @override
  Future<List<AppEntry>> allApps() async => [];
  @override
  Future<AppEntry?> defaultFor(MimeType mime, String path) async => null;
  @override
  Future<void> launch(AppEntry app, List<String> paths) async {}
  @override
  Future<void> setDefault(AppEntry app, MimeType mime) async =>
      throw SetDefaultUnsupported(t.openWith.unsupportedPlatform);
  @override
  Future<bool> canSetDefault() async => false;
}

// ───────────────────────────── Linux ──────────────────────────────

class LinuxAppResolver implements AppResolver {
  List<_LinuxApp>? _cache;

  List<String> get _appDirs {
    final dirs = <String>[];
    final dataHome = Platform.environment['XDG_DATA_HOME'];
    dirs.add(
      (dataHome != null && dataHome.isNotEmpty)
          ? dataHome
          : p.join(Platform.environment['HOME'] ?? '', '.local', 'share'),
    );
    final dataDirs = Platform.environment['XDG_DATA_DIRS'];
    dirs.addAll(
      (dataDirs != null && dataDirs.isNotEmpty)
          ? dataDirs.split(':')
          : ['/usr/local/share', '/usr/share'],
    );
    return dirs.map((d) => p.join(d, 'applications')).toList();
  }

  Future<List<_LinuxApp>> _scan() async {
    if (_cache != null) return _cache!;
    final apps = <String, _LinuxApp>{};
    for (final dir in _appDirs) {
      final d = Directory(dir);
      if (!d.existsSync()) continue;
      await for (final f in d.list(recursive: true, followLinks: false)) {
        if (f is! File || !f.path.endsWith('.desktop')) continue;
        final id = p
            .relative(f.path, from: dir)
            .replaceAll(Platform.pathSeparator, '-');
        if (apps.containsKey(id)) continue; // earlier dirs win
        try {
          final entry = DesktopEntry.parse(await f.readAsString());
          if (entry == null || !entry.isLaunchable) continue;
          apps[id] = _LinuxApp(id, entry);
        } catch (e, st) {
          log.warn(
            'open',
            'failed to parse desktop entry ${f.path}',
            error: e,
            stack: st,
          );
        }
      }
    }
    return _cache = apps.values.toList();
  }

  AppEntry _toEntry(_LinuxApp a, {bool isDefault = false}) => AppEntry(
    id: a.id,
    name: a.entry.name.isEmpty ? a.id : a.entry.name,
    exec: a.entry.exec,
    iconPath: IconResolver.instance.resolve(a.entry.icon),
    isDefault: isDefault,
  );

  @override
  Future<List<AppEntry>> appsFor(MimeType mime, String path) async {
    final all = await _scan();
    final def = await defaultFor(mime, path);
    final matches = all
        .where((a) => a.entry.mimeTypes.contains(mime.value))
        .map((a) => _toEntry(a, isDefault: a.id == def?.id))
        .toList();
    matches.sort((x, y) {
      if (x.isDefault != y.isDefault) return x.isDefault ? -1 : 1;
      return x.name.toLowerCase().compareTo(y.name.toLowerCase());
    });
    return matches;
  }

  @override
  Future<List<AppEntry>> allApps() async {
    final all = await _scan();
    final list = all
        .where((a) => !a.entry.noDisplay)
        .map((a) => _toEntry(a))
        .toList();
    list.sort((x, y) => x.name.toLowerCase().compareTo(y.name.toLowerCase()));
    return list;
  }

  @override
  Future<AppEntry?> defaultFor(MimeType mime, String path) async {
    try {
      final r = await Process.run('xdg-mime', ['query', 'default', mime.value]);
      final id = (r.stdout as String).trim();
      if (id.isEmpty) return null;
      final all = await _scan();
      for (final a in all) {
        if (a.id == id) return _toEntry(a, isDefault: true);
      }
    } catch (e, st) {
      log.warn('open', 'xdg default app lookup failed', error: e, stack: st);
    }
    return null;
  }

  @override
  Future<void> launch(AppEntry app, List<String> paths) async {
    final args = DesktopEntry.expandExec(app.exec, paths);
    if (args.isEmpty) return;
    await Process.start(
      args.first,
      args.sublist(1),
      mode: ProcessStartMode.detached,
    );
  }

  @override
  Future<bool> canSetDefault() async => true;

  @override
  Future<void> setDefault(AppEntry app, MimeType mime) async {
    final r = await Process.run('xdg-mime', ['default', app.id, mime.value]);
    if (r.exitCode != 0) {
      throw SetDefaultUnsupported(
        (r.stderr as String).trim().isEmpty
            ? t.openWith.xdgMimeFailed
            : (r.stderr as String).trim(),
      );
    }
  }
}

class _LinuxApp {
  final String id;
  final DesktopEntry entry;
  _LinuxApp(this.id, this.entry);
}

// ───────────────────────────── macOS ──────────────────────────────

class MacAppResolver implements AppResolver {
  List<AppEntry>? _allCache;

  @override
  Future<List<AppEntry>> appsFor(MimeType mime, String path) async {
    // Launch Services has no clean CLI to enumerate handlers; offer every
    // installed app with the default (if discoverable) first, mirroring
    // Finder's "Open With ▸ Other…".
    final def = await defaultFor(mime, path);
    final all = await allApps();
    if (def == null) return all;
    return [def, ...all.where((a) => a.id != def.id)];
  }

  @override
  Future<List<AppEntry>> allApps() async {
    if (_allCache != null) return _allCache!;
    final apps = <String, AppEntry>{};
    for (final dir in [
      '/Applications',
      '/System/Applications',
      p.join(Platform.environment['HOME'] ?? '', 'Applications'),
    ]) {
      final d = Directory(dir);
      if (!d.existsSync()) continue;
      for (final e in d.listSync(followLinks: false)) {
        if (e.path.endsWith('.app')) {
          final name = p.basenameWithoutExtension(e.path);
          apps[e.path] = AppEntry(id: e.path, name: name, exec: e.path);
        }
      }
    }
    final list = apps.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return _allCache = list;
  }

  @override
  Future<AppEntry?> defaultFor(MimeType mime, String path) async {
    // `duti -x` reports the default handler for a UTI when available.
    if (!await _hasDuti() || !mime.isUti) return null;
    try {
      final r = await Process.run('duti', ['-x', mime.value]);
      if (r.exitCode == 0) {
        final lines = (r.stdout as String)
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();
        // Last line is typically the bundle path.
        final bundle = lines.lastWhere(
          (l) => l.endsWith('.app'),
          orElse: () => '',
        );
        if (bundle.isNotEmpty) {
          return AppEntry(
            id: bundle,
            name: p.basenameWithoutExtension(bundle),
            exec: bundle,
            isDefault: true,
          );
        }
      }
    } catch (e, st) {
      log.warn('open', 'mac default app lookup failed', error: e, stack: st);
    }
    return null;
  }

  @override
  Future<void> launch(AppEntry app, List<String> paths) async {
    await Process.start('open', [
      '-a',
      app.exec,
      ...paths,
    ], mode: ProcessStartMode.detached);
  }

  Future<bool> _hasDuti() async {
    try {
      final r = await Process.run('which', ['duti']);
      return r.exitCode == 0;
    } catch (e, st) {
      log.warn('open', 'duti availability check failed', error: e, stack: st);
      return false;
    }
  }

  @override
  Future<bool> canSetDefault() => _hasDuti();

  @override
  Future<void> setDefault(AppEntry app, MimeType mime) async {
    if (!await _hasDuti()) {
      throw SetDefaultUnsupported(t.openWith.dutiRequired);
    }
    final bundleId = await _bundleId(app.exec);
    if (bundleId == null) {
      throw SetDefaultUnsupported(t.openWith.bundleIdReadFailed);
    }
    final r = await Process.run('duti', ['-s', bundleId, mime.value, 'all']);
    if (r.exitCode != 0) {
      throw SetDefaultUnsupported((r.stderr as String).trim());
    }
  }

  Future<String?> _bundleId(String appPath) async {
    try {
      final r = await Process.run('mdls', [
        '-name',
        'kMDItemCFBundleIdentifier',
        '-raw',
        appPath,
      ]);
      final out = (r.stdout as String).trim();
      return (out.isEmpty || out == '(null)') ? null : out;
    } catch (e, st) {
      log.warn('open', 'bundle id lookup failed', error: e, stack: st);
      return null;
    }
  }
}

// ──────────────────────────── Windows ─────────────────────────────

class WindowsAppResolver implements AppResolver {
  String _ext(String path) {
    final e = p.extension(path);
    return e.isEmpty ? '' : e;
  }

  @override
  Future<List<AppEntry>> appsFor(MimeType mime, String path) async {
    final ext = _ext(path);
    final apps = <String, AppEntry>{};
    final def = await defaultFor(mime, path);
    if (def != null) apps[def.id] = def;
    if (ext.isNotEmpty) {
      for (final prog in await _openWithProgids(ext)) {
        final entry = _entryForAssoc(prog, isDefault: false);
        if (entry != null) apps.putIfAbsent(entry.id, () => entry);
      }
    }
    final list = apps.values.toList();
    list.sort((a, b) {
      if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  List<AppEntry>? _allCache;

  @override
  Future<List<AppEntry>> allApps() async {
    if (_allCache != null) return _allCache!;
    final apps = <String, AppEntry>{};
    final programData = Platform.environment['ProgramData'] ?? '';
    final appData = Platform.environment['APPDATA'] ?? '';
    final dirs = [
      if (programData.isNotEmpty)
        p.join(programData, r'Microsoft\Windows\Start Menu\Programs'),
      if (appData.isNotEmpty)
        p.join(appData, r'Microsoft\Windows\Start Menu\Programs'),
    ].where((d) => Directory(d).existsSync()).toList();
    if (dirs.isEmpty) return _allCache = const [];

    final dirList = dirs.map((d) => "'${d.replaceAll("'", "''")}'").join(',');
    final script =
        r'$sh=New-Object -ComObject WScript.Shell;'
        'Get-ChildItem -Path $dirList -Recurse -Filter *.lnk '
        r'-ErrorAction SilentlyContinue | ForEach-Object {'
        r'$t=$sh.CreateShortcut($_.FullName).TargetPath;'
        r'if($t -and $t.ToLower().EndsWith(".exe")){'
        r'"$($_.BaseName)|$t"}}';
    try {
      final r = await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        script,
      ]).timeout(const Duration(seconds: 10));
      if (r.exitCode == 0) {
        for (final line in (r.stdout as String).split('\n')) {
          final parts = line.trim().split('|');
          if (parts.length != 2) continue;
          final name = parts[0].trim();
          final exe = parts[1].trim();
          if (name.isEmpty || exe.isEmpty || !File(exe).existsSync()) continue;
          apps.putIfAbsent(exe, () => AppEntry(id: exe, name: name, exec: exe));
        }
      }
    } catch (e, st) {
      log.warn('open', 'windows app enumeration failed', error: e, stack: st);
    }
    final list = apps.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return _allCache = list;
  }

  @override
  Future<AppEntry?> defaultFor(MimeType mime, String path) async {
    final ext = _ext(path);
    if (ext.isEmpty) return null;
    return _entryForAssoc(ext, isDefault: true);
  }

  /// Builds an [AppEntry] from a Windows association ([assoc] is either a file
  /// extension like `.png` or a ProgId). Resolves a real executable and a
  /// friendly name via the shell, so UWP/garbage ProgIds don't leak into the
  /// UI. Returns null when nothing usable is associated.
  AppEntry? _entryForAssoc(String assoc, {required bool isDefault}) {
    String? exe;
    String? friendly;
    String? command;
    try {
      exe = assocQueryStringOnWindows(assocStrExecutable, assoc);
      friendly = assocQueryStringOnWindows(assocStrFriendlyAppName, assoc);
      command = assocQueryStringOnWindows(assocStrCommand, assoc);
    } catch (e, st) {
      log.warn(
        'open',
        'windows association lookup failed',
        error: e,
        stack: st,
      );
      return null;
    }
    if ((exe == null || exe.isEmpty) && (command == null || command.isEmpty)) {
      return null;
    }
    // Prefer a real exe; the command template is the UWP/registry fallback.
    final launchTarget = (exe != null && exe.isNotEmpty) ? exe : command!;
    final name = (friendly != null && friendly.isNotEmpty)
        ? friendly
        : (exe != null && exe.isNotEmpty)
        ? p.basenameWithoutExtension(exe)
        : assoc;
    return AppEntry(
      id: launchTarget,
      name: name,
      exec: launchTarget,
      isDefault: isDefault,
    );
  }

  @override
  Future<void> launch(AppEntry app, List<String> paths) async {
    if (paths.isEmpty) return;
    final target = app.exec;
    // Preferred path: hand the app + file to the shell, which resolves app
    // paths and launches classic Win32 apps reliably.
    if (File(target).existsSync()) {
      for (final path in paths) {
        if (shellOpenWithAppOnWindows(target, path)) continue;
        await _runCommandTemplate(target, [path]);
      }
      return;
    }
    // [target] is a command template such as `"C:\..\app.exe" "%1"`.
    await _runCommandTemplate(target, paths);
  }

  Future<void> _runCommandTemplate(String template, List<String> paths) async {
    final argv = _expandCommand(template, paths);
    if (argv.isEmpty) return;
    try {
      await Process.start(
        argv.first,
        argv.sublist(1),
        mode: ProcessStartMode.detached,
      );
    } catch (e, st) {
      log.warn(
        'open',
        'windows command template launch failed',
        error: e,
        stack: st,
      );
      shellOpenOnWindows(paths.first);
    }
  }

  /// Expands a Windows `shell\open\command` template: substitutes `%1`/`%L`/
  /// `%*`/`%V` with the file path(s), honouring double-quote tokenisation.
  static List<String> _expandCommand(String template, List<String> paths) {
    final tokens = <String>[];
    final buf = StringBuffer();
    var inQuotes = false;
    var has = false;
    for (var i = 0; i < template.length; i++) {
      final c = template[i];
      if (c == '"') {
        inQuotes = !inQuotes;
        has = true;
        continue;
      }
      if (c == ' ' && !inQuotes) {
        if (has) {
          tokens.add(buf.toString());
          buf.clear();
          has = false;
        }
        continue;
      }
      buf.write(c);
      has = true;
    }
    if (has) tokens.add(buf.toString());

    final out = <String>[];
    var substituted = false;
    for (final tok in tokens) {
      if (RegExp(r'^%[1lLvV*]$').hasMatch(tok)) {
        out.addAll(paths);
        substituted = true;
      } else {
        out.add(tok);
      }
    }
    if (!substituted) out.addAll(paths);
    return out;
  }

  @visibleForTesting
  static List<String> debugExpandCommand(String template, List<String> paths) =>
      _expandCommand(template, paths);

  Future<List<String>> _openWithProgids(String ext) async {
    try {
      final r = await Process.run('reg', [
        'query',
        'HKCR\\$ext\\OpenWithProgids',
      ]).timeout(const Duration(seconds: 5));
      if (r.exitCode != 0) return const [];
      return (r.stdout as String)
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty && !l.startsWith('HKEY'))
          .map((l) => l.split(RegExp(r'\s+')).first)
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (e, st) {
      log.warn(
        'open',
        'windows OpenWithProgids lookup failed',
        error: e,
        stack: st,
      );
      return const [];
    }
  }

  @override
  Future<bool> canSetDefault() async => false;

  @override
  Future<void> setDefault(AppEntry app, MimeType mime) async {
    // Windows protects the per-user default (UserChoice hash); programmatic
    // changes are blocked by design. The system dialog is the supported path.
    throw SetDefaultUnsupported(t.openWith.windowsDefaultDialogRequired);
  }
}
