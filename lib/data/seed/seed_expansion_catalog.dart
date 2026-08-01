import 'seed_bar_ingredients.dart';
import 'seed_pantry_ingredients.dart';

/// Single call site for catalog/ingredient packs that need to catch up on
/// every launch, not just first install - bar/pantry ingredients diff-insert
/// any new hardcoded rows (e.g. a later addition like Baileys/pomegranate)
/// and re-run their sync/patch passes every time. Invoked from
/// `DatabaseService.runDeferredSeeds()` after first navigation (RT1).
///
/// Recipe expansion packs (cocktails import, menus import, coverage
/// cocktails) are NOT here - they're already seeded exactly once, on first
/// install/factory reset, from inside `seed_recipes.dart` (called via
/// `seedBundledData()`). Do not call them a second time from here - that was
/// a pre-existing dead-code redundancy (always a guaranteed no-op) that this
/// consolidation removes rather than perpetuates.
Future<void> seedExpansionCatalog(String defaultBoatSupabaseId) async {
  await seedBarIngredients();
  await seedPantryIngredients();
}
