import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/file_entry.dart';
import '../../core/platform/platform_paths.dart';
import '../../i18n/strings.g.dart';
import '../icons/waydir_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_toggle_chip.dart';
import 'dialog.dart';

enum _RenameMode { template, findReplace }

class _TokenDef {
  final String token;
  final String description;
  const _TokenDef(this.token, this.description);
}

class MultiRenameResult {
  final List<({String oldPath, String newName})> renames;
  const MultiRenameResult(this.renames);
}

Future<MultiRenameResult?> showMultiRenameDialog({
  required BuildContext context,
  required List<FileEntry> entries,
}) {
  if (entries.isEmpty) return Future.value(null);

  return showDialog<MultiRenameResult>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (ctx) => Center(
      child: Material(
        type: MaterialType.transparency,
        child: _MultiRenameBody(entries: entries),
      ),
    ),
  );
}

class _MultiRenameBody extends StatefulWidget {
  final List<FileEntry> entries;

  const _MultiRenameBody({required this.entries});

  @override
  State<_MultiRenameBody> createState() => _MultiRenameBodyState();
}

class _MultiRenameBodyState extends State<_MultiRenameBody> {
  _RenameMode _mode = _RenameMode.template;

  late final TextEditingController _templateCtrl;
  late final TextEditingController _findCtrl;
  late final TextEditingController _replaceCtrl;
  final FocusNode _templateFocus = FocusNode();
  final FocusNode _replaceFocus = FocusNode();
  bool _useRegex = false;
  bool _caseSensitive = false;
  bool _showOnlyChanged = false;

  late final List<_TokenDef> _tokens = [
    _TokenDef('[FILENAME]', t.multiRename.tokenFilename),
    _TokenDef('[EXT]', t.multiRename.tokenExt),
    _TokenDef('[N]', t.multiRename.tokenN),
    _TokenDef('[INDEX]', t.multiRename.tokenIndex),
    _TokenDef('[DATE]', t.multiRename.tokenDate),
  ];

  @override
  void initState() {
    super.initState();
    _templateCtrl = TextEditingController(text: '[FILENAME][EXT]')
      ..addListener(_rebuild);
    _findCtrl = TextEditingController()..addListener(_rebuild);
    _replaceCtrl = TextEditingController()..addListener(_rebuild);
  }

  @override
  void dispose() {
    _templateCtrl
      ..removeListener(_rebuild)
      ..dispose();
    _findCtrl
      ..removeListener(_rebuild)
      ..dispose();
    _replaceCtrl
      ..removeListener(_rebuild)
      ..dispose();
    _templateFocus.dispose();
    _replaceFocus.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  List<String> get _previews {
    return List.generate(widget.entries.length, (i) {
      final entry = widget.entries[i];

      return switch (_mode) {
        _RenameMode.template => _applyTemplate(_templateCtrl.text, entry, i),
        _RenameMode.findReplace => _applyFindReplace(
          _findCtrl.text,
          _replaceCtrl.text,
          entry,
          i,
        ),
      };
    });
  }

  String _applyTemplate(String template, FileEntry entry, int index) {
    final stem = _stem(entry);
    final ext = _ext(entry);

    return _expandTokens(template, stem, ext, index);
  }

  String _applyFindReplace(
    String find,
    String replace,
    FileEntry entry,
    int index,
  ) {
    if (find.isEmpty) return entry.name;
    final stem = _stem(entry);
    final ext = _ext(entry);
    final expandedReplace = _expandTokens(replace, stem, ext, index);
    String newName;
    if (_useRegex) {
      try {
        final regex = RegExp(find, caseSensitive: _caseSensitive);
        newName = entry.name.replaceAll(regex, expandedReplace);
      } catch (e) {
        newName = entry.name;
      }
    } else {
      if (_caseSensitive) {
        newName = entry.name.replaceAll(find, expandedReplace);
      } else {
        newName = _replaceIgnoreCase(entry.name, find, expandedReplace);
      }
    }

    return newName;
  }

  String _replaceIgnoreCase(String source, String find, String replace) {
    final lower = source.toLowerCase();
    final findLower = find.toLowerCase();
    final buf = StringBuffer();
    var start = 0;
    while (true) {
      final idx = lower.indexOf(findLower, start);
      if (idx < 0) break;
      buf.write(source.substring(start, idx));
      buf.write(replace);
      start = idx + find.length;
    }
    buf.write(source.substring(start));

    return buf.toString();
  }

  String _expandTokens(String template, String stem, String ext, int index) {
    final today = DateTime.now();
    final date =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return template
        .replaceAll('[FILENAME]', stem)
        .replaceAll('[EXT]', ext)
        .replaceAll('[N]', '${index + 1}')
        .replaceAll('[INDEX]', '$index')
        .replaceAll('[DATE]', date);
  }

  String _stem(FileEntry entry) {
    if (entry.type == FileItemType.folder) return entry.name;
    final dotIdx = entry.name.lastIndexOf('.');

    return dotIdx > 0 ? entry.name.substring(0, dotIdx) : entry.name;
  }

  String _ext(FileEntry entry) {
    if (entry.type == FileItemType.folder) return '';
    final dotIdx = entry.name.lastIndexOf('.');

    return dotIdx > 0 ? entry.name.substring(dotIdx) : '';
  }

  bool _isInvalid(String name) => !PlatformPaths.isValidFileName(name.trim());

  Set<String> _duplicates(List<String> previews) {
    final seen = <String>{};
    final dupes = <String>{};
    for (final name in previews) {
      if (!seen.add(name.toLowerCase())) dupes.add(name.toLowerCase());
    }

    return dupes;
  }

  int _changedCount(List<String> previews) {
    var n = 0;
    for (var i = 0; i < widget.entries.length; i++) {
      if (previews[i].trim() != widget.entries[i].name) n++;
    }

    return n;
  }

  int _errorCount(List<String> previews) {
    final dupes = _duplicates(previews);
    var n = 0;
    for (var i = 0; i < previews.length; i++) {
      final name = previews[i];
      if (name.trim() == widget.entries[i].name) continue;
      if (_isInvalid(name) || dupes.contains(name.toLowerCase())) n++;
    }

    return n;
  }

  bool _canSubmit(List<String> previews) {
    return _errorCount(previews) == 0 && _changedCount(previews) > 0;
  }

  void _insertToken(String token) {
    final focus = _mode == _RenameMode.template
        ? _templateFocus
        : _replaceFocus;
    final ctrl = _mode == _RenameMode.template ? _templateCtrl : _replaceCtrl;
    focus.requestFocus();
    final sel = ctrl.selection;
    final text = ctrl.text;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    final newText = text.replaceRange(start, end, token);
    ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + token.length),
    );
  }

  void _submit(List<String> previews) {
    if (!_canSubmit(previews)) return;
    final renames = <({String oldPath, String newName})>[];
    for (var i = 0; i < widget.entries.length; i++) {
      final entry = widget.entries[i];
      final newName = previews[i].trim();
      if (newName != entry.name) {
        renames.add((oldPath: entry.realPath, newName: newName));
      }
    }
    Navigator.of(context).pop(MultiRenameResult(renames));
  }

  @override
  Widget build(BuildContext context) {
    final previews = _previews;
    final dupes = _duplicates(previews);
    final changed = _changedCount(previews);
    final errors = _errorCount(previews);
    final canSubmit = _canSubmit(previews);

    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop();

          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: AppModal(
        icon: WaydirIconsRegular.pencilSimple,
        title: t.multiRename.title,
        width: 640,
        padding: const EdgeInsets.all(20),
        onClose: () => Navigator.of(context).pop(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.multiRename.subtitle(count: widget.entries.length),
              style: context.txt.body.copyWith(color: AppColors.fgMuted),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppToggleChip(
                    label: t.multiRename.modeTemplate,
                    selected: _mode == _RenameMode.template,
                    onTap: () => setState(() => _mode = _RenameMode.template),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppToggleChip(
                    label: t.multiRename.modeFindReplace,
                    selected: _mode == _RenameMode.findReplace,
                    onTap: () =>
                        setState(() => _mode = _RenameMode.findReplace),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_mode == _RenameMode.template) _buildTemplateMode(),
            if (_mode == _RenameMode.findReplace) _buildFindReplaceMode(),
            const SizedBox(height: 12),
            _buildTokenChips(),
            const SizedBox(height: 18),
            _buildPreviewHeader(changed, errors),
            const SizedBox(height: 6),
            _buildTable(previews, dupes),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                DialogButton(
                  label: t.dialog.cancel,
                  color: AppColors.fgMuted,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                DialogButton(
                  label: changed > 0
                      ? t.multiRename.renameCount(count: changed)
                      : t.multiRename.rename,
                  color: canSubmit ? AppColors.accent : AppColors.fgSubtle,
                  onTap: canSubmit ? () => _submit(previews) : () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.multiRename.namePattern, style: context.txt.fieldLabel),
        const SizedBox(height: 6),
        AppTextField(
          controller: _templateCtrl,
          focusNode: _templateFocus,
          autofocus: true,
          onSubmitted: (_) => _submit(_previews),
        ),
      ],
    );
  }

  Widget _buildFindReplaceMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.multiRename.find, style: context.txt.fieldLabel),
                  const SizedBox(height: 6),
                  AppTextField(
                    controller: _findCtrl,
                    autofocus: true,
                    onSubmitted: (_) => _submit(_previews),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.multiRename.replaceWith,
                    style: context.txt.fieldLabel,
                  ),
                  const SizedBox(height: 6),
                  AppTextField(
                    controller: _replaceCtrl,
                    focusNode: _replaceFocus,
                    onSubmitted: (_) => _submit(_previews),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _CheckOption(
              label: t.multiRename.useRegex,
              value: _useRegex,
              onChanged: (v) => setState(() => _useRegex = v),
            ),
            const SizedBox(width: 16),
            _CheckOption(
              label: t.multiRename.caseSensitive,
              value: _caseSensitive,
              onChanged: (v) => setState(() => _caseSensitive = v),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTokenChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Text(t.multiRename.tokens, style: context.txt.fieldLabel),
        ),
        for (final td in _tokens)
          _TokenChip(
            token: td.token,
            tooltip: td.description,
            onTap: () => _insertToken(td.token),
          ),
      ],
    );
  }

  Widget _buildPreviewHeader(int changed, int errors) {
    return Row(
      children: [
        Text(t.multiRename.preview, style: context.txt.fieldLabel),
        const SizedBox(width: 8),
        Text(
          t.multiRename.changedOfTotal(
            changed: changed,
            total: widget.entries.length,
          ),
          style: context.txt.captionSmall.copyWith(
            color: changed > 0 ? AppColors.accent : AppColors.fgMuted,
          ),
        ),
        if (errors > 0) ...[
          const SizedBox(width: 8),
          Text(
            '· ${t.multiRename.errorCount(count: errors)}',
            style: context.txt.captionSmall.copyWith(color: AppColors.danger),
          ),
        ],
        const Spacer(),
        _CheckOption(
          label: t.multiRename.showOnlyChanged,
          value: _showOnlyChanged,
          onChanged: (v) => setState(() => _showOnlyChanged = v),
        ),
      ],
    );
  }

  Widget _buildTable(List<String> previews, Set<String> dupes) {
    final visibleIndexes = <int>[];
    for (var i = 0; i < widget.entries.length; i++) {
      if (_showOnlyChanged && previews[i].trim() == widget.entries[i].name) {
        continue;
      }
      visibleIndexes.add(i);
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          _TableHeader(),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: visibleIndexes.isEmpty
                ? _EmptyState()
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: visibleIndexes.length,
                    itemBuilder: (ctx, listIdx) {
                      final i = visibleIndexes[listIdx];
                      final entry = widget.entries[i];
                      final newName = previews[i];
                      final changed = newName.trim() != entry.name;
                      final invalid = changed && _isInvalid(newName);
                      final isDupe =
                          changed && dupes.contains(newName.toLowerCase());

                      return _TableRow(
                        before: entry.name,
                        after: newName,
                        changed: changed,
                        invalid: invalid,
                        duplicate: isDupe,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TokenChip extends StatefulWidget {
  final String token;
  final String tooltip;
  final VoidCallback onTap;

  const _TokenChip({
    required this.token,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_TokenChip> createState() => _TokenChipState();
}

class _TokenChipState extends State<_TokenChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _hovered
                  ? AppColors.accent.withValues(alpha: 0.15)
                  : AppColors.bgInput,
              border: Border.all(
                color: _hovered ? AppColors.accent : AppColors.borderColor,
              ),
            ),
            child: Text(
              widget.token,
              style: context.txt.keyCap.copyWith(
                color: _hovered ? AppColors.accent : AppColors.fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        border: Border(bottom: BorderSide(color: AppColors.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              t.multiRename.columnBefore,
              style: context.txt.sectionLabel,
            ),
          ),
          const SizedBox(width: 30),
          Expanded(
            child: Text(
              t.multiRename.columnAfter,
              style: context.txt.sectionLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final String before;
  final String after;
  final bool changed;
  final bool invalid;
  final bool duplicate;

  const _TableRow({
    required this.before,
    required this.after,
    required this.changed,
    required this.invalid,
    required this.duplicate,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = invalid || duplicate;
    final trimmedAfter = after.trim();
    final afterColor = hasError
        ? AppColors.danger
        : changed
        ? AppColors.fg
        : AppColors.fgMuted;
    final bg = hasError
        ? AppColors.danger.withValues(alpha: 0.08)
        : Colors.transparent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderColor.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              before,
              style: context.txt.body.copyWith(color: AppColors.fgMuted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            WaydirIconsRegular.arrowRight,
            size: 12,
            color: changed
                ? AppColors.accent.withValues(alpha: 0.7)
                : AppColors.fgSubtle,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    trimmedAfter,
                    style: context.txt.body.copyWith(color: afterColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasError) ...[
                  const SizedBox(width: 6),
                  Text(
                    '· ${invalid ? t.multiRename.errorInvalid : t.multiRename.errorDuplicate}',
                    style: context.txt.captionSmall.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(t.multiRename.noChanges, style: context.txt.bodyMuted),
      ),
    );
  }
}

class _CheckOption extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CheckOption({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: AppColors.accent,
                side: BorderSide(color: AppColors.borderColor),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 6),
            Text(label, style: context.txt.captionSmall),
          ],
        ),
      ),
    );
  }
}
