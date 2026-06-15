import '../../features/locations/location_resolver.dart';
import '../../features/locations/location_uri.dart';
import '../platform/platform_paths.dart';
import '../settings/settings_store.dart';
import 'sftp_terminal.dart';
import 'shell_detector.dart';

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

      return TerminalLaunchSpec(
        cwd: physical ?? PlatformPaths.homePath,
        shell: _localShell(),
      );
    }

    return TerminalLaunchSpec(cwd: path, shell: _localShell());
  }

  /// Launch spec for an explicit shell executable at [cwd]. An empty [shell]
  /// (e.g. the "system default" choice) falls back to the platform default.
  static TerminalLaunchSpec forShell(String shell, String cwd) {
    return TerminalLaunchSpec(
      cwd: cwd,
      shell: shell.isEmpty ? _localShell() : shell,
    );
  }

  /// Launch spec for a WSL distribution. The target directory is passed via
  /// `--cd` (WSL translates Windows and `\\wsl.localhost` paths); the Windows
  /// process cwd is left at the home path because CreateProcess rejects a UNC
  /// working directory.
  static TerminalLaunchSpec forWsl(String distribution, String cwd) {
    return TerminalLaunchSpec(
      cwd: PlatformPaths.homePath,
      shell: 'wsl.exe',
      args: ['-d', distribution, '--cd', cwd],
    );
  }

  /// The shell to launch for a local session, from the user's preference.
  /// An empty string lets the native pty fall back to the platform default
  /// (`$SHELL` on Unix); `'system'` resolves to the platform's sensible
  /// default (PowerShell on Windows, `$SHELL` on Unix).
  static String _localShell() {
    final pref = SettingsStore.instance.terminalShell.value;
    if (pref.isNotEmpty && pref != 'system') return pref;

    return ShellDetector.defaultShellPath();
  }
}
