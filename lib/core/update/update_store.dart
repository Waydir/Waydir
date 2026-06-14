import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:signals/signals.dart';

import '../fs/checksum_service.dart';
import '../logging/app_logger.dart';
import 'github_releases.dart';
import 'install_format.dart';
import '../../i18n/strings.g.dart';
import 'swap_installer.dart';

enum UpdateStatus {
  idle,
  checking,
  upToDate,
  available,
  downloading,
  ready,
  launching,
  error,
}

class UpdateStore {
  static const _owner = 'Waydir';
  static const _repo = 'Waydir';
  static const _cacheTtl = Duration(hours: 1);

  static UpdateStore? _instance;
  static UpdateStore get instance {
    final i = _instance;
    if (i == null) {
      throw StateError('UpdateStore.init() must be called before instance');
    }
    return i;
  }

  static void init({required String currentVersion}) {
    _instance = UpdateStore(currentVersion: currentVersion);
  }

  final String currentVersion;
  final GithubReleasesClient _gh;
  final Future<Directory> Function() _temporaryDirectory;
  final http.Client Function() _downloadClientFactory;

  final status = signal<UpdateStatus>(UpdateStatus.idle);
  final latestRelease = signal<GithubRelease?>(null);
  final selectedAsset = signal<GithubAsset?>(null);
  final installFormat = signal<InstallFormat?>(null);
  final progress = signal<double>(0);
  final downloadedBytes = signal<int>(0);
  final totalBytes = signal<int>(0);
  final downloadedFile = signal<File?>(null);
  final errorMessage = signal<String?>(null);

  DateTime? _lastCheckedAt;
  http.Client? _downloadClient;

  late final updateAvailable = computed(() {
    final r = latestRelease.value;
    if (r == null) return false;
    return _isNewer(r.version, currentVersion);
  });

  UpdateStore({
    required this.currentVersion,
    GithubReleasesClient? client,
    Future<Directory> Function()? temporaryDirectory,
    http.Client Function()? downloadClientFactory,
  }) : _gh = client ?? GithubReleasesClient(owner: _owner, repo: _repo),
       _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory,
       _downloadClientFactory = downloadClientFactory ?? http.Client.new;

  static bool canSelfInstall(InstallFormat? fmt) =>
      fmt != null &&
      fmt != InstallFormat.linuxDeb &&
      fmt != InstallFormat.linuxRpm &&
      fmt != InstallFormat.linuxAppImage &&
      fmt != InstallFormat.unknown;

  Future<void> checkOnStartup() async {
    await Future.delayed(const Duration(seconds: 4));
    await check(force: false);
  }

  Future<void> check({bool force = true}) async {
    if (status.value == UpdateStatus.checking ||
        status.value == UpdateStatus.downloading) {
      return;
    }
    if (!force && _lastCheckedAt != null) {
      if (DateTime.now().difference(_lastCheckedAt!) < _cacheTtl) return;
    }
    status.value = UpdateStatus.checking;
    errorMessage.value = null;
    try {
      final release = await _gh.latestStable();
      _lastCheckedAt = DateTime.now();
      latestRelease.value = release;
      if (release == null) {
        status.value = UpdateStatus.upToDate;
        return;
      }
      if (_isNewer(release.version, currentVersion)) {
        final fmt = await InstallFormatDetector.detect();
        installFormat.value = fmt;
        selectedAsset.value = _pickAsset(release.assets, fmt);
        status.value = UpdateStatus.available;
      } else {
        status.value = UpdateStatus.upToDate;
      }
    } catch (e) {
      errorMessage.value = e.toString();
      status.value = UpdateStatus.error;
    }
  }

  Future<void> download() async {
    final asset = selectedAsset.value;
    if (asset == null) {
      errorMessage.value = t.update.noMatch;
      status.value = UpdateStatus.error;
      return;
    }
    status.value = UpdateStatus.downloading;
    progress.value = 0;
    downloadedBytes.value = 0;
    totalBytes.value = asset.sizeBytes;
    errorMessage.value = null;

    _downloadClient = _downloadClientFactory();
    File? outFile;
    try {
      final req = http.Request('GET', Uri.parse(asset.downloadUrl));
      final res = await _downloadClient!.send(req);
      if (res.statusCode != 200) {
        throw HttpException(
          t.update.downloadFailed(statusCode: res.statusCode),
          uri: req.url,
        );
      }
      final total = res.contentLength ?? asset.sizeBytes;
      totalBytes.value = total;

      final dir = await _temporaryDirectory();
      final outDir = Directory('${dir.path}/waydir-update');
      if (outDir.existsSync()) {
        try {
          outDir.deleteSync(recursive: true);
        } catch (e, st) {
          log.warn(
            'update',
            'failed to clear update cache',
            error: e,
            stack: st,
          );
        }
      }
      outDir.createSync(recursive: true);
      outFile = File('${outDir.path}/${asset.name}');
      final sink = outFile.openWrite();

      int received = 0;
      await for (final chunk in res.stream) {
        sink.add(chunk);
        received += chunk.length;
        downloadedBytes.value = received;
        if (total > 0) progress.value = received / total;
      }
      await sink.flush();
      await sink.close();

      await _verifyAssetDigest(asset, outFile);

      downloadedFile.value = outFile;
      progress.value = 1;
      status.value = UpdateStatus.ready;
    } catch (e) {
      downloadedFile.value = null;
      try {
        if (outFile != null && outFile.existsSync()) outFile.deleteSync();
      } catch (cleanupError, cleanupStack) {
        log.warn(
          'update',
          'failed to remove invalid update download',
          error: cleanupError,
          stack: cleanupStack,
        );
      }
      errorMessage.value = e.toString();
      status.value = UpdateStatus.error;
    } finally {
      _downloadClient?.close();
      _downloadClient = null;
    }
  }

  Future<bool> launchInstaller() async {
    final file = downloadedFile.value;
    final asset = selectedAsset.value;
    final fmt = installFormat.value;
    if (file == null || asset == null || fmt == null) return false;
    status.value = UpdateStatus.launching;
    try {
      await _verifyAssetDigest(asset, file);
      switch (fmt) {
        case InstallFormat.linuxPortable:
          final ok = await SwapInstaller.installLinuxPortable(file);
          if (!ok) {
            errorMessage.value = t.update.bundleNotWritable;
            status.value = UpdateStatus.error;
            return false;
          }
          return true;
        case InstallFormat.windowsInstaller:
          await Process.start(
            file.path,
            const [],
            mode: ProcessStartMode.detached,
          );
          return true;
        case InstallFormat.windowsPortable:
          final ok = await SwapInstaller.installWindowsPortable(file);
          if (!ok) {
            errorMessage.value = t.update.bundleNotWritable;
            status.value = UpdateStatus.error;
            return false;
          }
          return true;
        case InstallFormat.macDmg:
          await Process.start('open', [
            file.path,
          ], mode: ProcessStartMode.detached);
          return true;
        case InstallFormat.linuxDeb:
        case InstallFormat.linuxRpm:
        case InstallFormat.linuxAppImage:
        case InstallFormat.unknown:
          return false;
      }
    } catch (e) {
      errorMessage.value = t.update.installerLaunchFailed(error: e);
      status.value = UpdateStatus.error;
      return false;
    }
  }

  static Future<void> _verifyAssetDigest(GithubAsset asset, File file) async {
    final expected = _sha256FromAssetDigest(asset.digest);
    if (expected == null) {
      throw UpdateIntegrityException(
        t.update.missingChecksum(asset: asset.name),
      );
    }
    final actual = await ChecksumService.calculate(
      file.path,
      ChecksumAlgorithm.sha256,
    );
    if (!ChecksumService.matches(
      algorithm: ChecksumAlgorithm.sha256,
      expected: expected,
      actual: actual.digest,
    )) {
      throw UpdateIntegrityException(
        t.update.checksumMismatch(asset: asset.name),
      );
    }
  }

  static String? _sha256FromAssetDigest(String value) {
    final digest = value.trim().toLowerCase();
    const prefix = 'sha256:';
    if (!digest.startsWith(prefix)) return null;
    final expected = digest.substring(prefix.length);
    if (!ChecksumService.isExpectedFormatValid(
      ChecksumAlgorithm.sha256,
      expected,
    )) {
      return null;
    }
    return expected;
  }

  void openReleasePage() {
    final url = latestRelease.value?.htmlUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return;
    }
    final cmd = Platform.isWindows
        ? 'explorer'
        : Platform.isMacOS
        ? 'open'
        : 'xdg-open';
    Process.start(cmd, [uri.toString()], mode: ProcessStartMode.detached);
  }

  void reset() {
    progress.value = 0;
    downloadedBytes.value = 0;
    totalBytes.value = 0;
    downloadedFile.value = null;
    errorMessage.value = null;
    if (updateAvailable.value) {
      status.value = UpdateStatus.available;
    } else {
      status.value = UpdateStatus.idle;
    }
  }

  void dispose() {
    _downloadClient?.close();
    _gh.dispose();
  }

  static GithubAsset? _pickAsset(List<GithubAsset> assets, InstallFormat fmt) {
    GithubAsset? match(bool Function(String name) test) {
      for (final a in assets) {
        if (test(a.name.toLowerCase())) return a;
      }
      return null;
    }

    switch (fmt) {
      case InstallFormat.linuxDeb:
        return match((n) => n.endsWith('.deb')) ??
            match((n) => n.endsWith('.tar.gz') && n.contains('linux'));
      case InstallFormat.linuxRpm:
        return match((n) => n.endsWith('.rpm')) ??
            match((n) => n.endsWith('.tar.gz') && n.contains('linux'));
      case InstallFormat.linuxAppImage:
        return match((n) => n.endsWith('.appimage'));
      case InstallFormat.linuxPortable:
        return match((n) => n.endsWith('.tar.gz') && n.contains('linux'));
      case InstallFormat.windowsInstaller:
        return match((n) => n.endsWith('.exe')) ??
            match((n) => n.endsWith('.zip') && n.contains('windows'));
      case InstallFormat.windowsPortable:
        return match((n) => n.endsWith('.zip') && n.contains('windows'));
      case InstallFormat.macDmg:
        return match((n) => n.endsWith('.dmg'));
      case InstallFormat.unknown:
        return null;
    }
  }

  static bool _isNewer(String candidate, String current) {
    final a = _parseVersion(candidate);
    final b = _parseVersion(current);
    for (var i = 0; i < 3; i++) {
      if (a.parts[i] > b.parts[i]) return true;
      if (a.parts[i] < b.parts[i]) return false;
    }
    // Equal core: stable > prerelease.
    if (a.pre == null && b.pre != null) return true;
    if (a.pre != null && b.pre == null) return false;
    if (a.pre != null && b.pre != null) {
      return a.pre!.compareTo(b.pre!) > 0;
    }
    return false;
  }

  static _Version _parseVersion(String v) {
    final noBuild = v.split('+').first;
    final dash = noBuild.indexOf('-');
    final core = dash < 0 ? noBuild : noBuild.substring(0, dash);
    final pre = dash < 0 ? null : noBuild.substring(dash + 1);
    final parts = core.split('.');
    return _Version([
      for (var i = 0; i < 3; i++)
        i < parts.length ? (int.tryParse(parts[i]) ?? 0) : 0,
    ], pre);
  }
}

class _Version {
  final List<int> parts;
  final String? pre;
  _Version(this.parts, this.pre);
}

class UpdateIntegrityException implements Exception {
  final String message;

  UpdateIntegrityException(this.message);

  @override
  String toString() => message;
}
