import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/fs/file_sort.dart';
import 'package:waydir/core/models/file_entry.dart';

FileEntry _file(String name) => FileEntry(
  name: name,
  path: '/$name',
  type: FileItemType.file,
  size: 0,
  modified: DateTime(2026),
);

FileEntry _fileSize(String name, int size) => FileEntry(
  name: name,
  path: '/$name',
  type: FileItemType.file,
  size: size,
  modified: DateTime(2026),
);

FileEntry _folderSize(String name, int size) => FileEntry(
  name: name,
  path: '/$name',
  type: FileItemType.folder,
  size: size,
  modified: DateTime(2026),
);

FileEntry _folder(String name) => FileEntry(
  name: name,
  path: '/$name',
  type: FileItemType.folder,
  size: 0,
  modified: DateTime(2026),
);

List<String> _sortedNames(List<String> names, {required bool naturalSort}) {
  final sorted = sortEntries(
    names.map(_file).toList(),
    key: SortKey.name,
    ascending: true,
    foldersFirst: false,
    naturalSort: naturalSort,
  );
  return sorted.map((e) => e.name).toList();
}

void main() {
  group('compareNatural', () {
    test('orders numeric runs by value', () {
      expect(compareNatural('file2', 'file10'), lessThan(0));
      expect(compareNatural('10', '2'), greaterThan(0));
      expect(compareNatural('img7', 'img7'), 0);
    });

    test('handles leading zeros and trailing text', () {
      expect(compareNatural('v1', 'v01'), lessThan(0));
      expect(compareNatural('a10b2', 'a10b10'), lessThan(0));
    });
  });

  group('sortEntries naturalSort', () {
    test('lexicographic order without natural sort', () {
      expect(
        _sortedNames(['10', '100', '1000', '2', '200'], naturalSort: false),
        ['10', '100', '1000', '2', '200'],
      );
    });

    test('numeric order with natural sort', () {
      expect(
        _sortedNames(['10', '100', '1000', '2', '200'], naturalSort: true),
        ['2', '10', '100', '200', '1000'],
      );
    });
  });

  group('sortEntries sortFolders', () {
    test('folders keep name-ascending order when sortFolders is off', () {
      final entries = [
        _folder('beta'),
        _folder('alpha'),
        _file('c.txt'),
        _file('a.txt'),
      ];
      final sorted = sortEntries(
        entries,
        key: SortKey.name,
        ascending: false,
        foldersFirst: true,
        sortFolders: false,
      );
      expect(sorted.map((e) => e.name).toList(), [
        'alpha',
        'beta',
        'c.txt',
        'a.txt',
      ]);
    });

    test('folders follow the sort direction when sortFolders is on', () {
      final entries = [_folder('alpha'), _folder('beta')];
      final sorted = sortEntries(
        entries,
        key: SortKey.name,
        ascending: false,
        foldersFirst: true,
        sortFolders: true,
      );
      expect(sorted.map((e) => e.name).toList(), ['beta', 'alpha']);
    });
  });

  group('sortEntries size with folders', () {
    test('folders count as 0 and keep name order, ascending', () {
      final entries = [
        _folderSize('zeta', 4096),
        _folderSize('alpha', 4096),
        _fileSize('big.bin', 5000),
        _fileSize('small.txt', 100),
      ];
      final sorted = sortEntries(
        entries,
        key: SortKey.size,
        ascending: true,
        foldersFirst: false,
      );
      expect(sorted.map((e) => e.name).toList(), [
        'alpha',
        'zeta',
        'small.txt',
        'big.bin',
      ]);
    });

    test('folders stay name-ascending even when size is descending', () {
      final entries = [
        _folderSize('zeta', 4096),
        _folderSize('alpha', 4096),
        _fileSize('big.bin', 5000),
        _fileSize('small.txt', 100),
      ];
      final sorted = sortEntries(
        entries,
        key: SortKey.size,
        ascending: false,
        foldersFirst: false,
      );
      expect(sorted.map((e) => e.name).toList(), [
        'big.bin',
        'small.txt',
        'alpha',
        'zeta',
      ]);
    });
  });

  group('sortEntries size with computed folder sizes', () {
    test('folders with a computed size sort by it, ascending', () {
      final entries = [
        _folder('big'),
        _folder('small'),
        _fileSize('mid.bin', 500),
      ];
      final computed = {'/big': 9000, '/small': 100};
      final sorted = sortEntries(
        entries,
        key: SortKey.size,
        ascending: true,
        foldersFirst: false,
        folderSize: (e) => computed[e.path],
      );
      expect(sorted.map((e) => e.name).toList(), ['small', 'mid.bin', 'big']);
    });

    test('uncomputed folders stay name-ordered, computed ones sort', () {
      final entries = [
        _folder('zeta'),
        _folder('alpha'),
        _folder('huge'),
        _fileSize('mid.bin', 500),
      ];
      final computed = {'/huge': 9000};
      final sorted = sortEntries(
        entries,
        key: SortKey.size,
        ascending: true,
        foldersFirst: false,
        folderSize: (e) => computed[e.path],
      );
      expect(sorted.map((e) => e.name).toList(), [
        'alpha',
        'zeta',
        'mid.bin',
        'huge',
      ]);
    });
  });
}
