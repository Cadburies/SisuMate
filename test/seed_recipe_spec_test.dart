import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late final src = File('lib/data/seed/seed_recipes.dart').readAsStringSync();

  test('#332 Painkiller pineapple is ~120 ml (4 oz classic)', () {
    expect(
      src.contains(
          "addCocktail('cocktail_painkiller', 'Pineapple Juice', 120, 'ml')"),
      isTrue,
    );
  });

  test('#332 Suffering Bastard ginger beer has a volume', () {
    expect(
      src.contains(
          "addCocktail('cocktail_suffering_bastard', 'Ginger Beer', 100, 'ml')"),
      isTrue,
    );
  });

  test('#332 classic proteins are grams, not pieces', () {
    expect(
      src.contains(
          "addMenu('menu_american_steakhouse_classic', 'Prime Ribeye Steak', 600.0, 'g')"),
      isTrue,
    );
    expect(
      src.contains("addMenu('menu_classic_french_bistro', 'Duck Breast', 350.0, 'g')"),
      isTrue,
    );
  });
}
