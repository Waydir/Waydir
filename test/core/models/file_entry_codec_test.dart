import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/models/file_entry.dart';

void main() {
  test('FileEntryCodec round-trips entries including unicode', () {
    final entries = [
      FileEntry.raw(
        name: 'folder',
        path: '/root/folder',
        type: FileItemType.folder,
        size: 0,
        modifiedMs: 0,
      ),
      FileEntry.raw(
        name: 'zażółć gęślą.txt',
        path: '/root/zażółć gęślą.txt',
        type: FileItemType.file,
        size: 123456789012,
        modifiedMs: 1715900000000,
      ),
      FileEntry.raw(
        name: '',
        path: '/root/',
        type: FileItemType.file,
        size: 0,
        modifiedMs: -1,
      ),
    ];

    final decoded = FileEntryCodec.decode(FileEntryCodec.encode(entries));

    expect(decoded.length, entries.length);
    for (var i = 0; i < entries.length; i++) {
      expect(decoded[i].name, entries[i].name);
      expect(decoded[i].path, entries[i].path);
      expect(decoded[i].type, entries[i].type);
      expect(decoded[i].size, entries[i].size);
      expect(decoded[i].modifiedMs, entries[i].modifiedMs);
    }
  });

  test('FileEntryCodec rejects a malformed blob', () {
    expect(
      () =>
          FileEntryCodec.decode(FileEntryCodec.encode([])..fillRange(0, 4, 0)),
      throwsFormatException,
    );
  });
}
