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

// Re-export userSettingsProvider from di.dart to avoid breaking changes if imported from here
// Actually, better to import from di.dart in UI.

final activeBoatProvider = FutureProvider<Boat?>((ref) async {
  final settings = await ref.watch(userSettingsProvider.future);
  final boatId = settings?.activeBoatSupabaseId;
  if (boatId == null || boatId.isEmpty) return null;
  return ref.read(boatRepositoryProvider).getBoatById(boatId);
});
