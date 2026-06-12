import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/app/launch_args.dart';
import 'package:waydir/core/platform/platform_paths.dart';

void main() {
  group('LaunchArgs.parse', () {
    late Directory temp;

    String norm(String path) => PlatformPaths.normalize(path);

    setUp(() {
      LaunchArgs.options = const LaunchOptions();
      temp = Directory.systemTemp.createTempSync('waydir_launch');
    });

    tearDown(() {
      LaunchArgs.options = const LaunchOptions();
      if (temp.existsSync()) temp.deleteSync(recursive: true);
    });

    test('collects existing folder arguments as tabs', () {
      final a = Directory('${temp.path}/a')..createSync();
      final b = Directory('${temp.path}/b')..createSync();
      LaunchArgs.parse([a.path, b.path]);
      expect(LaunchArgs.options.folders, [norm(a.path), norm(b.path)]);
      expect(LaunchArgs.options.opensLocation, isTrue);
    });

    test('treats a bare file argument as a reveal target', () {
      final file = File('${temp.path}/note.txt')..writeAsStringSync('hi');
      LaunchArgs.parse([file.path]);
      expect(LaunchArgs.options.folders, isEmpty);
      expect(LaunchArgs.options.selectPath, norm(file.path));
    });

    test('--reveal selects a file and --split sets dual pane', () {
      final file = File('${temp.path}/x.txt')..writeAsStringSync('x');
      LaunchArgs.parse(['--split', '--reveal', file.path, temp.path]);
      expect(LaunchArgs.options.split, isTrue);
      expect(LaunchArgs.options.selectPath, norm(file.path));
      expect(LaunchArgs.options.folders, [norm(temp.path)]);
    });

    test('supports --select=<file> form', () {
      final file = File('${temp.path}/y.txt')..writeAsStringSync('y');
      LaunchArgs.parse(['--select=${file.path}']);
      expect(LaunchArgs.options.selectPath, norm(file.path));
    });

    test('parses --help and --version flags', () {
      LaunchArgs.parse(['--help']);
      expect(LaunchArgs.options.showHelp, isTrue);
      LaunchArgs.parse(['-v']);
      expect(LaunchArgs.options.showVersion, isTrue);
    });

    test('ignores unknown flags and non-existent paths', () {
      LaunchArgs.parse(['--bogus', '/no/such/path/here']);
      expect(LaunchArgs.options.opensLocation, isFalse);
    });

    test('leaves options empty with no arguments', () {
      LaunchArgs.parse(const []);
      expect(LaunchArgs.options.opensLocation, isFalse);
      expect(LaunchArgs.options.split, isFalse);
    });
  });
}
