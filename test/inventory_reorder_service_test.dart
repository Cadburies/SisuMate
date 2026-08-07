import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/inventory_reorder_service.dart';

void main() {
  group('InventoryReorderService (#298)', () {
    InventoryItem item({
      required String name,
      double qty = 1,
      String? notes,
      String? location,
    }) =>
        InventoryItem()
          ..name = name
          ..quantity = qty
          ..notes = notes
          ..location = location;

    test('default min 1 flags zero stock', () {
      final low = InventoryReorderService.lowStock([
        item(name: 'Impeller', qty: 0),
        item(name: 'Filters', qty: 5),
      ]);
      expect(low.map((e) => e.item.name), ['Impeller']);
    });

    test('min:N from notes raises threshold', () {
      final low = InventoryReorderService.lowStock([
        item(name: 'Filters', qty: 2, notes: 'min:3 for passage'),
      ]);
      expect(low, hasLength(1));
      expect(low.single.minQty, 3);
      expect(low.single.shortfall, closeTo(1, 0.01));
    });

    test('location tree and filter', () {
      final items = [
        item(name: 'A', location: 'Bilge'),
        item(name: 'B', location: 'Lazarette'),
        item(name: 'C', location: 'bilge'),
      ];
      expect(InventoryReorderService.locationTree(items),
          ['Bilge', 'Lazarette']);
      expect(
        InventoryReorderService.filterByLocation(items, 'Bilge')
            .map((e) => e.name),
        ['A', 'C'],
      );
    });
  });
}
