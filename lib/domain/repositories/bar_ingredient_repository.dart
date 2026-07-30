import '../../models/models.dart';

abstract class BarIngredientRepository {
  Stream<List<BarIngredient>> watchBarIngredients();
  Future<void> toggleInMyBar(BarIngredient ingredient);
  Future<void> addBarIngredient(BarIngredient ingredient);
  Future<void> updateBarIngredient(BarIngredient ingredient);
  Future<void> deleteBarIngredient(BarIngredient ingredient);
  Future<List<String>> recipeNamesForIngredient(String ingredientName);

  /// Cocktail recipes that list [ingredientName] (for navigation from My Bar).
  Future<List<Recipe>> cocktailsUsingIngredient(String ingredientName);
  Future<void> recordPurchase(
    BarIngredient ingredient, {
    required double price,
    required String place,
    String? priceUnit,
    String? notes,
  });
}
