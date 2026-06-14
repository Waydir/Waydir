import 'package:flutter/material.dart';

import '../../ui/theme/app_theme.dart';

class CodeLanguage {
  final Set<String> keywords;
  final Set<String> builtins;
  final String? lineComment;
  final String? altLineComment;
  final List<String>? blockComment;
  final String quotes;

  const CodeLanguage({
    this.keywords = const {},
    this.builtins = const {},
    this.lineComment,
    this.altLineComment,
    this.blockComment,
    this.quotes = '"\'',
  });
}

const _cFamilyKw = {
  'if',
  'else',
  'for',
  'while',
  'do',
  'switch',
  'case',
  'default',
  'break',
  'continue',
  'return',
  'goto',
  'struct',
  'enum',
  'union',
  'typedef',
  'sizeof',
  'static',
  'const',
  'volatile',
  'extern',
  'inline',
  'void',
  'int',
  'char',
  'float',
  'double',
  'long',
  'short',
  'unsigned',
  'signed',
  'bool',
  'class',
  'public',
  'private',
  'protected',
  'virtual',
  'override',
  'namespace',
  'template',
  'typename',
  'using',
  'new',
  'delete',
  'this',
  'true',
  'false',
  'nullptr',
  'auto',
  'try',
  'catch',
  'throw',
};

const _dartKw = {
  'abstract',
  'as',
  'assert',
  'async',
  'await',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'covariant',
  'default',
  'deferred',
  'do',
  'dynamic',
  'else',
  'enum',
  'export',
  'extends',
  'extension',
  'external',
  'factory',
  'false',
  'final',
  'finally',
  'for',
  'Function',
  'get',
  'hide',
  'if',
  'implements',
  'import',
  'in',
  'is',
  'late',
  'library',
  'mixin',
  'new',
  'null',
  'on',
  'operator',
  'part',
  'required',
  'rethrow',
  'return',
  'sealed',
  'set',
  'show',
  'static',
  'super',
  'switch',
  'sync',
  'this',
  'throw',
  'true',
  'try',
  'typedef',
  'var',
  'void',
  'while',
  'with',
  'yield',
};
const _dartTypes = {
  'int',
  'double',
  'num',
  'bool',
  'String',
  'List',
  'Map',
  'Set',
  'Future',
  'Stream',
  'Object',
  'Iterable',
  'Widget',
  'BuildContext',
  'override',
};

const _jsKw = {
  'abstract',
  'as',
  'async',
  'await',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'debugger',
  'default',
  'delete',
  'do',
  'else',
  'enum',
  'export',
  'extends',
  'false',
  'finally',
  'for',
  'from',
  'function',
  'get',
  'if',
  'implements',
  'import',
  'in',
  'instanceof',
  'interface',
  'let',
  'new',
  'null',
  'of',
  'package',
  'private',
  'protected',
  'public',
  'return',
  'set',
  'static',
  'super',
  'switch',
  'this',
  'throw',
  'true',
  'try',
  'type',
  'typeof',
  'undefined',
  'var',
  'void',
  'while',
  'yield',
  'readonly',
  'keyof',
  'namespace',
  'declare',
};

const _pyKw = {
  'and',
  'as',
  'assert',
  'async',
  'await',
  'break',
  'class',
  'continue',
  'def',
  'del',
  'elif',
  'else',
  'except',
  'False',
  'finally',
  'for',
  'from',
  'global',
  'if',
  'import',
  'in',
  'is',
  'lambda',
  'None',
  'nonlocal',
  'not',
  'or',
  'pass',
  'raise',
  'return',
  'True',
  'try',
  'while',
  'with',
  'yield',
  'match',
  'case',
  'self',
};

const _rustKw = {
  'as',
  'async',
  'await',
  'break',
  'const',
  'continue',
  'crate',
  'dyn',
  'else',
  'enum',
  'extern',
  'false',
  'fn',
  'for',
  'if',
  'impl',
  'in',
  'let',
  'loop',
  'match',
  'mod',
  'move',
  'mut',
  'pub',
  'ref',
  'return',
  'self',
  'Self',
  'static',
  'struct',
  'super',
  'trait',
  'true',
  'type',
  'unsafe',
  'use',
  'where',
  'while',
};

const _goKw = {
  'break',
  'case',
  'chan',
  'const',
  'continue',
  'default',
  'defer',
  'else',
  'fallthrough',
  'for',
  'func',
  'go',
  'goto',
  'if',
  'import',
  'interface',
  'map',
  'package',
  'range',
  'return',
  'select',
  'struct',
  'switch',
  'type',
  'var',
  'true',
  'false',
  'nil',
  'string',
  'int',
  'bool',
  'error',
};

final Map<String, CodeLanguage> _byExt = {
  'dart': const CodeLanguage(
    keywords: _dartKw,
    builtins: _dartTypes,
    lineComment: '//',
    blockComment: ['/*', '*/'],
  ),
  for (final e in ['js', 'jsx', 'ts', 'tsx', 'mjs', 'cjs'])
    e: const CodeLanguage(
      keywords: _jsKw,
      lineComment: '//',
      blockComment: ['/*', '*/'],
      quotes: '"\'`',
    ),
  for (final e in [
    'c',
    'h',
    'cpp',
    'cc',
    'cxx',
    'hpp',
    'java',
    'kt',
    'cs',
    'go',
    'swift',
    'scala',
  ])
    e: CodeLanguage(
      keywords: e == 'go' ? _goKw : _cFamilyKw,
      lineComment: '//',
      blockComment: const ['/*', '*/'],
    ),
  'rs': const CodeLanguage(
    keywords: _rustKw,
    lineComment: '//',
    blockComment: ['/*', '*/'],
  ),
  for (final e in [
    'py',
    'pyw',
    'rb',
    'sh',
    'bash',
    'zsh',
    'fish',
    'toml',
    'ini',
    'conf',
    'cfg',
  ])
    e: const CodeLanguage(keywords: _pyKw, lineComment: '#'),
  for (final e in ['yaml', 'yml']) e: const CodeLanguage(lineComment: '#'),
  for (final e in ['json', 'jsonc']) e: const CodeLanguage(lineComment: '//'),
  'sql': const CodeLanguage(
    keywords: {
      'select',
      'from',
      'where',
      'insert',
      'into',
      'values',
      'update',
      'set',
      'delete',
      'create',
      'table',
      'alter',
      'drop',
      'join',
      'left',
      'right',
      'inner',
      'outer',
      'on',
      'group',
      'by',
      'order',
      'having',
      'limit',
      'and',
      'or',
      'not',
      'null',
      'as',
      'distinct',
      'union',
      'index',
    },
    lineComment: '--',
    blockComment: ['/*', '*/'],
  ),
  for (final e in ['html', 'htm', 'xml', 'svg'])
    e: const CodeLanguage(blockComment: ['<!--', '-->']),
  for (final e in ['css', 'scss', 'sass', 'less'])
    e: const CodeLanguage(blockComment: ['/*', '*/']),
};

CodeLanguage? languageForExtension(String ext) => _byExt[ext.toLowerCase()];

String _esc(String s) => RegExp.escape(s);

List<TextSpan> highlightCode(String text, CodeLanguage lang, TextStyle base) {
  final commentStyle = base.copyWith(
    color: AppColors.fgMuted,
    fontStyle: FontStyle.italic,
  );
  final stringStyle = base.copyWith(color: AppColors.success);
  final numberStyle = base.copyWith(color: AppColors.warning);
  final keywordStyle = base.copyWith(
    color: AppColors.accent,
    fontWeight: FontWeight.w600,
  );
  final builtinStyle = base.copyWith(color: AppColors.fileCss);

  final parts = <String>[];
  final groups = <String>{};
  if (lang.blockComment != null) {
    parts.add(
      '(?<bc>${_esc(lang.blockComment!.first)}[\\s\\S]*?'
      '${_esc(lang.blockComment![1])})',
    );
    groups.add('bc');
  }
  if (lang.lineComment != null) {
    parts.add('(?<lc>${_esc(lang.lineComment!)}[^\\n]*)');
    groups.add('lc');
  }
  if (lang.altLineComment != null) {
    parts.add('(?<lc2>${_esc(lang.altLineComment!)}[^\\n]*)');
    groups.add('lc2');
  }
  for (var i = 0; i < lang.quotes.length; i++) {
    final q = _esc(lang.quotes[i]);
    parts.add('(?<s$i>$q(?:\\\\.|[^$q\\\\\\n])*$q)');
    groups.add('s$i');
  }
  parts.add(r'(?<num>\b\d[\w.]*\b)');
  groups.add('num');
  parts.add(r'(?<id>[A-Za-z_$][\w$]*)');
  groups.add('id');

  final re = RegExp(parts.join('|'), multiLine: true);
  final spans = <TextSpan>[];
  var last = 0;

  for (final m in re.allMatches(text)) {
    if (m.start > last) {
      spans.add(TextSpan(text: text.substring(last, m.start), style: base));
    }
    final tok = m[0]!;
    bool matched(String group) =>
        groups.contains(group) && m.namedGroup(group) != null;
    TextStyle st;
    if (matched('bc') || matched('lc') || matched('lc2')) {
      st = commentStyle;
    } else if (matched('num')) {
      st = numberStyle;
    } else if (matched('id')) {
      if (lang.keywords.contains(tok)) {
        st = keywordStyle;
      } else if (lang.builtins.contains(tok)) {
        st = builtinStyle;
      } else {
        st = base;
      }
    } else {
      st = stringStyle;
    }
    spans.add(TextSpan(text: tok, style: st));
    last = m.end;
  }
  if (last < text.length) {
    spans.add(TextSpan(text: text.substring(last), style: base));
  }

  return spans;
}
