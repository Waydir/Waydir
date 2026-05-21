import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/open/app_resolver.dart';

void main() {
  group('WindowsAppResolver command-template expansion', () {
    List<String> expand(String t, List<String> paths) =>
        WindowsAppResolver.debugExpandCommand(t, paths);

    test('substitutes %1 inside a quoted template', () {
      expect(
        expand(r'"C:\Program Files\App\app.exe" "%1"', [r'C:\a b\x.png']),
        [r'C:\Program Files\App\app.exe', r'C:\a b\x.png'],
      );
    });

    test('handles %L and %V the same as %1', () {
      expect(expand(r'C:\app.exe %L', [r'C:\x']), [r'C:\app.exe', r'C:\x']);
      expect(expand(r'C:\app.exe %V', [r'C:\x']), [r'C:\app.exe', r'C:\x']);
    });

    test('appends the path when the template has no placeholder', () {
      expect(expand(r'"C:\app.exe" --open', [r'C:\x']), [
        r'C:\app.exe',
        '--open',
        r'C:\x',
      ]);
    });
  });
}
