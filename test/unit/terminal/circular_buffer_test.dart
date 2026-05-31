import 'package:flutter_test/flutter_test.dart';
import 'package:waydir_term/src/utils/circular_buffer.dart';

class _Item with IndexedItem {
  _Item(this.value);
  final int value;
}

void main() {
  group('IndexAwareCircularBuffer.replaceWith', () {
    test('leaves no null holes when the ring origin has advanced', () {
      // Capacity 4. Push 6 so the ring wraps and _startIndex advances past 0
      // (the precondition for the old reflow crash).
      final buf = IndexAwareCircularBuffer<_Item>(4);
      for (var i = 0; i < 6; i++) {
        buf.push(_Item(i));
      }
      expect(buf.length, 4);

      buf.replaceWith([for (var i = 0; i < 4; i++) _Item(100 + i)]);

      expect(buf.length, 4);
      // Every slot in the logical window must be readable (no null deref).
      for (var i = 0; i < buf.length; i++) {
        expect(buf[i].value, 100 + i);
      }
    });

    test('keeps the last maxLength items when replacement overflows', () {
      final buf = IndexAwareCircularBuffer<_Item>(3);
      buf.push(_Item(0));
      buf.push(_Item(1));
      buf.push(_Item(2));
      buf.push(_Item(3)); // wraps, _startIndex advances

      buf.replaceWith([for (var i = 0; i < 5; i++) _Item(i)]);

      expect(buf.length, 3);
      expect([for (var i = 0; i < buf.length; i++) buf[i].value], [2, 3, 4]);
    });
  });
}
