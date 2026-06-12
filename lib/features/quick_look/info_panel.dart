import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';

import '../../core/fs/sftp_session_manager.dart';
import '../../core/fs/waydir_core_loader.dart';
import '../../core/models/file_entry.dart';
import '../../core/platform/platform_paths.dart';
import '../../core/settings/settings_store.dart';
import '../../i18n/strings.g.dart';
import '../../utils/format.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import '../files/file_icons.dart';
import 'quick_look_common.dart';
import 'quick_look_io.dart';

String _formatStatDate(DateTime d) {
  final s = SettingsStore.instance;
  return formatEntryDate(
    d,
    s.dateFormat.value,
    recentDatesRelative: s.recentDatesRelative.value,
  );
}

class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text.toUpperCase(), style: context.txt.sectionLabel),
    );
  }
}

class PropRow extends StatelessWidget {
  final String label;
  final String value;

  const PropRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: context.txt.captionSmall.copyWith(
                color: AppColors.fgMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SelectableText(
              value,
              style: context.txt.captionSmall.copyWith(color: AppColors.fg),
            ),
          ),
        ],
      ),
    );
  }
}

class _SizeRows extends StatelessWidget {
  final FileEntry entry;

  const _SizeRows({required this.entry});

  @override
  Widget build(BuildContext context) {
    if (entry.type != FileItemType.folder) {
      return PropRow(label: t.quickLook.size, value: formatBytes(entry.size));
    }
    return _FolderSizeRows(path: entry.realPath);
  }
}

class _FolderSizeRows extends StatefulWidget {
  final String path;

  const _FolderSizeRows({required this.path});

  @override
  State<_FolderSizeRows> createState() => _FolderSizeRowsState();
}

class _FolderSizeRowsState extends State<_FolderSizeRows> {
  Timer? _timer;
  int? _session;
  _SftpFolderScan? _sftpScan;
  FolderStats? _stats;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(_FolderSizeRows oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _stop(cancel: true);
      setState(() {
        _stats = null;
      });
      _start();
    }
  }

  @override
  void dispose() {
    _stop(cancel: true);
    super.dispose();
  }

  void _start() {
    _cancelled = false;
    if (PlatformPaths.isSftpUri(widget.path)) {
      _startSftpFolderScan();
      return;
    }
    try {
      _session = WaydirCoreLoader.folderScanStart(widget.path);
    } catch (_) {
      _session = null;
    }
    if (_session == null) return;
    _poll();
    _timer = Timer.periodic(const Duration(milliseconds: 120), (_) => _poll());
  }

  void _startSftpFolderScan() {
    unawaited(
      _SftpFolderScan.start(
        logicalPath: widget.path,
        onProgress: (stats) {
          if (!mounted || _cancelled) return;
          setState(() {
            _stats = stats;
          });
        },
      ).then((scan) {
        if (!mounted || _cancelled) {
          scan?.cancel();
          return;
        }
        if (scan == null) {
          setState(() {
            _stats = const FolderStats(0, 0, done: true);
          });
          return;
        }
        _sftpScan = scan;
      }),
    );
  }

  void _poll() {
    final session = _session;
    if (session == null) return;
    try {
      final r = WaydirCoreLoader.folderScanPoll(session);
      if (!mounted) return;
      setState(() {
        _stats = FolderStats(r.bytes, r.items, done: r.done);
      });
      if (r.done) _stop(cancel: false);
    } catch (_) {
      _stop(cancel: true);
    }
  }

  void _stop({required bool cancel}) {
    _cancelled = true;
    _timer?.cancel();
    _timer = null;
    _sftpScan?.cancel();
    _sftpScan = null;
    final session = _session;
    if (session == null) return;
    _session = null;
    try {
      if (cancel) WaydirCoreLoader.folderScanCancel(session);
      WaydirCoreLoader.folderScanFree(session);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final calc = t.quickLook.calculating;
    final stats = _stats;
    final size = stats == null
        ? calc
        : stats.done
        ? formatBytes(stats.bytes)
        : '${formatBytes(stats.bytes)} · $calc';
    final contains = stats == null
        ? calc
        : stats.done
        ? t.quickLook.items(count: stats.items)
        : '${t.quickLook.items(count: stats.items)} · $calc';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PropRow(label: t.quickLook.size, value: size),
        PropRow(label: t.quickLook.contains, value: contains),
      ],
    );
  }
}

class _SftpFolderScan {
  final Isolate _isolate;
  final ReceivePort _port;
  StreamSubscription<dynamic>? _subscription;
  bool _closed = false;

  _SftpFolderScan._(this._isolate, this._port);

  static Future<_SftpFolderScan?> start({
    required String logicalPath,
    required void Function(FolderStats stats) onProgress,
  }) async {
    final record = SftpSessionManager.recordFor(logicalPath);
    if (record == null) return null;
    final port = ReceivePort();
    final request = _SftpFolderScanRequest(
      port.sendPort,
      record.sessionId,
      SftpSessionManager.remotePath(logicalPath),
    );
    final Isolate isolate;
    try {
      isolate = await Isolate.spawn(
        _runSftpFolderScan,
        request,
        debugName: 'sftp-folder-scan',
      );
    } catch (_) {
      port.close();
      return null;
    }
    final scan = _SftpFolderScan._(isolate, port);
    scan._subscription = port.listen((message) {
      if (scan._closed || message is! _SftpFolderScanProgress) return;
      onProgress(FolderStats(message.bytes, message.items, done: message.done));
      if (message.done) {
        scan._close(kill: false);
      }
    });
    return scan;
  }

  void cancel() {
    _close(kill: true);
  }

  void _close({required bool kill}) {
    if (_closed) return;
    _closed = true;
    _subscription?.cancel();
    _subscription = null;
    _port.close();
    if (kill) {
      _isolate.kill(priority: Isolate.immediate);
    }
  }
}

class _SftpFolderScanRequest {
  final SendPort port;
  final int sessionId;
  final String remotePath;

  const _SftpFolderScanRequest(this.port, this.sessionId, this.remotePath);
}

class _SftpFolderScanProgress {
  final int bytes;
  final int items;
  final bool done;

  const _SftpFolderScanProgress(this.bytes, this.items, this.done);
}

void _runSftpFolderScan(_SftpFolderScanRequest request) {
  var bytes = 0;
  var items = 0;
  var pending = 0;
  var lastSend = DateTime.now().millisecondsSinceEpoch;

  void send(bool done) {
    request.port.send(_SftpFolderScanProgress(bytes, items, done));
    pending = 0;
    lastSend = DateTime.now().millisecondsSinceEpoch;
  }

  void maybeSend() {
    pending++;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (pending >= 64 || now - lastSend >= 150) {
      send(false);
    }
  }

  void walk(String remotePath) {
    final buf = WaydirCoreLoader.sftpList(request.sessionId, remotePath);
    if (buf == null) return;
    final entries = FileEntryCodec.decode(buf);
    for (final entry in entries) {
      items++;
      if (entry.type == FileItemType.folder) {
        walk(entry.path);
      } else {
        bytes += entry.size;
      }
      maybeSend();
    }
  }

  try {
    walk(request.remotePath);
  } catch (_) {}
  send(true);
}

class _StatRows extends StatelessWidget {
  final FileEntry entry;

  const _StatRows({required this.entry});

  @override
  Widget build(BuildContext context) {
    if (PlatformPaths.isRemoteUri(entry.realPath)) {
      return const SizedBox.shrink();
    }
    return AsyncRetain<FileStat?>(
      cacheKey: 'stat:${entry.realPath}|${entry.modifiedMs}',
      loader: () => FileStat.stat(entry.realPath),
      builder: (stat) {
        if (stat == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PropRow(
              label: t.quickLook.accessed,
              value: _formatStatDate(stat.accessed),
            ),
            PropRow(
              label: t.quickLook.changed,
              value: _formatStatDate(stat.changed),
            ),
            if (!PlatformPaths.isWindows)
              PropRow(label: t.quickLook.permissions, value: stat.modeString()),
          ],
        );
      },
    );
  }
}

List<Widget> propertyRows(FileEntry e) {
  return [
    SectionLabel(t.quickLook.sectionGeneral),
    PropRow(
      label: t.quickLook.type,
      value: e.type == FileItemType.folder
          ? t.quickLook.typeFolder
          : e.extension.isEmpty
          ? t.quickLook.typeFile
          : e.extension.toUpperCase(),
    ),
    _SizeRows(entry: e),
    PropRow(label: t.quickLook.modified, value: _formatStatDate(e.modified)),
    PropRow(label: t.quickLook.created, value: _formatStatDate(e.created)),
    const SizedBox(height: 16),
    SectionLabel(t.quickLook.sectionDetails),
    PropRow(label: t.quickLook.location, value: PlatformPaths.parentOf(e.path)),
    PropRow(label: t.quickLook.path, value: e.path),
    _StatRows(entry: e),
    AsyncRetain<QlSection?>(
      cacheKey: 'img:${e.realPath}|${e.modifiedMs}',
      loader: () => imageInfo(e),
      builder: (section) {
        if (section == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            SectionLabel(section.title),
            for (final row in section.rows)
              PropRow(label: row.key, value: row.value),
          ],
        );
      },
    ),
  ];
}

class InfoPanel extends StatelessWidget {
  final FileEntry entry;

  const InfoPanel({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgSidebar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        children: propertyRows(entry),
      ),
    );
  }
}

class PropertiesOnly extends StatelessWidget {
  final FileEntry? entry;

  const PropertiesOnly({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final e = entry;
    if (e == null) {
      return QlCentered(message: t.quickLook.noSelection);
    }
    return Container(
      color: AppColors.bgSidebar,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: propertyRows(e),
      ),
    );
  }
}

class _FolderJob {
  final FileEntry entry;
  final int? session;
  _SftpFolderScan? sftpScan;
  int bytes = 0;
  int items = 0;
  bool done = false;
  bool freed = false;

  _FolderJob.local(this.entry, int this.session);
  _FolderJob.sftp(this.entry) : session = null;
}

class _SelectionSizeItem {
  final FileEntry entry;
  final int bytes;
  final bool done;

  const _SelectionSizeItem({
    required this.entry,
    required this.bytes,
    required this.done,
  });
}

class _TypeBreakdownItem {
  final String label;
  final String ext;
  final int count;
  final int bytes;
  final bool done;

  const _TypeBreakdownItem({
    required this.label,
    required this.ext,
    required this.count,
    required this.bytes,
    required this.done,
  });
}

class _TypeScanGroup {
  final int count;
  final int bytes;

  const _TypeScanGroup({required this.count, required this.bytes});
}

class _TypeScanSftpRoot {
  final int sessionId;
  final String remotePath;

  const _TypeScanSftpRoot(this.sessionId, this.remotePath);
}

class _TypeScanRequest {
  final SendPort port;
  final List<String> localRoots;
  final List<_TypeScanSftpRoot> sftpRoots;

  const _TypeScanRequest(this.port, this.localRoots, this.sftpRoots);
}

class _TypeScanProgress {
  final Map<String, _TypeScanGroup> groups;
  final bool done;

  const _TypeScanProgress(this.groups, this.done);
}

class _TypeBreakdownScan {
  final Isolate _isolate;
  final ReceivePort _port;
  StreamSubscription<dynamic>? _subscription;
  bool _closed = false;

  _TypeBreakdownScan._(this._isolate, this._port);

  static Future<_TypeBreakdownScan?> start({
    required List<FileEntry> folders,
    required void Function(Map<String, _TypeScanGroup> groups, bool done)
    onProgress,
  }) async {
    final localRoots = <String>[];
    final sftpRoots = <_TypeScanSftpRoot>[];
    for (final folder in folders) {
      if (PlatformPaths.isSftpUri(folder.realPath)) {
        final record = SftpSessionManager.recordFor(folder.realPath);
        if (record == null) continue;
        sftpRoots.add(
          _TypeScanSftpRoot(
            record.sessionId,
            SftpSessionManager.remotePath(folder.realPath),
          ),
        );
      } else {
        localRoots.add(folder.realPath);
      }
    }
    if (localRoots.isEmpty && sftpRoots.isEmpty) return null;
    final port = ReceivePort();
    final request = _TypeScanRequest(port.sendPort, localRoots, sftpRoots);
    final Isolate isolate;
    try {
      isolate = await Isolate.spawn(
        _runTypeBreakdownScan,
        request,
        debugName: 'type-breakdown-scan',
      );
    } catch (_) {
      port.close();
      return null;
    }
    final scan = _TypeBreakdownScan._(isolate, port);
    scan._subscription = port.listen((message) {
      if (scan._closed || message is! _TypeScanProgress) return;
      onProgress(message.groups, message.done);
      if (message.done) scan._close(kill: false);
    });
    return scan;
  }

  void cancel() {
    _close(kill: true);
  }

  void _close({required bool kill}) {
    if (_closed) return;
    _closed = true;
    _subscription?.cancel();
    _subscription = null;
    _port.close();
    if (kill) {
      _isolate.kill(priority: Isolate.immediate);
    }
  }
}

void _runTypeBreakdownScan(_TypeScanRequest request) {
  final groups = <String, _TypeScanGroup>{};
  var pending = 0;
  var lastSend = DateTime.now().millisecondsSinceEpoch;

  String extOf(String name) {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex < 0) return '';
    return name.substring(dotIndex + 1).toLowerCase();
  }

  void addFile(String name, int bytes) {
    final ext = extOf(name);
    final current = groups[ext] ?? const _TypeScanGroup(count: 0, bytes: 0);
    groups[ext] = _TypeScanGroup(
      count: current.count + 1,
      bytes: current.bytes + bytes,
    );
  }

  void send(bool done) {
    request.port.send(_TypeScanProgress(Map.of(groups), done));
    pending = 0;
    lastSend = DateTime.now().millisecondsSinceEpoch;
  }

  void maybeSend() {
    pending++;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (pending >= 96 || now - lastSend >= 180) {
      send(false);
    }
  }

  void walkLocal(String root) {
    final stack = <Directory>[Directory(root)];
    while (stack.isNotEmpty) {
      final dir = stack.removeLast();
      List<FileSystemEntity> entries;
      try {
        entries = dir.listSync(followLinks: false);
      } catch (_) {
        continue;
      }
      for (final entity in entries) {
        if (entity is Directory) {
          stack.add(entity);
          continue;
        }
        if (entity is! File) continue;
        try {
          addFile(PlatformPaths.fileName(entity.path), entity.statSync().size);
          maybeSend();
        } catch (_) {}
      }
    }
  }

  void walkSftp(_TypeScanSftpRoot root) {
    void walk(String remotePath) {
      final buf = WaydirCoreLoader.sftpList(root.sessionId, remotePath);
      if (buf == null) return;
      final entries = FileEntryCodec.decode(buf);
      for (final entry in entries) {
        if (entry.type == FileItemType.folder) {
          walk(entry.path);
          continue;
        }
        addFile(entry.name, entry.size);
        maybeSend();
      }
    }

    walk(root.remotePath);
  }

  try {
    for (final root in request.localRoots) {
      walkLocal(root);
    }
    for (final root in request.sftpRoots) {
      walkSftp(root);
    }
  } catch (_) {}
  send(true);
}

const _statsIconWidth = 24.0;
const _statsCountWidth = 34.0;
const _statsSizeWidth = 98.0;
const _statsTypeSizeWidth = 92.0;

class MultiProperties extends StatefulWidget {
  final List<FileEntry> entries;

  const MultiProperties({super.key, required this.entries});

  @override
  State<MultiProperties> createState() => _MultiPropertiesState();
}

class _MultiPropertiesState extends State<MultiProperties> {
  Timer? _timer;
  _TypeBreakdownScan? _typeScan;
  Map<String, _TypeScanGroup> _folderTypeGroups = {};
  bool _typeScanDone = true;
  int _typeScanGen = 0;
  final List<_FolderJob> _jobs = [];

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(MultiProperties old) {
    super.didUpdateWidget(old);
    final a = old.entries.map((e) => e.path).join('|');
    final b = widget.entries.map((e) => e.path).join('|');
    if (a != b) {
      _stopAll();
      setState(() {
        _jobs.clear();
        _folderTypeGroups = {};
        _typeScanDone = true;
      });
      _start();
    }
  }

  @override
  void dispose() {
    _stopAll();
    super.dispose();
  }

  void _start() {
    var hasLocalJobs = false;
    final folderEntries = <FileEntry>[];
    for (final e in widget.entries) {
      if (e.type != FileItemType.folder) continue;
      folderEntries.add(e);
      if (PlatformPaths.isSftpUri(e.realPath)) {
        final job = _FolderJob.sftp(e);
        _jobs.add(job);
        unawaited(
          _SftpFolderScan.start(
            logicalPath: e.realPath,
            onProgress: (stats) {
              if (!mounted || !_jobs.contains(job)) return;
              job.bytes = stats.bytes;
              job.items = stats.items;
              job.done = stats.done;
              if (stats.done) job.sftpScan = null;
              setState(() {});
              _stopTimerIfAllDone();
            },
          ).then((scan) {
            if (!mounted || !_jobs.contains(job) || job.done) {
              scan?.cancel();
              return;
            }
            if (scan == null) {
              job.done = true;
              setState(() {});
              _stopTimerIfAllDone();
              return;
            }
            job.sftpScan = scan;
          }),
        );
        continue;
      }
      int? session;
      try {
        session = WaydirCoreLoader.folderScanStart(e.realPath);
      } catch (_) {
        session = null;
      }
      if (session == null) continue;
      _jobs.add(_FolderJob.local(e, session));
      hasLocalJobs = true;
    }
    _startTypeScan(folderEntries);
    if (!hasLocalJobs) return;
    _poll();
    _timer = Timer.periodic(const Duration(milliseconds: 120), (_) => _poll());
  }

  void _startTypeScan(List<FileEntry> folderEntries) {
    if (folderEntries.isEmpty) return;
    final gen = ++_typeScanGen;
    _typeScanDone = false;
    unawaited(
      _TypeBreakdownScan.start(
        folders: folderEntries,
        onProgress: (groups, done) {
          if (!mounted || gen != _typeScanGen) return;
          setState(() {
            _folderTypeGroups = groups;
            _typeScanDone = done;
            if (done) _typeScan = null;
          });
        },
      ).then((scan) {
        if (!mounted || gen != _typeScanGen || _typeScanDone) {
          scan?.cancel();
          return;
        }
        if (scan == null) {
          setState(() {
            _typeScanDone = true;
          });
          return;
        }
        _typeScan = scan;
      }),
    );
  }

  void _poll() {
    var allDone = true;
    for (final j in _jobs) {
      if (j.done) continue;
      final session = j.session;
      if (session == null) {
        allDone = false;
        continue;
      }
      try {
        final r = WaydirCoreLoader.folderScanPoll(session);
        j.bytes = r.bytes;
        j.items = r.items;
        j.done = r.done;
        if (!r.done) {
          allDone = false;
        } else {
          _free(j);
        }
      } catch (_) {
        j.done = true;
        _free(j);
      }
    }
    if (mounted) setState(() {});
    if (allDone) _stopTimerIfAllDone();
  }

  void _stopTimerIfAllDone() {
    if (!_jobs.every((j) => j.done)) return;
    _timer?.cancel();
    _timer = null;
  }

  void _free(_FolderJob j) {
    final session = j.session;
    if (session == null) return;
    if (j.freed) return;
    j.freed = true;
    try {
      WaydirCoreLoader.folderScanFree(session);
    } catch (_) {}
  }

  void _stopAll() {
    _timer?.cancel();
    _timer = null;
    _typeScanGen++;
    _typeScan?.cancel();
    _typeScan = null;
    for (final j in _jobs) {
      j.sftpScan?.cancel();
      j.sftpScan = null;
      final session = j.session;
      if (session == null) continue;
      if (j.freed) continue;
      if (!j.done) {
        try {
          WaydirCoreLoader.folderScanCancel(session);
        } catch (_) {}
      }
      _free(j);
    }
  }

  @override
  Widget build(BuildContext context) {
    final files = widget.entries
        .where((e) => e.type != FileItemType.folder)
        .toList();
    final folderCount = widget.entries.length - files.length;
    final fileBytes = files.fold<int>(0, (a, e) => a + e.size);
    final folderBytes = _jobs.fold<int>(0, (a, j) => a + j.bytes);
    final folderItems = _jobs.fold<int>(0, (a, j) => a + j.items);
    final allDone = _jobs.every((j) => j.done);
    final totalBytes = fileBytes + folderBytes;
    final totalItems = files.length + folderItems;
    final calc = t.quickLook.calculating;
    final largest =
        [
          for (final e in files)
            _SelectionSizeItem(entry: e, bytes: e.size, done: true),
          for (final job in _jobs)
            _SelectionSizeItem(
              entry: job.entry,
              bytes: job.bytes,
              done: job.done,
            ),
        ]..sort((a, b) {
          final bySize = b.bytes.compareTo(a.bytes);
          if (bySize != 0) return bySize;
          return a.entry.nameLower.compareTo(b.entry.nameLower);
        });
    final typeBreakdown = _typeBreakdown(
      files: files,
      folderGroups: _folderTypeGroups,
      done: _typeScanDone,
    );

    String live(String base) => allDone ? base : '$base · $calc';

    return Container(
      color: AppColors.bgSidebar,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                SectionLabel(t.quickLook.sectionGeneral),
                PropRow(
                  label: t.quickLook.size,
                  value: live(formatBytes(totalBytes)),
                ),
                PropRow(
                  label: t.quickLook.contains,
                  value: live(t.quickLook.items(count: totalItems)),
                ),
                PropRow(label: t.quickLook.typeFolder, value: '$folderCount'),
                PropRow(label: t.quickLook.typeFile, value: '${files.length}'),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.bgDivider),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionLabel(t.quickLook.sectionStatistics),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _StatisticsList(
                            title: t.quickLook.sizeBreakdown,
                            child: _StatisticsItems(items: largest),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatisticsList(
                            title: t.quickLook.typeBreakdown,
                            child: _TypeBreakdownItems(
                              items: typeBreakdown,
                              done: _typeScanDone,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_TypeBreakdownItem> _typeBreakdown({
    required List<FileEntry> files,
    required Map<String, _TypeScanGroup> folderGroups,
    required bool done,
  }) {
    final grouped = <String, ({String label, int count, int bytes})>{};
    void add(String ext, int count, int bytes) {
      final label = ext.isEmpty ? t.quickLook.noExtension : '.$ext';
      final current = grouped[ext] ?? (label: label, count: 0, bytes: 0);
      grouped[ext] = (
        label: current.label,
        count: current.count + count,
        bytes: current.bytes + bytes,
      );
    }

    for (final file in files) {
      add(file.extension, 1, file.size);
    }
    for (final entry in folderGroups.entries) {
      add(entry.key, entry.value.count, entry.value.bytes);
    }
    final items =
        [
          for (final entry in grouped.entries)
            _TypeBreakdownItem(
              label: entry.value.label,
              ext: entry.key,
              count: entry.value.count,
              bytes: entry.value.bytes,
              done: done,
            ),
        ]..sort((a, b) {
          final bySize = b.bytes.compareTo(a.bytes);
          if (bySize != 0) return bySize;
          return a.label.compareTo(b.label);
        });
    return items;
  }
}

class _StatisticsList extends StatelessWidget {
  final String title;
  final Widget child;

  const _StatisticsList({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.txt.captionSmall.copyWith(color: AppColors.fgMuted),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _StatisticsItems extends StatefulWidget {
  final List<_SelectionSizeItem> items;

  const _StatisticsItems({required this.items});

  @override
  State<_StatisticsItems> createState() => _StatisticsItemsState();
}

class _StatisticsItemsState extends State<_StatisticsItems> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border.all(color: AppColors.bgDivider),
      ),
      child: Scrollbar(
        controller: _controller,
        child: ListView.builder(
          controller: _controller,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _StatisticsItemRow(item: items[index]);
          },
        ),
      ),
    );
  }
}

class _TypeBreakdownItems extends StatefulWidget {
  final List<_TypeBreakdownItem> items;
  final bool done;

  const _TypeBreakdownItems({required this.items, required this.done});

  @override
  State<_TypeBreakdownItems> createState() => _TypeBreakdownItemsState();
}

class _TypeBreakdownItemsState extends State<_TypeBreakdownItems> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border.all(color: AppColors.bgDivider),
      ),
      child: items.isEmpty
          ? Center(
              child: Text(
                widget.done ? '' : t.quickLook.calculating,
                style: context.txt.captionSmall.copyWith(
                  color: AppColors.fgMuted,
                ),
              ),
            )
          : Scrollbar(
              controller: _controller,
              child: ListView.builder(
                controller: _controller,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return _TypeBreakdownItemRow(item: items[index]);
                },
              ),
            ),
    );
  }
}

class _TypeBreakdownItemRow extends StatelessWidget {
  final _TypeBreakdownItem item;

  const _TypeBreakdownItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final size = item.bytes == 0 && !item.done
        ? t.quickLook.calculating
        : item.done
        ? formatBytes(item.bytes)
        : '${formatBytes(item.bytes)} · ${t.quickLook.calculating}';
    return SizedBox(
      height: 32,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            SizedBox(
              width: _statsIconWidth,
              child: Align(
                alignment: Alignment.centerLeft,
                child: buildFileIcon(
                  name: item.ext.isEmpty ? item.label : 'file.${item.ext}',
                  ext: item.ext,
                  isFolder: false,
                  size: 16,
                ),
              ),
            ),
            Expanded(
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.txt.row.copyWith(color: AppColors.fg),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: _statsCountWidth,
              child: Text(
                '${item.count}',
                maxLines: 1,
                textAlign: TextAlign.right,
                style: context.txt.captionSmall.copyWith(
                  color: AppColors.fgMuted,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: _statsTypeSizeWidth,
              child: Text(
                size,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: context.txt.captionSmall.copyWith(
                  color: item.done ? AppColors.fgMuted : AppColors.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticsItemRow extends StatelessWidget {
  final _SelectionSizeItem item;

  const _StatisticsItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final entry = item.entry;
    final isFolder = entry.type == FileItemType.folder;
    final size = item.bytes == 0 && !item.done
        ? t.quickLook.calculating
        : item.done
        ? formatBytes(item.bytes)
        : '${formatBytes(item.bytes)} · ${t.quickLook.calculating}';
    return SizedBox(
      height: 32,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            buildFileIcon(
              name: entry.name,
              ext: entry.extension,
              isFolder: isFolder,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.txt.row.copyWith(color: AppColors.fg),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: _statsSizeWidth,
              child: Text(
                size,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: context.txt.captionSmall.copyWith(
                  color: item.done ? AppColors.fgMuted : AppColors.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
