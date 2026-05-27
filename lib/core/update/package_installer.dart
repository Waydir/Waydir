import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../i18n/strings.g.dart';
import '../terminal/terminal.dart';
import 'install_format.dart';

class PackageInstaller {
  static Future<bool> install(File pkg, InstallFormat fmt) async {
    if (!Platform.isLinux) return false;
    if (fmt != InstallFormat.linuxDeb && fmt != InstallFormat.linuxRpm) {
      return false;
    }

    if (await _has('pkcon')) {
      final r = await Process.run('pkcon', [
        '-y',
        '--allow-untrusted',
        'install-local',
        pkg.path,
      ]);
      if (r.exitCode == 0) return true;
    }

    final script = await _writeScript(pkg, fmt);

    if (await _has('pkexec')) {
      try {
        final r = await Process.run('pkexec', [script.path]);
        if (r.exitCode == 0) return true;
        // pkexec exit 126 = user dismissed auth prompt; do not retry chain.
        if (r.exitCode == 126) return false;
      } catch (_) {}
    }

    if (await TerminalService.runScript(script.path)) return true;

    try {
      await Process.start('xdg-open', [
        pkg.path,
      ], mode: ProcessStartMode.detached);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<File> _writeScript(File pkg, InstallFormat fmt) async {
    final tmp = await getTemporaryDirectory();
    final script = File('${tmp.path}/waydir-install-$pid.sh');
    final body = await _scriptBody(pkg, fmt);
    script.writeAsStringSync(body);
    await Process.run('chmod', ['+x', script.path]);
    return script;
  }

  static Future<String> _scriptBody(File pkg, InstallFormat fmt) async {
    final path = _shellQuote(pkg.path);
    final hasSudo = await _has('sudo');
    final elevate = hasSudo ? 'sudo ' : '';
    final okMessage = _shellQuote(t.update.terminalInstallOk);
    final failedMessage = _shellDoubleQuote(
      t.update.terminalInstallFailed(status: r'$status'),
    );

    String inner;
    if (fmt == InstallFormat.linuxDeb) {
      // dpkg fails on missing deps; apt-get -f pulls them in.
      inner =
          '${elevate}dpkg -i $path || '
          '${elevate}apt-get install --fix-broken -y';
    } else if (await _has('dnf')) {
      inner = '${elevate}dnf install -y $path';
    } else if (await _has('zypper')) {
      inner =
          '${elevate}zypper --non-interactive install '
          '--allow-unsigned-rpm $path';
    } else {
      inner = '${elevate}rpm -U --force $path';
    }

    return '''
#!/bin/bash
$inner
status=\$?
if [ -t 0 ]; then
  echo
  if [ \$status -eq 0 ]; then
    echo $okMessage
  else
    echo $failedMessage
  fi
  read -r _
fi
exit \$status
''';
  }

  static String _shellQuote(String path) {
    final escaped = path.replaceAll("'", r"'\''");
    return "'$escaped'";
  }

  static String _shellDoubleQuote(String text) {
    final escaped = text
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('`', r'\`');
    return '"$escaped"';
  }

  static final _whichCache = <String, bool>{};

  static Future<bool> _has(String bin) async {
    final cached = _whichCache[bin];
    if (cached != null) return cached;
    try {
      final r = await Process.run('which', [bin]);
      final ok = r.exitCode == 0;
      _whichCache[bin] = ok;
      return ok;
    } catch (_) {
      _whichCache[bin] = false;
      return false;
    }
  }
}
