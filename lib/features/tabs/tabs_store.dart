import 'package:signals/signals.dart';
import '../../core/platform/platform_paths.dart';
import '../navigation/navigation_store.dart';
import '../operations/operation_store.dart';
import 'tab_state.dart';

class TabSpec {
  final String path;
  final String? select;
  const TabSpec(this.path, [this.select]);
}

class TabsStore {
  final tabs = signal<List<TabState>>([]);
  final activeIndex = signal(0);
  late final activeTab = computed(() {
    final list = tabs.value;
    final idx = activeIndex.value;
    if (idx < 0 || idx >= list.length) {
      return list.first;
    }
    return list[idx];
  });

  final OperationStore operationStore;
  int _idCounter = 0;

  TabsStore({required this.operationStore, String? initialPath}) {
    addTab(initialPath ?? PlatformPaths.homePath);
  }

  TabsStore.fromPaths({
    required this.operationStore,
    required List<String> paths,
    int activeTabIndex = 0,
  }) {
    if (paths.isEmpty) {
      addTab(PlatformPaths.homePath);
      return;
    }
    for (final path in paths) {
      addTab(path, activate: false);
    }
    activeIndex.value = activeTabIndex.clamp(0, tabs.value.length - 1);
  }

  TabsStore.fromSpecs({
    required this.operationStore,
    required List<TabSpec> specs,
    int activeTabIndex = 0,
  }) {
    if (specs.isEmpty) {
      addTab(PlatformPaths.homePath);
      return;
    }
    for (final spec in specs) {
      addTab(spec.path, activate: false, select: spec.select);
    }
    activeIndex.value = activeTabIndex.clamp(0, tabs.value.length - 1);
  }

  void addTab(String path, {bool activate = true, String? select}) {
    final tab = TabState(
      id: '${_idCounter++}',
      store: NavigationStore(
        operationStore: operationStore,
        initialPath: path,
        initialSelect: select,
      ),
    );
    tabs.value = [...tabs.value, tab];
    if (activate) {
      activeIndex.value = tabs.value.length - 1;
    }
  }

  void closeTab(String id) {
    final list = tabs.value;
    final idx = list.indexWhere((t) => t.id == id);
    if (idx < 0) return;
    if (list.length <= 1) return;

    final tab = list[idx];
    tabs.value = List.of(list)..removeAt(idx);

    tab.store.dispose();

    final current = activeIndex.value;
    if (idx == current) {
      activeIndex.value = (idx < tabs.value.length)
          ? idx
          : tabs.value.length - 1;
    } else if (idx < current) {
      activeIndex.value = current - 1;
    }
  }

  void selectTab(int i) {
    if (i >= 0 && i < tabs.value.length) {
      activeIndex.value = i;
    }
  }

  void reorderTab(int from, int to) {
    final list = tabs.value;
    if (from < 0 || from >= list.length) return;
    if (to < 0 || to >= list.length) return;
    if (from == to) return;

    final activeId = activeTab.value.id;
    final next = List<TabState>.of(list);
    final tab = next.removeAt(from);
    next.insert(to, tab);
    tabs.value = next;
    activeIndex.value = next.indexWhere((t) => t.id == activeId);
  }

  void dispose() {
    for (final tab in tabs.value) {
      tab.store.dispose();
    }
  }
}
