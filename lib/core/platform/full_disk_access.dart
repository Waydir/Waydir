import 'dart:async';
import 'dart:io';

import '../logging/app_logger.dart';

const _fullDiskAccessPaneUrl =
    'x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles';

Future<bool> hasFullDiskAccess() async {
  if (!Platform.isMacOS) return true;
  final home = Platform.environment['HOME'];
  if (home == null || home.isEmpty) return false;
  final tccDb = File('$home/Library/Application Support/com.apple.TCC/TCC.db');
  try {
    final raf = tccDb.openSync();
    try {
      raf.readSync(1);
    } finally {
      raf.closeSync();
    }
    return true;
  } on FileSystemException {
    return false;
  } catch (e, st) {
    log.warn('platform', 'full disk access probe failed', error: e, stack: st);
    return false;
  }
}

void openFullDiskAccessSettings() {
  unawaited(Process.run('open', [_fullDiskAccessPaneUrl]));
}
