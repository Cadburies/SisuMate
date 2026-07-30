import 'package:drift/drift.dart';

import '../../models/models.dart';
import '../drift/app_database.dart';
import '../repositories/recipe_repository_impl.dart';
import 'cocktail_image_assets.dart';
import 'cocktail_tags.dart';
import 'recipe_drift_seed.dart';

/// Prefix for bar-catalog coverage cocktails (`cocktail_cov_…`).
///
/// Ensures every bundled bar ingredient is used in **≥2** cocktail recipes
/// (ingredient detail would otherwise show "Not used in any cocktail").
const coverageCocktailIdPrefix = 'cocktail_cov_';

/// Seeds coverage cocktails when missing (idempotent — safe every launch).
Future<void> seedCoverageCocktails(String defaultBoatSupabaseId) async {
  final db = AppDatabase.instance;
  final existing = {
    for (final r in await (db.select(db.recipes)
          ..where((t) => t.supabaseId.like('$coverageCocktailIdPrefix%')))
        .get())
      r.supabaseId
  };

  final recipes = <Recipe>[];
  final ingredients = <RecipeIngredient>[];

  void cocktail({
    required String idSuffix,
    required String name,
    required String description,
    required String instructions,
    required String glassware,
    required List<(String name, double? qty, String? unit, {bool garnish})>
        ings,
    int prepMinutes = 5,
    String? story,
  }) {
    final id = '$coverageCocktailIdPrefix$idSuffix';
    if (existing.contains(id)) return;

    recipes.add(
      Recipe()
        ..supabaseId = id
        ..boatSupabaseId = defaultBoatSupabaseId
        ..name = name
        ..description = description
        ..instructions = instructions
        ..recipeType = 'cocktail'
        ..isBundled = true
        ..isFavourite = isSeededFavouriteName(name)
        ..glassware = glassware
        ..prepMinutes = prepMinutes
        ..story = story
        ..imageAsset =
            cocktailImageAssetFor(name: name, glassware: glassware),
    );

    for (var i = 0; i < ings.length; i++) {
      final (ingName, qty, unit, garnish: isGarnish) = ings[i];
      ingredients.add(
        RecipeIngredient()
          ..supabaseId =
              'ing_${id}_${ingName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}_$i'
          ..recipeSupabaseId = id
          ..name = ingName
          ..quantity = isGarnish ? null : qty
          ..unit = isGarnish ? null : unit
          ..isGarnish = isGarnish
          ..sortOrder = i,
      );
    }
  }

  // ── Spirits / rums that had 0 catalog cocktail uses ─────────────────────

  cocktail(
    idSuffix: 'ti_punch',
    name: "Ti' Punch",
    description: 'Martinique classic — agricole, lime, sugar',
    instructions:
        'Build in a rocks glass over ice cubes. Squeeze lime, add sugar or syrup, then agricole. Swizzle briefly.',
    glassware: 'Rocks glass',
    ings: [
      ('Light Agricole Rum', 50, 'ml', garnish: false),
      ('Simple Syrup', 10, 'ml', garnish: false),
      ('Lime Wedges', null, null, garnish: true),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'agricole_swizzle',
    name: 'Agricole Swizzle',
    description: 'Gold agricole with falernum and crushed ice',
    instructions:
        'Build in a tall glass with crushed ice, swizzle until frosty, top with more ice.',
    glassware: 'Highball glass',
    ings: [
      ('Gold Agricole Rum', 45, 'ml', garnish: false),
      ('Falernum Syrup', 15, 'ml', garnish: false),
      ('Fresh Lime Juice', 20, 'ml', garnish: false),
      ('Crushed Ice', null, null, garnish: false),
      ('Dehydrated Lime Wheel', null, null, garnish: true),
    ],
  );
  cocktail(
    idSuffix: 'dark_agricole_punch',
    name: 'Dark Agricole Punch',
    description: 'Aged agricole with pineapple syrup and spice',
    instructions: 'Shake with ice, strain over crushed ice, garnish with cinnamon.',
    glassware: 'Tiki mug',
    ings: [
      ('Dark Agricole Rum', 45, 'ml', garnish: false),
      ('Pineapple Syrup', 20, 'ml', garnish: false),
      ('Fresh Lime Juice', 20, 'ml', garnish: false),
      ('Cinnamon Sticks', null, null, garnish: true),
      ('Crushed Ice', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'jamaican_swizzle',
    name: 'Jamaican Swizzle',
    description: 'Pot-still Jamaican rum swizzle with falernum',
    instructions: 'Swizzle pot-still rum, falernum, lime over crushed ice.',
    glassware: 'Highball glass',
    ings: [
      ('Pot Still Jamaican Rum', 45, 'ml', garnish: false),
      ('Falernum Syrup', 15, 'ml', garnish: false),
      ('Fresh Lime Juice', 20, 'ml', garnish: false),
      ('Ground Cinnamon', null, null, garnish: true),
      ('Crushed Ice', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'gold_rum_ginger',
    name: 'Gold Rum Ginger Highball',
    description: 'Gold blended rum and ginger ale',
    instructions: 'Build over ice cubes, top with ginger ale, lime wedge.',
    glassware: 'Highball glass',
    ings: [
      ('Gold Blended Rum', 50, 'ml', garnish: false),
      ('Ginger Ale', 120, 'ml', garnish: false),
      ('Lime Wedges', null, null, garnish: true),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'overproof_cola',
    name: 'Overproof Rum & Cola',
    description: 'Dark overproof blended rum with cola',
    instructions: 'Build over ice, top with cola, squeeze lime.',
    glassware: 'Highball glass',
    ings: [
      ('Dark Overproof Blended Rum', 40, 'ml', garnish: false),
      ('Cola (Coke)', 120, 'ml', garnish: false),
      ('Lime Wedges', null, null, garnish: true),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'overproof_swizzle',
    name: 'Overproof Swizzle',
    description: 'Dark overproof rum with pineapple syrup',
    instructions: 'Swizzle over crushed ice with pineapple syrup and lime.',
    glassware: 'Tiki mug',
    ings: [
      ('Dark Overproof Blended Rum', 30, 'ml', garnish: false),
      ('Gold Blended Rum', 20, 'ml', garnish: false),
      ('Pineapple Syrup', 15, 'ml', garnish: false),
      ('Fresh Lime Juice', 20, 'ml', garnish: false),
      ('Dehydrated Lime Wheel', null, null, garnish: true),
      ('Crushed Ice', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'pot_still_punch',
    name: 'Pot Still Fruit Punch',
    description: 'Jamaican pot still with tropical juices',
    instructions: 'Shake with ice, strain over ice cubes, fruit skewer garnish.',
    glassware: 'Rocks glass',
    ings: [
      ('Pot Still Jamaican Rum', 40, 'ml', garnish: false),
      ('Passion Fruit Juice', 30, 'ml', garnish: false),
      ('Mango Juice', 20, 'ml', garnish: false),
      ('Fresh Lime Juice', 15, 'ml', garnish: false),
      ('Fresh Fruit Skewers', null, null, garnish: true),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'light_agricole_tonic',
    name: 'Agricole & Tonic',
    description: 'Light agricole highball with tonic',
    instructions: 'Build over ice, top with tonic, lime wedge.',
    glassware: 'Highball glass',
    ings: [
      ('Light Agricole Rum', 45, 'ml', garnish: false),
      ('Tonic Water', 120, 'ml', garnish: false),
      ('Lime Wedges', null, null, garnish: true),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'gold_agricole_cola',
    name: 'Gold Agricole Cola',
    description: 'Gold agricole with cola and lime',
    instructions: 'Build over ice, top with cola.',
    glassware: 'Highball glass',
    ings: [
      ('Gold Agricole Rum', 45, 'ml', garnish: false),
      ('Cola (Coke)', 120, 'ml', garnish: false),
      ('Lime Wedges', null, null, garnish: true),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'dark_agricole_ginger',
    name: 'Dark Agricole Ginger',
    description: 'Dark agricole and ginger ale',
    instructions: 'Build over ice, top with ginger ale, cinnamon stick.',
    glassware: 'Highball glass',
    ings: [
      ('Dark Agricole Rum', 45, 'ml', garnish: false),
      ('Ginger Ale', 120, 'ml', garnish: false),
      ('Cinnamon Sticks', null, null, garnish: true),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );

  // ── Whiskey / tequila / arrack ────────────────────────────────────────────

  cocktail(
    idSuffix: 'irish_coffee',
    name: 'Irish Coffee',
    description: 'Irish whiskey, hot coffee, cream float',
    instructions:
        'Warm glass, add whiskey and sugar, fill with hot coffee, float lightly whipped cream.',
    glassware: 'Irish coffee glass',
    ings: [
      ('Irish Whiskey', 40, 'ml', garnish: false),
      ('Simple Syrup', 10, 'ml', garnish: false),
      ('Ground Cinnamon', null, null, garnish: true),
    ],
  );
  cocktail(
    idSuffix: 'irish_ginger',
    name: 'Irish Ginger Highball',
    description: 'Irish whiskey and ginger ale',
    instructions: 'Build over ice cubes, top with ginger ale, lime wedge.',
    glassware: 'Highball glass',
    ings: [
      ('Irish Whiskey', 50, 'ml', garnish: false),
      ('Ginger Ale', 120, 'ml', garnish: false),
      ('Lime Wedges', null, null, garnish: true),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'reposado_paloma',
    name: 'Reposado Paloma',
    description: 'Reposado tequila highball with grapefruit and salt rim',
    instructions: 'Salt the rim, build over ice, top with soda/juice blend.',
    glassware: 'Highball glass',
    ings: [
      ('Reposado Tequila', 50, 'ml', garnish: false),
      ('Grapefruit Juice', 60, 'ml', garnish: false),
      ('Soda Water', 60, 'ml', garnish: false),
      ('Fresh Lime Juice', 15, 'ml', garnish: false),
      ('Kosher Salt', null, null, garnish: true),
      ('Lime Wedges', null, null, garnish: true),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'reposado_margarita',
    name: 'Reposado Margarita',
    description: 'Reposado tequila margarita with sugar or salt rim option',
    instructions: 'Shake with ice, strain into salt- or sugar-rimmed glass.',
    glassware: 'Rocks glass',
    ings: [
      ('Reposado Tequila', 50, 'ml', garnish: false),
      ('Triple Sec', 20, 'ml', garnish: false),
      ('Fresh Lime Juice', 25, 'ml', garnish: false),
      ('Sugar (for rimming)', null, null, garnish: true),
      ('Kosher Salt', null, null, garnish: true),
      ('Lime Wedges', null, null, garnish: true),
    ],
  );
  cocktail(
    idSuffix: 'arrack_punch',
    name: 'Batavia Arrack Punch',
    description: 'Batavia arrack with tropical juices',
    instructions: 'Shake, strain over ice, fruit skewer garnish.',
    glassware: 'Punch glass',
    ings: [
      ('Batavia Arrack', 45, 'ml', garnish: false),
      ('Papaya Juice', 30, 'ml', garnish: false),
      ('Passion Fruit Juice', 20, 'ml', garnish: false),
      ('Fresh Lemon Juice', 15, 'ml', garnish: false),
      ('Simple Syrup', 10, 'ml', garnish: false),
      ('Fresh Fruit Skewers', null, null, garnish: true),
    ],
  );
  cocktail(
    idSuffix: 'arrack_cola',
    name: 'Arrack Cola',
    description: 'Batavia arrack highball with cola',
    instructions: 'Build over ice, top with cola, lime.',
    glassware: 'Highball glass',
    ings: [
      ('Batavia Arrack', 45, 'ml', garnish: false),
      ('Cola (Coke)', 120, 'ml', garnish: false),
      ('Lime Wedges', null, null, garnish: true),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );

  // ── Liqueurs ──────────────────────────────────────────────────────────────

  cocktail(
    idSuffix: 'blue_hawaiian',
    name: 'Blue Hawaiian',
    description: 'Blue curaçao tropical classic',
    instructions: 'Shake with ice, strain over crushed ice, pineapple garnish.',
    glassware: 'Hurricane glass',
    ings: [
      ('White Blended Rum', 30, 'ml', garnish: false),
      ('Blue Curaçao', 15, 'ml', garnish: false),
      ('Pineapple Juice', 60, 'ml', garnish: false),
      ('Cream of Coconut', 20, 'ml', garnish: false),
      ('Pineapple Spears', null, null, garnish: true),
      ('Crushed Ice', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'blue_lagoon',
    name: 'Blue Lagoon',
    description: 'Vodka and blue curaçao highball',
    instructions: 'Build over ice, top with lemonade or soda.',
    glassware: 'Highball glass',
    ings: [
      ('Vodka', 40, 'ml', garnish: false),
      ('Blue Curaçao', 20, 'ml', garnish: false),
      ('Fresh Lemon Juice', 15, 'ml', garnish: false),
      ('Soda Water', 80, 'ml', garnish: false),
      ('Dehydrated Lime Wheel', null, null, garnish: true),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'white_russian',
    name: 'White Russian',
    description: 'Vodka, coffee liqueur, cream',
    instructions: 'Build vodka and Kahlúa over ice, float cream.',
    glassware: 'Rocks glass',
    ings: [
      ('Vodka', 40, 'ml', garnish: false),
      ('Kahlúa', 20, 'ml', garnish: false),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'black_russian',
    name: 'Black Russian',
    description: 'Vodka and coffee liqueur',
    instructions: 'Build over ice cubes and stir.',
    glassware: 'Rocks glass',
    ings: [
      ('Vodka', 45, 'ml', garnish: false),
      ('Kahlúa', 20, 'ml', garnish: false),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'tia_maria_coffee',
    name: 'Tia Maria Coffee',
    description: 'Tia Maria in a coffee highball style serve',
    instructions: 'Build Tia Maria over ice with cola or coffee soda style mix.',
    glassware: 'Rocks glass',
    ings: [
      ('Tia Maria', 40, 'ml', garnish: false),
      ('Cola (Coke)', 80, 'ml', garnish: false),
      ('Ice Cubes', null, null, garnish: false),
      ('Ground Cinnamon', null, null, garnish: true),
    ],
  );
  cocktail(
    idSuffix: 'tia_maria_milk',
    name: 'Tia Maria Milk Punch',
    description: 'Tia Maria with cream and nutmeg',
    instructions: 'Shake with ice, strain over ice cubes.',
    glassware: 'Rocks glass',
    ings: [
      ('Tia Maria', 40, 'ml', garnish: false),
      ('Simple Syrup', 10, 'ml', garnish: false),
      ('Freshly Grated Nutmeg', null, null, garnish: true),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'mudslide',
    name: 'Mudslide',
    description: 'Baileys, Kahlúa, vodka cream cocktail',
    instructions: 'Shake with ice, strain into a chilled glass or over ice.',
    glassware: 'Coupe',
    ings: [
      ('Vodka', 30, 'ml', garnish: false),
      ('Baileys Irish Cream', 30, 'ml', garnish: false),
      ('Kahlúa', 30, 'ml', garnish: false),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'b52',
    name: 'B-52',
    description: 'Layered shot — coffee liqueur, Baileys, orange liqueur',
    instructions: 'Layer carefully in a shot glass: Kahlúa, then Baileys, then triple sec.',
    glassware: 'Shot glass',
    prepMinutes: 3,
    ings: [
      ('Kahlúa', 20, 'ml', garnish: false),
      ('Baileys Irish Cream', 20, 'ml', garnish: false),
      ('Triple Sec', 20, 'ml', garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'baileys_on_rocks',
    name: 'Baileys on the Rocks',
    description: 'Simple Irish cream over ice',
    instructions: 'Pour Baileys over ice cubes; optional cinnamon dust.',
    glassware: 'Rocks glass',
    prepMinutes: 1,
    ings: [
      ('Baileys Irish Cream', 60, 'ml', garnish: false),
      ('Ice Cubes', null, null, garnish: false),
      ('Ground Cinnamon', null, null, garnish: true),
    ],
  );
  cocktail(
    idSuffix: 'fuzzy_navel',
    name: 'Fuzzy Navel',
    description: 'Peach schnapps and orange juice',
    instructions: 'Build over ice cubes and stir.',
    glassware: 'Highball glass',
    ings: [
      ('Peach Schnapps', 45, 'ml', garnish: false),
      ('Orange Juice', 90, 'ml', garnish: false),
      ('Orange Slices', null, null, garnish: true),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'sex_on_the_beach',
    name: 'Sex on the Beach',
    description: 'Vodka, peach schnapps, juices',
    instructions: 'Build over ice, top with juices.',
    glassware: 'Highball glass',
    ings: [
      ('Vodka', 40, 'ml', garnish: false),
      ('Peach Schnapps', 20, 'ml', garnish: false),
      ('Cranberry Juice', 40, 'ml', garnish: false),
      ('Orange Juice', 40, 'ml', garnish: false),
      ('Fresh Fruit Skewers', null, null, garnish: true),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'french_martini',
    name: 'French Martini',
    description: 'Vodka, Chambord, pineapple',
    instructions: 'Shake hard with ice, strain into a coupe.',
    glassware: 'Coupe',
    ings: [
      ('Vodka', 45, 'ml', garnish: false),
      ('Chambord', 15, 'ml', garnish: false),
      ('Pineapple Juice', 45, 'ml', garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'kir_royale_chambord',
    name: 'Chambord Royale',
    description: 'Chambord topped with sparkling wine',
    instructions: 'Chambord in flute, top with champagne or prosecco.',
    glassware: 'Flute',
    ings: [
      ('Chambord', 15, 'ml', garnish: false),
      ('Champagne', 120, 'ml', garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'hugo',
    name: 'Hugo',
    description: 'St-Germain spritz with mint and lime',
    instructions: 'Build in wine glass over ice, top with prosecco and soda.',
    glassware: 'Wine glass',
    ings: [
      ('St-Germain Elderflower', 30, 'ml', garnish: false),
      ('Prosecco', 90, 'ml', garnish: false),
      ('Soda Water', 30, 'ml', garnish: false),
      ('Fresh Mint', null, null, garnish: true),
      ('Lime Wedges', null, null, garnish: true),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'elderflower_gin',
    name: 'Elderflower Gin Fizz',
    description: 'Gin with St-Germain and tonic',
    instructions: 'Build over ice, top with tonic.',
    glassware: 'Highball glass',
    ings: [
      ('Gin', 40, 'ml', garnish: false),
      ('St-Germain Elderflower', 20, 'ml', garnish: false),
      ('Tonic Water', 100, 'ml', garnish: false),
      ('Lime Wedges', null, null, garnish: true),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'pom_margarita',
    name: 'Pomegranate Margarita',
    description: 'Tequila margarita with pomegranate liqueur',
    instructions: 'Shake with ice, strain into salt-rimmed glass.',
    glassware: 'Rocks glass',
    ings: [
      ('Blanco Tequila', 45, 'ml', garnish: false),
      ('Pomegranate Liqueur', 20, 'ml', garnish: false),
      ('Fresh Lime Juice', 25, 'ml', garnish: false),
      ('Simple Syrup', 10, 'ml', garnish: false),
      ('Kosher Salt', null, null, garnish: true),
      ('Lime Wedges', null, null, garnish: true),
    ],
  );
  cocktail(
    idSuffix: 'pom_martini',
    name: 'Pomegranate Martini',
    description: 'Vodka martini with pomegranate liqueur',
    instructions: 'Shake with ice, strain into a chilled coupe.',
    glassware: 'Coupe',
    ings: [
      ('Vodka', 45, 'ml', garnish: false),
      ('Pomegranate Liqueur', 20, 'ml', garnish: false),
      ('Fresh Lemon Juice', 15, 'ml', garnish: false),
      ('Simple Syrup', 10, 'ml', garnish: false),
      ('Sugar (for rimming)', null, null, garnish: true),
    ],
  );
  cocktail(
    idSuffix: 'amarula_milk',
    name: 'Amarula Cream',
    description: 'Amarula over ice',
    instructions: 'Pour over ice cubes; optional cinnamon.',
    glassware: 'Rocks glass',
    prepMinutes: 1,
    ings: [
      ('Amarula', 60, 'ml', garnish: false),
      ('Ice Cubes', null, null, garnish: false),
      ('Ground Cinnamon', null, null, garnish: true),
    ],
  );
  cocktail(
    idSuffix: 'amarula_coffee',
    name: 'Amarula Coffee',
    description: 'Amarula with coffee-style cola build',
    instructions: 'Build Amarula over ice with a splash of cola.',
    glassware: 'Rocks glass',
    ings: [
      ('Amarula', 40, 'ml', garnish: false),
      ('Cola (Coke)', 60, 'ml', garnish: false),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'singapore_sling',
    name: "Singapore Sling (Yacht)",
    description: 'Gin sling with Bénédictine and fruit',
    instructions: 'Shake, strain over ice, top with soda.',
    glassware: 'Highball glass',
    ings: [
      ('Gin', 30, 'ml', garnish: false),
      ('Bénédictine', 15, 'ml', garnish: false),
      ('Grenadine', 15, 'ml', garnish: false),
      ('Fresh Lemon Juice', 15, 'ml', garnish: false),
      ('Pineapple Juice', 60, 'ml', garnish: false),
      ('Soda Water', 30, 'ml', garnish: false),
      ('Fresh Fruit Skewers', null, null, garnish: true),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'bobby_burns',
    name: 'Bobby Burns',
    description: 'Scotch and Bénédictine stirred classic',
    instructions: 'Stir with ice, strain into a coupe.',
    glassware: 'Coupe',
    ings: [
      ('Scotch Whisky', 45, 'ml', garnish: false),
      ('Sweet Vermouth', 20, 'ml', garnish: false),
      ('Bénédictine', 10, 'ml', garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'last_word',
    name: 'Last Word',
    description: 'Gin equal-parts with Chartreuse and maraschino',
    instructions: 'Shake hard with ice, strain into a coupe.',
    glassware: 'Coupe',
    ings: [
      ('Gin', 22, 'ml', garnish: false),
      ('Chartreuse', 22, 'ml', garnish: false),
      ('Maraschino Liqueur', 22, 'ml', garnish: false),
      ('Fresh Lime Juice', 22, 'ml', garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'bijou',
    name: 'Bijou',
    description: 'Gin, Chartreuse, sweet vermouth',
    instructions: 'Stir with ice, strain into a coupe.',
    glassware: 'Coupe',
    ings: [
      ('Gin', 30, 'ml', garnish: false),
      ('Chartreuse', 30, 'ml', garnish: false),
      ('Sweet Vermouth', 30, 'ml', garnish: false),
      ('Orange Bitters', 1, 'dash', garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'marsala_flip',
    name: 'Marsala Flip',
    description: 'Sweet Marsala wine flip',
    instructions: 'Dry shake, then shake with ice; strain and grate nutmeg.',
    glassware: 'Coupe',
    ings: [
      ('Marsala Wine', 60, 'ml', garnish: false),
      ('Simple Syrup', 10, 'ml', garnish: false),
      ('Egg White', 30, 'ml', garnish: false),
      ('Freshly Grated Nutmeg', null, null, garnish: true),
    ],
  );
  cocktail(
    idSuffix: 'marsala_spritz',
    name: 'Marsala Spritz',
    description: 'Marsala highball with soda',
    instructions: 'Build Marsala over ice, top with soda, orange slice.',
    glassware: 'Wine glass',
    ings: [
      ('Marsala Wine', 60, 'ml', garnish: false),
      ('Soda Water', 90, 'ml', garnish: false),
      ('Orange Slices', null, null, garnish: true),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );

  // ── Juices / syrups / garnish-heavy seconds ───────────────────────────────

  cocktail(
    idSuffix: 'passion_cola',
    name: 'Passion Cola Cooler',
    description: 'Passion fruit juice highball with ginger ale',
    instructions: 'Build juices over ice, top with ginger ale.',
    glassware: 'Highball glass',
    ings: [
      ('Passion Fruit Juice', 60, 'ml', garnish: false),
      ('Ginger Ale', 90, 'ml', garnish: false),
      ('Fresh Lime Juice', 15, 'ml', garnish: false),
      ('Fresh Fruit Skewers', null, null, garnish: true),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'mango_daiquiri',
    name: 'Mango Daiquiri',
    description: 'Rum daiquiri with mango juice',
    instructions: 'Shake with ice, strain into a coupe or over crushed ice.',
    glassware: 'Coupe',
    ings: [
      ('White Blended Rum', 45, 'ml', garnish: false),
      ('Mango Juice', 30, 'ml', garnish: false),
      ('Fresh Lime Juice', 20, 'ml', garnish: false),
      ('Simple Syrup', 10, 'ml', garnish: false),
      ('Dehydrated Lime Wheel', null, null, garnish: true),
    ],
  );
  cocktail(
    idSuffix: 'papaya_cooler',
    name: 'Papaya Cooler',
    description: 'Papaya juice highball with tonic',
    instructions: 'Build over ice, top with tonic.',
    glassware: 'Highball glass',
    ings: [
      ('Papaya Juice', 80, 'ml', garnish: false),
      ('Tonic Water', 80, 'ml', garnish: false),
      ('Fresh Lime Juice', 15, 'ml', garnish: false),
      ('Fresh Fruit Skewers', null, null, garnish: true),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'cinnamon_toddy_cold',
    name: 'Cinnamon Rum Cooler',
    description: 'Rum with pineapple syrup and cinnamon stick',
    instructions: 'Build over ice, stir, garnish with cinnamon stick.',
    glassware: 'Rocks glass',
    ings: [
      ('Dark Blended Rum', 45, 'ml', garnish: false),
      ('Pineapple Syrup', 15, 'ml', garnish: false),
      ('Fresh Lemon Juice', 15, 'ml', garnish: false),
      ('Cinnamon Sticks', null, null, garnish: true),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'sugar_rim_sidecar',
    name: 'Sugar-Rim Sidecar Style',
    description: 'Brandy citrus with a sugar rim',
    instructions: 'Rim glass with sugar, shake, strain.',
    glassware: 'Coupe',
    ings: [
      ('Brandy', 45, 'ml', garnish: false),
      ('Triple Sec', 20, 'ml', garnish: false),
      ('Fresh Lemon Juice', 20, 'ml', garnish: false),
      ('Sugar (for rimming)', null, null, garnish: true),
    ],
  );

  // ── Second recipes for ingredients that only had 1 cocktail ───────────────

  cocktail(
    idSuffix: 'demerara_float_daiquiri',
    name: 'Demerara Float Daiquiri',
    description: 'Lime daiquiri with overproof Demerara float',
    instructions: 'Shake white rum, lime, syrup; strain; float overproof Demerara.',
    glassware: 'Coupe',
    ings: [
      ('White Blended Rum', 45, 'ml', garnish: false),
      ('Fresh Lime Juice', 20, 'ml', garnish: false),
      ('Simple Syrup', 15, 'ml', garnish: false),
      ('Overproof Demerara Rum', 10, 'ml', garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'pot_still_daiquiri',
    name: 'Overproof Pot Still Daiquiri',
    description: 'Fierce Jamaican overproof daiquiri',
    instructions: 'Shake hard with ice, strain into a coupe.',
    glassware: 'Coupe',
    ings: [
      ('Overproof Pot Still Rum', 40, 'ml', garnish: false),
      ('Fresh Lime Juice', 20, 'ml', garnish: false),
      ('Simple Syrup', 15, 'ml', garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'spiced_rum_cola',
    name: 'Spiced Rum Cola',
    description: 'Spiced rum and cola highball',
    instructions: 'Build over ice, top with cola, lime wedge.',
    glassware: 'Highball glass',
    ings: [
      ('Spiced Rum', 50, 'ml', garnish: false),
      ('Cola (Coke)', 120, 'ml', garnish: false),
      ('Lime Wedges', null, null, garnish: true),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'pisco_punch',
    name: 'Pisco Punch Light',
    description: 'Pisco with pineapple and lemon',
    instructions: 'Shake, strain over ice.',
    glassware: 'Rocks glass',
    ings: [
      ('Pisco', 50, 'ml', garnish: false),
      ('Pineapple Juice', 40, 'ml', garnish: false),
      ('Fresh Lemon Juice', 15, 'ml', garnish: false),
      ('Simple Syrup', 10, 'ml', garnish: false),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'amaretto_sour',
    name: 'Amaretto Sour',
    description: 'Amaretto, lemon, optional egg white',
    instructions: 'Shake (dry then wet if using egg white), strain over ice.',
    glassware: 'Rocks glass',
    ings: [
      ('Amaretto', 45, 'ml', garnish: false),
      ('Fresh Lemon Juice', 25, 'ml', garnish: false),
      ('Simple Syrup', 10, 'ml', garnish: false),
      ('Egg White', 20, 'ml', garnish: false),
      ('Maraschino Cherries', null, null, garnish: true),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'peach_brandy_fix',
    name: 'Peach Brandy Fix',
    description: 'Peach brandy sour with crushed ice',
    instructions: 'Shake, strain over crushed ice.',
    glassware: 'Rocks glass',
    ings: [
      ('Peach Brandy', 45, 'ml', garnish: false),
      ('Fresh Lemon Juice', 20, 'ml', garnish: false),
      ('Simple Syrup', 15, 'ml', garnish: false),
      ('Crushed Ice', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'aperol_spritz',
    name: 'Aperol Spritz',
    description: 'Aperol, prosecco, soda',
    instructions: 'Build in wine glass over ice: Aperol, prosecco, soda.',
    glassware: 'Wine glass',
    ings: [
      ('Aperol', 60, 'ml', garnish: false),
      ('Prosecco', 90, 'ml', garnish: false),
      ('Soda Water', 30, 'ml', garnish: false),
      ('Orange Slices', null, null, garnish: true),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'fernet_cola',
    name: 'Fernet & Cola',
    description: 'Argentine classic — Fernet-Branca and cola',
    instructions: 'Build Fernet over ice, top with cola.',
    glassware: 'Highball glass',
    ings: [
      ('Fernet-Branca', 40, 'ml', garnish: false),
      ('Cola (Coke)', 120, 'ml', garnish: false),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'fernet_old_fashioned',
    name: 'Fernet Old Fashioned',
    description: 'Fernet-Branca stirred with demerara and bitters',
    instructions: 'Stir Fernet, syrup, and bitters over ice; serve rocks.',
    glassware: 'Rocks glass',
    ings: [
      ('Fernet-Branca', 45, 'ml', garnish: false),
      ('Demerara Syrup', 10, 'ml', garnish: false),
      ('Angostura Bitters', 2, 'dash', garnish: false),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'coconut_water_highball',
    name: 'Coconut Water Highball',
    description: 'White rum with coconut water',
    instructions: 'Build over ice, top with coconut water, lime.',
    glassware: 'Highball glass',
    ings: [
      ('White Blended Rum', 45, 'ml', garnish: false),
      ('Coconut Water', 120, 'ml', garnish: false),
      ('Lime Wedges', null, null, garnish: true),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'paper_plane_twin',
    name: 'Paper Plane Variation',
    description: 'Bourbon equal-parts with Amaro Nonino and Aperol',
    instructions: 'Shake equal parts, strain into a coupe.',
    glassware: 'Coupe',
    ings: [
      ('Bourbon', 22, 'ml', garnish: false),
      ('Amaro Nonino', 22, 'ml', garnish: false),
      ('Aperol', 22, 'ml', garnish: false),
      ('Fresh Lemon Juice', 22, 'ml', garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'ancho_paloma',
    name: 'Ancho Paloma',
    description: 'Tequila Paloma with Ancho Reyes',
    instructions: 'Build over ice with grapefruit and soda; float ancho.',
    glassware: 'Highball glass',
    ings: [
      ('Blanco Tequila', 40, 'ml', garnish: false),
      ('Ancho Reyes Chile Liqueur', 15, 'ml', garnish: false),
      ('Grapefruit Juice', 60, 'ml', garnish: false),
      ('Soda Water', 60, 'ml', garnish: false),
      ('Lime Wedges', null, null, garnish: true),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'jack_rose',
    name: 'Jack Rose',
    description: 'Applejack sour with grenadine',
    instructions: 'Shake with ice, strain into a coupe.',
    glassware: 'Coupe',
    ings: [
      ('Applejack', 50, 'ml', garnish: false),
      ('Fresh Lemon Juice', 20, 'ml', garnish: false),
      ('Grenadine', 15, 'ml', garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'calvados_sidecar',
    name: 'Calvados Sidecar',
    description: 'Apple brandy sidecar',
    instructions: 'Shake with ice, strain into a sugar-rimmed coupe.',
    glassware: 'Coupe',
    ings: [
      ('Calvados', 45, 'ml', garnish: false),
      ('Triple Sec', 20, 'ml', garnish: false),
      ('Fresh Lemon Juice', 20, 'ml', garnish: false),
      ('Sugar (for rimming)', null, null, garnish: true),
    ],
  );
  cocktail(
    idSuffix: 'bramble',
    name: 'Bramble',
    description: 'Gin sour with crème de mûre drizzle',
    instructions: 'Shake gin, lemon, syrup; strain over crushed ice; drizzle mûre.',
    glassware: 'Rocks glass',
    ings: [
      ('Gin', 45, 'ml', garnish: false),
      ('Fresh Lemon Juice', 20, 'ml', garnish: false),
      ('Simple Syrup', 10, 'ml', garnish: false),
      ('Crème de Mûre', 15, 'ml', garnish: false),
      ('Crushed Ice', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'pink_squirrel_2',
    name: 'Pink Squirrel Twin',
    description: 'Crème de noyaux cream cocktail',
    instructions: 'Shake with ice, strain into a coupe.',
    glassware: 'Coupe',
    ings: [
      ('Crème de Noyaux', 30, 'ml', garnish: false),
      ('White Crème de Cacao', 30, 'ml', garnish: false),
      ('Baileys Irish Cream', 30, 'ml', garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'grasshopper_2',
    name: 'Grasshopper Twin',
    description: 'Mint chocolate cream cocktail',
    instructions: 'Shake with ice, strain into a coupe.',
    glassware: 'Coupe',
    ings: [
      ('Green Crème de Menthe', 30, 'ml', garnish: false),
      ('White Crème de Cacao', 30, 'ml', garnish: false),
      ('Baileys Irish Cream', 30, 'ml', garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'stinger_2',
    name: 'Stinger Twin',
    description: 'Brandy and white crème de menthe',
    instructions: 'Stir with ice, strain into a rocks glass over ice.',
    glassware: 'Rocks glass',
    ings: [
      ('Brandy', 50, 'ml', garnish: false),
      ('White Crème de Menthe', 20, 'ml', garnish: false),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'rusty_nail_2',
    name: 'Rusty Nail Twin',
    description: 'Scotch and Drambuie',
    instructions: 'Build over ice and stir.',
    glassware: 'Rocks glass',
    ings: [
      ('Scotch Whisky', 45, 'ml', garnish: false),
      ('Drambuie', 25, 'ml', garnish: false),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'harvey_wallbanger',
    name: 'Harvey Wallbanger',
    description: 'Vodka screwdriver with Galliano float',
    instructions: 'Build vodka and OJ over ice; float Galliano.',
    glassware: 'Highball glass',
    ings: [
      ('Vodka', 45, 'ml', garnish: false),
      ('Orange Juice', 90, 'ml', garnish: false),
      ('Galliano', 15, 'ml', garnish: false),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'molasses_rum_old',
    name: 'Molasses Rum Old Fashioned',
    description: 'Rum old fashioned with molasses syrup',
    instructions: 'Stir rum, molasses syrup, bitters over ice.',
    glassware: 'Rocks glass',
    ings: [
      ('Dark Blended Rum', 50, 'ml', garnish: false),
      ('Molasses Syrup', 10, 'ml', garnish: false),
      ('Angostura Bitters', 2, 'dash', garnish: false),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'ramos_light',
    name: 'Ramos Light',
    description: 'Gin fizz notes with orange flower water',
    instructions: 'Shake hard with ice (and egg white if using), strain, top soda.',
    glassware: 'Highball glass',
    ings: [
      ('Gin', 45, 'ml', garnish: false),
      ('Fresh Lemon Juice', 15, 'ml', garnish: false),
      ('Fresh Lime Juice', 15, 'ml', garnish: false),
      ('Simple Syrup', 20, 'ml', garnish: false),
      ('Orange Flower Water', 3, 'dash', garnish: false),
      ('Egg White', 20, 'ml', garnish: false),
      ('Soda Water', 30, 'ml', garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'pecan_old_fashioned',
    name: 'Pecan Old Fashioned',
    description: 'Bourbon with pecan liqueur',
    instructions: 'Stir over ice, serve in rocks glass.',
    glassware: 'Rocks glass',
    ings: [
      ('Bourbon', 45, 'ml', garnish: false),
      ('Pecan Liqueur', 15, 'ml', garnish: false),
      ('Angostura Bitters', 2, 'dash', garnish: false),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'port_wine_sangaree',
    name: 'Port Wine Sangaree',
    description: 'Ruby port highball with nutmeg',
    instructions: 'Build port over ice, top with soda, grate nutmeg.',
    glassware: 'Highball glass',
    ings: [
      ('Ruby Port', 60, 'ml', garnish: false),
      ('Soda Water', 60, 'ml', garnish: false),
      ('Freshly Grated Nutmeg', null, null, garnish: true),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'rosemary_gin_fizz',
    name: 'Rosemary Gin Fizz',
    description: 'Gin fizz with rosemary syrup',
    instructions: 'Shake gin, lemon, rosemary syrup; strain over ice; top soda.',
    glassware: 'Highball glass',
    ings: [
      ('Gin', 45, 'ml', garnish: false),
      ('Rosemary Syrup', 20, 'ml', garnish: false),
      ('Fresh Lemon Juice', 20, 'ml', garnish: false),
      ('Soda Water', 60, 'ml', garnish: false),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'sherry_cobbler',
    name: 'Sweet Sherry Cobbler',
    description: 'Sweet sherry over crushed ice with fruit',
    instructions: 'Build sherry over crushed ice, garnish with fruit.',
    glassware: 'Highball glass',
    ings: [
      ('Sweet Sherry', 90, 'ml', garnish: false),
      ('Simple Syrup', 10, 'ml', garnish: false),
      ('Orange Slices', null, null, garnish: true),
      ('Fresh Fruit Skewers', null, null, garnish: true),
      ('Crushed Ice', null, null, garnish: false),
    ],
  );
  cocktail(
    idSuffix: 'penicillin_twin',
    name: 'Penicillin Twin',
    description: 'Scotch sour with honey-ginger syrup',
    instructions: 'Shake scotch, lemon, honey-ginger; strain over ice; optional Islay float.',
    glassware: 'Rocks glass',
    ings: [
      ('Scotch Whisky', 50, 'ml', garnish: false),
      ('Fresh Lemon Juice', 20, 'ml', garnish: false),
      ('Honey-Ginger Syrup', 20, 'ml', garnish: false),
      ('Ice Cubes', null, null, garnish: false),
    ],
  );

  if (recipes.isEmpty) return;

  await seedRecipesToDrift(recipes);
  await seedRecipeIngredientsToDrift(ingredients);
  await RecipeRepositoryImpl(AppDatabase.instance).syncMissingIngredientCounts();
}
