import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../core/logging/app_logger.dart';
import '../../core/models/file_entry.dart';
import '../../core/platform/platform_paths.dart';
import '../../i18n/strings.g.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import 'quick_look_common.dart';
import 'quick_look_io.dart';

/// Rendered Markdown preview. Read-only; switching to the source editor is
/// handled by the QuickLook header toggle, which routes back to [CodeEditor].
class MarkdownPreview extends StatelessWidget {
  final FileEntry entry;

  const MarkdownPreview({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: AsyncRetain<Probe>(
        cacheKey: entry.realPath,
        loader: () => probeFile(entry),
        loading: const QlCentered.spinner(),
        builder: (res) {
          if (res.kind != QlKind.text) {
            return QlCentered(message: res.note ?? t.quickLook.noPreview);
          }

          return _RenderedMarkdown(
            key: ValueKey(entry.realPath),
            text: res.text,
            basePath: entry.realPath,
          );
        },
      ),
    );
  }
}

final _mdImage = RegExp(r'!\[[^\]]*\]\(\s*(\S+?)\s*(?:"[^"]*")?\)');

/// Markdown image targets that point at the network, normalised the same way
/// the parser will (drop any `#WxH` dimension suffix, round-trip through [Uri])
/// so prefetched bytes are found again by [_MarkdownBody._buildImage].
Set<String> _remoteImageUrls(String md) {
  final urls = <String>{};
  for (final m in _mdImage.allMatches(md)) {
    final raw = m.group(1);
    if (raw == null) continue;
    final path = raw.split('#').first;
    if (!path.startsWith('http://') && !path.startsWith('https://')) continue;
    final uri = Uri.tryParse(path);
    if (uri != null) urls.add(uri.toString());
  }

  return urls;
}

/// Resolves the markdown text and prefetches any remote images before showing
/// anything. Building [MarkdownBody] only once every image's bytes are in hand
/// keeps inline images (rendered as `WidgetSpan`s) from being measured at a
/// stale zero size and then drawn oversized/clipped when they load late.
class _RenderedMarkdown extends StatefulWidget {
  final String text;
  final String basePath;

  const _RenderedMarkdown({
    super.key,
    required this.text,
    required this.basePath,
  });

  @override
  State<_RenderedMarkdown> createState() => _RenderedMarkdownState();
}

class _RenderedMarkdownState extends State<_RenderedMarkdown> {
  late final String _md = _sanitizeHtml(widget.text);
  final Map<String, Uint8List> _remote = {};
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    final urls = _remoteImageUrls(_md);
    if (urls.isEmpty) {
      _ready = true;
    } else {
      _prefetch(urls);
    }
  }

  Future<void> _prefetch(Set<String> urls) async {
    await Future.wait(
      urls.map((url) async {
        try {
          final res = await http
              .get(Uri.parse(url))
              .timeout(const Duration(seconds: 10));
          if (res.statusCode == 200) _remote[url] = res.bodyBytes;
        } catch (e, st) {
          log.warn(
            'quick-look',
            'markdown image fetch failed',
            error: e,
            stack: st,
          );
        }
      }),
    );
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const QlCentered.spinner();

    return _MarkdownBody(md: _md, basePath: widget.basePath, remote: _remote);
  }
}

const _empty = SizedBox.shrink();

final _imgTag = RegExp(r'<img\b[^>]*>', caseSensitive: false);
final _htmlAttr = RegExp(
  '''([\\w:-]+)\\s*=\\s*("([^"]*)"|'([^']*)')''',
  caseSensitive: false,
);
final _pBlock = RegExp(
  r'<p\b[^>]*>(.*?)</p>',
  caseSensitive: false,
  dotAll: true,
);
final _aPair = RegExp(
  r'<a\b([^>]*)>(.*?)</a>',
  caseSensitive: false,
  dotAll: true,
);
final _boldPair = RegExp(
  r'<(b|strong)\b[^>]*>(.*?)</\1>',
  caseSensitive: false,
  dotAll: true,
);
final _emPair = RegExp(
  r'<(i|em)\b[^>]*>(.*?)</\1>',
  caseSensitive: false,
  dotAll: true,
);
final _brTag = RegExp(r'<br\s*/?>', caseSensitive: false);
// Real HTML tags only: a tag name after `<` (or `</`). Leaves CommonMark
// autolinks like `<https://…>` and `<a@b.com>` untouched (no `://`/`@` here).
final _htmlTag = RegExp(r'</?[a-zA-Z][a-zA-Z0-9-]*(?:\s[^<>]*)?/?>');
final _fence = RegExp(r'^\s*(```|~~~)');

/// flutter_markdown_plus renders no HTML. Two things go wrong without help:
///  - images embedded as `<img>` tags (common in READMEs wrapped in
///    `<div>`/`<p>`/`<table>`) are dropped, and
///  - other tags (`<td>`, `<b>`, `</div>`, …) leak into the preview as text.
///
/// Rewrite each `<img>` to a Markdown image on its own line (the blank lines
/// break out of any enclosing HTML block so the parser sees a real image),
/// then strip the remaining tags while keeping their inner text. Fenced code
/// blocks and inline code spans are left untouched.
String _sanitizeHtml(String src) {
  final out = StringBuffer();
  var normal = StringBuffer();
  var inFence = false;

  void flushNormal() {
    final rewritten = _rewriteHtmlLinkParagraphs(normal.toString());
    normal = StringBuffer();
    for (final line in rewritten.split('\n')) {
      final parts = line.split('`');
      final sb = StringBuffer();
      for (var i = 0; i < parts.length; i++) {
        if (i > 0) sb.write('`');
        sb.write(i.isEven ? _stripHtml(parts[i]) : parts[i]);
      }
      out.writeln(sb.toString());
    }
  }

  for (final line in src.split('\n')) {
    if (_fence.hasMatch(line)) {
      flushNormal();
      inFence = !inFence;
      out.writeln(line);
      continue;
    }
    if (inFence) {
      out.writeln(line);
      continue;
    }
    normal.writeln(line);
  }
  flushNormal();

  return out.toString();
}

String _rewriteHtmlLinkParagraphs(String src) {
  return src.replaceAllMapped(_pBlock, (m) {
    final body = m[1]!;
    if (!_aPair.hasMatch(body) || _imgTag.hasMatch(body)) return m[0]!;

    final inline = _htmlInlineToMarkdown(body)
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join(' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (inline.isEmpty) return '';

    return '\n\n$inline\n\n';
  });
}

String _htmlInlineToMarkdown(String src) {
  var out = src.replaceAllMapped(_aPair, (m) {
    final attrs = m[1]!;
    final href = _attrValue(attrs, 'href');
    final text = _htmlInlineToMarkdown(m[2]!).trim();
    if (href == null || href.isEmpty || text.isEmpty) return text;

    return '[$text]($href)';
  });
  out = out.replaceAllMapped(
    _boldPair,
    (m) => '**${_htmlInlineToMarkdown(m[2]!).trim()}**',
  );
  out = out.replaceAllMapped(
    _emPair,
    (m) => '*${_htmlInlineToMarkdown(m[2]!).trim()}*',
  );

  return out.replaceAll(_brTag, '\n').replaceAll(_htmlTag, '');
}

String? _attrValue(String attrs, String name) {
  for (final a in _htmlAttr.allMatches(attrs)) {
    if (a[1]!.toLowerCase() == name) return a[3] ?? a[4] ?? '';
  }

  return null;
}

String _stripHtml(String segment) {
  return segment
      .replaceAllMapped(_imgTag, (m) {
        String? imgSrc;
        String alt = '';
        for (final a in _htmlAttr.allMatches(m[0]!)) {
          final name = a[1]!.toLowerCase();
          final value = a[3] ?? a[4] ?? '';
          if (name == 'src') {
            imgSrc = value;
          } else if (name == 'alt') {
            alt = value;
          }
        }
        if (imgSrc == null || imgSrc.isEmpty) return '';

        return '\n\n![$alt]($imgSrc)\n\n';
      })
      .replaceAll(_brTag, '\n')
      .replaceAll(_htmlTag, '');
}

class _MarkdownBody extends StatelessWidget {
  final String md;
  final String basePath;
  final Map<String, Uint8List> remote;

  const _MarkdownBody({
    required this.md,
    required this.basePath,
    required this.remote,
  });

  void _openLink(String? href) {
    if (href == null || href.isEmpty) return;
    final uri = Uri.tryParse(href);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return;
    }
    final cmd = Platform.isWindows
        ? 'explorer'
        : Platform.isMacOS
        ? 'open'
        : 'xdg-open';
    Process.start(cmd, [uri.toString()], mode: ProcessStartMode.detached);
  }

  /// Resolves image sources against the markdown file's own directory and
  /// renders SVG (e.g. shields.io badges) as well as raster images, whether
  /// remote, embedded as data URIs, or on disk. [Uri.resolveUri] handles
  /// `.`/`..`/absolute paths, unlike the package's default builder.
  Widget _buildImage(Uri uri, String? title, String? alt) {
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      final bytes = remote[uri.toString()];
      if (bytes == null) return _empty;

      return _bytesImage(bytes, isSvg: _looksLikeSvg(bytes));
    }
    if (uri.scheme == 'data') {
      final data = uri.data;
      if (data == null || !data.mimeType.startsWith('image/')) return _empty;

      return _bytesImage(
        data.contentAsBytes(),
        isSvg: data.mimeType.contains('svg'),
      );
    }
    if (PlatformPaths.isSftpUri(basePath)) return _empty;
    final baseDir = Uri.directory(p.dirname(basePath));
    final resolved = uri.hasScheme ? uri : baseDir.resolveUri(uri);
    if (resolved.scheme != 'file') return _empty;
    final file = File.fromUri(resolved);
    if (p.extension(file.path).toLowerCase() == '.svg') {
      Uint8List bytes;
      try {
        bytes = file.readAsBytesSync();
      } catch (_) {
        return _empty;
      }

      return _bytesImage(bytes, isSvg: true);
    }

    return _fit(
      Image.file(
        file,
        fit: BoxFit.scaleDown,
        errorBuilder: (_, _, _) => _empty,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseFont = context.txt.row.copyWith(height: 1.5, color: AppColors.fg);
    final mutedFont = baseFont.copyWith(color: AppColors.fgMuted);
    final monoFont = context.txt.code.copyWith(color: AppColors.fg);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      child: MarkdownBody(
        data: md,
        selectable: true,
        onTapLink: (_, href, _) => _openLink(href),
        imageBuilder: _buildImage,
        styleSheet: MarkdownStyleSheet(
          p: baseFont,
          h1: context.txt.heading.copyWith(height: 1.3),
          h2: context.txt.dialogTitle.copyWith(height: 1.3),
          h3: context.txt.bodyEmphasis.copyWith(color: AppColors.fgMuted),
          listBullet: baseFont,
          em: baseFont.copyWith(fontStyle: FontStyle.italic),
          strong: baseFont.copyWith(fontWeight: FontWeight.w600),
          code: monoFont.copyWith(backgroundColor: AppColors.bgInput),
          codeblockDecoration: BoxDecoration(color: AppColors.bgInput),
          codeblockPadding: const EdgeInsets.all(10),
          blockSpacing: 10,
          blockquote: mutedFont,
          blockquoteDecoration: BoxDecoration(
            color: AppColors.bgInput,
            border: Border(
              left: BorderSide(color: AppColors.borderColor, width: 3),
            ),
          ),
          blockquotePadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          a: baseFont.copyWith(
            color: AppColors.accent,
            decoration: TextDecoration.underline,
          ),
          horizontalRuleDecoration: BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.bgDivider)),
          ),
        ),
      ),
    );
  }
}

/// Keeps an image within the available width while preserving aspect ratio.
Widget _fit(Widget child) {
  return LayoutBuilder(
    builder: (context, c) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: c.maxWidth.isFinite ? c.maxWidth : double.infinity,
        ),
        child: child,
      );
    },
  );
}

Widget _bytesImage(Uint8List bytes, {required bool isSvg}) {
  if (isSvg) {
    final size = _svgIntrinsicSize(bytes);
    final svgBytes = _normalizeSvgForFlutter(bytes);

    return LayoutBuilder(
      builder: (context, c) {
        final maxW = c.maxWidth.isFinite ? c.maxWidth : double.infinity;
        var w = size?.width ?? 240;
        var h = size?.height ?? 160;
        if (w <= 0 || h <= 0) {
          w = 240;
          h = 160;
        }
        if (w > maxW) {
          h = h * (maxW / w);
          w = maxW;
        }
        if (!w.isFinite || !h.isFinite) {
          w = 240;
          h = 160;
        }

        return SizedBox(
          width: w,
          height: h,
          child: ClipRect(
            child: SvgPicture.memory(
              svgBytes,
              width: w,
              height: h,
              fit: BoxFit.contain,
              alignment: Alignment.centerLeft,
              placeholderBuilder: (_) => _empty,
            ),
          ),
        );
      },
    );
  }

  return _fit(
    Image.memory(
      bytes,
      fit: BoxFit.scaleDown,
      errorBuilder: (_, _, _) => _empty,
    ),
  );
}

bool _looksLikeSvg(Uint8List bytes) {
  final head = String.fromCharCodes(bytes.take(256)).trimLeft().toLowerCase();

  return head.startsWith('<?xml') || head.contains('<svg');
}

Uint8List _normalizeSvgForFlutter(Uint8List bytes) {
  final svg = utf8.decode(bytes, allowMalformed: true);
  final normalized = svg.replaceAllMapped(_textTag, (m) {
    final tag = m[0]!;
    final scale = _scaleTransform.firstMatch(tag);
    if (scale == null) return tag;

    final factor = double.tryParse(scale[2]!);
    if (factor == null || factor <= 0) return tag;

    final fontSize =
        _attrNumber(tag, 'font-size') ?? _inheritedFontSize(svg, m.start);
    var out = tag.replaceFirst(scale[0]!, '');
    out = _scaleAttr(out, 'x', factor);
    out = _scaleAttr(out, 'y', factor);
    out = _scaleAttr(out, 'dx', factor);
    out = _scaleAttr(out, 'dy', factor);
    out = _scaleAttr(out, 'textLength', factor);
    if (fontSize != null) {
      out = _setAttr(out, 'font-size', _formatSvgNumber(fontSize * factor));
    }

    return out;
  });

  return Uint8List.fromList(utf8.encode(normalized));
}

final _svgTag = RegExp(r'<svg[^>]*>', caseSensitive: false);
final _viewBox = RegExp(
  '''viewbox\\s*=\\s*["']([0-9.eE+\\s,-]+)''',
  caseSensitive: false,
);
final _textTag = RegExp(r'<text\b[^>]*>', caseSensitive: false);
final _scaleTransform = RegExp(
  r'''\s*transform\s*=\s*(["'])\s*scale\(\s*([0-9]*\.?[0-9]+)\s*\)\s*\1''',
  caseSensitive: false,
);

double? _attrNumber(String tag, String name) {
  final m = RegExp(
    '$name\\s*=\\s*["\']\\s*([0-9.]+)',
    caseSensitive: false,
  ).firstMatch(tag);

  return m == null ? null : double.tryParse(m[1]!);
}

double? _inheritedFontSize(String svg, int offset) {
  final before = svg.substring(0, offset);
  final matches = RegExp(
    'font-size\\s*=\\s*["\']\\s*([0-9.]+)',
    caseSensitive: false,
  ).allMatches(before);
  if (matches.isEmpty) return null;

  return double.tryParse(matches.last[1]!);
}

String _scaleAttr(String tag, String name, double factor) {
  return tag.replaceAllMapped(
    RegExp('$name\\s*=\\s*(["\'])\\s*([0-9.]+)\\s*\\1', caseSensitive: false),
    (m) =>
        '$name=${m[1]}${_formatSvgNumber(double.parse(m[2]!) * factor)}${m[1]}',
  );
}

String _setAttr(String tag, String name, String value) {
  final attr = RegExp('$name\\s*=\\s*(["\']).*?\\1', caseSensitive: false);
  if (attr.hasMatch(tag)) {
    return tag.replaceFirstMapped(attr, (m) => '$name=${m[1]}$value${m[1]}');
  }

  return tag.replaceFirst('>', ' $name="$value">');
}

String _formatSvgNumber(double value) {
  final fixed = value.toStringAsFixed(6);

  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}

/// Reads an SVG's intrinsic size from the root `<svg>` tag: explicit
/// width/height (units stripped) when present, otherwise the viewBox extent.
Size? _svgIntrinsicSize(Uint8List bytes) {
  final head = String.fromCharCodes(bytes.take(1024));
  final tag = _svgTag.firstMatch(head)?.group(0);
  if (tag == null) return null;

  double? dim(String name) {
    final m = RegExp(
      '$name\\s*=\\s*["\']\\s*([0-9.]+)\\s*([a-z%]*)',
      caseSensitive: false,
    ).firstMatch(tag);
    if (m == null) return null;
    final unit = m.group(2)?.toLowerCase() ?? '';
    if (unit.isNotEmpty && unit != 'px') return null;

    return double.tryParse(m.group(1)!);
  }

  final w = dim('width');
  final h = dim('height');
  if (w != null && h != null) return Size(w, h);

  final vb = _viewBox.firstMatch(tag)?.group(1);
  if (vb != null) {
    final parts = vb
        .trim()
        .split(RegExp(r'[\s,]+'))
        .map(double.tryParse)
        .toList();
    if (parts.length == 4 && parts[2] != null && parts[3] != null) {
      return Size(parts[2]!, parts[3]!);
    }
  }

  return null;
}
