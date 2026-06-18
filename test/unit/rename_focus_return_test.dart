import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/models/file_entry.dart';
import 'package:waydir/features/files/file_view.dart';
import 'package:waydir/ui/theme/app_theme.dart';

void main() {
  testWidgets(
    'keyboard focus must be reclaimed after an inline rename commits',
    (tester) async {
      final shellNode = FocusNode(debugLabel: 'shell');
      var enterCount = 0;
      String? renamingPath = '__pending_create__';
      late StateSetter setState;

      final pending = FileEntry(
        name: '',
        path: '__pending_create__',
        type: FileItemType.folder,
        size: 0,
        modified: DateTime.now(),
      );
      final existing = FileEntry(
        name: 'existing',
        path: '/tmp/existing',
        type: FileItemType.folder,
        size: 0,
        modified: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(),
          home: Scaffold(
            body: Focus(
              focusNode: shellNode,
              autofocus: true,
              onKeyEvent: (_, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.enter) {
                  enterCount++;
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: StatefulBuilder(
                builder: (context, s) {
                  setState = s;
                  return FileList(
                    files: renamingPath == '__pending_create__'
                        ? [pending, existing]
                        : [existing],
                    currentPath: '/tmp',
                    onSelect: (_) {},
                    onOpen: (_) {},
                    renamingPath: renamingPath,
                    onRenameSubmit: (_) => setState(() => renamingPath = null),
                    onRenameCancel: () => setState(() => renamingPath = null),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(EditableText), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'NewFolder');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.byType(EditableText), findsNothing);

      expect(FocusManager.instance.primaryFocus, isNot(shellNode));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(enterCount, 0);

      shellNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(enterCount, 1);

      shellNode.dispose();
    },
  );

  testWidgets('re-entering rename refocuses and reselects the field', (
    tester,
  ) async {
    String? renamingPath;
    late StateSetter setState;

    final existing = FileEntry(
      name: 'folder',
      path: '/tmp/folder',
      type: FileItemType.folder,
      size: 0,
      modified: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, s) {
              setState = s;
              return FileList(
                files: [existing],
                currentPath: '/tmp',
                onSelect: (_) {},
                onOpen: (_) {},
                renamingPath: renamingPath,
                onRenameSubmit: (_) => setState(() => renamingPath = null),
                onRenameCancel: () => setState(() => renamingPath = null),
              );
            },
          ),
        ),
      ),
    );

    Future<void> enterRename() async {
      setState(() => renamingPath = '/tmp/folder');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    void expectFocusedAndSelected() {
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.focusNode.hasFocus, isTrue);
      expect(editable.controller.selection.baseOffset, 0);
      expect(
        editable.controller.selection.extentOffset,
        editable.controller.text.length,
      );
      expect(editable.controller.text, 'folder');
    }

    await enterRename();
    expectFocusedAndSelected();

    setState(() => renamingPath = null);
    await tester.pumpAndSettle();
    expect(find.byType(EditableText), findsNothing);

    await enterRename();
    expectFocusedAndSelected();
  });
}
