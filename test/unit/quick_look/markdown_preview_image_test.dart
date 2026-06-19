import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:waydir/core/models/file_entry.dart';
import 'package:waydir/features/quick_look/markdown_preview.dart';
import 'package:waydir/ui/theme/app_theme.dart';

FileEntry _entry(String path) => FileEntry(
  name: path.split(Platform.pathSeparator).last,
  path: path,
  type: FileItemType.file,
  size: 0,
  modified: DateTime.now(),
);

Future<void> _pumpPreview(WidgetTester tester, String mdPath) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: Scaffold(body: MarkdownPreview(entry: _entry(mdPath))),
      ),
    );
    // probeFile() does real disk I/O; let it complete in the real zone.
    await Future<void>.delayed(const Duration(milliseconds: 300));
  });
  // Flush the setState scheduled when the probe future resolved.
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('renders an image referenced relative to the md file', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('md_preview_test');
    addTearDown(() => dir.deleteSync(recursive: true));

    final imgDir = Directory('${dir.path}/assets')..createSync();
    File('${imgDir.path}/pic.png').writeAsBytesSync(_onePixelPng);
    // Image alone as the very first block: the scrollable `Markdown` widget
    // drops this; `MarkdownBody` (what we use) must render it.
    final md = File('${dir.path}/doc.md')
      ..writeAsStringSync('![alt](assets/pic.png)\n');

    await _pumpPreview(tester, md.path);

    final fileImages = tester
        .widgetList<Image>(find.byType(Image))
        .where((i) => i.image is FileImage)
        .cast<Image>()
        .toList();
    expect(
      fileImages,
      isNotEmpty,
      reason: 'relative image reference should resolve to a FileImage',
    );
    final resolved = (fileImages.first.image as FileImage).file.path;
    expect(resolved, '${imgDir.path}/pic.png');
  });

  testWidgets('renders a local .svg image via SvgPicture', (tester) async {
    final dir = Directory.systemTemp.createTempSync('md_preview_test');
    addTearDown(() => dir.deleteSync(recursive: true));

    File('${dir.path}/icon.svg').writeAsStringSync(
      '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10">'
      '<rect width="10" height="10" fill="red"/></svg>',
    );
    final md = File('${dir.path}/doc.md')
      ..writeAsStringSync('![icon](icon.svg)\n');

    await _pumpPreview(tester, md.path);

    expect(
      find.byType(SvgPicture),
      findsOneWidget,
      reason: '.svg reference should render through flutter_svg',
    );
  });

  testWidgets('sizes SVG images from viewBox when dimensions are percentages', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('md_preview_test');
    addTearDown(() => dir.deleteSync(recursive: true));

    final svg = Uri.dataFromString(
      '<svg xmlns="http://www.w3.org/2000/svg" width="100%" height="100%" '
      'viewBox="0 0 240 60"><rect width="240" height="60"/></svg>',
      mimeType: 'image/svg+xml',
    );
    final md = File('${dir.path}/doc.md')
      ..writeAsStringSync('![badge]($svg)\n');

    await _pumpPreview(tester, md.path);

    final picture = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(picture.width, 240);
    expect(picture.height, 60);
  });

  testWidgets('renders a linked shields-style SVG at intrinsic size', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('md_preview_test');
    addTearDown(() => dir.deleteSync(recursive: true));
    final url = Uri.dataFromString(_shieldsSvg, mimeType: 'image/svg+xml');
    final md = File('${dir.path}/doc.md')
      ..writeAsStringSync('[![Flutter]($url)](https://flutter.dev)\n');

    await _pumpPreview(tester, md.path);

    expect(find.byType(SvgPicture), findsOneWidget);
    final picture = tester.widget<SvgPicture>(find.byType(SvgPicture));
    final loader = picture.bytesLoader as SvgBytesLoader;
    final svg = utf8.decode(loader.bytes);
    expect(tester.getSize(find.byType(SvgPicture)), const Size(107, 20));
    expect(svg, isNot(contains('transform="scale(.1)"')));
    expect(svg, contains('font-size="11"'));
    expect(svg, contains('x="41.5"'));
    expect(svg, contains('y="14"'));
  });

  testWidgets('renders an image embedded as an HTML <img> tag inside a '
      'block (div/p), which the parser would otherwise drop', (tester) async {
    final dir = Directory.systemTemp.createTempSync('md_preview_test');
    addTearDown(() => dir.deleteSync(recursive: true));

    File('${dir.path}/pic.png').writeAsBytesSync(_onePixelPng);
    final md = File('${dir.path}/readme.md')
      ..writeAsStringSync(
        '<div align="center">\n'
        '<p align="center">\n'
        '<img src="pic.png" alt="hero" width="600">\n'
        '</p>\n'
        '</div>\n',
      );

    await _pumpPreview(tester, md.path);

    final fileImages = tester
        .widgetList<Image>(find.byType(Image))
        .where((i) => i.image is FileImage);
    expect(
      fileImages,
      isNotEmpty,
      reason: 'HTML <img> should be converted to a rendered image',
    );
  });

  testWidgets('renders multiline HTML link paragraphs as inline links', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('md_preview_test');
    addTearDown(() => dir.deleteSync(recursive: true));

    final md = File('${dir.path}/readme.md')
      ..writeAsStringSync(
        '<p>\n'
        '  <a href="https://github.com/Waydir/Waydir/releases">'
        '<b>Download</b></a>\n'
        '  -\n'
        '  <a href="#install"><b>Install</b></a>\n'
        '  -\n'
        '  <a href="docs/plugins.md"><b>Plugins</b></a>\n'
        '</p>\n',
      );

    await _pumpPreview(tester, md.path);

    final shown = tester
        .widgetList<SelectableText>(find.byType(SelectableText))
        .map((s) => s.textSpan?.toPlainText() ?? s.data ?? '')
        .join(' ');

    expect(shown, contains('Download - Install - Plugins'));
    expect(shown, isNot(contains('•')));
  });

  testWidgets('strips leaked HTML tags but keeps their text and code spans', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('md_preview_test');
    addTearDown(() => dir.deleteSync(recursive: true));

    final md = File('${dir.path}/doc.md')
      ..writeAsStringSync(
        '<table><tr><td align="center">\n'
        '<b>Dual-pane copy</b><br>\n'
        '</td></tr></table>\n\n'
        'Use the `<td>` element here.\n',
      );

    await _pumpPreview(tester, md.path);

    final shown = tester
        .widgetList<SelectableText>(find.byType(SelectableText))
        .map((s) => s.textSpan?.toPlainText() ?? s.data ?? '')
        .join('\n');

    expect(shown, contains('Dual-pane copy'), reason: 'inner text kept');
    expect(shown, contains('<td>'), reason: 'inline code span preserved');
    expect(
      shown,
      isNot(contains('align=')),
      reason: 'leaked HTML attributes must be stripped',
    );
    expect(
      shown,
      isNot(contains('</td>')),
      reason: 'leaked closing tags must be stripped',
    );
  });
}

final List<int> _onePixelPng = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
];

const _shieldsSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" width="107" height="20" '
    'role="img" aria-label="Flutter: 3.35+"><title>Flutter: 3.35+</title>'
    '<g shape-rendering="crispEdges"><rect width="64" height="20" '
    'fill="#555"/><rect x="64" width="43" height="20" fill="#02569b"/></g>'
    '<g fill="#fff" text-anchor="middle" '
    'font-family="Verdana,Geneva,DejaVu Sans,sans-serif" '
    'text-rendering="geometricPrecision" font-size="110">'
    '<text x="415" y="140" textLength="370" transform="scale(.1)">'
    'Flutter</text><text x="845" y="140" textLength="330" '
    'transform="scale(.1)">3.35+</text></g></svg>';
