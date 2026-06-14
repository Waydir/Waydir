import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:signals/signals.dart';

import '../../core/fs/file_system_service.dart';
import '../../core/keyboard/keyboard_shortcuts.dart';
import '../../core/logging/app_logger.dart';
import '../../core/models/file_entry.dart';
import '../../core/platform/app_dirs.dart';
import 'plugin_ffi.dart';
import 'plugin_models.dart';
import 'plugin_settings_store.dart';

class PluginStore {
  PluginStore._();
  static final PluginStore instance = PluginStore._();

  static const int supportedApiVersion = 2;

  final plugins = signal<List<LoadedPlugin>>(const []);

  LoadedPlugin? pluginById(String pluginId) {
    for (final p in plugins.value) {
      if (p.manifest.id == pluginId) return p;
    }
    return null;
  }

  /// Schema defaults overlaid with the user's stored values for [pluginId],
  /// injected into the Lua context as `ctx.settings`.
  Map<String, dynamic> mergedSettings(String pluginId) {
    final out = <String, dynamic>{};
    final plugin = pluginById(pluginId);
    if (plugin != null) {
      for (final f in plugin.settingsSchema) {
        if (f.defaultValue != null) out[f.id] = f.defaultValue;
      }
    }
    out.addAll(PluginSettingsStore.instance.valuesFor(pluginId));
    return out;
  }

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
    _syncShortcuts();
  }

  void _syncShortcuts() {
    final defs = <ShortcutDef>[];
    final taken = <KeyChord>[];
    for (final c in shortcutContributions()) {
      final chord = AppShortcuts.parseChord(c.shortcut!);
      if (chord == null) {
        log.warn(
          'plugins',
          'unparseable shortcut "${c.shortcut}" for ${c.fullActionId}',
        );
        continue;
      }
      if (AppShortcuts.isChordUsedByBuiltin(chord)) {
        log.warn(
          'plugins',
          'shortcut "${c.shortcut}" for ${c.fullActionId} conflicts with a built-in; ignored',
        );
        continue;
      }
      if (taken.any((t) => t.sameChord(chord))) {
        log.warn(
          'plugins',
          'shortcut "${c.shortcut}" for ${c.fullActionId} conflicts with another plugin; ignored',
        );
        continue;
      }
      taken.add(chord);
      final title = c.title;
      defs.add(
        ShortcutDef(
          id: c.fullActionId,
          label: () => title,
          group: ShortcutGroup.plugins,
          key: chord.key,
          ctrl: chord.ctrl,
          shift: chord.shift,
          alt: chord.alt,
        ),
      );
    }
    AppShortcuts.setPluginShortcuts(defs);
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
        bars: const [],
        error: 'manifest: $e',
      );
    }

    if (manifest.apiVersion != supportedApiVersion) {
      return LoadedPlugin(
        manifest: manifest,
        dir: dirPath,
        enabled: false,
        contributions: const [],
        bars: const [],
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
        bars: const [],
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
        bars: const [],
        error: 'load result: $e',
      );
    }

    if (parsed['ok'] != true) {
      return LoadedPlugin(
        manifest: manifest,
        dir: dirPath,
        enabled: false,
        contributions: const [],
        bars: const [],
        error: parsed['error']?.toString() ?? 'unknown load error',
      );
    }

    final contributions = <PluginContribution>[];
    for (final item in (parsed['contributions'] as List? ?? const [])) {
      final c = item as Map<String, dynamic>;
      final actionId = c['id'] as String?;
      final title = c['title'] as String?;
      if (actionId == null || title == null) continue;
      final whereRaw = c['where'];
      final surfaces = whereRaw is List
          ? whereRaw.whereType<String>().map((e) => e.toLowerCase()).toSet()
          : <String>{'selection'};
      if (surfaces.isEmpty) surfaces.add('selection');
      contributions.add(
        PluginContribution(
          pluginId: manifest.id,
          actionId: actionId,
          menu: c['menu'] as String? ?? 'context',
          title: title,
          group: (c['group'] as String?)?.trim().isNotEmpty == true
              ? c['group'] as String
              : null,
          icon: c['icon'] as String?,
          when: PluginWhen.fromJson(c['when'] as Map<String, dynamic>?),
          surfaces: surfaces,
          shortcut: c['shortcut'] as String?,
          settings: PluginFormField.listFromJson(c['settings']),
          initLuaPath: initFile.path,
          pluginDir: dirPath,
          manifest: manifest,
        ),
      );
    }

    final bars = <PluginBarContribution>[];
    for (final item in (parsed['bars'] as List? ?? const [])) {
      final c = item as Map<String, dynamic>;
      final barId = c['id'] as String?;
      if (barId == null || barId.trim().isEmpty) continue;
      final interval = (c['interval'] as num?)?.toInt() ?? 10;
      bars.add(
        PluginBarContribution(
          pluginId: manifest.id,
          barId: barId,
          scope: (c['scope'] as String? ?? 'global').toLowerCase(),
          title: c['title'] as String? ?? barId,
          icon: c['icon'] as String?,
          intervalSeconds: interval <= 0 ? 0 : interval.clamp(2, 3600),
          refreshOnContextChange: c['refresh_on_change'] as bool? ?? true,
          settings: PluginFormField.listFromJson(c['settings']),
          initLuaPath: initFile.path,
          pluginDir: dirPath,
          manifest: manifest,
        ),
      );
    }

    return LoadedPlugin(
      manifest: manifest,
      dir: dirPath,
      enabled: true,
      contributions: contributions,
      bars: bars,
    );
  }

  Iterable<PluginContribution> get _activeContributions sync* {
    final disabled = PluginSettingsStore.instance.disabled.value;
    for (final plugin in plugins.value) {
      if (!plugin.enabled || plugin.error != null) continue;
      if (disabled.contains(plugin.manifest.id)) continue;
      yield* plugin.contributions;
    }
  }

  /// Re-derives state that depends on which plugins are active (e.g. after the
  /// user enables/disables one). Call when the disabled set changes.
  void applyEnablement() => _syncShortcuts();

  Iterable<PluginBarContribution> get _activeBars sync* {
    final disabled = PluginSettingsStore.instance.disabled.value;
    for (final plugin in plugins.value) {
      if (!plugin.enabled || plugin.error != null) continue;
      if (disabled.contains(plugin.manifest.id)) continue;
      yield* plugin.bars;
    }
  }

  List<PluginContribution> contextContributionsFor(List<FileEntry> entries) {
    final out = <PluginContribution>[];
    for (final c in _activeContributions) {
      if (c.menu != 'context') continue;
      if (!c.showsOn('selection')) continue;
      if (c.when.matches(entries, _isInArchive)) out.add(c);
    }
    return out;
  }

  List<PluginContribution> backgroundContributions() {
    return [
      for (final c in _activeContributions)
        if (c.menu == 'context' && c.showsOn('background')) c,
    ];
  }

  List<PluginContribution> menubarContributions() {
    return [
      for (final c in _activeContributions)
        if (c.menu == 'menubar') c,
    ];
  }

  List<PluginContribution> toolbarContributions() {
    return [
      for (final c in _activeContributions)
        if (c.menu == 'toolbar') c,
    ];
  }

  List<PluginContribution> shortcutContributions() {
    return [
      for (final c in _activeContributions)
        if (c.shortcut != null && c.shortcut!.trim().isNotEmpty) c,
    ];
  }

  List<PluginBarContribution> globalBarContributions() {
    return [
      for (final b in _activeBars)
        if (b.scope == 'global') b,
    ];
  }

  List<PluginBarContribution> paneBarContributions() {
    return [
      for (final b in _activeBars)
        if (b.scope == 'pane') b,
    ];
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
    Map<String, dynamic>? form,
  }) async {
    final ctx = <String, dynamic>{
      'paths': paths,
      'dir': dir,
      'plugin_dir': contribution.pluginDir,
      'settings': mergedSettings(contribution.pluginId),
    };
    if (form != null) ctx['form'] = form;
    final ctxJson = jsonEncode(ctx);
    final raw = await PluginFfi.invoke(
      initLuaPath: contribution.initLuaPath,
      actionId: contribution.actionId,
      ctxJson: ctxJson,
      perms: contribution.manifest.permsBitmask,
    );
    if (raw == null) {
      return [
        PluginEffect('error', {'message': 'native core unavailable'}),
      ];
    }
    return _parseEffectsResponse(raw);
  }

  Future<PluginBarInvokeResult> updateBar(
    PluginBarContribution bar, {
    required Map<String, dynamic> context,
  }) async {
    final ctx = _barContext(bar, context);
    final raw = await PluginFfi.barUpdate(
      initLuaPath: bar.initLuaPath,
      barId: bar.barId,
      ctxJson: jsonEncode(ctx),
      perms: bar.manifest.permsBitmask,
    );
    if (raw == null) {
      return PluginBarInvokeResult(
        state: PluginBarState.error('native core unavailable'),
        effects: const [],
      );
    }
    return _parseBarResponse(raw);
  }

  Future<PluginBarInvokeResult> clickBar(
    PluginBarContribution bar, {
    required String itemId,
    required Map<String, dynamic> context,
  }) async {
    final ctx = _barContext(bar, context);
    final raw = await PluginFfi.barClick(
      initLuaPath: bar.initLuaPath,
      barId: bar.barId,
      itemId: itemId,
      ctxJson: jsonEncode(ctx),
      perms: bar.manifest.permsBitmask,
    );
    if (raw == null) {
      return PluginBarInvokeResult(
        state: PluginBarState.error('native core unavailable'),
        effects: const [],
      );
    }
    return _parseBarResponse(raw);
  }

  Map<String, dynamic> _barContext(
    PluginBarContribution bar,
    Map<String, dynamic> context,
  ) {
    return {
      ...context,
      'plugin_dir': bar.pluginDir,
      'settings': mergedSettings(bar.pluginId),
    };
  }

  List<PluginEffect> _parseEffectsResponse(String raw) {
    try {
      final parsed = jsonDecode(raw) as Map<String, dynamic>;
      if (parsed['ok'] != true) {
        final message = parsed['error']?.toString() ?? 'unknown error';
        log.error('plugins', 'invoke failed: $message');
        return [
          PluginEffect('error', {'message': message}),
        ];
      }
      final effects = <PluginEffect>[];
      for (final e in (parsed['effects'] as List? ?? const [])) {
        final m = (e as Map).cast<String, dynamic>();
        effects.add(PluginEffect(m['type'] as String? ?? '', m));
      }
      return effects;
    } catch (e) {
      log.error('plugins', 'invoke parse: $e');
      return [
        PluginEffect('error', {'message': 'invalid plugin response'}),
      ];
    }
  }

  PluginBarInvokeResult _parseBarResponse(String raw) {
    try {
      final parsed = jsonDecode(raw) as Map<String, dynamic>;
      if (parsed['ok'] != true) {
        final message = parsed['error']?.toString() ?? 'unknown error';
        log.error('plugins', 'bar invoke failed: $message');
        return PluginBarInvokeResult(
          state: PluginBarState.error(message),
          effects: [
            PluginEffect('error', {'message': message}),
          ],
        );
      }
      final effects = <PluginEffect>[];
      for (final e in (parsed['effects'] as List? ?? const [])) {
        final m = (e as Map).cast<String, dynamic>();
        effects.add(PluginEffect(m['type'] as String? ?? '', m));
      }
      return PluginBarInvokeResult(
        state: parsed.containsKey('state')
            ? PluginBarState.fromJson(parsed['state'])
            : null,
        effects: effects,
      );
    } catch (e) {
      log.error('plugins', 'bar invoke parse: $e');
      return PluginBarInvokeResult(
        state: PluginBarState.error('invalid plugin response'),
        effects: [
          PluginEffect('error', {'message': 'invalid plugin response'}),
        ],
      );
    }
  }

  static bool _isInArchive(FileEntry e) =>
      FileSystemService.isInsideArchive(e.path);
}
