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

class PluginContribution {
  final String pluginId;
  final String actionId;
  final String menu;
  final String title;
  final String? icon;
  final PluginWhen when;
  final String initLuaPath;
  final String pluginDir;
  final bool allowExec;

  const PluginContribution({
    required this.pluginId,
    required this.actionId,
    required this.menu,
    required this.title,
    required this.icon,
    required this.when,
    required this.initLuaPath,
    required this.pluginDir,
    required this.allowExec,
  });

  String get fullActionId => 'plugin:$pluginId:$actionId';
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
}

class PluginEffect {
  final String type;
  final String? message;

  const PluginEffect(this.type, this.message);
}
