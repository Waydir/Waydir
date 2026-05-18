import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/app_info.dart';
import 'app/waydir_app.dart';
import 'core/fs/fs_worker_pool.dart';
import 'core/logging/app_logger.dart';
import 'core/settings/settings_store.dart';
import 'i18n/strings.g.dart';
import 'ui/theme/app_theme_registry.dart';

void main(List<String> args) async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

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
      } catch (_) {}
      unawaited(FsWorkerPool.instance.ensureStarted());
      await AppThemeRegistry.instance.load();
      await SettingsStore.instance.load();
      await AppInfo.init();
      runApp(TranslationProvider(child: const WaydirApp()));

      doWhenWindowReady(() {
        appWindow.minSize = const Size(700, 450);
        appWindow.size = const Size(1100, 700);
        appWindow.alignment = Alignment.center;
        appWindow.title = '';
        appWindow.show();
      });
    },
    (error, stack) {
      log.error('zone', '$error', stack: stack);
    },
  );
}
