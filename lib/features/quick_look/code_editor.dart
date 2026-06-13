import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:re_editor/re_editor.dart' as re;
import 'package:re_highlight/styles/atom-one-dark.dart';
import 'package:re_highlight/styles/atom-one-light.dart';
import 'package:signals/signals_flutter.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';

import '../../core/fs/sftp_fs.dart';
import '../../core/platform/platform_paths.dart';
import '../../core/settings/settings_store.dart';
import '../../i18n/strings.g.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import 'editor_languages.dart';
import 'quick_look_common.dart';

enum _VimMode { normal, insert, visual }

/// Lets the host observe unsaved state and trigger a save (e.g. to prompt
/// before closing the preview).
class CodeEditorController {
  final dirty = ValueNotifier<bool>(false);
  Future<bool> Function()? _save;

  /// Saves if dirty. Returns true when there is nothing to save or the save
  /// succeeded, false when the save failed.
  Future<bool> save() async => (await _save?.call()) ?? true;

  void dispose() => dirty.dispose();
}

/// Text/code preview editor. Backed by re_editor, which renders only the lines
/// in the viewport, so editing stays fast regardless of file size.
class CodeEditor extends StatefulWidget {
  final String path;
  final String extension;
  final String initial;
  final ValueNotifier<bool> editorActive;
  final CodeEditorController? controller;

  const CodeEditor({
    super.key,
    required this.path,
    required this.extension,
    required this.initial,
    required this.editorActive,
    this.controller,
  });

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  late final re.CodeLineEditingController _ctrl;
  late final bool _highlight = widget.initial.length <= maxHighlightChars;
  final _scroll = re.CodeScrollController();
  final _focus = FocusNode();

  Object? _savedRevision;
  bool _saving = false;
  String? _saveError;

  late _VimMode _vim;
  String? _pending;
  String? _register;
  bool _registerLinewise = false;

  @override
  void initState() {
    super.initState();
    _ctrl = re.CodeLineEditingController.fromText(widget.initial);
    _savedRevision = _ctrl.value.codeLines;
    _vim = SettingsStore.instance.quickLookVimMode.value
        ? _VimMode.normal
        : _VimMode.insert;
    widget.controller?._save = _save;
    widget.controller?.dirty.value = false;
    _ctrl.addListener(_syncDirty);
    _focus.addListener(_onFocusChange);
  }

  void _onFocusChange() => widget.editorActive.value = _focus.hasFocus;

  void _syncDirty() => widget.controller?.dirty.value = _dirty;

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _ctrl.removeListener(_syncDirty);
    _ctrl.dispose();
    _scroll.dispose();
    widget.editorActive.value = false;
    super.dispose();
  }

  bool get _dirty => !identical(_ctrl.value.codeLines, _savedRevision);

  Future<bool> _save() async {
    if (_saving || !_dirty) return true;
    final text = _ctrl.text;
    final revision = _ctrl.value.codeLines;
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
      if (!mounted) return true;
      setState(() {
        _saving = false;
        _savedRevision = revision;
        _saveError = null;
      });
      widget.controller?.dirty.value = _dirty;
      return true;
    } catch (_) {
      if (!mounted) return false;
      setState(() {
        _saving = false;
        _saveError = t.quickLook.saveError;
      });
      return false;
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final mod =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final vimEnabled = SettingsStore.instance.quickLookVimMode.value;
    if (!vimEnabled) return KeyEventResult.ignored;
    if (mod && event.logicalKey == LogicalKeyboardKey.keyR) {
      _ctrl.redo();
      return KeyEventResult.handled;
    }
    if (_vim == _VimMode.insert) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        setState(() => _vim = _VimMode.normal);
        _reattachInput();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    return _handleVimNormal(event);
  }

  void _enterInsert() {
    setState(() => _vim = _VimMode.insert);
    _reattachInput();
  }

  /// re_editor only opens/closes its text input connection on focus changes,
  /// not when `readOnly` flips. Toggling focus across a frame forces it to
  /// reopen the connection when entering insert mode (and close it on exit).
  void _reattachInput() {
    _focus.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  KeyEventResult _handleVimNormal(KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      setState(() {
        _pending = null;
        if (_vim == _VimMode.visual) _vim = _VimMode.normal;
      });
      _ctrl.cancelSelection();
      return KeyEventResult.handled;
    }
    final ch = event.character;
    if (ch == null || ch.isEmpty) return KeyEventResult.ignored;
    final visual = _vim == _VimMode.visual;

    if (_pending != null) {
      final op = _pending;
      setState(() => _pending = null);
      if (op == 'g' && ch == 'g') {
        visual
            ? _ctrl.extendSelectionToPageStart()
            : _ctrl.moveCursorToPageStart();
      } else if (op == 'd' && ch == 'd') {
        _ctrl.deleteSelectionLines();
      } else if (op == 'd' && ch == 'w') {
        _ctrl.deleteWordForward();
      } else if (op == 'y' && ch == 'y') {
        _yankLine();
      }
      return KeyEventResult.handled;
    }

    switch (ch) {
      case 'h':
        visual
            ? _ctrl.extendSelection(AxisDirection.left)
            : _ctrl.moveCursor(AxisDirection.left);
      case 'l':
        visual
            ? _ctrl.extendSelection(AxisDirection.right)
            : _ctrl.moveCursor(AxisDirection.right);
      case 'j':
        visual
            ? _ctrl.extendSelection(AxisDirection.down)
            : _ctrl.moveCursor(AxisDirection.down);
      case 'k':
        visual
            ? _ctrl.extendSelection(AxisDirection.up)
            : _ctrl.moveCursor(AxisDirection.up);
      case '0':
        visual
            ? _ctrl.extendSelectionToLineStart()
            : _ctrl.moveCursorToLineStart();
      case r'$':
        visual ? _ctrl.extendSelectionToLineEnd() : _ctrl.moveCursorToLineEnd();
      case 'w':
        visual
            ? _ctrl.extendSelectionToWordBoundaryForward()
            : _ctrl.moveCursorToWordBoundaryForward();
      case 'b':
        visual
            ? _ctrl.extendSelectionToWordBoundaryBackward()
            : _ctrl.moveCursorToWordBoundaryBackward();
      case 'G':
        visual ? _ctrl.extendSelectionToPageEnd() : _ctrl.moveCursorToPageEnd();
      case 'g':
        setState(() => _pending = 'g');
      case 'i':
        _enterInsert();
      case 'a':
        _ctrl.moveCursor(AxisDirection.right);
        _enterInsert();
      case 'A':
        _ctrl.moveCursorToLineEnd();
        _enterInsert();
      case 'I':
        _ctrl.moveCursorToLineStart();
        _enterInsert();
      case 'o':
        _ctrl.moveCursorToLineEnd();
        _ctrl.applyNewLine();
        _enterInsert();
      case 'O':
        _ctrl.moveCursorToLineStart();
        _ctrl.applyNewLine();
        _ctrl.moveCursor(AxisDirection.up);
        _enterInsert();
      case 'x':
        _ctrl.deleteForward();
      case 'd':
        if (visual) {
          _ctrl.deleteSelection();
          setState(() => _vim = _VimMode.normal);
        } else {
          setState(() => _pending = 'd');
        }
      case 'y':
        if (visual) {
          _yankSelection();
        } else {
          setState(() => _pending = 'y');
        }
      case 'p':
        _paste();
      case 'u':
        _ctrl.undo();
      case 'v':
        setState(() => _vim = visual ? _VimMode.normal : _VimMode.visual);
    }
    return KeyEventResult.handled;
  }

  void _yankLine() {
    final index = _ctrl.selection.extentIndex;
    _ctrl.selectLine(index);
    _register = _ctrl.selectedText;
    _registerLinewise = true;
    _ctrl.cancelSelection();
  }

  void _yankSelection() {
    _register = _ctrl.selectedText;
    _registerLinewise = false;
    setState(() => _vim = _VimMode.normal);
    _ctrl.cancelSelection();
  }

  void _paste() {
    final reg = _register;
    if (reg == null) return;
    if (_registerLinewise) {
      _ctrl.moveCursorToLineEnd();
      _ctrl.applyNewLine();
      _ctrl.replaceSelection(reg);
    } else {
      _ctrl.replaceSelection(reg);
    }
  }

  String _vimLabel() => switch (_vim) {
    _VimMode.normal => t.quickLook.vimNormal,
    _VimMode.insert => t.quickLook.vimInsert,
    _VimMode.visual => t.quickLook.vimVisual,
  };

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final s = SettingsStore.instance;
        final useSystem = s.quickLookUseSystemFont.value;
        final family = useSystem || s.quickLookFontFamily.value.isEmpty
            ? 'monospace'
            : s.quickLookFontFamily.value;
        final fontSize = s.quickLookFontSize.value.toDouble();
        final lineHeight = s.quickLookLineHeight.value;
        final showLineNumbers = s.quickLookShowLineNumbers.value;
        final relativeLineNumbers = s.quickLookRelativeLineNumbers.value;
        final wrapLines = s.quickLookWrapLines.value;
        final vimEnabled = s.quickLookVimMode.value;
        final readOnly = vimEnabled && _vim != _VimMode.insert;

        final lang = editorLanguageForExtension(widget.extension);
        final isDark = AppColors.brightness == Brightness.dark;
        final style = re.CodeEditorStyle(
          fontSize: fontSize,
          fontFamily: family,
          fontFamilyFallback: const ['monospace'],
          fontHeight: lineHeight,
          textColor: AppColors.fg,
          backgroundColor: AppColors.bg,
          selectionColor: AppColors.accent.withValues(alpha: 0.3),
          highlightColor: AppColors.accent.withValues(alpha: 0.18),
          cursorColor: AppColors.accent,
          cursorWidth: readOnly ? fontSize * 0.5 : 1.5,
          cursorLineColor: AppColors.fg.withValues(alpha: 0.04),
          chunkIndicatorColor: AppColors.fgSubtle,
          codeTheme: lang == null || !_highlight
              ? null
              : re.CodeHighlightTheme(
                  languages: {lang.id: lang.mode},
                  theme: isDark ? atomOneDarkTheme : atomOneLightTheme,
                ),
        );

        final editor = re.CodeEditor(
          controller: _ctrl,
          scrollController: _scroll,
          focusNode: _focus,
          style: style,
          wordWrap: wrapLines,
          readOnly: readOnly,
          showCursorWhenReadOnly: readOnly,
          // re_editor binds Ctrl/Cmd+S to a save intent but ships no action for
          // it; provide ours so the shortcut actually writes the file.
          shortcutOverrideActions: <Type, Action<Intent>>{
            re.CodeShortcutSaveIntent:
                CallbackAction<re.CodeShortcutSaveIntent>(
                  onInvoke: (intent) {
                    _save();
                    return null;
                  },
                ),
          },
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          indicatorBuilder: showLineNumbers
              ? (context, editingController, chunkController, notifier) {
                  return Row(
                    children: [
                      re.DefaultCodeLineNumber(
                        controller: editingController,
                        notifier: notifier,
                        // Reads the caret live so relative numbers update as the
                        // cursor moves without rebuilding the editor.
                        customLineIndex2Text: relativeLineNumbers
                            ? (i) =>
                                  '${(i - editingController.selection.extentIndex).abs()}'
                            : null,
                      ),
                    ],
                  );
                }
              : null,
        );

        return Container(
          color: AppColors.bg,
          child: Column(
            children: [
              Expanded(
                child: Focus(
                  canRequestFocus: false,
                  skipTraversal: true,
                  onKeyEvent: _onKey,
                  child: editor,
                ),
              ),
              Container(height: 1, color: AppColors.bgDivider),
              AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) => _StatusBar(
                  dirty: _dirty,
                  saving: _saving,
                  error: _saveError,
                  line: _ctrl.selection.extentIndex + 1,
                  lineCount: _ctrl.lineCount,
                  onSave: _save,
                  modeLabel: vimEnabled ? _vimLabel() : null,
                ),
              ),
            ],
          ),
        );
      },
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
