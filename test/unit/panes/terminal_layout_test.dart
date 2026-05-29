import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/features/panes/terminal_layout.dart';

void main() {
  group('TerminalLayout.reassignForDual', () {
    test('keeps active terminals that already belong to their slot', () {
      final active = TerminalLayout.reassignForDual(
        {0: 1, 1: 2},
        const [TerminalRef(1, 0), TerminalRef(2, 1)],
      );

      expect(active, {0: 1, 1: 2});
    });

    test('falls back to the first terminal of a slot when active is wrong', () {
      final active = TerminalLayout.reassignForDual(
        {0: 99},
        const [TerminalRef(1, 0), TerminalRef(2, 0), TerminalRef(3, 1)],
      );

      expect(active[0], 1);
      expect(active[1], 3);
    });

    test('drops a slot that has no terminals', () {
      final active = TerminalLayout.reassignForDual(
        {0: 1, 1: 5},
        const [TerminalRef(1, 0)],
      );

      expect(active, {0: 1});
      expect(active.containsKey(1), isFalse);
    });
  });

  group('TerminalLayout.mergeForSingle', () {
    test('prefers the terminal active in the preferred slot', () {
      final active = TerminalLayout.mergeForSingle({0: 1, 1: 2}, [1, 2], 1);

      expect(active[0], 2);
    });

    test('keeps slot 0 when the preferred terminal is gone', () {
      final active = TerminalLayout.mergeForSingle({0: 1, 1: 99}, [1, 2], 1);

      expect(active[0], 1);
    });

    test('falls back to the first terminal when both are gone', () {
      final active = TerminalLayout.mergeForSingle({0: 8, 1: 9}, [1, 2], 1);

      expect(active[0], 1);
    });

    test('drops slot 0 when nothing remains', () {
      final active = TerminalLayout.mergeForSingle({0: 8, 1: 9}, const [], 1);

      expect(active.containsKey(0), isFalse);
    });
  });

  group('TerminalLayout.mergeVisibilityForSingle', () {
    test('ors the two slots into the first', () {
      expect(TerminalLayout.mergeVisibilityForSingle([false, true]), [
        true,
        true,
      ]);
      expect(TerminalLayout.mergeVisibilityForSingle([false, false]), [
        false,
        false,
      ]);
    });

    test('handles a single-element list', () {
      expect(TerminalLayout.mergeVisibilityForSingle([true]), [true, false]);
    });
  });

  group('TerminalLayout.replacementId', () {
    test('returns null when the slot held a single terminal', () {
      expect(TerminalLayout.replacementId([1], 1, const []), isNull);
    });

    test('picks the previous terminal when a middle one closes', () {
      expect(TerminalLayout.replacementId([1, 2, 3], 2, [1, 3]), 1);
    });

    test('picks the next terminal when the first closes', () {
      expect(TerminalLayout.replacementId([1, 2, 3], 1, [2, 3]), 2);
    });

    test('falls back to a remaining terminal when the candidate is gone', () {
      expect(TerminalLayout.replacementId([1, 2], 2, [5]), 5);
    });
  });
}
