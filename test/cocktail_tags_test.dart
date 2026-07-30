import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/seed/cocktail_tags.dart';
import 'package:sisu_mate/models/models.dart';

void main() {
  group('cocktail seed favourites & tags', () {
    test('seeded favourite names match case-insensitively', () {
      expect(isSeededFavouriteName('mai tai'), isTrue);
      expect(isSeededFavouriteName('Tradewinds'), isTrue);
      expect(isSeededFavouriteName('Hinky Dinks Fizzy'), isTrue);
      expect(isSeededFavouriteName('Negroni'), isFalse);
    });

    test('classic meta sets favourite + cuisine + flavors for Mai Tai', () {
      final r = Recipe()
        ..supabaseId = 'cocktail_mai_tai'
        ..name = 'Mai Tai'
        ..recipeType = 'cocktail';
      applyClassicCocktailSeedMeta(r);
      expect(r.isFavourite, isTrue);
      expect(r.cuisine, contains('Tiki'));
      expect(r.flavorProfiles, isNotEmpty);
      expect(r.flavorProfiles, contains('rum-forward'));
    });

    test('mergeTagLists dedupes case-insensitively', () {
      expect(
        mergeTagLists(['Citrus', 'tropical'], ['citrus', 'spicy']),
        ['Citrus', 'tropical', 'spicy'],
      );
    });
  });
}
