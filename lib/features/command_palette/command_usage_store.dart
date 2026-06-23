/// Tracks how often and how recently each command is invoked, so the palette
/// can float frequently used commands to the top when the query is empty.
///
/// In-session only; usage resets on restart.
class CommandUsageStore {
  CommandUsageStore._();
  static final instance = CommandUsageStore._();

  final Map<String, int> _counts = {};
  int _tick = 0;
  final Map<String, int> _lastUsed = {};

  void record(String id) {
    _counts.update(id, (v) => v + 1, ifAbsent: () => 1);
    _lastUsed[id] = ++_tick;
  }

  /// Command ids ordered by a frecency score (recent + frequent first).
  List<String> rankedIds() {
    final ids = _counts.keys.toList();
    ids.sort((a, b) {
      final byRecent = (_lastUsed[b] ?? 0).compareTo(_lastUsed[a] ?? 0);
      if (byRecent != 0) return byRecent;
      return (_counts[b] ?? 0).compareTo(_counts[a] ?? 0);
    });
    return ids;
  }

  void clear() {
    _counts.clear();
    _lastUsed.clear();
    _tick = 0;
  }
}
