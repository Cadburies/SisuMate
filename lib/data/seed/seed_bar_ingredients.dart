import 'ingredient_drift_seed.dart';
import '../../models/models.dart';

// (name, category, flavorProfiles, abv, lastKnownPrice, priceUnit, imageUrl)
// Prices: approximate US retail USD (2025). imageUrl: stable Wikimedia Commons.
const _barData =
    <(String, String, List<String>, double?, double?, String?, String?)>[

  // ── Rums: Blended ─────────────────────────────────────────────────────────
  // SC Cat 1/2: Blended White/Light rum (Plantation 3 Stars, Caña Brava)
  ('White Blended Rum', 'spirit',
    ['fresh', 'sweet', 'light', 'tropical', 'clean'], 40.0, 20.0, '750ml', null),
  // SC Cat 3: Dark/Black blended rum (Gosling's Black Seal, Myers's)
  ('Dark Blended Rum', 'spirit',
    ['tropical', 'sweet', 'funky', 'rich', 'molasses', 'dark'], 40.0, 24.0, '750ml', null),
  // SC Cat 4: Black blended overproof (Coruba Dark, Gosling's 151)
  ('Dark Overproof Blended Rum', 'spirit',
    ['tropical', 'funky', 'dark', 'strong', 'fiery', 'molasses'], 75.5, 28.0, '750ml', null),
  // SC Cat 5: Lightly aged blended (Banks 7, Mount Gay Eclipse)
  ('Gold Blended Rum', 'spirit',
    ['tropical', 'sweet', 'light', 'vanilla', 'caramel'], 40.0, 26.0, '750ml', null),
  // SC Cat 7: Aged blended (Appleton Estate Signature, Flor de Caña 7yr)
  ('Aged Blended Rum', 'spirit',
    ['tropical', 'sweet', 'rich', 'vanilla', 'caramel', 'oak'], 43.0, 32.0, '750ml', null),

  // ── Rums: Demerara ────────────────────────────────────────────────────────
  // SC Cat 3 Demerara variation: Dark Demerara (El Dorado 12, Lemon Hart Dark)
  ('Dark Demerara Rum', 'spirit',
    ['tropical', 'funky', 'rich', 'molasses', 'dark', 'toffee'], 40.0, 34.0, '750ml', null),
  // SC Cat 9: Aged blended overproof Demerara (Lemon Hart 151, Hamilton 151)
  ('Overproof Demerara Rum', 'spirit',
    ['tropical', 'funky', 'fiery', 'molasses', 'strong', 'tiki'], 75.5, 36.0, '750ml', null),

  // ── Rums: Agricole ────────────────────────────────────────────────────────
  // SC Cat 1 Agricole: White/Light agricole (Clément Première Canne, Rhum J.M White)
  ('Light Agricole Rum', 'spirit',
    ['fresh', 'grassy', 'vegetal', 'tropical', 'bright', 'agricole'], 40.0, 38.0, '750ml', null),
  // SC Cat 6: Lightly aged agricole (Clément V.S., J.M Gold)
  ('Gold Agricole Rum', 'spirit',
    ['tropical', 'grassy', 'fresh', 'vanilla', 'agricole', 'light'], 40.0, 42.0, '750ml', null),
  // SC Cat 8: Aged agricole (Barbancourt 8yr, Clément V.S.O.P., Rhum J.M Gold)
  ('Dark Agricole Rum', 'spirit',
    ['tropical', 'rich', 'grassy', 'agricole', 'oak', 'complex', 'dark'], 43.0, 48.0, '750ml', null),

  // ── Rums: Pot Still / Jamaican ────────────────────────────────────────────
  // SC Cat 10: Pot still unaged (Smith & Cross, Rum-Bar Gold)
  ('Pot Still Jamaican Rum', 'spirit',
    ['funky', 'tropical', 'heavy', 'ester', 'pot-still', 'tiki', 'strong'], 57.0, 38.0, '750ml', null),
  // SC Cat 11: Pot still overproof (Wray & Nephew White Overproof, Rum-Bar Overproof)
  ('Overproof Pot Still Rum', 'spirit',
    ['funky', 'tropical', 'fiery', 'ester', 'pot-still', 'tiki', 'strong'], 63.0, 32.0, '750ml', null),

  // ── Rums: Specialty ───────────────────────────────────────────────────────
  ('Spiced Rum', 'spirit',
    ['spiced', 'sweet', 'tropical', 'warm', 'vanilla', 'caramel'], 35.0, 22.0, '750ml', null),

  // ── Other Spirits ─────────────────────────────────────────────────────────
  ('Bourbon', 'spirit',
    ['sweet', 'vanilla', 'caramel', 'warm', 'spirit-forward', 'oak'], 40.0, 32.0, '750ml', null),
  ('Rye Whiskey', 'spirit',
    ['spiced', 'dry', 'spirit-forward', 'peppery', 'grain'], 45.0, 34.0, '750ml', null),
  ('Scotch Whisky', 'spirit',
    ['smoky', 'peaty', 'rich', 'spirit-forward', 'complex'], 40.0, 45.0, '750ml', null),
  ('Irish Whiskey', 'spirit',
    ['light', 'smooth', 'sweet', 'spirit-forward', 'grain'], 40.0, 30.0, '750ml', null),
  ('Gin', 'spirit',
    ['herbal', 'botanical', 'fresh', 'floral', 'citrus', 'juniper'], 40.0, 30.0, '750ml', null),
  ('Vodka', 'spirit',
    ['neutral', 'clean', 'fresh', 'light'], 40.0, 20.0, '750ml', null),
  ('Blanco Tequila', 'spirit',
    ['fresh', 'citrus', 'vegetal', 'spirit-forward', 'agave'], 40.0, 28.0, '750ml', null),
  ('Reposado Tequila', 'spirit',
    ['sweet', 'spiced', 'citrus', 'warm', 'oak', 'agave'], 40.0, 34.0, '750ml', null),
  ('Mezcal', 'spirit',
    ['smoky', 'earthy', 'funky', 'spirit-forward', 'agave'], 40.0, 40.0, '750ml', null),
  ('Brandy', 'spirit',
    ['sweet', 'fruity', 'rich', 'warm', 'spirit-forward'], 40.0, 22.0, '750ml', null),
  ('Cognac', 'spirit',
    ['fruity', 'floral', 'rich', 'sweet', 'spirit-forward', 'oak'], 40.0, 50.0, '750ml', null),
  ('Pisco', 'spirit',
    ['fresh', 'floral', 'fruity', 'spirit-forward', 'grape'], 40.0, 28.0, '750ml', null),

  // ── Liqueurs & Modifiers ──────────────────────────────────────────────────
  ('Triple Sec', 'liqueur',
    ['citrus', 'sweet', 'orange', 'light'], 30.0, 16.0, '750ml', null),
  ('Cointreau', 'liqueur',
    ['citrus', 'sweet', 'orange', 'floral', 'premium'], 40.0, 38.0, '750ml', null),
  ('Blue Curaçao', 'liqueur',
    ['citrus', 'sweet', 'orange', 'tropical', 'funky'], 25.0, 16.0, '750ml', null),
  ('Amaretto', 'liqueur',
    ['sweet', 'almond', 'nutty', 'fruity', 'warm'], 28.0, 24.0, '750ml', null),
  ('Kahlúa', 'liqueur',
    ['sweet', 'coffee', 'rich', 'dark', 'creamy'], 20.0, 26.0, '750ml', null),
  ('Tia Maria', 'liqueur',
    ['sweet', 'coffee', 'vanilla', 'dark', 'smooth'], 20.0, 28.0, '750ml', null),
  // Irish cream — Mudslide, B-52, coffee drinks
  ('Baileys Irish Cream', 'liqueur',
    ['sweet', 'creamy', 'chocolate', 'vanilla', 'rich'], 17.0, 28.0, '750ml', null),
  // Fruit liqueur (distinct from grenadine syrup) — pom margs, martinis
  ('Pomegranate Liqueur', 'liqueur',
    ['sweet', 'fruity', 'tart', 'berry', 'pomegranate', 'bright'], 17.0, 26.0, '750ml', null),
  ('Maraschino Liqueur', 'liqueur',
    ['sweet', 'cherry', 'floral', 'nutty', 'tiki'], 32.0, 30.0, '500ml', null),
  ('Peach Schnapps', 'liqueur',
    ['sweet', 'fruity', 'peach', 'light'], 20.0, 16.0, '750ml', null),
  ('Peach Brandy', 'liqueur',
    ['fruity', 'sweet', 'peach', 'warm', 'spirit-forward', 'brandy'], 30.0, 28.0, '750ml', null),
  ('Chambord', 'liqueur',
    ['sweet', 'fruity', 'berry', 'floral', 'rich', 'raspberry'], 16.5, 30.0, '375ml', null),
  ('St-Germain Elderflower', 'liqueur',
    ['floral', 'sweet', 'fresh', 'aromatic', 'light', 'elderflower'], 20.0, 40.0, '375ml', null),
  // Classic tiki curaçao — amber/orange, distinct from Blue Curaçao
  ('Orange Curaçao', 'liqueur',
    ['citrus', 'sweet', 'orange', 'tiki', 'tropical', 'amber'], 40.0, 22.0, '750ml', null),
  // Key tiki modifiers
  ('Allspice Dram', 'liqueur',
    ['spiced', 'warm', 'tiki', 'aromatic', 'pimento', 'clove'], 22.5, 22.0, '750ml', null),
  ('Velvet Falernum', 'liqueur',
    ['sweet', 'spiced', 'tropical', 'tiki', 'lime', 'almond', 'clove'], 11.0, 18.0, '750ml', null),
  ('Absinthe', 'liqueur',
    ['herbal', 'anise', 'botanical', 'aromatic', 'strong', 'tiki'], 70.0, 45.0, '375ml', null),
  // Aperitifs & bitters-style
  ('Campari', 'liqueur',
    ['bitter', 'sweet', 'herbal', 'citrus', 'aperitif', 'complex'], 24.0, 30.0, '750ml', null),
  ('Aperol', 'liqueur',
    ['bitter', 'sweet', 'orange', 'light', 'aperitif'], 11.0, 24.0, '750ml', null),
  ('Fernet-Branca', 'liqueur',
    ['bitter', 'herbal', 'menthol', 'digestif', 'dark', 'complex'], 39.0, 30.0, '750ml', null),

  // ── Syrups ────────────────────────────────────────────────────────────────
  ('Orgeat', 'syrup',
    ['sweet', 'nutty', 'almond', 'tropical', 'floral', 'tiki'], null, 16.0, '500ml', null),
  ('Simple Syrup', 'syrup',
    ['sweet', 'neutral', 'light', 'clean'], null, 8.0, '750ml', null),
  ('Demerara Syrup', 'syrup',
    ['sweet', 'rich', 'molasses', 'caramel', 'tiki'], null, 10.0, '500ml', null),
  ('Honey Syrup', 'syrup',
    ['sweet', 'floral', 'rich', 'warm', 'natural'], null, 10.0, '500ml', null),
  ('Grenadine', 'syrup',
    ['sweet', 'fruity', 'berry', 'bright', 'pomegranate'], null, 10.0, '750ml', null),
  ('Falernum Syrup', 'syrup',
    ['sweet', 'spiced', 'tropical', 'tiki', 'lime', 'almond', 'clove'], null, 12.0, '500ml', null),
  ('Cinnamon Syrup', 'syrup',
    ['sweet', 'spiced', 'warm', 'aromatic', 'tiki'], null, 10.0, '375ml', null),
  // Key SC tiki syrup
  ('Passion Fruit Syrup', 'syrup',
    ['tropical', 'sweet', 'tart', 'fruity', 'exotic', 'tiki', 'bright'], null, 14.0, '375ml', null),
  ('Pineapple Syrup', 'syrup',
    ['tropical', 'sweet', 'fruity', 'bright', 'tiki'], null, 12.0, '375ml', null),
  ('Coconut Cream', 'syrup',
    ['tropical', 'sweet', 'rich', 'creamy', 'tiki'], null, 8.0, '400ml', null),
  ('Cream of Coconut', 'syrup',
    ['tropical', 'sweet', 'rich', 'creamy', 'tiki'], null, 8.0, '400ml', null),

  // ── Vermouths & Wine ──────────────────────────────────────────────────────
  ('Sweet Vermouth', 'wine',
    ['sweet', 'herbal', 'bitter', 'rich', 'aromatic', 'complex'], 15.0, 14.0, '750ml', null),
  ('Dry Vermouth', 'wine',
    ['dry', 'herbal', 'light', 'fresh', 'aromatic'], 18.0, 14.0, '750ml', null),
  ('Prosecco', 'wine',
    ['light', 'fresh', 'fruity', 'floral', 'fizzy', 'dry'], 11.0, 16.0, '750ml', null),
  ('Champagne', 'wine',
    ['dry', 'fresh', 'yeasty', 'light', 'fizzy', 'complex'], 12.0, 35.0, '750ml', null),
  ('Dry Sherry', 'wine',
    ['dry', 'nutty', 'saline', 'complex', 'oxidised'], 15.0, 16.0, '750ml', null),

  // ── Mixers ────────────────────────────────────────────────────────────────
  ('Cola (Coke)', 'mixer',
    ['sweet', 'spiced', 'dark', 'fizzy', 'caramel'], null, 5.0, '2L', null),
  ('Ginger Beer', 'mixer',
    ['spicy', 'sweet', 'fresh', 'fizzy', 'ginger'], null, 6.0, '4-pack', null),
  ('Ginger Ale', 'mixer',
    ['sweet', 'ginger', 'light', 'fizzy', 'mild'], null, 4.0, '2L', null),
  ('Soda Water', 'mixer',
    ['neutral', 'fizzy', 'light', 'fresh', 'clean'], null, 3.0, '1L', null),
  ('Tonic Water', 'mixer',
    ['bitter', 'fresh', 'fizzy', 'light', 'quinine'], null, 3.0, '1L', null),
  ('Coconut Water', 'mixer',
    ['tropical', 'light', 'fresh', 'sweet', 'natural'], null, 3.0, '330ml', null),

  // ── Juices ────────────────────────────────────────────────────────────────
  ('Fresh Lime Juice', 'juice',
    ['sour', 'citrus', 'fresh', 'tart', 'bright', 'tiki'],
    null, 4.0, '250ml',
    'https://commons.wikimedia.org/wiki/Special:FilePath/Lime-Whole-Split.jpg'),
  ('Fresh Lemon Juice', 'juice',
    ['sour', 'citrus', 'fresh', 'tart', 'bright'],
    null, 3.0, '250ml',
    'https://commons.wikimedia.org/wiki/Special:FilePath/Lemon.jpg'),
  ('Orange Juice', 'juice',
    ['sweet', 'citrus', 'fruity', 'fresh', 'light'], null, 4.0, '1L', null),
  ('Pineapple Juice', 'juice',
    ['tropical', 'sweet', 'fruity', 'bright', 'tiki'], null, 4.0, '1L', null),
  ('Grapefruit Juice', 'juice',
    ['citrus', 'tart', 'bitter', 'fresh', 'bright', 'tiki'], null, 4.0, '1L', null),
  ('Cranberry Juice', 'juice',
    ['tart', 'fruity', 'berry', 'sour', 'bright'], null, 4.0, '1L', null),
  ('Passion Fruit Juice', 'juice',
    ['tropical', 'sweet', 'tart', 'fruity', 'exotic', 'tiki'], null, 5.0, '1L', null),
  ('Mango Juice', 'juice',
    ['tropical', 'sweet', 'fruity', 'rich', 'exotic'], null, 4.0, '1L', null),
  ('Papaya Juice', 'juice',
    ['tropical', 'sweet', 'fruity', 'exotic', 'tiki'], null, 5.0, '1L', null),

  // ── Bitters ───────────────────────────────────────────────────────────────
  ('Angostura Bitters', 'bitters',
    ['bitter', 'spiced', 'aromatic', 'herbal', 'warm', 'tiki'], 44.7, 12.0, '200ml', null),
  ("Peychaud's Bitters", 'bitters',
    ['bitter', 'anise', 'floral', 'aromatic', 'fruity', 'light'], 35.0, 12.0, '150ml', null),
  ('Orange Bitters', 'bitters',
    ['bitter', 'citrus', 'aromatic', 'dry', 'spiced'], 28.0, 12.0, '150ml', null),

  // ── Garnishes ─────────────────────────────────────────────────────────────
  ('Fresh Mint', 'garnish',
    ['fresh', 'herbal', 'cool', 'bright', 'aromatic'],
    null, 3.0, 'bunch',
    'https://commons.wikimedia.org/wiki/Special:FilePath/Mint-leaves-2007.jpg'),
  ('Lime Wedges', 'garnish',
    ['citrus', 'sour', 'fresh', 'tiki'], null, 2.0, 'bag', null),
  ('Orange Slices', 'garnish',
    ['citrus', 'sweet', 'fresh'], null, 2.0, 'piece', null),
  ('Maraschino Cherries', 'garnish',
    ['sweet', 'fruity', 'bright', 'tiki'], null, 6.0, 'jar', null),
  ('Pineapple Spears', 'garnish',
    ['tropical', 'sweet', 'fruity', 'tiki'], null, 4.0, 'piece', null),
  ('Fresh Fruit Skewers', 'garnish',
    ['fruity', 'tropical', 'sweet', 'tiki'], null, 3.0, 'set', null),
  ('Edible Flowers', 'garnish',
    ['floral', 'fresh', 'light', 'aromatic'], null, 5.0, 'pack', null),
  ('Cinnamon Sticks', 'garnish',
    ['spiced', 'warm', 'aromatic', 'tiki'], null, 4.0, 'pack', null),
  ('Dehydrated Lime Wheel', 'garnish',
    ['citrus', 'tart', 'fresh', 'tiki'], null, 5.0, 'pack', null),

  // ── Rim & Dusting ─────────────────────────────────────────────────────────
  ('Kosher Salt', 'rim',
    ['salty', 'neutral', 'clean'], null, 3.0, '1kg', null),
  ('Sugar (for rimming)', 'rim',
    ['sweet', 'neutral'], null, 2.0, '500g', null),
  ('Freshly Grated Nutmeg', 'rim',
    ['spiced', 'warm', 'aromatic', 'tiki'], null, 4.0, 'piece', null),
  ('Ground Cinnamon', 'rim',
    ['spiced', 'warm', 'sweet', 'aromatic', 'tiki'], null, 4.0, '50g', null),

  // ── Ice ───────────────────────────────────────────────────────────────────
  ('Crushed Ice', 'ice', ['neutral', 'cold', 'tiki'], null, 3.0, '2kg bag', null),
  ('Ice Cubes', 'ice', ['neutral', 'cold', 'clean'], null, 3.0, '2kg bag', null),

  // ── Added from recipe/cocktail seed usage (auto-curated 2026-07-09) ──
  ('Amaro Nonino', 'liqueur',
    ['bitter', 'herbal', 'complex'], 30.0, 35.0, '750ml', null),
  ('Amarula', 'liqueur',
    ['creamy', 'sweet', 'tropical'], 17.0, 22.0, '750ml', null),
  ('Ancho Chile Bitters', 'bitters',
    ['spicy', 'smoky', 'bitter'], null, 14.0, '100ml', null),
  ('Ancho Reyes Chile Liqueur', 'liqueur',
    ['spicy', 'smoky', 'sweet'], 40.0, 32.0, '750ml', null),
  ('Angostura Amaro', 'liqueur',
    ['bitter', 'spiced', 'complex'], 35.0, 28.0, '750ml', null),
  ('Applejack', 'spirit',
    ['fruity', 'apple', 'warm'], 40.0, 28.0, '750ml', null),
  ('Apricot Liqueur', 'liqueur',
    ['fruity', 'sweet', 'stone-fruit'], 24.0, 22.0, '750ml', null),
  ('Batavia Arrack', 'spirit',
    ['funky', 'tropical', 'spicy'], 50.0, 36.0, '750ml', null),
  ('Bénédictine', 'liqueur',
    ['herbal', 'sweet', 'complex'], 40.0, 38.0, '750ml', null),
  ('Calvados', 'spirit',
    ['apple', 'oak', 'warm'], 40.0, 40.0, '750ml', null),
  ('Chartreuse', 'liqueur',
    ['herbal', 'complex', 'botanical'], 55.0, 55.0, '750ml', null),
  ('Crème de Cacao', 'liqueur',
    ['chocolate', 'sweet', 'rich'], 25.0, 18.0, '750ml', null),
  ('White Crème de Cacao', 'liqueur',
    ['chocolate', 'sweet', 'light'], 25.0, 18.0, '750ml', null),
  ('Crème de Cassis', 'liqueur',
    ['berry', 'sweet', 'fruity'], 15.0, 18.0, '750ml', null),
  ('Crème de Mûre', 'liqueur',
    ['berry', 'sweet', 'blackberry'], 16.0, 20.0, '750ml', null),
  ('Crème de Noyaux', 'liqueur',
    ['nutty', 'almond', 'sweet'], 24.0, 22.0, '750ml', null),
  ('Crème de Violette', 'liqueur',
    ['floral', 'sweet', 'violet'], 20.0, 24.0, '750ml', null),
  ('Green Crème de Menthe', 'liqueur',
    ['mint', 'sweet', 'cooling'], 24.0, 16.0, '750ml', null),
  ('White Crème de Menthe', 'liqueur',
    ['mint', 'sweet', 'cooling'], 24.0, 16.0, '750ml', null),
  ('Drambuie', 'liqueur',
    ['honey', 'herbal', 'scotch'], 40.0, 35.0, '750ml', null),
  ('Egg White', 'mixer',
    ['protein', 'foamy', 'neutral'], null, 3.0, 'carton', null),
  ('Galliano', 'liqueur',
    ['herbal', 'vanilla', 'anise'], 42.3, 32.0, '750ml', null),
  ('Lillet Blanc', 'wine',
    ['floral', 'citrus', 'light'], 17.0, 20.0, '750ml', null),
  ('Marsala Wine', 'wine',
    ['sweet', 'nutty', 'oxidized'], 18.0, 14.0, '750ml', null),
  ('Molasses Syrup', 'syrup',
    ['dark', 'sweet', 'molasses'], null, 8.0, '250ml', null),
  ('Orange Flower Water', 'mixer',
    ['floral', 'aromatic', 'citrus'], null, 8.0, '100ml', null),
  ('Pecan Liqueur', 'liqueur',
    ['nutty', 'sweet', 'pecan'], 20.0, 28.0, '750ml', null),
  // Peychaud's already listed under Bitters above — do not duplicate.
  ('Ruby Port', 'wine',
    ['sweet', 'fruity', 'rich'], 20.0, 18.0, '750ml', null),
  ('Rosemary Syrup', 'syrup',
    ['herbal', 'sweet', 'aromatic'], null, 8.0, '250ml', null),
  ('Sweet Sherry', 'wine',
    ['sweet', 'nutty', 'oxidized'], 17.0, 14.0, '750ml', null),
  ('Honey-Ginger Syrup', 'syrup',
    ['sweet', 'spicy', 'ginger'], null, 8.0, '250ml', null),
];

// Substitute hierarchy: key ingredient can substitute FOR the listed names.
// e.g. 'Orange Curaçao' → ('Triple Sec', 'Cointreau') means:
// if you have Orange Curaçao stocked, recipes calling for Triple Sec or Cointreau are covered.
const _barSubstitutes = <String, (String?, String?)>{
  'Orange Curaçao':        ('Triple Sec', 'Cointreau'),
  'Velvet Falernum':       ('Falernum Syrup', null),
  'Honey Syrup':           ('Simple Syrup', null),
  'Demerara Syrup':        ('Simple Syrup', null),
  'Cinnamon Syrup':        ('Demerara Syrup', null),
  'Ginger Beer':           ('Ginger Ale', null),
  'Dark Blended Rum':      ('Dark Demerara Rum', 'Dark Agricole Rum'),
  'White Blended Rum':     ('Light Agricole Rum', 'Gold Blended Rum'),
  'Overproof Pot Still Rum': ('Overproof Demerara Rum', null),
  'Peach Brandy':          ('Peach Schnapps', null),
  'Brandy':                ('Cognac', null),
  'Dry Sherry':            ('Dry Vermouth', null),
  'Fresh Lemon Juice':     ('Fresh Lime Juice', null),
  'Grapefruit Juice':      ('Orange Juice', null),
  'Allspice Dram':         ('Cinnamon Syrup', null),
  'Bourbon':               ('Rye Whiskey', 'Irish Whiskey'),
};

List<BarIngredient> _buildBarIngredients() {
  final ingredients = <BarIngredient>[];
  for (var i = 0; i < _barData.length; i++) {
    final (name, cat, flavors, abv, price, priceUnit, imgUrl) = _barData[i];
    final subs = _barSubstitutes[name];
    ingredients.add(
      BarIngredient()
        ..supabaseId =
            'bar_${name.toLowerCase().replaceAll(RegExp(r"[^a-z0-9]"), '_')}'
        ..name = name
        ..category = cat
        ..flavorProfiles = List<String>.from(flavors)
        ..alcoholByVolume = abv
        ..lastKnownPrice = price
        ..lastKnownPriceUnit = priceUnit
        ..priceCurrency = 'USD'
        ..imageUrl = imgUrl
        ..inMyBar = false
        ..sortOrder = i
        ..isBundled = true
        ..substitute1 = subs?.$1
        ..substitute2 = subs?.$2,
    );
  }
  return ingredients;
}

Future<void> seedBarIngredients() async {
  // BarIngredient moved to Drift (S1).
  final ingredients = _buildBarIngredients();
  if (await barIngredientCountInDrift() == 0) {
    await seedBarIngredientsToDrift(ingredients);
  } else {
    // Existing installs: add only newly catalogued ingredients (keep inMyBar).
    await insertMissingBarIngredientsToDrift(ingredients);
  }

  // Always sync substitutes so existing installs get them without wiping inMyBar state.
  await syncBarSubstitutesInDrift(_barSubstitutes);
}
