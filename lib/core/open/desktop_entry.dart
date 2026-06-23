/// Minimal freedesktop.org Desktop Entry parser, kept pure so it can be unit
/// tested without a real filesystem.
class DesktopEntry {
  final String name;
  final String exec;
  final String? icon;
  final List<String> mimeTypes;
  final bool noDisplay;
  final bool hidden;
  final bool isApplication;
  final bool terminal;

  const DesktopEntry({
    required this.name,
    required this.exec,
    required this.icon,
    required this.mimeTypes,
    required this.noDisplay,
    required this.hidden,
    required this.isApplication,
    required this.terminal,
  });

  /// True when the entry should be offered to the user as an opener.
  bool get isLaunchable => isApplication && !hidden && exec.isNotEmpty;

  /// Parses the `[Desktop Entry]` group only. Returns null when the content
  /// has no such group.
  static DesktopEntry? parse(String content) {
    final lines = content.split('\n');
    var inGroup = false;
    final fields = <String, String>{};
    for (var raw in lines) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      if (line.startsWith('[') && line.endsWith(']')) {
        inGroup = line == '[Desktop Entry]';
        continue;
      }
      if (!inGroup) continue;
      final eq = line.indexOf('=');
      if (eq <= 0) continue;
      final key = line.substring(0, eq).trim();
      if (key.contains('[')) continue;
      if (fields.containsKey(key)) continue;
      fields[key] = line.substring(eq + 1).trim();
    }
    if (fields.isEmpty) return null;
    final mimes = (fields['MimeType'] ?? '')
        .split(';')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return DesktopEntry(
      name: fields['Name'] ?? '',
      exec: fields['Exec'] ?? '',
      icon: fields['Icon'],
      mimeTypes: mimes,
      noDisplay: fields['NoDisplay']?.toLowerCase() == 'true',
      hidden: fields['Hidden']?.toLowerCase() == 'true',
      isApplication: (fields['Type'] ?? 'Application') == 'Application',
      terminal: fields['Terminal']?.toLowerCase() == 'true',
    );
  }

  /// Expands the `Exec` field codes per the Desktop Entry spec, substituting
  /// the given file [paths]. Unsupported codes are dropped; `%%` becomes `%`.
  static List<String> expandExec(String exec, List<String> paths) {
    final tokens = _tokenize(exec);
    final result = <String>[];
    for (final tok in tokens) {
      switch (tok) {
        case '%f':
        case '%u':
          if (paths.isNotEmpty) result.add(paths.first);
        case '%F':
        case '%U':
          result.addAll(paths);
        case '%i':
        case '%c':
        case '%k':
        case '%d':
        case '%D':
        case '%n':
        case '%N':
        case '%v':
        case '%m':
          break; // deprecated / not meaningful here
        default:
          result.add(tok.replaceAll('%%', '%'));
      }
    }

    return result;
  }

  /// Splits a command line honouring double quotes (Desktop Entry quoting).
  static List<String> _tokenize(String s) {
    final tokens = <String>[];
    final buf = StringBuffer();
    var inQuotes = false;
    var hasContent = false;
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (c == '"') {
        inQuotes = !inQuotes;
        hasContent = true;
        continue;
      }
      if (c == '\\' && inQuotes && i + 1 < s.length) {
        buf.write(s[++i]);
        hasContent = true;
        continue;
      }
      if (c == ' ' && !inQuotes) {
        if (hasContent) {
          tokens.add(buf.toString());
          buf.clear();
          hasContent = false;
        }
        continue;
      }
      buf.write(c);
      hasContent = true;
    }
    if (hasContent) tokens.add(buf.toString());

    return tokens;
  }
}
