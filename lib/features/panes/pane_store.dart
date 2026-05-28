import '../operations/operation_store.dart';
import '../tabs/tabs_store.dart';

class PaneStore {
  final TabsStore tabs;

  PaneStore({required OperationStore operationStore, String? initialPath})
    : tabs = TabsStore(
        operationStore: operationStore,
        initialPath: initialPath,
      );

  PaneStore.fromPaths({
    required OperationStore operationStore,
    required List<String> paths,
    int activeTabIndex = 0,
  }) : tabs = TabsStore.fromPaths(
         operationStore: operationStore,
         paths: paths,
         activeTabIndex: activeTabIndex,
       );

  void dispose() {
    tabs.dispose();
  }
}
