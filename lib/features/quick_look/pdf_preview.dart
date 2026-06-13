import 'dart:async';
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/fs/waydir_core_loader.dart';
import '../../i18n/strings.g.dart';
import '../../ui/theme/app_theme.dart';
import 'quick_look_common.dart';

const _maxRenderWidth = 2400;

// Isolate.run closures must capture only sendable values. Keeping these at the
// top level means their scope holds nothing but the plain arguments - defining
// them inside a widget method would drag the surrounding context (Completer,
// BuildContext, ...) into the message and make it unsendable.
Future<List<double>?> _pageAspectsInIsolate(String path) =>
    Isolate.run(() => WaydirCoreLoader.pdfPageAspects(path));

Future<PdfRenderedPage?> _renderInIsolate(String path, int index, int width) =>
    Isolate.run(() => WaydirCoreLoader.pdfRenderPage(path, index, width));

class PdfPreview extends StatefulWidget {
  final String path;

  const PdfPreview({super.key, required this.path});

  @override
  State<PdfPreview> createState() => _PdfPreviewState();
}

class _PdfPreviewState extends State<PdfPreview> {
  @override
  Widget build(BuildContext context) {
    final path = widget.path;
    return Container(
      color: AppColors.bg,
      width: double.infinity,
      child: AsyncRetain<List<double>?>(
        cacheKey: path,
        loader: () async {
          try {
            return await _pageAspectsInIsolate(path);
          } catch (_) {
            return null;
          }
        },
        loading: const QlCentered.spinner(),
        builder: (aspects) {
          if (aspects == null || aspects.isEmpty) {
            return QlCentered(message: t.quickLook.noPreview);
          }
          return _PdfPageList(path: path, aspects: aspects);
        },
      ),
    );
  }
}

class _PdfPageList extends StatelessWidget {
  final String path;
  final List<double> aspects;

  const _PdfPageList({required this.path, required this.aspects});

  static const _gap = 16.0;
  static const _pad = 16.0;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    return LayoutBuilder(
      builder: (context, c) {
        final logicalWidth = c.maxWidth - _pad * 2;
        final pixelWidth = (logicalWidth * dpr).round().clamp(
          200,
          _maxRenderWidth,
        );
        return Stack(
          children: [
            // Per-page extents are known up front, so feeding them through
            // itemExtentBuilder lets the ListView compute the exact scroll
            // range and keeps the scrollbar from jittering as pages render.
            ListView.builder(
              padding: const EdgeInsets.all(_pad),
              itemCount: aspects.length,
              itemExtentBuilder: (index, _) {
                if (index >= aspects.length) return null;
                final last = index == aspects.length - 1;
                return logicalWidth * aspects[index] + (last ? 0 : _gap);
              },
              itemBuilder: (context, index) {
                final last = index == aspects.length - 1;
                return Padding(
                  padding: EdgeInsets.only(bottom: last ? 0 : _gap),
                  child: _PdfPageItem(
                    key: ValueKey('$path#$index@$pixelWidth'),
                    path: path,
                    index: index,
                    pixelWidth: pixelWidth,
                    logicalWidth: logicalWidth,
                    aspect: aspects[index],
                  ),
                );
              },
            ),
            Positioned(
              left: 12,
              bottom: 10,
              child: QlHudChip(
                text: t.quickLook.pdfPages(count: aspects.length),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PdfPageItem extends StatefulWidget {
  final String path;
  final int index;
  final int pixelWidth;
  final double logicalWidth;
  final double aspect;

  const _PdfPageItem({
    super.key,
    required this.path,
    required this.index,
    required this.pixelWidth,
    required this.logicalWidth,
    required this.aspect,
  });

  @override
  State<_PdfPageItem> createState() => _PdfPageItemState();
}

class _PdfPageItemState extends State<_PdfPageItem> {
  ui.Image? _image;
  bool _failed = false;
  int _gen = 0;

  @override
  void initState() {
    super.initState();
    _render();
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<void> _render() async {
    final gen = ++_gen;
    final path = widget.path;
    final index = widget.index;
    final width = widget.pixelWidth;
    PdfRenderedPage? page;
    try {
      page = await _renderInIsolate(path, index, width);
    } catch (_) {
      page = null;
    }
    if (!mounted || gen != _gen) return;
    if (page == null) {
      setState(() => _failed = true);
      return;
    }
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      page.rgba,
      page.width,
      page.height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    final image = await completer.future;
    if (!mounted || gen != _gen) {
      image.dispose();
      return;
    }
    setState(() {
      _image?.dispose();
      _image = image;
    });
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    return Container(
      width: widget.logicalWidth,
      height: widget.logicalWidth * widget.aspect,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: _failed
          ? Icon(Icons.broken_image_outlined, color: AppColors.fgSubtle)
          : image == null
          ? const QlCentered.spinner()
          : RawImage(image: image, fit: BoxFit.contain),
    );
  }
}
