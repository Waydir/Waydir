import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/features/quick_look/quick_look_common.dart';

void main() {
  group('Quick Look extension sets do not overlap', () {
    test('pdf and binary sets are disjoint', () {
      expect(pdfExts.intersection(binaryExts), isEmpty);
    });

    test('pdf and image sets are disjoint', () {
      expect(pdfExts.intersection(imageExts), isEmpty);
    });

    test('image and binary sets are disjoint', () {
      expect(imageExts.intersection(binaryExts), isEmpty);
    });
  });

  group('PDF routing', () {
    test('pdf routes to PDF preview', () {
      expect(pdfExts.contains('pdf'), isTrue);
    });

    test('pdf is not in binary fallback', () {
      expect(binaryExts.contains('pdf'), isFalse);
    });
  });

  group('Image routing', () {
    final imageTypes = ['png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp'];

    for (final ext in imageTypes) {
      test('.$ext routes to image preview', () {
        expect(imageExts.contains(ext), isTrue);
        expect(binaryExts.contains(ext), isFalse);
      });
    }
  });

  group('Markdown routing', () {
    test('markdown and binary sets are disjoint', () {
      expect(markdownExts.intersection(binaryExts), isEmpty);
    });

    test('.md and .markdown route to markdown preview', () {
      expect(markdownExts.contains('md'), isTrue);
      expect(markdownExts.contains('markdown'), isTrue);
      expect(binaryExts.contains('md'), isFalse);
      expect(imageExts.contains('md'), isFalse);
      expect(pdfExts.contains('md'), isFalse);
    });
  });

  group('Binary fallback routing', () {
    final archiveTypes = ['zip', 'tar', '7z', 'gz', 'bz2', 'rar', 'xz'];
    final mediaTypes = ['mp3', 'mp4', 'mkv', 'wav', 'flac', 'ogg', 'aac'];
    final officeTypes = ['doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'];
    final execTypes = ['exe', 'dll', 'so', 'dylib'];

    for (final ext in [
      ...archiveTypes,
      ...mediaTypes,
      ...officeTypes,
      ...execTypes,
    ]) {
      test('.$ext routes to binary fallback', () {
        expect(binaryExts.contains(ext), isTrue);
      });
    }
  });
}
