import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/di.dart';
import '../models/models.dart';

final recipesProvider = StreamProvider.family<List<Recipe>, String>((ref, recipeType) {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.watchRecipes().map(
    (recipes) => recipes.where((r) => r.recipeType == recipeType).toList(),
  );
});

final recipeIngredientsProvider =
    StreamProvider.family<List<RecipeIngredient>, String>((ref, recipeId) {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.watchIngredients(recipeId);
});

final dailyCocktailProvider = Provider<Recipe?>((ref) {
  final recipes = ref.watch(recipesProvider('cocktail')).asData?.value;
  if (recipes == null || recipes.isEmpty) return null;
  final now = DateTime.now();
  final dayOfYear = now.difference(DateTime(now.year)).inDays;
  return recipes[dayOfYear % recipes.length];
});
