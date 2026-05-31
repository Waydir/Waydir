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
}
