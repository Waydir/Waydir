import 'package:signals/signals.dart';

import '../../core/database/app_database.dart';
import '../../core/settings/settings_store.dart';

/// Sidebar section ids in their default order. Bookmarks reorder through
/// [BookmarkStore]; the other three also persist per-item order/visibility.
const sidebarSectionFavorites = 'favorites';
const sidebarSectionDevices = 'devices';
const sidebarSectionNetwork = 'network';
const sidebarSectionBookmarks = 'bookmarks';

const _defaultSectionOrder = [
  sidebarSectionFavorites,
  sidebarSectionDevices,
  sidebarSectionNetwork,
  sidebarSectionBookmarks,
];

const _sectionScope = 'section';

/// User overrides for the sidebar layout: order and visibility of sections and
/// of items within the favorites/devices/network sections. Backed by the
/// `sidebar_prefs` table and exposed as signals so the sidebar reacts to edits.
class SidebarStore {
  static final SidebarStore instance = SidebarStore._();

  SidebarStore._();

  final editing = signal<bool>(false);
  final sectionOrder = signal<List<String>>(_defaultSectionOrder);
  final hiddenSections = signal<Set<String>>(const {});
  final itemOrder = signal<Map<String, List<String>>>(const {});
  final hiddenItems = signal<Map<String, Set<String>>>(const {});

  AppDatabase get _db => SettingsStore.instance.db;

  Future<void> load() async {
    final rows = await _db.getSidebarPrefs();

    final sectionRows = rows.where((r) => r.scope == _sectionScope).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final storedSections = sectionRows
        .map((r) => r.itemKey)
        .where(_defaultSectionOrder.contains)
        .toList();
    sectionOrder.value = [
      ...storedSections,
      ..._defaultSectionOrder.where((s) => !storedSections.contains(s)),
    ];
    hiddenSections.value = {
      for (final r in sectionRows)
        if (r.hidden) r.itemKey,
    };

    final order = <String, List<String>>{};
    final hidden = <String, Set<String>>{};
    for (final scope in _defaultSectionOrder) {
      if (scope == sidebarSectionBookmarks) continue;
      final scopeRows = rows.where((r) => r.scope == scope).toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      order[scope] = scopeRows.map((r) => r.itemKey).toList();
      hidden[scope] = {
        for (final r in scopeRows)
          if (r.hidden) r.itemKey,
      };
    }
    itemOrder.value = order;
    hiddenItems.value = hidden;
  }

  void toggleEditing() => editing.value = !editing.value;

  bool isSectionHidden(String id) => hiddenSections.value.contains(id);

  bool isItemHidden(String scope, String key) =>
      hiddenItems.value[scope]?.contains(key) ?? false;

  Future<void> reorderSections(int oldIndex, int newIndex) async {
    final next = _moved(sectionOrder.value, oldIndex, newIndex);
    if (next == null) return;
    sectionOrder.value = next;
    await _db.setSidebarOrder(_sectionScope, next);
  }

  Future<void> setSectionHidden(String id, bool hidden) async {
    final next = {...hiddenSections.value};
    if (hidden) {
      next.add(id);
    } else {
      next.remove(id);
    }
    hiddenSections.value = next;
    // Materialize the full order so a lone hidden row can't reorder sections on
    // the next load (rows without an orderIndex would otherwise sort first).
    await _db.setSidebarOrder(_sectionScope, sectionOrder.value);
    final idx = sectionOrder.value.indexOf(id);
    await _db.setSidebarPref(
      _sectionScope,
      id,
      orderIndex: idx < 0 ? 0 : idx,
      hidden: hidden,
    );
  }

  /// Projects [items] into the user's stored order for [scope]: known keys
  /// first (by stored position), then any unknown items in their incoming
  /// order. Does not filter hidden items — callers decide based on edit mode.
  List<T> orderItems<T>(String scope, List<T> items, String Function(T) keyOf) {
    final order = itemOrder.value[scope];
    if (order == null || order.isEmpty) return items;
    final pos = {for (var i = 0; i < order.length; i++) order[i]: i};
    final known = <T>[];
    final unknown = <T>[];
    for (final item in items) {
      (pos.containsKey(keyOf(item)) ? known : unknown).add(item);
    }
    known.sort((a, b) => pos[keyOf(a)]!.compareTo(pos[keyOf(b)]!));
    return [...known, ...unknown];
  }

  Future<void> reorderItems(
    String scope,
    int oldIndex,
    int newIndex,
    List<String> currentKeys,
  ) async {
    final next = _moved(currentKeys, oldIndex, newIndex);
    if (next == null) return;
    final map = {...itemOrder.value};
    map[scope] = next;
    itemOrder.value = map;
    await _db.setSidebarOrder(scope, next);
  }

  Future<void> setItemHidden(
    String scope,
    String key,
    bool hidden,
    List<String> currentKeys,
  ) async {
    final map = {
      for (final e in hiddenItems.value.entries) e.key: {...e.value},
    };
    final bucket = map.putIfAbsent(scope, () => <String>{});
    if (hidden) {
      bucket.add(key);
    } else {
      bucket.remove(key);
    }
    hiddenItems.value = map;
    final order = {...itemOrder.value};
    order[scope] = currentKeys;
    itemOrder.value = order;
    // Persist the full order alongside the flag so a lone hidden row can't
    // reorder items on the next load.
    await _db.setSidebarOrder(scope, currentKeys);
    final idx = currentKeys.indexOf(key);
    await _db.setSidebarPref(
      scope,
      key,
      orderIndex: idx < 0 ? 0 : idx,
      hidden: hidden,
    );
  }

  /// [newIndex] is the post-removal target index, as supplied by
  /// `ReorderableListView.onReorderItem`.
  List<String>? _moved(List<String> source, int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= source.length) return null;
    var to = newIndex;
    if (to < 0) to = 0;
    if (to > source.length - 1) to = source.length - 1;
    if (to == oldIndex) return null;
    final list = [...source];
    final item = list.removeAt(oldIndex);
    list.insert(to, item);
    return list;
  }
}
