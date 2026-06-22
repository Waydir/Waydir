import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/features/command_palette/fuzzy_match.dart';

void main() {
  group('fuzzyMatch', () {
    test('empty query matches everything with score 0', () {
      final m = fuzzyMatch('', 'Anything');
      expect(m, isNotNull);
      expect(m!.score, 0);
      expect(m.matchedIndices, isEmpty);
    });

    test('returns null when query is not a subsequence', () {
      expect(fuzzyMatch('xyz', 'New folder'), isNull);
    });

    test('matches a subsequence and records indices', () {
      final m = fuzzyMatch('nf', 'New folder');
      expect(m, isNotNull);
      expect(m!.matchedIndices, [0, 4]);
    });

    test('prefix match scores higher than mid-word match', () {
      final prefix = fuzzyMatch('co', 'Copy')!.score;
      final mid = fuzzyMatch('co', 'Recompute')!.score;
      expect(prefix, greaterThan(mid));
    });

    test('word-boundary match scores higher than scattered match', () {
      final boundary = fuzzyMatch('nt', 'New tab')!.score;
      final scattered = fuzzyMatch('nt', 'Invert selection')!.score;
      expect(boundary, greaterThan(scattered));
    });

    test('consecutive run scores higher than gapped match', () {
      final consecutive = fuzzyMatch('cop', 'Copy')!.score;
      final gapped = fuzzyMatch('cop', 'Compute folder size')!.score;
      expect(consecutive, greaterThan(gapped));
    });

    test('is case-insensitive', () {
      expect(fuzzyMatch('PASTE', 'paste'), isNotNull);
      expect(fuzzyMatch('paste', 'PASTE'), isNotNull);
    });
  });
}
