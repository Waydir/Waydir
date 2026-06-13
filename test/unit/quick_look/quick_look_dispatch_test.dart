import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/features/quick_look/quick_look_common.dart';

void main() {
  group('Quick Look extension routing', () {
    test('pdf routes to the PDF preview, not the binary fallback', () {
      expect(pdfExts.contains('pdf'), isTrue);
      expect(binaryExts.contains('pdf'), isFalse);
    });

    test('extension sets do not overlap', () {
      expect(pdfExts.intersection(binaryExts), isEmpty);
      expect(pdfExts.intersection(imageExts), isEmpty);
    });
  });
}
