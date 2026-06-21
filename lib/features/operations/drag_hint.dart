import 'package:flutter/services.dart';
import 'package:signals/signals_flutter.dart';

import '../../core/settings/settings_store.dart';

enum DragMode { copy, move }

class DragHintController {
  static final DragHintController instance = DragHintController._();
  DragHintController._();

  final mode = signal(DragMode.copy);
}

DragMode initialDragMode() {
  final moveByDefault = SettingsStore.instance.dragMovesByDefault.value;
  final alt = HardwareKeyboard.instance.isAltPressed;
  final move = moveByDefault != alt;

  return move ? DragMode.move : DragMode.copy;
}
