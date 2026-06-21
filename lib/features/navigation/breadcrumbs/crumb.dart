import 'package:flutter/widgets.dart';

import '../../../core/platform/platform_paths.dart';
import '../../../core/platform/trash_location.dart';
import '../../../i18n/strings.g.dart';
import '../../../ui/icons/distro_icons.dart';
import '../../../ui/icons/waydir_icons.dart';
import '../../containers/wsl_path.dart';
import '../../tags/tag_path.dart';
import '../../tags/tag_store.dart';

class Crumb {
  final String label;
  final String fullPath;
  final IconData? icon;
  final Color? iconColor;
  final Color? dotColor;

  const Crumb({
    required this.label,
    required this.fullPath,
    this.icon,
    this.iconColor,
    this.dotColor,
  });
}

List<Crumb> crumbsFromPath(String path) {
  if (path.isEmpty) return const [];

  if (isTagPath(path)) {
    final id = tagIdFromPath(path);
    final tag = id == null ? null : TagStore.instance.byId.value[id];

    return [
      Crumb(
        label: tag?.name ?? t.sidebar.tags,
        fullPath: path,
        dotColor: tag?.color,
      ),
    ];
  }

  if (isTrashPath(path)) {
    final crumbs = <Crumb>[
      Crumb(
        label: t.sidebar.trash,
        fullPath: kTrashPath,
        icon: WaydirIconsRegular.trashSimple,
      ),
    ];
    if (path != kTrashPath) {
      final rest = path
          .substring(kTrashPath.length + 1)
          .split('/')
          .where((s) => s.isNotEmpty)
          .toList();
      for (var i = 0; i < rest.length; i++) {
        crumbs.add(
          Crumb(
            label: rest[i],
            fullPath: '$kTrashPath/${rest.sublist(0, i + 1).join('/')}',
          ),
        );
      }
    }

    return crumbs;
  }

  final wsl = parseWslPath(path);
  if (wsl != null) {
    final crumbs = <Crumb>[
      Crumb(
        label: wsl.distro,
        fullPath: wsl.root,
        icon: distroIconFor(wsl.distro),
        iconColor: distroColorFor(wsl.distro),
      ),
    ];
    for (var i = 0; i < wsl.rest.length; i++) {
      crumbs.add(
        Crumb(
          label: wsl.rest[i],
          fullPath: '${wsl.root}\\${wsl.rest.sublist(0, i + 1).join('\\')}',
        ),
      );
    }

    return crumbs;
  }

  final segments = PlatformPaths.segments(path);
  if (segments.isEmpty) {
    if (!PlatformPaths.isWindows && path.startsWith('/')) {
      return const [Crumb(label: '/', fullPath: '/')];
    }

    return const [];
  }

  final isWindows = PlatformPaths.isWindows;
  final isSmb = PlatformPaths.isSmbUri(path);
  final isSftp = PlatformPaths.isSftpUri(path);
  final hasUriRoot = isWindows || isSmb || isSftp;

  final rootLabel = isSmb || isSftp
      ? segments.first
      : (isWindows ? '${segments.first}\\' : '/');
  final rootFullPath = hasUriRoot
      ? PlatformPaths.buildPartialPath(segments, 0)
      : '/';

  final crumbs = <Crumb>[Crumb(label: rootLabel, fullPath: rootFullPath)];
  final offset = hasUriRoot ? 1 : 0;
  for (var i = offset; i < segments.length; i++) {
    crumbs.add(
      Crumb(
        label: segments[i],
        fullPath: PlatformPaths.buildPartialPath(segments, i),
      ),
    );
  }

  return crumbs;
}
