import 'package:flutter/widgets.dart';

import '../../../core/platform/platform_paths.dart';
import '../../../core/platform/trash_location.dart';
import '../../../i18n/strings.g.dart';
import '../../../ui/icons/waydir_icons.dart';

class Crumb {
  final String label;
  final String fullPath;
  final IconData? icon;

  const Crumb({required this.label, required this.fullPath, this.icon});
}

List<Crumb> crumbsFromPath(String path) {
  if (path.isEmpty) return const [];

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

  final segments = PlatformPaths.segments(path);
  if (segments.isEmpty) return const [];

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
