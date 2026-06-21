import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/models/file_entry.dart';
import 'package:waydir/features/compare/compare_diff.dart';

void main() {
  FileEntry entry(
    String path, {
    int size = 1,
    int ms = 10000,
    FileItemType type = FileItemType.file,
  }) {
    return FileEntry.raw(
      name: path.split('/').last,
      path: path,
      type: type,
      size: size,
      modifiedMs: ms,
    );
  }

  test('classifies unique newer older and identical files', () {
    final diff = buildCompareDiff(
      leftRoot: '/left',
      rightRoot: '/right',
      leftEntries: [
        entry('/left/only-left.txt'),
        entry('/left/newer.txt', ms: 20000),
        entry('/left/older.txt', ms: 10000),
        entry('/left/same.txt', size: 7, ms: 30000),
      ],
      rightEntries: [
        entry('/right/only-right.txt'),
        entry('/right/newer.txt', ms: 10000),
        entry('/right/older.txt', ms: 20000),
        entry('/right/same.txt', size: 7, ms: 30000),
      ],
    );

    expect(diff.left['/left/only-left.txt']!.status, CompareStatus.unique);
    expect(diff.right['/right/only-right.txt']!.status, CompareStatus.unique);
    expect(diff.left['/left/newer.txt']!.status, CompareStatus.newer);
    expect(diff.right['/right/newer.txt']!.status, CompareStatus.older);
    expect(diff.left['/left/older.txt']!.status, CompareStatus.older);
    expect(diff.right['/right/older.txt']!.status, CompareStatus.newer);
    expect(diff.left['/left/same.txt']!.status, CompareStatus.identical);
    expect(diff.counts.identical, 1);
    expect(diff.counts.differ, 2);
    expect(diff.counts.uniqueLeft, 1);
    expect(diff.counts.uniqueRight, 1);
  });

  test('mtime tolerance treats close mtimes as identical', () {
    final diff = buildCompareDiff(
      leftRoot: '/left',
      rightRoot: '/right',
      leftEntries: [entry('/left/file.txt', size: 4, ms: 10000)],
      rightEntries: [entry('/right/file.txt', size: 4, ms: 11999)],
    );

    expect(diff.left['/left/file.txt']!.status, CompareStatus.identical);
    expect(diff.right['/right/file.txt']!.status, CompareStatus.identical);
    expect(diff.counts.identical, 1);
  });

  test('same mtime but different size is differ', () {
    final diff = buildCompareDiff(
      leftRoot: '/left',
      rightRoot: '/right',
      leftEntries: [entry('/left/file.txt', size: 4, ms: 10000)],
      rightEntries: [entry('/right/file.txt', size: 5, ms: 10000)],
    );

    expect(diff.left['/left/file.txt']!.status, CompareStatus.differ);
    expect(diff.right['/right/file.txt']!.status, CompareStatus.differ);
  });

  test('recursive folder is marked differing from child differences', () {
    final diff = buildCompareDiff(
      leftRoot: '/left',
      rightRoot: '/right',
      leftEntries: [
        entry('/left/folder', type: FileItemType.folder, ms: 10000),
        entry('/left/folder/child.txt', ms: 30000),
      ],
      rightEntries: [
        entry('/right/folder', type: FileItemType.folder, ms: 10000),
        entry('/right/folder/child.txt', ms: 10000),
      ],
    );

    expect(diff.left['/left/folder']!.status, CompareStatus.newer);
    expect(diff.right['/right/folder']!.status, CompareStatus.older);
  });
}
