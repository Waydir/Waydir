import 'package:flutter/material.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';
import 'package:signals/signals_flutter.dart';
import '../../core/models/app_notification.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import 'notification_store.dart';

class NotificationOverlay extends StatelessWidget {
  final NotificationStore store;

  const NotificationOverlay({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final items = store.notifications.value;
        if (items.isEmpty) return const SizedBox.shrink();
        const maxVisible = 6;
        final visible = items.length > maxVisible
            ? items.sublist(items.length - maxVisible)
            : items;

        return Positioned(
          top: 8,
          right: 8,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 296),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: visible
                  .map(
                    (n) => _NotificationCard(
                      key: ValueKey(n.id),
                      notification: n,
                      onDismiss: () => store.dismiss(n.id),
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}

class _NotificationCard extends StatefulWidget {
  final AppNotification notification;
  final VoidCallback onDismiss;

  const _NotificationCard({
    super.key,
    required this.notification,
    required this.onDismiss,
  });

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  bool _dismissed = false;
  bool _applyToAll = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _opacity = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _anim.forward();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (!widget.notification.dismissible) return;
    if (_dismissed || !mounted) return;
    _dismissed = true;
    _anim.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final accent = n.accentColor ?? AppColors.accent;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          width: 280,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: AppColors.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.zero,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (n.icon != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(n.icon!, size: 16, color: accent),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (n.title != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                n.title!,
                                style: context.txt.bodyEmphasis.copyWith(
                                  color: accent,
                                ),
                              ),
                            ),
                          Text(
                            n.message,
                            style: context.txt.body.copyWith(height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    if (n.dismissible)
                      GestureDetector(
                        onTap: _dismiss,
                        child: Icon(
                          WaydirIconsRegular.x,
                          size: 14,
                          color: AppColors.fgMuted,
                        ),
                      ),
                  ],
                ),
              ),
              if (n.applyToAllLabel != null)
                _ApplyToAllCheckbox(
                  label: n.applyToAllLabel!,
                  value: _applyToAll,
                  onChanged: (value) => setState(() => _applyToAll = value),
                ),
              if (n.actions.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    12,
                    n.applyToAllLabel != null ? 6 : 0,
                    12,
                    8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: n.actions.map((action) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: _ActionButton(
                          action: action,
                          onDismiss: _dismiss,
                          applyToAll: _applyToAll,
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApplyToAllCheckbox extends StatefulWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ApplyToAllCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_ApplyToAllCheckbox> createState() => _ApplyToAllCheckboxState();
}

class _ApplyToAllCheckboxState extends State<_ApplyToAllCheckbox> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = _hovered ? AppColors.fg : AppColors.fgMuted;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => widget.onChanged(!widget.value),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: widget.value ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(
                    color: widget.value
                        ? AppColors.accent
                        : AppColors.borderColor,
                  ),
                ),
                child: widget.value
                    ? Icon(
                        WaydirIconsRegular.check,
                        size: 10,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  widget.label,
                  style: context.txt.row.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final NotificationAction action;
  final VoidCallback onDismiss;
  final bool applyToAll;

  const _ActionButton({
    required this.action,
    required this.onDismiss,
    required this.applyToAll,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.action.color ?? AppColors.accent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {
          final onTapWithApplyToAll = widget.action.onTapWithApplyToAll;
          if (onTapWithApplyToAll != null) {
            onTapWithApplyToAll(widget.applyToAll);
          } else {
            widget.action.onTap();
          }
          if (widget.action.dismissOnTap) widget.onDismiss();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _hovered ? color.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: _hovered ? color : AppColors.borderColor),
          ),
          child: Text(
            widget.action.label,
            style: context.txt.rowEmphasis.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}
