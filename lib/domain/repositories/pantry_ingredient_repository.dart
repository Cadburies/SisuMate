import '../../models/models.dart';

abstract class PantryIngredientRepository {
  Stream<List<PantryIngredient>> watchPantryIngredients();
  Future<void> toggleInMyPantry(PantryIngredient ingredient);
  Future<void> addPantryIngredient(PantryIngredient ingredient);
  Future<void> updatePantryIngredient(PantryIngredient ingredient);
  Future<void> deletePantryIngredient(PantryIngredient ingredient);
  Future<List<String>> recipeNamesForIngredient(String ingredientName);

  /// Menu recipes that list [ingredientName] (for navigation from My Pantry).
  Future<List<Recipe>> menusUsingIngredient(String ingredientName);
  Future<void> recordPurchase(
    PantryIngredient ingredient, {
    required double price,
    required String place,
    String? priceUnit,
    String? notes,
  });
}
