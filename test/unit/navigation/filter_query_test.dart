import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/models/file_entry.dart';
import 'package:waydir/features/navigation/filter_query.dart';

FileEntry _file(
  String name, {
  int size = 0,
  DateTime? modified,
  DateTime? created,
}) {
  final date = modified ?? DateTime(2026, 6, 13, 12);
  return FileEntry(
    name: name,
    path: '/$name',
    type: FileItemType.file,
    size: size,
    modified: date,
    created: created ?? date,
  );
}

FileEntry _folder(String name) => FileEntry(
  name: name,
  path: '/$name',
  type: FileItemType.folder,
  size: 0,
  modified: DateTime(2026, 6, 13, 12),
);

void main() {
  group('parseFilterQuery', () {
    test('matches name terms and extensions', () {
      final parsed = parseFilterQuery('invoice ext:pdf,docx').query!;

      expect(parsed.matches(_file('invoice.pdf')), true);
      expect(parsed.matches(_file('invoice.docx')), true);
      expect(parsed.matches(_file('notes.pdf')), false);
      expect(parsed.matches(_file('invoice.png')), false);
    });

    test('matches kind categories', () {
      final parsed = parseFilterQuery('kind:image').query!;

      expect(parsed.matches(_file('photo.png')), true);
      expect(parsed.matches(_file('main.dart')), false);
      expect(parsed.matches(_folder('Pictures')), false);
    });

    test('matches size comparisons', () {
      final parsed = parseFilterQuery('size:>10mb').query!;

      expect(parsed.matches(_file('large.zip', size: 11 * 1024 * 1024)), true);
      expect(parsed.matches(_file('small.zip', size: 9 * 1024 * 1024)), false);
    });

    test('matches modified ranges', () {
      final parsed = parseFilterQuery('modified:week').query!;
      final now = DateTime(2026, 6, 13, 12);

      expect(
        parsed.matches(
          _file('recent.txt', modified: DateTime(2026, 6, 10)),
          now: now,
        ),
        true,
      );
      expect(
        parsed.matches(
          _file('old.txt', modified: DateTime(2026, 5, 1)),
          now: now,
        ),
        false,
      );
    });

    test('matches hidden files', () {
      final parsed = parseFilterQuery('hidden:true').query!;

      expect(parsed.matches(_file('.env')), true);
      expect(parsed.matches(_file('env.txt')), false);
    });

    test('reports unknown filters', () {
      final parsed = parseFilterQuery('owner:me');

      expect(parsed.error, 'Unknown filter: owner');
    });
  });

  group('filterSuggestions', () {
    test('suggests keys for the active token', () {
      final suggestions = filterSuggestions('ki', 2);

      expect(suggestions.first.label, 'kind:');
    });

    test('suggests values after a key', () {
      final suggestions = filterSuggestions('kind:im', 7);

      expect(suggestions.first.label, 'kind:image');
    });

    test('applies suggestion to the active token', () {
      final suggestion = filterSuggestions('kind:im size', 7).first;
      final next = applyFilterSuggestion('kind:im size', 7, suggestion);

      expect(next, 'kind:image size');
    });

    test('does not add a space after key suggestions', () {
      final suggestion = filterSuggestions('ty', 2).first;
      final next = applyFilterSuggestion('ty', 2, suggestion);

      expect(next, 'type:');
    });
  });
}
