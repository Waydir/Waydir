import 'package:path/path.dart' as p;
import 'package:signals/signals.dart';
import '../../core/platform/trash_location.dart';
import '../../i18n/strings.g.dart';
import '../navigation/navigation_store.dart';

class TabState {
  final String id;
  final NavigationStore store;
  late final Computed<String> title;

  TabState({required this.id, required this.store}) {
    title = computed(() {
      final path = store.currentPath.value;
      if (path == kTrashPath) return t.sidebar.trash;
      final name = p.basename(path);
      if (name.isEmpty) return '/';

      return name;
    });
  }
}
