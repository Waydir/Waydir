import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/archive/archive_reader.dart';
import 'package:waydir/core/archive/archive_service.dart';
import 'package:waydir/core/models/file_entry.dart';

void main() {
  final mtime = DateTime(2020, 1, 1);

  ArchiveEntry e(String path, {bool dir = false, int size = 0}) =>
      ArchiveEntry(path: path, size: size, isDir: dir, mtimeSeconds: 0);

  test('root level lists top-level files and synthesized dirs', () {
    final all = [
      e('a.txt', size: 5),
      e('sub/', dir: true),
      e('sub/b.txt', size: 6),
      e('deep/x/y.txt', size: 1),
    ];
    final level = ArchiveService.levelEntries('/t/x.zip', '', all, mtime);
    final byName = {for (final f in level) f.name: f};
    expect(byName.keys.toSet(), {'a.txt', 'sub', 'deep'});
    expect(byName['a.txt']!.type, FileItemType.file);
    expect(byName['a.txt']!.size, 5);
    expect(byName['sub']!.type, FileItemType.folder);
    expect(byName['deep']!.type, FileItemType.folder);
    expect(byName['a.txt']!.path, '/t/x.zip/a.txt');
  });

  test('nested level lists only immediate children', () {
    final all = [
      e('sub/b.txt', size: 6),
      e('sub/inner/c.txt', size: 2),
      e('other.txt'),
    ];
    final level = ArchiveService.levelEntries('/t/x.zip', 'sub', all, mtime);
    final names = level.map((f) => f.name).toSet();
    expect(names, {'b.txt', 'inner'});
    final inner = level.firstWhere((f) => f.name == 'inner');
    expect(inner.type, FileItemType.folder);
    expect(inner.path, '/t/x.zip/sub/inner');
  });

  test('directory entry without explicit header is still synthesized', () {
    final all = [e('only/deep/file.txt', size: 3)];
    final level = ArchiveService.levelEntries('/t/x.zip', '', all, mtime);
    expect(level.single.name, 'only');
    expect(level.single.type, FileItemType.folder);
  });
}
