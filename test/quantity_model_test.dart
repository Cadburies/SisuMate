import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/quantity_model.dart';

void main() {
  const model = QuantityModel();

  group('PurchaseSpec.fromFields / seed label', () {
    test('parses 250ml bottle + price', () {
      final s = PurchaseSpec.fromSeedLabel(
        packageQty: 250,
        packageUnit: 'ml',
        priceUnit: '250ml bottle',
        price: 12,
      );
      expect(s.hasSize, isTrue);
      expect(s.sizeBase, 250);
      expect(s.sizeUnit, 'ml');
      expect(s.noun, 'bottle');
      expect(s.unitLabel, '250ml bottle');
      expect(s.pricePerUnit, 12);
    });

    test('parses 500g pack', () {
      final s = PurchaseSpec.fromSeedLabel(
        packageQty: 500,
        packageUnit: 'g',
        priceUnit: '500g pack',
        price: 4,
      );
      expect(s.sizeBase, 500);
      expect(s.sizeUnit, 'g');
      expect(s.noun, 'pack');
    });

    test('1L bottle wins over stale 500 ml seed qty', () {
      final s = PurchaseSpec.fromSeedLabel(
        packageQty: 500,
        packageUnit: 'ml',
        priceUnit: '1L bottle',
        price: 18,
      );
      expect(s.sizeBase, 1000);
      expect(s.sizeUnit, 'ml');
      expect(s.unitLabel, '1L bottle');
    });

    test('parses 12x200ml case as total volume', () {
      final s = PurchaseSpec.fromSeedLabel(
        priceUnit: '12x200ml case',
        price: 15,
        defaultNoun: 'pack',
      );
      expect(s.sizeBase, 2400);
      expect(s.sizeUnit, 'ml');
      expect(s.unitsPerPurchase, 12);
      expect(s.innerSizeBase, 200);
      expect(s.noun, 'case');
      expect(s.unitLabel, '12×200ml case');
    });

    test('fromPantry ignores on-hand quantity as pack size', () {
      final p = PantryIngredient()
        ..name = 'Couscous'
        ..quantity = 200
        ..unit = 'g'
        ..inMyPantry = true
        ..purchaseSizeBase = 500
        ..purchaseBaseUnit = 'g'
        ..purchaseNoun = 'pack'
        ..lastKnownPrice = 4;
      final s = PurchaseSpec.fromPantry(p);
      expect(s.sizeBase, 500);
      expect(s.sizeBase, isNot(200));
    });
  });

  group('packagesToBuy / shopLine', () {
    test('scenario 1 — balsamic 1 bottle \$12', () {
      final purchase = PurchaseSpec.fromFields(
        purchaseSizeBase: 250,
        purchaseBaseUnit: 'ml',
        purchaseNoun: 'bottle',
        price: 12,
      );
      final line = model.shopLine(
        name: 'Aged Balsamic Vinegar',
        needQty: 250,
        needUnit: 'ml',
        haveBase: 0,
        purchase: purchase,
      )!;
      expect(line.packages, 1);
      expect(line.lineEstimate, 12);
    });

    test('scenario 4 — couscous 900 g / 500 g bags', () {
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
        1,
      );
    });
  });

  group('on-hand', () {
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

    test('tracked + null amount is unknown, not covered', () {
      final p = PantryIngredient()
        ..name = 'Couscous'
        ..quantity = null
        ..inMyPantry = true;
      expect(model.pantryOnHandBase(p, needUnit: 'g'), isNull);
    });
  });

  group('recipe cost', () {
    test('scenario 8 — couscous 50 g × 6 is one 500 g pack', () {
      final pantry = PantryIngredient()
        ..name = 'Couscous'
        ..purchaseSizeBase = 500
        ..purchaseBaseUnit = 'g'
        ..purchaseNoun = 'pack'
        ..lastKnownPrice = 4
        ..inMyPantry = false;
      final cost = model.recipePackCost(
        ingredients: [
          RecipeIngredient()
            ..name = 'Couscous'
            ..quantity = 50
            ..unit = 'g',
        ],
        pantry: [pantry],
        servings: 6,
      );
      expect(cost, 4);
    });
  });

  group('preferred drinks', () {
    test('scenario 2 — vodka short + ting safety case', () {
      final vodka = BarIngredient()
        ..name = 'Vodka'
        ..purchaseSizeBase = 750
        ..purchaseBaseUnit = 'ml'
        ..purchaseNoun = 'bottle'
        ..lastKnownPrice = 20
        ..inMyBar = false;
      final ting = BarIngredient()
        ..name = 'Ting'
        ..purchaseSizeBase = 2400
        ..purchaseBaseUnit = 'ml'
        ..purchaseNoun = 'case'
        ..unitsPerPurchase = 12
        ..innerSizeBase = 200
        ..lastKnownPrice = 15
        ..inMyBar = true
        ..onHandBase = 2400
        ..onHandUnit = 'ml';
      final lines = model.preferredDrinkPacks(
        preferredNames: ["Tito's Vodka", 'Ting'],
        bar: [vodka, ting],
        safetyByName: {'ting': 1},
      );
      expect(lines.map((l) => l.name), containsAll(['Vodka', 'Ting']));
      final v = lines.firstWhere((l) => l.name == 'Vodka');
      expect(v.packages, 1);
      expect(v.lineEstimate, 20);
      final t = lines.firstWhere((l) => l.name == 'Ting');
      expect(t.packages, 1);
      expect(t.unitLabel, contains('200ml'));
      expect(t.lineEstimate, 15);
    });
  });
}
