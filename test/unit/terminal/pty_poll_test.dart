import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/terminal/pty_session.dart';

void main() {
  group('nextPollInterval', () {
    const min = Duration(milliseconds: 16);
    const max = Duration(milliseconds: 120);

    test('resets to the minimum on activity', () {
      final next = nextPollInterval(
        current: max,
        active: true,
        min: min,
        max: max,
      );

      expect(next, min);
    });

    test('backs off geometrically while idle', () {
      final first = nextPollInterval(
        current: min,
        active: false,
        min: min,
        max: max,
      );
      final second = nextPollInterval(
        current: first,
        active: false,
        min: min,
        max: max,
      );

      expect(first, const Duration(milliseconds: 32));
      expect(second, const Duration(milliseconds: 64));
    });

    test('clamps the idle backoff to the maximum', () {
      final next = nextPollInterval(
        current: const Duration(milliseconds: 80),
        active: false,
        min: min,
        max: max,
      );

      expect(next, max);
    });
  });
}
