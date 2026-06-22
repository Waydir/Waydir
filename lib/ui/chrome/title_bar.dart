import 'dart:io' show Platform, Process, ProcessStartMode;

import '../window/move_window.dart';
import '../window/window_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';

import '../../app/app_info.dart';
import '../../app/waydir_app.dart';
import '../../core/keyboard/keyboard_shortcuts.dart';
import '../../features/command_palette/command_palette_launcher.dart';
import '../../features/help/changelog_dialog.dart';
import '../../features/help/help_dialog.dart';
import '../../features/plugins/plugin_icons.dart';
import '../../features/plugins/plugin_models.dart';
import '../../features/settings/keybindings_help_view.dart';
import '../../features/settings/panes/about_pane.dart';
import '../../features/settings/panes/diagnostics_pane.dart';
import '../../features/settings/panes/plugins_pane.dart';
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

void _openInAppTutorial() {
  final ctx = waydirNavigatorKey.currentContext;
  if (ctx != null) showHelpDialog(ctx);
}

void _openChangelog() {
  final ctx = waydirNavigatorKey.currentContext;
  if (ctx != null) showChangelogDialog(ctx);
}

void _openPlugins() {
  final ctx = waydirNavigatorKey.currentContext;
  if (ctx != null) showPluginsDialog(ctx);
}

void _openDiagnostics() {
  final ctx = waydirNavigatorKey.currentContext;
  if (ctx != null) showDiagnosticsDialog(ctx);
}

void _openAbout() {
  final ctx = waydirNavigatorKey.currentContext;
  if (ctx != null) showWaydirAboutDialog(ctx);
}

void _openUrl(String url) {
  final cmd = Platform.isWindows
      ? 'explorer'
      : Platform.isMacOS
      ? 'open'
      : 'xdg-open';
  Process.start(cmd, [url], mode: ProcessStartMode.detached);
}

void _openRepository() {
  _openUrl('https://github.com/Waydir/Waydir');
}

void _openIssue() {
  _openUrl('https://github.com/Waydir/Waydir/issues/new');
}

class TitleBar extends StatelessWidget {
  final Widget child;
  final Widget? menuTrailing;
  final List<PlatformMenu> platformMenus;
  final List<PluginContribution> pluginContributions;
  final ValueChanged<String>? onPluginAction;

  const TitleBar({
    super.key,
    required this.child,
    this.menuTrailing,
    this.platformMenus = const [],
    this.pluginContributions = const [],
    this.onPluginAction,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isMacOS) {
      return PlatformMenuBar(
        menus: _platformMenus(),
        child: Column(
          children: [
            _TitleBarRow(
              menuTrailing: menuTrailing,
              pluginContributions: pluginContributions,
              onPluginAction: onPluginAction,
            ),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Column(
      children: [
        _TitleBarRow(
          menuTrailing: menuTrailing,
          pluginContributions: pluginContributions,
          onPluginAction: onPluginAction,
        ),
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
                label: t.preferences.categories.about,
                onSelected: _openAbout,
              ),
              PlatformMenuItem(
                label: t.appMenu.changelog,
                onSelected: _openChangelog,
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
      _platformPluginsMenu(),
      _platformHelpMenu(),
    ];
  }

  PlatformMenu _platformPluginsMenu() {
    return PlatformMenu(
      label: t.preferences.plugins.title,
      menus: [
        PlatformMenuItem(
          label: t.appMenu.managePlugins,
          onSelected: _openPlugins,
        ),
        if (pluginContributions.isNotEmpty)
          PlatformMenuItemGroup(
            members: [
              for (final c in pluginContributions)
                PlatformMenuItem(
                  label: c.title,
                  onSelected: onPluginAction == null
                      ? null
                      : () => onPluginAction!(c.fullActionId),
                ),
            ],
          ),
      ],
    );
  }

  PlatformMenu _platformHelpMenu() {
    return PlatformMenu(
      label: t.appMenu.help,
      menus: [
        PlatformMenuItem(
          label: t.help.menuLabel,
          shortcut: const SingleActivator(
            LogicalKeyboardKey.slash,
            meta: true,
            shift: true,
          ),
          onSelected: _openInAppTutorial,
        ),
        PlatformMenuItem(
          label: t.keybindings.menuLabel,
          shortcut: const SingleActivator(LogicalKeyboardKey.slash, meta: true),
          onSelected: _openKeybindingsHelp,
        ),
        PlatformMenuItem(
          label: t.preferences.diagnostics.title,
          onSelected: _openDiagnostics,
        ),
        PlatformMenuItemGroup(
          members: [
            PlatformMenuItem(
              label: t.appMenu.repository,
              onSelected: _openRepository,
            ),
            PlatformMenuItem(
              label: t.appMenu.createIssue,
              onSelected: _openIssue,
            ),
          ],
        ),
      ],
    );
  }
}

class _TitleBarRow extends StatelessWidget {
  final Widget? menuTrailing;
  final List<PluginContribution> pluginContributions;
  final ValueChanged<String>? onPluginAction;

  const _TitleBarRow({
    this.menuTrailing,
    required this.pluginContributions,
    required this.onPluginAction,
  });

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
            _MenuBar(
              trailing: menuTrailing,
              pluginContributions: pluginContributions,
              onPluginAction: onPluginAction,
            ),
          ],
          Expanded(
            child: Stack(
              children: [
                const MoveWindow(),
                const Center(child: _CommandPaletteButton()),
              ],
            ),
          ),
          if (!Platform.isMacOS) const _WindowButtons(),
        ],
      ),
    );
  }
}

class _MenuBar extends StatelessWidget {
  final Widget? trailing;
  final List<PluginContribution> pluginContributions;
  final ValueChanged<String>? onPluginAction;

  const _MenuBar({
    this.trailing,
    required this.pluginContributions,
    required this.onPluginAction,
  });

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
              label: t.preferences.categories.about,
              action: 'about',
            ),
            ContextMenuItem(
              icon: WaydirIconsRegular.notebook,
              label: t.appMenu.changelog,
              action: 'changelog',
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
              case 'about':
                _openAbout();
              case 'changelog':
                _openChangelog();
              case 'quit':
                SystemNavigator.pop();
            }
          },
        ),
        ?trailing,
        TitleMenuButton(
          label: t.preferences.plugins.title,
          items: [
            ContextMenuItem(
              icon: WaydirIconsRegular.gearSix,
              label: t.appMenu.managePlugins,
              action: 'manage_plugins',
            ),
            if (pluginContributions.isNotEmpty) ContextMenuItem.divider,
            for (final c in pluginContributions)
              ContextMenuItem(
                icon: pluginGlyph(c.icon),
                label: c.title,
                action: c.fullActionId,
                iconPath: c.iconPath,
                shortcut: c.shortcut,
              ),
          ],
          onSelect: (action) {
            if (action == 'manage_plugins') {
              _openPlugins();
            } else if (action.startsWith('plugin:')) {
              onPluginAction?.call(action);
            }
          },
        ),
        TitleMenuButton(
          label: t.appMenu.help,
          items: [
            ContextMenuItem(
              icon: WaydirIconsRegular.info,
              label: t.help.menuLabel,
              action: 'tutorial',
              shortcut: '?',
            ),
            ContextMenuItem(
              icon: WaydirIconsRegular.keyboard,
              label: t.keybindings.menuLabel,
              action: 'keybindings',
            ),
            ContextMenuItem(
              icon: WaydirIconsRegular.bug,
              label: t.preferences.diagnostics.title,
              action: 'diagnostics',
            ),
            ContextMenuItem.divider,
            ContextMenuItem(
              icon: WaydirIconsRegular.gitBranch,
              label: t.appMenu.repository,
              action: 'repository',
            ),
            ContextMenuItem(
              icon: WaydirIconsRegular.arrowSquareOut,
              label: t.appMenu.createIssue,
              action: 'issue',
            ),
          ],
          onSelect: (action) {
            switch (action) {
              case 'tutorial':
                _openInAppTutorial();
              case 'keybindings':
                _openKeybindingsHelp();
              case 'diagnostics':
                _openDiagnostics();
              case 'repository':
                _openRepository();
              case 'issue':
                _openIssue();
            }
          },
        ),
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

class _CommandPaletteButton extends StatefulWidget {
  const _CommandPaletteButton();

  @override
  State<_CommandPaletteButton> createState() => _CommandPaletteButtonState();
}

class _CommandPaletteButtonState extends State<_CommandPaletteButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final binding = AppShortcuts.getById('command_palette').displayKeys;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: t.commandPalette.title,
        child: GestureDetector(
          onTap: () => CommandPaletteLauncher.instance.open?.call(),
          child: Container(
            height: 22,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: _hovered ? AppColors.bgHover : AppColors.bgInput,
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  WaydirIconsRegular.magnifyingGlass,
                  size: 11,
                  color: AppColors.fgSubtle,
                ),
                const SizedBox(width: 7),
                Text(binding, style: context.txt.keyCap),
              ],
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
