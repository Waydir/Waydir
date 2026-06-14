import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:waydir/core/update/github_releases.dart';
import 'package:waydir/core/update/install_format.dart';
import 'package:waydir/core/update/update_store.dart';

void main() {
  group('GithubAsset', () {
    test('parses release asset digest', () {
      final asset = GithubAsset.fromJson({
        'name': 'waydir.zip',
        'browser_download_url': 'https://example.invalid/waydir.zip',
        'size': 7,
        'digest':
            'sha256:fee49e636dec6a20f3705578d7b0c19ad7baec1e5ea4f18ce17b30cc8b0a0902',
      });

      expect(
        asset.digest,
        'sha256:fee49e636dec6a20f3705578d7b0c19ad7baec1e5ea4f18ce17b30cc8b0a0902',
      );
    });
  });

  group('UpdateStore download integrity', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('waydir_update_test');
    });

    tearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('accepts a download with matching SHA-256 digest', () async {
      final store = _store(
        dir,
        responseBody: 'Waydir\n',
        digest:
            'sha256:fee49e636dec6a20f3705578d7b0c19ad7baec1e5ea4f18ce17b30cc8b0a0902',
      );
      addTearDown(store.dispose);

      await store.download();

      expect(store.status.value, UpdateStatus.ready);
      expect(store.errorMessage.value, isNull);
      expect(store.downloadedFile.value, isNotNull);
      expect(await store.downloadedFile.value!.readAsString(), 'Waydir\n');
    });

    test('rejects a download without a valid digest', () async {
      final store = _store(dir, responseBody: 'Waydir\n', digest: '');
      addTearDown(store.dispose);

      await store.download();

      expect(store.status.value, UpdateStatus.error);
      expect(store.downloadedFile.value, isNull);
      expect(store.errorMessage.value, contains('valid SHA-256 checksum'));
    });

    test('rejects launch when the downloaded file is modified', () async {
      final store = _store(
        dir,
        responseBody: 'Waydir\n',
        digest:
            'sha256:fee49e636dec6a20f3705578d7b0c19ad7baec1e5ea4f18ce17b30cc8b0a0902',
      );
      addTearDown(store.dispose);

      await store.download();
      await store.downloadedFile.value!.writeAsString('tampered');
      store.installFormat.value = InstallFormat.unknown;

      final launched = await store.launchInstaller();

      expect(launched, isFalse);
      expect(store.status.value, UpdateStatus.error);
      expect(store.errorMessage.value, contains('SHA-256 verification'));
    });
  });
}

UpdateStore _store(
  Directory dir, {
  required String responseBody,
  required String digest,
}) {
  final store = UpdateStore(
    currentVersion: '0.0.0',
    temporaryDirectory: () async => dir,
    downloadClientFactory: () =>
        MockClient((request) async => http.Response(responseBody, 200)),
  );
  store.selectedAsset.value = GithubAsset(
    name: 'waydir.zip',
    downloadUrl: 'https://example.invalid/waydir.zip',
    sizeBytes: responseBody.length,
    digest: digest,
  );
  store.installFormat.value = InstallFormat.windowsPortable;
  return store;
}
