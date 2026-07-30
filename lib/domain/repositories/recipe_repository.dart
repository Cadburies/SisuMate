import '../../models/models.dart';

abstract class RecipeRepository {
  Stream<List<Recipe>> watchRecipes();
  Stream<List<RecipeIngredient>> watchIngredients(String recipeId);
  Future<List<RecipeIngredient>> getIngredientsOnce(String recipeId);
  Future<void> addRecipe(Recipe recipe);
  Future<void> updateRecipe(Recipe recipe);
  Future<void> deleteRecipe(Recipe recipe);
  Future<void> addIngredient(RecipeIngredient ingredient);
  Future<void> updateIngredient(RecipeIngredient ingredient);
  Future<void> deleteIngredient(RecipeIngredient ingredient);
  Future<void> syncMissingIngredientCounts();
}
