import 'package:flutter_test/flutter_test.dart';
import 'package:waydir_term/xterm.dart';

void expectNoHoles(Terminal terminal) {
  final lines = terminal.buffer.lines;
  for (var i = 0; i < lines.length; i++) {
    // `lines[i]` throws if the slot is null (the paint crash). Every line in
    // the window must also be attached — a detached line aliased into the
    // window is the corruption that later nulls a slot and trips `_move`.
    expect(lines[i].attached, isTrue, reason: 'detached/hole at line $i');
  }
}

void main() {
  group('Terminal alt-buffer scrolling (codex-style TUI)', () {
    test(
      'heavy scrolling in a scroll region leaves no null/detached lines',
      () {
        final terminal = Terminal(maxLines: 200);
        terminal.resize(80, 24);

        // Enter alternate screen (DECSET 1049) like a full-screen TUI.
        terminal.write('\x1b[?1049h');
        // Set a scroll region (DECSTBM) rows 2..23.
        terminal.write('\x1b[2;23r');

        // Hammer the scroll region: cursor to bottom, emit many line feeds,
        // plus interleaved insert/delete-line sequences.
        for (var i = 0; i < 500; i++) {
          terminal.write('\x1b[23;1H'); // cursor to bottom of region
          terminal.write('line $i\n');
          if (i % 7 == 0) terminal.write('\x1b[2L'); // insert lines
          if (i % 11 == 0) terminal.write('\x1b[1M'); // delete line
          expectNoHoles(terminal);
        }

        // Resize a few times while in the alt buffer.
        for (final h in [30, 18, 24, 40, 12]) {
          terminal.resize(100, h);
          terminal.write('after resize\n');
          expectNoHoles(terminal);
        }

        // Back to the main screen.
        terminal.write('\x1b[?1049l');
        expectNoHoles(terminal);
      },
    );
  });
}
