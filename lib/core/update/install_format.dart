import 'dart:io';

import '../logging/app_logger.dart';

/// Distribution format the running binary was installed as.
enum InstallFormat {
  linuxDeb,
  linuxRpm,
  linuxAppImage,
  linuxPortable,
  windowsInstaller,
  windowsPortable,
  macDmg,
  unknown,
}

class InstallFormatDetector {
  /// Best-effort detection based on the actual binary path, not the OS.
  /// Falls back to a portable variant when no system package owns the
  /// running executable - this covers users who downloaded the tar.gz on
  /// Fedora, extracted a zip on Windows, or copied the .app outside of
  /// /Applications on macOS.
  static Future<InstallFormat> detect() async {
    final exe = _resolveExe(Platform.resolvedExecutable);
    if (Platform.isLinux) return _detectLinux(exe);
    if (Platform.isWindows) return _detectWindows(exe);
    if (Platform.isMacOS) return _detectMac(exe);
    return InstallFormat.unknown;
  }

  static String _resolveExe(String path) {
    try {
      return File(path).resolveSymbolicLinksSync();
    } catch (e, st) {
      log.warn(
        'update',
        'executable path resolution failed',
        error: e,
        stack: st,
      );
      return path;
    }
  }

  static Future<InstallFormat> _detectLinux(String exe) async {
    if (Platform.environment.containsKey('APPIMAGE')) {
      return InstallFormat.linuxAppImage;
    }
    if (await _ownedByDpkg(exe)) return InstallFormat.linuxDeb;
    if (await _ownedByRpm(exe)) return InstallFormat.linuxRpm;
    return InstallFormat.linuxPortable;
  }

  static Future<bool> _ownedByDpkg(String exe) async {
    try {
      final r = await Process.run('dpkg', ['-S', exe]);
      return r.exitCode == 0 && (r.stdout as String).trim().isNotEmpty;
    } catch (e, st) {
      log.warn('update', 'dpkg ownership check failed', error: e, stack: st);
      return false;
    }
  }

  static Future<bool> _ownedByRpm(String exe) async {
    try {
      final r = await Process.run('rpm', ['-qf', exe]);
      return r.exitCode == 0 &&
          !(r.stdout as String).contains('not owned by any package');
    } catch (e, st) {
      log.warn('update', 'rpm ownership check failed', error: e, stack: st);
      return false;
    }
  }

  static Future<InstallFormat> _detectWindows(String exe) async {
    final lower = exe.toLowerCase();
    if (lower.contains(r'\program files') ||
        lower.contains(r'\programfiles') ||
        lower.contains(r'\appdata\local\programs\')) {
      return InstallFormat.windowsInstaller;
    }
    return InstallFormat.windowsPortable;
  }

  static Future<InstallFormat> _detectMac(String exe) async {
    return InstallFormat.macDmg;
  }
}
