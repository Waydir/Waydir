import 'dart:convert';

import 'package:signals/signals.dart';

import '../../core/database/app_database.dart';
import '../../core/logging/app_logger.dart';

/// Persisted per-plugin configuration, cached in memory. Values are stored
/// JSON-encoded so any scalar from a plugin's settings schema round-trips.
class PluginSettingsStore {
  PluginSettingsStore._();
  static final PluginSettingsStore instance = PluginSettingsStore._();

  AppDatabase? _db;

  /// pluginId -> { key -> decoded value }. A signal so the settings UI can
  /// react to writes from plugin actions.
  final values = signal<Map<String, Map<String, dynamic>>>(const {});

  /// Plugin ids the user has turned off.
  final disabled = signal<Set<String>>(const {});

  Future<void> load(AppDatabase db) async {
    _db = db;
    final rows = await db.getAllPluginSettings();
    final out = <String, Map<String, dynamic>>{};
    for (final r in rows) {
      out.putIfAbsent(r.pluginId, () => {})[r.key] = _decode(r.value);
    }
    values.value = out;
    disabled.value = (await db.getDisabledPlugins()).toSet();
  }

  bool isDisabled(String pluginId) => disabled.value.contains(pluginId);

  Future<void> setDisabled(String pluginId, bool value) async {
    final next = {...disabled.value};
    if (value) {
      next.add(pluginId);
    } else {
      next.remove(pluginId);
    }
    disabled.value = next;
    await _db?.setPluginDisabled(pluginId, value);
  }

  Map<String, dynamic> valuesFor(String pluginId) =>
      values.value[pluginId] ?? const {};

  Future<void> set(String pluginId, String key, dynamic value) async {
    final next = {
      for (final e in values.value.entries) e.key: {...e.value},
    };
    next.putIfAbsent(pluginId, () => {})[key] = value;
    values.value = next;
    await _db?.setPluginSetting(pluginId, key, jsonEncode(value));
  }

  Future<void> setAll(String pluginId, Map<String, dynamic> entries) async {
    final next = {
      for (final e in values.value.entries) e.key: {...e.value},
    };
    final bucket = next.putIfAbsent(pluginId, () => {});
    bucket.addAll(entries);
    values.value = next;
    for (final e in entries.entries) {
      await _db?.setPluginSetting(pluginId, e.key, jsonEncode(e.value));
    }
  }

  static dynamic _decode(String raw) {
    try {
      return jsonDecode(raw);
    } catch (e) {
      log.warn('plugins', 'bad stored setting: $e');

      return raw;
    }
  }
}
