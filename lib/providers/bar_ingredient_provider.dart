import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/di.dart';
import '../models/models.dart';

final barIngredientsProvider = StreamProvider<List<BarIngredient>>((ref) {
  return ref.watch(barIngredientRepositoryProvider).watchBarIngredients();
});

/// Returns the cocktail names that use a given ingredient name.
final cocktailsForIngredientProvider =
    FutureProvider.family<List<String>, String>((ref, ingredientName) async {
  return ref
      .watch(barIngredientRepositoryProvider)
      .recipeNamesForIngredient(ingredientName);
});

/// Cocktail [Recipe]s that use [ingredientName] (tappable navigation).
final cocktailRecipesForIngredientProvider =
    FutureProvider.family<List<Recipe>, String>((ref, ingredientName) async {
  return ref
      .watch(barIngredientRepositoryProvider)
      .cocktailsUsingIngredient(ingredientName);
});
