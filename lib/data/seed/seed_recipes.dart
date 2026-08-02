import '../../models/models.dart';
import '../drift/app_database.dart';
import '../repositories/recipe_repository_impl.dart';
import 'cocktail_image_assets.dart';
import 'cocktail_tags.dart';
import 'recipe_drift_seed.dart';
import 'seed_cocktails_import.dart';
import 'seed_coverage_cocktails.dart';
import 'seed_menus_import.dart';

/// Seeds classic cocktails, menus, syrups, and expansion packs.
///
/// Called on **first install and factory reset only** (via [seedBundledData]),
/// not on every healthy restart - so bar/pantry stock and user favourites
/// survive normal app restarts. Purges known classic bundled ids then inserts
/// current source (images, tags, seed favourites, metric ingredients).
Future<void> seedRecipes(String defaultBoatSupabaseId) async {
  // -- Purge classic bundled recipes so a factory reseed is clean -----------
  const seededCocktailIds = [
    'cocktail_mai_tai', 'cocktail_zombie', 'cocktail_painkiller',
    'cocktail_navy_grog', 'cocktail_suffering_bastard', 'cocktail_fog_cutter',
    'cocktail_scorpion_bowl', 'cocktail_three_dots_and_a_dash',
    'cocktail_missionarys_downfall', 'cocktail_beachbums_own',
    'cocktail_jet_pilot', 'cocktail_jungle_bird', 'cocktail_saturn',
    'cocktail_test_pilot', 'cocktail_doctor_funk', 'cocktail_cobras_fang',
  ];
  const seededSyrupIds = [
    'syrup_demerara_21', 'syrup_cinnamon', 'syrup_orgeat',
    'syrup_velvet_falernum', 'syrup_grenadine', 'syrup_dons_mix_1',
    'syrup_honey', 'syrup_passion_fruit', 'syrup_coconut_cream',
    'syrup_dons_spices_2', 'syrup_gardenia_mix', 'syrup_dons_mix_2',
    'syrup_hibiscus_grenadine', 'syrup_macadamia_orgeat',
  ];
  const seededMenuIds = [
    'menu_mediterranean_seafood_feast', 'menu_asian_fusion_yacht_dinner',
    'menu_classic_french_bistro', 'menu_italian_villa_dinner',
    'menu_caribbean_yacht_bbq', 'menu_modern_australian_cuisine',
    'menu_spanish_tapas_yacht_party', 'menu_japanese_kaiseki_dinner',
    'menu_american_steakhouse_classic', 'menu_thai_royal_cuisine',
  ];
  final classicIds = [
    ...seededCocktailIds,
    ...seededMenuIds,
    ...seededSyrupIds,
  ];
  await purgeSeededRecipeIngredientsFromDrift(classicIds);
  await purgeSeededRecipesFromDrift(classicIds);

  // ===================================================================
  // COCKTAILS - Top 10 Tiki from Smuggler's Cove
  // ===================================================================

  final cocktails = <Recipe>[
    Recipe()
      ..supabaseId = 'cocktail_mai_tai'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Mai Tai'
      ..description = 'The classic tiki cocktail from Trader Vic\'s, featuring rum, lime, and almond syrup'
      ..instructions = 'Shake all ingredients with ice. Strain into a rocks glass filled with crushed ice. Garnish with a lime shell, mint sprig, and pineapple spear.'
      ..recipeType = 'cocktail'
      ..isBundled = true
      ..glassware = 'Rocks glass'
      ..prepMinutes = 5
      ..story = 'Victor "Trader Vic" Bergeron mixed the first Mai Tai in 1944 in Oakland for two visiting Tahitians. They exclaimed "Mai Tai - Roa Ae!" - Tahitian for "out of this world, the best!" Don the Beachcomber claimed his own version predated it; the two men argued about it until their dying days. Both were probably right in their own way.',
    Recipe()
      ..supabaseId = 'cocktail_zombie'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Zombie'
      ..description = 'Don the Beachcomber\'s legendary multi-rum cocktail'
      ..instructions = 'Shake all ingredients with ice. Strain into a tall glass filled with crushed ice. Garnish with a mint sprig and fruit skewer.'
      ..recipeType = 'cocktail'
      ..isBundled = true
      ..glassware = 'Zombie glass'
      ..prepMinutes = 7
      ..story = 'Don the Beachcomber created the Zombie around 1934 at his Hollywood bar. A regular returned three days after his first glass, claiming it had turned him into a zombie for his entire business trip. Alarmed, Don limited customers to two per visit and encoded the recipe in a cipher - keeping the formula secret for decades to foil rival bartenders.',
    Recipe()
      ..supabaseId = 'cocktail_painkiller'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Painkiller'
      ..description = 'Creamy coconut tiki classic from the British Virgin Islands'
      ..instructions = 'Shake with ice and strain into a rocks glass filled with ice. Garnish with freshly grated nutmeg.'
      ..recipeType = 'cocktail'
      ..isBundled = true
      ..glassware = 'Rocks glass'
      ..prepMinutes = 5
      ..story = 'Born at the Soggy Dollar Bar on Jost Van Dyke, BVI - named because boats anchored offshore and guests swam in with waterlogged cash. Pusser\'s Rum trademarked the name in 1989, requiring any bar to use their brand to legally call it a Painkiller. The original bartender reportedly used whatever rum was to hand. The trademark dispute is ongoing.',
    Recipe()
      ..supabaseId = 'cocktail_navy_grog'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Navy Grog'
      ..description = 'Don the Beachcomber\'s complex rum blend with honey and citrus'
      ..instructions = 'Shake with ice and strain into a rocks glass filled with crushed ice. Garnish with a lime wheel.'
      ..recipeType = 'cocktail'
      ..isBundled = true
      ..glassware = 'Rocks glass'
      ..prepMinutes = 5
      ..story = 'An homage to the Royal Navy\'s daily rum ration issued since 1740, when Admiral Edward Vernon ordered watered rum instead of neat spirit. Vernon wore a grogram coat, earning him the nickname "Old Grog" - giving us the word groggy. Don the Beachcomber transformed the sailors\' daily medicine into something worth celebrating on dry land.',
    Recipe()
      ..supabaseId = 'cocktail_suffering_bastard'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Suffering Bastard'
      ..description = 'The hangover cure that doubles as a cocktail'
      ..instructions = 'Shake with ice and strain into a rocks glass filled with ice. Top with ginger beer. Garnish with a lime wheel.'
      ..recipeType = 'cocktail'
      ..isBundled = true
      ..glassware = 'Rocks glass'
      ..prepMinutes = 5
      ..story = 'Created by Joe Scialom at Cairo\'s Shepheard\'s Hotel as a hangover cure for British officers the morning after the Battle of El Alamein in 1942. Trader Vic later adapted it with tropical flavours. One of the few cocktails with documented military history - reportedly served for breakfast to officers before they returned to their commands.',
    Recipe()
      ..supabaseId = 'cocktail_fog_cutter'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Fog Cutter'
      ..description = 'Trader Vic\'s "drink that sneaks up on you"'
      ..instructions = 'Shake all ingredients except the sherry with ice. Strain into a tall glass filled with crushed ice. Float the sherry on top. Garnish with a pineapple spear.'
      ..recipeType = 'cocktail'
      ..isBundled = true
      ..glassware = 'Tall glass'
      ..prepMinutes = 5
      ..story = 'Trader Vic warned drinkers bluntly: "Fog Cutter, hell! After two of these, you won\'t even see the stuff." The Amontillado float was Vic\'s signature touch - a nutty cap that cuts through the citrus fog before you can see what hit you. One of his most popular 1940s creations, it remains a favourite for watching expressions change mid-drink.',
    Recipe()
      ..supabaseId = 'cocktail_scorpion_bowl'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Scorpion Bowl'
      ..description = 'Legendary communal tiki bowl for sharing'
      ..instructions = 'Blend all ingredients with ice. Pour into a large bowl or individual glasses. Garnish with edible flowers and fruit.'
      ..recipeType = 'cocktail'
      ..isBundled = true
      ..glassware = 'Scorpion bowl'
      ..prepMinutes = 8
      ..story = 'Designed by Trader Vic in the 1950s as a communal ceremony for two to four people. The flaming rum float - ignited tableside - became the defining image of Polynesian restaurant culture. Vic imported genuine scorpion bowls from Hawaii; the long straws kept guests safe from the flame while maintaining the theatre of sharing.',
    Recipe()
      ..supabaseId = 'cocktail_three_dots_and_a_dash'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Three Dots and a Dash'
      ..description = 'Smuggler\'s Cove\'s signature cocktail'
      ..instructions = 'Shake with ice and strain into a rocks glass filled with crushed ice. Garnish with a lime wheel and pineapple fronds.'
      ..recipeType = 'cocktail'
      ..isBundled = true
      ..glassware = 'Rocks glass'
      ..prepMinutes = 5
      ..story = 'Named after Morse code for V (----), created by Trader Vic during World War II as a toast to Allied forces. The garnish encodes the message: three cherry dots, one pineapple-frond dash. Served at Vic\'s restaurants throughout the war. Chicago\'s celebrated Three Dots and a Dash bar, opened 2013, took its name and spirit directly from this cocktail.',
    Recipe()
      ..supabaseId = 'cocktail_missionarys_downfall'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Missionary\'s Downfall'
      ..description = 'Complex rum cocktail with tropical fruit'
      ..instructions = 'Shake with ice and strain into a rocks glass filled with crushed ice. Garnish with a pineapple spear.'
      ..recipeType = 'cocktail'
      ..isBundled = true
      ..glassware = 'Rocks glass'
      ..prepMinutes = 5
      ..story = 'Don the Beachcomber created this deceptively gentle drink in the 1940s, naming it for its ability to lead the pious astray. The peach brandy and mint make it taste like a garden party rather than a rum cocktail - which was precisely the point. Donn reportedly kept close watch on missionary guests and quietly refilled their glasses more than most.',
    Recipe()
      ..supabaseId = 'cocktail_beachbums_own'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Beachbum\'s Own'
      ..description = 'Jeff "Beachbum" Berry\'s modern tiki classic'
      ..instructions = 'Shake with ice and strain into a rocks glass filled with crushed ice. Garnish with a lime wheel.'
      ..recipeType = 'cocktail'
      ..isBundled = true
      ..glassware = 'Rocks glass'
      ..prepMinutes = 5
      ..story = 'Jeff "Beachbum" Berry spent years decoding Don the Beachcomber\'s secret recipes, tracking down coded ingredient names through former employees and informants. His books rescued tiki\'s lost canon from obscurity. This cocktail - named for Berry himself - is his tribute to the masters whose work he preserved. One rum, one citrus, one sweetener: tiki distilled to its essence.',
    Recipe()
      ..supabaseId = 'cocktail_jet_pilot'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Jet Pilot'
      ..description = 'Don the Beachcomber\'s turbo-charged Zombie variant - complex, boozy, and unforgettable'
      ..instructions = 'Combine all ingredients except absinthe in a blender with crushed ice. Flash blend briefly (just to integrate, not to froth). Pour into a tiki mug or chimney glass. Add a few more ice cubes. Drop the absinthe on top as a float. Garnish with a bushy mint sprig.'
      ..recipeType = 'cocktail'
      ..isBundled = true
      ..glassware = 'Tiki mug or chimney glass'
      ..prepMinutes = 7
      ..story = 'Donn Beach developed the Jet Pilot in the 1950s as a more refined, concentrated Zombie - same DNA, shorter pour, more layered spice. It uses three different rums (white, aged Jamaican, and overproof) alongside Don\'s Mix and Velvet Falernum. The name riffs on the aviation spirit of the post-war decade. At Smuggler\'s Cove, it\'s described as "the Zombie\'s dangerous little brother."',
    Recipe()
      ..supabaseId = 'cocktail_jungle_bird'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Jungle Bird'
      ..description = 'Bitter, boozy, and tropical - the one tiki cocktail that requires Campari'
      ..instructions = 'Combine all ingredients in a cocktail shaker with ice. Shake vigorously for 15 seconds. Strain over fresh ice into a double rocks glass or tiki mug. Garnish with a fresh pineapple wedge and a maraschino cherry.'
      ..recipeType = 'cocktail'
      ..isBundled = true
      ..glassware = 'Double rocks glass or tiki mug'
      ..prepMinutes = 5
      ..story = 'Created by bartender Iain Marshall at the Kuala Lumpur Hilton\'s Aviary Bar in 1978, the Jungle Bird lay largely forgotten until Jeff Berry published it in his 2002 book "Intoxica!" It became a sensation virtually overnight - a tiki cocktail that\'s simultaneously bitter, sweet, sour, and tropical. The Campari is the key: do not substitute it. It is now one of the most-ordered tiki drinks in the world.',
    Recipe()
      ..supabaseId = 'cocktail_saturn'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Saturn'
      ..description = 'Gin-based tiki cocktail - fruity, floral, and surprisingly light for something so complex'
      ..instructions = 'Combine all ingredients in a cocktail shaker with crushed ice. Shake well for 10 seconds. Open-pour (with ice) into a tiki glass or coupe. Garnish with a lemon wheel and a slapped mint sprig.'
      ..recipeType = 'cocktail'
      ..isBundled = true
      ..glassware = 'Tiki glass or coupe'
      ..prepMinutes = 5
      ..story = 'Created by J. "Popo" Galsini and submitted to the IBA (International Bartenders Association) competition in 1967, the Saturn was essentially the only gin-based tiki cocktail to find lasting fame. Jeff Berry published it in "Beachbum Berry\'s Grog Log" and it has since become a gateway drink for gin lovers who think they don\'t like tiki. The passion fruit and orgeat combine in a way that defies easy description.',
    Recipe()
      ..supabaseId = 'cocktail_test_pilot'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Test Pilot'
      ..description = 'Don the Beachcomber original - a more nuanced, slightly less potent sibling of the Zombie'
      ..instructions = 'Combine all ingredients in a cocktail shaker with crushed ice. Shake for 10 seconds. Pour (with ice) into a rocks glass or tiki mug. Garnish with mint and a maraschino cherry.'
      ..recipeType = 'cocktail'
      ..isBundled = true
      ..glassware = 'Rocks glass or tiki mug'
      ..prepMinutes = 6
      ..story = 'Donn Beach created the Test Pilot in the early 1940s as a tribute to the aviators of the era. Where the Zombie is a blunt instrument, the Test Pilot uses two of Don\'s Mix formulas side by side - the cinnamon-forward Mix #1 and the honeyed Mix #2 - to create a layered citrus complexity that reveals itself slowly across the drink. It is often described as the drink that proves Don was a genius, not just a showman.',
    Recipe()
      ..supabaseId = 'cocktail_doctor_funk'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Doctor Funk'
      ..description = 'Stevenson-era Samoan rum drink with absinthe - refreshing despite its eccentric pedigree'
      ..instructions = 'Combine rum, lime juice, lemon juice, simple syrup, grenadine, and absinthe in a shaker with ice. Shake well. Strain into a highball glass over ice. Top with soda water. Garnish with a lime wheel.'
      ..recipeType = 'cocktail'
      ..isBundled = true
      ..glassware = 'Highball glass'
      ..prepMinutes = 5
      ..story = 'Dr. Bernard Funk was Robert Louis Stevenson\'s physician in Samoa in the 1890s, and by all accounts also his dedicated drinking companion. Stevenson reportedly credited the Doctor\'s rum concoction with keeping him alive through his tuberculosis. The absinthe is a small but essential ingredient - it appeared in bar culture long before tiki, and Donn Beach adopted it as a flavoring agent throughout his work. The name "Funk" has given this drink an enduringly subversive reputation.',
    Recipe()
      ..supabaseId = 'cocktail_cobras_fang'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = "Cobra's Fang"
      ..description = "Don the Beachcomber's allspice-and-absinthe rum punch - exotic, complex, and slightly dangerous"
      ..instructions = 'Combine all ingredients in a shaker with crushed ice. Shake briskly for 10 seconds. Pour (unstrained) into a tiki mug or coupe. Garnish with a lime wheel and maraschino cherry.'
      ..recipeType = 'cocktail'
      ..isBundled = true
      ..glassware = 'Tiki mug or coupe'
      ..prepMinutes = 6
      ..story = "Cobra's Fang appeared on Don the Beachcomber's menu sometime in the 1940s. Like many of his originals it used coded ingredient names - the allspice dram was called \"St. Elizabeth Allspice Dram\" and Absinthe appeared under its own name only in the master copy. Jeff Berry's sleuthing uncovered the full recipe. The allspice-absinthe combination is the cocktail's fang - it bites back just enough.",
  ];

  for (final c in cocktails) {
    applyClassicCocktailSeedMeta(c);
    c.imageAsset =
        cocktailImageAssetFor(name: c.name, glassware: c.glassware);
  }

  await seedRecipesToDrift(cocktails);

  // ===================================================================
  // COCKTAIL INGREDIENTS
  // Ingredient names match seed_bar_ingredients.dart exactly (case-sensitive).
  // ===================================================================

  final cocktailIngredients = <RecipeIngredient>[];

  void addCocktail(
    String recipeId,
    String name,
    double? quantity,
    String? unit, {
    String? substitute,
    bool isOptional = false,
    bool isGarnish = false,
    String? garnishNotes,
  }) {
    cocktailIngredients.add(
      RecipeIngredient()
        ..supabaseId = 'ing_${recipeId}_${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}'
        ..recipeSupabaseId = recipeId
        ..name = name
        ..quantity = quantity
        ..unit = unit
        ..substitute = substitute
        ..isOptional = isOptional
        ..isGarnish = isGarnish
        ..garnishNotes = garnishNotes,
    );
  }

  // Mai Tai
  addCocktail('cocktail_mai_tai', 'White Blended Rum', 60, 'ml');
  addCocktail('cocktail_mai_tai', 'Dark Blended Rum', 30, 'ml');
  addCocktail('cocktail_mai_tai', 'Fresh Lime Juice', 30, 'ml');
  addCocktail('cocktail_mai_tai', 'Orange Curacao', 15, 'ml');
  addCocktail('cocktail_mai_tai', 'Orgeat', 15, 'ml');
  addCocktail('cocktail_mai_tai', 'Fresh Mint', null, null, isGarnish: true, garnishNotes: 'Slap a generous sprig between your palms to release the oils, then tuck it upright behind the ice so the aroma rises with every sip.');
  addCocktail('cocktail_mai_tai', 'Pineapple Spears', null, null, isGarnish: true, garnishNotes: 'Cut a wedge from a fresh pineapple, skewer it on a cocktail pick and rest it across the rim. The flag should face forward.');

  // Zombie (Smuggler's Cove version)
  addCocktail('cocktail_zombie', 'White Blended Rum', 45, 'ml');
  addCocktail('cocktail_zombie', 'Dark Blended Rum', 45, 'ml');
  addCocktail('cocktail_zombie', 'Overproof Pot Still Rum', 30, 'ml');
  addCocktail('cocktail_zombie', 'Fresh Lime Juice', 30, 'ml');
  addCocktail('cocktail_zombie', 'Grapefruit Juice', 15, 'ml');
  addCocktail('cocktail_zombie', 'Cinnamon Syrup', 15, 'ml');
  addCocktail('cocktail_zombie', 'Grenadine', 20, 'ml');
  addCocktail('cocktail_zombie', 'Velvet Falernum', 20, 'ml');
  addCocktail('cocktail_zombie', 'Angostura Bitters', 1.0, 'dash');
  addCocktail('cocktail_zombie', 'Absinthe', 1.0, 'dash');
  addCocktail('cocktail_zombie', 'Fresh Mint', null, null, isGarnish: true, garnishNotes: 'Slap a bushy sprig between palms and plant it upright in the crushed ice. The tropical aroma should hit before the first sip.');

  // Painkiller
  addCocktail('cocktail_painkiller', 'Dark Blended Rum', 60, 'ml');
  addCocktail('cocktail_painkiller', 'Pineapple Juice', 30, 'ml');
  addCocktail('cocktail_painkiller', 'Orange Juice', 30, 'ml');
  addCocktail('cocktail_painkiller', 'Cream of Coconut', 30, 'ml');
  addCocktail('cocktail_painkiller', 'Freshly Grated Nutmeg', null, null, isGarnish: true, garnishNotes: 'Grate whole nutmeg directly over the surface of the drink just before serving - the warmth of the foam carries the spice. Pre-ground nutmeg loses most of its punch.');

  // Navy Grog
  addCocktail('cocktail_navy_grog', 'White Blended Rum', 30, 'ml');
  addCocktail('cocktail_navy_grog', 'Dark Blended Rum', 30, 'ml');
  addCocktail('cocktail_navy_grog', 'Dark Demerara Rum', 30, 'ml');
  addCocktail('cocktail_navy_grog', 'Fresh Lime Juice', 20, 'ml');
  addCocktail('cocktail_navy_grog', 'Honey Syrup', 20, 'ml');
  addCocktail('cocktail_navy_grog', 'Soda Water', 60, 'ml');
  addCocktail('cocktail_navy_grog', 'Lime Wheel', null, null, isGarnish: true, garnishNotes: 'Cut a thin wheel from the center of a lime and nick the rind so it perches on the glass rim. Squeeze the wheel over the drink before placing it.');

  // Suffering Bastard
  addCocktail('cocktail_suffering_bastard', 'Gin', 30, 'ml');
  addCocktail('cocktail_suffering_bastard', 'Bourbon', 30, 'ml');
  addCocktail('cocktail_suffering_bastard', 'Fresh Lime Juice', 20, 'ml');
  addCocktail('cocktail_suffering_bastard', 'Angostura Bitters', 2.0, 'dash');
  addCocktail('cocktail_suffering_bastard', 'Ginger Beer', null, null, isOptional: true);
  addCocktail('cocktail_suffering_bastard', 'Fresh Mint Sprig', null, null, isGarnish: true, garnishNotes: 'Slap the sprig and tuck it into the neck of the tiki mug or alongside the ice. A cucumber slice on the rim is a classic British Cairo-era touch - add one if available.');
  addCocktail('cocktail_suffering_bastard', 'Lime Wedge', null, null, isGarnish: true, garnishNotes: 'Squeeze the wedge over the top and drop it in. The fresh citrus brightens the ginger beer finish.');

  // Fog Cutter
  addCocktail('cocktail_fog_cutter', 'White Blended Rum', 60, 'ml');
  addCocktail('cocktail_fog_cutter', 'Dark Blended Rum', 30, 'ml');
  addCocktail('cocktail_fog_cutter', 'Gin', 30, 'ml');
  addCocktail('cocktail_fog_cutter', 'Orange Juice', 60, 'ml');
  addCocktail('cocktail_fog_cutter', 'Fresh Lemon Juice', 30, 'ml');
  addCocktail('cocktail_fog_cutter', 'Orgeat', 15, 'ml');
  addCocktail('cocktail_fog_cutter', 'Dry Sherry', 15, 'ml');
  addCocktail('cocktail_fog_cutter', 'Orange Wheel', null, null, isGarnish: true, garnishNotes: 'Float a thin half-wheel of orange on the surface. The sherry float on top of the drink means this garnish is purely visual - keep it pristine.');

  // Scorpion Bowl
  addCocktail('cocktail_scorpion_bowl', 'White Blended Rum', 60, 'ml');
  addCocktail('cocktail_scorpion_bowl', 'Dark Blended Rum', 30, 'ml');
  addCocktail('cocktail_scorpion_bowl', 'Brandy', 30, 'ml');
  addCocktail('cocktail_scorpion_bowl', 'Orange Juice', 60, 'ml');
  addCocktail('cocktail_scorpion_bowl', 'Fresh Lime Juice', 30, 'ml');
  addCocktail('cocktail_scorpion_bowl', 'Orgeat', 15, 'ml');
  addCocktail('cocktail_scorpion_bowl', 'Fresh Orchid', null, null, isGarnish: true, garnishNotes: 'Place an edible orchid or gardenia bloom on the crushed ice mound in the center of the bowl. The theatrical presentation is part of the Scorpion Bowl experience - serve with long straws for the whole table.');
  addCocktail('cocktail_scorpion_bowl', 'Pineapple Wedges', null, null, isGarnish: true, garnishNotes: 'Fan 2-3 pineapple wedges around the rim of the bowl. Each diner gets a wedge to nibble between sips.');

  // Three Dots and a Dash (Trader Vic / Smuggler's Cove version)
  addCocktail('cocktail_three_dots_and_a_dash', 'Aged Blended Rum', 45, 'ml');
  addCocktail('cocktail_three_dots_and_a_dash', 'Dark Blended Rum', 20, 'ml');
  addCocktail('cocktail_three_dots_and_a_dash', 'Fresh Lime Juice', 20, 'ml');
  addCocktail('cocktail_three_dots_and_a_dash', 'Honey Syrup', 15, 'ml');
  addCocktail('cocktail_three_dots_and_a_dash', 'Velvet Falernum', 15, 'ml');
  addCocktail('cocktail_three_dots_and_a_dash', 'Allspice Dram', 15, 'ml');
  addCocktail('cocktail_three_dots_and_a_dash', 'Orange Juice', 15, 'ml');
  addCocktail('cocktail_three_dots_and_a_dash', 'Angostura Bitters', 2.0, 'dash');
  addCocktail('cocktail_three_dots_and_a_dash', 'Maraschino Cherries', null, null, isGarnish: true, garnishNotes: 'Skewer three maraschino cherries in a row on a cocktail pick - these are the three dots of the Morse code V (---). Place the pick across the rim.');
  addCocktail('cocktail_three_dots_and_a_dash', 'Pineapple Spears', null, null, isGarnish: true, garnishNotes: 'Add one pineapple spear or frond alongside the cherry pick - this is the dash (-) completing the V (----). Together they toast Allied forces.');

  // Missionary's Downfall (Don the Beachcomber original)
  addCocktail('cocktail_missionarys_downfall', 'White Blended Rum', 45, 'ml');
  addCocktail('cocktail_missionarys_downfall', 'Peach Brandy', 20, 'ml');
  addCocktail('cocktail_missionarys_downfall', 'Honey Syrup', 15, 'ml');
  addCocktail('cocktail_missionarys_downfall', 'Fresh Lime Juice', 20, 'ml');
  addCocktail('cocktail_missionarys_downfall', 'Pineapple Juice', 15, 'ml');
  addCocktail('cocktail_missionarys_downfall', 'Fresh Mint', null, null, isGarnish: true, garnishNotes: 'This drink is blended with mint, so the garnish continues the theme. Mound a generous bouquet of fresh mint in the crushed ice so guests bury their nose in it before drinking.');

  // Beachbum's Own
  addCocktail('cocktail_beachbums_own', 'White Blended Rum', 60, 'ml');
  addCocktail('cocktail_beachbums_own', 'Fresh Lime Juice', 20, 'ml');
  addCocktail('cocktail_beachbums_own', 'Honey Syrup', 20, 'ml');
  addCocktail('cocktail_beachbums_own', 'Orange Bitters', 2.0, 'dash');
  addCocktail('cocktail_beachbums_own', 'Peychaud\'s Bitters', 2.0, 'dash');
  addCocktail('cocktail_beachbums_own', 'Lime Wheel', null, null, isGarnish: true, garnishNotes: 'Nick a thin lime wheel and perch it on the rim. The simplicity of the garnish mirrors the elegance of this understated cocktail - keep it clean.');

  // Jet Pilot
  addCocktail('cocktail_jet_pilot', 'Dark Blended Rum', 45, 'ml');
  addCocktail('cocktail_jet_pilot', 'Aged Pot Still Rum', 20, 'ml');
  addCocktail('cocktail_jet_pilot', 'Black Blended Overproof Rum', 20, 'ml');
  addCocktail('cocktail_jet_pilot', 'Fresh Lime Juice', 20, 'ml');
  addCocktail('cocktail_jet_pilot', "Don's Mix #1", 20, 'ml');
  addCocktail('cocktail_jet_pilot', 'Velvet Falernum', 15, 'ml');
  addCocktail('cocktail_jet_pilot', 'Angostura Bitters', 1.0, 'dash');
  addCocktail('cocktail_jet_pilot', 'Absinthe', 1.0, 'dash');
  addCocktail('cocktail_jet_pilot', 'Fresh Mint', null, null, isGarnish: true, garnishNotes: 'Plant a bushy mint sprig in the center of the crushed ice so it rises above the rim. The herbal aroma meets the nose before the first sip - that contrast is the point.');

  // Jungle Bird
  addCocktail('cocktail_jungle_bird', 'Dark Rum', 45, 'ml', substitute: 'Aged Jamaican Rum');
  addCocktail('cocktail_jungle_bird', 'Campari', 20, 'ml');
  addCocktail('cocktail_jungle_bird', 'Pineapple Juice', 45, 'ml');
  addCocktail('cocktail_jungle_bird', 'Fresh Lime Juice', 20, 'ml');
  addCocktail('cocktail_jungle_bird', 'Demerara Syrup', 15, 'ml', substitute: 'Simple Syrup');
  addCocktail('cocktail_jungle_bird', 'Pineapple Wedge', null, null, isGarnish: true, garnishNotes: 'Skewer a thick pineapple wedge with a cocktail pick, add a maraschino cherry to the pick, and rest it on the glass rim. The pineapple echoes the juice; the cherry nods to classic tiki.');
  addCocktail('cocktail_jungle_bird', 'Maraschino Cherry', null, null, isGarnish: true, garnishNotes: 'Place on the cocktail pick alongside the pineapple wedge.');

  // Saturn
  addCocktail('cocktail_saturn', 'London Dry Gin', 45, 'ml');
  addCocktail('cocktail_saturn', 'Fresh Lemon Juice', 15, 'ml');
  addCocktail('cocktail_saturn', 'Passion Fruit Syrup', 15, 'ml');
  addCocktail('cocktail_saturn', 'Velvet Falernum', 5, 'ml');
  addCocktail('cocktail_saturn', 'Orgeat', 5, 'ml');
  addCocktail('cocktail_saturn', 'Lemon Wheel', null, null, isGarnish: true, garnishNotes: 'Nick a thin lemon wheel and perch it on the rim of the tiki glass. The yellow contrasts beautifully with the drink\'s pale amber color.');
  addCocktail('cocktail_saturn', 'Fresh Mint Sprig', null, null, isGarnish: true, garnishNotes: 'Slap a small mint sprig and tuck it beside the lemon wheel. The floral mint bridges the gin and passion fruit beautifully.');

  // Test Pilot
  addCocktail('cocktail_test_pilot', 'Dark Blended Rum', 45, 'ml');
  addCocktail('cocktail_test_pilot', 'Aged Blended Rum', 20, 'ml');
  addCocktail('cocktail_test_pilot', 'Velvet Falernum', 15, 'ml');
  addCocktail('cocktail_test_pilot', "Don's Mix #1", 15, 'ml');
  addCocktail('cocktail_test_pilot', "Don's Mix #2", 5, 'ml');
  addCocktail('cocktail_test_pilot', 'Cointreau', 5, 'ml', substitute: 'Orange Curacao');
  addCocktail('cocktail_test_pilot', 'Angostura Bitters', 2.0, 'dash');
  addCocktail('cocktail_test_pilot', 'Absinthe', 1.0, 'dash');
  addCocktail('cocktail_test_pilot', 'Maraschino Cherries', null, null, isGarnish: true, garnishNotes: 'Skewer two cherries on a short cocktail pick and lay across the rim. A simple, classic finish for a serious cocktail.');
  addCocktail('cocktail_test_pilot', 'Fresh Mint Sprig', null, null, isGarnish: true, garnishNotes: 'Slap a small sprig and tuck it behind the cherries. The aviator theme calls for something crisp and upright - keep it tidy.');

  // Doctor Funk
  addCocktail('cocktail_doctor_funk', 'Dark Jamaican Rum', 60, 'ml', substitute: 'White Blended Rum');
  addCocktail('cocktail_doctor_funk', 'Fresh Lime Juice', 20, 'ml');
  addCocktail('cocktail_doctor_funk', 'Fresh Lemon Juice', 15, 'ml');
  addCocktail('cocktail_doctor_funk', 'Simple Syrup', 15, 'ml');
  addCocktail('cocktail_doctor_funk', 'Pomegranate Grenadine', 5, 'ml');
  addCocktail('cocktail_doctor_funk', 'Absinthe', 15, 'ml');
  addCocktail('cocktail_doctor_funk', 'Soda Water', 60, 'ml');
  addCocktail('cocktail_doctor_funk', 'Lime Wheel', null, null, isGarnish: true, garnishNotes: 'Nick a thin wheel and perch it on the highball rim. The drink is long and refreshing - keep the garnish clean and simple to match.');

  // Cobra's Fang
  addCocktail('cocktail_cobras_fang', 'Dark Blended Rum', 30, 'ml');
  addCocktail('cocktail_cobras_fang', 'Aged Pot Still Rum', 30, 'ml');
  addCocktail('cocktail_cobras_fang', 'Velvet Falernum', 15, 'ml');
  addCocktail('cocktail_cobras_fang', 'Fresh Orange Juice', 20, 'ml');
  addCocktail('cocktail_cobras_fang', 'Fresh Lime Juice', 20, 'ml');
  addCocktail('cocktail_cobras_fang', 'Allspice Dram', 5, 'ml');
  addCocktail('cocktail_cobras_fang', 'Angostura Bitters', 2.0, 'dash');
  addCocktail('cocktail_cobras_fang', 'Absinthe', 2.0, 'dash');
  addCocktail('cocktail_cobras_fang', 'Lime Wheel', null, null, isGarnish: true, garnishNotes: 'Nick a lime wheel and rest it on the rim. The pop of green against the amber drink is visually striking - serve immediately, the ice melts fast.');
  addCocktail('cocktail_cobras_fang', 'Maraschino Cherry', null, null, isGarnish: true, garnishNotes: 'Drop a single cherry into the drink to sink to the bottom - a small surprise at the end of the glass, Don\'s signature theatrical touch.');

  await seedRecipeIngredientsToDrift(cocktailIngredients);

  // Expansion pack from cocktails_import.json (metric, one-glass, garnishes).
  await seedCocktailsImport(defaultBoatSupabaseId);
  await seedMenusImport(defaultBoatSupabaseId);
  // Bar-catalog coverage: every bar ingredient appears in >=2 cocktails.
  await seedCoverageCocktails(defaultBoatSupabaseId);

  // Recompute availability against (possibly empty) My Bar so "Can make now"
  // is not stuck at the default missingIngredientCount=0 for every recipe.
  await RecipeRepositoryImpl(AppDatabase.instance)
      .syncMissingIngredientCounts();

  // ===================================================================
  // MENUS - Top 10 Super Yacht Dinner Menus (base = 2 people)
  // ===================================================================

  final menus = <Recipe>[
    Recipe()
      ..supabaseId = 'menu_mediterranean_seafood_feast'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Mediterranean Seafood Feast'
      ..description = 'Elegant seafood dinner for two with fresh Mediterranean flavors'
      ..instructions = 'Serve courses sequentially. Start with appetizers, followed by main course, then dessert.'
      ..recipeType = 'menu'
      ..isBundled = true
      ..cuisine = ['Main', 'Mediterranean']
      ..cookingMethod = 'Pan-fry'
      ..prepMinutes = 30
      ..cookMinutes = 25
      ..story = 'Scaled for two at sea - use servings to scale for more guests. A crisp Sauvignon Blanc or dry Riesling lifts citrus and brine. Caribbean substitute: any dry white with citrus notes (Sauvignon Blanc / unoaked Chardonnay / dry Riesling).',
    Recipe()
      ..supabaseId = 'menu_asian_fusion_yacht_dinner'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Asian Fusion Yacht Dinner'
      ..description = 'Contemporary Asian cuisine for two with yacht-appropriate presentation'
      ..instructions = 'Prepare sauces first. Cook proteins to order. Serve with jasmine rice and stir-fried vegetables.'
      ..recipeType = 'menu'
      ..isBundled = true
      ..cuisine = ['Main', 'Asian']
      ..cookingMethod = 'Wok'
      ..prepMinutes = 25
      ..cookMinutes = 20
      ..story = 'Scaled for two. Off-dry Gewurztraminer or Riesling calms chilli heat; a cold lager also works. Caribbean substitute: slightly sweet white (Riesling / Gewurztraminer style) or ice-cold lager.',
    Recipe()
      ..supabaseId = 'menu_classic_french_bistro'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Classic French Bistro'
      ..description = 'Timeless French cuisine for two with butter sauces and fresh herbs'
      ..instructions = 'Prepare sauces ahead. Time proteins to be served hot. Classic French service: appetizers, main, cheese course, dessert.'
      ..recipeType = 'menu'
      ..isBundled = true
      ..cuisine = ['Main', 'French']
      ..cookingMethod = 'Stovetop'
      ..prepMinutes = 30
      ..cookMinutes = 35
      ..story = 'Scaled for two. Unoaked or lightly oaked Chardonnay suits butter sauces; Pinot Noir for duck. Caribbean substitute: white Burgundy style (Chardonnay) or light red (Pinot Noir).',
    Recipe()
      ..supabaseId = 'menu_italian_villa_dinner'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Italian Villa Dinner'
      ..description = 'Authentic Italian regional cuisine for two with family-style service'
      ..instructions = 'Use high-quality extra virgin olive oil. Cook pasta al dente.'
      ..recipeType = 'menu'
      ..isBundled = true
      ..cuisine = ['Main', 'Italian']
      ..cookingMethod = 'Stovetop'
      ..prepMinutes = 20
      ..cookMinutes = 30
      ..story = 'Scaled for two. Chianti-style Sangiovese or a medium Merlot matches tomato and olive oil. Caribbean substitute: medium-bodied red (Merlot / Sangiovese / Cabernet blend), not too oaky.',
    Recipe()
      ..supabaseId = 'menu_caribbean_yacht_bbq'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Caribbean Yacht BBQ'
      ..description = 'Casual island-inspired barbecue for two with tropical flavors'
      ..instructions = 'Marinate proteins overnight. Grill over medium heat. Serve with cold beer or rum punch.'
      ..recipeType = 'menu'
      ..isBundled = true
      ..cuisine = ['Main', 'Caribbean', 'Braai']
      ..cookingMethod = 'Grill'
      ..prepMinutes = 15
      ..cookMinutes = 30
      ..story = 'Scaled for two. Ice-cold lager or a rum highball with lime; for wine, off-dry Riesling or rose. Caribbean substitute: any cold lager or dry rose; keep spirits light with ice and citrus.',
    Recipe()
      ..supabaseId = 'menu_modern_australian_cuisine'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Modern Australian Cuisine'
      ..description = 'Contemporary Australian flavors for two with native-inspired notes'
      ..instructions = 'Focus on fresh, local ingredients. Use bold herbs and spices.'
      ..recipeType = 'menu'
      ..isBundled = true
      ..cuisine = ['Main', 'Australian']
      ..cookingMethod = 'Grill'
      ..prepMinutes = 20
      ..cookMinutes = 25
      ..story = 'Scaled for two. Cabernet or Shiraz/Syrah stands up to rich grilled meat. Caribbean substitute: full red (Cabernet / Merlot / Shiraz), fruit-forward if young.',
    Recipe()
      ..supabaseId = 'menu_spanish_tapas_yacht_party'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Spanish Tapas Yacht Party'
      ..description = 'Social Spanish small plates for two - easy to scale for guests'
      ..instructions = 'Prepare tapas in batches. Serve at room temperature or warm.'
      ..recipeType = 'menu'
      ..isBundled = true
      ..cuisine = ['Appetizer', 'Spanish']
      ..cookingMethod = 'One-pot'
      ..prepMinutes = 30
      ..cookMinutes = 20
      ..story = 'Scaled for two (double freely for a party). Rioja-style Tempranillo or dry Cava. Caribbean substitute: medium red (Tempranillo / Grenache style) or dry sparkling white.',
    Recipe()
      ..supabaseId = 'menu_japanese_kaiseki_dinner'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Japanese Kaiseki Dinner'
      ..description = 'Multi-course Japanese-inspired dinner for two'
      ..instructions = 'Serve courses in order. Use fresh, seasonal ingredients. Minimal seasoning to highlight natural flavors.'
      ..recipeType = 'menu'
      ..isBundled = true
      ..cuisine = ['Main', 'Japanese']
      ..cookingMethod = 'Raw / No-cook'
      ..prepMinutes = 40
      ..cookMinutes = 20
      ..story = 'Scaled for two. Junmai-style sake or a very dry sparkling white keeps the palate clean. Caribbean substitute: dry sparkling white or light lager if sake is unavailable.',
    Recipe()
      ..supabaseId = 'menu_american_steakhouse_classic'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'American Steakhouse Classic'
      ..description = 'Premium steaks and traditional sides for two'
      ..instructions = 'Bring steaks to room temperature before cooking. Use high heat for perfect crust. Rest before serving.'
      ..recipeType = 'menu'
      ..isBundled = true
      ..cuisine = ['Main', 'American']
      ..cookingMethod = 'Grill'
      ..prepMinutes = 15
      ..cookMinutes = 20
      ..story = 'Scaled for two. Cabernet Sauvignon or Shiraz/Syrah with steak. Caribbean substitute: full red (Cabernet / Merlot / Shiraz).',
    Recipe()
      ..supabaseId = 'menu_thai_royal_cuisine'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Thai Royal Cuisine'
      ..description = 'Elegant Thai dishes for two with palace-inspired balance'
      ..instructions = 'Balance sweet, sour, salty, and spicy flavors. Use fresh herbs. Serve with jasmine rice.'
      ..recipeType = 'menu'
      ..isBundled = true
      ..cuisine = ['Main', 'Thai']
      ..cookingMethod = 'Wok'
      ..prepMinutes = 25
      ..cookMinutes = 25
      ..story = 'Scaled for two. Off-dry Gewurztraminer or Riesling calms chilli heat; cold lager also works. Caribbean substitute: slightly sweet white or ice-cold lager.',
  ];

  await seedRecipesToDrift(menus);

  // ===================================================================
  // MENU INGREDIENTS
  // Ingredient names match seed_pantry_ingredients.dart exactly where possible.
  // Specialty/fresh proteins (Sea Bass, Duck, etc.) are market items not in pantry seed.
  // ===================================================================

  final menuIngredients = <RecipeIngredient>[];

  void addMenu(
    String recipeId,
    String name,
    double? quantity,
    String? unit, {
    String? substitute,
    bool isOptional = false,
    bool isGarnish = false,
  }) {
    menuIngredients.add(
      RecipeIngredient()
        ..supabaseId = 'ing_${recipeId}_${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}'
        ..recipeSupabaseId = recipeId
        ..name = name
        ..quantity = quantity
        ..unit = unit
        ..substitute = substitute
        ..isOptional = isOptional
        ..isGarnish = isGarnish,
    );
  }

  // Quantities below are a **2-person base** (app servings 1 = this amount).

  // Mediterranean Seafood Feast
  addMenu('menu_mediterranean_seafood_feast', 'Fresh Sea Bass', 2.0, 'fillets');
  addMenu('menu_mediterranean_seafood_feast', 'Calamari', 200.0, 'g');
  addMenu('menu_mediterranean_seafood_feast', 'Mussels', 400.0, 'g');
  addMenu('menu_mediterranean_seafood_feast', 'Cherry Tomatoes', 150.0, 'g');
  addMenu('menu_mediterranean_seafood_feast', 'Fennel', 1.0, 'bulbs');
  addMenu('menu_mediterranean_seafood_feast', 'Extra Virgin Olive Oil', 30.0, 'ml');
  addMenu('menu_mediterranean_seafood_feast', 'Fresh Basil', 10.0, 'g');
  addMenu('menu_mediterranean_seafood_feast', 'Fresh Lemon', 1.0, 'pieces', substitute: 'lemon zest');

  // Asian Fusion Yacht Dinner
  addMenu('menu_asian_fusion_yacht_dinner', 'Fresh Tuna', 300.0, 'g');
  addMenu('menu_asian_fusion_yacht_dinner', 'Udon Noodles', 200.0, 'g', substitute: 'Pasta');
  addMenu('menu_asian_fusion_yacht_dinner', 'Shiitake Mushrooms', 100.0, 'g');
  addMenu('menu_asian_fusion_yacht_dinner', 'Baby Bok Choy', 200.0, 'g');
  addMenu('menu_asian_fusion_yacht_dinner', 'Fresh Ginger', 20.0, 'g');
  addMenu('menu_asian_fusion_yacht_dinner', 'Soy Sauce', 30.0, 'ml');
  addMenu('menu_asian_fusion_yacht_dinner', 'Sesame Oil', 15.0, 'ml');
  addMenu('menu_asian_fusion_yacht_dinner', 'Rice Wine Vinegar', 15.0, 'ml');
  addMenu('menu_asian_fusion_yacht_dinner', 'Jasmine Rice', 160.0, 'g');

  // Classic French Bistro
  addMenu('menu_classic_french_bistro', 'Duck Breast', 2.0, 'pieces');
  addMenu('menu_classic_french_bistro', 'Fingerling Potatoes', 300.0, 'g');
  addMenu('menu_classic_french_bistro', 'French Green Beans', 200.0, 'g');
  addMenu('menu_classic_french_bistro', 'Shallots', 2.0, 'pieces');
  addMenu('menu_classic_french_bistro', 'Dry White Wine', 100.0, 'ml');
  addMenu('menu_classic_french_bistro', 'Fresh Thyme', 15.0, 'ml');
  addMenu('menu_classic_french_bistro', 'Butter', 60.0, 'g');
  addMenu('menu_classic_french_bistro', 'Dijon Mustard', 15.0, 'ml', isOptional: true);

  // Italian Villa Dinner
  addMenu('menu_italian_villa_dinner', 'Pasta', 200.0, 'g');
  addMenu('menu_italian_villa_dinner', 'Canned Chopped Tomatoes', 400.0, 'g', substitute: 'San Marzano Tomatoes');
  addMenu('menu_italian_villa_dinner', 'Fresh Mozzarella', 100.0, 'g');
  addMenu('menu_italian_villa_dinner', 'Fresh Basil', 10.0, 'g');
  addMenu('menu_italian_villa_dinner', 'Prosciutto di Parma', 50.0, 'g', isOptional: true);
  addMenu('menu_italian_villa_dinner', 'Extra Virgin Olive Oil', 30.0, 'ml');
  addMenu('menu_italian_villa_dinner', 'Aged Balsamic Vinegar', 15.0, 'ml');
  addMenu('menu_italian_villa_dinner', 'Garlic', 3.0, 'cloves');

  // Caribbean Yacht BBQ
  addMenu('menu_caribbean_yacht_bbq', 'Jerk Chicken', 500.0, 'g');
  addMenu('menu_caribbean_yacht_bbq', 'Fresh Fish Fillets', 300.0, 'g');
  addMenu('menu_caribbean_yacht_bbq', 'Pineapple', 200.0, 'g');
  addMenu('menu_caribbean_yacht_bbq', 'Mango', 1.0, 'pieces');
  addMenu('menu_caribbean_yacht_bbq', 'Allspice Berries', 5.0, 'ml');
  addMenu('menu_caribbean_yacht_bbq', 'Scotch Bonnet Peppers', 1.0, 'pieces', substitute: 'Chilli Flakes');
  addMenu('menu_caribbean_yacht_bbq', 'Fresh Thyme', 15.0, 'ml');
  addMenu('menu_caribbean_yacht_bbq', 'Dark Blended Rum', 30.0, 'ml');

  // Modern Australian Cuisine
  addMenu('menu_modern_australian_cuisine', 'Lamb Rack', 2.0, 'pieces');
  addMenu('menu_modern_australian_cuisine', 'Wattleseed', 5.0, 'ml', isOptional: true);
  addMenu('menu_modern_australian_cuisine', 'Fresh Oysters', 6.0, 'pieces');
  addMenu('menu_modern_australian_cuisine', 'Macadamia Nuts', 40.0, 'g');
  addMenu('menu_modern_australian_cuisine', 'Honey', 15.0, 'ml');
  addMenu('menu_modern_australian_cuisine', 'Fresh Lemon', 1.0, 'pieces');
  addMenu('menu_modern_australian_cuisine', 'Extra Virgin Olive Oil', 30.0, 'ml');
  addMenu('menu_modern_australian_cuisine', 'Fresh Thyme', 15.0, 'ml');

  // Spanish Tapas Yacht Party
  addMenu('menu_spanish_tapas_yacht_party', 'Serrano Ham', 80.0, 'g');
  addMenu('menu_spanish_tapas_yacht_party', 'Manchego Cheese', 80.0, 'g');
  addMenu('menu_spanish_tapas_yacht_party', 'Calamari', 200.0, 'g');
  addMenu('menu_spanish_tapas_yacht_party', 'Piquillo Peppers', 80.0, 'g', substitute: 'Roasted Red Peppers');
  addMenu('menu_spanish_tapas_yacht_party', 'Olives', 60.0, 'g');
  addMenu('menu_spanish_tapas_yacht_party', 'Spanish Chorizo', 80.0, 'g');
  addMenu('menu_spanish_tapas_yacht_party', 'Paprika', 5.0, 'ml');
  addMenu('menu_spanish_tapas_yacht_party', 'Extra Virgin Olive Oil', 30.0, 'ml');

  // Japanese Kaiseki Dinner
  addMenu('menu_japanese_kaiseki_dinner', 'Fresh Sashimi Grade Fish', 200.0, 'g');
  addMenu('menu_japanese_kaiseki_dinner', 'Fresh Tofu', 200.0, 'g');
  addMenu('menu_japanese_kaiseki_dinner', 'Dashi Stock', 400.0, 'ml', substitute: 'Vegetable Stock');
  addMenu('menu_japanese_kaiseki_dinner', 'Mirin', 30.0, 'ml');
  addMenu('menu_japanese_kaiseki_dinner', 'Soy Sauce', 30.0, 'ml');
  addMenu('menu_japanese_kaiseki_dinner', 'Fresh Ginger', 15.0, 'g');
  addMenu('menu_japanese_kaiseki_dinner', 'Wasabi Root', 10.0, 'g', isOptional: true);
  addMenu('menu_japanese_kaiseki_dinner', 'Sesame Oil', 5.0, 'ml');

  // American Steakhouse Classic
  addMenu('menu_american_steakhouse_classic', 'Prime Ribeye Steak', 2.0, 'pieces');
  addMenu('menu_american_steakhouse_classic', 'Asparagus', 200.0, 'g');
  addMenu('menu_american_steakhouse_classic', 'Butter', 40.0, 'g');
  addMenu('menu_american_steakhouse_classic', 'Heavy Cream', 100.0, 'ml');
  addMenu('menu_american_steakhouse_classic', 'Garlic', 3.0, 'cloves');
  addMenu('menu_american_steakhouse_classic', 'Fresh Thyme', 15.0, 'ml');
  addMenu('menu_american_steakhouse_classic', 'Salt', null, 'to taste');
  addMenu('menu_american_steakhouse_classic', 'Black Pepper', null, 'to taste');

  // Thai Royal Cuisine
  addMenu('menu_thai_royal_cuisine', 'Fresh Seafood', 350.0, 'g');
  addMenu('menu_thai_royal_cuisine', 'Coconut Milk', 1.0, 'cans');
  addMenu('menu_thai_royal_cuisine', 'Lemongrass', 2.0, 'stalks');
  addMenu('menu_thai_royal_cuisine', 'Thai Basil', 10.0, 'g', substitute: 'Fresh Basil');
  addMenu('menu_thai_royal_cuisine', 'Galangal', 15.0, 'g', substitute: 'Fresh Ginger');
  addMenu('menu_thai_royal_cuisine', 'Palm Sugar', 20.0, 'g', substitute: 'Brown Sugar');
  addMenu('menu_thai_royal_cuisine', 'Fish Sauce', 15.0, 'ml');
  addMenu('menu_thai_royal_cuisine', 'Chilli Flakes', 2.5, 'ml');
  addMenu('menu_thai_royal_cuisine', 'Jasmine Rice', 160.0, 'g');

  await seedRecipeIngredientsToDrift(menuIngredients);

  // ===================================================================
  // SYRUPS & HOUSE MIXES - BC22
  // ===================================================================

  final syrups = <Recipe>[
    Recipe()
      ..supabaseId = 'syrup_demerara_21'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Demerara Syrup'
      ..description = 'Rich molasses-forward syrup - the backbone of most tiki cocktails'
      ..instructions = 'Combine 2 cups Demerara sugar with 1 cup hot (not boiling) water. Stir until fully dissolved. Cool, pour into a bottle, refrigerate. Keeps 3-4 weeks.'
      ..recipeType = 'syrup'
      ..isBundled = true
      ..prepMinutes = 5
      ..cookMinutes = 5
      ..story = 'Donn Beach (Don the Beachcomber) insisted on Demerara sugar in place of white sugar for its deep molasses notes - a decision that quietly separated his drinks from everyone else\'s. The 2:1 ratio produces a viscous, shelf-stable syrup that carries the spirit of the cane from field to glass.'
      ..flavorProfiles = ['sweet', 'earthy', 'warming'],
    Recipe()
      ..supabaseId = 'syrup_cinnamon'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Cinnamon Syrup'
      ..description = 'Warm, aromatic spiced syrup used in Zombies, Don\'s Mix, and countless tiki builds'
      ..instructions = 'Simmer 4 cinnamon sticks in 1 cup water for 10 minutes. Add 2 cups white sugar, stir until dissolved. Cool, strain out sticks, bottle. Keeps 2-3 weeks refrigerated.'
      ..recipeType = 'syrup'
      ..isBundled = true
      ..prepMinutes = 2
      ..cookMinutes = 15
      ..story = 'Cinnamon syrup is the quiet workhorse of the tiki pantry - appearing in Trader Vic\'s originals and Don the Beachcomber\'s coded formulae alike. Don used it under cipher names like "mix #4" to guard his recipes from rival barkeeps who sent spies to sit at his bar.'
      ..flavorProfiles = ['spicy', 'sweet', 'warming'],
    Recipe()
      ..supabaseId = 'syrup_orgeat'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Orgeat'
      ..description = 'Fresh almond syrup - the heart of the Mai Tai and a tiki essential'
      ..instructions = 'Blend 1 cup blanched almonds with 11/2 cups water. Strain through cheesecloth, squeezing firmly. Heat almond milk with 1 cup sugar until dissolved. Off heat, add 1/2 tsp orange flower water and 1 tbsp vodka as preservative. Bottle and refrigerate up to 2 weeks.'
      ..recipeType = 'syrup'
      ..isBundled = true
      ..prepMinutes = 25
      ..cookMinutes = 10
      ..story = 'Trader Vic called orgeat "the most important ingredient" in the Mai Tai - a bold claim for a syrup. The word comes from the French "orge" (barley), because medieval orgeat was barley-water sweetened with almonds. By the 19th century almonds had taken over entirely. Vic sourced it from a local Oakland confectioner before eventually bottling his own.'
      ..flavorProfiles = ['nutty', 'sweet', 'floral'],
    Recipe()
      ..supabaseId = 'syrup_velvet_falernum'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Velvet Falernum'
      ..description = 'Rum-based lime-almond-spice liqueur from Barbados - a cornerstone of tiki'
      ..instructions = 'Zest 6 limes and steep zest with 10 cloves, 5 allspice berries, 2 oz fresh ginger (sliced), and 1/4 cup blanched almonds in 1 cup white rum for 24 hours. Strain, press solids. Combine with 1 cup simple syrup and 1/4 tsp vanilla extract. Bottle. Keeps 1 month refrigerated.'
      ..recipeType = 'syrup'
      ..isBundled = true
      ..prepMinutes = 30
      ..cookMinutes = 0
      ..story = 'John D. Taylor\'s Velvet Falernum has been produced in Barbados since 1890. The commercial version is 11% ABV and sweetly spiced - but bartenders who make their own can dial up the rum, lime, or spice to match their bar. The name "falernum" likely traces to Falernian wine, the most celebrated wine of ancient Rome.'
      ..flavorProfiles = ['citrus', 'spicy', 'nutty'],
    Recipe()
      ..supabaseId = 'syrup_grenadine'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Grenadine'
      ..description = 'Real pomegranate grenadine - nothing like the artificial red dye version'
      ..instructions = 'Combine 2 cups pomegranate juice and 2 cups white sugar in a saucepan. Heat over medium, stirring, until sugar dissolves - do not boil. Remove from heat, add 1 tsp orange flower water (optional) and 1 oz pomegranate molasses for depth. Cool, bottle. Keeps 1 month refrigerated.'
      ..recipeType = 'syrup'
      ..isBundled = true
      ..prepMinutes = 5
      ..cookMinutes = 10
      ..story = 'Grenadine takes its name from "grenade" - French for pomegranate. Nineteenth-century bartenders made it from actual pomegranates. Somewhere in the 20th century food manufacturers replaced the fruit with high-fructose corn syrup and red dye #40. When Smuggler\'s Cove opened in 2009, they put house-made pomegranate grenadine back on the bar. It changed everything.'
      ..flavorProfiles = ['tart', 'fruity', 'sweet-tart'],
    Recipe()
      ..supabaseId = 'syrup_dons_mix_1'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = "Don's Mix #1"
      ..description = "Don the Beachcomber's secret pre-mix of grapefruit juice and cinnamon syrup"
      ..instructions = "Combine 2 parts fresh grapefruit juice with 1 part cinnamon syrup. Stir to combine. Use immediately or refrigerate for up to 3 days. Shake before use."
      ..recipeType = 'syrup'
      ..isBundled = true
      ..prepMinutes = 2
      ..cookMinutes = 0
      ..story = "Don the Beachcomber used coded ingredient names on his recipe cards so employees couldn't recreate his drinks after leaving. \"Mix #1\" appears in the Zombie and several other originals. Tiki historian Jeff \"Beachbum\" Berry spent years tracking down former staff to decode the cipher. Mix #1 turned out to be this elegant two-ingredient blend that makes grapefruit taste like a spirit."
      ..flavorProfiles = ['citrus', 'spicy', 'tart'],
    // -- New Smuggler's Cove / Trader Vic / Don the Beachcomber syrups --------
    Recipe()
      ..supabaseId = 'syrup_honey'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Honey Syrup'
      ..description = 'Liquid honey diluted for easy pouring and consistent measuring'
      ..instructions = 'Warm 1 cup raw honey gently over low heat until it thins. Remove from heat and stir in 1/2 cup hot water until fully combined. Cool, bottle. Keeps 1 month refrigerated. For rich honey syrup (2:1) skip the extra water and use 1/2 cup water to 1 cup honey.'
      ..recipeType = 'syrup'
      ..isBundled = true
      ..prepMinutes = 5
      ..cookMinutes = 5
      ..story = 'Honey syrup is the ingredient that lets bartenders use honey with precision - undiluted honey clumps in cold drinks. Smuggler\'s Cove uses it in the Three Dots and a Dash, Navy Grog, and many others. Donn Beach favored Hawaiian raw honey; any unfiltered wildflower or clover honey works beautifully.'
      ..flavorProfiles = ['sweet', 'floral', 'earthy'],
    Recipe()
      ..supabaseId = 'syrup_passion_fruit'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Passion Fruit Syrup'
      ..description = 'Intensely tropical, sweet-tart syrup from one of the most evocative fruits in the Pacific'
      ..instructions = 'Halve 12 ripe passion fruits and scoop pulp (seeds and all) into a blender. Pulse 5 seconds - just enough to free the juice, not to break the seeds. Strain through a fine-mesh sieve. Measure the resulting juice and add an equal volume of 1:1 simple syrup. Stir, bottle, refrigerate. Use within 5 days fresh, or freeze for 3 months. Frozen Goya passion fruit puree works well when fresh fruit is out of season - mix 1:1 with simple syrup.'
      ..recipeType = 'syrup'
      ..isBundled = true
      ..prepMinutes = 15
      ..cookMinutes = 0
      ..story = 'The passion fruit is native to South America but was transplanted across the Pacific Islands - and into the tiki pantheon - during the 20th century. Jeff Berry\'s Saturn (1967) brought it into cocktail culture. Smuggler\'s Cove uses house-made passion fruit syrup in seven different drinks on their menu, making it one of their most essential house preparations.'
      ..flavorProfiles = ['tropical', 'fruity', 'sweet-tart'],
    Recipe()
      ..supabaseId = 'syrup_coconut_cream'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Fresh Coconut Cream'
      ..description = 'Unsweetened coconut cream - richer and cleaner than canned cream of coconut'
      ..instructions = 'Open 2 mature coconuts, drain the water (drink it). Crack shells, peel brown skin, and cube the white flesh. Blend coconut flesh with 11/2 cups warm water until very smooth, about 2 minutes. Strain through several layers of cheesecloth, squeezing firmly. Refrigerate the liquid overnight - the cream rises to the top. Skim it off. Use within 3 days. Alternatively: buy full-fat canned coconut cream (not cream of coconut) - shake well before use.'
      ..recipeType = 'syrup'
      ..isBundled = true
      ..prepMinutes = 30
      ..cookMinutes = 0
      ..story = 'Smuggler\'s Cove makes a careful distinction between cream of coconut (the sweetened Coco Lopez product used in Painkillers) and fresh coconut cream - the unsweetened fat extracted from fresh coconut flesh. The latter has a cleaner, less cloying tropical flavour and is the base of their more refined coconut preparations.'
      ..flavorProfiles = ['creamy', 'tropical', 'sweet'],
    Recipe()
      ..supabaseId = 'syrup_dons_spices_2'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = "Don's Spices #2"
      ..description = "Don the Beachcomber's vanilla-anise blend - the ghost flavor in many of his originals"
      ..instructions = "Combine 2 oz Pernod (or pastis) with 2 tsp pure vanilla extract. Stir to combine. Store in a small dropper bottle. Use in dashes - 1 dash = roughly 3 ml. This is a flavoring blend, not a syrup; use sparingly. Keeps indefinitely."
      ..recipeType = 'syrup'
      ..isBundled = true
      ..prepMinutes = 2
      ..cookMinutes = 0
      ..story = "Don the Beachcomber numbered his secret blends to obscure them from rival bartenders. Spices #2 is a marriage of pastis (anise-forward) and vanilla - two flavors that shouldn't work together but somehow elevate everything around them. Jeff Berry decoded it by tracking down Don's former bar manager. It appears in the Jet Pilot and the Cobra's Fang."
      ..flavorProfiles = ['herbal', 'sweet', 'complex'],
    Recipe()
      ..supabaseId = 'syrup_gardenia_mix'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Gardenia Mix'
      ..description = 'Butter-honey emulsion that adds a silky, tropical richness to grogs and punches'
      ..instructions = 'Melt 4 tbsp unsalted butter in a small saucepan over very low heat. Add 4 tbsp raw honey and stir gently until fully emulsified. Remove from heat and store at room temperature in a small jar - it will set to a spreadable consistency when cold, which is fine. Warm briefly before use if needed. Use within 1 week.'
      ..recipeType = 'syrup'
      ..isBundled = true
      ..prepMinutes = 5
      ..cookMinutes = 5
      ..story = 'Gardenia Mix is one of the most unusual ingredients in the tiki canon - a warm butter-honey emulsion that melts into a drink and adds an extraordinary mouthfeel. It appears in Trader Vic\'s Navy Grog and several Don the Beachcomber originals. The name comes from the gardenia flowers that traditionally garnished the bowls it was used in.'
      ..flavorProfiles = ['creamy', 'sweet', 'floral'],
    Recipe()
      ..supabaseId = 'syrup_dons_mix_2'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = "Don's Mix #2"
      ..description = "Don the Beachcomber's honey-grapefruit blend - lighter and more floral than Mix #1"
      ..instructions = "Combine 2 parts fresh white grapefruit juice with 1 part honey syrup. Whisk until the honey is fully incorporated. Use within 3 days refrigerated. Unlike Mix #1, Mix #2 uses honey rather than cinnamon syrup, giving it a floral top note instead of a spiced one."
      ..recipeType = 'syrup'
      ..isBundled = true
      ..prepMinutes = 3
      ..cookMinutes = 0
      ..story = "Don the Beachcomber used a numerical coding system on his recipe cards - Mix #1 through #4 were his essential pre-blended bases, each a different ratio of juice and sweetener. Mix #2 (grapefruit and honey) appears in the Test Pilot alongside its sibling Mix #1. Together they give the drink an extraordinary citrus complexity that no single juice can replicate."
      ..flavorProfiles = ['citrus', 'sweet', 'floral'],
    Recipe()
      ..supabaseId = 'syrup_hibiscus_grenadine'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Hibiscus Grenadine'
      ..description = "Smuggler's Cove variant - pomegranate grenadine steeped with dried hibiscus for deeper floral tartness"
      ..instructions = 'Steep 3 tbsp dried hibiscus flowers (flor de Jamaica) in 2 cups pomegranate juice for 30 minutes. Strain out flowers. Heat juice over medium, add 2 cups sugar, stir until dissolved - do not boil. Off heat, add 1 tsp orange flower water. Cool, bottle. Keeps 1 month refrigerated. The hibiscus adds a brilliant ruby color and a cranberry-adjacent tartness.'
      ..recipeType = 'syrup'
      ..isBundled = true
      ..prepMinutes = 35
      ..cookMinutes = 10
      ..story = "Hibiscus (flor de Jamaica in Mexico) has been used in aguas frescas and cold teas across the tropical world for centuries. Smuggler's Cove steeps dried hibiscus flowers in their pomegranate grenadine, creating a deeper, more complex version that bridges the gap between grenadine and shrub. The crimson color alone justifies the extra step."
      ..flavorProfiles = ['tart', 'floral', 'fruity'],
    Recipe()
      ..supabaseId = 'syrup_macadamia_orgeat'
      ..boatSupabaseId = defaultBoatSupabaseId
      ..name = 'Macadamia Nut Orgeat'
      ..description = "Trader Vic's Pacific twist on classic orgeat - butterier and more tropical than the almond original"
      ..instructions = 'Blend 1 cup raw unsalted macadamia nuts with 11/2 cups warm water until smooth. Strain through cheesecloth, squeezing firmly. Heat nut milk with 1 cup sugar until dissolved. Off heat, add 1/2 tsp pure vanilla extract (no orange flower water - macadamia is already floral) and 1 tbsp vodka as preservative. Bottle and refrigerate up to 2 weeks.'
      ..recipeType = 'syrup'
      ..isBundled = true
      ..prepMinutes = 20
      ..cookMinutes = 10
      ..story = "Trader Vic Bergeron grew up in Oakland but fell in love with the Pacific and Hawaii - macadamia nuts were his way of rooting orgeat in the Islands rather than the Mediterranean. His macadamia orgeat appeared on the menu at Trader Vic's in the 1960s and was a signature of the Polynesian pop era. It is buttery, vanilla-forward, and undeniably tropical."
      ..flavorProfiles = ['nutty', 'creamy', 'tropical'],
  ];

  await seedRecipesToDrift(syrups);

  final syrupIngredients = <RecipeIngredient>[];

  void addSyrup(
    String recipeId,
    String name,
    double? quantity,
    String? unit, {
    bool isOptional = false,
  }) {
    syrupIngredients.add(
      RecipeIngredient()
        ..supabaseId =
            'ing_${recipeId}_${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}'
        ..recipeSupabaseId = recipeId
        ..name = name
        ..quantity = quantity
        ..unit = unit
        ..isOptional = isOptional,
    );
  }

  // Demerara Syrup
  addSyrup('syrup_demerara_21', 'Demerara Sugar', 480.0, 'ml');
  addSyrup('syrup_demerara_21', 'Water', 240.0, 'ml');

  // Cinnamon Syrup
  addSyrup('syrup_cinnamon', 'Cinnamon Sticks', 4.0, 'sticks');
  addSyrup('syrup_cinnamon', 'Water', 240.0, 'ml');
  addSyrup('syrup_cinnamon', 'White Sugar', 480.0, 'ml');

  // Orgeat
  addSyrup('syrup_orgeat', 'Blanched Almonds', 240.0, 'ml');
  addSyrup('syrup_orgeat', 'Water', 360.0, 'ml');
  addSyrup('syrup_orgeat', 'White Sugar', 240.0, 'ml');
  addSyrup('syrup_orgeat', 'Orange Flower Water', 2.5, 'ml', isOptional: true);
  addSyrup('syrup_orgeat', 'Vodka', 15.0, 'ml');

  // Velvet Falernum
  addSyrup('syrup_velvet_falernum', 'White Blended Rum', 240.0, 'ml');
  addSyrup('syrup_velvet_falernum', 'Lime Zest', 6.0, 'limes');
  addSyrup('syrup_velvet_falernum', 'Blanched Almonds', 60.0, 'ml');
  addSyrup('syrup_velvet_falernum', 'Cloves', 10.0, 'whole');
  addSyrup('syrup_velvet_falernum', 'Allspice Berries', 5.0, 'whole');
  addSyrup('syrup_velvet_falernum', 'Fresh Ginger', 59.1, 'ml');
  addSyrup('syrup_velvet_falernum', 'Vanilla Extract', 1.25, 'ml');
  addSyrup('syrup_velvet_falernum', 'Simple Syrup', 240.0, 'ml');

  // Grenadine
  addSyrup('syrup_grenadine', 'Pomegranate Juice', 480.0, 'ml');
  addSyrup('syrup_grenadine', 'White Sugar', 480.0, 'ml');
  addSyrup('syrup_grenadine', 'Orange Flower Water', 5.0, 'ml', isOptional: true);
  addSyrup('syrup_grenadine', 'Pomegranate Molasses', 29.6, 'ml', isOptional: true);

  // Don's Mix #1
  addSyrup('syrup_dons_mix_1', 'Grapefruit Juice', 2.0, 'parts');
  addSyrup('syrup_dons_mix_1', 'Cinnamon Syrup', 1.0, 'part');

  // Honey Syrup
  addSyrup('syrup_honey', 'Raw Honey', 240.0, 'ml');
  addSyrup('syrup_honey', 'Hot Water', 120.0, 'ml');

  // Passion Fruit Syrup
  addSyrup('syrup_passion_fruit', 'Fresh Passion Fruit', 12.0, 'fruits', isOptional: false);
  addSyrup('syrup_passion_fruit', 'Simple Syrup', 240.0, 'ml');

  // Fresh Coconut Cream
  addSyrup('syrup_coconut_cream', 'Mature Coconuts', 2.0, 'whole');
  addSyrup('syrup_coconut_cream', 'Warm Water', 360.0, 'ml');

  // Don's Spices #2
  addSyrup('syrup_dons_spices_2', 'Pernod', 59.1, 'ml');
  addSyrup('syrup_dons_spices_2', 'Pure Vanilla Extract', 10.0, 'ml');

  // Gardenia Mix
  addSyrup('syrup_gardenia_mix', 'Unsalted Butter', 60.0, 'ml');
  addSyrup('syrup_gardenia_mix', 'Raw Honey', 60.0, 'ml');

  // Don's Mix #2
  addSyrup('syrup_dons_mix_2', 'White Grapefruit Juice', 2.0, 'parts');
  addSyrup('syrup_dons_mix_2', 'Honey Syrup', 1.0, 'part');

  // Hibiscus Grenadine
  addSyrup('syrup_hibiscus_grenadine', 'Dried Hibiscus Flowers', 45.0, 'ml');
  addSyrup('syrup_hibiscus_grenadine', 'Pomegranate Juice', 480.0, 'ml');
  addSyrup('syrup_hibiscus_grenadine', 'White Sugar', 480.0, 'ml');
  addSyrup('syrup_hibiscus_grenadine', 'Orange Flower Water', 5.0, 'ml', isOptional: true);

  // Macadamia Nut Orgeat
  addSyrup('syrup_macadamia_orgeat', 'Raw Macadamia Nuts', 240.0, 'ml');
  addSyrup('syrup_macadamia_orgeat', 'Warm Water', 360.0, 'ml');
  addSyrup('syrup_macadamia_orgeat', 'White Sugar', 240.0, 'ml');
  addSyrup('syrup_macadamia_orgeat', 'Pure Vanilla Extract', 2.5, 'ml');
  addSyrup('syrup_macadamia_orgeat', 'Vodka', 15.0, 'ml');

  await seedRecipeIngredientsToDrift(syrupIngredients);
}
