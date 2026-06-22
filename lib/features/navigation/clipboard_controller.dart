import 'package:flutter/services.dart';
import 'package:signals/signals.dart';

import '../../core/clipboard/file_clipboard.dart';
import '../../core/models/file_entry.dart';
import '../../core/platform/platform_paths.dart';

enum ClipboardMode { copy, cut }

class ClipboardController {
  final clipboardPaths = signal<Set<String>>({});
  final clipboardMode = signal<ClipboardMode?>(null);
  late final Computed<bool> canPaste = computed(
    () => clipboardPaths.value.isNotEmpty && clipboardMode.value != null,
  );

  void copySelectedPaths(Set<String> paths) {
    if (paths.isEmpty) return;
    final text = paths.length == 1 ? paths.first : paths.join('\n');
    Clipboard.setData(ClipboardData(text: text));
  }

  Future<void> copyEntries(List<FileEntry> entries) async {
    await _writeEntries(entries, ClipboardMode.copy);
  }

  Future<void> cutEntries(List<FileEntry> entries) async {
    await _writeEntries(entries, ClipboardMode.cut);
  }

  Future<bool> hasPasteableFiles({required bool isTrashView}) async {
    if (canPaste.value) return true;
    if (isTrashView) return false;
    final paths = await FileClipboard.readFilePaths();

    return paths.isNotEmpty;
  }

  Future<List<String>> readAvailablePaths() async {
    final paths = await FileClipboard.readFilePaths();
    if (paths.isNotEmpty) return paths;

    return clipboardPaths.value.toList();
  }

  Future<ClipboardPastePayload> readPastePayload() async {
    final internalPaths = Set<String>.from(clipboardPaths.value);
    final internalCut = clipboardMode.value == ClipboardMode.cut;
    final paths = await readAvailablePaths();
    if (paths.isEmpty) {
      return ClipboardPastePayload.empty(internalPaths: internalPaths);
    }
    final samePaths =
        internalPaths.length == paths.length &&
        internalPaths.containsAll(paths.toSet());
    var isCut = samePaths && internalCut;
    if (!isCut) isCut = await FileClipboard.isCutOperation();

    return ClipboardPastePayload(
      paths: paths,
      internalPaths: internalPaths,
      samePaths: samePaths,
      isCut: isCut,
    );
  }

  void clearInternal({ClipboardMode? mode}) {
    batch(() {
      clipboardPaths.value = {};
      clipboardMode.value = mode;
    });
  }

  Future<void> _writeEntries(
    List<FileEntry> entries,
    ClipboardMode mode,
  ) async {
    if (entries.isEmpty) return;
    final logical = entries.map((e) => e.path).toList();
    final physical = entries.map((e) => e.realPath).toList();
    batch(() {
      clipboardPaths.value = Set<String>.from(logical);
      clipboardMode.value = mode;
    });
    if (!physical.any(PlatformPaths.isSftpUri)) {
      await FileClipboard.writeFiles(
        physical,
        isCut: mode == ClipboardMode.cut,
      );
    }
  }
}

class ClipboardPastePayload {
  final List<String> paths;
  final Set<String> internalPaths;
  final bool samePaths;
  final bool isCut;

  const ClipboardPastePayload({
    required this.paths,
    required this.internalPaths,
    required this.samePaths,
    required this.isCut,
  });

  const ClipboardPastePayload.empty({required this.internalPaths})
    : paths = const [],
      samePaths = false,
      isCut = false;
}
