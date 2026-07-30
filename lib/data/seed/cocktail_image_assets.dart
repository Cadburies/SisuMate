/// Offline cocktail art under `assets/cocktails/`.
///
/// Specific photos are used when a file exists for that drink; otherwise a
/// glassware-style default keeps every cocktail covered without network.
library;

/// Filenames (under `assets/cocktails/`) that ship in the APK.
/// Kept in sync with the directory — regenerate when adding photos.
const Set<String> kBundledCocktailImageFiles = {
  '_default.jpg',
  '_default_rocks.jpg',
  '_default_coupe.jpg',
  '_default_highball.jpg',
  '_default_tiki.jpg',
  '_default_flute.jpg',
  'navy_grog.jpg',
  'bloody_mary.jpg',
  'espresso_martini.jpg',
  'paloma.jpg',
  'paper_plane.jpg',
  'sidecar.jpg',
};

String cocktailSlug(String name) {
  return name
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z0-9]+"), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}

/// Path relative to `assets/` for [Recipe.imageAsset] / [SmartImage.assetName].
String cocktailImageAssetFor({
  required String name,
  String? glassware,
}) {
  final file = '${cocktailSlug(name)}.jpg';
  if (kBundledCocktailImageFiles.contains(file)) {
    return 'cocktails/$file';
  }
  return cocktailDefaultImageAsset(glassware);
}

String cocktailDefaultImageAsset(String? glassware) {
  final g = (glassware ?? '').toLowerCase();
  if (g.contains('flute') || g.contains('champagne')) {
    return 'cocktails/_default_flute.jpg';
  }
  if (g.contains('tiki') || g.contains('mug') || g.contains('bowl')) {
    return 'cocktails/_default_tiki.jpg';
  }
  if (g.contains('highball') ||
      g.contains('collins') ||
      g.contains('tall') ||
      g.contains('zombie')) {
    return 'cocktails/_default_highball.jpg';
  }
  if (g.contains('coupe') || g.contains('martini') || g.contains('nick')) {
    return 'cocktails/_default_coupe.jpg';
  }
  if (g.contains('rocks') ||
      g.contains('old fashioned') ||
      g.contains('double')) {
    return 'cocktails/_default_rocks.jpg';
  }
  return 'cocktails/_default.jpg';
}
