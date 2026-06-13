import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signals/signals_flutter.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';

import '../../core/fs/sftp_fs.dart';
import '../../core/platform/platform_paths.dart';
import '../../core/settings/settings_store.dart';
import '../../i18n/strings.g.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import 'code_highlighter.dart';
import 'quick_look_common.dart';

class HighlightController extends TextEditingController {
  final CodeLanguage? language;
  final bool highlight;

  String? _cachedText;
  TextStyle? _cachedStyle;
  TextSpan? _cachedSpan;

  HighlightController({required this.language, required this.highlight});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final base = style ?? const TextStyle();
    if (!highlight || language == null) {
      return TextSpan(text: text, style: base);
    }
    if (text == _cachedText && base == _cachedStyle && _cachedSpan != null) {
      return _cachedSpan!;
    }
    final span = TextSpan(
      style: base,
      children: highlightCode(text, language!, base),
    );
    _cachedText = text;
    _cachedStyle = base;
    _cachedSpan = span;
    return span;
  }
}

enum _VimMode { normal, insert, visual }

class CodeEditor extends StatefulWidget {
  final String path;
  final String extension;
  final String initial;
  final ValueNotifier<bool> editorActive;

  const CodeEditor({
    super.key,
    required this.path,
    required this.extension,
    required this.initial,
    required this.editorActive,
  });

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  late final HighlightController _ctrl;
  final _focus = FocusNode();
  final _vScroll = ScrollController();
  final _hScroll = ScrollController();
  late String _savedText;
  bool _dirty = false;
  bool _saving = false;
  String? _saveError;
  int _caretLine = 0;
  int _lines = 1;

  late _VimMode _vim;
  String? _pending;
  String? _vimRegister;
  bool _vimRegisterLinewise = false;
  List<double> _lineHeightSnapshot = const [];
  double _editorViewportHeight = 0;
  double _editorTextWidth = 0;
  double _editorLeftPad = 16;
  bool _wrapLinesSnapshot = true;
  TextStyle? _measureStyleSnapshot;

  static const _topPad = 10.0;

  @override
  void initState() {
    super.initState();
    _savedText = widget.initial;
    _vim = SettingsStore.instance.quickLookVimMode.value
        ? _VimMode.normal
        : _VimMode.insert;
    _ctrl = HighlightController(
      language: languageForExtension(widget.extension),
      highlight: widget.initial.length <= maxHighlightChars,
    );
    _ctrl.text = widget.initial;
    _lines = '\n'.allMatches(widget.initial).length + 1;
    _ctrl.addListener(_onChanged);
    _focus.addListener(_onFocusChange);
  }

  void _onFocusChange() => widget.editorActive.value = _focus.hasFocus;

  @override
  void dispose() {
    _ctrl.removeListener(_onChanged);
    _ctrl.dispose();
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _vScroll.dispose();
    _hScroll.dispose();
    widget.editorActive.value = false;
    super.dispose();
  }

  void _onChanged() {
    final text = _ctrl.text;
    final dirty = text != _savedText;
    final caret = _ctrl.selection.baseOffset.clamp(0, text.length);
    var line = 0;
    var total = 0;
    for (var i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) == 0x0A) {
        if (i < caret) line++;
        total++;
      }
    }
    final lines = total + 1;
    final settings = SettingsStore.instance;
    final refreshLayout =
        !settings.quickLookWrapLines.value ||
        settings.quickLookShowLineNumbers.value;
    if (dirty != _dirty ||
        line != _caretLine ||
        lines != _lines ||
        _saveError != null ||
        refreshLayout) {
      setState(() {
        _dirty = dirty;
        _caretLine = line;
        _lines = lines;
        _saveError = null;
      });
    }
  }

  Future<void> _save() async {
    if (_saving || !_dirty) return;
    final text = _ctrl.text;
    setState(() => _saving = true);
    try {
      if (PlatformPaths.isSftpUri(widget.path)) {
        await const SftpFs().writeBytes(
          widget.path,
          Uint8List.fromList(utf8.encode(text)),
        );
      } else {
        await File(widget.path).writeAsString(text, flush: true);
      }
      if (!mounted) return;
      setState(() {
        _saving = false;
        _savedText = text;
        _dirty = _ctrl.text != _savedText;
        _saveError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = t.quickLook.saveError;
      });
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final ctrl =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    if (ctrl && event.logicalKey == LogicalKeyboardKey.keyS) {
      _save();
      return KeyEventResult.handled;
    }
    final vimEnabled = SettingsStore.instance.quickLookVimMode.value;
    if (vimEnabled && _vim != _VimMode.insert) {
      return _handleVimNormal(event);
    }
    if (vimEnabled && event.logicalKey == LogicalKeyboardKey.escape) {
      final caret = _ctrl.selection.extentOffset.clamp(0, _ctrl.text.length);
      setState(() => _vim = _VimMode.normal);
      _ctrl.selection = TextSelection.collapsed(offset: caret);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      final sel = _ctrl.selection;
      if (sel.isValid) {
        final text = _ctrl.text;
        final start = sel.start;
        _ctrl.value = _ctrl.value.copyWith(
          text: text.replaceRange(start, sel.end, '  '),
          selection: TextSelection.collapsed(offset: start + 2),
        );
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleVimNormal(KeyEvent event) {
    final text = _ctrl.text;
    final len = text.length;
    final caret = _ctrl.selection.extentOffset.clamp(0, len);
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      setState(() {
        _pending = null;
        if (_vim == _VimMode.visual) _vim = _VimMode.normal;
      });
      _ctrl.selection = TextSelection.collapsed(offset: caret);
      return KeyEventResult.handled;
    }
    final ch = event.character;
    if (ch == null || ch.isEmpty) {
      if (event.logicalKey == LogicalKeyboardKey.tab) {
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (_pending != null) {
      final op = _pending;
      setState(() => _pending = null);
      if (op == 'g' && ch == 'g') {
        _moveTo(0);
      } else if (op == 'd' && ch == 'd') {
        _deleteLine();
      } else if (op == 'y' && ch == 'y') {
        _yankLine();
      }
      return KeyEventResult.handled;
    }
    switch (ch) {
      case 'h':
        _moveTo(_left(text, caret));
      case 'l':
        _moveTo(_right(text, caret));
      case 'j':
        _moveTo(_down(text, caret));
      case 'k':
        _moveTo(_up(text, caret));
      case '0':
        _moveTo(_lineStartOf(text, caret));
      case r'$':
        _moveTo(_lineEndOf(text, caret));
      case '^':
        _moveTo(_firstNonBlank(text, caret));
      case 'w':
        _moveTo(_wordForward(text, caret));
      case 'b':
        _moveTo(_wordBackward(text, caret));
      case 'G':
        _moveTo(_lineStartOf(text, len));
      case 'g':
        setState(() => _pending = 'g');
      case 'i':
        _enterInsert(caret);
      case 'a':
        _enterInsert((caret + 1).clamp(0, len));
      case 'A':
        _enterInsert(_lineEndOf(text, caret));
      case 'I':
        _enterInsert(_firstNonBlank(text, caret));
      case 'o':
        _openLine(below: true);
      case 'O':
        _openLine(below: false);
      case 'x':
        _deleteChar();
      case 'd':
        if (_vim == _VimMode.visual) {
          _deleteSelection();
        } else {
          setState(() => _pending = 'd');
        }
      case 'y':
        if (_vim == _VimMode.visual) {
          _yankSelection();
        } else {
          setState(() => _pending = 'y');
        }
      case 'p':
        _paste();
      case 'v':
        setState(
          () => _vim = _vim == _VimMode.visual
              ? _VimMode.normal
              : _VimMode.visual,
        );
        _ctrl.selection = TextSelection.collapsed(offset: caret);
        _scrollCaretIntoView(caret);
    }
    return KeyEventResult.handled;
  }

  void _moveTo(int offset) {
    final len = _ctrl.text.length;
    final target = offset.clamp(0, len);
    if (_vim == _VimMode.visual) {
      final base = _ctrl.selection.baseOffset.clamp(0, len);
      _ctrl.selection = TextSelection(baseOffset: base, extentOffset: target);
    } else {
      _ctrl.selection = TextSelection.collapsed(offset: target);
    }
    _scrollCaretIntoView(target);
  }

  void _enterInsert(int caret) {
    final len = _ctrl.text.length;
    setState(() => _vim = _VimMode.insert);
    final target = caret.clamp(0, len);
    _ctrl.selection = TextSelection.collapsed(offset: target);
    _scrollCaretIntoView(target);
    _focus.requestFocus();
  }

  void _scrollCaretIntoView(int offset) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final text = _ctrl.text;
      final target = offset.clamp(0, text.length);
      _scrollVerticalCaretIntoView(text, target);
      if (!_wrapLinesSnapshot) {
        _scrollHorizontalCaretIntoView(text, target);
      }
    });
  }

  void _scrollVerticalCaretIntoView(String text, int offset) {
    if (!_vScroll.hasClients || _lineHeightSnapshot.isEmpty) return;
    var line = 0;
    for (var i = 0; i < offset && i < text.length; i++) {
      if (text.codeUnitAt(i) == 0x0A) line++;
    }
    if (line >= _lineHeightSnapshot.length) {
      line = _lineHeightSnapshot.length - 1;
    }
    var top = 0.0;
    for (var i = 0; i < line; i++) {
      top += _lineHeightSnapshot[i];
    }
    final height = _lineHeightSnapshot[line];
    final bottom = top + height;
    final viewport = _editorViewportHeight > 0
        ? _editorViewportHeight
        : _vScroll.position.viewportDimension;
    final current = _vScroll.offset;
    final margin = height;
    double? next;
    if (top < current + margin) {
      next = top - margin;
    } else if (bottom > current + viewport - margin) {
      next = bottom - viewport + margin;
    }
    if (next == null) return;
    _vScroll.jumpTo(
      next.clamp(
        _vScroll.position.minScrollExtent,
        _vScroll.position.maxScrollExtent,
      ),
    );
  }

  void _scrollHorizontalCaretIntoView(String text, int offset) {
    if (!_hScroll.hasClients) return;
    final style = _measureStyleSnapshot;
    if (style == null) return;
    final lineStart = _lineStartOf(text, offset);
    final prefix = text.substring(lineStart, offset);
    final x = _editorLeftPad + _measureTextWidth(prefix, style);
    final viewport = _hScroll.position.viewportDimension;
    final current = _hScroll.offset;
    final margin = _editorTextWidth < 48 ? 0.0 : 24.0;
    double? next;
    if (x < current + margin) {
      next = x - margin;
    } else if (x > current + viewport - margin) {
      next = x - viewport + margin;
    }
    if (next == null) return;
    _hScroll.jumpTo(
      next.clamp(
        _hScroll.position.minScrollExtent,
        _hScroll.position.maxScrollExtent,
      ),
    );
  }

  void _openLine({required bool below}) {
    final text = _ctrl.text;
    final caret = _ctrl.selection.extentOffset.clamp(0, text.length);
    if (below) {
      final le = _lineEndOf(text, caret);
      _ctrl.value = TextEditingValue(
        text: text.replaceRange(le, le, '\n'),
        selection: TextSelection.collapsed(offset: le + 1),
      );
      _enterInsert(le + 1);
    } else {
      final ls = _lineStartOf(text, caret);
      _ctrl.value = TextEditingValue(
        text: text.replaceRange(ls, ls, '\n'),
        selection: TextSelection.collapsed(offset: ls),
      );
      _enterInsert(ls);
    }
  }

  void _deleteChar() {
    final text = _ctrl.text;
    final caret = _ctrl.selection.extentOffset.clamp(0, text.length);
    if (caret >= text.length || text.codeUnitAt(caret) == 0x0A) return;
    final next = text.replaceRange(caret, caret + 1, '');
    final le = _lineEndOf(next, caret);
    final newCaret = caret > le ? le : caret;
    _ctrl.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: newCaret),
    );
  }

  void _deleteLine() {
    final text = _ctrl.text;
    final caret = _ctrl.selection.extentOffset.clamp(0, text.length);
    final ls = _lineStartOf(text, caret);
    final le = _lineEndOf(text, caret);
    _vimRegister = text.substring(ls, le);
    _vimRegisterLinewise = true;
    var removeStart = ls;
    var removeEnd = le;
    if (le < text.length) {
      removeEnd = le + 1;
    } else if (ls > 0) {
      removeStart = ls - 1;
    }
    final next = text.replaceRange(removeStart, removeEnd, '');
    final newCaret = _firstNonBlank(next, removeStart.clamp(0, next.length));
    _ctrl.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(
        offset: newCaret.clamp(0, next.length),
      ),
    );
  }

  void _yankLine() {
    final text = _ctrl.text;
    final caret = _ctrl.selection.extentOffset.clamp(0, text.length);
    final ls = _lineStartOf(text, caret);
    final le = _lineEndOf(text, caret);
    _vimRegister = text.substring(ls, le);
    _vimRegisterLinewise = true;
  }

  void _deleteSelection() {
    final text = _ctrl.text;
    final sel = _ctrl.selection;
    final start = sel.start.clamp(0, text.length);
    var end = sel.end.clamp(0, text.length);
    if (end < text.length) end += 1;
    _vimRegister = text.substring(start, end);
    _vimRegisterLinewise = false;
    final next = text.replaceRange(start, end, '');
    setState(() => _vim = _VimMode.normal);
    _ctrl.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start.clamp(0, next.length)),
    );
  }

  void _yankSelection() {
    final text = _ctrl.text;
    final sel = _ctrl.selection;
    final start = sel.start.clamp(0, text.length);
    var end = sel.end.clamp(0, text.length);
    if (end < text.length) end += 1;
    _vimRegister = text.substring(start, end);
    _vimRegisterLinewise = false;
    setState(() => _vim = _VimMode.normal);
    _ctrl.selection = TextSelection.collapsed(offset: start);
  }

  void _paste() {
    final reg = _vimRegister;
    if (reg == null) return;
    final text = _ctrl.text;
    final caret = _ctrl.selection.extentOffset.clamp(0, text.length);
    if (_vimRegisterLinewise) {
      final le = _lineEndOf(text, caret);
      final String insert;
      final int newCaret;
      if (le < text.length) {
        insert = '$reg\n';
        newCaret = le + 1;
      } else {
        insert = '\n$reg';
        newCaret = le + 1;
      }
      final at = le < text.length ? le + 1 : text.length;
      _ctrl.value = TextEditingValue(
        text: text.replaceRange(at, at, insert),
        selection: TextSelection.collapsed(offset: newCaret),
      );
    } else {
      final at = (caret + 1).clamp(0, text.length);
      _ctrl.value = TextEditingValue(
        text: text.replaceRange(at, at, reg),
        selection: TextSelection.collapsed(offset: at + reg.length - 1),
      );
    }
  }

  int _left(String t, int off) {
    final ls = _lineStartOf(t, off);
    return off > ls ? off - 1 : off;
  }

  int _right(String t, int off) {
    final le = _lineEndOf(t, off);
    return off < le ? off + 1 : off;
  }

  int _down(String t, int off) {
    final ls = _lineStartOf(t, off);
    final col = off - ls;
    final le = _lineEndOf(t, off);
    if (le >= t.length) return off;
    final nextStart = le + 1;
    final nextEnd = _lineEndOf(t, nextStart);
    return (nextStart + col).clamp(nextStart, nextEnd);
  }

  int _up(String t, int off) {
    final ls = _lineStartOf(t, off);
    final col = off - ls;
    if (ls == 0) return off;
    final prevEnd = ls - 1;
    final prevStart = _lineStartOf(t, prevEnd);
    return (prevStart + col).clamp(prevStart, prevEnd);
  }

  int _lineStartOf(String t, int off) {
    var i = off.clamp(0, t.length);
    while (i > 0 && t.codeUnitAt(i - 1) != 0x0A) {
      i--;
    }
    return i;
  }

  int _lineEndOf(String t, int off) {
    var i = off.clamp(0, t.length);
    while (i < t.length && t.codeUnitAt(i) != 0x0A) {
      i++;
    }
    return i;
  }

  int _firstNonBlank(String t, int off) {
    final ls = _lineStartOf(t, off);
    final le = _lineEndOf(t, off);
    var i = ls;
    while (i < le && (t.codeUnitAt(i) == 0x20 || t.codeUnitAt(i) == 0x09)) {
      i++;
    }
    return i;
  }

  int _wordForward(String t, int off) {
    final len = t.length;
    var i = off;
    if (i < len) {
      if (_isWordChar(t.codeUnitAt(i))) {
        while (i < len && _isWordChar(t.codeUnitAt(i))) {
          i++;
        }
      } else if (!_isSpace(t.codeUnitAt(i))) {
        while (i < len &&
            !_isWordChar(t.codeUnitAt(i)) &&
            !_isSpace(t.codeUnitAt(i))) {
          i++;
        }
      }
    }
    while (i < len && _isSpace(t.codeUnitAt(i))) {
      i++;
    }
    return i;
  }

  int _wordBackward(String t, int off) {
    var i = off - 1;
    while (i > 0 && _isSpace(t.codeUnitAt(i))) {
      i--;
    }
    if (i <= 0) return 0;
    if (_isWordChar(t.codeUnitAt(i))) {
      while (i > 0 && _isWordChar(t.codeUnitAt(i - 1))) {
        i--;
      }
    } else {
      while (i > 0 &&
          !_isWordChar(t.codeUnitAt(i - 1)) &&
          !_isSpace(t.codeUnitAt(i - 1))) {
        i--;
      }
    }
    return i;
  }

  bool _isSpace(int c) => c == 0x20 || c == 0x09 || c == 0x0A;

  bool _isWordChar(int c) =>
      (c >= 0x30 && c <= 0x39) ||
      (c >= 0x41 && c <= 0x5A) ||
      (c >= 0x61 && c <= 0x7A) ||
      c == 0x5F;

  String _vimLabel() => switch (_vim) {
    _VimMode.normal => t.quickLook.vimNormal,
    _VimMode.insert => t.quickLook.vimInsert,
    _VimMode.visual => t.quickLook.vimVisual,
  };

  double _lineExtent(TextStyle style, StrutStyle strut) {
    final painter = TextPainter(
      text: TextSpan(text: ' ', style: style),
      strutStyle: strut,
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.height;
  }

  double _measureTextWidth(String text, TextStyle style) {
    if (text.isEmpty) return 0;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  double _lineNumberWidth(int count, TextStyle style) {
    final digits = '$count'.length;
    final sample = List.filled(digits, '8').join();
    return 22 + _measureTextWidth(sample, style);
  }

  double _contentWidth(TextStyle style, double minWidth) {
    var maxWidth = 0.0;
    for (final line in _ctrl.text.split('\n')) {
      final width = _measureTextWidth(line, style);
      if (width > maxWidth) maxWidth = width;
    }
    return maxWidth > minWidth ? maxWidth : minWidth;
  }

  List<double> _lineHeights({
    required TextStyle style,
    required StrutStyle strut,
    required bool wrapLines,
    required double maxWidth,
  }) {
    final lineExtent = _lineExtent(style, strut);
    final lines = _ctrl.text.split('\n');
    if (!wrapLines || maxWidth <= 0) {
      return [for (var i = 0; i < lines.length; i++) lineExtent];
    }
    return [
      for (final line in lines)
        if (line.isEmpty)
          lineExtent
        else
          (TextPainter(
            text: TextSpan(text: line, style: style),
            strutStyle: strut,
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: maxWidth)).height,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: SignalBuilder(
        builder: (context) {
          final s = SettingsStore.instance;
          final vimEnabled = s.quickLookVimMode.value;
          final useSystem = s.quickLookUseSystemFont.value;
          final family = useSystem || s.quickLookFontFamily.value.isEmpty
              ? 'monospace'
              : s.quickLookFontFamily.value;
          final fontSize = s.quickLookFontSize.value.toDouble();
          final lineHeight = s.quickLookLineHeight.value;
          final showLineNumbers = s.quickLookShowLineNumbers.value;
          final relativeLineNumbers = s.quickLookRelativeLineNumbers.value;
          final wrapLines = s.quickLookWrapLines.value;
          final readOnly = vimEnabled && _vim != _VimMode.insert;
          final baseStyle = TextStyle(
            fontFamily: family,
            fontSize: fontSize,
            height: lineHeight,
            color: AppColors.fg,
          );
          final strut = StrutStyle(
            fontSize: fontSize,
            height: lineHeight,
            forceStrutHeight: true,
          );
          return Column(
            children: [
              Expanded(
                child: Focus(
                  onKeyEvent: _onKey,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final lineNumberStyle = baseStyle.copyWith(
                        color: AppColors.fgSubtle,
                      );
                      final maxLineNumber = relativeLineNumbers
                          ? [
                              _caretLine,
                              _lines - 1 - _caretLine,
                            ].reduce((a, b) => a > b ? a : b).clamp(0, _lines)
                          : _lines;
                      final gutterWidth = showLineNumbers
                          ? _lineNumberWidth(maxLineNumber, lineNumberStyle)
                          : 0.0;
                      final paneWidth = (constraints.maxWidth - gutterWidth)
                          .clamp(0.0, double.infinity);
                      final leftPad = showLineNumbers ? 8.0 : 16.0;
                      final editorTextWidth = (paneWidth - leftPad - 16).clamp(
                        0.0,
                        double.infinity,
                      );
                      final contentWidth = wrapLines
                          ? paneWidth
                          : _contentWidth(baseStyle, editorTextWidth) +
                                leftPad +
                                16;
                      final lineHeights = _lineHeights(
                        style: baseStyle,
                        strut: strut,
                        wrapLines: wrapLines,
                        maxWidth: editorTextWidth,
                      );
                      _lineHeightSnapshot = lineHeights;
                      _editorViewportHeight = (constraints.maxHeight - 20)
                          .clamp(0.0, double.infinity);
                      _editorTextWidth = editorTextWidth;
                      _editorLeftPad = leftPad;
                      _wrapLinesSnapshot = wrapLines;
                      _measureStyleSnapshot = baseStyle;
                      final editor = _EditorField(
                        controller: _ctrl,
                        focusNode: _focus,
                        scrollController: _vScroll,
                        baseStyle: baseStyle,
                        strutStyle: strut,
                        topPad: _topPad,
                        leftPad: leftPad,
                        readOnly: readOnly,
                        cursorWidth: readOnly ? fontSize * 0.55 : 1.5,
                      );
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showLineNumbers)
                            _LineGutter(
                              lineHeights: lineHeights,
                              scroll: _vScroll,
                              style: lineNumberStyle,
                              strutStyle: strut,
                              topPad: _topPad,
                              width: gutterWidth,
                              relative: relativeLineNumbers,
                              currentLine: _caretLine,
                            ),
                          Expanded(
                            child: wrapLines
                                ? editor
                                : Scrollbar(
                                    controller: _hScroll,
                                    notificationPredicate: (notification) =>
                                        notification.depth == 0,
                                    child: SingleChildScrollView(
                                      controller: _hScroll,
                                      scrollDirection: Axis.horizontal,
                                      child: SizedBox(
                                        width: contentWidth,
                                        child: editor,
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              Container(height: 1, color: AppColors.bgDivider),
              _StatusBar(
                dirty: _dirty,
                saving: _saving,
                error: _saveError,
                line: _caretLine + 1,
                lineCount: _lines,
                onSave: _save,
                modeLabel: vimEnabled ? _vimLabel() : null,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LineGutter extends StatelessWidget {
  final List<double> lineHeights;
  final ScrollController scroll;
  final TextStyle style;
  final StrutStyle strutStyle;
  final double topPad;
  final double width;
  final bool relative;
  final int currentLine;

  const _LineGutter({
    required this.lineHeights,
    required this.scroll,
    required this.style,
    required this.strutStyle,
    required this.topPad,
    required this.width,
    required this.relative,
    required this.currentLine,
  });

  String _label(int index) {
    if (!relative) return '${index + 1}';
    final distance = (index - currentLine).abs();
    return '$distance';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.bgDivider)),
      ),
      child: ClipRect(
        child: Padding(
          padding: EdgeInsets.only(top: topPad),
          child: AnimatedBuilder(
            animation: scroll,
            builder: (context, _) {
              final offset = scroll.hasClients ? scroll.offset : 0.0;
              return Transform.translate(
                offset: Offset(0, -offset),
                child: OverflowBox(
                  alignment: Alignment.topRight,
                  minHeight: 0,
                  maxHeight: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < lineHeights.length; i++)
                        SizedBox(
                          height: lineHeights[i],
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              _label(i),
                              textAlign: TextAlign.right,
                              style: style,
                              strutStyle: strutStyle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EditorField extends StatelessWidget {
  final HighlightController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final TextStyle baseStyle;
  final StrutStyle strutStyle;
  final double topPad;
  final double leftPad;
  final bool readOnly;
  final double cursorWidth;

  const _EditorField({
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.baseStyle,
    required this.strutStyle,
    required this.topPad,
    required this.leftPad,
    required this.readOnly,
    required this.cursorWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(leftPad, topPad, 16, topPad),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        scrollController: scrollController,
        readOnly: readOnly,
        showCursor: true,
        expands: true,
        maxLines: null,
        cursorColor: AppColors.accent,
        cursorWidth: cursorWidth,
        style: baseStyle,
        strutStyle: strutStyle,
        keyboardType: TextInputType.multiline,
        textAlignVertical: TextAlignVertical.top,
        decoration: const InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final bool dirty;
  final bool saving;
  final String? error;
  final int line;
  final int lineCount;
  final VoidCallback onSave;
  final String? modeLabel;

  const _StatusBar({
    required this.dirty,
    required this.saving,
    required this.error,
    required this.line,
    required this.lineCount,
    required this.onSave,
    required this.modeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final Color dot;
    final String label;
    if (error != null) {
      dot = AppColors.danger;
      label = error!;
    } else if (saving) {
      dot = AppColors.warning;
      label = t.quickLook.save;
    } else if (dirty) {
      dot = AppColors.warning;
      label = t.quickLook.unsaved;
    } else {
      dot = AppColors.success;
      label = t.quickLook.saved;
    }
    return Container(
      height: 30,
      color: AppColors.bgStatus,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: context.txt.caption),
          const Spacer(),
          if (modeLabel != null) ...[
            Text(
              modeLabel!,
              style: context.txt.caption.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 14),
          ],
          Text(
            t.quickLook.linePosition(line: line, count: lineCount),
            style: context.txt.caption.copyWith(color: AppColors.fgMuted),
          ),
          const SizedBox(width: 14),
          _SaveButton(enabled: dirty && !saving, onTap: onSave),
        ],
      ),
    );
  }
}

class _SaveButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _SaveButton({required this.enabled, required this.onTap});

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.enabled ? AppColors.accent : AppColors.fgSubtle;
    return MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _hover && widget.enabled
                ? AppColors.accent.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(WaydirIconsRegular.floppyDisk, size: 13, color: color),
              const SizedBox(width: 6),
              Text(
                '${t.quickLook.save}  ⌃S',
                style: context.txt.caption.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
