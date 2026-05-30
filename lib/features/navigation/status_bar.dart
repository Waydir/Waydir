import 'package:flutter/material.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';
import 'package:signals/signals_flutter.dart';
import 'navigation_store.dart';
import '../../app/app_info.dart';
import '../../core/update/update_store.dart';
import '../../features/update/update_dialog.dart';
import '../../core/settings/settings_store.dart';
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
          SignalBuilder(
            builder: (context) {
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
            },
          ),
          const Spacer(),
          const _StatusZoomControl(),
          const SizedBox(width: 8),
          _StatusVersion(),
          const SizedBox(width: 8),
          _StatusNotificationsButton(notificationStore: notificationStore),
        ],
      ),
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

class _StatusZoomControl extends StatelessWidget {
  const _StatusZoomControl();

  @override
  Widget build(BuildContext context) {
    final settings = SettingsStore.instance;
    return SignalBuilder(
      builder: (context) {
        final scale = settings.fileListScale.value;
        final percent = (scale * 100).round();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ZoomGlyphButton(
              glyph: '−',
              tooltip: t.statusBar.zoomOut,
              enabled: scale > SettingsStore.fileListScaleMin,
              onTap: settings.decreaseFileListScale,
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: settings.resetFileListScale,
                behavior: HitTestBehavior.opaque,
                child: Tooltip(
                  message: t.statusBar.zoomReset,
                  child: Container(
                    width: 38,
                    height: 20,
                    alignment: Alignment.center,
                    child: Text('$percent%', style: context.txt.muted),
                  ),
                ),
              ),
            ),
            _ZoomGlyphButton(
              glyph: '+',
              tooltip: t.statusBar.zoomIn,
              enabled: scale < SettingsStore.fileListScaleMax,
              onTap: settings.increaseFileListScale,
            ),
          ],
        );
      },
    );
  }
}

class _ZoomGlyphButton extends StatefulWidget {
  final String glyph;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;

  const _ZoomGlyphButton({
    required this.glyph,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_ZoomGlyphButton> createState() => _ZoomGlyphButtonState();
}

class _ZoomGlyphButtonState extends State<_ZoomGlyphButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = !widget.enabled
        ? AppColors.fgSubtle
        : (_hovered ? AppColors.fg : AppColors.fgMuted);
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.enabled ? widget.onTap : null,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hovered && widget.enabled
                  ? AppColors.bgHover
                  : Colors.transparent,
              borderRadius: BorderRadius.zero,
            ),
            child: Text(
              widget.glyph,
              style: context.txt.rowEmphasis.copyWith(color: color),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusVersion extends StatefulWidget {
  @override
  State<_StatusVersion> createState() => _StatusVersionState();
}

class _StatusVersionState extends State<_StatusVersion> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final available = UpdateStore.instance.updateAvailable.value;
        final label = '${t.app.title} ${AppInfo.versionLabel.value}';
        final latest = UpdateStore.instance.latestRelease.value?.version;
        final color = available
            ? AppColors.warning
            : (_hover ? AppColors.fg : AppColors.fgMuted);
        final tooltip = available && latest != null
            ? t.update.tooltipAvailable(version: latest)
            : t.update.tooltipUpToDate;

        final inner = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: context.txt.muted.copyWith(
                color: color,
                fontWeight: available ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (available) ...[
              const SizedBox(width: 4),
              Icon(WaydirIconsRegular.arrowUp, size: 11, color: color),
            ],
          ],
        );

        return Tooltip(
          message: tooltip,
          waitDuration: const Duration(milliseconds: 400),
          child: MouseRegion(
            cursor: available ? SystemMouseCursors.click : MouseCursor.defer,
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            child: GestureDetector(
              onTap: available ? () => showUpdateDialog(context) : null,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: inner,
              ),
            ),
          ),
        );
      },
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
    return SignalBuilder(
      builder: (context) {
        final count = notificationStore.history.value.length;
        return _StatusIconButton(
          icon: WaydirIconsRegular.bell,
          tooltip: t.toolbar.notifications,
          badge: count,
          onTap: () => _open(context),
        );
      },
    );
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
              borderRadius: BorderRadius.zero,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(child: Icon(widget.icon, size: 13, color: iconColor)),
                if (widget.badge > 0)
                  Positioned(
                    right: 4,
                    top: 3,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.zero,
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
