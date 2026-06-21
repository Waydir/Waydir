import '../../core/models/file_entry.dart';
import '../../i18n/strings.g.dart';

const filterSearchMode = 'filter';

const filterQueryKeys = [
  'name',
  'kind',
  'ext',
  'type',
  'size',
  'modified',
  'created',
  'hidden',
  'tag',
];

const filterKindValues = [
  'image',
  'document',
  'archive',
  'code',
  'audio',
  'video',
  'folder',
  'app',
  'package',
  'database',
  'font',
  'config',
];

const filterTypeValues = ['file', 'folder'];
const filterBooleanValues = ['true', 'false'];
const filterDateValues = ['today', 'yesterday', 'week', 'month', 'year'];
const filterSizeValues = ['>1mb', '>10mb', '>100mb', '<1mb', '<10mb', '<100mb'];

const _imageExtensions = {
  'png',
  'jpg',
  'jpeg',
  'gif',
  'bmp',
  'tif',
  'tiff',
  'webp',
  'heic',
  'heif',
  'svg',
  'ico',
  'avif',
  'raw',
  'cr2',
  'nef',
  'arw',
  'dng',
  'psd',
  'ai',
  'xcf',
};

const _documentExtensions = {
  'txt',
  'text',
  'log',
  'md',
  'markdown',
  'rst',
  'rtf',
  'pdf',
  'doc',
  'docx',
  'odt',
  'pages',
  'tex',
  'epub',
  'mobi',
  'xls',
  'xlsx',
  'ods',
  'numbers',
  'csv',
  'tsv',
  'ppt',
  'pptx',
  'odp',
  'key',
};

const _archiveExtensions = {
  'zip',
  'tar',
  'gz',
  'tgz',
  'bz2',
  'xz',
  'zst',
  '7z',
  'rar',
  'lz',
  'lzma',
  'cab',
  'iso',
  'dmg',
  'jar',
};

const _codeExtensions = {
  'dart',
  'c',
  'h',
  'cpp',
  'cc',
  'cxx',
  'hpp',
  'cs',
  'java',
  'kt',
  'kts',
  'swift',
  'go',
  'rs',
  'py',
  'rb',
  'php',
  'pl',
  'lua',
  'r',
  'js',
  'mjs',
  'cjs',
  'ts',
  'tsx',
  'jsx',
  'vue',
  'svelte',
  'sh',
  'bash',
  'zsh',
  'fish',
  'ps1',
  'bat',
  'cmd',
  'sql',
  'asm',
  's',
  'scala',
  'clj',
  'ex',
  'exs',
  'erl',
  'hs',
  'ml',
  'jl',
  'zig',
  'nim',
  'html',
  'htm',
  'css',
  'scss',
  'sass',
  'less',
};

const _audioExtensions = {
  'mp3',
  'wav',
  'flac',
  'aac',
  'ogg',
  'opus',
  'm4a',
  'wma',
  'aiff',
  'mid',
  'midi',
};

const _videoExtensions = {
  'mp4',
  'm4v',
  'mov',
  'avi',
  'mkv',
  'webm',
  'flv',
  'wmv',
  'mpg',
  'mpeg',
  '3gp',
};

const _appExtensions = {'exe', 'app', 'appimage', 'msi'};
const _packageExtensions = {'deb', 'rpm', 'apk', 'msi'};
const _databaseExtensions = {'db', 'sqlite', 'sqlite3'};
const _fontExtensions = {'ttf', 'otf', 'woff', 'woff2', 'eot'};
const _configExtensions = {
  'json',
  'jsonc',
  'json5',
  'yaml',
  'yml',
  'toml',
  'ini',
  'cfg',
  'conf',
  'env',
  'xml',
  'plist',
  'properties',
  'gitignore',
  'gitattributes',
};

class FilterQueryParseResult {
  final FilterQuery? query;
  final String? error;

  const FilterQueryParseResult({this.query, this.error});
}

class FilterQuery {
  final List<String> nameTerms;
  final Set<String> extensions;
  final Set<String> kinds;
  final FileItemType? type;
  final SizeFilter? size;
  final DateFilter? modified;
  final DateFilter? created;
  final bool? hidden;
  final Set<String> tagNames;

  const FilterQuery({
    this.nameTerms = const [],
    this.extensions = const {},
    this.kinds = const {},
    this.type,
    this.size,
    this.modified,
    this.created,
    this.hidden,
    this.tagNames = const {},
  });

  String get recursiveNameQuery => nameTerms.join(' ').trim();

  bool matches(FileEntry entry, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final lowerName = entry.name.toLowerCase();
    for (final term in nameTerms) {
      if (!lowerName.contains(term)) return false;
    }
    if (extensions.isNotEmpty && !extensions.contains(entry.extension)) {
      return false;
    }
    if (kinds.isNotEmpty && !kinds.any((kind) => _matchesKind(entry, kind))) {
      return false;
    }
    if (type != null && entry.type != type) return false;
    if (size != null && !size!.matches(entry.size)) return false;
    if (modified != null && !modified!.matches(entry.modified, n)) return false;
    if (created != null && !created!.matches(entry.created, n)) return false;
    if (hidden != null && entry.isHidden != hidden) return false;

    return true;
  }
}

class SizeFilter {
  final String operator;
  final int bytes;

  const SizeFilter(this.operator, this.bytes);

  bool matches(int size) {
    switch (operator) {
      case '>':
        return size > bytes;
      case '>=':
        return size >= bytes;
      case '<':
        return size < bytes;
      case '<=':
        return size <= bytes;
      default:
        return size == bytes;
    }
  }
}

class DateFilter {
  final String value;

  const DateFilter(this.value);

  bool matches(DateTime date, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    switch (value) {
      case 'today':
        return !date.isBefore(today);
      case 'yesterday':
        final start = today.subtract(const Duration(days: 1));

        return !date.isBefore(start) && date.isBefore(today);
      case 'week':
        return !date.isBefore(now.subtract(const Duration(days: 7)));
      case 'month':
        return !date.isBefore(now.subtract(const Duration(days: 30)));
      case 'year':
        return !date.isBefore(now.subtract(const Duration(days: 365)));
      default:
        return true;
    }
  }
}

class FilterSuggestion {
  final String label;
  final String replacement;
  final String detail;
  final bool trailingSpace;

  const FilterSuggestion(
    this.label,
    this.replacement,
    this.detail, {
    this.trailingSpace = true,
  });
}

FilterQueryParseResult parseFilterQuery(String input) {
  final nameTerms = <String>[];
  final extensions = <String>{};
  final kinds = <String>{};
  FileItemType? type;
  SizeFilter? size;
  DateFilter? modified;
  DateFilter? created;
  bool? hidden;
  final tagNames = <String>{};

  for (final raw in input.trim().split(RegExp(r'\s+'))) {
    if (raw.isEmpty) continue;
    final colon = raw.indexOf(':');
    if (colon <= 0) {
      nameTerms.add(raw.toLowerCase());
      continue;
    }
    final key = raw.substring(0, colon).toLowerCase();
    final value = raw.substring(colon + 1).toLowerCase();
    if (!filterQueryKeys.contains(key)) {
      return FilterQueryParseResult(
        error: t.search.filterErrors.unknownFilter(key: key),
      );
    }
    if (value.isEmpty) {
      return FilterQueryParseResult(
        error: t.search.filterErrors.missingValue(key: key),
      );
    }
    switch (key) {
      case 'name':
        nameTerms.add(value);
      case 'ext':
        extensions.addAll(
          value
              .split(',')
              .map((v) => v.trim().replaceFirst(RegExp(r'^\.'), ''))
              .where((v) => v.isNotEmpty),
        );
      case 'kind':
        final values = value.split(',').map((v) => v.trim());
        for (final kind in values) {
          if (!filterKindValues.contains(kind)) {
            return FilterQueryParseResult(
              error: t.search.filterErrors.unknownKind(kind: kind),
            );
          }
          kinds.add(kind);
        }
      case 'type':
        if (!filterTypeValues.contains(value)) {
          return FilterQueryParseResult(
            error: t.search.filterErrors.unknownType(type: value),
          );
        }
        type = value == 'folder' ? FileItemType.folder : FileItemType.file;
      case 'size':
        final parsed = _parseSize(value);
        if (parsed == null) {
          return FilterQueryParseResult(
            error: t.search.filterErrors.invalidSize,
          );
        }
        size = parsed;
      case 'modified':
        if (!filterDateValues.contains(value)) {
          return FilterQueryParseResult(
            error: t.search.filterErrors.unknownModified(value: value),
          );
        }
        modified = DateFilter(value);
      case 'created':
        if (!filterDateValues.contains(value)) {
          return FilterQueryParseResult(
            error: t.search.filterErrors.unknownCreated(value: value),
          );
        }
        created = DateFilter(value);
      case 'hidden':
        if (!filterBooleanValues.contains(value)) {
          return FilterQueryParseResult(
            error: t.search.filterErrors.hiddenBoolean,
          );
        }
        hidden = value == 'true';
      case 'tag':
        tagNames.addAll(
          value.split(',').map((v) => v.trim()).where((v) => v.isNotEmpty),
        );
    }
  }

  return FilterQueryParseResult(
    query: FilterQuery(
      nameTerms: nameTerms,
      extensions: extensions,
      kinds: kinds,
      type: type,
      size: size,
      modified: modified,
      created: created,
      hidden: hidden,
      tagNames: tagNames,
    ),
  );
}

List<FilterSuggestion> filterSuggestions(String input, int cursorOffset) {
  final offset = cursorOffset < 0 ? input.length : cursorOffset;
  final clamped = offset > input.length ? input.length : offset;
  final range = _activeTokenRange(input, clamped);
  final start = range.$1;
  final end = range.$2;
  final token = input.substring(start, end).toLowerCase();
  final colon = token.indexOf(':');
  if (colon < 0) {
    final matches = filterQueryKeys
        .where((key) => key.startsWith(token))
        .map(
          (key) => FilterSuggestion(
            '$key:',
            '$key:',
            _detailForKey(key),
            trailingSpace: false,
          ),
        )
        .toList();

    return matches.take(8).toList();
  }
  final key = token.substring(0, colon);
  final value = token.substring(colon + 1);
  final values = _valuesForKey(key);
  if (values.isEmpty) return const [];

  return values
      .where((v) => v.startsWith(value))
      .map((v) => FilterSuggestion('$key:$v', '$key:$v', _detailForKey(key)))
      .take(8)
      .toList();
}

String applyFilterSuggestion(
  String input,
  int cursorOffset,
  FilterSuggestion suggestion,
) {
  final offset = cursorOffset < 0 ? input.length : cursorOffset;
  final clamped = offset > input.length ? input.length : offset;
  final range = _activeTokenRange(input, clamped);
  final start = range.$1;
  final end = range.$2;
  final before = input.substring(0, start);
  final after = input.substring(end).trimLeft();
  final replacement = suggestion.trailingSpace
      ? '${suggestion.replacement} '
      : suggestion.replacement;

  return after.isEmpty ? '$before$replacement' : '$before$replacement$after';
}

(int, int) _activeTokenRange(String input, int offset) {
  var start = offset;
  while (start > 0 && !input.codeUnitAt(start - 1)._isWhitespace) {
    start--;
  }
  var end = offset;
  while (end < input.length && !input.codeUnitAt(end)._isWhitespace) {
    end++;
  }

  return (start, end);
}

extension on int {
  bool get _isWhitespace => this == 0x20 || this == 0x09 || this == 0x0a;
}

SizeFilter? _parseSize(String value) {
  final match = RegExp(
    r'^(>=|<=|>|<|=)?([0-9]+(?:\.[0-9]+)?)(b|kb|mb|gb|tb)?$',
  ).firstMatch(value);
  if (match == null) return null;
  final op = match.group(1) ?? '=';
  final amount = double.tryParse(match.group(2)!);
  if (amount == null) return null;
  final unit = match.group(3) ?? 'b';
  final multiplier = switch (unit) {
    'kb' => 1024,
    'mb' => 1024 * 1024,
    'gb' => 1024 * 1024 * 1024,
    'tb' => 1024 * 1024 * 1024 * 1024,
    _ => 1,
  };

  return SizeFilter(op, (amount * multiplier).round());
}

bool _matchesKind(FileEntry entry, String kind) {
  if (kind == 'folder') return entry.type == FileItemType.folder;
  if (entry.type == FileItemType.folder) return false;
  final ext = entry.extension;

  return switch (kind) {
    'image' => _imageExtensions.contains(ext),
    'document' => _documentExtensions.contains(ext),
    'archive' => _archiveExtensions.contains(ext),
    'code' => _codeExtensions.contains(ext) || _isCodeFileName(entry.name),
    'audio' => _audioExtensions.contains(ext),
    'video' => _videoExtensions.contains(ext),
    'app' => _appExtensions.contains(ext),
    'package' => _packageExtensions.contains(ext),
    'database' => _databaseExtensions.contains(ext),
    'font' => _fontExtensions.contains(ext),
    'config' => _configExtensions.contains(ext),
    _ => false,
  };
}

bool _isCodeFileName(String name) {
  final lower = name.toLowerCase();

  return lower == 'dockerfile' ||
      lower == 'containerfile' ||
      lower == 'makefile' ||
      lower == 'rakefile' ||
      lower == 'gemfile' ||
      lower == 'podfile';
}

List<String> _valuesForKey(String key) {
  return switch (key) {
    'kind' => filterKindValues,
    'type' => filterTypeValues,
    'hidden' => filterBooleanValues,
    'modified' || 'created' => filterDateValues,
    'size' => filterSizeValues,
    _ => const [],
  };
}

String _detailForKey(String key) {
  return switch (key) {
    'name' => t.search.filterDetails.name,
    'kind' => t.search.filterDetails.kind,
    'ext' => t.search.filterDetails.ext,
    'type' => t.search.filterDetails.type,
    'size' => t.search.filterDetails.size,
    'modified' => t.search.filterDetails.modified,
    'created' => t.search.filterDetails.created,
    'hidden' => t.search.filterDetails.hidden,
    _ => '',
  };
}
