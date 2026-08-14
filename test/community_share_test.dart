import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/community_share.dart';

void main() {
  group('communityShareKindOf', () {
    test('legacy checklist payload (no kind) still counts as checklist', () {
      expect(
        communityShareKindOf({
          'title': 'Pre-departure',
          'appType': 'checklist',
          'items': [],
        }),
        CommunityShareKind.checklist,
      );
    });

    test('explicit kind wins', () {
      expect(
        communityShareKindOf({'kind': 'recipe', 'name': 'Stew'}),
        CommunityShareKind.recipe,
      );
    });
  });

  group('encode / decode recipe (#323)', () {
    test('Yanmar-unrelated: a menu recipe round-trips ingredients', () {
      final recipe = Recipe()
        ..name = 'Conch stew'
        ..recipeType = 'menu'
        ..description = 'Bahamas staple'
        ..instructions = 'Simmer'
        ..cuisine = ['Caribbean']
        ..winePairing = 'Riesling';
      final ings = [
        RecipeIngredient()
          ..name = 'Conch'
          ..quantity = 500
          ..unit = 'g',
      ];
      final payload = encodeRecipeContent(recipe, ings);
      expect(payload['kind'], CommunityShareKind.recipe);
      final decoded = decodeSharedRecipe(
        payload,
        recipeSupabaseId: 'r1',
        boatId: 'boat-1',
      );
      expect(decoded.recipe.name, 'Conch stew');
      expect(decoded.recipe.recipeType, 'menu');
      expect(decoded.recipe.winePairing, 'Riesling');
      expect(decoded.ingredients.single.name, 'Conch');
      expect(decoded.ingredients.single.quantity, 500);
    });

    test('cocktail payload uses the cocktail kind', () {
      final recipe = Recipe()
        ..name = 'Painkiller'
        ..recipeType = 'cocktail';
      final payload = encodeRecipeContent(recipe, const []);
      expect(payload['kind'], CommunityShareKind.cocktail);
    });
  });

  group('encode collection / shopping', () {
    test('collection embeds recipes so import does not need local ids', () {
      final maiTai = Recipe()
        ..name = 'Mai Tai'
        ..recipeType = 'cocktail';
      final payload = encodeCollectionContent(
        name: 'Tiki night',
        recipes: [
          (
            maiTai,
            [RecipeIngredient()..name = 'Rum'],
          ),
        ],
      );
      expect(payload['kind'], CommunityShareKind.collection);
      final recipes = payload['recipes'] as List;
      expect(recipes, hasLength(1));
      expect((recipes.first as Map)['name'], 'Mai Tai');
      expect((recipes.first as Map)['ingredients'], isNotEmpty);
    });

    test('shopping list drops hidden lines', () {
      final payload = encodeShoppingContent(
        title: 'Exuma provisioning',
        items: [
          ShoppingItem()
            ..name = 'Limes'
            ..quantity = 12
            ..origin = 'pantry',
          ShoppingItem()
            ..name = 'Gone'
            ..isHidden = true,
        ],
      );
      expect(payload['kind'], CommunityShareKind.shopping);
      final items = payload['items'] as List;
      expect(items, hasLength(1));
      expect((items.first as Map)['name'], 'Limes');
    });
  });
}
