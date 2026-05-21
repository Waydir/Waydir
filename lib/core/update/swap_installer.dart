import 'dart:io';

import 'package:path/path.dart' as p;

/// Performs a portable in-place update by:
///   1. Extracting the downloaded archive into a sibling staging dir
///   2. Writing a small helper script that waits for the parent app to
///      exit, swaps the staging dir with the bundle dir, restarts the
///      app, and cleans up the old bundle
///   3. Spawning the helper detached
///
/// Returns true when the helper was spawned successfully and the caller
/// should call exit(0) to release the bundle so the helper can swap it.
class SwapInstaller {
  static Future<bool> installLinuxPortable(File archive) async {
    final bundleDir = _resolveLinuxBundleDir();
    if (!await _isWritable(bundleDir)) return false;

    final staging = Directory(p.join(bundleDir.parent.path, '.waydir-staging'));
    if (staging.existsSync()) staging.deleteSync(recursive: true);
    staging.createSync(recursive: true);

    final extract = await Process.run('tar', [
      '-xzf',
      archive.path,
      '-C',
      staging.path,
    ]);
    if (extract.exitCode != 0) {
      staging.deleteSync(recursive: true);
      return false;
    }

    final stagingRoot = _flattenSingleChild(staging);
    if (!File(p.join(stagingRoot.path, 'waydir')).existsSync()) {
      staging.deleteSync(recursive: true);
      return false;
    }

    final exeName = p.basename(_resolvedExe());
    final script = _writeShellScript(
      bundle: bundleDir,
      staging: stagingRoot,
      exeName: exeName,
    );
    await Process.run('chmod', ['+x', script.path]);
    await Process.start(
      script.path,
      const [],
      mode: ProcessStartMode.detached,
    );
    return true;
  }

  static Future<bool> installWindowsPortable(File archive) async {
    final bundleDir = _resolveWindowsBundleDir();
    if (!await _isWritable(bundleDir)) return false;

    final staging = Directory(p.join(bundleDir.parent.path, '.waydir-staging'));
    if (staging.existsSync()) staging.deleteSync(recursive: true);
    staging.createSync(recursive: true);

    final extract = await Process.run('powershell', [
      '-NoProfile',
      '-Command',
      'Expand-Archive -LiteralPath "${archive.path}" -DestinationPath "${staging.path}" -Force',
    ]);
    if (extract.exitCode != 0) {
      staging.deleteSync(recursive: true);
      return false;
    }

    final stagingRoot = _flattenSingleChild(staging);
    if (!File(p.join(stagingRoot.path, 'waydir.exe')).existsSync()) {
      staging.deleteSync(recursive: true);
      return false;
    }

    final exeName = p.basename(_resolvedExe());
    final script = _writeBatchScript(
      bundle: bundleDir,
      staging: stagingRoot,
      exeName: exeName,
    );
    await Process.start(
      'cmd',
      ['/c', 'start', '', '/min', script.path],
      mode: ProcessStartMode.detached,
    );
    return true;
  }

  static Directory _resolveLinuxBundleDir() {
    final exe = _resolvedExe();
    return Directory(p.dirname(exe));
  }

  static Directory _resolveWindowsBundleDir() {
    final exe = _resolvedExe();
    return Directory(p.dirname(exe));
  }

  static String _resolvedExe() {
    try {
      return File(Platform.resolvedExecutable).resolveSymbolicLinksSync();
    } catch (_) {
      return Platform.resolvedExecutable;
    }
  }

  static Future<bool> _isWritable(Directory dir) async {
    try {
      final probe = File(p.join(dir.path, '.waydir-write-probe'));
      probe.writeAsStringSync('x');
      probe.deleteSync();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// When the archive expands into a single top-level directory (common
  /// for zips), descend into it so callers can treat the returned dir as
  /// the new bundle root.
  static Directory _flattenSingleChild(Directory staging) {
    final entries = staging.listSync();
    if (entries.length == 1 && entries.first is Directory) {
      return entries.first as Directory;
    }
    return staging;
  }

  static File _writeShellScript({
    required Directory bundle,
    required Directory staging,
    required String exeName,
  }) {
    final script = File(p.join(bundle.parent.path, '.waydir-swap.sh'));
    final old = '${bundle.path}.old';
    script.writeAsStringSync('''
#!/bin/sh
sleep 2
BUNDLE="${bundle.path}"
STAGING="${staging.path}"
OLD="$old"
rm -rf "\$OLD" 2>/dev/null
mv "\$BUNDLE" "\$OLD" || exit 1
mv "\$STAGING" "\$BUNDLE" || { mv "\$OLD" "\$BUNDLE"; exit 1; }
"\$BUNDLE/$exeName" >/dev/null 2>&1 &
sleep 3
rm -rf "\$OLD" 2>/dev/null
rm -- "\$0" 2>/dev/null
''');
    return script;
  }

  static File _writeBatchScript({
    required Directory bundle,
    required Directory staging,
    required String exeName,
  }) {
    final script = File(p.join(bundle.parent.path, '.waydir-swap.cmd'));
    final old = '${bundle.path}.old';
    script.writeAsStringSync('''
@echo off
timeout /t 2 /nobreak >nul
set "BUNDLE=${bundle.path}"
set "STAGING=${staging.path}"
set "OLD=$old"
if exist "%OLD%" rmdir /s /q "%OLD%"
move "%BUNDLE%" "%OLD%" >nul || exit /b 1
move "%STAGING%" "%BUNDLE%" >nul
if errorlevel 1 (
  move "%OLD%" "%BUNDLE%" >nul
  exit /b 1
)
start "" "%BUNDLE%\\$exeName"
timeout /t 4 /nobreak >nul
rmdir /s /q "%OLD%"
del "%~f0"
''');
    return script;
  }
}
