import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

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
      child: Text(
        text.toUpperCase(),
        style: context.txt.sectionLabel.copyWith(fontSize: 11.5),
      ),
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
  FolderStats? _stats;

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
    try {
      _session = WaydirCoreLoader.folderScanStart(widget.path);
    } catch (_) {
      _session = null;
    }
    if (_session == null) return;
    _poll();
    _timer = Timer.periodic(const Duration(milliseconds: 120), (_) => _poll());
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
    _timer?.cancel();
    _timer = null;
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

class _StatRows extends StatelessWidget {
  final FileEntry entry;

  const _StatRows({required this.entry});

  @override
  Widget build(BuildContext context) {
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
  final int session;
  int bytes = 0;
  int items = 0;
  bool done = false;
  bool freed = false;

  _FolderJob(this.session);
}

/// Aggregate properties for a multi-selection: sums plain file sizes
/// immediately and recursively scans every selected folder, summing bytes
/// and contained items live.
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
    for (final e in widget.entries) {
      if (e.type != FileItemType.folder) continue;
      int? session;
      try {
        session = WaydirCoreLoader.folderScanStart(e.realPath);
      } catch (_) {
        session = null;
      }
      if (session == null) continue;
      _jobs.add(_FolderJob(session));
    }
    if (_jobs.isEmpty) return;
    _poll();
    _timer = Timer.periodic(const Duration(milliseconds: 120), (_) => _poll());
  }

  void _poll() {
    var allDone = true;
    for (final j in _jobs) {
      if (j.done) continue;
      try {
        final r = WaydirCoreLoader.folderScanPoll(j.session);
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
    if (allDone) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _free(_FolderJob j) {
    if (j.freed) return;
    j.freed = true;
    try {
      WaydirCoreLoader.folderScanFree(j.session);
    } catch (_) {}
  }

  void _stopAll() {
    _timer?.cancel();
    _timer = null;
    for (final j in _jobs) {
      if (j.freed) continue;
      if (!j.done) {
        try {
          WaydirCoreLoader.folderScanCancel(j.session);
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
