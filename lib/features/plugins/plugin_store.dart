import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:signals/signals.dart';

import '../../core/fs/file_system_service.dart';
import '../../core/logging/app_logger.dart';
import '../../core/models/file_entry.dart';
import '../../core/platform/app_dirs.dart';
import 'plugin_ffi.dart';
import 'plugin_models.dart';

class PluginStore {
  PluginStore._();
  static final PluginStore instance = PluginStore._();

  static const int supportedApiVersion = 1;

  final plugins = signal<List<LoadedPlugin>>(const []);

  Future<void> loadAll() async {
    final dirPath = await AppDirs.plugins();
    final dir = Directory(dirPath);
    final loaded = <LoadedPlugin>[];
    if (await dir.exists()) {
      await for (final entry in dir.list()) {
        if (entry is! Directory) continue;
        final plugin = await _loadOne(entry.path);
        if (plugin != null) loaded.add(plugin);
      }
    }
    plugins.value = loaded;
    log.warn('plugins', 'loaded ${loaded.length} plugin(s) from $dirPath');
  }

  Future<LoadedPlugin?> _loadOne(String dirPath) async {
    final fallbackId = p.basename(dirPath);
    final manifestFile = File(p.join(dirPath, 'manifest.json'));
    final initFile = File(p.join(dirPath, 'init.lua'));
    if (!await manifestFile.exists() || !await initFile.exists()) return null;

    PluginManifest manifest;
    try {
      final raw = jsonDecode(await manifestFile.readAsString());
      manifest = PluginManifest.fromJson(
        raw as Map<String, dynamic>,
        fallbackId,
      );
    } catch (e) {
      return LoadedPlugin(
        manifest: PluginManifest(
          id: fallbackId,
          name: fallbackId,
          version: '0.0.0',
          author: '',
          description: '',
          apiVersion: 0,
          permissions: const {},
        ),
        dir: dirPath,
        enabled: false,
        contributions: const [],
        error: 'manifest: $e',
      );
    }

    if (manifest.apiVersion != supportedApiVersion) {
      return LoadedPlugin(
        manifest: manifest,
        dir: dirPath,
        enabled: false,
        contributions: const [],
        error:
            'api_version ${manifest.apiVersion} not supported '
            '(this build: $supportedApiVersion)',
      );
    }

    final raw = PluginFfi.load(initFile.path);
    if (raw == null) {
      return LoadedPlugin(
        manifest: manifest,
        dir: dirPath,
        enabled: false,
        contributions: const [],
        error: 'native core unavailable',
      );
    }

    Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      return LoadedPlugin(
        manifest: manifest,
        dir: dirPath,
        enabled: false,
        contributions: const [],
        error: 'load result: $e',
      );
    }

    if (parsed['ok'] != true) {
      return LoadedPlugin(
        manifest: manifest,
        dir: dirPath,
        enabled: false,
        contributions: const [],
        error: parsed['error']?.toString() ?? 'unknown load error',
      );
    }

    final allowExec = manifest.permissions.contains('exec');
    final contributions = <PluginContribution>[];
    for (final item in (parsed['contributions'] as List? ?? const [])) {
      final c = item as Map<String, dynamic>;
      final actionId = c['id'] as String?;
      final title = c['title'] as String?;
      if (actionId == null || title == null) continue;
      contributions.add(
        PluginContribution(
          pluginId: manifest.id,
          actionId: actionId,
          menu: c['menu'] as String? ?? 'context',
          title: title,
          icon: c['icon'] as String?,
          when: PluginWhen.fromJson(c['when'] as Map<String, dynamic>?),
          initLuaPath: initFile.path,
          pluginDir: dirPath,
          allowExec: allowExec,
        ),
      );
    }

    return LoadedPlugin(
      manifest: manifest,
      dir: dirPath,
      enabled: true,
      contributions: contributions,
    );
  }

  List<PluginContribution> contextContributionsFor(List<FileEntry> entries) {
    final out = <PluginContribution>[];
    for (final plugin in plugins.value) {
      if (!plugin.enabled || plugin.error != null) continue;
      for (final c in plugin.contributions) {
        if (c.menu != 'context') continue;
        if (c.when.matches(entries, _isInArchive)) out.add(c);
      }
    }
    return out;
  }

  PluginContribution? contributionByFullId(String fullActionId) {
    for (final plugin in plugins.value) {
      for (final c in plugin.contributions) {
        if (c.fullActionId == fullActionId) return c;
      }
    }
    return null;
  }

  Future<List<PluginEffect>> invoke(
    PluginContribution contribution, {
    required List<String> paths,
    required String dir,
  }) async {
    final ctxJson = jsonEncode({
      'paths': paths,
      'dir': dir,
      'plugin_dir': contribution.pluginDir,
    });
    final raw = await PluginFfi.invoke(
      initLuaPath: contribution.initLuaPath,
      actionId: contribution.actionId,
      ctxJson: ctxJson,
      allowExec: contribution.allowExec,
    );
    if (raw == null) return const [];
    try {
      final parsed = jsonDecode(raw) as Map<String, dynamic>;
      if (parsed['ok'] != true) {
        log.error('plugins', 'invoke failed: ${parsed['error']}');
        return [PluginEffect('log', parsed['error']?.toString())];
      }
      final effects = <PluginEffect>[];
      for (final e in (parsed['effects'] as List? ?? const [])) {
        final m = e as Map<String, dynamic>;
        effects.add(PluginEffect(m['type'] as String? ?? '', m['message'] as String?));
      }
      return effects;
    } catch (e) {
      log.error('plugins', 'invoke parse: $e');
      return const [];
    }
  }

  static bool _isInArchive(FileEntry e) =>
      FileSystemService.isInsideArchive(e.path);
}
