import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/models/file_entry.dart';
import '../../core/platform/platform_paths.dart';
import '../../features/files/file_icons.dart';
import '../../i18n/strings.g.dart';
import '../../utils/format.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';

/// File-explorer style Properties dialog for a single [entry].
Future<void> showPropertiesDialog({
  required BuildContext context,
  required FileEntry entry,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (ctx) => Center(
      child: Material(
        type: MaterialType.transparency,
        child: _PropertiesBody(entry: entry),
      ),
    ),
  );
}

class _PropertiesBody extends StatelessWidget {
  final FileEntry entry;

  const _PropertiesBody({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isFolder = entry.type == FileItemType.folder;
    return Container(
      width: 420,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhosphorIcon(
                isFolder
                    ? PhosphorIconsRegular.folder
                    : fileIcon(entry.extension),
                size: 22,
                color: isFolder
                    ? AppColors.accent
                    : fileIconColor(entry.extension),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  entry.name,
                  style: context.txt.heading,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Row(
            label: t.properties.type,
            value: isFolder
                ? t.properties.typeFolder
                : entry.extension.isEmpty
                ? t.properties.typeFile
                : '${entry.extension.toUpperCase()} ${t.properties.typeFile}',
          ),
          _Row(
            label: t.properties.location,
            value: PlatformPaths.parentOf(entry.path),
          ),
          _SizeRow(entry: entry),
          const _Divider(),
          _StatRows(entry: entry),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: _Button(
              label: t.properties.close,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SizeRow extends StatelessWidget {
  final FileEntry entry;

  const _SizeRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    if (entry.type != FileItemType.folder) {
      return _Row(
        label: t.properties.size,
        value: t.properties.sizeDetail(
          formatted: formatBytes(entry.size),
          count: entry.size,
        ),
      );
    }
    return FutureBuilder<_FolderStats>(
      future: _folderStats(entry.realPath),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Column(
            children: [
              _Row(label: t.properties.size, value: t.properties.calculating),
              _Row(
                label: t.properties.contains,
                value: t.properties.calculating,
              ),
            ],
          );
        }
        final s = snap.data!;
        return Column(
          children: [
            _Row(
              label: t.properties.size,
              value: t.properties.sizeDetail(
                formatted: formatBytes(s.bytes),
                count: s.bytes,
              ),
            ),
            _Row(
              label: t.properties.contains,
              value: t.properties.containsItems(count: s.items),
            ),
          ],
        );
      },
    );
  }
}

class _StatRows extends StatelessWidget {
  final FileEntry entry;

  const _StatRows({required this.entry});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FileStat>(
      future: FileStat.stat(entry.realPath),
      builder: (context, snap) {
        final stat = snap.data;
        return Column(
          children: [
            _Row(
              label: t.properties.modified,
              value: stat == null ? '—' : _formatDate(stat.modified),
            ),
            _Row(
              label: t.properties.accessed,
              value: stat == null ? '—' : _formatDate(stat.accessed),
            ),
            _Row(
              label: t.properties.changed,
              value: stat == null ? '—' : _formatDate(stat.changed),
            ),
            _Row(
              label: t.properties.permissions,
              value: stat == null ? '—' : stat.modeString(),
            ),
          ],
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

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
              style: context.txt.caption.copyWith(color: AppColors.fgMuted),
            ),
          ),
          const SizedBox(width: 12),
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

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(height: 1, thickness: 1, color: AppColors.bgDivider),
    );
  }
}

class _Button extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _Button({required this.label, required this.onTap});

  @override
  State<_Button> createState() => _ButtonState();
}

class _ButtonState extends State<_Button> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.accent.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _hovered
                  ? AppColors.accent
                  : AppColors.accent.withValues(alpha: 0.4),
            ),
          ),
          child: Text(
            widget.label,
            style: context.txt.rowEmphasis.copyWith(color: AppColors.accent),
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime d) {
  final locale = intl.Intl.canonicalizedLocale(
    ui.PlatformDispatcher.instance.locale.toLanguageTag(),
  );
  try {
    return intl.DateFormat.yMMMd(locale).add_jms().format(d);
  } catch (_) {
    return d.toIso8601String();
  }
}

class _FolderStats {
  final int bytes;
  final int items;

  const _FolderStats(this.bytes, this.items);
}

Future<_FolderStats> _folderStats(String path) async {
  var bytes = 0;
  var items = 0;
  try {
    final dir = Directory(path);
    await for (final e in dir.list(recursive: true, followLinks: false)) {
      items++;
      if (e is File) {
        try {
          bytes += await e.length();
        } catch (_) {}
      }
    }
  } catch (_) {}
  return _FolderStats(bytes, items);
}
