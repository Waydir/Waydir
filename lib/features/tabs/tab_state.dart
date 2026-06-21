import 'package:path/path.dart' as p;
import 'package:signals/signals.dart';
import '../../core/platform/trash_location.dart';
import '../../i18n/strings.g.dart';
import '../containers/wsl_path.dart';
import '../navigation/navigation_store.dart';
import '../tags/tag_path.dart';
import '../tags/tag_store.dart';

class TabState {
  final String id;
  final NavigationStore store;
  late final Computed<String> title;

  TabState({required this.id, required this.store}) {
    title = computed(() {
      final path = store.currentPath.value;
      if (path == kTrashPath) return t.sidebar.trash;
      if (isTagPath(path)) {
        final id = tagIdFromPath(path);
        final tag = id == null ? null : TagStore.instance.byId.value[id];

        return tag?.name ?? t.sidebar.tags;
      }
      final wsl = parseWslPath(path);
      if (wsl != null && wsl.rest.isEmpty) return wsl.distro;
      final name = p.basename(path);
      if (name.isEmpty) return '/';

      return name;
    });
  }
}
