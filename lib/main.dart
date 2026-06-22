import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'ui/window/window.dart';
import 'app/app_info.dart';
import 'app/launch_args.dart';
import 'app/waydir_app.dart';
import 'core/fs/fs_backend.dart';
import 'core/fs/fs_worker_pool.dart';
import 'core/fs/local_fs.dart';
import 'core/fs/sftp_fs.dart';
import 'core/logging/app_logger.dart';
import 'core/settings/settings_store.dart';
import 'core/update/update_store.dart';
import 'features/navigation/sidebar_store.dart';
import 'features/plugins/plugin_settings_store.dart';
import 'features/plugins/plugin_store.dart';
import 'features/tags/tag_store.dart';
import 'i18n/strings.g.dart';
import 'ui/theme/app_theme_registry.dart';

void main(List<String> args) async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Waydir doesn't run inside the macOS App Sandbox, so file_picker's
      // sandbox-extension entitlement check is irrelevant and would
      // otherwise reject every pick with ENTITLEMENT_NOT_FOUND.
      await FilePicker.skipEntitlementsChecks();

      LaunchArgs.parse(args);
      if (LaunchArgs.options.showHelp) {
        stdout.writeln(LaunchArgs.helpText);
        exit(0);
      }

      await AppLogger.instance.init();

      FlutterError.onError = (details) {
        log.error('flutter', details.exceptionAsString(), stack: details.stack);
        FlutterError.presentError(details);
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        log.error('platform', '$error', stack: stack);

        return true;
      };

      LocaleSettings.useDeviceLocale();
      try {
        await initializeDateFormatting();
      } catch (e, st) {
        log.warn(
          'i18n',
          'date formatting initialization failed',
          error: e,
          stack: st,
        );
      }
      FsBackendRegistry.registerLocal(const LocalFs());
      FsBackendRegistry.register(const SftpFs());
      unawaited(FsWorkerPool.instance.ensureStarted());
      await AppThemeRegistry.instance.load();
      await SettingsStore.instance.load();
      await SidebarStore.instance.load();
      await PluginSettingsStore.instance.load(SettingsStore.instance.db);
      await TagStore.instance.load(SettingsStore.instance.db);
      await AppInfo.init();
      if (LaunchArgs.options.showVersion) {
        stdout.writeln('Waydir ${AppInfo.version.value}');
        exit(0);
      }
      const fakeVersion = String.fromEnvironment('WAYDIR_FAKE_VERSION');
      UpdateStore.init(
        currentVersion: fakeVersion.isNotEmpty
            ? fakeVersion
            : AppInfo.version.value,
      );
      unawaited(UpdateStore.instance.checkOnStartup());
      unawaited(PluginStore.instance.loadAll());
      runApp(TranslationProvider(child: const WaydirApp()));

      if (isWindowChromeSupported) {
        appWindow.minSize = const Size(700, 450);
        appWindow.size = const Size(1100, 700);
        appWindow.alignment = Alignment.center;
        appWindow.title = t.app.title;
        appWindow.show();
      }
    },
    (error, stack) {
      log.error('zone', '$error', stack: stack);
    },
  );
}
