import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../core/di.dart';

// Service is replaced by Repository usage

final shoppingCategoriesProvider = StreamProvider<List<ShoppingCategory>>((
  ref,
) {
  final repository = ref.watch(shoppingRepositoryProvider);
  return repository.watchCategories();
});

final shoppingItemsByCategoryProvider =
    StreamProvider.family<List<ShoppingItem>, String>((ref, categoryId) {
      final repository = ref.watch(shoppingRepositoryProvider);
      return repository.watchItems(categoryId);
    });

/// Recipe ingredient lines for every meal-plan slot (BAI2 meal-need scoring).
final mealPlanIngredientsMapProvider =
    FutureProvider<Map<String, List<RecipeIngredient>>>((ref) async {
  final plans = await ref.watch(mealPlansProvider.future);
  final repo = ref.watch(recipeRepositoryProvider);
  final ids = <String>{};
  for (final p in plans) {
    for (final s in p.slots) {
      if (s.recipeSupabaseId.isNotEmpty) ids.add(s.recipeSupabaseId);
    }
  }
  final map = <String, List<RecipeIngredient>>{};
  for (final id in ids) {
    map[id] = await repo.getIngredientsOnce(id);
  }
  return map;
});

// Re-export userSettingsProvider from di.dart to avoid breaking changes if imported from here
// Actually, better to import from di.dart in UI.

final activeBoatProvider = FutureProvider<Boat?>((ref) async {
  final settings = await ref.watch(userSettingsProvider.future);
  final boatId = settings?.activeBoatSupabaseId;
  if (boatId == null || boatId.isEmpty) return null;
  return ref.read(boatRepositoryProvider).getBoatById(boatId);
});
