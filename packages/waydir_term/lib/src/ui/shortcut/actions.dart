import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:waydir_term/src/terminal.dart';
import 'package:waydir_term/src/ui/controller.dart';
import 'package:waydir_term/src/ui/selection_mode.dart';

class TerminalActions extends StatelessWidget {
  const TerminalActions({
    super.key,
    required this.terminal,
    required this.controller,
    required this.child,
  });

  final Terminal terminal;

  final TerminalController controller;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: {
        PasteTextIntent: CallbackAction<PasteTextIntent>(
          onInvoke: (intent) async {
            final data = await Clipboard.getData(Clipboard.kTextPlain);
            final text = data?.text;
            if (text != null && text.isNotEmpty) {
              terminal.paste(text);
              controller.clearSelection();
            } else {
              terminal.charInput(0x76, ctrl: true);
            }
            return null;
          },
        ),
        CopySelectionTextIntent: CallbackAction<CopySelectionTextIntent>(
          onInvoke: (intent) async {
            final selection = controller.selection;

            if (selection == null) {
              return;
            }

            final text = terminal.buffer.getText(selection);

            await Clipboard.setData(ClipboardData(text: text));

            return null;
          },
        ),
        SelectAllTextIntent: CallbackAction<SelectAllTextIntent>(
          onInvoke: (intent) {
            controller.setSelection(
              terminal.buffer.createAnchor(
                0,
                terminal.buffer.height - terminal.viewHeight,
              ),
              terminal.buffer.createAnchor(
                terminal.viewWidth,
                terminal.buffer.height - 1,
              ),
              mode: SelectionMode.line,
            );
            return null;
          },
        ),
      },
      child: child,
    );
  }
}
