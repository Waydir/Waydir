import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/fs/checksum_service.dart';

void main() {
  group('ChecksumService', () {
    test('normalizes expected checksums', () {
      expect(ChecksumService.normalizeExpected(' AB CD:12-34\n'), 'abcd1234');
    });

    test('validates algorithm-specific length', () {
      expect(
        ChecksumService.isExpectedFormatValid(
          ChecksumAlgorithm.md5,
          'd41d8cd98f00b204e9800998ecf8427e',
        ),
        isTrue,
      );
      expect(
        ChecksumService.isExpectedFormatValid(
          ChecksumAlgorithm.sha256,
          'd41d8cd98f00b204e9800998ecf8427e',
        ),
        isFalse,
      );
      expect(
        ChecksumService.isExpectedFormatValid(
          ChecksumAlgorithm.md5,
          'zz1d8cd98f00b204e9800998ecf8427e',
        ),
        isFalse,
      );
    });

    test('calculates md5 and sha256 for a file', () async {
      final dir = await Directory.systemTemp.createTemp('waydir_checksum_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/sample.txt');
      await file.writeAsString('Waydir\n');

      final md5 = await ChecksumService.calculate(
        file.path,
        ChecksumAlgorithm.md5,
      );
      final sha256 = await ChecksumService.calculate(
        file.path,
        ChecksumAlgorithm.sha256,
      );

      expect(md5.digest, 'c559240deb98788f40eb3f18395a8112');
      expect(
        sha256.digest,
        'fee49e636dec6a20f3705578d7b0c19ad7baec1e5ea4f18ce17b30cc8b0a0902',
      );
      expect(md5.bytes, 7);
      expect(sha256.bytes, 7);
    });

    test('compares normalized expected value against actual digest', () {
      expect(
        ChecksumService.matches(
          algorithm: ChecksumAlgorithm.md5,
          expected: 'c5 59 24 0d eb 98 78 8f 40 eb 3f 18 39 5a 81 12',
          actual: 'c559240deb98788f40eb3f18395a8112',
        ),
        isTrue,
      );
    });
  });
}
