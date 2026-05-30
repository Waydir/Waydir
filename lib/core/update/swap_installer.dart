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
    await Process.start(script.path, const [], mode: ProcessStartMode.detached);
    return true;
  }

  static Future<bool> installWindowsPortable(File archive) async {
    final bundleDir = _resolveWindowsBundleDir();
    if (!await _isWritable(bundleDir)) return false;

    final staging = Directory(p.join(bundleDir.parent.path, '.waydir-staging'));
    if (staging.existsSync()) staging.deleteSync(recursive: true);
    staging.createSync(recursive: true);

    final aEsc = archive.path.replaceAll("'", "''");
    final sEsc = staging.path.replaceAll("'", "''");
    final extract = await Process.run('powershell', [
      '-NoProfile',
      '-NonInteractive',
      '-Command',
      "Expand-Archive -LiteralPath '$aEsc' -DestinationPath '$sEsc' -Force",
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
    final script = _writePowerShellScript(
      bundle: bundleDir,
      staging: stagingRoot,
      exeName: exeName,
    );
    await Process.start('powershell', [
      '-NoProfile',
      '-NonInteractive',
      '-ExecutionPolicy',
      'Bypass',
      '-WindowStyle',
      'Hidden',
      '-File',
      script.path,
    ], mode: ProcessStartMode.detached);
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

  static File _writePowerShellScript({
    required Directory bundle,
    required Directory staging,
    required String exeName,
  }) {
    final script = File(p.join(bundle.parent.path, '.waydir-swap.ps1'));
    final old = '${bundle.path}.old';
    final exePath = p.join(bundle.path, exeName);
    String q(String s) => "'${s.replaceAll("'", "''")}'";
    script.writeAsStringSync('''
\$ErrorActionPreference = 'Stop'
\$bundle = ${q(bundle.path)}
\$staging = ${q(staging.path)}
\$old = ${q(old)}
\$exe = ${q(exePath)}

# Set-Location off the bundle dir; Windows cannot rename a directory that is
# the working directory of a running process (this script's own cwd).
Set-Location -LiteralPath ${q(bundle.parent.path)}

if (Test-Path -LiteralPath \$old) { Remove-Item -LiteralPath \$old -Recurse -Force }

# Wait for the parent app to release the bundle, then swap.
\$moved = \$false
for (\$i = 0; \$i -lt 30; \$i++) {
  try {
    Move-Item -LiteralPath \$bundle -Destination \$old -Force
    \$moved = \$true
    break
  } catch {
    Start-Sleep -Seconds 1
  }
}
if (-not \$moved) { exit 1 }

try {
  Move-Item -LiteralPath \$staging -Destination \$bundle -Force
} catch {
  Move-Item -LiteralPath \$old -Destination \$bundle -Force
  exit 1
}

Start-Process -FilePath \$exe
Start-Sleep -Seconds 4
Remove-Item -LiteralPath \$old -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath \$PSCommandPath -Force -ErrorAction SilentlyContinue
''');
    return script;
  }
}
