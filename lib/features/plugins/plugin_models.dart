import 'package:path/path.dart' as p;

import '../../core/models/file_entry.dart';

abstract class PluginRuntimeTarget {
  String get pluginId;
  PluginManifest get manifest;
  String get runtimeId;
}

class PluginManifest {
  final String id;
  final String name;
  final String version;
  final String author;
  final String description;
  final int apiVersion;

  const PluginManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.author,
    required this.description,
    required this.apiVersion,
  });

  factory PluginManifest.fromJson(
    Map<String, dynamic> json,
    String fallbackId,
  ) {
    return PluginManifest(
      id: (json['id'] as String?)?.trim().isNotEmpty == true
          ? json['id'] as String
          : fallbackId,
      name: json['name'] as String? ?? fallbackId,
      version: json['version'] as String? ?? '0.0.0',
      author: json['author'] as String? ?? '',
      description: json['description'] as String? ?? '',
      apiVersion: (json['api_version'] as num?)?.toInt() ?? 1,
    );
  }
}

class PluginWhen {
  final Set<String> types;
  final Set<String> extensions;
  final int min;
  final int? max;
  final bool? inArchive;

  const PluginWhen({
    this.types = const {},
    this.extensions = const {},
    this.min = 1,
    this.max,
    this.inArchive,
  });

  factory PluginWhen.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PluginWhen();
    Set<String> strSet(dynamic v) => v is List
        ? v.whereType<String>().map((e) => e.toLowerCase()).toSet()
        : {};

    return PluginWhen(
      types: strSet(json['types']),
      extensions: strSet(json['extensions']),
      min: (json['min'] as num?)?.toInt() ?? 1,
      max: (json['max'] as num?)?.toInt(),
      inArchive: json['in_archive'] as bool?,
    );
  }

  bool matches(List<FileEntry> entries, bool Function(FileEntry) inArchiveOf) {
    if (entries.isEmpty || entries.length < min) return false;
    if (max != null && entries.length > max!) return false;
    for (final e in entries) {
      final kind = e.type == FileItemType.folder ? 'folder' : 'file';
      if (types.isNotEmpty && !types.contains(kind)) return false;
      if (extensions.isNotEmpty) {
        if (e.type == FileItemType.folder) return false;
        if (!extensions.contains(e.extension.toLowerCase())) return false;
      }
      if (inArchive != null && inArchiveOf(e) != inArchive) return false;
    }

    return true;
  }
}

/// One field in a plugin-declared form (settings schema or `dialog` effect).
class PluginFormField {
  final String id;
  final String type;
  final String label;
  final String? hint;
  final dynamic defaultValue;
  final List<PluginFormOption> options;

  const PluginFormField({
    required this.id,
    required this.type,
    required this.label,
    this.hint,
    this.defaultValue,
    this.options = const [],
  });

  factory PluginFormField.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];

    return PluginFormField(
      id: json['id'] as String? ?? '',
      type: (json['type'] as String? ?? 'text').toLowerCase(),
      label: json['label'] as String? ?? (json['id'] as String? ?? ''),
      hint: json['hint'] as String?,
      defaultValue: json['default'],
      options: rawOptions is List
          ? rawOptions
                .whereType<Object>()
                .map(PluginFormOption.fromAny)
                .toList()
          : const [],
    );
  }

  static List<PluginFormField> listFromJson(dynamic raw) {
    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map((e) => PluginFormField.fromJson(e.cast<String, dynamic>()))
        .where((f) => f.id.isNotEmpty)
        .toList();
  }
}

class PluginFormOption {
  final String value;
  final String label;

  const PluginFormOption({required this.value, required this.label});

  factory PluginFormOption.fromAny(Object raw) {
    if (raw is Map) {
      final m = raw.cast<String, dynamic>();
      final value = (m['value'] ?? m['id'] ?? '').toString();

      return PluginFormOption(
        value: value,
        label: m['label'] as String? ?? value,
      );
    }
    final s = raw.toString();

    return PluginFormOption(value: s, label: s);
  }
}

class PluginContribution implements PluginRuntimeTarget {
  @override
  final String pluginId;
  final String actionId;
  final String menu;
  final String title;
  final String? group;
  final String? icon;
  final PluginWhen when;
  final Set<String> surfaces;
  final String? shortcut;

  /// When non-null, this contribution is a reactive event handler (e.g.
  /// `navigate`, `selection_change`) rather than a menu/toolbar action, and is
  /// hidden from every menu surface.
  final String? event;
  final List<PluginFormField> settings;
  final String initLuaPath;
  final String pluginDir;
  @override
  final PluginManifest manifest;

  const PluginContribution({
    required this.pluginId,
    required this.actionId,
    required this.menu,
    required this.title,
    required this.group,
    required this.icon,
    required this.when,
    required this.surfaces,
    required this.shortcut,
    required this.event,
    required this.settings,
    required this.initLuaPath,
    required this.pluginDir,
    required this.manifest,
  });

  String get fullActionId => 'plugin:$pluginId:$actionId';

  @override
  String get runtimeId => fullActionId;

  /// Resolves [icon] to an absolute file path when it points at an image
  /// (PNG/SVG) bundled in the plugin, or null for the default glyph.
  String? get iconPath {
    final ic = icon;
    if (ic == null) return null;
    if (ic.contains('/') || ic.endsWith('.svg') || ic.endsWith('.png')) {
      return p.isAbsolute(ic) ? ic : p.join(pluginDir, ic);
    }

    return null;
  }

  bool showsOn(String surface) => surfaces.contains(surface);
}

class PluginBarContribution implements PluginRuntimeTarget {
  @override
  final String pluginId;
  final String barId;
  final String scope;
  final String title;
  final String? icon;
  final int intervalSeconds;
  final bool refreshOnContextChange;
  final List<PluginFormField> settings;
  final String initLuaPath;
  final String pluginDir;
  @override
  final PluginManifest manifest;

  const PluginBarContribution({
    required this.pluginId,
    required this.barId,
    required this.scope,
    required this.title,
    required this.icon,
    required this.intervalSeconds,
    required this.refreshOnContextChange,
    required this.settings,
    required this.initLuaPath,
    required this.pluginDir,
    required this.manifest,
  });

  String get fullBarId => 'plugin:$pluginId:bar:$barId';

  @override
  String get runtimeId => fullBarId;

  String? get iconPath {
    final ic = icon;
    if (ic == null) return null;
    if (ic.contains('/') || ic.endsWith('.svg') || ic.endsWith('.png')) {
      return p.isAbsolute(ic) ? ic : p.join(pluginDir, ic);
    }

    return null;
  }
}

class PluginColumnContribution implements PluginRuntimeTarget {
  @override
  final String pluginId;
  final String columnId;
  final String title;
  final double width;
  final List<PluginFormField> settings;
  final String initLuaPath;
  final String pluginDir;
  @override
  final PluginManifest manifest;

  const PluginColumnContribution({
    required this.pluginId,
    required this.columnId,
    required this.title,
    required this.width,
    required this.settings,
    required this.initLuaPath,
    required this.pluginDir,
    required this.manifest,
  });

  String get fullColumnId => 'plugin:$pluginId:col:$columnId';

  @override
  String get runtimeId => fullColumnId;
}

class PluginBarItem {
  final String type;
  final String id;
  final String text;
  final String? icon;
  final String? tooltip;
  final String? level;
  final String? action;

  const PluginBarItem({
    required this.type,
    required this.id,
    required this.text,
    this.icon,
    this.tooltip,
    this.level,
    this.action,
  });

  factory PluginBarItem.fromJson(Map<String, dynamic> json) {
    return PluginBarItem(
      type: (json['type'] as String? ?? 'text').toLowerCase(),
      id: json['id'] as String? ?? '',
      text: (json['text'] ?? json['label'] ?? '').toString(),
      icon: json['icon'] as String?,
      tooltip: json['tooltip'] as String?,
      level: (json['level'] as String?)?.toLowerCase(),
      action: (json['action'] as String?)?.toLowerCase(),
    );
  }
}

class PluginBarState {
  final bool visible;
  final List<PluginBarItem> items;
  final String? error;
  final DateTime updatedAt;

  const PluginBarState({
    required this.visible,
    required this.items,
    required this.updatedAt,
    this.error,
  });

  factory PluginBarState.hidden() {
    return PluginBarState(
      visible: false,
      items: const [],
      updatedAt: DateTime.now(),
    );
  }

  factory PluginBarState.error(String message) {
    return PluginBarState(
      visible: true,
      items: [
        PluginBarItem(
          type: 'badge',
          id: 'error',
          text: message,
          level: 'error',
        ),
      ],
      error: message,
      updatedAt: DateTime.now(),
    );
  }

  factory PluginBarState.fromJson(dynamic raw) {
    if (raw is! Map) return PluginBarState.hidden();
    final map = raw.cast<String, dynamic>();
    final itemsRaw = map['items'];

    return PluginBarState(
      visible: map['visible'] != false,
      items: itemsRaw is List
          ? itemsRaw
                .whereType<Map>()
                .map((e) => PluginBarItem.fromJson(e.cast<String, dynamic>()))
                .toList()
          : const [],
      updatedAt: DateTime.now(),
    );
  }
}

class PluginBarInvokeResult {
  final PluginBarState? state;
  final List<PluginEffect> effects;

  const PluginBarInvokeResult({required this.state, required this.effects});
}

class LoadedPlugin {
  final PluginManifest manifest;
  final String dir;
  final bool enabled;
  final List<PluginContribution> contributions;
  final List<PluginBarContribution> bars;
  final List<PluginColumnContribution> columns;
  final String? error;

  const LoadedPlugin({
    required this.manifest,
    required this.dir,
    required this.enabled,
    required this.contributions,
    this.bars = const [],
    this.columns = const [],
    this.error,
  });

  /// Combined settings schema across all of the plugin's contributions,
  /// de-duplicated by field id (first wins).
  List<PluginFormField> get settingsSchema {
    final seen = <String>{};
    final out = <PluginFormField>[];
    for (final c in contributions) {
      for (final f in c.settings) {
        if (seen.add(f.id)) out.add(f);
      }
    }
    for (final b in bars) {
      for (final f in b.settings) {
        if (seen.add(f.id)) out.add(f);
      }
    }
    for (final c in columns) {
      for (final f in c.settings) {
        if (seen.add(f.id)) out.add(f);
      }
    }

    return out;
  }
}

class PluginEffect {
  final String type;
  final Map<String, dynamic> data;

  const PluginEffect(this.type, this.data);

  String? get message => data['message'] as String?;
}
