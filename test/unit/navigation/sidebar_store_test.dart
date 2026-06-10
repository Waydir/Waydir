import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/features/navigation/sidebar_store.dart';

void main() {
  final store = SidebarStore.instance;

  setUp(() {
    store.itemOrder.value = const {};
  });

  String id(String s) => s;

  group('SidebarStore.orderItems', () {
    test('returns incoming order when no stored order exists', () {
      final result = store.orderItems('devices', ['a', 'b', 'c'], id);
      expect(result, ['a', 'b', 'c']);
    });

    test('sorts known keys by stored position', () {
      store.itemOrder.value = {
        'devices': ['c', 'a', 'b'],
      };
      final result = store.orderItems('devices', ['a', 'b', 'c'], id);
      expect(result, ['c', 'a', 'b']);
    });

    test('appends unknown keys after known ones in incoming order', () {
      store.itemOrder.value = {
        'devices': ['b', 'a'],
      };
      final result = store.orderItems('devices', ['a', 'x', 'b', 'y'], id);
      expect(result, ['b', 'a', 'x', 'y']);
    });

    test('ignores stored keys no longer present', () {
      store.itemOrder.value = {
        'devices': ['gone', 'b', 'a'],
      };
      final result = store.orderItems('devices', ['a', 'b'], id);
      expect(result, ['b', 'a']);
    });
  });
}
