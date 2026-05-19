import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';

const imageExts = {'png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp'};

/// Extensions that are never useful to preview as text — route straight to
/// properties without reading the file.
const binaryExts = {
  'zip',
  'rar',
  '7z',
  'gz',
  'bz2',
  'xz',
  'tar',
  'tgz',
  'zst',
  'lz4',
  'exe',
  'dll',
  'so',
  'dylib',
  'bin',
  'o',
  'a',
  'lib',
  'class',
  'jar',
  'pdf',
  'doc',
  'docx',
  'xls',
  'xlsx',
  'ppt',
  'pptx',
  'odt',
  'ods',
  'mp3',
  'wav',
  'flac',
  'ogg',
  'aac',
  'm4a',
  'opus',
  'mp4',
  'mkv',
  'mov',
  'avi',
  'webm',
  'flv',
  'wmv',
  'm4v',
  'ico',
  'tif',
  'tiff',
  'psd',
  'heic',
  'avif',
  'raw',
  'svg',
  'ttf',
  'otf',
  'woff',
  'woff2',
  'eot',
  'db',
  'sqlite',
  'sqlite3',
  'dat',
  'pack',
  'idx',
  'wasm',
  'pyc',
  'iso',
  'img',
  'dmg',
  'deb',
  'rpm',
  'apk',
  'msi',
  'appimage',
};
const maxTextBytes = 4 * 1024 * 1024;
const maxHighlightChars = 200 * 1024;
const panelWidth = 300.0;

class QlCentered extends StatelessWidget {
  final String? message;
  final IconData? icon;
  final bool spinner;

  const QlCentered({super.key, this.message, this.icon}) : spinner = false;

  const QlCentered.spinner({super.key})
    : message = null,
      icon = null,
      spinner = true;

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
                  PhosphorIcon(icon!, size: 48, color: AppColors.fgSubtle),
                  const SizedBox(height: 14),
                ],
                Text(message ?? '', style: context.txt.muted),
              ],
            ),
    );
  }
}

class QlHudChip extends StatelessWidget {
  final String text;

  const QlHudChip({super.key, required this.text});

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

class AsyncRetain<T> extends StatefulWidget {
  final String cacheKey;
  final Future<T> Function() loader;
  final Widget Function(T data) builder;
  final Widget? loading;

  const AsyncRetain({
    super.key,
    required this.cacheKey,
    required this.loader,
    required this.builder,
    this.loading,
  });

  @override
  State<AsyncRetain<T>> createState() => _AsyncRetainState<T>();
}

class _AsyncRetainState<T> extends State<AsyncRetain<T>> {
  T? _data;
  bool _has = false;
  int _gen = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(AsyncRetain<T> old) {
    super.didUpdateWidget(old);
    if (old.cacheKey != widget.cacheKey) _load();
  }

  Future<void> _load() async {
    final gen = ++_gen;
    try {
      final result = await widget.loader();
      if (!mounted || gen != _gen) return;
      setState(() {
        _data = result;
        _has = true;
      });
    } catch (_) {
      if (!mounted || gen != _gen) return;
      setState(() => _has = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_has) return widget.loading ?? const SizedBox.shrink();
    return widget.builder(_data as T);
  }
}
