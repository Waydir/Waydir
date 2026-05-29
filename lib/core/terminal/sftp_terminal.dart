import '../../features/locations/location_uri.dart';
import '../fs/sftp_session_manager.dart';

class SftpTerminalCommand {
  final String program;
  final List<String> args;

  const SftpTerminalCommand({required this.program, required this.args});
}

class SftpTerminal {
  SftpTerminal._();

  static SftpTerminalCommand? command(LocationUri uri) {
    final host = uri.host;
    if (host == null || host.isEmpty) return null;
    final user = uri.username;
    final port = uri.port ?? 22;
    final remote = SftpSessionManager.remotePath(uri.raw);

    final target = (user == null || user.isEmpty) ? host : '$user@$host';
    final args = <String>['-t'];
    if (port != 22) {
      args.add('-p');
      args.add('$port');
    }
    args.add(target);
    args.add(_remoteShell(remote));
    return SftpTerminalCommand(program: 'ssh', args: args);
  }

  static String _remoteShell(String remotePath) {
    final dir = remotePath.isEmpty ? '/' : remotePath;
    final quoted = "'${dir.replaceAll("'", r"'\''")}'";
    return 'cd $quoted 2>/dev/null; exec "\${SHELL:-/bin/sh}" -l';
  }
}
