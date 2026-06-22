import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';

import '../../core/keyboard/keyboard_shortcuts.dart';
import '../../i18n/strings.g.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../ui/theme/app_theme.dart';
import 'app_command.dart';
import 'fuzzy_match.dart';

/// Opens the command palette as a top-anchored modal. [onRun] is called with
/// the command the user chose (after it runs), and [recentIds] orders the list
/// when the query is empty.
Future<void> showCommandPalette({
  required BuildContext context,
  required List<AppCommand> commands,
  required void Function(AppCommand command) onRun,
  List<String> recentIds = const [],
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (ctx) => Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 96),
        child: Material(
          type: MaterialType.transparency,
          child: _CommandPalette(
            commands: commands,
            recentIds: recentIds,
            onRun: (cmd) {
              Navigator.of(ctx).pop();
              onRun(cmd);
              cmd.run();
            },
            onClose: () => Navigator.of(ctx).pop(),
          ),
        ),
      ),
    ),
  );
}

class _CommandPalette extends StatefulWidget {
  final List<AppCommand> commands;
  final List<String> recentIds;
  final void Function(AppCommand command) onRun;
  final VoidCallback onClose;

  const _CommandPalette({
    required this.commands,
    required this.recentIds,
    required this.onRun,
    required this.onClose,
  });

  @override
  State<_CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<_CommandPalette> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late final FocusNode _focusNode;
  String _query = '';
  int _selected = 0;
  List<(AppCommand, List<int>)> _resultsCache = const [];

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(onKeyEvent: _onKeyEvent);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<(AppCommand, List<int>)> get _results {
    final q = _query.trim();
    if (q.isEmpty) {
      final order = {
        for (var i = 0; i < widget.recentIds.length; i++)
          widget.recentIds[i]: i,
      };
      final sorted = [
        for (final c in widget.commands)
          if (!c.queryOnly) c,
      ];
      sorted.sort((a, b) {
        final ra = order[a.id] ?? 1 << 30;
        final rb = order[b.id] ?? 1 << 30;
        return ra.compareTo(rb);
      });
      return [for (final c in sorted) (c, const <int>[])];
    }

    final scored = <(AppCommand, int, List<int>)>[];
    for (final cmd in widget.commands) {
      final m = fuzzyMatch(q, cmd.label);
      if (m != null) scored.add((cmd, m.score, m.matchedIndices));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final s in scored) (s.$1, s.$3)];
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final results = _resultsCache;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        _moveSelection(1, results.length);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _moveSelection(-1, results.length);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
        _runSelected(results);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
        widget.onClose();
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _moveSelection(int delta, int count) {
    if (count == 0) return;
    setState(() {
      _selected = (_selected + delta).clamp(0, count - 1);
    });
    _ensureVisible();
  }

  void _runSelected(List<(AppCommand, List<int>)> results) {
    if (results.isEmpty) return;
    final cmd = results[_selected.clamp(0, results.length - 1)].$1;
    if (!cmd.enabled) return;
    widget.onRun(cmd);
  }

  void _ensureVisible() {
    if (!_scrollController.hasClients) return;
    const rowHeight = _CommandRow.height;
    final target = _selected * rowHeight;
    final viewport = _scrollController.position.viewportDimension;
    final offset = _scrollController.offset;
    if (target < offset) {
      _scrollController.jumpTo(target);
    } else if (target + rowHeight > offset + viewport) {
      _scrollController.jumpTo(target + rowHeight - viewport);
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    _resultsCache = results;
    if (_selected >= results.length) _selected = 0;

    return Container(
      width: 560,
      constraints: const BoxConstraints(maxHeight: 440),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildInput(context),
          Container(height: 1, color: AppColors.bgDivider),
          Flexible(
            child: results.isEmpty
                ? _buildEmpty(context)
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: results.length,
                    itemBuilder: (ctx, i) {
                      final (cmd, matched) = results[i];
                      return _CommandRow(
                        command: cmd,
                        matchedIndices: matched,
                        binding: AppShortcuts.tryGetById(cmd.id)?.displayKeys,
                        selected: i == _selected,
                        onTap: cmd.enabled ? () => widget.onRun(cmd) : null,
                        onHover: () => setState(() => _selected = i),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(
            WaydirIconsRegular.magnifyingGlass,
            size: 15,
            color: AppColors.fgSubtle,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              style: context.txt.rowEmphasis,
              cursorColor: AppColors.fg,
              cursorWidth: 1,
              onChanged: (v) => setState(() {
                _query = v;
                _selected = 0;
              }),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: t.commandPalette.placeholder,
                hintStyle: context.txt.rowEmphasis.copyWith(
                  color: AppColors.fgSubtle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Text(t.commandPalette.empty, style: context.txt.muted),
      ),
    );
  }
}

class _CommandRow extends StatelessWidget {
  static const height = 46.0;

  final AppCommand command;
  final List<int> matchedIndices;
  final String? binding;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback onHover;

  const _CommandRow({
    required this.command,
    required this.matchedIndices,
    required this.binding,
    required this.selected,
    required this.onTap,
    required this.onHover,
  });

  Widget _buildLabel(BuildContext context, Color color) {
    final base = context.txt.row.copyWith(color: color);
    if (matchedIndices.isEmpty) {
      return Text(command.label, style: base, overflow: TextOverflow.ellipsis);
    }
    final matched = matchedIndices.toSet();
    final highlight = base.copyWith(
      color: AppColors.accent,
      fontWeight: FontWeight.w600,
    );
    return Text.rich(
      TextSpan(
        children: [
          for (var i = 0; i < command.label.length; i++)
            TextSpan(
              text: command.label[i],
              style: matched.contains(i) ? highlight : base,
            ),
        ],
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    final disabled = !command.enabled;
    final fg = disabled ? AppColors.fgSubtle : AppColors.fg;

    return MouseRegion(
      onEnter: (_) => onHover(),
      cursor: disabled ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          color: selected ? AppColors.bgHover : Colors.transparent,
          child: Row(
            children: [
              Icon(
                command.icon,
                size: 15,
                color: disabled ? AppColors.fgSubtle : AppColors.fgMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel(context, fg),
                    if (command.description != null)
                      Text(
                        command.description!,
                        style: context.txt.muted,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (disabled && command.disabledReason != null)
                Text(command.disabledReason!, style: context.txt.muted)
              else if (binding != null && binding!.isNotEmpty)
                Text(binding!, style: context.txt.keyCap),
            ],
          ),
        ),
      ),
    );
  }
}
