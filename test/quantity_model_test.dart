import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/quantity_model.dart';

/// #310 — purchase pack math (scenarios from the issue).
void main() {
  const model = QuantityModel();

  group('PurchaseSpec.fromCatalog', () {
    test('parses 250ml bottle + price', () {
      final s = PurchaseSpec.fromCatalog(
        packageQty: 250,
        packageUnit: 'ml',
        priceUnit: '250ml bottle',
        price: 12,
      );
      expect(s.hasSize, isTrue);
      expect(s.sizeBase, 250);
      expect(s.sizeUnit, 'ml');
      expect(s.unitLabel, '250ml bottle');
      expect(s.pricePerUnit, 12);
    });

    test('parses 500g pack', () {
      final s = PurchaseSpec.fromCatalog(
        packageQty: 500,
        packageUnit: 'g',
        priceUnit: '500g pack',
        price: 4,
      );
      expect(s.sizeBase, 500);
      expect(s.sizeUnit, 'g');
    });

    test('parses 750ml from bar price unit', () {
      final s = PurchaseSpec.fromCatalog(
        priceUnit: '750ml',
        price: 20,
      );
      expect(s.sizeBase, 750);
      expect(s.sizeUnit, 'ml');
    });

    test('parses 12x200ml case as total volume', () {
      final s = PurchaseSpec.fromCatalog(
        priceUnit: '12x200ml case',
        price: 15,
      );
      expect(s.sizeBase, 2400);
      expect(s.sizeUnit, 'ml');
    });
  });

  group('packagesToBuy', () {
    test('scenario 1 — balsamic 1 bottle', () {
      final packs = model.packagesToBuy(
        needBase: 250,
        haveBase: 0,
        packageSizeBase: 250,
      );
      expect(packs, 1);
      final line = model.shopLine(
        name: 'Aged Balsamic Vinegar',
        needQty: 250,
        needUnit: 'ml',
        haveBase: 0,
        purchase: PurchaseSpec.fromCatalog(
          packageQty: 250,
          packageUnit: 'ml',
          priceUnit: '250ml bottle',
          price: 12,
        ),
      )!;
      expect(line.packages, 1);
      expect(line.lineEstimate, 12);
    });

    test('scenario 4 — couscous 900 g need, 500 g bags', () {
      expect(
        model.packagesToBuy(needBase: 900, haveBase: 0, packageSizeBase: 500),
        2,
      );
      expect(
        model.packagesToBuy(needBase: 900, haveBase: 500, packageSizeBase: 500),
        1,
      );
    });

    test('scenario 6 — vodka pours → bottles', () {
      expect(
        model.bottlesFromPours(
          pourMlEach: 60,
          drinkCount: 8,
          bottleMl: 750,
          onHandMl: 100,
        ),
        1, // need 480, have 100, deficit 380 → 1×750
      );
    });
  });

  group('pantryOnHandBase', () {
    test('not in pantry → 0', () {
      final p = PantryIngredient()
        ..name = 'Couscous'
        ..quantity = 500
        ..unit = 'g'
        ..inMyPantry = false;
      expect(model.pantryOnHandBase(p, needUnit: 'g'), 0);
    });

    test('in pantry with amount → that amount', () {
      final p = PantryIngredient()
        ..name = 'Couscous'
        ..quantity = 500
        ..unit = 'g'
        ..inMyPantry = true;
      expect(model.pantryOnHandBase(p, needUnit: 'g'), 500);
    });

    test('scenario 5 — in pantry qty 0 → 0', () {
      final p = PantryIngredient()
        ..name = 'Couscous'
        ..quantity = 0
        ..unit = 'g'
        ..inMyPantry = true;
      expect(model.pantryOnHandBase(p, needUnit: 'g'), 0);
    });
  });
}
