import '../models/models.dart';
import 'recipe_allergen_service.dart';
import 'trip_schedule.dart';

// Index 1 = Mon .. 7 = Sun, matching Dart's DateTime.weekday directly (index 0 unused).
const isoWeekdayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String _mealLabel(String mealType) =>
    mealType.isEmpty ? '' : mealType[0].toUpperCase() + mealType.substring(1);

/// A plan's `dayOffset` is relative to its own `startDate`, which can be any
/// weekday and any trip length — never assume dayOffset 0 is a Monday.
String provisionDayMealLabel(MealPlan plan, MealPlanSlot slot) {
  final date = plan.startDate.add(Duration(days: slot.dayOffset));
  return '${isoWeekdayNames[date.weekday]} ${_mealLabel(slot.mealType)}';
}

String _qtyLabel(double? quantity, String? unit) => quantity == null
    ? ''
    : '${quantity % 1 == 0 ? quantity.toInt() : quantity.toStringAsFixed(1)}'
        '${unit != null && unit.isNotEmpty ? ' $unit' : ''}';

class ProvisionItem {
  final String name;
  final double? quantity;
  final String? unit;
  const ProvisionItem(this.name, this.quantity, this.unit);

  /// e.g. "Garlic: 11 cloves"
  String get formatted {
    final qtyLabel = _qtyLabel(quantity, unit);
    return qtyLabel.isEmpty ? name : '$name: $qtyLabel';
  }
}

/// One or more occurrences of the same protein/seafood ingredient (by name +
/// unit) across the plan's slots. Kept separate from consolidated items
/// because per-portion proteins shouldn't be silently summed into a single
/// total — but repeats of the *same* dish (e.g. seabass served twice) should
/// still read as "2 × 24 fillets", not two identical-looking lines.
class PortionedGroup {
  final String name;
  final String? unit;
  final List<double?> quantities; // one per occurrence, same order as [notes]
  final List<String> notes; // day/meal label per occurrence
  const PortionedGroup({
    required this.name,
    required this.unit,
    required this.quantities,
    required this.notes,
  });

  int get count => quantities.length;

  bool get _isUniform =>
      quantities.isEmpty || quantities.every((q) => q == quantities.first);

  /// - Single occurrence: "Sirloin Steak × 2 (Thu Dinner)"
  /// - Repeats, same quantity: "Fresh Sea Bass — 2 × 24 fillets (Mon Breakfast, Wed Dinner)"
  /// - Repeats, differing quantity: "Fresh Sea Bass — 24 fillets (Mon Breakfast), 12 fillets (Wed Dinner)"
  String get formatted {
    if (count <= 1) {
      final qtyLabel = _qtyLabel(quantities.first, unit);
      final qtyPart = qtyLabel.isEmpty ? '' : ' × $qtyLabel';
      return '$name$qtyPart (${notes.first})';
    }
    if (_isUniform) {
      final qtyLabel = _qtyLabel(quantities.first, unit);
      final qtyPart = qtyLabel.isEmpty ? '' : ' $count × $qtyLabel';
      return '$name —$qtyPart (${notes.join(', ')})';
    }
    final entries = List.generate(count, (i) {
      final qtyLabel = _qtyLabel(quantities[i], unit);
      return '${qtyLabel.isEmpty ? name : qtyLabel} (${notes[i]})';
    });
    return '$name — ${entries.join(', ')}';
  }
}

class ProvisionResult {
  final List<String> allergenWarnings;
  final List<PortionedGroup> portionedItems;
  final List<ProvisionItem> consolidatedItems;
  const ProvisionResult({
    required this.allergenWarnings,
    required this.portionedItems,
    required this.consolidatedItems,
  });
}

/// Fresh meat/poultry/fish/seafood is rarely a stocked PantryIngredient (the
/// pantry seed only tracks shelf-stable goods), so `category == 'protein'`
/// alone misses almost every real protein ingredient. This name-keyword list
/// is the fallback for ingredients with no pantry match.
const _proteinKeywords = [
  'steak', 'beef', 'pork', 'lamb', 'veal', 'venison', 'sausage', 'bacon',
  'ham', 'chicken', 'turkey', 'duck', 'fish', 'salmon', 'tuna', 'cod',
  'snapper', 'bass', 'halibut', 'mackerel', 'trout', 'sardine', 'anchov',
  'shrimp', 'prawn', 'crab', 'lobster', 'mussel', 'clam', 'oyster',
  'scallop', 'calamari', 'squid', 'octopus',
];

bool _isProteinIngredient(String name, PantryIngredient? pantryMatch) {
  if (pantryMatch?.category.toLowerCase() == 'protein') return true;
  final lower = name.toLowerCase();
  return _proteinKeywords.any(lower.contains);
}

/// Turns a MealPlan's assigned recipe slots into a guest-count-scaled
/// provision list. Proteins (fish/meat/poultry) are grouped separately by
/// name + unit so repeats of the same dish read as "N × qty" rather than
/// duplicate lines; everything else is summed across all meals by ingredient
/// name + unit. Flags recipes whose derived allergens conflict with any of
/// the plan's selected guest profiles.
class ProvisionCalculator {
  static ProvisionResult compute({
    required MealPlan plan,
    required Map<String, List<RecipeIngredient>> ingredientsByRecipe,
    required List<PantryIngredient> pantry,
    required List<GuestProfile> profiles,
  }) {
    final restrictedAllergens = profiles
        .where((p) => plan.guestProfileIds.contains(p.id))
        .expand((p) => p.allergenRestrictions)
        .toSet();
    final pantryByName = {
      for (final p in pantry) p.name.toLowerCase().trim(): p,
    };

    final allergenWarnings = <String>[];
    final portioned = <String, PortionedGroup>{};
    final consolidated = <String, ProvisionItem>{};

    for (final slot in plan.slots) {
      if (slot.recipeSupabaseId.isEmpty) continue;
      // Skip slots that no longer correspond to a valid day/meal-type combo
      // for this plan (e.g. legacy data from before flexible trip lengths,
      // or a day dropped by shortening the trip) — they're invisible in the
      // grid, so they shouldn't silently inflate the provision list either.
      if (slot.dayOffset < 0 || slot.dayOffset >= plan.numberOfDays) continue;
      if (!mealTypesForDay(slot.dayOffset, plan.numberOfDays)
          .contains(slot.mealType)) {
        continue;
      }
      final ingredients = ingredientsByRecipe[slot.recipeSupabaseId] ?? [];

      if (restrictedAllergens.isNotEmpty) {
        final assessment = RecipeAllergenService.assess(ingredients, pantry);
        final conflicts =
            assessment.allergens.intersection(restrictedAllergens);
        if (conflicts.isNotEmpty) {
          allergenWarnings.add(
              '${slot.recipeName} (${provisionDayMealLabel(plan, slot)}): contains ${conflicts.join(', ')}');
        }
      }

      for (final ing in ingredients) {
        final scaledQty =
            ing.quantity != null ? ing.quantity! * plan.guestCount : null;
        final pantryMatch = pantryByName[ing.name.toLowerCase().trim()];
        final isProtein = _isProteinIngredient(ing.name, pantryMatch);

        if (isProtein) {
          final key = '${ing.name.toLowerCase().trim()}|${ing.unit ?? ''}';
          final existing = portioned[key];
          final note = provisionDayMealLabel(plan, slot);
          portioned[key] = existing == null
              ? PortionedGroup(
                  name: ing.name,
                  unit: ing.unit,
                  quantities: [scaledQty],
                  notes: [note])
              : PortionedGroup(
                  name: existing.name,
                  unit: existing.unit,
                  quantities: [...existing.quantities, scaledQty],
                  notes: [...existing.notes, note]);
        } else {
          final key = '${ing.name.toLowerCase().trim()}|${ing.unit ?? ''}';
          final existing = consolidated[key];
          if (existing == null) {
            consolidated[key] = ProvisionItem(ing.name, scaledQty, ing.unit);
          } else if (scaledQty != null && existing.quantity != null) {
            consolidated[key] = ProvisionItem(
                ing.name, existing.quantity! + scaledQty, ing.unit);
          }
        }
      }
    }

    final portionedItems = portioned.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final consolidatedItems = consolidated.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return ProvisionResult(
      allergenWarnings: allergenWarnings,
      portionedItems: portionedItems,
      consolidatedItems: consolidatedItems,
    );
  }
}
