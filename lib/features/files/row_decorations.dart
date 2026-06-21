import 'package:flutter/material.dart';
import 'package:signals/signals.dart';

class RowDecoration {
  final Color tint;
  final String? badge;
  final List<Color> badgeColors;

  const RowDecoration({
    required this.tint,
    this.badge,
    this.badgeColors = const [],
  });
}

class RowDecorationStore {
  final _layers = signal<Map<String, Map<String, RowDecoration>>>({});
  final _reactiveLayers = <ReadonlySignal<Map<String, RowDecoration>>>[];

  void setLayer(String source, Map<String, RowDecoration> deco) {
    _layers.value = {..._layers.value, source: Map.unmodifiable(deco)};
  }

  void clearLayer(String source) {
    if (!_layers.value.containsKey(source)) return;
    final next = Map<String, Map<String, RowDecoration>>.from(_layers.value);
    next.remove(source);
    _layers.value = next;
  }

  void addReactiveLayer(ReadonlySignal<Map<String, RowDecoration>> layer) {
    _reactiveLayers.add(layer);
  }

  late final byPath = computed<Map<String, RowDecoration>>(() {
    final merged = <String, RowDecoration>{};
    for (final layer in _layers.value.values) {
      merged.addAll(layer);
    }
    for (final layer in _reactiveLayers) {
      merged.addAll(layer.value);
    }

    return Map.unmodifiable(merged);
  });

  void dispose() {
    byPath.dispose();
    _layers.dispose();
  }
}
