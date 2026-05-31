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

  group('IndexAwareCircularBuffer element moves', () {
    test('list[i] = list[j] does not alias items across slots', () {
      // Reproduces the buffer line-scroll pattern (scrollUp): shift every line
      // up by one, then fill the last. The same item must never end up in two
      // slots — otherwise detaching one alias leaves a detached item (or null
      // hole) in the window, crashing paint.
      final buf = IndexAwareCircularBuffer<_Item>(5);
      for (var i = 0; i < 5; i++) {
        buf.push(_Item(i));
      }

      for (var i = 0; i < 4; i++) {
        buf[i] = buf[i + 1];
      }
      buf[4] = _Item(99);

      expect([for (var i = 0; i < 5; i++) buf[i].value], [1, 2, 3, 4, 99]);
      for (var i = 0; i < 5; i++) {
        expect(buf[i].attached, isTrue, reason: 'slot $i detached');
      }
    });

    test('scrollDown pattern (bottom-up copy) leaves no holes', () {
      final buf = IndexAwareCircularBuffer<_Item>(5);
      for (var i = 0; i < 5; i++) {
        buf.push(_Item(i));
      }

      for (var i = 4; i >= 0; i--) {
        buf[i] = i >= 1 ? buf[i - 1] : _Item(99);
      }

      expect([for (var i = 0; i < 5; i++) buf[i].value], [99, 0, 1, 2, 3]);
      for (var i = 0; i < 5; i++) {
        expect(buf[i].attached, isTrue, reason: 'slot $i detached');
      }
    });
  });
}
