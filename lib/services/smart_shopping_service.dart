import '../models/models.dart';
import 'seasonal_service.dart';

/// One shopping line with a passage-priority score and human reasons (BAI2).
class RankedShoppingItem {
  final ShoppingItem item;
  /// Higher = buy sooner before passage.
  final int score;
  final List<String> reasons;

  const RankedShoppingItem({
    required this.item,
    required this.score,
    required this.reasons,
  });
}

/// BAI2: rank open shopping lines using pantry, meal plan, season, prices.
///
/// Pure offline rules — no network. Safe to call from UI with current Drift
/// snapshots.
class SmartShoppingService {
  const SmartShoppingService();

  /// Prioritized “buy before passage” list (unbought, non-hidden first).
  ///
  /// Scoring (additive):
  /// - Needed by an active meal plan recipe: +100
  /// - Matching pantry item not in My Pantry: +60
  /// - Matching pantry item expired / expiring ≤7d: +50
  /// - Name matches in-season produce: +40
  /// - Critical origin (engine / deck / safety-ish spares): +25
  /// - Has a known last price (budget-aware): +10
  /// - Quantity weight: +min(qty, 5)
  static List<RankedShoppingItem> rankForPassage({
    required List<ShoppingItem> items,
    List<PantryIngredient> pantry = const [],
    List<MealPlan> mealPlans = const [],
    Map<String, List<RecipeIngredient>> ingredientsByRecipe = const {},
    List<String>? inSeasonNames,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now().toUtc();
    final season = (inSeasonNames ?? SeasonalService.getInSeasonNow())
        .map((s) => s.toLowerCase().trim())
        .toList();

    final pantryByName = <String, PantryIngredient>{
      for (final p in pantry) p.name.toLowerCase().trim(): p,
    };

    // Names required by any meal-plan slot with a recipe. Plans that have
    // already fully elapsed don't need re-provisioning, so they're excluded
    // — otherwise a finished trip's ingredients would inflate priority
    // forever.
    final mealNeed = <String>{};
    for (final plan in mealPlans) {
      final ends = plan.startDate.add(Duration(days: plan.numberOfDays));
      if (ends.isBefore(at)) continue;
      for (final slot in plan.slots) {
        if (slot.recipeSupabaseId.isEmpty) continue;
        if (slot.dayOffset < 0 || slot.dayOffset >= plan.numberOfDays) {
          continue;
        }
        final ings = ingredientsByRecipe[slot.recipeSupabaseId] ?? const [];
        for (final ing in ings) {
          final n = ing.name.toLowerCase().trim();
          if (n.isNotEmpty) mealNeed.add(n);
        }
      }
    }

    final ranked = <RankedShoppingItem>[];
    for (final item in items) {
      if (item.isHidden) continue;
      if (item.isBought) {
        // Still include bought at the bottom for stable list APIs; score 0.
        ranked.add(RankedShoppingItem(
          item: item,
          score: 0,
          reasons: const ['Already bought'],
        ));
        continue;
      }

      var score = 0;
      final reasons = <String>[];
      final name = item.name.toLowerCase().trim();

      // Meal plan need (substring either way for "tomatoes" / "cherry tomatoes").
      if (mealNeed.isNotEmpty &&
          mealNeed.any((m) => name.contains(m) || m.contains(name))) {
        score += 100;
        reasons.add('On meal plan');
      }

      final pantryMatch = pantryByName[name] ??
          pantryByName.entries
              .where((e) => name.contains(e.key) || e.key.contains(name))
              .map((e) => e.value)
              .firstOrNull;

      if (pantryMatch != null) {
        if (!pantryMatch.inMyPantry) {
          score += 60;
          reasons.add('Not in pantry');
        }
        final exp = pantryMatch.expiryDate?.toUtc();
        if (exp != null) {
          final days = exp.difference(at).inDays;
          if (days < 0) {
            score += 50;
            reasons.add('Pantry stock expired');
          } else if (days <= 7) {
            score += 50;
            reasons.add('Pantry stock expires soon');
          }
        }
      } else if (item.origin == 'galley') {
        // Galley line with no pantry catalog match still matters for trips.
        score += 20;
        reasons.add('Galley provision');
      }

      if (season.any((s) => name.contains(s) || s.contains(name))) {
        score += 40;
        reasons.add('In season now');
      }

      final origin = item.origin.toLowerCase();
      if (origin == 'engine' || origin == 'deck' || origin == 'spares') {
        score += 25;
        reasons.add('Boat-critical ($origin)');
      }

      if (item.lastPurchasePrice != null && item.lastPurchasePrice! > 0) {
        score += 10;
        reasons.add('Price on file');
      }

      final q = item.quantity < 1 ? 1 : item.quantity;
      score += q > 5 ? 5 : q;

      if (reasons.isEmpty) {
        reasons.add('Open shopping line');
      }

      ranked.add(RankedShoppingItem(
        item: item,
        score: score,
        reasons: reasons,
      ));
    }

    ranked.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      // Tie-break: higher unit price first (don't forget expensive bits).
      final pa = a.item.lastPurchasePrice ?? 0;
      final pb = b.item.lastPurchasePrice ?? 0;
      final byPrice = pb.compareTo(pa);
      if (byPrice != 0) return byPrice;
      return a.item.name.toLowerCase().compareTo(b.item.name.toLowerCase());
    });

    return ranked;
  }
}
