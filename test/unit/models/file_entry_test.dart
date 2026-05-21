import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/models/file_entry.dart';

void main() {
  group('FileEntry', () {
    test('extension returns empty for folders', () {
      final entry = FileEntry(
        name: 'my_folder',
        path: '/home/user/my_folder',
        type: FileItemType.folder,
        size: 4096,
        modified: DateTime(2025, 1, 1),
      );
      expect(entry.extension, '');
    });

    test('extension returns correct value for files', () {
      final entry = FileEntry(
        name: 'script.dart',
        path: '/home/user/script.dart',
        type: FileItemType.file,
        size: 1024,
        modified: DateTime(2025, 1, 1),
      );
      expect(entry.extension, 'dart');
    });

    test('extension is lowercase', () {
      final entry = FileEntry(
        name: 'photo.JPG',
        path: '/home/user/photo.JPG',
        type: FileItemType.file,
        size: 2048,
        modified: DateTime(2025, 1, 1),
      );
      expect(entry.extension, 'jpg');
    });

    test('extension returns empty for files without extension', () {
      final entry = FileEntry(
        name: 'Makefile',
        path: '/home/user/Makefile',
        type: FileItemType.file,
        size: 512,
        modified: DateTime(2025, 1, 1),
      );
      expect(entry.extension, '');
    });

    test('extension handles dotfiles correctly', () {
      final entry = FileEntry(
        name: '.gitignore',
        path: '/home/user/.gitignore',
        type: FileItemType.file,
        size: 128,
        modified: DateTime(2025, 1, 1),
      );
      expect(entry.extension, 'gitignore');
    });

    test('extension handles double extensions', () {
      final entry = FileEntry(
        name: 'archive.tar.gz',
        path: '/home/user/archive.tar.gz',
        type: FileItemType.file,
        size: 4096,
        modified: DateTime(2025, 1, 1),
      );
      expect(entry.extension, 'gz');
    });

    test('stores all properties correctly', () {
      final date = DateTime(2025, 6, 15, 10, 30);
      final entry = FileEntry(
        name: 'test.txt',
        path: '/tmp/test.txt',
        type: FileItemType.file,
        size: 999,
        modified: date,
      );
      expect(entry.name, 'test.txt');
      expect(entry.path, '/tmp/test.txt');
      expect(entry.type, FileItemType.file);
      expect(entry.size, 999);
      expect(entry.modified, date);
    });

    test('isHidden returns true for dotfiles', () {
      final entry = FileEntry(
        name: '.gitignore',
        path: '/home/user/.gitignore',
        type: FileItemType.file,
        size: 128,
        modified: DateTime(2025, 1, 1),
      );
      expect(entry.isHidden, true);
    });

    test('isHidden returns true for hidden folders', () {
      final entry = FileEntry(
        name: '.config',
        path: '/home/user/.config',
        type: FileItemType.folder,
        size: 4096,
        modified: DateTime(2025, 1, 1),
      );
      expect(entry.isHidden, true);
    });

    test('isHidden returns false for normal files', () {
      final entry = FileEntry(
        name: 'readme.md',
        path: '/home/user/readme.md',
        type: FileItemType.file,
        size: 256,
        modified: DateTime(2025, 1, 1),
      );
      expect(entry.isHidden, false);
    });
  });
}
