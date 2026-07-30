import 'dart:convert';
import '../core/units.dart';
import '../models/models.dart';

/// Thrown when an import file is malformed or an item fails validation.
/// [message] is user-facing; [itemIndex] (0-based) is set when the problem is a
/// specific item so the UI can say "Item 3: ...".
class ImportException implements Exception {
  final String message;
  final int? itemIndex;
  ImportException(this.message, {this.itemIndex});

  /// A ready-to-show sentence for the import error dialog.
  String get display =>
      itemIndex == null ? message : 'Item ${itemIndex! + 1}: $message';

  @override
  String toString() => 'ImportException($display)';
}

/// A parsed, fully-validated batch ready to persist. Exactly one collection is
/// populated, selected by [kind]. Parsing is all-or-nothing: if any item is
/// invalid, [ImportService.parse] throws and nothing is returned, so callers
/// never persist a partial batch.
class ImportBatch {
  final String kind;
  final List<FuelLogEntry> fuelLogs;
  final List<InventoryItem> inventoryItems;
  final List<ImportedRecipe> recipes;
  final List<CrewMember> crewMembers;
  final List<Document> documents;
  final List<MaintenanceTask> maintenanceTasks;

  /// Group-scoped: the persisting screen sets each item's `groupSupabaseId`
  /// from the group the user is importing into (option A).
  final List<ChecklistItem> checklistItems;

  /// Category-nested: each carries its target category name; the persisting
  /// screen match-or-creates the category (option B).
  final List<ImportedShoppingItem> shoppingItems;

  const ImportBatch._({
    required this.kind,
    this.fuelLogs = const [],
    this.inventoryItems = const [],
    this.recipes = const [],
    this.crewMembers = const [],
    this.documents = const [],
    this.maintenanceTasks = const [],
    this.checklistItems = const [],
    this.shoppingItems = const [],
  });

  /// Number of top-level items in the batch (recipes count as one each).
  int get count => switch (kind) {
        ImportService.kindFuelLog => fuelLogs.length,
        ImportService.kindInventory => inventoryItems.length,
        ImportService.kindRecipe => recipes.length,
        ImportService.kindCrew => crewMembers.length,
        ImportService.kindDocument => documents.length,
        ImportService.kindMaintenance => maintenanceTasks.length,
        ImportService.kindChecklist => checklistItems.length,
        ImportService.kindShopping => shoppingItems.length,
        _ => 0,
      };

  /// SYN3: stamp every boat-scoped row with the active boat (mutates in place).
  void applyBoatId(String boatSupabaseId) {
    if (boatSupabaseId.isEmpty) return;
    for (final e in fuelLogs) {
      e.boatSupabaseId = boatSupabaseId;
    }
    for (final e in inventoryItems) {
      e.boatSupabaseId = boatSupabaseId;
    }
    for (final r in recipes) {
      r.recipe.boatSupabaseId = boatSupabaseId;
    }
    for (final e in crewMembers) {
      e.boatSupabaseId = boatSupabaseId;
    }
    for (final e in documents) {
      e.boatSupabaseId = boatSupabaseId;
    }
    for (final e in maintenanceTasks) {
      e.boatSupabaseId = boatSupabaseId;
    }
    for (final e in checklistItems) {
      e.boatSupabaseId = boatSupabaseId;
    }
    for (final s in shoppingItems) {
      s.item.boatSupabaseId = boatSupabaseId;
    }
  }
}

/// A recipe plus its ingredients, linked and ready to persist together.
class ImportedRecipe {
  final Recipe recipe;
  final List<RecipeIngredient> ingredients;
  const ImportedRecipe(this.recipe, this.ingredients);
}

/// A shopping item plus the name of the category it should live in (from the
/// file). The persisting screen match-or-creates the category and sets the
/// item's `categorySupabaseId`.
class ImportedShoppingItem {
  final ShoppingItem item;
  final String? categoryName;
  const ImportedShoppingItem(this.item, this.categoryName);
}

/// Shared JSON bulk import/export for the app (IMP1). One envelope shape for
/// every module: `{ "sisuMateImport": 1, "kind": "...", "items": [...] }`.
/// Items carry only user-facing fields; import mints the internal ones
/// (`id`/`supabaseId`/`isSynced`/`lastModified`/`boatSupabaseId`).
///
/// First cut covers Fuel & Water, Inventory, and Recipe (flat + nested).
/// The parse/export/sample methods are pure so they can be unit tested without
/// a database; callers persist the returned models through the normal repositories.
class ImportService {
  static const int formatVersion = 1;

  static const kindFuelLog = 'fuelLog';
  static const kindInventory = 'inventory';
  static const kindRecipe = 'recipe';
  static const kindCrew = 'crew';
  static const kindDocument = 'document';
  static const kindMaintenance = 'maintenance';
  static const kindChecklist = 'checklist';
  static const kindShopping = 'shopping';
  static const supportedKinds = {
    kindFuelLog,
    kindInventory,
    kindRecipe,
    kindCrew,
    kindDocument,
    kindMaintenance,
    kindChecklist,
    kindShopping,
  };

  static const _placeholderBoatId = '00000000-0000-0000-0000-000000000000';
  /// Canonical persistence types (what lands in [Recipe.recipeType]).
  static const _recipeTypes = {'menu', 'cocktail', 'syrup'};

  /// Meal-course tags accepted on Chef recipe imports; stored as `menu` plus a
  /// cuisine tag (e.g. Main, Braai). See outstanding Chef import notes.
  static const _mealCourseTypes = {
    'main': 'Main',
    'side': 'Side',
    'dessert': 'Dessert',
    'snack': 'Snack',
    'braai': 'Braai',
    'breakfast': 'Breakfast',
    'preserves': 'Preserves',
    'appetizer': 'Appetizer',
  };

  static String _mintId(String prefix, int index) =>
      'imp_${prefix}_${DateTime.now().millisecondsSinceEpoch}_$index';

  /// Prefer an explicit id from the file (re-export round-trip); else mint (IMP2).
  static String _id(Map<String, dynamic> j, String prefix, int index) {
    final raw = j['supabaseId'] ?? j['id'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    return _mintId(prefix, index);
  }

  // ── Content keys for exact-content / natural-key dedupe (IMP2) ─────────────
  // Fuel logs are intentionally excluded — identical fill-ups are distinct.

  static String contentKeyCrew(CrewMember m) => m.name.toLowerCase().trim();

  static String contentKeyInventory(InventoryItem i) =>
      '${i.name.toLowerCase().trim()}|${(i.location ?? '').toLowerCase().trim()}';

  static String contentKeyDocument(Document d) =>
      '${d.title.toLowerCase().trim()}|${d.type.toLowerCase().trim()}';

  static String contentKeyMaintenance(MaintenanceTask t) =>
      t.description.toLowerCase().trim();

  static String contentKeyChecklist(ChecklistItem i) =>
      '${i.title.toLowerCase().trim()}|${i.groupSupabaseId}';

  static String contentKeyShopping(ShoppingItem i) =>
      '${i.name.toLowerCase().trim()}|${i.origin.toLowerCase().trim()}';

  static String contentKeyRecipe(Recipe r) =>
      '${r.name.toLowerCase().trim()}|${r.recipeType.toLowerCase().trim()}';

  /// Find existing row by supabaseId first, else by [contentKey] (IMP2).
  static T? matchExisting<T>({
    required List<T> existing,
    required String incomingId,
    required String Function(T) idOf,
    required String Function(T) contentKeyOf,
    required String incomingContentKey,
  }) {
    for (final e in existing) {
      if (idOf(e) == incomingId) return e;
    }
    for (final e in existing) {
      if (contentKeyOf(e) == incomingContentKey) return e;
    }
    return null;
  }

  // ---- Import ----

  /// Parse and validate an import file. Throws [ImportException] on any problem
  /// (envelope or item level); returns a fully-mapped [ImportBatch] otherwise.
  ///
  /// When [boatSupabaseId] is non-empty (SYN3), all boat-scoped rows are stamped
  /// with that id instead of the zero UUID placeholder.
  static ImportBatch parse(String jsonText, {String? boatSupabaseId}) {
    final Object? decoded;
    try {
      decoded = jsonDecode(jsonText);
    } catch (_) {
      throw ImportException('The file is not valid JSON.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw ImportException(
          'The file must be a JSON object with "sisuMateImport", "kind" and "items".');
    }
    final version = decoded['sisuMateImport'];
    if (version is! int) {
      throw ImportException('Missing or invalid "sisuMateImport" version.');
    }
    if (version > formatVersion) {
      throw ImportException(
          'This file needs a newer version of Sisu Mate (format v$version).');
    }
    final kind = decoded['kind'];
    if (kind is! String || !supportedKinds.contains(kind)) {
      throw ImportException(
          'Unknown or unsupported "kind": ${decoded['kind']}. Expected one of: ${supportedKinds.join(', ')}.');
    }
    final rawItems = decoded['items'];
    if (rawItems is! List) {
      throw ImportException('"items" must be a list.');
    }
    if (rawItems.isEmpty) {
      throw ImportException('"items" is empty — nothing to import.');
    }

    final ImportBatch batch;
    switch (kind) {
      case kindFuelLog:
        batch = ImportBatch._(
            kind: kind,
            fuelLogs: [
              for (var i = 0; i < rawItems.length; i++)
                _parseFuel(_asMap(rawItems[i], i), i)
            ]);
      case kindInventory:
        batch = ImportBatch._(
            kind: kind,
            inventoryItems: [
              for (var i = 0; i < rawItems.length; i++)
                _parseInventory(_asMap(rawItems[i], i), i)
            ]);
      case kindRecipe:
        batch = ImportBatch._(
            kind: kind,
            recipes: [
              for (var i = 0; i < rawItems.length; i++)
                _parseRecipe(_asMap(rawItems[i], i), i)
            ]);
      case kindCrew:
        batch = ImportBatch._(
            kind: kind,
            crewMembers: [
              for (var i = 0; i < rawItems.length; i++)
                _parseCrew(_asMap(rawItems[i], i), i)
            ]);
      case kindDocument:
        batch = ImportBatch._(
            kind: kind,
            documents: [
              for (var i = 0; i < rawItems.length; i++)
                _parseDocument(_asMap(rawItems[i], i), i)
            ]);
      case kindMaintenance:
        batch = ImportBatch._(
            kind: kind,
            maintenanceTasks: [
              for (var i = 0; i < rawItems.length; i++)
                _parseMaintenance(_asMap(rawItems[i], i), i)
            ]);
      case kindChecklist:
        batch = ImportBatch._(
            kind: kind,
            checklistItems: [
              for (var i = 0; i < rawItems.length; i++)
                _parseChecklist(_asMap(rawItems[i], i), i)
            ]);
      case kindShopping:
        batch = ImportBatch._(
            kind: kind,
            shoppingItems: [
              for (var i = 0; i < rawItems.length; i++)
                _parseShopping(_asMap(rawItems[i], i), i)
            ]);
      default:
        throw ImportException('Unsupported kind: $kind');
    }
    if (boatSupabaseId != null && boatSupabaseId.isNotEmpty) {
      batch.applyBoatId(boatSupabaseId);
    }
    return batch;
  }

  static FuelLogEntry _parseFuel(Map<String, dynamic> j, int i) {
    final type = _optString(j, 'type', i) ?? 'Fuel';
    if (type != 'Fuel' && type != 'Water') {
      throw ImportException('"type" must be "Fuel" or "Water".', itemIndex: i);
    }
    // Prefer explicit liters; accept gallons / unit tag and convert to L.
    double liters;
    if (j.containsKey('gallons')) {
      liters = UnitConverter.displayVolumeToLiters(
          _requireNumber(j, 'gallons', i), UnitSystem.imperial);
    } else {
      liters = _requireNumber(j, 'liters', i);
      final unit = (_optString(j, 'unit', i) ?? '').toLowerCase();
      if (unit == 'gal' || unit == 'gallon' || unit == 'gallons') {
        liters =
            UnitConverter.displayVolumeToLiters(liters, UnitSystem.imperial);
      }
    }
    // Price: pricePerLiter is canonical storage; pricePerGallon from imperial export.
    final double pricePerLiter;
    if (j.containsKey('pricePerGallon')) {
      pricePerLiter = UnitConverter.displayPriceToPerLiter(
        _requireNumber(j, 'pricePerGallon', i),
        UnitSystem.imperial,
      );
    } else {
      pricePerLiter = _optNumber(j, 'pricePerLiter', i) ?? 0;
    }
    return FuelLogEntry()
      // Fuel always mints a new id — no dedupe (identical fill-ups are valid).
      ..supabaseId = _mintId('fuel', i)
      ..boatSupabaseId = _placeholderBoatId
      ..type = type
      ..date = _optDate(j, 'date', i) ?? DateTime.now()
      ..liters = liters
      ..pricePerLiter = pricePerLiter
      ..totalCost = liters * pricePerLiter
      ..notes = _optString(j, 'notes', i);
  }

  static InventoryItem _parseInventory(Map<String, dynamic> j, int i) {
    final rawQty = _optNumber(j, 'quantity', i) ?? 1;
    final rawUnit = _optString(j, 'unit', i);
    final (qty, unit) = UnitConverter.normalizePair(rawQty, rawUnit);
    return InventoryItem()
      ..supabaseId = _id(j, 'inv', i)
      ..boatSupabaseId = _placeholderBoatId
      ..name = _requireString(j, 'name', i)
      ..location = _optString(j, 'location', i)
      ..quantity = qty ?? 1
      ..unit = unit
      ..serialNumber = _optString(j, 'serialNumber', i)
      ..notes = _optString(j, 'notes', i);
  }

  static ImportedRecipe _parseRecipe(Map<String, dynamic> j, int i) {
    final rawType = (_optString(j, 'recipeType', i) ?? 'menu').toLowerCase();
    final courseLabel = _mealCourseTypes[rawType];
    final recipeType = courseLabel != null ? 'menu' : rawType;
    if (!_recipeTypes.contains(recipeType)) {
      throw ImportException(
          '"recipeType" must be one of: ${_recipeTypes.join(', ')} '
          '(or a meal course: ${_mealCourseTypes.keys.join(', ')}).',
          itemIndex: i);
    }
    final recipeSupabaseId = _id(j, 'recipe', i);
    final cuisine = dedupeStrings([
      ..._optStringList(j, 'cuisine', i),
      ?courseLabel,
    ]);
    final recipe = Recipe()
      ..supabaseId = recipeSupabaseId
      ..boatSupabaseId = _placeholderBoatId
      ..name = _requireString(j, 'name', i)
      ..recipeType = recipeType
      ..description = _optString(j, 'description', i)
      ..instructions = _optString(j, 'instructions', i)
      // Canonical key is glassware (Recipe.glassware); glasstype is accepted as
      // an alias for external/LLM-authored files that use that name.
      ..glassware =
          _optString(j, 'glassware', i) ?? _optString(j, 'glasstype', i)
      ..story = _optString(j, 'story', i)
      ..cuisine = cuisine
      ..flavorProfiles = dedupeStrings(_optStringList(j, 'flavorProfiles', i))
      ..cookingMethod = _optString(j, 'cookingMethod', i)
      ..prepMinutes = _optInt(j, 'prepMinutes', i)
      ..cookMinutes = _optInt(j, 'cookMinutes', i);

    // Normalize free-text temps in instructions to °C for storage.
    final instructions = recipe.instructions;
    if (instructions != null) {
      recipe.instructions = UnitConverter.convertTemperaturesInText(
        instructions,
        UnitSystem.metric,
      );
    }

    final rawIngredients = j['ingredients'];
    if (rawIngredients != null && rawIngredients is! List) {
      throw ImportException('"ingredients" must be a list.', itemIndex: i);
    }
    final ingredients = <RecipeIngredient>[];
    final rolledFlavors = <String>[...recipe.flavorProfiles];
    if (rawIngredients is List) {
      for (var k = 0; k < rawIngredients.length; k++) {
        final ing = rawIngredients[k];
        if (ing is! Map<String, dynamic>) {
          throw ImportException('ingredient ${k + 1} must be an object.',
              itemIndex: i);
        }
        // Ingredient-level flavorProfiles roll up onto the cocktail (no dups).
        rolledFlavors.addAll(_optStringList(ing, 'flavorProfiles', i));
        final (qty, unit) = UnitConverter.normalizePair(
          _optNumber(ing, 'quantity', i),
          _optString(ing, 'unit', i),
        );
        ingredients.add(RecipeIngredient()
          ..supabaseId = '${recipeSupabaseId}_ing_$k'
          ..recipeSupabaseId = recipeSupabaseId
          ..name = _requireString(ing, 'name', i)
          ..quantity = qty
          ..unit = unit
          ..substitute = _optString(ing, 'substitute', i)
          ..isGarnish = _optBool(ing, 'isGarnish', i) ?? false
          ..garnishNotes = _optString(ing, 'garnishNotes', i)
          ..isOptional = _optBool(ing, 'isOptional', i) ?? false
          ..sortOrder = k);
      }
    }
    recipe.flavorProfiles = dedupeStrings(rolledFlavors);
    return ImportedRecipe(recipe, ingredients);
  }

  static CrewMember _parseCrew(Map<String, dynamic> j, int i) {
    return CrewMember()
      ..supabaseId = _id(j, 'crew', i)
      ..boatSupabaseId = _placeholderBoatId
      ..name = _requireString(j, 'name', i)
      ..role = _optString(j, 'role', i) ?? 'Crew'
      ..phone = _optString(j, 'phone', i)
      ..email = _optString(j, 'email', i)
      ..iceContact = _optString(j, 'iceContact', i)
      ..certifications = _optString(j, 'certifications', i);
  }

  static Document _parseDocument(Map<String, dynamic> j, int i) {
    return Document()
      ..supabaseId = _id(j, 'doc', i)
      ..boatSupabaseId = _placeholderBoatId
      ..title = _requireString(j, 'title', i)
      ..type = _optString(j, 'type', i) ?? 'Other'
      ..notes = _optString(j, 'notes', i)
      ..expiry = _optDate(j, 'expiry', i);
  }

  static MaintenanceTask _parseMaintenance(Map<String, dynamic> j, int i) {
    return MaintenanceTask()
      ..supabaseId = _id(j, 'maint', i)
      ..boatSupabaseId = _placeholderBoatId
      ..description = _requireString(j, 'description', i)
      ..intervalHours = _optInt(j, 'intervalHours', i)
      ..intervalMonths = _optInt(j, 'intervalMonths', i)
      ..lastDoneHours = _optInt(j, 'lastDoneHours', i)
      ..lastDoneDate = _optDate(j, 'lastDoneDate', i)
      ..doneBy = _optString(j, 'doneBy', i)
      ..notes = _optString(j, 'notes', i);
  }

  /// Parses a checklist item. `groupSupabaseId` is left empty; the importing
  /// screen sets it to the group the user is currently in (option A).
  static ChecklistItem _parseChecklist(Map<String, dynamic> j, int i) {
    final title = _requireString(j, 'title', i);
    return ChecklistItem()
      ..supabaseId = _id(j, 'chk', i)
      ..boatSupabaseId = _placeholderBoatId
      ..title = title
      ..name = _optString(j, 'name', i) ?? title
      ..description = _optString(j, 'description', i)
      ..notes = _optString(j, 'notes', i)
      ..sortOrder = _optInt(j, 'sortOrder', i) ?? 0;
  }

  /// Parses a shopping item + its target category name. `categorySupabaseId`
  /// is set by the screen after match-or-creating the category.
  static ImportedShoppingItem _parseShopping(Map<String, dynamic> j, int i) {
    final category = _optString(j, 'category', i);
    final rawQty = (_optNumber(j, 'quantity', i) ?? 1).toDouble();
    final (qty, unit) =
        UnitConverter.normalizePair(rawQty, _optString(j, 'unit', i));
    final item = ShoppingItem()
      ..supabaseId = _id(j, 'shop', i)
      ..boatSupabaseId = _placeholderBoatId
      ..name = _requireString(j, 'name', i)
      ..quantity = (qty ?? 1).round()
      ..unit = unit
      ..notes = _optString(j, 'notes', i)
      // `origin` is the shopping screen's visible top-level grouping (the
      // category is only the container the screen iterates to find items).
      ..origin = category ?? 'spares';
    return ImportedShoppingItem(item, category);
  }

  // ---- Field readers (throw ImportException with a user-facing reason) ----

  static Map<String, dynamic> _asMap(Object? item, int i) {
    if (item is! Map<String, dynamic>) {
      throw ImportException('Expected a JSON object.', itemIndex: i);
    }
    return item;
  }

  static String _requireString(Map<String, dynamic> j, String key, int i) {
    final v = j[key];
    if (v is! String || v.trim().isEmpty) {
      throw ImportException('"$key" is required and must be text.',
          itemIndex: i);
    }
    return v;
  }

  static String? _optString(Map<String, dynamic> j, String key, int i) {
    final v = j[key];
    if (v == null) return null;
    if (v is! String) {
      throw ImportException('"$key" must be text.', itemIndex: i);
    }
    return v.isEmpty ? null : v;
  }

  /// Optional string list. Accepts a JSON array of strings, or a single string
  /// (wrapped as a one-element list) for older/LLM files that used a scalar.
  static List<String> _optStringList(Map<String, dynamic> j, String key, int i) {
    final v = j[key];
    if (v == null) return const [];
    if (v is String) {
      final t = v.trim();
      return t.isEmpty ? const [] : [t];
    }
    if (v is! List) {
      throw ImportException(
          '"$key" must be a list of text (or a single text value).',
          itemIndex: i);
    }
    final out = <String>[];
    for (var k = 0; k < v.length; k++) {
      final e = v[k];
      if (e is! String || e.trim().isEmpty) {
        throw ImportException('"$key" entries must be non-empty text.',
            itemIndex: i);
      }
      out.add(e.trim());
    }
    return out;
  }

  static double _requireNumber(Map<String, dynamic> j, String key, int i) {
    final v = j[key];
    if (v is num) return v.toDouble();
    throw ImportException('"$key" is required and must be a number.',
        itemIndex: i);
  }

  static double? _optNumber(Map<String, dynamic> j, String key, int i) {
    final v = j[key];
    if (v == null) return null;
    if (v is num) return v.toDouble();
    throw ImportException('"$key" must be a number.', itemIndex: i);
  }

  static int? _optInt(Map<String, dynamic> j, String key, int i) {
    final v = j[key];
    if (v == null) return null;
    if (v is int) return v;
    throw ImportException('"$key" must be a whole number.', itemIndex: i);
  }

  static bool? _optBool(Map<String, dynamic> j, String key, int i) {
    final v = j[key];
    if (v == null) return null;
    if (v is bool) return v;
    throw ImportException('"$key" must be true or false.', itemIndex: i);
  }

  static DateTime? _optDate(Map<String, dynamic> j, String key, int i) {
    final v = j[key];
    if (v == null) return null;
    if (v is! String) {
      throw ImportException('"$key" must be a date like "2026-07-05".',
          itemIndex: i);
    }
    final parsed = DateTime.tryParse(v);
    if (parsed == null) {
      throw ImportException('"$key" must be a date like "2026-07-05".',
          itemIndex: i);
    }
    return parsed;
  }

  // ---- Export ----

  static final _encoder = const JsonEncoder.withIndent('  ');

  static String _envelope(String kind, List<Map<String, dynamic>> items) =>
      _encoder.convert({
        'sisuMateImport': formatVersion,
        'kind': kind,
        'items': items,
      });

  static String _dateOnly(DateTime d) => d.toIso8601String().split('T')[0];

  static String exportFuelLogs(
    List<FuelLogEntry> entries, {
    UnitSystem unitSystem = UnitSystem.metric,
  }) =>
      _envelope(
        kindFuelLog,
        entries.map((e) {
          if (unitSystem == UnitSystem.imperial) {
            return {
              if (e.supabaseId.isNotEmpty) 'supabaseId': e.supabaseId,
              'type': e.type,
              'date': _dateOnly(e.date),
              'gallons': UnitConverter.litersToDisplay(
                  e.liters, UnitSystem.imperial),
              'unit': 'gal',
              'pricePerGallon': UnitConverter.pricePerLiterToDisplay(
                  e.pricePerLiter, UnitSystem.imperial),
              if (e.notes != null) 'notes': e.notes,
            };
          }
          return {
            if (e.supabaseId.isNotEmpty) 'supabaseId': e.supabaseId,
            'type': e.type,
            'date': _dateOnly(e.date),
            'liters': e.liters,
            'pricePerLiter': e.pricePerLiter,
            if (e.notes != null) 'notes': e.notes,
          };
        }).toList(),
      );

  static String exportInventory(
    List<InventoryItem> items, {
    UnitSystem unitSystem = UnitSystem.metric,
  }) =>
      _envelope(
        kindInventory,
        items.map((i) {
          final shown = UnitConverter.forDisplay(
              i.quantity, i.unit, unitSystem);
          return {
            if (i.supabaseId.isNotEmpty) 'supabaseId': i.supabaseId,
            'name': i.name,
            if (i.location != null) 'location': i.location,
            'quantity': shown?.quantity ?? i.quantity,
            if ((shown?.unit ?? i.unit) != null &&
                (shown?.unit ?? i.unit)!.isNotEmpty)
              'unit': shown?.unit ?? i.unit,
            if (i.serialNumber != null) 'serialNumber': i.serialNumber,
            if (i.notes != null) 'notes': i.notes,
          };
        }).toList(),
      );

  static String exportRecipes(
    List<ImportedRecipe> recipes, {
    UnitSystem unitSystem = UnitSystem.metric,
  }) =>
      _envelope(
        kindRecipe,
        recipes.map((r) {
          final instructions = r.recipe.instructions == null
              ? null
              : UnitConverter.convertTemperaturesInText(
                  r.recipe.instructions!, unitSystem);
          return {
            if (r.recipe.supabaseId.isNotEmpty)
              'supabaseId': r.recipe.supabaseId,
            'name': r.recipe.name,
            'recipeType': r.recipe.recipeType.isEmpty
                ? 'menu'
                : r.recipe.recipeType,
            if (r.recipe.cuisine.isNotEmpty) 'cuisine': r.recipe.cuisine,
            if (r.recipe.flavorProfiles.isNotEmpty)
              'flavorProfiles': r.recipe.flavorProfiles,
            if (r.recipe.description != null)
              'description': r.recipe.description,
            'instructions': ?instructions,
            if (r.recipe.glassware != null) 'glassware': r.recipe.glassware,
            if (r.recipe.story != null) 'story': r.recipe.story,
            if (r.recipe.prepMinutes != null)
              'prepMinutes': r.recipe.prepMinutes,
            if (r.recipe.cookMinutes != null)
              'cookMinutes': r.recipe.cookMinutes,
            'ingredients': r.ingredients.map((ing) {
              final isCocktail = r.recipe.recipeType == 'cocktail';
              final shown = UnitConverter.forDisplay(
                ing.quantity,
                ing.unit,
                unitSystem,
                preferBarUnits: isCocktail,
              );
              return {
                'name': ing.name,
                if (shown?.quantity != null || ing.quantity != null)
                  'quantity': shown?.quantity ?? ing.quantity,
                if ((shown?.unit ?? ing.unit) != null &&
                    (shown?.unit ?? ing.unit)!.isNotEmpty)
                  'unit': shown?.unit ?? ing.unit,
                if (ing.isOptional) 'isOptional': true,
                if (ing.isGarnish) 'isGarnish': true,
              };
            }).toList(),
          };
        }).toList(),
      );

  static String exportCrew(List<CrewMember> members) => _envelope(
        kindCrew,
        members
            .map((m) => {
                  if (m.supabaseId.isNotEmpty) 'supabaseId': m.supabaseId,
                  'name': m.name,
                  'role': m.role,
                  if (m.phone != null) 'phone': m.phone,
                  if (m.email != null) 'email': m.email,
                  if (m.iceContact != null) 'iceContact': m.iceContact,
                  if (m.certifications != null)
                    'certifications': m.certifications,
                })
            .toList(),
      );

  static String exportDocuments(List<Document> documents) => _envelope(
        kindDocument,
        documents
            .map((d) => {
                  if (d.supabaseId.isNotEmpty) 'supabaseId': d.supabaseId,
                  'title': d.title,
                  'type': d.type,
                  if (d.notes != null) 'notes': d.notes,
                  if (d.expiry != null) 'expiry': _dateOnly(d.expiry!),
                })
            .toList(),
      );

  static String exportMaintenance(List<MaintenanceTask> tasks) => _envelope(
        kindMaintenance,
        tasks
            .map((t) => {
                  if (t.supabaseId.isNotEmpty) 'supabaseId': t.supabaseId,
                  'description': t.description,
                  if (t.intervalHours != null) 'intervalHours': t.intervalHours,
                  if (t.intervalMonths != null)
                    'intervalMonths': t.intervalMonths,
                  if (t.lastDoneHours != null) 'lastDoneHours': t.lastDoneHours,
                  if (t.lastDoneDate != null)
                    'lastDoneDate': _dateOnly(t.lastDoneDate!),
                  if (t.doneBy != null) 'doneBy': t.doneBy,
                  if (t.notes != null) 'notes': t.notes,
                })
            .toList(),
      );

  static String exportChecklist(List<ChecklistItem> items) => _envelope(
        kindChecklist,
        items
            .map((it) => {
                  if (it.supabaseId.isNotEmpty) 'supabaseId': it.supabaseId,
                  'title': it.title,
                  if (it.description != null) 'description': it.description,
                  if (it.notes != null) 'notes': it.notes,
                  'sortOrder': it.sortOrder,
                })
            .toList(),
      );

  static String exportShopping(
    List<ImportedShoppingItem> items, {
    UnitSystem unitSystem = UnitSystem.metric,
  }) =>
      _envelope(
        kindShopping,
        items.map((s) {
          final shown = UnitConverter.forDisplay(
            s.item.quantity.toDouble(),
            s.item.unit,
            unitSystem,
          );
          return {
            if (s.item.supabaseId.isNotEmpty) 'supabaseId': s.item.supabaseId,
            'name': s.item.name,
            // export the visible group (origin), which round-trips back
            // into both origin and the category on re-import
            'category': s.item.origin,
            'quantity': shown?.quantity.round() ?? s.item.quantity,
            if ((shown?.unit ?? s.item.unit) != null &&
                (shown?.unit ?? s.item.unit)!.isNotEmpty)
              'unit': shown?.unit ?? s.item.unit,
            if (s.item.notes != null) 'notes': s.item.notes,
          };
        }).toList(),
      );

  /// A worked example for [kind] — shown on the import screen so the user knows
  /// the shape, and written out by "Export sample template" (the file to hand
  /// an LLM as the target format).
  static String sampleFor(String kind) {
    switch (kind) {
      case kindFuelLog:
        return _envelope(kindFuelLog, [
          {
            'type': 'Fuel',
            'date': '2026-07-05',
            'liters': 40,
            'pricePerLiter': 2.00,
            'notes': 'Marina top-up'
          },
          {'type': 'Water', 'date': '2026-07-05', 'liters': 200},
        ]);
      case kindInventory:
        return _envelope(kindInventory, [
          {
            'name': 'Fenders',
            'location': 'Lazarette',
            'quantity': 4,
            'unit': 'pcs',
            'serialNumber': 'SN-99'
          },
        ]);
      case kindRecipe:
        return _envelope(kindRecipe, [
          {
            'name': 'Mai Tai',
            'recipeType': 'cocktail',
            'cuisine': ['Tiki', 'Classic'],
            'flavorProfiles': ['tropical', 'citrus', 'balanced'],
            'description':
                'The classic tiki cocktail from Trader Vic\'s — rum, lime, and almond.',
            'glassware': 'Double rocks glass',
            'story':
                'Trader Vic claimed the Mai Tai for a Tahitian friend who tasted it and said "mai tai — roa aé" ("out of this world — the best").',
            'instructions': 'Shake with crushed ice; garnish with mint.',
            'ingredients': [
              {
                'name': 'aged rum',
                'quantity': 60,
                'unit': 'ml',
                'flavorProfiles': ['rum-forward', 'bold'],
              },
              {'name': 'lime', 'quantity': 1, 'unit': 'whole'},
              {'name': 'mint', 'isGarnish': true},
            ],
          },
        ]);
      case kindCrew:
        return _envelope(kindCrew, [
          {
            'name': 'Skipper Ada',
            'role': 'Captain',
            'phone': '+358 40 123 4567',
            'iceContact': 'Next of kin: +358 40 000 0000',
            'certifications': 'RYA Yachtmaster'
          },
        ]);
      case kindDocument:
        return _envelope(kindDocument, [
          {
            'title': 'Boat Registration',
            'type': 'Registration',
            'expiry': '2027-06-01',
            'notes': 'Renewed annually'
          },
        ]);
      case kindMaintenance:
        return _envelope(kindMaintenance, [
          {
            'description': 'Engine oil change',
            'intervalHours': 250,
            'intervalMonths': 12,
            'lastDoneHours': 1200,
            'lastDoneDate': '2026-05-01',
            'doneBy': 'Jo'
          },
        ]);
      case kindChecklist:
        return _envelope(kindChecklist, [
          {
            'title': 'Check bilge pump',
            'description': 'Confirm the automatic float switch works',
            'sortOrder': 0
          },
          {'title': 'Test navigation lights', 'sortOrder': 1},
        ]);
      case kindShopping:
        return _envelope(kindShopping, [
          {
            'name': 'Fenders',
            'category': 'Deck Gear',
            'quantity': 4,
            'unit': 'pcs'
          },
          {'name': 'Engine oil', 'category': 'Engine', 'quantity': 2, 'unit': 'L'},
        ]);
      default:
        throw ArgumentError('No sample for kind: $kind');
    }
  }
}
