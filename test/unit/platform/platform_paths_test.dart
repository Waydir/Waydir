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

    test('detects share roots', () {
      expect(PlatformPaths.isRoot(r'\\192.168.32.12\adssad'), isTrue);
      expect(PlatformPaths.isRoot(r'\\192.168.32.12\adssad\'), isTrue);
      expect(PlatformPaths.isRoot(r'\\192.168.32.12\adssad\folder'), isFalse);
    });

    test('returns the share root as parent boundary', () {
      expect(
        PlatformPaths.parentOf(r'\\192.168.32.12\adssad\folder'),
        r'\\192.168.32.12\adssad',
      );
      expect(
        PlatformPaths.parentOf(r'\\192.168.32.12\adssad'),
        r'\\192.168.32.12\adssad\',
      );
    });

    test('builds breadcrumb segments and partial paths', () {
      final segments = PlatformPaths.segments(
        r'\\192.168.32.12\adssad\folder\child',
      );

      expect(segments, [r'\\192.168.32.12\adssad', 'folder', 'child']);
      expect(
        PlatformPaths.buildPartialPath(segments, 0),
        r'\\192.168.32.12\adssad\',
      );
      expect(
        PlatformPaths.buildPartialPath(segments, 1),
        r'\\192.168.32.12\adssad\folder',
      );
      expect(
        PlatformPaths.buildPartialPath(segments, 2),
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
}
