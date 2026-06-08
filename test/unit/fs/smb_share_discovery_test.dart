import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/fs/smb_share_discovery.dart';

void main() {
  group('SmbShareDiscovery.parseSmbclientGrepable', () {
    test('parses disk shares and drops admin shares', () {
      const text = '''
Disk|public|Public files
Disk|media|
Disk|IPC\$|IPC Service
Disk|C\$|Default share
Printer|HP1|Office printer
Disk|backup|Daily backups
''';
      final shares = SmbShareDiscovery.parseSmbclientGrepable(text);
      expect(shares.map((s) => s.name), ['public', 'media', 'backup']);
      expect(shares[0].comment, 'Public files');
      expect(shares[1].comment, isNull);
      expect(shares[2].comment, 'Daily backups');
    });

    test('handles empty input', () {
      expect(SmbShareDiscovery.parseSmbclientGrepable(''), isEmpty);
    });

    test('ignores non-Disk lines', () {
      const text = '''
Workgroup|WORKGROUP|
Server|nas1|My NAS
Disk|share1|
''';
      final shares = SmbShareDiscovery.parseSmbclientGrepable(text);
      expect(shares.map((s) => s.name), ['share1']);
    });
  });

  group('SmbShareDiscovery.parseSmbutil', () {
    test('parses macOS smbutil view output', () {
      const text = '''
Share          Type    Comment
-------------------------------
public         Disk    Public files
media          Disk
IPC\$           Pipe
admin\$         Disk    Admin
''';
      final shares = SmbShareDiscovery.parseSmbutil(text);
      expect(shares.map((s) => s.name), ['public', 'media']);
      expect(shares[0].comment, 'Public files');
      expect(shares[1].comment, isNull);
    });
  });

  group('SmbShareDiscovery.parseNetView', () {
    test('parses Windows net view output', () {
      const text = '''
Shared resources at \\\\nas1

Share name   Type   Used as   Comment
-------------------------------------
public       Disk             Public files
media        Disk
IPC\$         IPC              Remote IPC
The command completed successfully.
''';
      final shares = SmbShareDiscovery.parseNetView(text);
      expect(shares.map((s) => s.name), ['public', 'media']);
      expect(shares[0].comment, 'Public files');
    });

    test('parses localized net view output (no English "Disk")', () {
      const text = '''
Zasoby udostępnione w \\\\nas1

Nazwa udziału   Typ    Używane jako   Komentarz
-------------------------------------------------
public          Dysk                  Pliki publiczne
media           Dysk
IPC\$            IPC                   Zdalne IPC
Polecenie zostało wykonane pomyślnie.
''';
      final shares = SmbShareDiscovery.parseNetView(text);
      expect(shares.map((s) => s.name), ['public', 'media']);
      expect(shares[0].comment, 'Pliki publiczne');
    });
  });
}
