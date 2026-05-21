import 'package:flutter/material.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';
import 'package:signals/signals_flutter.dart';
import '../../core/models/file_operation.dart';
import '../../ui/overlays/popup_overlay.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../i18n/strings.g.dart';
import '../../utils/format.dart';
import 'conflict_dialog.dart' show showErrorListDialog;
import 'operation_store.dart';

void showOperationsPanel({
  required BuildContext context,
  required Offset position,
  required OperationStore operationStore,
}) {
  showPopup(
    context: context,
    position: position,
    width: 380,
    autoDismiss: true,
    builder: (_) => _OperationsPanelBody(operationStore: operationStore),
  );
}

class _OperationsPanelBody extends StatelessWidget {
  final OperationStore operationStore;

  const _OperationsPanelBody({required this.operationStore});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
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
                  WaydirIconsRegular.clockClockwise,
                  size: 16,
                  color: AppColors.fgMuted,
                ),
                const SizedBox(width: 8),
                Text(t.operations.title, style: context.txt.dialogTitle),
                const Spacer(),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: AppColors.bgDivider),
          Watch((context) {
            final ops = operationStore.tasks.value
                .where(
                  (task) =>
                      task.status != TaskStatus.completed &&
                      task.status != TaskStatus.failed &&
                      task.status != TaskStatus.cancelled,
                )
                .toList();
            if (ops.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  t.operations.noActive,
                  style: context.txt.body.copyWith(color: AppColors.fgSubtle),
                ),
              );
            }
            return Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: ops.length,
                separatorBuilder: (_, _) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.bgDivider,
                  ),
                ),
                itemBuilder: (_, i) =>
                    _TaskTile(task: ops[i], operationStore: operationStore),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final FileTask task;
  final OperationStore operationStore;

  const _TaskTile({required this.task, required this.operationStore});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (task.status) {
      TaskStatus.queued => AppColors.neutral,
      TaskStatus.preparing => AppColors.accent,
      TaskStatus.waitingConflicts => AppColors.warning,
      TaskStatus.running => AppColors.accent,
      TaskStatus.paused => AppColors.warning,
      TaskStatus.cancelling => AppColors.neutral,
      TaskStatus.completed => AppColors.success,
      TaskStatus.failed => AppColors.danger,
      TaskStatus.cancelled => AppColors.neutral,
    };

    final statusIcon = switch (task.status) {
      TaskStatus.queued => WaydirIconsRegular.clock,
      TaskStatus.preparing => WaydirIconsRegular.arrowsClockwise,
      TaskStatus.waitingConflicts => WaydirIconsRegular.warning,
      TaskStatus.running => WaydirIconsRegular.arrowsClockwise,
      TaskStatus.paused => WaydirIconsRegular.pause,
      TaskStatus.cancelling => WaydirIconsRegular.stop,
      TaskStatus.completed => WaydirIconsRegular.check,
      TaskStatus.failed => WaydirIconsRegular.x,
      TaskStatus.cancelled => WaydirIconsRegular.prohibit,
    };

    final isActive =
        task.status == TaskStatus.running ||
        task.status == TaskStatus.preparing ||
        task.status == TaskStatus.waitingConflicts ||
        task.status == TaskStatus.cancelling;

    final showProgress =
        task.status == TaskStatus.running ||
        task.status == TaskStatus.preparing ||
        task.status == TaskStatus.cancelling;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, size: 14, color: statusColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  TaskLabel.title(task),
                  style: context.txt.bodyEmphasis,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showProgress)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Text(
                    '${(task.progress * 100).round()}%',
                    style: context.txt.rowEmphasis.copyWith(color: statusColor),
                  ),
                ),
              if (isActive && task.status != TaskStatus.cancelling) ...[
                const SizedBox(width: 6),
                _CancelBtn(onTap: () => operationStore.cancelTask(task.id)),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            TaskLabel.subtitle(task),
            style: context.txt.bodyMuted,
            overflow: TextOverflow.ellipsis,
          ),
          if (showProgress) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.zero,
              child: LinearProgressIndicator(
                value: task.totalFiles > 0 ? task.progress : null,
                minHeight: 4,
                backgroundColor: AppColors.bgInput,
                valueColor: AlwaysStoppedAnimation(statusColor),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          TaskLabel.progressText(task),
                          style: context.txt.muted,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (task.status == TaskStatus.running &&
                          task.bytesPerSecond > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          formatSpeed(task.bytesPerSecond),
                          style: context.txt.muted.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (task.totalFiles > 0)
                  Text(
                    t.operations.filesCount(
                      processed: task.processedFiles,
                      count: task.totalFiles,
                    ),
                    style: context.txt.muted,
                  ),
              ],
            ),
          ],
          if (task.conflicts.isNotEmpty &&
              (task.status == TaskStatus.running ||
                  task.status == TaskStatus.waitingConflicts)) ...[
            const SizedBox(height: 6),
            Text(
              t.tasks.status.conflicts(count: task.conflicts.length),
              style: context.txt.row.copyWith(color: AppColors.warning),
            ),
          ],
          if (task.status == TaskStatus.completed &&
              task.errors.isNotEmpty) ...[
            const SizedBox(height: 3),
            MouseRegion(
              child: GestureDetector(
                onTap: () =>
                    showErrorListDialog(context: context, errors: task.errors),
                child: Text(
                  t.operations.errorsCount(count: task.errors.length),
                  style: context.txt.row.copyWith(color: AppColors.danger),
                ),
              ),
            ),
          ],
          if (task.status == TaskStatus.completed ||
              task.status == TaskStatus.failed ||
              task.status == TaskStatus.cancelled) ...[
            const SizedBox(height: 3),
            Text(
              task.endTime != null ? formatTimeAgo(task.endTime!) : '',
              style: context.txt.captionSmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _CancelBtn extends StatefulWidget {
  final VoidCallback onTap;

  const _CancelBtn({required this.onTap});

  @override
  State<_CancelBtn> createState() => _CancelBtnState();
}

class _CancelBtnState extends State<_CancelBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: t.dialog.cancel,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _hovered
                  ? AppColors.danger.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.zero,
            ),
            child: Icon(
              WaydirIconsRegular.x,
              size: 12,
              color: _hovered ? AppColors.danger : AppColors.fgMuted,
            ),
          ),
        ),
      ),
    );
  }
}
