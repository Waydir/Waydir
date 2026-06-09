import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';

import '../../core/fs/sftp_fs.dart';
import '../../core/platform/platform_paths.dart';
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
  late String _savedText;
  bool _dirty = false;
  bool _saving = false;
  String? _saveError;
  int _caretLine = 0;
  int _lines = 1;

  static const _fontSize = 13.0;
  static const _lineHeight = 1.5;

  @override
  void initState() {
    super.initState();
    _savedText = widget.initial;
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
    if (dirty != _dirty ||
        line != _caretLine ||
        lines != _lines ||
        _saveError != null) {
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
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final ctrl =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    if (ctrl && event.logicalKey == LogicalKeyboardKey.keyS) {
      _save();
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

  static const _topPad = 10.0;

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: _fontSize,
      height: _lineHeight,
      color: AppColors.fg,
    );
    return Container(
      color: AppColors.bg,
      child: Column(
        children: [
          Expanded(
            child: Focus(
              onKeyEvent: _onKey,
              child: _EditorField(
                controller: _ctrl,
                focusNode: _focus,
                scrollController: _vScroll,
                baseStyle: baseStyle,
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
          ),
        ],
      ),
    );
  }
}

class _EditorField extends StatelessWidget {
  final HighlightController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final TextStyle baseStyle;

  const _EditorField({
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.baseStyle,
  });

  static const _fontSize = _CodeEditorState._fontSize;
  static const _lineHeight = _CodeEditorState._lineHeight;
  static const _topPad = _CodeEditorState._topPad;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, _topPad, 16, _topPad),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        scrollController: scrollController,
        expands: true,
        maxLines: null,
        cursorColor: AppColors.accent,
        cursorWidth: 1.5,
        style: baseStyle,
        strutStyle: const StrutStyle(
          fontSize: _fontSize,
          height: _lineHeight,
          forceStrutHeight: true,
        ),
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

  const _StatusBar({
    required this.dirty,
    required this.saving,
    required this.error,
    required this.line,
    required this.lineCount,
    required this.onSave,
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
