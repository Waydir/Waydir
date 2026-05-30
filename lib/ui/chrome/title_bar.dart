import 'dart:io' show Platform;

import '../window/move_window.dart';
import '../window/window_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';

import '../../app/app_info.dart';
import '../../app/waydir_app.dart';
import '../../features/help/help_dialog.dart';
import '../../features/settings/keybindings_help_view.dart';
import '../../features/settings/preferences_view.dart';
import '../../i18n/strings.g.dart';
import '../overlays/context_menu.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';

void _openPreferences() {
  final ctx = waydirNavigatorKey.currentContext;
  if (ctx != null) showPreferencesDialog(ctx);
}

void _openKeybindingsHelp() {
  final ctx = waydirNavigatorKey.currentContext;
  if (ctx != null) showKeybindingsHelp(ctx);
}

void _openHelp() {
  final ctx = waydirNavigatorKey.currentContext;
  if (ctx != null) showHelpDialog(ctx);
}

class TitleBar extends StatelessWidget {
  final Widget child;
  final Widget? menuTrailing;
  final List<PlatformMenu> platformMenus;

  const TitleBar({
    super.key,
    required this.child,
    this.menuTrailing,
    this.platformMenus = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isMacOS) {
      return PlatformMenuBar(
        menus: _platformMenus(),
        child: Column(
          children: [
            _TitleBarRow(menuTrailing: menuTrailing),
            Expanded(child: child),
          ],
        ),
      );
    }
    return Column(
      children: [
        _TitleBarRow(menuTrailing: menuTrailing),
        Expanded(child: child),
      ],
    );
  }

  List<PlatformMenuItem> _platformMenus() {
    return [
      PlatformMenu(
        label: t.app.title,
        menus: [
          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: t.preferences.menuLabel,
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.comma,
                  meta: true,
                ),
                onSelected: _openPreferences,
              ),
            ],
          ),
          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: t.help.menuLabel,
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.slash,
                  meta: true,
                  shift: true,
                ),
                onSelected: _openHelp,
              ),
              PlatformMenuItem(
                label: t.keybindings.menuLabel,
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.slash,
                  meta: true,
                ),
                onSelected: _openKeybindingsHelp,
              ),
            ],
          ),
          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: t.appMenu.quit,
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyQ,
                  meta: true,
                ),
                onSelected: SystemNavigator.pop,
              ),
            ],
          ),
        ],
      ),
      ...platformMenus,
    ];
  }
}

class _TitleBarRow extends StatelessWidget {
  final Widget? menuTrailing;

  const _TitleBarRow({this.menuTrailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.bgSidebar,
        border: Border(bottom: BorderSide(color: AppColors.bgDivider)),
      ),
      child: Row(
        children: [
          SizedBox(width: Platform.isMacOS ? 76 : 19),
          if (!Platform.isMacOS) ...[
            Image.asset(AppInfo.iconAsset, width: 13, height: 13),
            const SizedBox(width: 12),
          ],
          _MenuBar(trailing: menuTrailing),
          const Expanded(child: MoveWindow()),
          if (!Platform.isMacOS) const _WindowButtons(),
        ],
      ),
    );
  }
}

class _MenuBar extends StatelessWidget {
  final Widget? trailing;

  const _MenuBar({this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TitleMenuButton(
          label: t.app.title,
          items: [
            ContextMenuItem(
              icon: WaydirIconsRegular.gearSix,
              label: t.preferences.menuLabel,
              action: 'preferences',
            ),
            ContextMenuItem(
              icon: WaydirIconsRegular.info,
              label: t.help.menuLabel,
              action: 'help',
              shortcut: '?',
            ),
            ContextMenuItem(
              icon: WaydirIconsRegular.keyboard,
              label: t.keybindings.menuLabel,
              action: 'keybindings',
            ),
            ContextMenuItem.divider,
            ContextMenuItem(
              icon: WaydirIconsRegular.signOut,
              label: t.appMenu.quit,
              action: 'quit',
            ),
          ],
          onSelect: (action) {
            switch (action) {
              case 'preferences':
                _openPreferences();
              case 'help':
                _openHelp();
              case 'keybindings':
                _openKeybindingsHelp();
              case 'quit':
                SystemNavigator.pop();
            }
          },
        ),
        ?trailing,
      ],
    );
  }
}

class TitleMenuButton extends StatefulWidget {
  final String label;
  final List<ContextMenuItem> items;
  final void Function(String action) onSelect;

  const TitleMenuButton({
    super.key,
    required this.label,
    required this.items,
    required this.onSelect,
  });

  @override
  State<TitleMenuButton> createState() => _TitleMenuButtonState();
}

class _TitleMenuButtonState extends State<TitleMenuButton> {
  final _key = GlobalKey();
  bool _hovered = false;

  void _open() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset(0, box.size.height));
    showContextMenu(
      context: context,
      position: pos,
      items: widget.items,
      onSelect: widget.onSelect,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        key: _key,
        onTap: _open,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 24,
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.bgHover : Colors.transparent,
            borderRadius: BorderRadius.zero,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: context.txt.captionSmall.copyWith(
              color: _hovered ? AppColors.fg : AppColors.fgMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _WindowButtons extends StatelessWidget {
  const _WindowButtons();

  static final _iconColor = AppColors.fgMuted;
  static final _iconHoverColor = AppColors.fg;

  static final _btnColors = WindowButtonColors(
    iconNormal: _iconColor,
    iconMouseOver: _iconHoverColor,
    mouseOver: AppColors.bgHover,
    mouseDown: AppColors.bgSurface,
  );

  static final _closeColors = WindowButtonColors(
    iconNormal: _iconColor,
    iconMouseOver: Colors.white,
    mouseOver: AppColors.windowCloseHover,
    mouseDown: AppColors.windowClosePressed,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MinimizeWindowButton(colors: _btnColors, animate: false),
        MaximizeWindowButton(colors: _btnColors, animate: false),
        CloseWindowButton(colors: _closeColors, animate: false),
      ],
    );
  }
}
