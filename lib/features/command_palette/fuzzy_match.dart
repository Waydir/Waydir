/// Result of fuzzy-matching a query against a candidate string.
class FuzzyMatch {
  final int score;
  final List<int> matchedIndices;

  const FuzzyMatch(this.score, this.matchedIndices);
}

/// Scores [query] as a subsequence of [text]. Returns `null` when [query] is
/// not a subsequence of [text]. An empty query always matches with score 0.
///
/// Higher scores are better. Bonuses are awarded for matches at the start of
/// the text, at word boundaries (after a separator or on a CamelCase hump) and
/// for consecutive runs.
FuzzyMatch? fuzzyMatch(String query, String text) {
  if (query.isEmpty) return const FuzzyMatch(0, []);
  if (text.isEmpty) return null;

  final q = query.toLowerCase();
  final lower = text.toLowerCase();

  final indices = <int>[];
  int score = 0;
  int textIndex = 0;
  int run = 0;

  for (int qi = 0; qi < q.length; qi++) {
    final ch = q.codeUnitAt(qi);
    int found = -1;
    for (int ti = textIndex; ti < lower.length; ti++) {
      if (lower.codeUnitAt(ti) == ch) {
        found = ti;
        break;
      }
    }
    if (found == -1) return null;

    score += 1;
    if (found == 0) score += 8;
    if (_isWordBoundary(text, lower, found)) score += 6;
    if (found == textIndex && qi > 0) {
      run += 1;
      score += run * 2;
    } else {
      run = 0;
    }
    score -= (found - textIndex).clamp(0, 4);

    indices.add(found);
    textIndex = found + 1;
  }

  score -= (text.length - q.length) ~/ 8;

  return FuzzyMatch(score, indices);
}

bool _isWordBoundary(String text, String lower, int index) {
  if (index == 0) return true;
  final prev = lower.codeUnitAt(index - 1);
  if (prev == 0x20 || prev == 0x2d || prev == 0x5f || prev == 0x2f) {
    return true;
  }
  final isUpper = text.codeUnitAt(index) != lower.codeUnitAt(index);
  return isUpper;
}
