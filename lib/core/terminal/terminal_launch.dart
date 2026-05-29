import '../../features/locations/location_resolver.dart';
import '../../features/locations/location_uri.dart';
import '../platform/platform_paths.dart';
import 'sftp_terminal.dart';

class TerminalLaunchSpec {
  final String shell;
  final List<String> args;
  final String cwd;

  const TerminalLaunchSpec({
    this.shell = '',
    this.args = const [],
    required this.cwd,
  });
}

class TerminalLaunch {
  TerminalLaunch._();

  static TerminalLaunchSpec resolve(String path) {
    if (PlatformPaths.isSftpUri(path)) {
      final uri = LocationUri.parse(path);
      final remote = SftpTerminal.command(uri);
      if (remote != null) {
        return TerminalLaunchSpec(
          shell: remote.program,
          args: remote.args,
          cwd: PlatformPaths.homePath,
        );
      }
      return TerminalLaunchSpec(cwd: PlatformPaths.homePath);
    }
    if (PlatformPaths.isSmbUri(path)) {
      final physical = LocationResolver.logicalToPhysical(path);
      return TerminalLaunchSpec(cwd: physical ?? PlatformPaths.homePath);
    }
    return TerminalLaunchSpec(cwd: path);
  }
}
