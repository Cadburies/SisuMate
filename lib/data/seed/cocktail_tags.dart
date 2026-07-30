import '../../models/models.dart';

/// Seeded favourites (user backlog #2). Exact name match, case-insensitive.
const kSeededFavouriteCocktailNames = {
  'Mai Tai',
  'Zombie',
  'Three Dots and a Dash',
  "Beachbum's Own",
  'Tradewinds',
  "Hinky Dinks Fizzy",
};

/// Suggested cuisine / style tags (user backlog #4). Import may add others;
/// users can create custom tags in the editor.
const kSuggestedCocktailCuisineTags = [
  'IBA Official',
  'Long',
  'Moderately Strong',
  'New',
  'Non-alcoholic',
  'Shooter',
  'Soft',
  'Strong',
  'Tiki',
  'Custom',
  'Classic',
  'Modern',
  'American',
  'Caribbean',
  'French',
  'Italian',
  'British',
  'Cuban',
  'Mexican',
  'Japanese',
  'Texan',
  'New York',
];

/// Suggested flavor-profile tags (user backlog #3 / #5 core set).
const kSuggestedCocktailFlavorTags = [
  'citrus',
  'tropical',
  'sweet',
  'bitter',
  'spicy',
  'rum-forward',
  'smoky',
  'herbal',
  'creamy',
  'dry',
  'fruity',
  'floral',
  'nutty',
  'earthy',
  'refreshing',
  'strong',
  'balanced',
  'complex',
  'tart',
  'sweet-tart',
  'funk',
  'warming',
  'cooling',
  'gin-forward',
  'whiskey-forward',
  'elegant',
  'bold',
  'sparkling',
];

bool isSeededFavouriteName(String name) {
  final n = name.trim().toLowerCase();
  return kSeededFavouriteCocktailNames.any((f) => f.toLowerCase() == n);
}

/// Classic seeder meta: favourites + cuisine + flavor tags.
void applyClassicCocktailSeedMeta(Recipe c) {
  if (isSeededFavouriteName(c.name)) {
    c.isFavourite = true;
  }

  // Defaults for the classic Smuggler's Cove / tiki set.
  final byId = <String, (List<String> cuisine, List<String> flavors)>{
    'cocktail_mai_tai': (
      ['Tiki', 'Classic'],
      ['tropical', 'citrus', 'rum-forward', 'nutty']
    ),
    'cocktail_zombie': (
      ['Tiki', 'Classic', 'Strong'],
      ['rum-forward', 'citrus', 'spicy', 'complex', 'strong']
    ),
    'cocktail_painkiller': (
      ['Tiki', 'Classic', 'Caribbean'],
      ['creamy', 'tropical', 'sweet', 'rum-forward']
    ),
    'cocktail_navy_grog': (
      ['Tiki', 'Classic'],
      ['rum-forward', 'citrus', 'honey', 'refreshing']
    ),
    'cocktail_suffering_bastard': (
      ['Classic', 'British'],
      ['spicy', 'citrus', 'herbal', 'refreshing']
    ),
    'cocktail_fog_cutter': (
      ['Tiki', 'Classic', 'Strong'],
      ['citrus', 'nutty', 'strong', 'complex']
    ),
    'cocktail_scorpion_bowl': (
      ['Tiki', 'Classic', 'Long'],
      ['tropical', 'citrus', 'sweet', 'strong']
    ),
    'cocktail_three_dots_and_a_dash': (
      ['Tiki', 'Classic'],
      ['rum-forward', 'spicy', 'citrus', 'tropical']
    ),
    'cocktail_missionarys_downfall': (
      ['Tiki', 'Classic'],
      ['tropical', 'herbal', 'sweet', 'refreshing']
    ),
    'cocktail_beachbums_own': (
      ['Tiki', 'Classic'],
      ['rum-forward', 'citrus', 'balanced']
    ),
    'cocktail_jet_pilot': (
      ['Tiki', 'Classic', 'Strong'],
      ['rum-forward', 'spicy', 'citrus', 'strong', 'complex']
    ),
    'cocktail_jungle_bird': (
      ['Tiki', 'Classic', 'Modern'],
      ['bitter', 'tropical', 'rum-forward', 'balanced']
    ),
    'cocktail_saturn': (
      ['Tiki', 'Classic'],
      ['gin-forward', 'tropical', 'floral', 'fruity']
    ),
    'cocktail_test_pilot': (
      ['Tiki', 'Classic'],
      ['rum-forward', 'citrus', 'spicy', 'complex']
    ),
    'cocktail_doctor_funk': (
      ['Tiki', 'Classic', 'Long'],
      ['rum-forward', 'herbal', 'citrus', 'refreshing']
    ),
    'cocktail_cobras_fang': (
      ['Tiki', 'Classic', 'Strong'],
      ['rum-forward', 'spicy', 'citrus', 'herbal', 'bold']
    ),
  };

  final meta = byId[c.supabaseId];
  if (meta != null) {
    c.cuisine = List<String>.from(meta.$1);
    c.flavorProfiles = List<String>.from(meta.$2);
  } else if (c.cuisine.isEmpty && c.recipeType == 'cocktail') {
    c.cuisine = ['Tiki'];
  }
}

/// Merges [extra] into [base] without case-insensitive duplicates.
List<String> mergeTagLists(List<String> base, Iterable<String> extra) {
  return dedupeStrings([...base, ...extra]);
}
