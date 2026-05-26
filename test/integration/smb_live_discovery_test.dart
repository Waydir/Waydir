@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/fs/smb_share_discovery.dart';
import 'package:waydir/core/platform/platform_paths.dart';
import 'package:waydir/features/locations/location_resolver.dart';

void main() {
  group('live SMB discovery against podman container on 127.0.0.1:1445', () {
    setUp(SmbShareDiscovery.invalidateAll);

    test('anonymous discovery lists public/media/backup', () async {
      final r = await SmbShareDiscovery.list(host: '127.0.0.1', port: 1445);
      expect(r, isA<SmbShareListOk>());
      final names = (r as SmbShareListOk).shares.map((s) => s.name).toList();
      expect(names, containsAll(['public', 'media', 'backup']));
      expect(names, isNot(contains('IPC\$')));
    });

    test('bad host returns error not crash', () async {
      final r = await SmbShareDiscovery.list(host: 'nonexistent.invalid');
      expect(r, isA<SmbShareListError>());
    });

    test('refused port returns error not crash', () async {
      final r = await SmbShareDiscovery.list(host: '127.0.0.1', port: 9);
      expect(r, isA<SmbShareListError>());
    });

    test('cache returns same data on second call', () async {
      final a = await SmbShareDiscovery.list(host: '127.0.0.1', port: 1445);
      final b = await SmbShareDiscovery.list(host: '127.0.0.1', port: 1445);
      expect(a, isA<SmbShareListOk>());
      expect(b, isA<SmbShareListOk>());
      expect(
        (a as SmbShareListOk).shares.map((s) => s.name),
        (b as SmbShareListOk).shares.map((s) => s.name),
      );
    });

    test('with bogus creds still resolves (guest fallback or auth error)',
        () async {
      final r = await SmbShareDiscovery.list(
        host: '127.0.0.1',
        port: 1445,
        credentials: const SmbCredentials(
          username: 'wronguser',
          password: 'wrongpass',
        ),
      );
      expect(r, anyOf(isA<SmbShareListOk>(), isA<SmbShareListError>()));
    });
  });

  group('PlatformPaths SMB segmentation', () {
    test('smb://host has one segment', () {
      expect(PlatformPaths.segments('smb://127.0.0.1:1445'),
          ['smb://127.0.0.1:1445']);
    });

    test('smb://host/share splits host and share', () {
      expect(PlatformPaths.segments('smb://127.0.0.1:1445/public'),
          ['smb://127.0.0.1:1445', 'public']);
    });

    test('smb://host/share/sub splits all three', () {
      expect(PlatformPaths.segments('smb://h/share/sub'),
          ['smb://h', 'share', 'sub']);
    });

    test('parentOf walks back through share to host', () {
      expect(PlatformPaths.parentOf('smb://h/share/folder'), 'smb://h/share');
      expect(PlatformPaths.parentOf('smb://h/share'), 'smb://h');
      expect(PlatformPaths.parentOf('smb://h'), 'smb://h');
    });
  });
}
