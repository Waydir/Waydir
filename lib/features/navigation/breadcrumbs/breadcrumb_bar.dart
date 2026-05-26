import 'package:flutter/material.dart';

import '../../../ui/icons/waydir_icons.dart';
import '../../../ui/overlays/context_menu.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/theme/app_text_styles.dart';
import 'crumb.dart';

class BreadcrumbBar extends StatelessWidget {
  final List<Crumb> crumbs;
  final ValueChanged<String> onNavigate;

  const BreadcrumbBar({
    super.key,
    required this.crumbs,
    required this.onNavigate,
  });

  static const double _segHPad = 3.0;
  static const double _caretBoxW = 16.0;
  static const double _ellipsisBoxW = 14.0 + _segHPad * 2;
  static const double _iconSize = 13.0;
  static const double _iconGap = 6.0;

  @override
  Widget build(BuildContext context) {
    if (crumbs.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final txt = context.txt;
        final regular = txt.body;
        final bold = txt.bodyEmphasis;
        final widths = _measureAll(crumbs, regular, bold);
        final n = crumbs.length;
        final lastIdx = n - 1;
        final maxW = constraints.maxWidth;

        double total = widths[0];
        for (var i = 1; i < n; i++) {
          total += _caretBoxW + widths[i];
        }

        if (n == 1 || total <= maxW) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < n; i++) ...[
                if (i > 0) const _Caret(),
                _segmentWidget(i, isLast: i == lastIdx, flexible: i == lastIdx),
              ],
            ],
          );
        }

        final rootW = widths[0];
        double available =
            maxW - rootW - _caretBoxW - _ellipsisBoxW - _caretBoxW;
        if (available < 0) available = 0;

        final shown = <int>[lastIdx];
        double used = widths[lastIdx];
        for (var i = n - 2; i >= 1; i--) {
          final w = _caretBoxW + widths[i];
          if (used + w <= available) {
            shown.insert(0, i);
            used += w;
          } else {
            break;
          }
        }

        final hidden = <int>[];
        for (var i = 1; i < n; i++) {
          if (!shown.contains(i)) hidden.add(i);
        }

        return Row(
          children: [
            _segmentWidget(0, isLast: false, flexible: false),
            const _Caret(),
            if (hidden.isNotEmpty)
              _EllipsisMenu(
                hiddenCrumbs: [for (final i in hidden) crumbs[i]],
                onNavigate: onNavigate,
              ),
            for (var k = 0; k < shown.length; k++) ...[
              if (hidden.isNotEmpty || k > 0) const _Caret(),
              _segmentWidget(
                shown[k],
                isLast: shown[k] == lastIdx,
                flexible: shown[k] == lastIdx,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _segmentWidget(
    int i, {
    required bool isLast,
    required bool flexible,
  }) {
    final segment = _CrumbSegment(
      crumb: crumbs[i],
      isLast: isLast,
      ellipsisOverflow: flexible,
      onTap: isLast ? null : () => onNavigate(crumbs[i].fullPath),
    );
    return flexible ? Flexible(child: segment) : segment;
  }

  List<double> _measureAll(
    List<Crumb> crumbs,
    TextStyle regular,
    TextStyle bold,
  ) {
    final lastIdx = crumbs.length - 1;
    final widths = List<double>.filled(crumbs.length, 0);
    for (var i = 0; i < crumbs.length; i++) {
      final c = crumbs[i];
      final style = i == lastIdx ? bold : regular;
      final tp = TextPainter(
        text: TextSpan(text: c.label, style: style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      final iconExtra = c.icon != null ? _iconSize + _iconGap : 0;
      widths[i] = _segHPad * 2 + iconExtra + tp.width;
    }
    return widths;
  }
}

class _Caret extends StatelessWidget {
  const _Caret();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Icon(
        WaydirIconsRegular.caretRight,
        size: 14,
        color: AppColors.fgSubtle,
      ),
    );
  }
}

class _CrumbSegment extends StatefulWidget {
  final Crumb crumb;
  final VoidCallback? onTap;
  final bool isLast;
  final bool ellipsisOverflow;

  const _CrumbSegment({
    required this.crumb,
    required this.onTap,
    required this.isLast,
    required this.ellipsisOverflow,
  });

  @override
  State<_CrumbSegment> createState() => _CrumbSegmentState();
}

class _CrumbSegmentState extends State<_CrumbSegment> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final clickable = widget.onTap != null;
    final icon = widget.crumb.icon;
    final textStyle = context.txt.body.copyWith(
      color: widget.isLast
          ? AppColors.fg
          : (clickable ? AppColors.fgMuted : AppColors.fg),
      fontWeight: widget.isLast ? FontWeight.w500 : FontWeight.normal,
    );

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: AppColors.fgAccent),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            widget.crumb.label,
            maxLines: 1,
            softWrap: false,
            overflow: widget.ellipsisOverflow
                ? TextOverflow.ellipsis
                : TextOverflow.clip,
            style: textStyle,
          ),
        ),
      ],
    );

    return MouseRegion(
      onEnter: clickable ? (_) => setState(() => _hovered = true) : null,
      onExit: clickable ? (_) => setState(() => _hovered = false) : null,
      cursor: clickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          decoration: _hovered
              ? BoxDecoration(color: AppColors.bgHover)
              : null,
          child: content,
        ),
      ),
    );
  }
}

class _EllipsisMenu extends StatefulWidget {
  final List<Crumb> hiddenCrumbs;
  final ValueChanged<String> onNavigate;

  const _EllipsisMenu({required this.hiddenCrumbs, required this.onNavigate});

  @override
  State<_EllipsisMenu> createState() => _EllipsisMenuState();
}

class _EllipsisMenuState extends State<_EllipsisMenu> {
  bool _hovered = false;

  void _openMenu() {
    final box = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = box.localToGlobal(
      Offset(0, box.size.height + 2),
      ancestor: overlay,
    );

    showContextMenu(
      context: context,
      position: position,
      items: [
        for (var i = 0; i < widget.hiddenCrumbs.length; i++)
          ContextMenuItem(
            icon: WaydirIconsRegular.folder,
            label: widget.hiddenCrumbs[i].label,
            action: '$i',
          ),
      ],
      onSelect: (action) {
        final idx = int.parse(action);
        widget.onNavigate(widget.hiddenCrumbs[idx].fullPath);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _openMenu,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          decoration: _hovered
              ? BoxDecoration(color: AppColors.bgHover)
              : null,
          child: Tooltip(
            message: widget.hiddenCrumbs.map((c) => c.label).join(' › '),
            child: Text(
              '…',
              style: context.txt.body.copyWith(
                color: _hovered ? AppColors.fg : AppColors.fgMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
