import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:signals/signals_flutter.dart';
import 'navigation_store.dart';
import '../../app/app_info.dart';
import '../../core/models/file_operation.dart';
import '../operations/operation_store.dart';
import '../../ui/overlays/notification_store.dart';
import '../../ui/overlays/notifications_panel.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../i18n/strings.g.dart';

class StatusBar extends StatelessWidget {
  final NavigationStore store;
  final OperationStore operationStore;
  final NotificationStore notificationStore;

  const StatusBar({
    super.key,
    required this.store,
    required this.operationStore,
    required this.notificationStore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.bgStatus,
        border: Border(top: BorderSide(color: AppColors.bgDivider)),
      ),
      child: Row(
        children: [
          Watch((context) {
            final total = store.totalItems.value;
            final folders = store.folderCount.value;
            final files = store.fileCount.value;
            final selected = store.selectedCount.value;

            return Row(
              children: [
                _statusText(context, t.statusBar.items(count: total)),
                _sep(context),
                _statusText(
                  context,
                  '${t.statusBar.folders(count: folders)}, ${t.statusBar.files(count: files)}',
                ),
                if (selected > 0) ...[
                  _sep(context),
                  Text(
                    t.statusBar.selected(count: selected),
                    style: context.txt.rowEmphasis.copyWith(
                      color: AppColors.fgAccent,
                    ),
                  ),
                ],
              ],
            );
          }),
          const Spacer(),
          Watch((context) {
            final tasks = operationStore.tasks.value;
            final active = tasks.where(
              (t) =>
                  t.status == TaskStatus.running ||
                  t.status == TaskStatus.preparing ||
                  t.status == TaskStatus.cancelling,
            );

            if (active.isEmpty) {
              return _statusText(
                context,
                '${AppInfo.name} ${AppInfo.versionLabel.value}',
              );
            }

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final task in active) ...[
                  _taskChip(context, task),
                  const SizedBox(width: 8),
                ],
                _statusText(
                  context,
                  '${AppInfo.name} ${AppInfo.versionLabel.value}',
                ),
              ],
            );
          }),
          const SizedBox(width: 8),
          _StatusNotificationsButton(notificationStore: notificationStore),
        ],
      ),
    );
  }

  Widget _taskChip(BuildContext context, FileTask task) {
    final pct = task.totalFiles > 0
        ? '${(task.progress.clamp(0.0, 1.0) * 100).round()}%'
        : null;

    final icon = switch (task.type) {
      TaskType.copy => PhosphorIconsRegular.copy,
      TaskType.move => PhosphorIconsRegular.arrowRight,
      TaskType.delete => PhosphorIconsRegular.trash,
      TaskType.trash => PhosphorIconsRegular.trashSimple,
      TaskType.extract => PhosphorIconsRegular.archive,
      TaskType.compress => PhosphorIconsRegular.fileZip,
      TaskType.archiveEdit => PhosphorIconsRegular.archive,
    };

    final label = TaskLabel.title(task);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PhosphorIcon(icon, size: 11, color: AppColors.fgAccent),
        const SizedBox(width: 4),
        Text(
          label,
          style: context.txt.rowEmphasis.copyWith(color: AppColors.fgAccent),
          overflow: TextOverflow.ellipsis,
        ),
        if (pct != null) ...[
          const SizedBox(width: 4),
          Text(pct, style: context.txt.muted),
        ],
        if (task.conflicts.isNotEmpty) ...[
          const SizedBox(width: 6),
          PhosphorIcon(
            PhosphorIconsRegular.warning,
            size: 11,
            color: AppColors.warning,
          ),
          const SizedBox(width: 3),
          Text(
            '${task.conflicts.length}',
            style: context.txt.row.copyWith(color: AppColors.warning),
          ),
        ],
      ],
    );
  }

  static Widget _statusText(BuildContext context, String text) {
    return Text(text, style: context.txt.muted);
  }

  static Widget _sep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '|',
        style: context.txt.row.copyWith(color: AppColors.fgSubtle),
      ),
    );
  }
}

class _StatusNotificationsButton extends StatelessWidget {
  final NotificationStore notificationStore;

  const _StatusNotificationsButton({required this.notificationStore});

  void _open(BuildContext context) {
    final box = context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset(0, box.size.height));
    showNotificationsPanel(
      context: context,
      position: offset,
      store: notificationStore,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final count = notificationStore.history.value.length;
      return _StatusIconButton(
        icon: PhosphorIconsRegular.bell,
        tooltip: t.toolbar.notifications,
        badge: count,
        onTap: () => _open(context),
      );
    });
  }
}

class _StatusIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final int badge;
  final VoidCallback onTap;

  const _StatusIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badge = 0,
  });

  @override
  State<_StatusIconButton> createState() => _StatusIconButtonState();
}

class _StatusIconButtonState extends State<_StatusIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final iconColor = _hovered ? AppColors.fg : AppColors.fgMuted;
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 24,
            height: 20,
            margin: const EdgeInsets.only(left: 2),
            decoration: BoxDecoration(
              color: _hovered ? AppColors.bgHover : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: PhosphorIcon(widget.icon, size: 13, color: iconColor),
                ),
                if (widget.badge > 0)
                  Positioned(
                    right: 4,
                    top: 3,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
