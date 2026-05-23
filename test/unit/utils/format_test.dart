import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/utils/format.dart';

void main() {
  group('formatDurationShort', () {
    test('formats subsecond durations', () {
      expect(formatDurationShort(Duration.zero), '<1s');
      expect(formatDurationShort(const Duration(milliseconds: 500)), '<1s');
    });

    test('formats seconds', () {
      expect(formatDurationShort(const Duration(seconds: 42)), '42s');
    });

    test('formats minutes with seconds', () {
      expect(formatDurationShort(const Duration(seconds: 80)), '1m 20s');
    });

    test('formats hours with minutes', () {
      expect(formatDurationShort(const Duration(minutes: 125)), '2h 5m');
    });
  });
}
