import 'dart:io';

import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../../ui/theme/app_theme.dart';
import 'quick_look_common.dart';

class ImagePreview extends StatefulWidget {
  final String path;

  const ImagePreview({super.key, required this.path});

  @override
  State<ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<ImagePreview> {
  final _controller = TransformationController();

  @override
  void didUpdateWidget(ImagePreview old) {
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
                      gaplessPlayback: true,
                      frameBuilder: (context, child, frame, wasSyncLoaded) {
                        if (wasSyncLoaded || frame != null) return child;
                        return const QlCentered.spinner();
                      },
                      errorBuilder: (_, _, _) =>
                          QlCentered(message: t.quickLook.noPreview),
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
                          _scrollbar(
                            vertical: true,
                            viewport: vh,
                            track: vh - 16,
                            scale: s,
                            translation: tr.y,
                          ),
                          _scrollbar(
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
                          child: QlHudChip(text: '${(s * 100).round()}%'),
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

  Widget _scrollbar({
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
