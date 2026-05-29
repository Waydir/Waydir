import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:signals/signals_flutter.dart';
import '../core/settings/settings_store.dart';
import '../i18n/strings.g.dart';
import '../ui/theme/app_theme.dart';
import '../ui/theme/app_theme_registry.dart';
import 'waydir_shell.dart';

final waydirNavigatorKey = GlobalKey<NavigatorState>();

class WaydirApp extends StatefulWidget {
  const WaydirApp({super.key});

  @override
  State<WaydirApp> createState() => _WaydirAppState();
}

class _WaydirAppState extends State<WaydirApp> {
  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final themeId = SettingsStore.instance.themeId.value;
        AppThemeRegistry.instance.loadSync();
        final theme = AppThemeRegistry.instance.resolve(themeId);
        AppColors.setTheme(theme);
        return MaterialApp(
          key: ValueKey(theme.id),
          title: t.app.title,
          navigatorKey: waydirNavigatorKey,
          locale: TranslationProvider.of(context).flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(theme),
          home: const WaydirShell(),
        );
      },
    );
  }
}
