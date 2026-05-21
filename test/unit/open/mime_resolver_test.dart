import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/open/mime_resolver.dart';

void main() {
  group('MimeType', () {
    test('unknown is octet-stream', () {
      expect(MimeType.unknown.isUnknown, isTrue);
      expect(const MimeType('').isUnknown, isTrue);
      expect(const MimeType('image/png').isUnknown, isFalse);
    });
  });

  group('MimeResolver fallback', () {
    test('resolves common types by extension', () async {
      final r = MimeResolver.platform();
      final png = await r.resolve('/nonexistent/sample.png');
      expect(png.value, 'image/png');
      expect(png.isUti, isFalse);
    });

    test('returns octet-stream for unknown extensions', () async {
      final r = MimeResolver.platform();
      final unknown = await r.resolve('/nonexistent/sample.unknown_ext_xyz');
      expect(unknown, MimeType.unknown);
      expect(unknown.isUnknown, isTrue);
    });
  });
}
