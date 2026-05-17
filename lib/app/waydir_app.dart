import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:signals/signals_flutter.dart';
import '../core/settings/settings_store.dart';
import '../i18n/strings.g.dart';
import '../ui/theme/app_theme.dart';
import 'waydir_page.dart';

final waydirNavigatorKey = GlobalKey<NavigatorState>();

class WaydirApp extends StatefulWidget {
  const WaydirApp({super.key});

  @override
  State<WaydirApp> createState() => _WaydirAppState();
}

class _WaydirAppState extends State<WaydirApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    setState(() {});
  }

  Brightness _resolve(String mode) {
    switch (mode) {
      case 'light':
        return Brightness.light;
      case 'dark':
        return Brightness.dark;
      default:
        return SchedulerBinding.instance.platformDispatcher.platformBrightness;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final brightness = _resolve(SettingsStore.instance.themeMode.value);
      AppColors.brightness = brightness;
      return MaterialApp(
        key: ValueKey(brightness),
        title: t.app.title,
        navigatorKey: waydirNavigatorKey,
        locale: TranslationProvider.of(context).flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(brightness),
        home: const WaydirPage(),
      );
    });
  }
}
