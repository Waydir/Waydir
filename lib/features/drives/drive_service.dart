import 'dart:convert';
import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'drive_model.dart';
import '../../core/logging/app_logger.dart';
import '../../core/platform/platform_paths.dart';
import '../../i18n/strings.g.dart';

abstract class DriveService {
  Future<List<Drive>> getDrives();
  Future<void> mount(Drive drive);
  Future<void> mountWithPassword(Drive drive, String password);
  Future<void> unmount(Drive drive);

  factory DriveService() {
    if (PlatformPaths.isWindows) {
      return _WindowsDriveService();
    } else if (PlatformPaths.isLinux) {
      return _LinuxDriveService();
    } else {
      return _MacDriveService();
    }
  }
}

typedef _WNetGetConnectionNative =
    Uint32 Function(Pointer<Utf16>, Pointer<Utf16>, Pointer<Uint32>);
typedef _WNetGetConnectionDart =
    int Function(Pointer<Utf16>, Pointer<Utf16>, Pointer<Uint32>);

class _WindowsDriveService implements DriveService {
  static final _wNetGetConnection = DynamicLibrary.open('mpr.dll')
      .lookupFunction<_WNetGetConnectionNative, _WNetGetConnectionDart>(
        'WNetGetConnectionW',
      );

  @override
  Future<List<Drive>> getDrives() async {
    final drives = <Drive>[];

    final bitMask = GetLogicalDrives();
    if (bitMask == 0) return drives;

    for (var i = 0; i < 26; i++) {
      if ((bitMask & (1 << i)) != 0) {
        final letter = String.fromCharCode(65 + i);
        final rootPath = '$letter:\\';
        final rootPathPtr = rootPath.toNativeUtf16();

        try {
          final driveType = GetDriveType(rootPathPtr);
          if (driveType == DRIVE_REMOTE) {
            final target = _networkDriveTarget(letter);
            drives.add(
              Drive(
                id: rootPath,
                label: t.sidebar.drives.windowsDriveLabel(
                  name: _shareName(target) ?? t.sidebar.drives.networkDrive,
                  letter: letter,
                ),
                mountPoint: rootPath,
                isRemovable: false,
                isNetwork: true,
                remoteTarget: target,
                fsType: null,
              ),
            );
          } else if (driveType == DRIVE_REMOVABLE || driveType == DRIVE_FIXED) {
            final volumeNameBuffer = wsalloc(MAX_PATH + 1);
            try {
              final result = GetVolumeInformation(
                rootPathPtr,
                volumeNameBuffer,
                MAX_PATH + 1,
                nullptr,
                nullptr,
                nullptr,
                nullptr,
                0,
              );

              String label = t.sidebar.drives.localDisk;
              if (result != 0) {
                label = volumeNameBuffer.toDartString();
              }
              if (label.isEmpty) {
                label = driveType == DRIVE_REMOVABLE
                    ? t.sidebar.drives.usbDrive
                    : t.sidebar.drives.localDisk;
              }

              drives.add(
                Drive(
                  id: rootPath,
                  label: t.sidebar.drives.windowsDriveLabel(
                    name: label,
                    letter: letter,
                  ),
                  mountPoint: rootPath,
                  isRemovable: driveType == DRIVE_REMOVABLE,
                  fsType: null,
                  space: _windowsSpace(rootPath),
                ),
              );
            } finally {
              free(volumeNameBuffer);
            }
          }
        } finally {
          free(rootPathPtr);
        }
      }
    }

    return drives;
  }

  @override
  Future<void> mount(Drive drive) async {}

  @override
  Future<void> mountWithPassword(Drive drive, String password) async {}

  @override
  Future<void> unmount(Drive drive) async {
    final letter = drive.id.replaceAll(r'\', '');
    if (drive.isNetwork) {
      await Process.run('net', ['use', letter, '/delete', '/y']);
      return;
    }
    if (!drive.isRemovable) return;
    final script =
        '\$driveEject = New-Object -comObject Shell.Application; \$driveEject.Namespace(17).ParseName("$letter").InvokeVerb("Eject")';
    await Process.run('powershell', ['-NoProfile', '-Command', script]);
  }

  /// Resolves the UNC path (e.g. `\\server\share`) backing a mapped network
  /// drive letter via WNetGetConnectionW. Returns null if it can't be read.
  String? _shareName(String? target) {
    if (target == null) return null;
    final parts = target
        .split(RegExp(r'[\\/]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return null;
    return parts.last;
  }

  String? _networkDriveTarget(String letter) {
    final local = '$letter:'.toNativeUtf16();
    final length = calloc<Uint32>()..value = MAX_PATH + 1;
    final remote = wsalloc(MAX_PATH + 1);
    try {
      final result = _wNetGetConnection(local, remote, length);
      if (result != 0) return null;
      final unc = remote.toDartString();
      return unc.isEmpty ? null : unc;
    } catch (e, st) {
      log.warn('drives', 'network drive lookup failed', error: e, stack: st);
      return null;
    } finally {
      free(local);
      free(remote);
      calloc.free(length);
    }
  }

  DriveSpace? _windowsSpace(String rootPath) {
    final path = rootPath.toNativeUtf16();
    final freeToCaller = calloc<Uint64>();
    final total = calloc<Uint64>();
    final free = calloc<Uint64>();
    try {
      final ok = GetDiskFreeSpaceEx(path, freeToCaller, total, free);
      if (ok == 0 || total.value <= 0) return null;
      return DriveSpace(totalBytes: total.value, freeBytes: free.value);
    } catch (e, st) {
      log.warn(
        'drives',
        'windows drive space lookup failed',
        error: e,
        stack: st,
      );
      return null;
    } finally {
      calloc.free(path);
      calloc.free(freeToCaller);
      calloc.free(total);
      calloc.free(free);
    }
  }
}

class _LinuxDriveService implements DriveService {
  @override
  Future<List<Drive>> getDrives() async {
    try {
      final result = await Process.run('lsblk', [
        '-J',
        '-o',
        'NAME,TYPE,MOUNTPOINT,SIZE,LABEL,RM,FSTYPE,PARTTYPENAME',
      ]);

      if (result.exitCode != 0) return [];

      final data = jsonDecode(result.stdout as String) as Map<String, dynamic>;
      final devices = data['blockdevices'] as List<dynamic>? ?? [];

      final drives = <Drive>[];
      drives.add(
        Drive(
          id: '/',
          label: t.sidebar.root,
          mountPoint: '/',
          isRemovable: false,
          fsType: null,
          space: await _unixSpace('/'),
        ),
      );

      for (final device in devices) {
        await _processDevice(device as Map<String, dynamic>, drives);
      }

      return drives;
    } catch (e, st) {
      log.warn('drives', 'linux drive discovery failed', error: e, stack: st);
      return [];
    }
  }

  Future<void> _processDevice(
    Map<String, dynamic> device,
    List<Drive> drives,
  ) async {
    final name = device['name'] as String?;
    final type = device['type'] as String?;
    final mountPoint = device['mountpoint'] as String?;
    final label = device['label'] as String?;
    final rm = device['rm'];
    final fstype = device['fstype'] as String?;
    final partTypeName = device['parttypename'] as String?;

    final isRemovable = rm == true || rm == '1' || rm == 1;

    if (type == 'part' || type == 'disk') {
      if (fstype != null && fstype != 'swap') {
        final lowerLabel = label?.toLowerCase() ?? '';
        final lowerPartType = partTypeName?.toLowerCase() ?? '';

        final isSystem =
            mountPoint == '/' ||
            mountPoint == '/home' ||
            mountPoint == '/boot' ||
            mountPoint == '/boot/efi' ||
            mountPoint == '[SWAP]';
        final isEfi =
            fstype == 'vfat' &&
            (lowerLabel == 'efi' || lowerLabel == 'efi system partition');
        final isRecoveryOrReserved =
            lowerPartType.contains('recovery') ||
            lowerPartType.contains('reserved') ||
            lowerPartType.contains('extended boot');

        if (type != 'loop' &&
            !(mountPoint != null && mountPoint.contains('snap')) &&
            !isSystem &&
            !isEfi &&
            !isRecoveryOrReserved) {
          final id = '/dev/$name';
          if (!drives.any((d) => d.id == id)) {
            drives.add(
              Drive(
                id: id,
                label: label ?? name ?? t.sidebar.drives.unknownDrive,
                mountPoint: mountPoint,
                isRemovable: isRemovable,
                fsType: fstype,
                space: mountPoint == null ? null : await _unixSpace(mountPoint),
              ),
            );
          }
        }
      }
    }

    final children = device['children'] as List<dynamic>?;
    if (children != null) {
      for (final child in children) {
        await _processDevice(child as Map<String, dynamic>, drives);
      }
    }
  }

  @override
  Future<void> mount(Drive drive) async {
    final result = await Process.run('udisksctl', ['mount', '-b', drive.id]);
    if (result.exitCode != 0) {
      throw Exception(result.stderr.toString());
    }
  }

  @override
  Future<void> mountWithPassword(Drive drive, String password) async {
    final user = Platform.environment['USER'] ?? 'user';
    final safeLabel = drive.label.replaceAll(RegExp(r'[/\\\s]+'), '_');
    final mnt = '/run/media/$user/$safeLabel';

    await _runSudoWithPassword(['mkdir', '-p', mnt], password);

    List<String> options = const [];
    if (drive.fsType == 'ntfs' ||
        drive.fsType == 'vfat' ||
        drive.fsType == 'exfat') {
      try {
        final uidRes = await Process.run('id', ['-u']);
        final gidRes = await Process.run('id', ['-g']);
        if (uidRes.exitCode == 0 && gidRes.exitCode == 0) {
          options = [
            '-o',
            'uid=${uidRes.stdout.toString().trim()},gid=${gidRes.stdout.toString().trim()}',
          ];
        }
      } catch (e, st) {
        log.warn(
          'drives',
          'failed to read user ids for mount options',
          error: e,
          stack: st,
        );
      }
    }

    await _runSudoWithPassword(['mount', ...options, drive.id, mnt], password);
  }

  @override
  Future<void> unmount(Drive drive) async {
    final result = await Process.run('udisksctl', ['unmount', '-b', drive.id]);
    if (result.exitCode != 0 &&
        !result.stderr.toString().contains('Not mounted')) {
      throw Exception(result.stderr.toString());
    }
  }

  Future<void> _runSudoWithPassword(List<String> args, String password) async {
    final process = await Process.start('sudo', ['-S', ...args]);
    process.stdin.writeln(password);
    await process.stdin.close();
    final stderr = await process.stderr.transform(utf8.decoder).join();
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception(stderr);
    }
  }
}

class _MacDriveService implements DriveService {
  @override
  Future<List<Drive>> getDrives() async {
    try {
      final dfResult = await Process.run('df', ['-lPk']);
      if (dfResult.exitCode != 0) return [];

      final drives = <Drive>[];
      final lines = (dfResult.stdout as String).split('\n');

      for (final line in lines.skip(1)) {
        if (line.trim().isEmpty) continue;
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length < 6) continue;

        final device = parts[0];
        final mountPoint = parts.sublist(5).join(' ');

        if (!device.startsWith('/dev/disk')) continue;
        if (mountPoint == '/System/Volumes/Data') continue;

        final isRoot = mountPoint == '/';
        final isVolumes = mountPoint.startsWith('/Volumes/');
        if (!isRoot && !isVolumes) continue;

        final label = isRoot
            ? t.sidebar.drives.macintoshHd
            : mountPoint.substring('/Volumes/'.length);

        bool isRemovable = false;
        if (!isRoot) {
          try {
            final info = await Process.run('diskutil', ['info', device]);
            if (info.exitCode == 0) {
              final output = info.stdout as String;
              isRemovable =
                  output.contains('Removable Media: Removable') ||
                  output.contains('Removable Media:    Removable') ||
                  output.contains('Protocol: USB') ||
                  output.contains('Protocol:    USB');
            }
          } catch (e, st) {
            log.warn(
              'drives',
              'mac removable drive detection failed',
              error: e,
              stack: st,
            );
          }
        }

        drives.add(
          Drive(
            id: device,
            label: label,
            mountPoint: mountPoint,
            isRemovable: isRemovable,
            fsType: null,
            space: _spaceFromDfParts(parts),
          ),
        );
      }

      return drives;
    } catch (e, st) {
      log.warn('drives', 'mac drive discovery failed', error: e, stack: st);
      return [];
    }
  }

  @override
  Future<void> mount(Drive drive) async {
    await Process.run('diskutil', ['mount', drive.id]);
  }

  @override
  Future<void> mountWithPassword(Drive drive, String password) async {
    await Process.run('diskutil', ['mount', drive.id]);
  }

  @override
  Future<void> unmount(Drive drive) async {
    await Process.run('diskutil', ['unmount', drive.id]);
  }
}

Future<DriveSpace?> _unixSpace(String path) async {
  try {
    final result = await Process.run('df', ['-Pk', path]);
    if (result.exitCode != 0) return null;
    final lines = (result.stdout as String)
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.length < 2) return null;
    return _spaceFromDfParts(lines.last.trim().split(RegExp(r'\s+')));
  } catch (e, st) {
    log.warn('drives', 'drive space lookup failed', error: e, stack: st);
    return null;
  }
}

DriveSpace? _spaceFromDfParts(List<String> parts) {
  if (parts.length < 4) return null;
  final blocks = int.tryParse(parts[1]);
  final available = int.tryParse(parts[3]);
  if (blocks == null || available == null || blocks <= 0) return null;
  return DriveSpace(totalBytes: blocks * 1024, freeBytes: available * 1024);
}
