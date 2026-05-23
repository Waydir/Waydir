import 'dart:io';

class _TerminalSpec {
  final String id;
  final String displayName;
  final String executable;
  final List<String> Function(String directory) argsBuilder;
  final List<String> Function(String script)? execArgsBuilder;
  final bool useWorkingDirectory;

  const _TerminalSpec({
    required this.id,
    required this.displayName,
    required this.executable,
    required this.argsBuilder,
    this.execArgsBuilder,
    this.useWorkingDirectory = true,
  });
}

List<String> _execDashE(String s) => ['-e', s];
List<String> _execDashDash(String s) => ['--', s];
List<String> _execBare(String s) => [s];
List<String> _execWezterm(String s) => ['start', '--', s];
List<String> _execGnome(String s) => ['--', 'bash', s];
List<String> _execKonsole(String s) => ['-e', 'bash', s];

class _TerminalRegistry {
  static final List<_TerminalSpec> linux = [
    _TerminalSpec(
      id: 'x-terminal-emulator',
      displayName: 'Default Terminal',
      executable: 'x-terminal-emulator',
      argsBuilder: (_) => const [],
      execArgsBuilder: _execDashE,
    ),
    _TerminalSpec(
      id: 'kitty',
      displayName: 'Kitty',
      executable: 'kitty',
      argsBuilder: (_) => const [],
      execArgsBuilder: _execBare,
    ),
    _TerminalSpec(
      id: 'alacritty',
      displayName: 'Alacritty',
      executable: 'alacritty',
      argsBuilder: (_) => const [],
      execArgsBuilder: _execDashE,
    ),
    _TerminalSpec(
      id: 'wezterm',
      displayName: 'WezTerm',
      executable: 'wezterm',
      argsBuilder: (_) => const [],
      execArgsBuilder: _execWezterm,
    ),
    _TerminalSpec(
      id: 'foot',
      displayName: 'Foot',
      executable: 'foot',
      argsBuilder: (_) => const [],
      execArgsBuilder: _execDashE,
    ),
    _TerminalSpec(
      id: 'ghostty',
      displayName: 'Ghostty',
      executable: 'ghostty',
      argsBuilder: (_) => const [],
      execArgsBuilder: _execDashE,
    ),
    _TerminalSpec(
      id: 'rio',
      displayName: 'Rio',
      executable: 'rio',
      argsBuilder: (_) => const [],
      execArgsBuilder: _execDashE,
    ),
    _TerminalSpec(
      id: 'ptyxis',
      displayName: 'Ptyxis',
      executable: 'ptyxis',
      argsBuilder: (d) => ['--new-window', '--working-directory=$d'],
      execArgsBuilder: _execDashDash,
    ),
    _TerminalSpec(
      id: 'kgx',
      displayName: 'GNOME Console',
      executable: 'kgx',
      argsBuilder: (d) => ['--working-directory=$d'],
      execArgsBuilder: _execGnome,
    ),
    _TerminalSpec(
      id: 'gnome-terminal',
      displayName: 'GNOME Terminal',
      executable: 'gnome-terminal',
      argsBuilder: (d) => ['--working-directory=$d'],
      execArgsBuilder: _execGnome,
    ),
    _TerminalSpec(
      id: 'konsole',
      displayName: 'Konsole',
      executable: 'konsole',
      argsBuilder: (d) => ['--workdir', d],
      execArgsBuilder: _execKonsole,
    ),
    _TerminalSpec(
      id: 'yakuake',
      displayName: 'Yakuake',
      executable: 'yakuake',
      argsBuilder: (_) => const [],
    ),
    _TerminalSpec(
      id: 'deepin-terminal',
      displayName: 'Deepin Terminal',
      executable: 'deepin-terminal',
      argsBuilder: (d) => ['--work-directory', d],
      execArgsBuilder: _execDashE,
    ),
    _TerminalSpec(
      id: 'xfce4-terminal',
      displayName: 'Xfce Terminal',
      executable: 'xfce4-terminal',
      argsBuilder: (d) => ['--working-directory=$d'],
      execArgsBuilder: _execDashE,
    ),
    _TerminalSpec(
      id: 'mate-terminal',
      displayName: 'MATE Terminal',
      executable: 'mate-terminal',
      argsBuilder: (d) => ['--working-directory=$d'],
      execArgsBuilder: _execDashE,
    ),
    _TerminalSpec(
      id: 'lxterminal',
      displayName: 'LXTerminal',
      executable: 'lxterminal',
      argsBuilder: (d) => ['--working-directory=$d'],
      execArgsBuilder: _execDashE,
    ),
    _TerminalSpec(
      id: 'qterminal',
      displayName: 'QTerminal',
      executable: 'qterminal',
      argsBuilder: (d) => ['--workdir', d],
      execArgsBuilder: _execDashE,
    ),
    _TerminalSpec(
      id: 'terminator',
      displayName: 'Terminator',
      executable: 'terminator',
      argsBuilder: (d) => ['--working-directory=$d'],
      execArgsBuilder: _execDashE,
    ),
    _TerminalSpec(
      id: 'tilix',
      displayName: 'Tilix',
      executable: 'tilix',
      argsBuilder: (d) => ['--working-directory=$d'],
      execArgsBuilder: _execDashE,
    ),
    _TerminalSpec(
      id: 'terminology',
      displayName: 'Terminology',
      executable: 'terminology',
      argsBuilder: (d) => ['-d', d],
      execArgsBuilder: _execDashE,
    ),
    _TerminalSpec(
      id: 'sakura',
      displayName: 'Sakura',
      executable: 'sakura',
      argsBuilder: (_) => const [],
      execArgsBuilder: _execDashE,
    ),
    _TerminalSpec(
      id: 'roxterm',
      displayName: 'ROXTerm',
      executable: 'roxterm',
      argsBuilder: (d) => ['--directory=$d'],
      execArgsBuilder: _execDashE,
    ),
    _TerminalSpec(
      id: 'st',
      displayName: 'st',
      executable: 'st',
      argsBuilder: (_) => const [],
      execArgsBuilder: _execDashE,
    ),
    _TerminalSpec(
      id: 'urxvt',
      displayName: 'urxvt',
      executable: 'urxvt',
      argsBuilder: (_) => const [],
      execArgsBuilder: _execDashE,
    ),
    _TerminalSpec(
      id: 'xterm',
      displayName: 'Xterm',
      executable: 'xterm',
      argsBuilder: (_) => const [],
      execArgsBuilder: _execDashE,
    ),
  ];

  static final List<_TerminalSpec> macos = [
    _TerminalSpec(
      id: 'iterm',
      displayName: 'iTerm',
      executable: 'open',
      argsBuilder: (d) => ['-a', 'iTerm', d],
      useWorkingDirectory: false,
    ),
    _TerminalSpec(
      id: 'warp',
      displayName: 'Warp',
      executable: 'open',
      argsBuilder: (d) => ['-a', 'Warp', d],
      useWorkingDirectory: false,
    ),
    _TerminalSpec(
      id: 'alacritty',
      displayName: 'Alacritty',
      executable: 'open',
      argsBuilder: (d) => ['-a', 'Alacritty', d],
      useWorkingDirectory: false,
    ),
    _TerminalSpec(
      id: 'kitty',
      displayName: 'Kitty',
      executable: 'open',
      argsBuilder: (d) => ['-a', 'kitty', d],
      useWorkingDirectory: false,
    ),
    _TerminalSpec(
      id: 'ghostty',
      displayName: 'Ghostty',
      executable: 'open',
      argsBuilder: (d) => ['-a', 'Ghostty', d],
      useWorkingDirectory: false,
    ),
    _TerminalSpec(
      id: 'terminal',
      displayName: 'Terminal',
      executable: 'open',
      argsBuilder: (d) => ['-a', 'Terminal', d],
      useWorkingDirectory: false,
    ),
  ];

  static final List<_TerminalSpec> windows = [
    _TerminalSpec(
      id: 'wt',
      displayName: 'Windows Terminal',
      executable: 'wt',
      argsBuilder: (d) => ['-d', d],
    ),
    _TerminalSpec(
      id: 'powershell',
      displayName: 'PowerShell',
      executable: 'powershell',
      argsBuilder: (d) => [
        '-NoExit',
        '-Command',
        'Set-Location -LiteralPath "$d"',
      ],
    ),
    _TerminalSpec(
      id: 'cmd',
      displayName: 'Command Prompt',
      executable: 'cmd',
      argsBuilder: (d) => ['/k', 'cd', '/d', d],
    ),
  ];

  static List<_TerminalSpec> all() {
    if (Platform.isLinux) return linux;
    if (Platform.isMacOS) return macos;
    if (Platform.isWindows) return windows;
    return const [];
  }

  static _TerminalSpec? byId(String id) {
    for (final t in all()) {
      if (t.id == id) return t;
    }
    return null;
  }
}

class TerminalService {
  static final _detectionCache = <String, bool>{};

  static Future<bool> _isAvailable(String executable) async {
    final cached = _detectionCache[executable];
    if (cached != null) return cached;
    final result = await _which(executable);
    _detectionCache[executable] = result;
    return result;
  }

  static Future<bool> _which(String executable) async {
    try {
      final cmd = Platform.isWindows ? 'where' : 'which';
      final result = await Process.run(cmd, [executable], runInShell: true);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _launch(_TerminalSpec spec, String directory) async {
    try {
      await Process.start(
        spec.executable,
        spec.argsBuilder(directory),
        workingDirectory: spec.useWorkingDirectory ? directory : null,
        mode: ProcessStartMode.detached,
        runInShell: Platform.isWindows,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openInDirectory(
    String directory, {
    String? preferredId,
    String? customCommand,
  }) async {
    if (preferredId == 'custom' &&
        customCommand != null &&
        customCommand.trim().isNotEmpty) {
      if (await _launchCustom(customCommand, directory)) return;
    }
    if (preferredId != null &&
        preferredId != 'auto' &&
        preferredId != 'custom') {
      final spec = _TerminalRegistry.byId(preferredId);
      if (spec != null && await _launch(spec, directory)) return;
    }
    for (final spec in _TerminalRegistry.all()) {
      if (Platform.isLinux || Platform.isWindows) {
        if (!await _isAvailable(spec.executable)) continue;
      }
      if (await _launch(spec, directory)) return;
    }
  }

  static Future<bool> _launchCustom(String command, String directory) async {
    try {
      final expanded = command.replaceAll(r'{dir}', directory);
      final parts = _tokenize(expanded);
      if (parts.isEmpty) return false;
      await Process.start(
        parts.first,
        parts.sublist(1),
        workingDirectory: directory,
        mode: ProcessStartMode.detached,
        runInShell: Platform.isWindows,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> runScript(String scriptPath) async {
    if (!Platform.isLinux) return false;
    for (final spec in _TerminalRegistry.linux) {
      final builder = spec.execArgsBuilder;
      if (builder == null) continue;
      if (!await _isAvailable(spec.executable)) continue;
      try {
        await Process.start(
          spec.executable,
          builder(scriptPath),
          mode: ProcessStartMode.detached,
        );
        return true;
      } catch (_) {}
    }
    return false;
  }

  static List<String> _tokenize(String input) {
    final tokens = <String>[];
    final buf = StringBuffer();
    String? quote;
    for (int i = 0; i < input.length; i++) {
      final c = input[i];
      if (quote != null) {
        if (c == quote) {
          quote = null;
        } else {
          buf.write(c);
        }
      } else if (c == '"' || c == "'") {
        quote = c;
      } else if (c == ' ' || c == '\t') {
        if (buf.isNotEmpty) {
          tokens.add(buf.toString());
          buf.clear();
        }
      } else {
        buf.write(c);
      }
    }
    if (buf.isNotEmpty) tokens.add(buf.toString());
    return tokens;
  }
}
