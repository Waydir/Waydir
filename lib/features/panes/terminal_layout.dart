class TerminalRef {
  final int id;
  final int originPane;

  const TerminalRef(this.id, this.originPane);
}

class TerminalLayout {
  TerminalLayout._();

  /// Reassigns each slot's active terminal so it points to one of its own
  /// terminals when entering dual mode. Slots without any terminal are dropped.
  static Map<int, int> reassignForDual(
    Map<int, int> active,
    List<TerminalRef> terminals,
  ) {
    final next = Map<int, int>.from(active);
    final slot0 = terminals.where((t) => t.originPane == 0).toList();
    final slot1 = terminals.where((t) => t.originPane == 1).toList();
    if (!slot0.any((t) => t.id == next[0])) {
      if (slot0.isEmpty) {
        next.remove(0);
      } else {
        next[0] = slot0.first.id;
      }
    }
    if (!slot1.any((t) => t.id == next[1])) {
      if (slot1.isEmpty) {
        next.remove(1);
      } else {
        next[1] = slot1.first.id;
      }
    }

    return next;
  }

  /// Collapses two slots into one when exiting dual mode, preferring the
  /// terminal active in [preferredSlot], then slot 0's current terminal, then
  /// the first available one.
  static Map<int, int> mergeForSingle(
    Map<int, int> active,
    List<int> allIds,
    int preferredSlot,
  ) {
    final next = Map<int, int>.from(active);
    final preferredId = active[preferredSlot];
    if (preferredId != null && allIds.contains(preferredId)) {
      next[0] = preferredId;
    } else if (next[0] != null && allIds.contains(next[0])) {
      // keep the existing slot 0 terminal
    } else if (allIds.isNotEmpty) {
      next[0] = allIds.first;
    } else {
      next.remove(0);
    }

    return next;
  }

  /// Merges per-slot visibility into a single visible slot when exiting dual.
  static List<bool> mergeVisibilityForSingle(List<bool> visible) {
    if (visible.length > 1) {
      return [visible.first || visible[1], visible[1]];
    }

    return [visible.isEmpty ? false : visible.first, false];
  }

  /// Picks the terminal that becomes active after [closedId] is removed from a
  /// slot. [visibleOrder] is the ordered ids the slot held before the close and
  /// [remainingIds] the ids still alive afterwards. Returns null when the slot
  /// should be emptied and hidden.
  static int? replacementId(
    List<int> visibleOrder,
    int closedId,
    List<int> remainingIds,
  ) {
    if (visibleOrder.length <= 1) return null;
    final closedIndex = visibleOrder.indexOf(closedId);
    final replacementIndex = closedIndex <= 0 ? 0 : closedIndex - 1;
    final candidate = visibleOrder[replacementIndex] == closedId
        ? visibleOrder[(replacementIndex + 1).clamp(0, visibleOrder.length - 1)]
        : visibleOrder[replacementIndex];
    if (remainingIds.contains(candidate)) return candidate;

    return remainingIds.isEmpty ? null : remainingIds.first;
  }
}
