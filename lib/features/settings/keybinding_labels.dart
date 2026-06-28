import 'package:flutter/widgets.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';

import '../../core/keyboard/keyboard_shortcuts.dart';
import '../../i18n/strings.g.dart';

const shortcutGroupOrder = ShortcutGroup.values;

final shortcutGroupMeta =
    <ShortcutGroup, ({String Function() title, IconData icon})>{
      ShortcutGroup.navigation: (
        title: () => t.keybindings.categories.navigation,
        icon: WaydirIconsRegular.compass,
      ),
      ShortcutGroup.quickLook: (
        title: () => t.keybindings.categories.quickLook,
        icon: WaydirIconsRegular.eye,
      ),
      ShortcutGroup.view: (
        title: () => t.keybindings.categories.view,
        icon: WaydirIconsRegular.eye,
      ),
      ShortcutGroup.tabs: (
        title: () => t.keybindings.categories.tabs,
        icon: WaydirIconsRegular.tabs,
      ),
      ShortcutGroup.panes: (
        title: () => t.keybindings.categories.panes,
        icon: WaydirIconsRegular.columns,
      ),
      ShortcutGroup.terminal: (
        title: () => t.keybindings.categories.terminal,
        icon: WaydirIconsRegular.terminal,
      ),
      ShortcutGroup.fileOps: (
        title: () => t.keybindings.categories.fileOps,
        icon: WaydirIconsRegular.copy,
      ),
      ShortcutGroup.selection: (
        title: () => t.keybindings.categories.selection,
        icon: WaydirIconsRegular.checkSquare,
      ),
      ShortcutGroup.search: (
        title: () => t.keybindings.categories.search,
        icon: WaydirIconsRegular.magnifyingGlass,
      ),
      ShortcutGroup.general: (
        title: () => t.keybindings.categories.general,
        icon: WaydirIconsRegular.gearSix,
      ),
      ShortcutGroup.plugins: (
        title: () => t.preferences.plugins.title,
        icon: WaydirIconsRegular.gearSix,
      ),
    };

String shortcutLabel(ShortcutDef s) => switch (s.id) {
  'open_item' => t.keybindings.openItem,
  'go_up' => t.keybindings.goUp,
  'go_back' => t.keybindings.goBack,
  'go_forward' => t.keybindings.goForward,
  'refresh' => t.keybindings.refresh,
  'focus_path' => t.keybindings.focusPath,
  'quick_look' => t.keybindings.quickLook,
  'quick_look_close' => t.keybindings.quickLookClose,
  'quick_look_prev_file' => t.keybindings.quickLookPrevFile,
  'quick_look_next_file' => t.keybindings.quickLookNextFile,
  'quick_look_prev_file_edit' => t.keybindings.quickLookPrevFileEdit,
  'quick_look_next_file_edit' => t.keybindings.quickLookNextFileEdit,
  'quick_look_save' => t.keybindings.quickLookSave,
  'cursor_up' => t.keybindings.cursorUp,
  'cursor_down' => t.keybindings.cursorDown,
  'page_up' => t.keybindings.pageUp,
  'page_down' => t.keybindings.pageDown,
  'home' => t.keybindings.home,
  'end' => t.keybindings.end,
  'new_tab' => t.keybindings.newTab,
  'close_tab' => t.keybindings.closeTab,
  'next_tab' => t.keybindings.nextTab,
  'prev_tab' => t.keybindings.prevTab,
  'switch_tab' => t.keybindings.switchTab,
  'jump_bookmark' => t.keybindings.jumpBookmark,
  'toggle_dual' => t.keybindings.toggleDual,
  'switch_pane' => t.keybindings.switchPane,
  'compare' => t.keybindings.compare,
  'compare_sync_right' => t.keybindings.compareSyncRight,
  'compare_sync_left' => t.keybindings.compareSyncLeft,
  'compare_exit' => t.keybindings.compareExit,
  'focus_terminal' => t.keybindings.focusTerminal,
  'toggle_terminal' => t.keybindings.toggleTerminal,
  'new_terminal_tab' => t.keybindings.newTerminalTab,
  'close_terminal_tab' => t.keybindings.closeTerminalTab,
  'insert_relative_paths' => t.keybindings.insertRelativePaths,
  'insert_absolute_paths' => t.keybindings.insertAbsolutePaths,
  'terminal_font_increase' => t.keybindings.terminalFontIncrease,
  'terminal_font_decrease' => t.keybindings.terminalFontDecrease,
  'terminal_font_reset' => t.keybindings.terminalFontReset,
  'file_list_zoom_in' => t.keybindings.fileListZoomIn,
  'file_list_zoom_out' => t.keybindings.fileListZoomOut,
  'file_list_zoom_reset' => t.keybindings.fileListZoomReset,
  'toggle_sidebar' => t.keybindings.toggleSidebar,
  'toggle_view' => t.keybindings.toggleView,
  'copy' => t.keybindings.copy,
  'cut' => t.keybindings.cut,
  'paste' => t.keybindings.paste,
  'duplicate' => t.keybindings.duplicate,
  'delete' => t.keybindings.delete,
  'delete_permanent' => t.keybindings.deletePermanent,
  'rename' => t.keybindings.rename,
  'new_folder' => t.keybindings.newFolder,
  'dual_copy' => t.keybindings.dualCopy,
  'dual_move' => t.keybindings.dualMove,
  'select_all' => t.keybindings.selectAll,
  'select_pattern' => t.keybindings.selectPattern,
  'deselect_all' => t.keybindings.deselectAll,
  'invert_selection' => t.keybindings.invertSelection,
  'toggle_select' => t.keybindings.toggleSelect,
  'save_selection' => t.keybindings.saveSelection,
  'load_selection' => t.keybindings.loadSelection,
  'compute_folder_size' => t.keybindings.computeFolderSize,
  'search' => t.keybindings.search,
  'recursive_search' => t.keybindings.recursiveSearch,
  'toggle_hidden' => t.menu.showHidden,
  'command_palette' => t.keybindings.commandPalette,
  'preferences' => t.keybindings.preferences,
  'help' => t.help.menuLabel,
  'close_search' => t.keybindings.closeSearch,
  _ => s.label(),
};
