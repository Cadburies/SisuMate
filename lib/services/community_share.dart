import 'dart:convert';

import '../models/models.dart';

/// #323 — Community content kinds. Checklists keep working when [kind]
/// is omitted (legacy `appType` + `items` payload).
abstract final class CommunityShareKind {
  static const checklist = 'checklist';
  static const recipe = 'recipe';
  static const cocktail = 'cocktail';
  static const collection = 'collection';
  static const shopping = 'shopping';

  /// Browse chips — checklist kinds still use ChecklistGroup.appType as
  /// the stored [CommunityTemplate.category].
  static const browseCategories = <String>[
    'all',
    'checklist',
    'maintenance',
    'safety',
    recipe,
    cocktail,
    collection,
    shopping,
  ];

  static String label(String cat) => switch (cat) {
        'all' => 'All',
        'safety' => 'Safety Briefing',
        recipe => 'Chef / menus',
        cocktail => 'Cocktails',
        collection => 'Collections',
        shopping => 'Shopping',
        _ => cat.isEmpty ? cat : '${cat[0].toUpperCase()}${cat.substring(1)}',
      };

  static String importDestination(String cat) => switch (cat) {
        recipe => 'Chef',
        cocktail => 'Cocktails',
        collection => 'Collections',
        shopping => 'Shopping',
        'maintenance' => 'Maintenance',
        'safety' => 'Safety',
        _ => 'Checklists',
      };
}

/// Resolve the payload kind. Missing [kind] + checklist-shaped body
/// (the pre-#323 format) is treated as a checklist.
String communityShareKindOf(Map<String, dynamic> content) {
  final k = (content['kind'] as String?)?.trim() ?? '';
  if (k.isNotEmpty) return k;
  return CommunityShareKind.checklist;
}

String communityShareSlug(String title) => title
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'^_|_$'), '');

Map<String, dynamic> encodeChecklistContent({
  required ChecklistGroup group,
  required List<ChecklistItem> items,
}) =>
    {
      'kind': CommunityShareKind.checklist,
      'title': group.title,
      'appType': group.appType,
      'iconName': group.iconName,
      'items': items
          .map((i) => {
                'name': i.name,
                'title': i.title,
                'description': i.description,
              })
          .toList(),
    };

Map<String, dynamic> encodeRecipeContent(
  Recipe recipe,
  List<RecipeIngredient> ingredients,
) {
  final isDrink =
      recipe.recipeType == 'cocktail' || recipe.recipeType == 'syrup';
  return {
    'kind': isDrink ? CommunityShareKind.cocktail : CommunityShareKind.recipe,
    'recipeType': recipe.recipeType.isEmpty ? 'menu' : recipe.recipeType,
    'name': recipe.name,
    if (recipe.description != null) 'description': recipe.description,
    if (recipe.instructions != null) 'instructions': recipe.instructions,
    if (recipe.cuisine.isNotEmpty) 'cuisine': recipe.cuisine,
    if (recipe.flavorProfiles.isNotEmpty)
      'flavorProfiles': recipe.flavorProfiles,
    if (recipe.cookingMethod != null) 'cookingMethod': recipe.cookingMethod,
    if (recipe.winePairing != null) 'winePairing': recipe.winePairing,
    if (recipe.cocktailPairing != null)
      'cocktailPairing': recipe.cocktailPairing,
    if (recipe.prepMinutes != null) 'prepMinutes': recipe.prepMinutes,
    if (recipe.cookMinutes != null) 'cookMinutes': recipe.cookMinutes,
    if (recipe.glassware != null) 'glassware': recipe.glassware,
    if (recipe.story != null) 'story': recipe.story,
    'ingredients': ingredients
        .map((ing) => {
              'name': ing.name,
              if (ing.quantity != null) 'quantity': ing.quantity,
              if (ing.unit != null) 'unit': ing.unit,
              if (ing.substitute != null) 'substitute': ing.substitute,
              'isGarnish': ing.isGarnish,
              'isOptional': ing.isOptional,
              if (ing.garnishNotes != null) 'garnishNotes': ing.garnishNotes,
            })
        .toList(),
  };
}

Map<String, dynamic> encodeCollectionContent({
  required String name,
  required List<(Recipe, List<RecipeIngredient>)> recipes,
}) =>
    {
      'kind': CommunityShareKind.collection,
      'name': name,
      'recipes': [
        for (final (r, ings) in recipes) encodeRecipeContent(r, ings),
      ],
    };

Map<String, dynamic> encodeShoppingContent({
  required String title,
  required List<ShoppingItem> items,
}) =>
    {
      'kind': CommunityShareKind.shopping,
      'title': title,
      'items': items
          .where((i) => !i.isHidden)
          .map((i) => {
                'name': i.name,
                'quantity': i.quantity,
                if (i.unit != null) 'unit': i.unit,
                'origin': i.origin,
                if (i.notes != null) 'notes': i.notes,
              })
          .toList(),
    };

CommunityTemplate communityTemplateFromPayload({
  required String title,
  required String category,
  required Map<String, dynamic> content,
  required String description,
  required String subcategory,
  required String authorId,
}) {
  return CommunityTemplate()
    ..title = title
    ..name = communityShareSlug(title)
    ..description = description
    ..category = category
    ..subcategory = subcategory
    ..authorId = authorId
    ..content = jsonEncode(content)
    ..lastModified = DateTime.now().toUtc();
}

({Recipe recipe, List<RecipeIngredient> ingredients}) decodeSharedRecipe(
  Map<String, dynamic> raw, {
  required String recipeSupabaseId,
  required String boatId,
}) {
  final recipeType = (raw['recipeType'] as String?)?.trim();
  final recipe = Recipe()
    ..supabaseId = recipeSupabaseId
    ..boatSupabaseId = boatId
    ..name = (raw['name'] as String?) ?? ''
    ..recipeType = (recipeType == null || recipeType.isEmpty)
        ? 'menu'
        : recipeType
    ..description = raw['description'] as String?
    ..instructions = raw['instructions'] as String?
    ..cuisine = stringListFromJson(raw['cuisine'])
    ..flavorProfiles = stringListFromJson(raw['flavorProfiles'])
    ..cookingMethod = raw['cookingMethod'] as String?
    ..winePairing = raw['winePairing'] as String?
    ..cocktailPairing = raw['cocktailPairing'] as String?
    ..prepMinutes = (raw['prepMinutes'] as num?)?.toInt()
    ..cookMinutes = (raw['cookMinutes'] as num?)?.toInt()
    ..glassware = raw['glassware'] as String?
    ..story = raw['story'] as String?
    ..isBundled = false
    ..createdAt = DateTime.now()
    ..lastModified = DateTime.now().toUtc();
  final rawIngs = raw['ingredients'];
  final ingredients = <RecipeIngredient>[];
  if (rawIngs is List) {
    for (var k = 0; k < rawIngs.length; k++) {
      final ing = rawIngs[k];
      if (ing is! Map) continue;
      final m = Map<String, dynamic>.from(ing);
      ingredients.add(RecipeIngredient()
        ..supabaseId = '${recipeSupabaseId}_ing_$k'
        ..recipeSupabaseId = recipeSupabaseId
        ..name = (m['name'] as String?) ?? ''
        ..quantity = (m['quantity'] as num?)?.toDouble()
        ..unit = m['unit'] as String?
        ..substitute = m['substitute'] as String?
        ..isGarnish = m['isGarnish'] == true
        ..isOptional = m['isOptional'] == true
        ..garnishNotes = m['garnishNotes'] as String?
        ..sortOrder = k
        ..lastModified = DateTime.now().toUtc());
    }
  }
  return (recipe: recipe, ingredients: ingredients);
}
