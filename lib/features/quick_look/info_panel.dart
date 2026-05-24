import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';

import '../../core/fs/sftp_session_manager.dart';
import '../../core/fs/waydir_core_loader.dart';
import '../../core/models/file_entry.dart';
import '../../core/platform/platform_paths.dart';
import '../../i18n/strings.g.dart';
import '../../utils/format.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import 'quick_look_common.dart';
import 'quick_look_io.dart';

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
              value: formatTimeAgo(stat.accessed),
            ),
            PropRow(
              label: t.quickLook.changed,
              value: formatTimeAgo(stat.changed),
            ),
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
    PropRow(label: t.quickLook.modified, value: formatTimeAgo(e.modified)),
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
  final int? session;
  _SftpFolderScan? sftpScan;
  int bytes = 0;
  int items = 0;
  bool done = false;
  bool freed = false;

  _FolderJob.local(int this.session);
  _FolderJob.sftp() : session = null;
}

class MultiProperties extends StatefulWidget {
  final List<FileEntry> entries;

  const MultiProperties({super.key, required this.entries});

  @override
  State<MultiProperties> createState() => _MultiPropertiesState();
}

class _MultiPropertiesState extends State<MultiProperties> {
  Timer? _timer;
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
    for (final e in widget.entries) {
      if (e.type != FileItemType.folder) continue;
      if (PlatformPaths.isSftpUri(e.realPath)) {
        final job = _FolderJob.sftp();
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
      _jobs.add(_FolderJob.local(session));
      hasLocalJobs = true;
    }
    if (!hasLocalJobs) return;
    _poll();
    _timer = Timer.periodic(const Duration(milliseconds: 120), (_) => _poll());
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

    String live(String base) => allDone ? base : '$base · $calc';

    return Container(
      color: AppColors.bgSidebar,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
    );
  }
}
