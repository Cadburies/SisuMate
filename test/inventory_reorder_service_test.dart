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
      String? barcode,
      String? linkedMaintenanceItemSupabaseId,
      String? unit,
    }) =>
        InventoryItem()
          ..name = name
          ..quantity = qty
          ..notes = notes
          ..location = location
          ..barcode = barcode
          ..unit = unit
          ..linkedMaintenanceItemSupabaseId = linkedMaintenanceItemSupabaseId;

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

    group('findByBarcode (#318)', () {
      test('returns the item with a matching barcode', () {
        final items = [
          item(name: 'Impeller', barcode: '012345678905'),
          item(name: 'Filters', barcode: '098765432109'),
        ];
        expect(
          InventoryReorderService.findByBarcode(items, '098765432109')
              ?.name,
          'Filters',
        );
      });

      test('returns null when nothing matches', () {
        final items = [item(name: 'Impeller', barcode: '012345678905')];
        expect(
          InventoryReorderService.findByBarcode(items, 'unknown-code'),
          isNull,
        );
      });

      test('null/empty barcode never matches, even an item with none set',
          () {
        final items = [item(name: 'No barcode item')];
        expect(InventoryReorderService.findByBarcode(items, null), isNull);
        expect(InventoryReorderService.findByBarcode(items, ''), isNull);
      });
    });

    group('linkedTo / usedBy (#319)', () {
      test('linkedTo returns only items pointing at that checklist id', () {
        final items = [
          item(name: 'Impeller', linkedMaintenanceItemSupabaseId: 'maint_1'),
          item(name: 'Belt', linkedMaintenanceItemSupabaseId: 'maint_2'),
          item(name: 'Unlinked'),
        ];
        expect(
          InventoryReorderService.linkedTo(items, 'maint_1').map((e) => e.name),
          ['Impeller'],
        );
        expect(InventoryReorderService.linkedTo(items, null), isEmpty);
        expect(InventoryReorderService.linkedTo(items, ''), isEmpty);
      });

      test('usedByLabel prefixes the group title and reports a missing task', () {
        final task = ChecklistItem()
          ..supabaseId = 'maint_1'
          ..groupSupabaseId = 'grp_eng'
          ..title = 'Replace impeller';
        final linked = item(
          name: 'Impeller',
          linkedMaintenanceItemSupabaseId: 'maint_1',
        );
        expect(
          InventoryReorderService.usedByLabel(
            linked,
            [task],
            groupTitleOf: (id) => id == 'grp_eng' ? 'Engine Room' : '',
          ),
          'Engine Room — Replace impeller',
        );
        expect(
          InventoryReorderService.usedByLabel(item(name: 'Unlinked'), [task]),
          isNull,
        );
        expect(
          InventoryReorderService.usedByLabel(
            item(name: 'Orphan', linkedMaintenanceItemSupabaseId: 'gone'),
            [task],
          ),
          'Linked task missing',
        );
      });

      test('spareOnHandLabel includes qty, unit, and min', () {
        expect(
          InventoryReorderService.spareOnHandLabel(
            item(name: 'Impeller', qty: 3, unit: 'pcs'),
          ),
          'Impeller: 3 pcs on hand, min 1',
        );
      });
    });

    group('quantity history (#320)', () {
      test('averageDaysBetweenRestocks needs two restocks', () {
        expect(InventoryReorderService.averageDaysBetweenRestocks([]), isNull);
        expect(
          InventoryReorderService.averageDaysBetweenRestocks([
            InventoryQtyChange(
              at: DateTime.utc(2026, 1, 1),
              from: 1,
              to: 4,
            ),
          ]),
          isNull,
        );
        expect(
          InventoryReorderService.averageDaysBetweenRestocks([
            InventoryQtyChange(
              at: DateTime.utc(2026, 1, 1),
              from: 1,
              to: 4,
            ),
            InventoryQtyChange(
              at: DateTime.utc(2026, 1, 11),
              from: 0,
              to: 3,
            ),
          ]),
          10,
        );
      });

      test('quantityHistoryLines lists newest change first and the restock avg',
          () {
        final inv = item(name: 'Flares', qty: 3)
          ..lastModified = DateTime.utc(2026, 1, 11)
          ..quantityHistory = [
            InventoryQtyChange(
              at: DateTime.utc(2026, 1, 1),
              from: 1,
              to: 4,
            ),
            InventoryQtyChange(
              at: DateTime.utc(2026, 1, 5),
              from: 4,
              to: 0,
            ),
            InventoryQtyChange(
              at: DateTime.utc(2026, 1, 11),
              from: 0,
              to: 3,
            ),
          ];
        final lines = InventoryReorderService.quantityHistoryLines(inv);
        expect(lines.first, contains('Last modified:'));
        expect(lines[1], contains('Qty 0 → 3 restock'));
        expect(lines[2], contains('Qty 4 → 0'));
        expect(lines.last, 'Average 10 days between restocks');
      });
    });
  });
}
