import '../../core/models/file_entry.dart';

class PluginManifest {
  final String id;
  final String name;
  final String version;
  final String author;
  final String description;
  final int apiVersion;
  final Set<String> permissions;

  const PluginManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.author,
    required this.description,
    required this.apiVersion,
    required this.permissions,
  });

  factory PluginManifest.fromJson(Map<String, dynamic> json, String fallbackId) {
    final perms = json['permissions'];
    return PluginManifest(
      id: (json['id'] as String?)?.trim().isNotEmpty == true
          ? json['id'] as String
          : fallbackId,
      name: json['name'] as String? ?? fallbackId,
      version: json['version'] as String? ?? '0.0.0',
      author: json['author'] as String? ?? '',
      description: json['description'] as String? ?? '',
      apiVersion: (json['api_version'] as num?)?.toInt() ?? 1,
      permissions: perms is List
          ? perms.whereType<String>().toSet()
          : const <String>{},
    );
  }

  /// Permission bitmask passed to the native invoke call. Keep in sync with
  /// the `PERM_*` constants in `rust/waydir_core/src/plugin.rs`.
  int get permsBitmask {
    var bits = 0;
    if (permissions.contains('exec')) bits |= 1 << 0;
    if (permissions.contains('fs')) bits |= 1 << 1;
    return bits;
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
    Set<String> strSet(dynamic v) =>
        v is List ? v.whereType<String>().map((e) => e.toLowerCase()).toSet() : {};
    return PluginWhen(
      types: strSet(json['types']),
      extensions: strSet(json['extensions']),
      min: (json['min'] as num?)?.toInt() ?? 1,
      max: (json['max'] as num?)?.toInt(),
      inArchive: json['in_archive'] as bool?,
    );
  }

  bool matches(
    List<FileEntry> entries,
    bool Function(FileEntry) inArchiveOf,
  ) {
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

class PluginContribution {
  final String pluginId;
  final String actionId;
  final String menu;
  final String title;
  final String? icon;
  final PluginWhen when;
  final Set<String> surfaces;
  final String? shortcut;
  final List<PluginFormField> settings;
  final String initLuaPath;
  final String pluginDir;
  final PluginManifest manifest;

  const PluginContribution({
    required this.pluginId,
    required this.actionId,
    required this.menu,
    required this.title,
    required this.icon,
    required this.when,
    required this.surfaces,
    required this.shortcut,
    required this.settings,
    required this.initLuaPath,
    required this.pluginDir,
    required this.manifest,
  });

  String get fullActionId => 'plugin:$pluginId:$actionId';

  bool get allowExec => manifest.permissions.contains('exec');

  bool showsOn(String surface) => surfaces.contains(surface);
}

class LoadedPlugin {
  final PluginManifest manifest;
  final String dir;
  final bool enabled;
  final List<PluginContribution> contributions;
  final String? error;

  const LoadedPlugin({
    required this.manifest,
    required this.dir,
    required this.enabled,
    required this.contributions,
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
    return out;
  }
}

class PluginEffect {
  final String type;
  final Map<String, dynamic> data;

  const PluginEffect(this.type, this.data);

  String? get message => data['message'] as String?;
}
