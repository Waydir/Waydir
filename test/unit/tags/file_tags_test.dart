import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Tags', () {
    test('seeds the default palette on first open', () async {
      final tags = await db.getTags();

      expect(tags.length, 4);
      expect(tags.first.name, 'Red');
      expect(tags.map((t) => t.orderIndex), [0, 1, 2, 3]);
    });

    test('create, update and delete a tag', () async {
      final id = await db.createTag('Work', 0xFF112233, 7);
      var tags = await db.getTags();
      expect(tags.any((t) => t.id == id && t.name == 'Work'), isTrue);

      await db.updateTag(id, name: 'Job', color: 0xFF445566);
      tags = await db.getTags();
      final updated = tags.firstWhere((t) => t.id == id);
      expect(updated.name, 'Job');
      expect(updated.color, 0xFF445566);

      await db.deleteTag(id);
      tags = await db.getTags();
      expect(tags.any((t) => t.id == id), isFalse);
    });

    test('deleting a tag removes its file assignments', () async {
      final id = await db.createTag('Temp', 0xFF000000, 7);
      await db.addFileTag('/a.txt', id);
      await db.addFileTag('/b.txt', id);

      await db.deleteTag(id);

      expect(await db.getPathsForTag(id), isEmpty);
    });
  });

  group('FileTags', () {
    late int red;
    late int blue;

    setUp(() async {
      final tags = await db.getTags();
      red = tags.firstWhere((t) => t.name == 'Red').id;
      blue = tags.firstWhere((t) => t.name == 'Blue').id;
    });

    test('add and query tags for paths', () async {
      await db.addFileTag('/a.txt', red);
      await db.addFileTag('/a.txt', blue);
      await db.addFileTag('/b.txt', red);

      final rows = await db.getFileTagsForPaths(['/a.txt', '/b.txt']);
      expect(rows.length, 3);

      expect((await db.getPathsForTag(red))..sort(), ['/a.txt', '/b.txt']);
      expect(await db.getPathsForTag(blue), ['/a.txt']);
    });

    test('adding the same tag twice is idempotent', () async {
      await db.addFileTag('/a.txt', red);
      await db.addFileTag('/a.txt', red);

      expect(await db.getPathsForTag(red), ['/a.txt']);
    });

    test('remove a single tag and clear all tags', () async {
      await db.addFileTag('/a.txt', red);
      await db.addFileTag('/a.txt', blue);

      await db.removeFileTag('/a.txt', red);
      expect(await db.getPathsForTag(red), isEmpty);
      expect(await db.getPathsForTag(blue), ['/a.txt']);

      await db.clearFileTags('/a.txt');
      expect(await db.getPathsForTag(blue), isEmpty);
    });

    test('moveFileTags follows a renamed path', () async {
      await db.addFileTag('/old.txt', red);
      await db.addFileTag('/old.txt', blue);

      await db.moveFileTags('/old.txt', '/new.txt');

      expect(await db.getFileTagsForPaths(['/old.txt']), isEmpty);
      final rows = await db.getFileTagsForPaths(['/new.txt']);
      expect(rows.map((r) => r.tagId)..toList(), containsAll([red, blue]));
    });
  });
}
