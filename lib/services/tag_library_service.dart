import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed/cocktail_tags.dart';

/// Kind of free-text / combobox tag vocabulary.
enum TagKind { cuisine, flavor }

/// Suggested + user-created tags for cuisine/style and flavor profiles.
///
/// Suggested sets encourage uniformity; any tag the user types that is not
/// already known is remembered (SharedPreferences) and appears in the
/// combobox next time.
class TagLibraryService {
  TagLibraryService._();
  static final TagLibraryService instance = TagLibraryService._();

  static const _cuisineKey = 'tag_library_cuisine_v1';
  static const _flavorKey = 'tag_library_flavor_v1';

  /// Core suggested cuisine / style tags (cocktails + menus).
  static const suggestedCuisine = <String>[
    ...kSuggestedCocktailCuisineTags,
    // Chef course / region extras (deduped when merged)
    'Main',
    'Side',
    'Dessert',
    'Snack',
    'Braai',
    'Breakfast',
    'Preserves',
    'Appetizer',
    'Mediterranean',
    'Asian',
    'Indian',
    'Mexican',
    'Middle Eastern',
    'Greek',
    'African',
    'Boer',
    'South African',
  ];

  /// Core suggested flavor tags.
  static const suggestedFlavor = kSuggestedCocktailFlavorTags;

  Future<List<String>> customTags(TagKind kind) async {
    final prefs = await SharedPreferences.getInstance();
    final key = kind == TagKind.cuisine ? _cuisineKey : _flavorKey;
    return List<String>.from(prefs.getStringList(key) ?? const []);
  }

  /// Suggested + custom + [extra] (e.g. tags already on the recipe), sorted.
  Future<List<String>> options(
    TagKind kind, {
    Iterable<String> extra = const [],
  }) async {
    final suggested =
        kind == TagKind.cuisine ? suggestedCuisine : suggestedFlavor;
    final custom = await customTags(kind);
    final merged = <String>{};
    for (final t in [...suggested, ...custom, ...extra]) {
      final n = t.trim();
      if (n.isEmpty) continue;
      // Prefer first casing we saw; skip case-duplicates.
      if (merged.any((m) => m.toLowerCase() == n.toLowerCase())) continue;
      merged.add(n);
    }
    final list = merged.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  /// Remember [tag] if it is not already in suggested or custom (case-insensitive).
  Future<void> remember(TagKind kind, String tag) async {
    final t = tag.trim();
    if (t.isEmpty) return;
    final suggested =
        kind == TagKind.cuisine ? suggestedCuisine : suggestedFlavor;
    if (suggested.any((s) => s.toLowerCase() == t.toLowerCase())) return;

    final prefs = await SharedPreferences.getInstance();
    final key = kind == TagKind.cuisine ? _cuisineKey : _flavorKey;
    final custom = List<String>.from(prefs.getStringList(key) ?? const []);
    if (custom.any((c) => c.toLowerCase() == t.toLowerCase())) return;
    custom.add(t);
    custom.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    await prefs.setStringList(key, custom);
  }

  /// Remember every tag in [tags] for [kind].
  Future<void> rememberAll(TagKind kind, Iterable<String> tags) async {
    for (final t in tags) {
      await remember(kind, t);
    }
  }
}
