import 'package:package_info_plus/package_info_plus.dart';
import 'package:signals/signals.dart';

class AppInfo {
  static const String repository = 'Waydir/Waydir';
  static const String homepage = 'https://github.com/Waydir/Waydir';
  static const String license = 'MIT';
  static const String iconAsset = 'assets/app_icon.png';

  static final version = signal<String>('…');
  static final Computed<String> versionLabel = computed(
    () => 'v${version.value}',
  );

  static Future<void> init() async {
    final info = await PackageInfo.fromPlatform();
    version.value = info.version;
  }

  const AppInfo._();
}
