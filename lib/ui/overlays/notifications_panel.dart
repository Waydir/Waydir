import 'package:flutter/material.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';
import 'package:signals/signals_flutter.dart';
import '../../core/models/app_notification.dart';
import '../../i18n/strings.g.dart';
import '../../utils/format.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import 'notification_store.dart';
import 'popup_overlay.dart';

void showNotificationsPanel({
  required BuildContext context,
  required Offset position,
  required NotificationStore store,
}) {
  showPopup(
    context: context,
    position: position,
    width: 360,
    autoDismiss: true,
    builder: (_) => _NotificationsPanelBody(store: store),
  );
}

class _NotificationsPanelBody extends StatelessWidget {
  final NotificationStore store;

  const _NotificationsPanelBody({required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      constraints: const BoxConstraints(maxHeight: 520),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Icon(
                  WaydirIconsRegular.bell,
                  size: 16,
                  color: AppColors.fgMuted,
                ),
                const SizedBox(width: 8),
                Text(t.notifications.title, style: context.txt.dialogTitle),
                const Spacer(),
                SignalBuilder(
                  builder: (context) {
                    final has = store.history.value.any((n) => n.dismissible);
                    if (!has) return const SizedBox.shrink();

                    return _ClearButton(onTap: () => store.clearHistory());
                  },
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: AppColors.bgDivider),
          SignalBuilder(
            builder: (context) {
              final items = store.history.value;
              if (items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    t.notifications.empty,
                    style: context.txt.body.copyWith(color: AppColors.fgSubtle),
                  ),
                );
              }
              final reversed = items.reversed.toList();

              return Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: reversed.length,
                  separatorBuilder: (_, _) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.bgDivider,
                    ),
                  ),
                  itemBuilder: (_, i) => _NotificationTile(
                    notification: reversed[i],
                    onRemove: () => store.removeFromHistory(reversed[i].id),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ClearButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ClearButton({required this.onTap});

  @override
  State<_ClearButton> createState() => _ClearButtonState();
}

class _ClearButtonState extends State<_ClearButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          t.notifications.clear,
          style: context.txt.row.copyWith(
            color: _hovered ? AppColors.accentHover : AppColors.accent,
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatefulWidget {
  final AppNotification notification;
  final VoidCallback onRemove;

  const _NotificationTile({required this.notification, required this.onRemove});

  @override
  State<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<_NotificationTile> {
  bool _hovered = false;
  bool _applyToAll = false;

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final accent = n.accentColor ?? AppColors.accent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        color: _hovered ? AppColors.bgHover : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (n.icon != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(n.icon!, size: 14, color: accent),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (n.title != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        n.title!,
                        style: context.txt.rowEmphasis.copyWith(color: accent),
                      ),
                    ),
                  Text(
                    n.message,
                    style: context.txt.row.copyWith(height: 1.35),
                  ),
                  if (n.applyToAllLabel != null) ...[
                    const SizedBox(height: 7),
                    _InlineCheckbox(
                      label: n.applyToAllLabel!,
                      value: _applyToAll,
                      onChanged: (value) => setState(() => _applyToAll = value),
                    ),
                  ],
                  if (n.actions.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: n.actions
                          .map(
                            (action) => _PanelActionButton(
                              action: action,
                              applyToAll: _applyToAll,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    formatTimeAgo(n.timestamp),
                    style: context.txt.caption.copyWith(
                      color: AppColors.fgSubtle,
                    ),
                  ),
                ],
              ),
            ),
            if (_hovered && n.dismissible)
              GestureDetector(
                onTap: widget.onRemove,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6, top: 2),
                  child: Icon(
                    WaydirIconsRegular.x,
                    size: 12,
                    color: AppColors.fgMuted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InlineCheckbox extends StatefulWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _InlineCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_InlineCheckbox> createState() => _InlineCheckboxState();
}

class _InlineCheckboxState extends State<_InlineCheckbox> {
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
        child: Row(
          children: [
            Container(
              width: 13,
              height: 13,
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
                  ? Icon(WaydirIconsRegular.check, size: 9, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.label,
                style: context.txt.caption.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelActionButton extends StatefulWidget {
  final NotificationAction action;
  final bool applyToAll;

  const _PanelActionButton({required this.action, required this.applyToAll});

  @override
  State<_PanelActionButton> createState() => _PanelActionButtonState();
}

class _PanelActionButtonState extends State<_PanelActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.action.color ?? AppColors.accent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
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
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _hovered ? color.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: _hovered ? color : AppColors.borderColor),
          ),
          child: Text(
            widget.action.label,
            style: context.txt.caption.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}
