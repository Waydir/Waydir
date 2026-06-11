import 'dart:async';
import 'dart:io';

/// macOS "Full Disk Access" privacy pane URL.
const _fullDiskAccessPaneUrl =
    'x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles';

/// Whether the app currently has macOS Full Disk Access.
///
/// There is no public API to query this, so we probe a path readable *only*
/// with Full Disk Access: the user's TCC database. It exists on every Mac and
/// is not one of the auto-prompted folders (Documents/Desktop/Downloads), so
/// the probe fails silently when access is missing — it never triggers an
/// extra permission prompt.
///
/// Caveat: TCC attributes file access to the "responsible process". A debug
/// build launched from a terminal that itself has Full Disk Access therefore
/// reports a false positive — this is reliable only for a normally launched
/// (Finder/dock) app bundle. Returns `true` on non-macOS platforms.
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
  } catch (_) {
    return false;
  }
}

/// Opens System Settings → Privacy & Security → Full Disk Access.
///
/// macOS exposes no API to grant Full Disk Access programmatically (unlike
/// camera/microphone), so we only guide the user to the settings pane, where
/// they enable Waydir and relaunch.
void openFullDiskAccessSettings() {
  unawaited(Process.run('open', [_fullDiskAccessPaneUrl]));
}
