import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/open/desktop_entry.dart';

void main() {
  group('DesktopEntry.parse', () {
    test('parses the [Desktop Entry] group only', () {
      final e = DesktopEntry.parse('''
[Desktop Entry]
Type=Application
Name=Image Viewer
Name[de]=Bildbetrachter
Exec=eog %U
Icon=eog
MimeType=image/png;image/jpeg;
NoDisplay=false

[Desktop Action new-window]
Name=New Window
Exec=eog --new-window
''');
      expect(e, isNotNull);
      expect(e!.name, 'Image Viewer'); // locale-suffixed key ignored
      expect(e.exec, 'eog %U');
      expect(e.icon, 'eog');
      expect(e.mimeTypes, ['image/png', 'image/jpeg']);
      expect(e.isApplication, isTrue);
      expect(e.isLaunchable, isTrue);
    });

    test('honours Hidden and NoDisplay', () {
      final e = DesktopEntry.parse(
        '[Desktop Entry]\nType=Application\nName=X\nExec=x\nHidden=true\n',
      )!;
      expect(e.hidden, isTrue);
      expect(e.isLaunchable, isFalse);
    });

    test('returns null without a Desktop Entry group', () {
      expect(DesktopEntry.parse('# just a comment\n'), isNull);
    });
  });

  group('DesktopEntry.expandExec', () {
    test('substitutes single-file codes', () {
      expect(DesktopEntry.expandExec('eog %f', ['/tmp/a.png']), [
        'eog',
        '/tmp/a.png',
      ]);
      expect(DesktopEntry.expandExec('app %u', ['/tmp/a', '/tmp/b']), [
        'app',
        '/tmp/a',
      ]);
    });

    test('expands multi-file codes to every path', () {
      expect(DesktopEntry.expandExec('app %F', ['/a', '/b']), [
        'app',
        '/a',
        '/b',
      ]);
    });

    test('drops deprecated codes and unescapes %%', () {
      expect(DesktopEntry.expandExec('app %i %c 100%%', ['/a']), [
        'app',
        '100%',
      ]);
    });

    test('honours quoted arguments', () {
      expect(DesktopEntry.expandExec('"/opt/My App/bin" --flag %f', ['/a']), [
        '/opt/My App/bin',
        '--flag',
        '/a',
      ]);
    });

    test('no file codes means no path is appended', () {
      expect(DesktopEntry.expandExec('app --gui', []), ['app', '--gui']);
    });
  });
}
