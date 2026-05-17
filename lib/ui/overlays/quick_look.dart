import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:exif/exif.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:signals/signals_flutter.dart';

import '../../core/models/file_entry.dart';
import '../../features/files/file_icons.dart';
import '../../core/platform/platform_paths.dart';
import '../../features/navigation/navigation_store.dart';
import '../../i18n/strings.g.dart';
import '../../utils/format.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';

const _imageExts = {'png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp'};

/// Max bytes read for a textual preview.
const _maxTextBytes = 1024 * 1024;

/// Quick Look overlay: a full-window preview of the file under the cursor of
/// [store]. Spacebar / Esc closes it; arrow keys move to the adjacent file and
/// the preview follows the cursor live.
Future<void> showQuickLook({
  required BuildContext context,
  required NavigationStore store,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Quick Look',
    barrierColor: Colors.black.withValues(alpha: 0.62),
    transitionDuration: const Duration(milliseconds: 110),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _QuickLook(store: store);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _QuickLook extends StatefulWidget {
  final NavigationStore store;

  const _QuickLook({required this.store});

  @override
  State<_QuickLook> createState() => _QuickLookState();
}

class _QuickLookState extends State<_QuickLook> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      widget.store.moveCursor(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      widget.store.moveCursor(-1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Focus(
      onKeyEvent: _handleKey,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: (size.width * 0.7).clamp(360.0, 1100.0),
            height: (size.height * 0.78).clamp(320.0, 900.0),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Watch((_) {
                final entry = widget.store.cursorEntry.value;
                return Column(
                  children: [
                    _Header(
                      entry: entry,
                      onClose: () => Navigator.of(context).pop(),
                    ),
                    Container(height: 1, color: AppColors.bgDivider),
                    _MetadataBar(entry: entry),
                    Container(height: 1, color: AppColors.bgDivider),
                    Expanded(child: _PreviewBody(entry: entry)),
                    Container(height: 1, color: AppColors.bgDivider),
                    _DetailsBar(entry: entry),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final FileEntry? entry;
  final VoidCallback onClose;

  const _Header({required this.entry, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final name = e?.name ?? t.quickLook.noSelection;
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          const SizedBox(width: 16),
          PhosphorIcon(
            e == null
                ? PhosphorIconsRegular.file
                : e.type == FileItemType.folder
                ? PhosphorIconsRegular.folder
                : fileIcon(e.extension),
            size: 20,
            color: e == null
                ? AppColors.fgMuted
                : e.type == FileItemType.folder
                ? AppColors.accent
                : fileIconColor(e.extension),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: context.txt.bodyEmphasis,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _CloseButton(onTap: onClose),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class _CloseButton extends StatefulWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _hover ? AppColors.bgHover : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.close,
            size: 17,
            color: _hover ? AppColors.fg : AppColors.fgMuted,
          ),
        ),
      ),
    );
  }
}

typedef _Section = ({String title, List<MapEntry<String, String>> rows});

class _MetadataBar extends StatelessWidget {
  final FileEntry? entry;

  const _MetadataBar({required this.entry});

  @override
  Widget build(BuildContext context) {
    final e = entry;
    if (e == null) {
      return SizedBox(
        height: 52,
        child: Container(
          color: AppColors.bgSidebar,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(t.quickLook.noSelection, style: context.txt.muted),
        ),
      );
    }

    final primary = <MapEntry<String, String>>[
      MapEntry(
        t.quickLook.type,
        e.type == FileItemType.folder
            ? t.quickLook.typeFolder
            : e.extension.isEmpty
            ? t.quickLook.typeFile
            : e.extension.toUpperCase(),
      ),
      if (e.type != FileItemType.folder)
        MapEntry(t.quickLook.size, formatBytes(e.size)),
      MapEntry(t.quickLook.modified, formatTimeAgo(e.modified)),
    ];

    return SizedBox(
      height: 52,
      child: Container(
        color: AppColors.bgSidebar,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: primary.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final row = primary[index];
            return _MetaPill(label: row.key, value: row.value);
          },
        ),
      ),
    );
  }
}

class _DetailsBar extends StatelessWidget {
  final FileEntry? entry;

  const _DetailsBar({required this.entry});

  @override
  Widget build(BuildContext context) {
    final e = entry;
    if (e == null) return const SizedBox.shrink();

    final secondary = <MapEntry<String, String>>[
      MapEntry(t.quickLook.path, e.path),
      MapEntry(t.quickLook.location, PlatformPaths.parentOf(e.path)),
    ];

    return SizedBox(
      height: 52,
      child: Container(
        color: AppColors.bgSidebar,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: FutureBuilder<_Section?>(
          key: ValueKey('${e.realPath}|${e.modified.millisecondsSinceEpoch}'),
          future: _extraInfo(e),
          builder: (context, snap) {
            final extra = snap.data?.rows ?? const <MapEntry<String, String>>[];
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: secondary.length + extra.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final row = index < secondary.length
                    ? secondary[index]
                    : extra[index - secondary.length];
                return _MetaPill(label: row.key, value: row.value);
              },
            );
          },
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String label;
  final String value;

  const _MetaPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: context.txt.caption.copyWith(color: AppColors.fgMuted),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: context.txt.caption.copyWith(color: AppColors.fg),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

Future<_Section?> _extraInfo(FileEntry e) async {
  if (e.type == FileItemType.folder) return null;
  final rows = <MapEntry<String, String>>[];
  try {
    if (_imageExts.contains(e.extension)) {
      final bytes = await _readHead(e.realPath, 512 * 1024);
      final tags = await readExifFromBytes(bytes);
      String? tag(String k) {
        final v = tags[k]?.printable.trim();
        return (v == null || v.isEmpty) ? null : v;
      }

      final w = tag('EXIF ExifImageWidth') ?? tag('Image ImageWidth');
      final h = tag('EXIF ExifImageLength') ?? tag('Image ImageLength');
      if (w != null && h != null) {
        rows.add(MapEntry(t.quickLook.dimensions, '$w × $h'));
      }
      final make = tag('Image Make');
      final model = tag('Image Model');
      final cam = [make, model].whereType<String>().join(' ');
      if (cam.isNotEmpty) rows.add(MapEntry(t.quickLook.camera, cam));
      final lens = tag('EXIF LensModel');
      if (lens != null) rows.add(MapEntry(t.quickLook.lens, lens));
      final exp = tag('EXIF ExposureTime');
      if (exp != null) rows.add(MapEntry(t.quickLook.exposure, '$exp s'));
      final fnum = tag('EXIF FNumber');
      if (fnum != null) rows.add(MapEntry(t.quickLook.aperture, 'f/$fnum'));
      final iso = tag('EXIF ISOSpeedRatings');
      if (iso != null) rows.add(MapEntry(t.quickLook.iso, iso));
      final fl = tag('EXIF FocalLength');
      if (fl != null) rows.add(MapEntry(t.quickLook.focalLength, '$fl mm'));
      final dt = tag('EXIF DateTimeOriginal');
      if (dt != null) rows.add(MapEntry(t.quickLook.dateTaken, dt));
      if (rows.isEmpty) return null;
      return (title: t.quickLook.sectionImage, rows: rows);
    }
    final res = await _readText(e);
    if (res.error == null && res.text.isNotEmpty) {
      final lines = '\n'.allMatches(res.text).length + 1;
      rows.add(MapEntry(t.quickLook.lines, '$lines'));
      rows.add(MapEntry(t.quickLook.characters, '${res.text.length}'));
      return (title: t.quickLook.sectionText, rows: rows);
    }
  } catch (_) {
    // Metadata is best-effort.
  }
  return null;
}

Future<Uint8List> _readHead(String path, int maxBytes) async {
  final builder = BytesBuilder(copy: false);
  await for (final chunk in File(path).openRead(0, maxBytes)) {
    builder.add(chunk);
  }
  return builder.takeBytes();
}

class _PreviewBody extends StatelessWidget {
  final FileEntry? entry;

  const _PreviewBody({required this.entry});

  @override
  Widget build(BuildContext context) {
    final e = entry;
    if (e == null) {
      return _Centered(message: t.quickLook.noSelection);
    }
    if (e.type == FileItemType.folder) {
      return _Centered(
        message: t.quickLook.folder,
        icon: PhosphorIconsRegular.folder,
      );
    }
    if (_imageExts.contains(e.extension)) {
      return _ImagePreview(path: e.realPath);
    }
    return _TextPreview(entry: e);
  }
}

class _ImagePreview extends StatefulWidget {
  final String path;

  const _ImagePreview({required this.path});

  @override
  State<_ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<_ImagePreview> {
  final _controller = TransformationController();

  @override
  void didUpdateWidget(_ImagePreview old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path) _controller.value = Matrix4.identity();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, c) {
          final vw = c.maxWidth;
          final vh = c.maxHeight;
          return Stack(
            children: [
              GestureDetector(
                onDoubleTap: () => _controller.value = Matrix4.identity(),
                child: InteractiveViewer(
                  transformationController: _controller,
                  maxScale: 8,
                  minScale: 1,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox.expand(
                    child: Image.file(
                      File(widget.path),
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      frameBuilder: (context, child, frame, wasSyncLoaded) {
                        if (wasSyncLoaded || frame != null) return child;
                        return const _Centered.spinner();
                      },
                      errorBuilder: (_, _, _) =>
                          _Centered(message: t.quickLook.noPreview),
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final m = _controller.value;
                  final s = m.getMaxScaleOnAxis();
                  final tr = m.getTranslation();
                  final zoomed = s > 1.001;
                  return IgnorePointer(
                    child: Stack(
                      children: [
                        if (zoomed) ...[
                          _imageScrollbar(
                            vertical: true,
                            viewport: vh,
                            track: vh - 16,
                            scale: s,
                            translation: tr.y,
                          ),
                          _imageScrollbar(
                            vertical: false,
                            viewport: vw,
                            track: vw - 16,
                            scale: s,
                            translation: tr.x,
                          ),
                        ],
                        Positioned(
                          left: 12,
                          bottom: 10,
                          child: _HudChip(text: '${(s * 100).round()}%'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _imageScrollbar({
    required bool vertical,
    required double viewport,
    required double track,
    required double scale,
    required double translation,
  }) {
    final visibleFrac = (1 / scale).clamp(0.0, 1.0);
    final maxStart = 1 - visibleFrac;
    final startFrac = viewport <= 0
        ? 0.0
        : (-translation / (scale * viewport)).clamp(0.0, maxStart);
    final thumbLen = visibleFrac * track;
    final thumbPos = 6 + startFrac * track;
    if (vertical) {
      return Positioned(
        top: thumbPos,
        right: 4,
        child: _ScrollThumb(width: 5, height: thumbLen),
      );
    }
    return Positioned(
      left: thumbPos,
      bottom: 4,
      child: _ScrollThumb(width: thumbLen, height: 5),
    );
  }
}

class _ScrollThumb extends StatelessWidget {
  final double width;
  final double height;

  const _ScrollThumb({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.fgMuted.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _HudChip extends StatelessWidget {
  final String text;

  const _HudChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.bgSurface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Text(text, style: context.txt.caption),
    );
  }
}

class _TextPreview extends StatelessWidget {
  final FileEntry entry;

  const _TextPreview({required this.entry});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TextResult>(
      key: ValueKey(
        '${entry.realPath}|${entry.modified.millisecondsSinceEpoch}',
      ),
      future: _readText(entry),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const _Centered.spinner();
        }
        final res = snap.data;
        if (res == null || res.error != null) {
          return _Centered(message: res?.error ?? t.quickLook.readError);
        }
        return _TextScroller(text: res.text);
      },
    );
  }
}

class _TextScroller extends StatefulWidget {
  final String text;

  const _TextScroller({required this.text});

  @override
  State<_TextScroller> createState() => _TextScrollerState();
}

class _TextScrollerState extends State<_TextScroller> {
  final _vCtrl = ScrollController();
  final _hCtrl = ScrollController();
  double _percent = 0;

  @override
  void initState() {
    super.initState();
    _vCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _vCtrl.removeListener(_onScroll);
    _vCtrl.dispose();
    _hCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_vCtrl.hasClients) return;
    final max = _vCtrl.position.maxScrollExtent;
    final p = max <= 0 ? 0.0 : (_vCtrl.offset / max).clamp(0.0, 1.0);
    if ((p - _percent).abs() > 0.005) setState(() => _percent = p);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      width: double.infinity,
      child: Stack(
        children: [
          Scrollbar(
            controller: _vCtrl,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _vCtrl,
              child: Scrollbar(
                controller: _hCtrl,
                thumbVisibility: true,
                notificationPredicate: (n) => n.depth == 1,
                child: SingleChildScrollView(
                  controller: _hCtrl,
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 24, 24),
                    child: SelectableText(
                      widget.text,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        height: 1.45,
                        color: AppColors.fg,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 14,
            bottom: 10,
            child: IgnorePointer(
              child: _HudChip(text: '${(_percent * 100).round()}%'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextResult {
  final String text;
  final String? error;

  const _TextResult(this.text, {this.error});
}

Future<_TextResult> _readText(FileEntry entry) async {
  try {
    final file = File(entry.realPath);
    // Stream at most _maxTextBytes + 1 so a huge file never gets fully loaded
    // into memory (that was the source of the UI stutter on big files).
    final builder = BytesBuilder(copy: false);
    await for (final chunk in file.openRead(0, _maxTextBytes + 1)) {
      builder.add(chunk);
      if (builder.length > _maxTextBytes) break;
    }
    final bytes = builder.takeBytes();
    if (bytes.length > _maxTextBytes) {
      return _TextResult('', error: t.quickLook.tooLarge);
    }
    final scanLen = bytes.length > 8000 ? 8000 : bytes.length;
    for (var i = 0; i < scanLen; i++) {
      if (bytes[i] == 0) {
        return _TextResult('', error: t.quickLook.binaryFile);
      }
    }
    return _TextResult(utf8.decode(bytes, allowMalformed: true));
  } catch (_) {
    return _TextResult('', error: t.quickLook.readError);
  }
}

class _Centered extends StatelessWidget {
  final String? message;
  final IconData? icon;
  final bool spinner;

  const _Centered({this.message, this.icon}) : spinner = false;

  const _Centered.spinner() : message = null, icon = null, spinner = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      alignment: Alignment.center,
      child: spinner
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.fgMuted,
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  PhosphorIcon(icon!, size: 44, color: AppColors.fgSubtle),
                  const SizedBox(height: 12),
                ],
                Text(message ?? '', style: context.txt.muted),
              ],
            ),
    );
  }
}
