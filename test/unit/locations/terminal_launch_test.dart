import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/platform/platform_paths.dart';
import 'package:waydir/core/settings/settings_store.dart';
import 'package:waydir/core/terminal/sftp_terminal.dart';
import 'package:waydir/core/terminal/shell_detector.dart';
import 'package:waydir/core/terminal/terminal_launch.dart';
import 'package:waydir/features/locations/location_resolver.dart';
import 'package:waydir/features/locations/location_uri.dart';

void main() {
  group('SftpTerminal.command', () {
    test('builds ssh command with user, host and remote cd', () {
      final cmd = SftpTerminal.command(
        LocationUri.parse('sftp://alice@host.local/srv/data'),
      )!;

      expect(cmd.program, 'ssh');
      expect(cmd.args.first, '-t');
      expect(cmd.args, contains('alice@host.local'));
      expect(cmd.args, isNot(contains('-p')));
      expect(cmd.args.last, startsWith("cd '/srv/data'"));
    });

    test('adds port flag for non-default ports', () {
      final cmd = SftpTerminal.command(
        LocationUri.parse('sftp://bob@host:2222/'),
      )!;

      expect(cmd.args, containsAllInOrder(['-p', '2222']));
      expect(cmd.args.last, startsWith("cd '/'"));
    });

    test('omits user when absent', () {
      final cmd = SftpTerminal.command(LocationUri.parse('sftp://host/'))!;

      expect(cmd.args, contains('host'));
    });

    test('escapes single quotes in remote path', () {
      final cmd = SftpTerminal.command(LocationUri.parse("sftp://host/a'b"))!;

      expect(cmd.args.last, contains(r"/a'\''b'"));
    });

    test('returns null without a host', () {
      expect(SftpTerminal.command(LocationUri.parse('sftp://')), isNull);
    });
  });

  group('TerminalLaunch.resolve', () {
    tearDown(() => SettingsStore.instance.terminalShell.value = 'system');

    test('local path launches the configured shell in that directory', () {
      SettingsStore.instance.terminalShell.value = '/usr/bin/fish';
      final spec = TerminalLaunch.resolve('/home/user/projects');

      expect(spec.shell, '/usr/bin/fish');
      expect(spec.args, isEmpty);
      expect(spec.cwd, '/home/user/projects');
    });

    test('system default resolves to the platform default shell', () {
      SettingsStore.instance.terminalShell.value = 'system';
      final spec = TerminalLaunch.resolve('/home/user/projects');

      expect(spec.shell, ShellDetector.defaultShellPath());
    });

    test('sftp path launches ssh from home', () {
      final spec = TerminalLaunch.resolve('sftp://eve@host/var/log');

      expect(spec.shell, 'ssh');
      expect(spec.args, contains('eve@host'));
      expect(spec.cwd, PlatformPaths.homePath);
    });

    test('mounted smb path launches shell in the physical mountpoint', () {
      final mount = Directory.systemTemp.createTempSync('waydir_smb_mount');
      Directory('${mount.path}/docs').createSync();
      LocationResolver.debugSetMappingForTests(
        'smb://server/share',
        mount.path,
      );
      addTearDown(() {
        LocationResolver.debugClearMappingsForTests();
        mount.deleteSync(recursive: true);
      });

      SettingsStore.instance.terminalShell.value = '/bin/bash';
      final spec = TerminalLaunch.resolve('smb://server/share/docs');

      expect(spec.shell, '/bin/bash');
      expect(spec.cwd, '${mount.path}/docs');
    });

    test('unmounted smb path falls back to home', () {
      final spec = TerminalLaunch.resolve('smb://nowhere/share');

      expect(spec.cwd, PlatformPaths.homePath);
    });
  });
}
