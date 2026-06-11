import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/platform/platform_paths.dart';

void main() {
  group('PlatformPaths Windows UNC paths', () {
    setUp(() {
      PlatformPaths.isWindowsOverrideForTesting = true;
    });

    tearDown(() {
      PlatformPaths.isWindowsOverrideForTesting = null;
    });

    test('normalizes forward slashes without losing the UNC root', () {
      expect(
        PlatformPaths.normalize('//192.168.32.12/adssad/folder'),
        r'\\192.168.32.12\adssad\folder',
      );
    });

    test('treats the server as root, not the share', () {
      expect(PlatformPaths.isRoot(r'\\192.168.32.12'), isTrue);
      expect(PlatformPaths.isRoot(r'\\192.168.32.12\'), isTrue);
      expect(PlatformPaths.isRoot(r'\\192.168.32.12\adssad'), isFalse);
      expect(PlatformPaths.isRoot(r'\\192.168.32.12\adssad\folder'), isFalse);
    });

    test('detects a UNC server root with no share', () {
      expect(
        PlatformPaths.windowsUncServerRoot(r'\\computername'),
        'computername',
      );
      expect(
        PlatformPaths.windowsUncServerRoot(r'\\computername\'),
        'computername',
      );
      expect(
        PlatformPaths.windowsUncServerRoot('//computername'),
        'computername',
      );
      expect(
        PlatformPaths.windowsUncServerRoot(r'\\192.168.32.12'),
        '192.168.32.12',
      );
    });

    test('is not a server root once a share is present', () {
      expect(
        PlatformPaths.windowsUncServerRoot(r'\\computername\share'),
        isNull,
      );
      expect(
        PlatformPaths.windowsUncServerRoot(r'\\computername\share\sub'),
        isNull,
      );
      expect(PlatformPaths.windowsUncServerRoot(r'C:\Users'), isNull);
    });

    test('walks up from share to server as parent boundary', () {
      expect(
        PlatformPaths.parentOf(r'\\192.168.32.12\adssad\folder'),
        r'\\192.168.32.12\adssad',
      );
      expect(
        PlatformPaths.parentOf(r'\\192.168.32.12\adssad'),
        r'\\192.168.32.12',
      );
      expect(PlatformPaths.parentOf(r'\\192.168.32.12'), r'\\192.168.32.12\');
    });

    test('builds breadcrumb segments and partial paths', () {
      final segments = PlatformPaths.segments(
        r'\\192.168.32.12\adssad\folder\child',
      );

      expect(segments, [r'\\192.168.32.12', 'adssad', 'folder', 'child']);
      expect(PlatformPaths.buildPartialPath(segments, 0), r'\\192.168.32.12\');
      expect(
        PlatformPaths.buildPartialPath(segments, 1),
        r'\\192.168.32.12\adssad',
      );
      expect(
        PlatformPaths.buildPartialPath(segments, 2),
        r'\\192.168.32.12\adssad\folder',
      );
      expect(
        PlatformPaths.buildPartialPath(segments, 3),
        r'\\192.168.32.12\adssad\folder\child',
      );
    });

    test('uses Windows path rules for file names and joins', () {
      expect(
        PlatformPaths.fileName(r'\\192.168.32.12\adssad\file.txt'),
        'file.txt',
      );
      expect(
        PlatformPaths.join(r'\\192.168.32.12\adssad', 'folder'),
        r'\\192.168.32.12\adssad\folder',
      );
    });
  });

  group('PlatformPaths.expandTilde', () {
    setUp(() {
      PlatformPaths.homePathOverrideForTesting = '/home/tester';
    });

    tearDown(() {
      PlatformPaths.homePathOverrideForTesting = null;
      PlatformPaths.isWindowsOverrideForTesting = null;
    });

    test('expands a bare tilde to the home directory', () {
      expect(PlatformPaths.expandTilde('~'), '/home/tester');
    });

    test('expands ~/ to a path inside the home directory', () {
      expect(PlatformPaths.expandTilde('~/Documents'), '/home/tester/Documents');
      expect(PlatformPaths.expandTilde('~/a/b'), '/home/tester/a/b');
    });

    test('leaves absolute paths unchanged', () {
      expect(PlatformPaths.expandTilde('/etc/passwd'), '/etc/passwd');
    });

    test('does not expand ~user', () {
      expect(PlatformPaths.expandTilde('~user'), '~user');
      expect(PlatformPaths.expandTilde('~user/docs'), '~user/docs');
    });

    test('leaves remote URIs unchanged', () {
      expect(
        PlatformPaths.expandTilde('smb://server/share'),
        'smb://server/share',
      );
    });

    test('leaves an empty string unchanged', () {
      expect(PlatformPaths.expandTilde(''), '');
    });

    test('expands ~\\ on Windows', () {
      PlatformPaths.isWindowsOverrideForTesting = true;
      PlatformPaths.homePathOverrideForTesting = r'C:\Users\tester';
      expect(PlatformPaths.expandTilde(r'~\Docs'), r'C:\Users\tester\Docs');
      expect(PlatformPaths.expandTilde('~/Docs'), r'C:\Users\tester\Docs');
    });
  });
}
