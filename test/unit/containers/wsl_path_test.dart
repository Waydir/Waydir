import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/platform/platform_paths.dart';
import 'package:waydir/core/terminal/terminal_launch.dart';
import 'package:waydir/features/containers/wsl_path.dart';

void main() {
  group('parseWslPath', () {
    test('parses distro root with wsl.localhost host', () {
      final wsl = parseWslPath(r'\\wsl.localhost\Ubuntu\');
      expect(wsl, isNotNull);
      expect(wsl!.distro, 'Ubuntu');
      expect(wsl.root, r'\\wsl.localhost\Ubuntu');
      expect(wsl.rest, isEmpty);
    });

    test('parses nested path and preserves host casing', () {
      final wsl = parseWslPath(r'\\wsl.localhost\Ubuntu-22.04\home\bob');
      expect(wsl!.distro, 'Ubuntu-22.04');
      expect(wsl.root, r'\\wsl.localhost\Ubuntu-22.04');
      expect(wsl.rest, ['home', 'bob']);
    });

    test('accepts legacy wsl\$ host', () {
      final wsl = parseWslPath(r'\\wsl$\Debian\etc');
      expect(wsl!.distro, 'Debian');
      expect(wsl.root, r'\\wsl$\Debian');
      expect(wsl.rest, ['etc']);
    });

    test('accepts forward slashes', () {
      final wsl = parseWslPath('//wsl.localhost/Ubuntu/home');
      expect(wsl!.distro, 'Ubuntu');
      expect(wsl.rest, ['home']);
    });

    test('returns null for non-wsl UNC and local paths', () {
      expect(parseWslPath(r'\\server\share\file'), isNull);
      expect(parseWslPath(r'C:\Users\bob'), isNull);
      expect(parseWslPath('/home/bob'), isNull);
      expect(parseWslPath(r'\\wsl.localhost\'), isNull);
    });
  });

  group('auto WSL launch from a files path', () {
    setUp(() => PlatformPaths.homePathOverrideForTesting = r'C:\Users\bob');
    tearDown(() => PlatformPaths.homePathOverrideForTesting = null);

    test('a WSL path resolves to a wsl.exe launch in that distro', () {
      const path = r'\\wsl.localhost\Ubuntu\home\bob\src';
      final wsl = parseWslPath(path);
      expect(wsl, isNotNull);
      final spec = TerminalLaunch.forWsl(wsl!.distro, path);
      expect(spec.shell, 'wsl.exe');
      expect(spec.args, ['-d', 'Ubuntu', '--cd', path]);
      expect(spec.cwd, r'C:\Users\bob');
    });
  });
}
