import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/features/locations/location_uri.dart';

void main() {
  group('LocationUri', () {
    test('parses smb uri with host, port, share, and path', () {
      final uri = LocationUri.parse('smb://server.local:1445/share/dir/file');

      expect(uri.scheme, LocationScheme.smb);
      expect(uri.host, 'server.local');
      expect(uri.port, 1445);
      expect(uri.share, 'share');
      expect(uri.path, 'dir/file');
      expect(uri.displayLabel, 'server.local/share/dir/file');
    });

    test('converts smb uri to windows unc without a port', () {
      final uri = LocationUri.parse('smb://server/share/dir/file');

      expect(uri.toWindowsUnc(), r'\\server\share\dir\file');
    });

    test('converts windows unc path to smb uri', () {
      final uri = LocationUri.parse(r'\\server\share\dir\file');

      expect(uri.scheme, LocationScheme.windowsUnc);
      expect(uri.toSmbUri(), 'smb://server/share/dir/file');
    });
  });
}
