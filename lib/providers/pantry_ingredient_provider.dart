import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/di.dart';
import '../models/models.dart';

final pantryIngredientsProvider = StreamProvider<List<PantryIngredient>>((ref) {
  return ref.watch(pantryIngredientRepositoryProvider).watchPantryIngredients();
});

/// Returns the menu names that use a given ingredient name.
final menusForIngredientProvider =
    FutureProvider.family<List<String>, String>((ref, ingredientName) async {
  return ref
      .watch(pantryIngredientRepositoryProvider)
      .recipeNamesForIngredient(ingredientName);
});

/// Menu [Recipe]s that use [ingredientName] (tappable navigation).
final menuRecipesForIngredientProvider =
    FutureProvider.family<List<Recipe>, String>((ref, ingredientName) async {
  return ref
      .watch(pantryIngredientRepositoryProvider)
      .menusUsingIngredient(ingredientName);
});
