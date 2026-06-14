import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/settings/settings_store.dart';

void main() {
  final store = SettingsStore.instance;

  group('SettingsStore terminal font size stepping', () {
    setUp(() {
      store.terminalFontSize.value = SettingsStore.defaultTerminalFontSize;
    });

    tearDown(() {
      store.terminalFontSize.value = SettingsStore.defaultTerminalFontSize;
    });

    test('increase steps to the next size', () {
      store.terminalFontSize.value = 13;
      store.increaseTerminalFontSize();
      expect(store.terminalFontSize.value, 14);
    });

    test('decrease steps to the previous size', () {
      store.terminalFontSize.value = 13;
      store.decreaseTerminalFontSize();
      expect(store.terminalFontSize.value, 12);
    });

    test('increase clamps at the maximum size', () {
      store.terminalFontSize.value = SettingsStore.terminalFontSizes.last;
      store.increaseTerminalFontSize();
      expect(store.terminalFontSize.value, SettingsStore.terminalFontSizes.last);
    });

    test('decrease clamps at the minimum size', () {
      store.terminalFontSize.value = SettingsStore.terminalFontSizes.first;
      store.decreaseTerminalFontSize();
      expect(store.terminalFontSize.value, SettingsStore.terminalFontSizes.first);
    });

    test('reset returns to the default size', () {
      store.terminalFontSize.value = 22;
      store.resetTerminalFontSize();
      expect(
        store.terminalFontSize.value,
        SettingsStore.defaultTerminalFontSize,
      );
    });

    test('increase from a value between steps snaps to next valid size', () {
      store.terminalFontSize.value = 17;
      store.increaseTerminalFontSize();
      expect(store.terminalFontSize.value, 18);
    });

    test('decrease from a value between steps snaps to previous valid size', () {
      store.terminalFontSize.value = 17;
      store.decreaseTerminalFontSize();
      expect(store.terminalFontSize.value, 16);
    });

    test('decrease from a value above the list maximum snaps to second-to-last', () {
      store.terminalFontSize.value = 99;
      store.decreaseTerminalFontSize();
      final sizes = SettingsStore.terminalFontSizes;
      expect(store.terminalFontSize.value, sizes[sizes.length - 2]);
    });
  });

  group('SettingsStore file list scale stepping', () {
    setUp(() {
      store.fileListScale.value = SettingsStore.defaultFileListScale;
    });

    tearDown(() {
      store.fileListScale.value = SettingsStore.defaultFileListScale;
    });

    test('increase adds one step', () {
      store.fileListScale.value = 1.0;
      store.increaseFileListScale();
      expect(store.fileListScale.value, closeTo(1.1, 0.001));
    });

    test('decrease subtracts one step', () {
      store.fileListScale.value = 1.0;
      store.decreaseFileListScale();
      expect(store.fileListScale.value, closeTo(0.9, 0.001));
    });

    test('increase clamps at maximum', () {
      store.fileListScale.value = SettingsStore.fileListScaleMax;
      store.increaseFileListScale();
      expect(
        store.fileListScale.value,
        closeTo(SettingsStore.fileListScaleMax, 0.001),
      );
    });

    test('decrease clamps at minimum', () {
      store.fileListScale.value = SettingsStore.fileListScaleMin;
      store.decreaseFileListScale();
      expect(
        store.fileListScale.value,
        closeTo(SettingsStore.fileListScaleMin, 0.001),
      );
    });

    test('reset returns to 1.0', () {
      store.fileListScale.value = 1.5;
      store.resetFileListScale();
      expect(
        store.fileListScale.value,
        closeTo(SettingsStore.defaultFileListScale, 0.001),
      );
    });

    test('multiple increases accumulate correctly', () {
      store.fileListScale.value = 1.0;
      store.increaseFileListScale();
      store.increaseFileListScale();
      store.increaseFileListScale();
      expect(store.fileListScale.value, closeTo(1.3, 0.01));
    });
  });

  group('SettingsStore signal defaults', () {
    test('themeId defaults to dark', () {
      expect(store.themeId.value, 'dark');
    });

    test('confirmDelete defaults to true', () {
      expect(store.confirmDelete.value, isTrue);
    });

    test('sortAscending defaults to true', () {
      expect(store.sortAscending.value, isTrue);
    });

    test('foldersFirst defaults to true', () {
      expect(store.foldersFirst.value, isTrue);
    });

    test('showHiddenDefault defaults to false', () {
      expect(store.showHiddenDefault.value, isFalse);
    });

    test('sessionIsDual defaults to false', () {
      expect(store.sessionIsDual.value, isFalse);
    });

    test('fileListScale defaults to 1.0', () {
      expect(store.fileListScale.value, closeTo(1.0, 0.001));
    });

    test('terminalFontSize defaults to 13', () {
      expect(
        store.terminalFontSize.value,
        SettingsStore.defaultTerminalFontSize,
      );
    });
  });
}
