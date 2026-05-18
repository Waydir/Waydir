import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/features/quick_look/code_highlighter.dart';

void main() {
  test('highlightCode handles languages without block comment groups', () {
    final lang = languageForExtension('json')!;

    expect(
      () => highlightCode(
        '{"name": "waydir", "size": 42}',
        lang,
        const TextStyle(),
      ),
      returnsNormally,
    );
  });
}
