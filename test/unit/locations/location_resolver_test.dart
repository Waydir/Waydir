import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:waydir/features/locations/location_resolver.dart';

void main() {
  group('LocationResolver mappings', () {
    late Directory temp;

    setUp(() {
      temp = Directory.systemTemp.createTempSync('waydir-location-resolver-');
      LocationResolver.debugClearMappingsForTests();
    });

    tearDown(() {
      LocationResolver.debugClearMappingsForTests();
      if (temp.existsSync()) temp.deleteSync(recursive: true);
    });

    test('maps logical smb paths to physical mount paths', () {
      LocationResolver.debugSetMappingForTests('smb://server/share', temp.path);

      expect(
        LocationResolver.logicalToPhysical('smb://server/share/dir/file.txt'),
        p.join(temp.path, 'dir', 'file.txt'),
      );
    });

    test('maps physical mount paths back to logical smb paths', () {
      LocationResolver.debugSetMappingForTests('smb://server/share', temp.path);

      expect(
        LocationResolver.physicalToLogical(
          p.join(temp.path, 'dir', 'file.txt'),
        ),
        'smb://server/share/dir/file.txt',
      );
    });

    test('drops stale mappings when the mount root disappears', () {
      LocationResolver.debugSetMappingForTests('smb://server/share', temp.path);
      temp.deleteSync(recursive: true);

      expect(LocationResolver.logicalToPhysical('smb://server/share'), isNull);
      expect(LocationResolver.debugMappings, isEmpty);
    });

    test('normalizes gvfs smb mountpoint paths to smb uris', () {
      final physical = p.join(
        '/run/user/1000/gvfs',
        'smb-share:server=nas,share=media,port=1445',
        'Movies',
        'clip.mkv',
      );

      expect(
        LocationResolver.physicalToLogical(physical),
        'smb://nas:1445/media/Movies/clip.mkv',
      );
    });
  });
}
