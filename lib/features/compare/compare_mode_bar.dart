import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../core/keyboard/keyboard_shortcuts.dart';
import '../../i18n/strings.g.dart';
import '../../ui/icons/waydir_icons.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import 'compare_controller.dart';

class CompareModeBar extends StatelessWidget {
  final CompareController controller;

  const CompareModeBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        if (!controller.active.value) return const SizedBox.shrink();
        final counts = controller.counts.value;
        final running = controller.running.value;
        final recursive = controller.recursive.value;

        return Container(
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.bgToolbar,
            border: Border(top: BorderSide(color: AppColors.bgDivider)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: ClipRect(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Row(
                      children: [
                        _LegendDot(
                          color: AppColors.compareUnique,
                          label: t.compare.unique,
                        ),
                        const SizedBox(width: 12),
                        _LegendDot(
                          color: AppColors.compareNewer,
                          label: t.compare.newer,
                        ),
                        const SizedBox(width: 12),
                        _LegendDot(
                          color: AppColors.compareOlder,
                          label: t.compare.older,
                        ),
                        const SizedBox(width: 12),
                        _LegendDot(
                          color: AppColors.compareDiffer,
                          label: t.compare.differ,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          running
                              ? t.compare.running
                              : t.compare.counts(
                                  identical: counts.identical,
                                  differ: counts.differ,
                                  uniqueLeft: counts.uniqueLeft,
                                  uniqueRight: counts.uniqueRight,
                                ),
                          style: context.txt.captionSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _CompareButton(
                label: t.compare.recursive,
                active: recursive,
                onTap: () => controller.setRecursive(!recursive),
              ),
              const SizedBox(width: 6),
              _CompareButton(
                label: t.compare.syncRight,
                shortcutId: 'compare_sync_right',
                onTap: controller.syncLeftToRight,
              ),
              const SizedBox(width: 6),
              _CompareButton(
                label: t.compare.syncLeft,
                shortcutId: 'compare_sync_left',
                onTap: controller.syncRightToLeft,
              ),
              const SizedBox(width: 6),
              _CompareCloseButton(onTap: controller.stop),
            ],
          ),
        );
      },
    );
  }
}

class _CompareCloseButton extends StatefulWidget {
  final VoidCallback onTap;

  const _CompareCloseButton({required this.onTap});

  @override
  State<_CompareCloseButton> createState() => _CompareCloseButtonState();
}

class _CompareCloseButtonState extends State<_CompareCloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: t.compare.done,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _hovered ? AppColors.bgHover : Colors.transparent,
              borderRadius: BorderRadius.zero,
            ),
            child: Icon(
              WaydirIconsRegular.x,
              size: 14,
              color: AppColors.fgMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, color: color.withValues(alpha: 0.8)),
        const SizedBox(width: 5),
        Text(label, style: context.txt.captionSmall),
      ],
    );
  }
}

class _CompareButton extends StatefulWidget {
  final String label;
  final String? shortcutId;
  final bool active;
  final VoidCallback onTap;

  const _CompareButton({
    required this.label,
    required this.onTap,
    this.shortcutId,
    this.active = false,
  });

  @override
  State<_CompareButton> createState() => _CompareButtonState();
}

class _CompareButtonState extends State<_CompareButton> {
  bool _hovered = false;

  String? get _shortcutDisplay => widget.shortcutId == null
      ? null
      : AppShortcuts.tryGetById(widget.shortcutId!)?.displayKeys;

  @override
  Widget build(BuildContext context) {
    final bg = widget.active
        ? AppColors.bgSelectedMuted
        : _hovered
        ? AppColors.bgHover
        : AppColors.bgInput;
    final shortcut = _shortcutDisplay;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(
              color: widget.active ? AppColors.accent : AppColors.bgDivider,
            ),
            borderRadius: BorderRadius.zero,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.label, style: context.txt.captionSmall),
              if (shortcut != null) ...[
                const SizedBox(width: 6),
                _ShortcutKeyCap(label: shortcut),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutKeyCap extends StatelessWidget {
  final String label;

  const _ShortcutKeyCap({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        border: Border.all(color: AppColors.borderColor),
        borderRadius: BorderRadius.zero,
      ),
      child: Text(label, style: context.txt.keyCap),
    );
  }
}
