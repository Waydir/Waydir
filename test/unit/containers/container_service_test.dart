import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/features/containers/container_service.dart';

List<int> _utf16le(String s, {bool bom = true}) {
  final bytes = <int>[];
  if (bom) bytes.addAll([0xFF, 0xFE]);
  for (final unit in s.codeUnits) {
    bytes.add(unit & 0xFF);
    bytes.add((unit >> 8) & 0xFF);
  }

  return bytes;
}

void main() {
  group('parseWslNames', () {
    test('decodes UTF-16LE with BOM and CRLF line endings', () {
      final bytes = _utf16le('Ubuntu\r\nDebian\r\n');
      expect(parseWslNames(bytes), ['Ubuntu', 'Debian']);
    });

    test('handles no BOM and LF endings', () {
      final bytes = _utf16le('Ubuntu-22.04\nkali-linux\n', bom: false);
      expect(parseWslNames(bytes), ['Ubuntu-22.04', 'kali-linux']);
    });

    test('drops blank lines and trims whitespace', () {
      final bytes = _utf16le('  Ubuntu  \r\n\r\n');
      expect(parseWslNames(bytes), ['Ubuntu']);
    });

    test('returns empty for empty input', () {
      expect(parseWslNames(const []), isEmpty);
    });
  });
}
