import 'dart:io';

import '../../core/logging/app_logger.dart';
import '../../core/platform/platform_paths.dart';
import 'wsl_distribution.dart';

abstract class ContainerService {
  Future<List<WslDistribution>> list();

  factory ContainerService() {
    if (PlatformPaths.isWindows) return _WindowsWslService();

    return _NoopContainerService();
  }
}

class _NoopContainerService implements ContainerService {
  @override
  Future<List<WslDistribution>> list() async => const [];
}

class _WindowsWslService implements ContainerService {
  @override
  Future<List<WslDistribution>> list() async {
    final installed = await _names(const ['--list', '--quiet']);
    if (installed.isEmpty) return const [];
    final running = (await _names(const [
      '--list',
      '--running',
      '--quiet',
    ])).toSet();

    return [
      for (final name in installed)
        WslDistribution(name: name, isRunning: running.contains(name)),
    ];
  }

  Future<List<String>> _names(List<String> args) async {
    try {
      final result = await Process.run('wsl.exe', args, stdoutEncoding: null);
      if (result.exitCode != 0) return const [];

      return parseWslNames(result.stdout as List<int>);
    } catch (e, st) {
      log.warn('containers', 'wsl list failed', error: e, stack: st);

      return const [];
    }
  }
}

/// `wsl.exe` emits UTF-16LE (with a BOM); a plain utf8/system decode mangles
/// it. Decode the raw bytes as UTF-16LE, then split into trimmed, non-empty
/// distribution names.
List<String> parseWslNames(List<int> bytes) {
  if (bytes.isEmpty) return const [];
  var start = 0;
  if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) start = 2;
  final units = <int>[];
  for (var i = start; i + 1 < bytes.length; i += 2) {
    units.add(bytes[i] | (bytes[i + 1] << 8));
  }
  final text = String.fromCharCodes(units);

  return [
    for (final line in text.split('\n'))
      if (line.replaceAll('\r', '').trim().isNotEmpty)
        line.replaceAll('\r', '').trim(),
  ];
}
