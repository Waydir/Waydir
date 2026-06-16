import 'package:waydir/ui/icons/waydir_icons.dart';
import '../../core/fs/file_sort.dart';
import '../../i18n/strings.g.dart';
import '../../ui/overlays/context_menu.dart';
import '../navigation/navigation_store.dart';
import 'file_view.dart';

const sortKeyActionPrefix = 'sort_key:';
const sortAscendingAction = 'sort_dir:asc';
const sortDescendingAction = 'sort_dir:desc';

List<ContextMenuItem> buildSortMenuItems(NavigationStore store) {
  final activeKey = store.sortKey.value;
  final ascending = store.sortAscending.value;
  final c = t.fileView.columns;
  ContextMenuItem keyItem(String label, SortKey key) => ContextMenuItem(
    icon: activeKey == key
        ? WaydirIconsRegular.check
        : WaydirIconsRegular.caretUpDown,
    label: label,
    action: '$sortKeyActionPrefix${sortKeyToString(key)}',
  );

  return [
    keyItem(c.name, SortKey.name),
    for (final col in orderedColumns())
      keyItem(fileColumnLabel(col), fileColumnSortKey(col)),
    ContextMenuItem.divider,
    ContextMenuItem(
      icon: ascending ? WaydirIconsRegular.check : WaydirIconsRegular.caretUp,
      label: t.menu.sortAscending,
      action: sortAscendingAction,
    ),
    ContextMenuItem(
      icon: ascending ? WaydirIconsRegular.caretDown : WaydirIconsRegular.check,
      label: t.menu.sortDescending,
      action: sortDescendingAction,
    ),
  ];
}

ContextMenuItem sortMenuParent(NavigationStore store) => ContextMenuItem(
  icon: WaydirIconsRegular.caretUpDown,
  label: t.menu.sortBy,
  action: 'sort_by',
  children: buildSortMenuItems(store),
);

bool handleSortMenuAction(NavigationStore store, String action) {
  if (action.startsWith(sortKeyActionPrefix)) {
    store.setSortKey(
      sortKeyFromString(action.substring(sortKeyActionPrefix.length)),
    );

    return true;
  }
  switch (action) {
    case sortAscendingAction:
      store.setSortAscending(true);

      return true;
    case sortDescendingAction:
      store.setSortAscending(false);

      return true;
  }

  return false;
}
