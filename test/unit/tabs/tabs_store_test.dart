import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/features/operations/operation_store.dart';
import 'package:waydir/features/tabs/tabs_store.dart';

void main() {
  group('TabsStore reorder', () {
    late OperationStore operationStore;
    late TabsStore tabsStore;

    setUp(() {
      operationStore = OperationStore();
      tabsStore = TabsStore.fromPaths(
        operationStore: operationStore,
        paths: const ['/one', '/two', '/three'],
        activeTabIndex: 1,
      );
    });

    tearDown(() {
      tabsStore.dispose();
      operationStore.dispose();
    });

    test('moves tabs and preserves the active tab', () {
      final activeId = tabsStore.activeTab.value.id;

      tabsStore.reorderTab(1, 0);

      expect(tabsStore.tabs.value.map((tab) => tab.store.currentPath.value), [
        '/two',
        '/one',
        '/three',
      ]);
      expect(tabsStore.activeTab.value.id, activeId);
      expect(tabsStore.activeIndex.value, 0);
    });
  });
}
