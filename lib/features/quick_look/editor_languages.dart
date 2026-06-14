import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/bash.dart';
import 'package:re_highlight/languages/c.dart';
import 'package:re_highlight/languages/cpp.dart';
import 'package:re_highlight/languages/csharp.dart';
import 'package:re_highlight/languages/css.dart';
import 'package:re_highlight/languages/dart.dart';
import 'package:re_highlight/languages/diff.dart';
import 'package:re_highlight/languages/dockerfile.dart';
import 'package:re_highlight/languages/go.dart';
import 'package:re_highlight/languages/ini.dart';
import 'package:re_highlight/languages/java.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/languages/kotlin.dart';
import 'package:re_highlight/languages/less.dart';
import 'package:re_highlight/languages/lua.dart';
import 'package:re_highlight/languages/makefile.dart';
import 'package:re_highlight/languages/markdown.dart';
import 'package:re_highlight/languages/objectivec.dart';
import 'package:re_highlight/languages/php.dart';
import 'package:re_highlight/languages/powershell.dart';
import 'package:re_highlight/languages/python.dart';
import 'package:re_highlight/languages/ruby.dart';
import 'package:re_highlight/languages/rust.dart';
import 'package:re_highlight/languages/scss.dart';
import 'package:re_highlight/languages/sql.dart';
import 'package:re_highlight/languages/swift.dart';
import 'package:re_highlight/languages/typescript.dart';
import 'package:re_highlight/languages/xml.dart';
import 'package:re_highlight/languages/yaml.dart';

/// Maps a file extension to a re_highlight language id and mode for the editor's
/// syntax highlighting. Returns null when no highlighting applies.
({String id, CodeHighlightThemeMode mode})? editorLanguageForExtension(
  String extension,
) {
  final entry = _byExtension[extension.toLowerCase()];
  if (entry == null) return null;

  return (id: entry.$1, mode: CodeHighlightThemeMode(mode: entry.$2));
}

final _byExtension = <String, (String, dynamic)>{
  'dart': ('dart', langDart),
  'json': ('json', langJson),
  'jsonc': ('json', langJson),
  'yaml': ('yaml', langYaml),
  'yml': ('yaml', langYaml),
  'xml': ('xml', langXml),
  'svg': ('xml', langXml),
  'html': ('xml', langXml),
  'htm': ('xml', langXml),
  'xaml': ('xml', langXml),
  'md': ('markdown', langMarkdown),
  'markdown': ('markdown', langMarkdown),
  'js': ('javascript', langJavascript),
  'mjs': ('javascript', langJavascript),
  'cjs': ('javascript', langJavascript),
  'jsx': ('javascript', langJavascript),
  'ts': ('typescript', langTypescript),
  'tsx': ('typescript', langTypescript),
  'py': ('python', langPython),
  'java': ('java', langJava),
  'kt': ('kotlin', langKotlin),
  'kts': ('kotlin', langKotlin),
  'c': ('c', langC),
  'h': ('c', langC),
  'cpp': ('cpp', langCpp),
  'cc': ('cpp', langCpp),
  'cxx': ('cpp', langCpp),
  'hpp': ('cpp', langCpp),
  'hh': ('cpp', langCpp),
  'cs': ('csharp', langCsharp),
  'go': ('go', langGo),
  'rs': ('rust', langRust),
  'rb': ('ruby', langRuby),
  'php': ('php', langPhp),
  'sh': ('bash', langBash),
  'bash': ('bash', langBash),
  'zsh': ('bash', langBash),
  'sql': ('sql', langSql),
  'css': ('css', langCss),
  'scss': ('scss', langScss),
  'less': ('less', langLess),
  'swift': ('swift', langSwift),
  'toml': ('ini', langIni),
  'ini': ('ini', langIni),
  'cfg': ('ini', langIni),
  'conf': ('ini', langIni),
  'properties': ('ini', langIni),
  'lua': ('lua', langLua),
  'mk': ('makefile', langMakefile),
  'makefile': ('makefile', langMakefile),
  'dockerfile': ('dockerfile', langDockerfile),
  'ps1': ('powershell', langPowershell),
  'm': ('objectivec', langObjectivec),
  'mm': ('objectivec', langObjectivec),
  'diff': ('diff', langDiff),
  'patch': ('diff', langDiff),
};
