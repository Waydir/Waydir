import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals/signals.dart' show signal;
import 'package:signals/signals_flutter.dart' hide signal;

import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../ui/widgets/app_icon.dart';
import 'plugin_icons.dart';
import 'plugin_models.dart';
import 'plugin_store.dart';

typedef PluginBarEffectsHandler =
    Future<void> Function(
      List<PluginEffect> effects,
      PluginRuntimeTarget target,
    );

class PluginBarStore {
  PluginBarStore._();
  static final PluginBarStore instance = PluginBarStore._();

  final states = signal<Map<String, PluginBarState>>(const {});

  void set(String key, PluginBarState state) {
    states.value = {...states.value, key: state};
  }

  void removeAll(Iterable<String> keys) {
    final remove = keys.toSet();
    if (remove.isEmpty) return;
    states.value = {
      for (final e in states.value.entries)
        if (!remove.contains(e.key)) e.key: e.value,
    };
  }
}

class PluginBarHost extends StatefulWidget {
  final String hostId;
  final List<PluginBarContribution> bars;
  final Map<String, dynamic> contextData;
  final String contextKey;
  final PluginBarEffectsHandler onEffects;

  const PluginBarHost({
    super.key,
    required this.hostId,
    required this.bars,
    required this.contextData,
    required this.contextKey,
    required this.onEffects,
  });

  @override
  State<PluginBarHost> createState() => _PluginBarHostState();
}

class _PluginBarHostState extends State<PluginBarHost> {
  final _timers = <String, Timer>{};
  final _intervals = <String, int>{};
  final _inFlight = <String>{};

  @override
  void initState() {
    super.initState();
    _syncTimers(refreshNew: true);
  }

  @override
  void didUpdateWidget(covariant PluginBarHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTimers(refreshNew: true);
    if (oldWidget.contextKey != widget.contextKey) {
      for (final bar in widget.bars) {
        unawaited(_refresh(bar));
      }
    }
  }

  @override
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    PluginBarStore.instance.removeAll(_timers.keys);
    _timers.clear();
    _intervals.clear();
    super.dispose();
  }

  void _syncTimers({required bool refreshNew}) {
    final next = {for (final bar in widget.bars) _stateKey(bar): bar};
    final removed = _timers.keys
        .where((key) => !next.containsKey(key))
        .toList();
    for (final key in removed) {
      _timers.remove(key)?.cancel();
      _intervals.remove(key);
    }
    PluginBarStore.instance.removeAll(removed);
    for (final entry in next.entries) {
      if (_intervals[entry.key] != entry.value.intervalSeconds) {
        _timers.remove(entry.key)?.cancel();
        _intervals.remove(entry.key);
      }
      if (_timers.containsKey(entry.key)) continue;
      final bar = entry.value;
      final key = entry.key;
      _intervals[key] = bar.intervalSeconds;
      _timers[entry.key] = Timer.periodic(
        Duration(seconds: bar.intervalSeconds),
        (_) {
          final current = _barForKey(key);
          if (current != null) unawaited(_refresh(current));
        },
      );
      if (refreshNew) unawaited(_refresh(bar));
    }
  }

  String _stateKey(PluginBarContribution bar) {
    return '${widget.hostId}:${bar.fullBarId}';
  }

  PluginBarContribution? _barForKey(String key) {
    for (final bar in widget.bars) {
      if (_stateKey(bar) == key) return bar;
    }
    return null;
  }

  Future<void> _refresh(PluginBarContribution bar) async {
    final key = _stateKey(bar);
    if (_inFlight.contains(key)) return;
    _inFlight.add(key);
    try {
      final result = await PluginStore.instance.updateBar(
        bar,
        context: widget.contextData,
      );
      if (!mounted) return;
      final state = result.state;
      if (state != null) PluginBarStore.instance.set(key, state);
      if (result.effects.isNotEmpty) {
        await widget.onEffects(result.effects, bar);
      }
    } finally {
      _inFlight.remove(key);
    }
  }

  Future<void> _click(PluginBarContribution bar, PluginBarItem item) async {
    if (item.action == 'refresh') {
      await _refresh(bar);
      return;
    }
    final itemId = item.id.isNotEmpty ? item.id : item.action ?? '';
    if (itemId.isEmpty) return;
    final result = await PluginStore.instance.clickBar(
      bar,
      itemId: itemId,
      context: widget.contextData,
    );
    if (!mounted) return;
    if (result.effects.isNotEmpty) await widget.onEffects(result.effects, bar);
    final state = result.state;
    if (state != null) PluginBarStore.instance.set(_stateKey(bar), state);
    await _refresh(bar);
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final states = PluginBarStore.instance.states.value;
        final visible = <(PluginBarContribution, PluginBarState)>[];
        for (final bar in widget.bars) {
          final state = states[_stateKey(bar)];
          if (state == null || !state.visible || state.items.isEmpty) continue;
          visible.add((bar, state));
        }
        if (visible.isEmpty) return const SizedBox.shrink();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final row in visible)
              _PluginBarRow(
                bar: row.$1,
                state: row.$2,
                onItemTap: (item) => unawaited(_click(row.$1, item)),
              ),
          ],
        );
      },
    );
  }
}

class _PluginBarRow extends StatelessWidget {
  final PluginBarContribution bar;
  final PluginBarState state;
  final void Function(PluginBarItem item) onItemTap;

  const _PluginBarRow({
    required this.bar,
    required this.state,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconPath = bar.iconPath;
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.bgStatus,
        border: Border(top: BorderSide(color: AppColors.bgDivider)),
      ),
      child: Row(
        children: [
          if (iconPath != null)
            AppIcon(path: iconPath, size: 13)
          else
            Icon(pluginGlyph(bar.icon), size: 13, color: AppColors.fgMuted),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              bar.title,
              style: context.txt.muted,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          for (final item in state.items) _PluginBarItemView(item, onItemTap),
        ],
      ),
    );
  }
}

class _PluginBarItemView extends StatelessWidget {
  final PluginBarItem item;
  final void Function(PluginBarItem item) onTap;

  const _PluginBarItemView(this.item, this.onTap);

  @override
  Widget build(BuildContext context) {
    switch (item.type) {
      case 'separator':
        return Container(
          width: 1,
          height: 12,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          color: AppColors.bgDivider,
        );
      case 'badge':
        return _PluginBarBadge(item: item);
      case 'button':
        return _PluginBarButton(item: item, onTap: () => onTap(item));
      case 'icon':
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Icon(
            pluginGlyph(item.icon),
            size: 13,
            color: _levelColor(item.level) ?? AppColors.fgMuted,
          ),
        );
      default:
        return Flexible(
          fit: FlexFit.loose,
          child: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Text(
              item.text,
              style: context.txt.muted.copyWith(color: _levelColor(item.level)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
    }
  }
}

class _PluginBarBadge extends StatelessWidget {
  final PluginBarItem item;

  const _PluginBarBadge({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = _levelColor(item.level) ?? AppColors.fgMuted;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.zero,
      ),
      child: Text(
        item.text,
        style: context.txt.muted.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PluginBarButton extends StatefulWidget {
  final PluginBarItem item;
  final VoidCallback onTap;

  const _PluginBarButton({required this.item, required this.onTap});

  @override
  State<_PluginBarButton> createState() => _PluginBarButtonState();
}

class _PluginBarButtonState extends State<_PluginBarButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = _hovered ? AppColors.fg : AppColors.fgMuted;
    final child = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 20,
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.bgHover : Colors.transparent,
            borderRadius: BorderRadius.zero,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.item.icon != null)
                Icon(pluginGlyph(widget.item.icon), size: 13, color: color),
              if (widget.item.icon != null && widget.item.text.isNotEmpty)
                const SizedBox(width: 4),
              if (widget.item.text.isNotEmpty)
                Text(
                  widget.item.text,
                  style: context.txt.muted.copyWith(color: color),
                ),
            ],
          ),
        ),
      ),
    );
    final tooltip = widget.item.tooltip;
    if (tooltip == null || tooltip.isEmpty) return child;
    return Tooltip(message: tooltip, child: child);
  }
}

Color? _levelColor(String? level) {
  switch (level) {
    case 'success':
      return AppColors.success;
    case 'warn':
    case 'warning':
      return AppColors.warning;
    case 'error':
    case 'danger':
      return AppColors.danger;
    case 'info':
      return AppColors.fgAccent;
  }
  return null;
}
