import '../models/models.dart';

// ── Data types ────────────────────────────────────────────────────────────────

class SuggestedIngredient {
  final String name;
  final double quantity;
  final String unit;
  final bool optional;
  const SuggestedIngredient(this.name, this.quantity, this.unit, {this.optional = false});
}

class CocktailSuggestion {
  final String name;
  final List<SuggestedIngredient> ingredients;
  final String instructions;
  final String rationale;
  final String technique; // shake | stir | build | blend

  const CocktailSuggestion({
    required this.name,
    required this.ingredients,
    required this.instructions,
    required this.rationale,
    required this.technique,
  });
}

class DishSuggestion {
  final String name;
  final List<SuggestedIngredient> ingredients;
  final String instructions;
  final String rationale;
  final String cuisine;

  const DishSuggestion({
    required this.name,
    required this.ingredients,
    required this.instructions,
    required this.rationale,
    required this.cuisine,
  });
}

// ── Static flavor knowledge ───────────────────────────────────────────────────

// Fallback flavor profiles for ingredients that don't have them set yet
const _barDefaults = <String, (String cat, List<String> flavors)>{
  'dark rum': ('spirit', ['tropical', 'sweet', 'funky', 'rich']),
  'light rum': ('spirit', ['tropical', 'fresh', 'sweet']),
  'white rum': ('spirit', ['fresh', 'sweet', 'light']),
  'aged rum': ('spirit', ['tropical', 'sweet', 'rich', 'vanilla']),
  'spiced rum': ('spirit', ['spiced', 'sweet', 'tropical']),
  'bourbon': ('spirit', ['sweet', 'vanilla', 'caramel', 'spirit-forward']),
  'rye whiskey': ('spirit', ['spiced', 'dry', 'spirit-forward']),
  'scotch whisky': ('spirit', ['smoky', 'peaty', 'spirit-forward']),
  'irish whiskey': ('spirit', ['light', 'smooth', 'sweet']),
  'gin': ('spirit', ['herbal', 'botanical', 'fresh', 'floral', 'citrus']),
  'vodka': ('spirit', ['neutral', 'clean', 'fresh']),
  'blanco tequila': ('spirit', ['fresh', 'citrus', 'vegetal']),
  'reposado tequila': ('spirit', ['sweet', 'spiced', 'citrus']),
  'mezcal': ('spirit', ['smoky', 'earthy', 'funky']),
  'cognac': ('spirit', ['fruity', 'floral', 'rich', 'sweet']),
  'pisco': ('spirit', ['fresh', 'floral', 'fruity']),
  'triple sec': ('liqueur', ['citrus', 'sweet', 'orange']),
  'cointreau': ('liqueur', ['citrus', 'sweet', 'orange', 'floral']),
  'campari': ('liqueur', ['bitter', 'sweet', 'herbal', 'aperitif']),
  'aperol': ('liqueur', ['bitter', 'sweet', 'orange', 'aperitif']),
  'orgeat': ('syrup', ['sweet', 'nutty', 'almond', 'tropical']),
  'simple syrup': ('syrup', ['sweet', 'neutral']),
  'demerara syrup': ('syrup', ['sweet', 'rich', 'molasses']),
  'honey syrup': ('syrup', ['sweet', 'floral', 'warm']),
  'grenadine': ('syrup', ['sweet', 'fruity', 'berry']),
  'velvet falernum': ('liqueur', ['sweet', 'spiced', 'tropical', 'tiki']),
  'allspice dram': ('liqueur', ['spiced', 'warm', 'tiki']),
  'fresh lime juice': ('juice', ['sour', 'citrus', 'fresh', 'tart']),
  'fresh lemon juice': ('juice', ['sour', 'citrus', 'fresh', 'tart']),
  'pineapple juice': ('juice', ['tropical', 'sweet', 'fruity']),
  'grapefruit juice': ('juice', ['citrus', 'tart', 'bitter']),
  'orange juice': ('juice', ['sweet', 'citrus', 'fruity']),
  'angostura bitters': ('bitters', ['bitter', 'spiced', 'aromatic']),
  "peychaud's bitters": ('bitters', ['bitter', 'anise', 'floral']),
  'orange bitters': ('bitters', ['bitter', 'citrus', 'aromatic']),
  'ginger beer': ('mixer', ['spicy', 'sweet', 'fresh', 'fizzy']),
  'soda water': ('mixer', ['neutral', 'fizzy']),
  'tonic water': ('mixer', ['bitter', 'fresh', 'fizzy']),
  'prosecco': ('wine', ['light', 'fresh', 'fruity', 'fizzy']),
  'sweet vermouth': ('wine', ['sweet', 'herbal', 'bitter', 'aromatic']),
  'coconut cream': ('syrup', ['tropical', 'sweet', 'rich', 'creamy']),
  'cream of coconut': ('syrup', ['tropical', 'sweet', 'rich', 'creamy']),
};

const _pantryDefaults = <String, (String cat, List<String> flavors, List<String> cuisines)>{
  'garlic': ('vegetable', ['pungent', 'savory', 'aromatic', 'umami'], ['Italian', 'Mediterranean', 'Asian']),
  'onion': ('vegetable', ['savory', 'sweet', 'aromatic'], ['General']),
  'shallots': ('vegetable', ['sweet', 'mild', 'aromatic'], ['French', 'Asian']),
  'fresh ginger': ('vegetable', ['spicy', 'warm', 'aromatic', 'fresh'], ['Asian', 'Caribbean']),
  'extra virgin olive oil': ('oil', ['rich', 'fruity', 'savory'], ['Italian', 'Mediterranean']),
  'butter': ('dairy', ['rich', 'creamy', 'sweet'], ['French', 'European']),
  'soy sauce': ('sauce', ['salty', 'umami', 'savory', 'dark'], ['Asian']),
  'fish sauce': ('sauce', ['salty', 'umami', 'funky', 'savory'], ['Thai', 'Vietnamese']),
  'canned chopped tomatoes': ('tinned', ['sweet', 'sour', 'savory', 'umami'], ['Italian', 'Mediterranean']),
  'pasta': ('grain', ['neutral', 'starchy'], ['Italian']),
  'basmati rice': ('grain', ['neutral', 'fragrant', 'light'], ['Indian', 'Asian']),
  'coconut milk': ('tinned', ['sweet', 'rich', 'creamy', 'tropical'], ['Asian', 'Thai', 'Caribbean']),
  'eggs': ('dairy', ['rich', 'savory', 'creamy'], ['General']),
  'heavy cream': ('dairy', ['rich', 'creamy', 'sweet'], ['French']),
  'parmesan': ('dairy', ['salty', 'umami', 'nutty', 'sharp'], ['Italian']),
  'fresh basil': ('herb', ['herbal', 'sweet', 'fresh', 'aromatic'], ['Italian', 'Mediterranean']),
  'fresh parsley': ('herb', ['fresh', 'herbal', 'light'], ['Mediterranean']),
  'miso paste': ('condiment', ['umami', 'salty', 'savory', 'funky'], ['Japanese']),
  'tahini': ('condiment', ['nutty', 'bitter', 'rich'], ['Mediterranean', 'Middle Eastern']),
  'honey': ('sweetener', ['sweet', 'floral', 'warm'], ['Mediterranean']),
  'lentils (red)': ('grain', ['earthy', 'savory', 'mild'], ['Indian', 'Middle Eastern']),
  'canned chickpeas': ('tinned', ['earthy', 'savory', 'mild'], ['Mediterranean', 'Middle Eastern']),
  'dijon mustard': ('condiment', ['sharp', 'tangy', 'savory'], ['French']),
  'capers': ('condiment', ['salty', 'sour', 'briny'], ['Italian', 'Mediterranean']),
  'anchovies': ('condiment', ['salty', 'umami', 'funky', 'rich'], ['Italian', 'Mediterranean']),
};

// ── Cocktail flavor direction rules ──────────────────────────────────────────

// Preferred categories and flavor tags per desired vibe
const _vibeToFlavors = <String, List<String>>{
  'tropical': ['tropical', 'fruity', 'sweet', 'citrus'],
  'tiki': ['tropical', 'spiced', 'funky', 'sweet', 'tiki'],
  'fresh': ['fresh', 'citrus', 'light', 'herbal'],
  'citrus': ['citrus', 'sour', 'fresh', 'bright'],
  'sour': ['sour', 'tart', 'citrus', 'bright'],
  'smoky': ['smoky', 'earthy', 'funky'],
  'bitter': ['bitter', 'aperitif', 'herbal'],
  'spirit-forward': ['spirit-forward', 'rich', 'warm'],
  'floral': ['floral', 'aromatic', 'fresh', 'light'],
  'herbal': ['herbal', 'botanical', 'aromatic'],
  'spiced': ['spiced', 'warm', 'aromatic'],
  'fizzy': ['fizzy', 'fresh', 'light'],
};

// Which cocktail template to use for each vibe
const _vibeTechnique = <String, String>{
  'tropical': 'shake',
  'tiki': 'shake',
  'fresh': 'shake',
  'citrus': 'shake',
  'sour': 'shake',
  'smoky': 'stir',
  'bitter': 'build',
  'spirit-forward': 'stir',
  'floral': 'shake',
  'herbal': 'shake',
  'spiced': 'stir',
  'fizzy': 'build',
};

// Creative name parts keyed by vibe
const _vibeAdjectives = <String, List<String>>{
  'tropical': ['Tropic', 'Caribbean', 'Island', 'Tiki', 'Sunset', 'Horizon', 'Palm'],
  'tiki': ['Tiki', 'Polynesian', 'Reef', 'Aloha', 'Lagoon', 'Coral'],
  'fresh': ['Spring', 'Garden', 'Morning', 'Clear', 'Alpine', 'Crisp'],
  'citrus': ['Citrus', 'Bright', 'Zesty', 'Golden', 'Grove', 'Sunny'],
  'sour': ['Sharp', 'Nimble', 'Lively', 'Zesty', 'Perky', 'Brisk'],
  'smoky': ['Ember', 'Dusk', 'Storm', 'Dark', 'Haze', 'Shadow'],
  'bitter': ['Aperitivo', 'Dusk', 'Negroni', 'Campo', 'Piazza', 'Milano'],
  'spirit-forward': ['Classic', 'Reserve', 'Stirred', 'Old', 'Noble', 'Quiet'],
  'floral': ['Garden', 'Bloom', 'Petal', 'Meadow', 'Spring', 'Rose'],
  'herbal': ['Botanica', 'Verdant', 'Sage', 'Herbal', 'Alpine', 'Forest'],
  'spiced': ['Spiced', 'Autumn', 'Warm', 'Harvest', 'Cinnamon', 'Chai'],
  'fizzy': ['Sparkling', 'Fizzy', 'Bubbling', 'Light', 'Breezy', 'Airy'],
};

const _spiritNouns = <String, List<String>>{
  'rum': ['Sling', 'Punch', 'Fizz', 'Swizzle', 'Fix', 'Breeze'],
  'gin': ['Fizz', 'Rickey', 'Sling', 'Smash', 'Collins', 'Breeze'],
  'vodka': ['Mule', 'Cooler', 'Breeze', 'Crush', 'Fix', 'Fizz'],
  'tequila': ['Margarita', 'Paloma', 'Sour', 'Smash', 'Fizz'],
  'mezcal': ['Smash', 'Sour', 'Fix', 'Highball', 'Negroni'],
  'whiskey': ['Sour', 'Smash', 'Old Fashioned', 'Highball', 'Fix'],
  'bourbon': ['Sour', 'Smash', 'Fix', 'Old Fashioned', 'Cooler'],
  'cognac': ['Sidecar', 'Sour', 'Fix', 'Sling', 'Royale'],
  'default': ['Cooler', 'Smash', 'Fix', 'Sling', 'Punch', 'Sour'],
};

// ── Cocktail suggestion engine ────────────────────────────────────────────────

class MixologistService {
  static String _category(BarIngredient i) {
    if (i.category.isNotEmpty) return i.category;
    final lower = i.name.toLowerCase();
    return _barDefaults[lower]?.$1 ?? 'unknown';
  }

  static List<String> _flavors(BarIngredient i) {
    if (i.flavorProfiles.isNotEmpty) return i.flavorProfiles;
    final lower = i.name.toLowerCase();
    return _barDefaults[lower]?.$2 ?? [];
  }

  static int _flavorScore(List<String> ingredientFlavors, List<String> desired) {
    var score = 0;
    for (final f in ingredientFlavors) {
      if (desired.contains(f)) score++;
    }
    return score;
  }

  static String _spiritKey(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('rum')) return 'rum';
    if (lower.contains('gin')) return 'gin';
    if (lower.contains('vodka')) return 'vodka';
    if (lower.contains('tequila')) return 'tequila';
    if (lower.contains('mezcal')) return 'mezcal';
    if (lower.contains('bourbon')) return 'bourbon';
    if (lower.contains('whiskey') || lower.contains('whisky')) return 'whiskey';
    if (lower.contains('cognac') || lower.contains('brandy')) return 'cognac';
    return 'default';
  }

  static String _generateName(
      String spirit, String vibe, List<SuggestedIngredient> ingredients) {
    final adjs = _vibeAdjectives[vibe] ?? ['Classic'];
    final nouns = _spiritNouns[_spiritKey(spirit)] ?? _spiritNouns['default']!;
    // Use ingredient count as a deterministic seed so it's stable per combo
    final seed = ingredients.length % adjs.length;
    return '${adjs[seed]} ${nouns[seed % nouns.length]}';
  }

  static String _buildInstructions(String technique, List<SuggestedIngredient> ingredients) {
    final ingList = ingredients
        .where((i) => !i.optional)
        .map((i) => '${i.quantity}${i.unit} ${i.name}')
        .join(', ');

    switch (technique) {
      case 'stir':
        return 'Combine $ingList in a mixing glass with ice. Stir for 30 seconds. Strain into a chilled glass.';
      case 'build':
        return 'Fill a glass with ice. Add $ingList in order. Stir gently to combine.';
      case 'blend':
        return 'Add $ingList to a blender with a cup of crushed ice. Blend until smooth. Pour into a glass.';
      default:
        return 'Combine $ingList in a cocktail shaker with ice. Shake vigorously for 12 seconds. Strain into a chilled glass.';
    }
  }

  // Spirit → food pairing hints (BC13)
  static const _spiritFoodPairings = <String, List<String>>{
    'rum': ['Jerk chicken', 'Grilled fish', 'Tropical fruit', 'Coconut rice'],
    'gin': ['Smoked salmon', 'Light seafood', 'Cucumber salad', 'Thai dishes'],
    'vodka': ['Caviar', 'Blinis', 'Pickled vegetables', 'Smoked fish'],
    'tequila': ['Tacos', 'Ceviche', 'Guacamole', 'Grilled corn'],
    'mezcal': ['Grilled meats', 'Charred vegetables', 'Aged cheese', 'Mole'],
    'bourbon': ['BBQ ribs', 'Smoked brisket', 'Pecan pie', 'Sharp cheddar'],
    'whiskey': ['Cheese board', 'Smoked meats', 'Dark chocolate', 'Roasted nuts'],
    'cognac': ['Foie gras', 'Creamy sauces', 'Dark chocolate', 'Blue cheese'],
  };

  static List<String> foodPairings(String spiritName) =>
      _spiritFoodPairings[_spiritKey(spiritName)] ??
      ['Light snacks', 'Cheese board', 'Fresh fruit'];

  // Occasion → extra vibes (BC14)
  static const occasionVibes = <String, List<String>>{
    'Summer': ['tropical', 'fresh', 'citrus', 'fizzy'],
    'Winter': ['spiced', 'spirit-forward', 'bitter'],
    'Date Night': ['floral', 'spirit-forward', 'herbal'],
    'BBQ': ['smoky', 'tropical', 'spiced'],
    'Game Night': ['fizzy', 'fresh', 'tiki'],
    'Christmas': ['spiced', 'bitter', 'floral'],
  };

  // Main cocktail suggestion method
  static CocktailSuggestion? suggest({
    required List<String> vibes,
    required List<BarIngredient> barIngredients,
  }) {
    final available = barIngredients.where((i) => i.inMyBar).toList();
    if (available.isEmpty) return null;

    // Build desired flavor list from vibes
    final desiredFlavors = <String>{};
    for (final v in vibes) {
      desiredFlavors.addAll(_vibeToFlavors[v] ?? []);
    }
    if (desiredFlavors.isEmpty) {
      desiredFlavors.addAll(['fresh', 'citrus', 'sweet']);
    }

    final technique = _vibeTechnique[vibes.firstOrNull] ?? 'shake';
    final desiredList = desiredFlavors.toList();

    // Categorise available ingredients
    final spirits = available.where((i) => _category(i) == 'spirit').toList();
    final juices = available.where((i) => _category(i) == 'juice').toList();
    final syrups = available.where((i) => _category(i) == 'syrup').toList();
    final liqueurs = available.where((i) => _category(i) == 'liqueur').toList();
    final bitters = available.where((i) => _category(i) == 'bitters').toList();
    final mixers = available.where((i) => _category(i) == 'mixer').toList();

    if (spirits.isEmpty) return null; // Need at least a spirit

    // Score and rank spirits
    spirits.sort((a, b) =>
        _flavorScore(_flavors(b), desiredList)
            .compareTo(_flavorScore(_flavors(a), desiredList)));
    final spirit = spirits.first;

    // Select acid — prefer sour/citrus juices that match vibe
    final acids = juices.where((j) {
      final f = _flavors(j);
      return f.contains('sour') || f.contains('citrus') || f.contains('tart');
    }).toList();
    acids.sort((a, b) =>
        _flavorScore(_flavors(b), desiredList)
            .compareTo(_flavorScore(_flavors(a), desiredList)));

    // Select sweet — prefer syrups matching vibe
    final sweets = [...syrups];
    sweets.addAll(liqueurs.where((l) => _flavors(l).contains('sweet')));
    sweets.sort((a, b) =>
        _flavorScore(_flavors(b), desiredList)
            .compareTo(_flavorScore(_flavors(a), desiredList)));

    // Select modifier — optional liqueur that adds complexity
    final modifiers = liqueurs
        .where((l) => l != (sweets.firstOrNull))
        .toList();
    modifiers.sort((a, b) =>
        _flavorScore(_flavors(b), desiredList)
            .compareTo(_flavorScore(_flavors(a), desiredList)));

    // Select fizz for build/fizzy vibes
    BarIngredient? fizz;
    if (technique == 'build' || vibes.contains('fizzy')) {
      final fizzOpts = mixers
          .where((m) => _flavors(m).contains('fizzy'))
          .toList();
      fizzOpts.sort((a, b) =>
          _flavorScore(_flavors(b), desiredList)
              .compareTo(_flavorScore(_flavors(a), desiredList)));
      fizz = fizzOpts.firstOrNull;
    }

    // Select bitters — optional
    final bitter = bitters.firstOrNull;

    // Build ingredient list
    final ingredients = <SuggestedIngredient>[
      SuggestedIngredient(spirit.name, 2.0, 'oz'),
    ];

    if (acids.isNotEmpty) {
      ingredients.add(SuggestedIngredient(acids.first.name, 0.75, 'oz'));
    }

    if (sweets.isNotEmpty) {
      ingredients.add(SuggestedIngredient(sweets.first.name, 0.75, 'oz'));
    }

    if (modifiers.isNotEmpty && modifiers.first != sweets.firstOrNull) {
      ingredients.add(
          SuggestedIngredient(modifiers.first.name, 0.5, 'oz', optional: true));
    }

    if (fizz != null) {
      ingredients.add(SuggestedIngredient(fizz.name, 2.0, 'oz'));
    }

    if (bitter != null) {
      ingredients.add(SuggestedIngredient(bitter.name, 2.0, 'dashes', optional: true));
    }

    final name = _generateName(spirit.name, vibes.firstOrNull ?? 'fresh', ingredients);

    final vibeLabel = vibes.join(', ');
    final rationale =
        'Built around ${spirit.name} to match your $vibeLabel vibe. '
        '${acids.isNotEmpty ? "${acids.first.name} adds brightness. " : ""}'
        '${sweets.isNotEmpty ? "${sweets.first.name} balances with sweetness." : ""}';

    return CocktailSuggestion(
      name: name,
      ingredients: ingredients,
      instructions: _buildInstructions(technique, ingredients),
      rationale: rationale,
      technique: technique,
    );
  }

  // ── Dish suggestion engine ──────────────────────────────────────────────────

  static String _pantryCategory(PantryIngredient i) {
    if (i.category.isNotEmpty) return i.category;
    final lower = i.name.toLowerCase();
    return _pantryDefaults[lower]?.$1 ?? 'unknown';
  }

  static List<String> _pantryFlavors(PantryIngredient i) {
    if (i.flavorProfiles.isNotEmpty) return i.flavorProfiles;
    final lower = i.name.toLowerCase();
    return _pantryDefaults[lower]?.$2 ?? [];
  }

  static const _cuisineVibes = <String, List<String>>{
    'italian': ['savory', 'umami', 'herbal', 'rich'],
    'asian': ['umami', 'savory', 'spicy', 'aromatic'],
    'mediterranean': ['savory', 'fresh', 'herbal', 'briny'],
    'light': ['fresh', 'light', 'herbal', 'bright'],
    'hearty': ['rich', 'savory', 'earthy', 'warm'],
    'comfort': ['rich', 'creamy', 'warm', 'savory'],
    'fresh': ['fresh', 'light', 'herbal', 'bright'],
    'spicy': ['spicy', 'hot', 'pungent', 'aromatic'],
    'umami': ['umami', 'savory', 'funky', 'rich'],
    'sweet & savory': ['sweet', 'savory', 'caramel', 'warm'],
  };

  static const _cuisineTemplates = <String, String>{
    'italian': 'Italian',
    'asian': 'Asian',
    'mediterranean': 'Mediterranean',
    'light': 'Light',
    'hearty': 'Hearty',
    'comfort': 'Comfort',
    'fresh': 'Fresh',
    'spicy': 'Spiced',
    'umami': 'Umami-Rich',
    'sweet & savory': 'Sweet & Savory',
  };

  static DishSuggestion? suggestDish({
    required List<String> vibes,
    required List<PantryIngredient> pantryIngredients,
    List<String> allergenRestrictions = const [],
    List<String> dietaryRequirements = const [],
  }) {
    var available = pantryIngredients.where((i) => i.inMyPantry).toList();
    // Exclude ingredients that contain a restricted allergen
    if (allergenRestrictions.isNotEmpty) {
      available = available
          .where((i) => i.allergenTags.every((a) => !allergenRestrictions.contains(a)))
          .toList();
    }
    // Exclude ingredients that don't satisfy required dietary tags (if any)
    if (dietaryRequirements.isNotEmpty) {
      available = available
          .where((i) => dietaryRequirements.every((d) => i.dietaryTags.contains(d)))
          .toList();
    }
    if (available.isEmpty) return null;

    final primaryVibe = vibes.firstOrNull ?? 'hearty';
    final desiredFlavors = <String>{};
    for (final v in vibes) {
      desiredFlavors.addAll(_cuisineVibes[v.toLowerCase()] ?? []);
    }
    if (desiredFlavors.isEmpty) {
      desiredFlavors.addAll(['savory', 'rich', 'warm']);
    }
    final desiredList = desiredFlavors.toList();
    final cuisineLabel = _cuisineTemplates[primaryVibe.toLowerCase()] ?? 'Sailor';

    // Categorise
    final proteins = available
        .where((i) => ['protein', 'dairy'].contains(_pantryCategory(i)) &&
            _pantryFlavors(i).any((f) => ['savory', 'rich', 'umami'].contains(f)))
        .toList();
    final grains =
        available.where((i) => _pantryCategory(i) == 'grain').toList();
    final oils = available.where((i) => _pantryCategory(i) == 'oil').toList();
    final aromatics = available
        .where((i) =>
            _pantryCategory(i) == 'vegetable' &&
            _pantryFlavors(i).any((f) => ['pungent', 'aromatic', 'savory'].contains(f)))
        .toList();
    final sauces = available
        .where((i) => ['sauce', 'condiment', 'tinned'].contains(_pantryCategory(i)))
        .toList();
    final herbs =
        available.where((i) => _pantryCategory(i) == 'herb').toList();
    final seasonings =
        available.where((i) => _pantryCategory(i) == 'seasoning').toList();

    // Score and rank by vibe match; expiring within 7 days gets a priority boost
    final now = DateTime.now();
    int score(PantryIngredient i) {
      final base = _flavorScore(_pantryFlavors(i), desiredList);
      if (i.expiryDate != null &&
          i.expiryDate!.isBefore(now.add(const Duration(days: 7)))) {
        return base + 100;
      }
      return base;
    }
    proteins.sort((a, b) => score(b).compareTo(score(a)));
    sauces.sort((a, b) => score(b).compareTo(score(a)));
    aromatics.sort((a, b) => score(b).compareTo(score(a)));

    final dishIngredients = <SuggestedIngredient>[];

    // Base oil or butter
    if (oils.isNotEmpty) {
      final oil = oils.first;
      dishIngredients.add(SuggestedIngredient(oil.name, 2.0, 'tbsp'));
    }

    // Primary aromatic
    if (aromatics.isNotEmpty) {
      dishIngredients.add(SuggestedIngredient(aromatics.first.name, 1.0, 'clove/piece'));
      if (aromatics.length > 1) {
        dishIngredients.add(SuggestedIngredient(aromatics[1].name, 1.0, 'piece'));
      }
    }

    // Protein or main ingredient
    if (proteins.isNotEmpty) {
      dishIngredients.add(SuggestedIngredient(proteins.first.name, 200.0, 'g'));
    }

    // Grain / starch
    if (grains.isNotEmpty) {
      final grain = grains.first;
      final qty = grain.name.toLowerCase().contains('rice') ? 150.0 : 200.0;
      final unit = grain.name.toLowerCase().contains('rice') ? 'g' : 'g';
      dishIngredients.add(SuggestedIngredient(grain.name, qty, unit));
    }

    // Sauce or tins
    if (sauces.isNotEmpty) {
      dishIngredients.add(SuggestedIngredient(sauces.first.name, 1.0, 'can/jar'));
      if (sauces.length > 1) {
        dishIngredients.add(SuggestedIngredient(sauces[1].name, 1.0, 'tbsp', optional: true));
      }
    }

    // Herbs
    if (herbs.isNotEmpty) {
      dishIngredients.add(
          SuggestedIngredient(herbs.first.name, 1.0, 'handful', optional: true));
    }

    // Seasonings
    final salt = seasonings.where((s) => s.name.toLowerCase().contains('salt')).firstOrNull;
    final pepper = seasonings.where((s) => s.name.toLowerCase().contains('pepper')).firstOrNull;
    if (salt != null) dishIngredients.add(SuggestedIngredient(salt.name, 0.0, 'to taste'));
    if (pepper != null) dishIngredients.add(SuggestedIngredient(pepper.name, 0.0, 'to taste'));

    if (dishIngredients.isEmpty) return null;

    // Generate name
    final proteinLabel = proteins.isNotEmpty ? proteins.first.name : 'Pantry';
    final dishName = '$cuisineLabel ${proteinLabel.split(' ').last}';

    final grainLabel = grains.isNotEmpty ? ' Serve with ${grains.first.name}.' : '';
    final instructions =
        'Heat oil in a pan over medium heat. Sauté aromatics until fragrant, about 2 minutes. '
        'Add main ingredients and cook through, about 8–12 minutes. '
        'Add sauce and simmer for 5 minutes. Season to taste. '
        '${herbs.isNotEmpty ? "Finish with fresh ${herbs.first.name}. " : ""}'
        '$grainLabel';

    final vibeLabel = vibes.join(', ');
    final rationale =
        'A $vibeLabel dish built from what\'s in your pantry. '
        '${aromatics.isNotEmpty ? "${aromatics.first.name} builds the aromatic base. " : ""}'
        '${sauces.isNotEmpty ? "${sauces.first.name} adds depth and character." : ""}';

    return DishSuggestion(
      name: dishName,
      ingredients: dishIngredients,
      instructions: instructions,
      rationale: rationale,
      cuisine: cuisineLabel,
    );
  }
}
