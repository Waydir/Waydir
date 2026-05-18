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
            width: 80,
            child: Text(
              label,
              style: context.txt.caption.copyWith(color: AppColors.fgMuted),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              value,
              style: context.txt.caption.copyWith(color: AppColors.fg),
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
  bool _failed = false;

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
        _failed = false;
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
    if (_session == null) {
      _failed = true;
      return;
    }
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
        _failed = false;
      });
      if (r.done) _stop(cancel: false);
    } catch (_) {
      if (mounted) {
        setState(() => _failed = true);
      }
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
    final size = _failed
        ? t.quickLook.readError
        : stats == null
        ? calc
        : stats.done
        ? formatBytes(stats.bytes)
        : '${formatBytes(stats.bytes)} · $calc';
    final contains = _failed
        ? t.quickLook.readError
        : stats == null
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
  final String? note;

  const PropertiesOnly({super.key, required this.entry, this.note});

  @override
  Widget build(BuildContext context) {
    final e = entry;
    if (e == null) {
      return QlCentered(message: t.quickLook.noSelection);
    }
    final hasNote = note != null;
    if (!hasNote) {
      return Container(
        color: AppColors.bgSidebar,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: propertyRows(e),
        ),
      );
    }
    return Container(
      color: AppColors.bg,
      alignment: Alignment.center,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                note!,
                textAlign: TextAlign.center,
                style: context.txt.caption.copyWith(color: AppColors.fgMuted),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgSidebar,
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: propertyRows(e),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
