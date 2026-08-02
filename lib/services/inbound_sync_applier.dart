import 'dart:convert';

import 'package:drift/drift.dart';

import '../data/drift/app_database.dart';
import '../models/models.dart';

/// Applies remote Supabase JSON into Drift for tables that participate in
/// realtime inbound sync. Used by [SyncService] (T5).
class InboundSyncApplier {
  final AppDatabase db;

  InboundSyncApplier(this.db);

  /// All tables with two-way sync (outbound queue + inbound apply). SYN1/SYN2.
  static const syncedTables = {
    'boats',
    'checklist_groups',
    'checklist_items',
    'shopping_categories',
    'shopping_items',
    'captain_logs',
    'maintenance_tasks',
    // SYN1 — were outbound-only
    'documents',
    'crew_members',
    'inventory_items',
    'fuel_logs',
    // SYN2 — recipes & stock
    'recipes',
    'recipe_ingredients',
    'bar_ingredients',
    'pantry_ingredients',
  };

  bool supports(String table) => syncedTables.contains(table);

  /// Normalise remote map keys so domain [fromJson] works (id → supabaseId).
  Map<String, dynamic> normalizeRemote(Map<String, dynamic> raw) {
    final m = Map<String, dynamic>.from(raw);
    if ((m['supabaseId'] == null || (m['supabaseId'] as String?)?.isEmpty == true) &&
        m['id'] != null) {
      m['supabaseId'] = m['id'].toString();
    }
    // Ensure required timestamp strings for fromJson.
    m['lastModified'] ??= DateTime.now().toUtc().toIso8601String();
    m['createdAt'] ??= m['lastModified'];
    if (m['logDate'] == null && m.containsKey('date') && m['date'] is String) {
      // fuel_logs use `date`; captain logs use `logDate`
      m['logDate'] ??= m['date'];
    }
    return m;
  }

  String recordId(Map<String, dynamic> remote) {
    final n = normalizeRemote(remote);
    return (n['supabaseId'] as String?) ?? '';
  }

  DateTime? remoteLastModified(Map<String, dynamic> remote) {
    final v = normalizeRemote(remote)['lastModified'];
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  /// Local domain snapshot as JSON, or null if missing.
  Future<({Map<String, dynamic> json, bool isSynced, DateTime lastModified})?>
      getLocal(String table, String supabaseId) async {
    if (supabaseId.isEmpty) return null;
    switch (table) {
      case 'boats':
        final r = await (db.select(db.boats)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .getSingleOrNull();
        if (r == null) return null;
        final d = _boatDomain(r);
        return (json: d.toJson(), isSynced: d.isSynced, lastModified: d.lastModified);
      case 'checklist_groups':
        final r = await (db.select(db.checklistGroups)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .getSingleOrNull();
        if (r == null) return null;
        final d = _groupDomain(r);
        return (json: d.toJson(), isSynced: d.isSynced, lastModified: d.lastModified);
      case 'checklist_items':
        final r = await (db.select(db.checklistItems)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .getSingleOrNull();
        if (r == null) return null;
        final d = _itemDomain(r);
        return (json: d.toJson(), isSynced: d.isSynced, lastModified: d.lastModified);
      case 'shopping_categories':
        final r = await (db.select(db.shoppingCategories)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .getSingleOrNull();
        if (r == null) return null;
        final d = _shopCatDomain(r);
        return (json: d.toJson(), isSynced: d.isSynced, lastModified: d.lastModified);
      case 'shopping_items':
        final r = await (db.select(db.shoppingItems)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .getSingleOrNull();
        if (r == null) return null;
        final d = _shopItemDomain(r);
        return (json: d.toJson(), isSynced: d.isSynced, lastModified: d.lastModified);
      case 'captain_logs':
        final r = await (db.select(db.captainLogEntries)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .getSingleOrNull();
        if (r == null) return null;
        final d = _logDomain(r);
        return (json: d.toJson(), isSynced: d.isSynced, lastModified: d.lastModified);
      case 'maintenance_tasks':
        final r = await (db.select(db.maintenanceTasks)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .getSingleOrNull();
        if (r == null) return null;
        final d = _maintDomain(r);
        return (json: d.toJson(), isSynced: d.isSynced, lastModified: d.lastModified);
      case 'documents':
        final r = await (db.select(db.documents)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .getSingleOrNull();
        if (r == null) return null;
        final d = _docDomain(r);
        return (json: d.toJson(), isSynced: d.isSynced, lastModified: d.lastModified);
      case 'crew_members':
        final r = await (db.select(db.crewMembers)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .getSingleOrNull();
        if (r == null) return null;
        final d = _crewDomain(r);
        return (json: d.toJson(), isSynced: d.isSynced, lastModified: d.lastModified);
      case 'inventory_items':
        final r = await (db.select(db.inventoryItems)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .getSingleOrNull();
        if (r == null) return null;
        final d = _invDomain(r);
        return (json: d.toJson(), isSynced: d.isSynced, lastModified: d.lastModified);
      case 'fuel_logs':
        final r = await (db.select(db.fuelLogEntries)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .getSingleOrNull();
        if (r == null) return null;
        final d = _fuelDomain(r);
        return (json: d.toJson(), isSynced: d.isSynced, lastModified: d.lastModified);
      case 'recipes':
        final r = await (db.select(db.recipes)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .getSingleOrNull();
        if (r == null) return null;
        final d = _recipeDomain(r);
        return (json: d.toJson(), isSynced: d.isSynced, lastModified: d.lastModified);
      case 'recipe_ingredients':
        final r = await (db.select(db.recipeIngredients)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .getSingleOrNull();
        if (r == null) return null;
        final d = _recipeIngDomain(r);
        return (json: d.toJson(), isSynced: d.isSynced, lastModified: d.lastModified);
      case 'bar_ingredients':
        final r = await (db.select(db.barIngredients)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .getSingleOrNull();
        if (r == null) return null;
        final d = _barDomain(r);
        return (json: d.toJson(), isSynced: d.isSynced, lastModified: d.lastModified);
      case 'pantry_ingredients':
        final r = await (db.select(db.pantryIngredients)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .getSingleOrNull();
        if (r == null) return null;
        final d = _pantryDomain(r);
        return (json: d.toJson(), isSynced: d.isSynced, lastModified: d.lastModified);
      default:
        return null;
    }
  }

  /// Upsert remote into Drift and mark [isSynced] true (inbound accepted).
  Future<void> applyRemote(String table, Map<String, dynamic> remote) async {
    final n = normalizeRemote(remote);
    n['isSynced'] = true;
    final id = n['supabaseId'] as String? ?? '';
    if (id.isEmpty) return;

    switch (table) {
      case 'boats':
        await _upsertBoat(Boat.fromJson(n)..isSynced = true);
      case 'checklist_groups':
        await _upsertGroup(ChecklistGroup.fromJson(n)..isSynced = true);
      case 'checklist_items':
        await _upsertItem(ChecklistItem.fromJson(n)..isSynced = true);
      case 'shopping_categories':
        await _upsertShopCat(ShoppingCategory.fromJson(n)..isSynced = true);
      case 'shopping_items':
        await _upsertShopItem(ShoppingItem.fromJson(n)..isSynced = true);
      case 'captain_logs':
        await _upsertLog(CaptainLogEntry.fromJson(n)..isSynced = true);
      case 'maintenance_tasks':
        await _upsertMaint(MaintenanceTask.fromJson(n)..isSynced = true);
      case 'documents':
        await _upsertDoc(Document.fromJson(n)..isSynced = true);
      case 'crew_members':
        await _upsertCrew(CrewMember.fromJson(n)..isSynced = true);
      case 'inventory_items':
        await _upsertInv(InventoryItem.fromJson(n)..isSynced = true);
      case 'fuel_logs':
        await _upsertFuel(FuelLogEntry.fromJson(n)..isSynced = true);
      case 'recipes':
        await _upsertRecipe(Recipe.fromJson(n)..isSynced = true);
      case 'recipe_ingredients':
        await _upsertRecipeIng(RecipeIngredient.fromJson(n)..isSynced = true);
      case 'bar_ingredients':
        await _upsertBar(BarIngredient.fromJson(n)..isSynced = true);
      case 'pantry_ingredients':
        await _upsertPantry(PantryIngredient.fromJson(n)..isSynced = true);
    }
  }

  /// Hard-delete a local Drift row by domain [supabaseId] (unprefixed).
  /// Used when the remote stream snapshot no longer contains the row.
  Future<void> deleteLocal(String table, String supabaseId) async {
    if (supabaseId.isEmpty) return;
    switch (table) {
      case 'boats':
        await (db.delete(db.boats)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .go();
      case 'checklist_groups':
        await (db.delete(db.checklistGroups)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .go();
      case 'checklist_items':
        await (db.delete(db.checklistItems)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .go();
      case 'shopping_categories':
        await (db.delete(db.shoppingCategories)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .go();
      case 'shopping_items':
        await (db.delete(db.shoppingItems)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .go();
      case 'captain_logs':
        await (db.delete(db.captainLogEntries)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .go();
      case 'maintenance_tasks':
        await (db.delete(db.maintenanceTasks)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .go();
      case 'documents':
        await (db.delete(db.documents)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .go();
      case 'crew_members':
        await (db.delete(db.crewMembers)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .go();
      case 'inventory_items':
        await (db.delete(db.inventoryItems)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .go();
      case 'fuel_logs':
        await (db.delete(db.fuelLogEntries)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .go();
      case 'recipes':
        await (db.delete(db.recipes)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .go();
      case 'recipe_ingredients':
        await (db.delete(db.recipeIngredients)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .go();
      case 'bar_ingredients':
        await (db.delete(db.barIngredients)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .go();
      case 'pantry_ingredients':
        await (db.delete(db.pantryIngredients)
              ..where((t) => t.supabaseId.equals(supabaseId)))
            .go();
    }
  }

  /// Local `supabaseId`s eligible for remote hard-delete reconcile.
  ///
  /// Excludes:
  /// - unsynced local rows
  /// - **bundled seed** rows (`isBundled`) where the column exists
  /// - **factory-baseline** rows (`lastModified` ≤ factory epoch) — seed stamps
  ///   `isSynced=true` + epoch so they lose LWW to real edits, but Supabase
  ///   streams often start empty for a boat that never uploaded seed content.
  ///   Reconciling those empties hard-deleted every checklist/recipe/bar row.
  Future<List<String>> listLocalSyncedIds(String table) async {
    // Import-safe epoch (same as DatabaseService.factoryEpoch).
    final factoryEpoch = DateTime.utc(2000);
    switch (table) {
      case 'boats':
        return (await (db.select(db.boats)
                  ..where((t) =>
                      t.isSynced.equals(true) &
                      t.lastModified.isBiggerThanValue(factoryEpoch)))
                .get())
            .map((r) => r.supabaseId)
            .toList();
      case 'checklist_groups':
        return (await (db.select(db.checklistGroups)
                  ..where((t) =>
                      t.isSynced.equals(true) &
                      t.isBundled.equals(false) &
                      t.lastModified.isBiggerThanValue(factoryEpoch)))
                .get())
            .map((r) => r.supabaseId)
            .toList();
      case 'checklist_items':
        return (await (db.select(db.checklistItems)
                  ..where((t) =>
                      t.isSynced.equals(true) &
                      t.isBundled.equals(false) &
                      t.lastModified.isBiggerThanValue(factoryEpoch)))
                .get())
            .map((r) => r.supabaseId)
            .toList();
      case 'shopping_categories':
        return (await (db.select(db.shoppingCategories)
                  ..where((t) =>
                      t.isSynced.equals(true) &
                      t.lastModified.isBiggerThanValue(factoryEpoch)))
                .get())
            .map((r) => r.supabaseId)
            .toList();
      case 'shopping_items':
        return (await (db.select(db.shoppingItems)
                  ..where((t) =>
                      t.isSynced.equals(true) &
                      t.isBundled.equals(false) &
                      t.lastModified.isBiggerThanValue(factoryEpoch)))
                .get())
            .map((r) => r.supabaseId)
            .toList();
      case 'captain_logs':
        return (await (db.select(db.captainLogEntries)
                  ..where((t) =>
                      t.isSynced.equals(true) &
                      t.lastModified.isBiggerThanValue(factoryEpoch)))
                .get())
            .map((r) => r.supabaseId)
            .toList();
      case 'maintenance_tasks':
        return (await (db.select(db.maintenanceTasks)
                  ..where((t) =>
                      t.isSynced.equals(true) &
                      t.lastModified.isBiggerThanValue(factoryEpoch)))
                .get())
            .map((r) => r.supabaseId)
            .toList();
      case 'documents':
        return (await (db.select(db.documents)
                  ..where((t) =>
                      t.isSynced.equals(true) &
                      t.lastModified.isBiggerThanValue(factoryEpoch)))
                .get())
            .map((r) => r.supabaseId)
            .toList();
      case 'crew_members':
        return (await (db.select(db.crewMembers)
                  ..where((t) =>
                      t.isSynced.equals(true) &
                      t.lastModified.isBiggerThanValue(factoryEpoch)))
                .get())
            .map((r) => r.supabaseId)
            .toList();
      case 'inventory_items':
        return (await (db.select(db.inventoryItems)
                  ..where((t) =>
                      t.isSynced.equals(true) &
                      t.lastModified.isBiggerThanValue(factoryEpoch)))
                .get())
            .map((r) => r.supabaseId)
            .toList();
      case 'fuel_logs':
        return (await (db.select(db.fuelLogEntries)
                  ..where((t) =>
                      t.isSynced.equals(true) &
                      t.lastModified.isBiggerThanValue(factoryEpoch)))
                .get())
            .map((r) => r.supabaseId)
            .toList();
      case 'recipes':
        return (await (db.select(db.recipes)
                  ..where((t) =>
                      t.isSynced.equals(true) &
                      t.isBundled.equals(false) &
                      t.lastModified.isBiggerThanValue(factoryEpoch)))
                .get())
            .map((r) => r.supabaseId)
            .toList();
      case 'recipe_ingredients':
        final bundledRecipeIds = (await (db.select(db.recipes)
                  ..where((t) => t.isBundled.equals(true)))
                .get())
            .map((r) => r.supabaseId)
            .toSet();
        return (await (db.select(db.recipeIngredients)
                  ..where((t) =>
                      t.isSynced.equals(true) &
                      t.lastModified.isBiggerThanValue(factoryEpoch)))
                .get())
            .where((r) => !bundledRecipeIds.contains(r.recipeSupabaseId))
            .map((r) => r.supabaseId)
            .toList();
      case 'bar_ingredients':
        return (await (db.select(db.barIngredients)
                  ..where((t) =>
                      t.isSynced.equals(true) &
                      t.isBundled.equals(false) &
                      t.lastModified.isBiggerThanValue(factoryEpoch)))
                .get())
            .map((r) => r.supabaseId)
            .toList();
      case 'pantry_ingredients':
        return (await (db.select(db.pantryIngredients)
                  ..where((t) =>
                      t.isSynced.equals(true) &
                      t.isBundled.equals(false) &
                      t.lastModified.isBiggerThanValue(factoryEpoch)))
                .get())
            .map((r) => r.supabaseId)
            .toList();
      default:
        return const [];
    }
  }

  // ── Domain mappers (mirror repository_impl) ──────────────────────────────

  Boat _boatDomain(BoatRow r) => Boat()
    ..id = r.id
    ..supabaseId = r.supabaseId
    ..name = r.name
    ..isBought = r.isBought
    ..isHidden = r.isHidden
    ..isSynced = r.isSynced
    ..lastPurchasePrice = r.lastPurchasePrice
    ..notes = r.notes
    ..origin = r.origin
    ..photoUrl = r.photoUrl
    ..ownerId = r.ownerId
    ..shareCode = r.shareCode
    ..lastModified = r.lastModified;

  ChecklistGroup _groupDomain(ChecklistGroupRow r) => ChecklistGroup()
    ..id = r.id
    ..supabaseId = r.supabaseId
    ..boatSupabaseId = r.boatSupabaseId
    ..appType = r.appType
    ..title = r.title
    ..description = r.description
    ..iconName = r.iconName
    ..isBought = r.isBought
    ..isBundled = r.isBundled
    ..isExpanded = r.isExpanded
    ..isHidden = r.isHidden
    ..isSynced = r.isSynced
    ..lastPurchasePrice = r.lastPurchasePrice
    ..notes = r.notes
    ..origin = r.origin
    ..sortOrder = r.sortOrder
    ..lastModified = r.lastModified
    ..communityTemplateId = r.communityTemplateId
    ..communityTemplateVersion = r.communityTemplateVersion;

  ChecklistItem _itemDomain(ChecklistItemRow r) => ChecklistItem()
    ..id = r.id
    ..supabaseId = r.supabaseId
    ..boatSupabaseId = r.boatSupabaseId
    ..groupSupabaseId = r.groupSupabaseId
    ..title = r.title
    ..name = r.name
    ..description = r.description
    ..assetName = r.assetName
    ..photoUrl = r.photoUrl
    ..userPhotoUrl = r.userPhotoUrl
    ..userPhotoPath = r.userPhotoPath
    ..notes = r.notes
    ..isCompleted = r.isCompleted
    ..completedAt = r.completedAt
    ..completionHistory =
        (jsonDecode(r.completionHistory) as List).cast<String>()
    ..isBundled = r.isBundled
    ..isHidden = r.isHidden
    ..isPermanentlyDeleted = r.isPermanentlyDeleted
    ..isSynced = r.isSynced
    ..createdAt = r.createdAt
    ..sortOrder = r.sortOrder
    ..lastModified = r.lastModified;

  ShoppingCategory _shopCatDomain(ShoppingCategoryRow r) => ShoppingCategory()
    ..id = r.id
    ..supabaseId = r.supabaseId
    ..boatSupabaseId = r.boatSupabaseId
    ..name = r.name
    ..sortOrder = r.sortOrder
    ..isSynced = r.isSynced
    ..lastModified = r.lastModified;

  ShoppingItem _shopItemDomain(ShoppingItemRow r) => ShoppingItem()
    ..id = r.id
    ..supabaseId = r.supabaseId
    ..boatSupabaseId = r.boatSupabaseId
    ..categorySupabaseId = r.categorySupabaseId
    ..name = r.name
    ..quantity = r.quantity
    ..unit = r.unit
    ..isBought = r.isBought
    ..isBundled = r.isBundled
    ..isSynced = r.isSynced
    ..isHidden = r.isHidden
    ..notes = r.notes
    ..origin = r.origin
    ..lastPurchasePrice = r.lastPurchasePrice
    ..lastPurchasePlace = r.lastPurchasePlace
    ..userPhotoUrl = r.userPhotoUrl
    ..lastModified = r.lastModified;

  CaptainLogEntry _logDomain(CaptainLogEntryRow r) => CaptainLogEntry()
    ..id = r.id
    ..supabaseId = r.supabaseId
    ..boatSupabaseId = r.boatSupabaseId
    ..logDate = r.logDate
    ..title = r.title
    ..logTime = r.logTime
    ..positionLat = r.positionLat
    ..positionLng = r.positionLng
    ..weather = r.weather
    ..windSpeedKt = r.windSpeedKt
    ..windDir = r.windDir
    ..crewOnBoard = (jsonDecode(r.crewOnBoard) as List).cast<String>()
    ..notes = r.notes
    ..photos = (jsonDecode(r.photos) as List).cast<String>()
    ..isSynced = r.isSynced
    ..lastModified = r.lastModified;

  MaintenanceTask _maintDomain(MaintenanceTaskRow r) => MaintenanceTask()
    ..id = r.id
    ..supabaseId = r.supabaseId
    ..boatSupabaseId = r.boatSupabaseId
    ..description = r.description
    ..intervalHours = r.intervalHours
    ..intervalMonths = r.intervalMonths
    ..lastDoneHours = r.lastDoneHours
    ..lastDoneDate = r.lastDoneDate
    ..doneBy = r.doneBy
    ..notes = r.notes
    ..isHidden = r.isHidden
    ..isSynced = r.isSynced
    ..lastModified = r.lastModified;

  Document _docDomain(DocumentRow r) => Document()
    ..id = r.id
    ..supabaseId = r.supabaseId
    ..boatSupabaseId = r.boatSupabaseId
    ..title = r.title
    ..type = r.type
    ..fileUrl = r.fileUrl
    ..localPath = r.localPath
    ..notes = r.notes
    ..expiry = r.expiry
    ..isSynced = r.isSynced
    ..lastModified = r.lastModified;

  CrewMember _crewDomain(CrewMemberRow r) => CrewMember()
    ..id = r.id
    ..supabaseId = r.supabaseId
    ..boatSupabaseId = r.boatSupabaseId
    ..name = r.name
    ..role = r.role
    ..phone = r.phone
    ..email = r.email
    ..iceContact = r.iceContact
    ..certifications = r.certifications
    ..localPath = r.localPath
    ..isSynced = r.isSynced
    ..lastModified = r.lastModified;

  InventoryItem _invDomain(InventoryItemRow r) => InventoryItem()
    ..id = r.id
    ..supabaseId = r.supabaseId
    ..boatSupabaseId = r.boatSupabaseId
    ..name = r.name
    ..location = r.location
    ..quantity = r.quantity
    ..unit = r.unit
    ..serialNumber = r.serialNumber
    ..notes = r.notes
    ..localPath = r.localPath
    ..isSynced = r.isSynced
    ..lastModified = r.lastModified;

  FuelLogEntry _fuelDomain(FuelLogEntryRow r) => FuelLogEntry()
    ..id = r.id
    ..supabaseId = r.supabaseId
    ..boatSupabaseId = r.boatSupabaseId
    ..date = r.date
    ..type = r.type
    ..liters = r.liters
    ..pricePerLiter = r.pricePerLiter
    ..totalCost = r.totalCost
    ..notes = r.notes
    ..isSynced = r.isSynced
    ..lastModified = r.lastModified;

  Recipe _recipeDomain(RecipeRow r) => Recipe()
    ..id = r.id
    ..supabaseId = r.supabaseId
    ..boatSupabaseId = r.boatSupabaseId
    ..name = r.name
    ..description = r.description
    ..instructions = r.instructions
    ..recipeType = r.recipeType
    ..createdAt = r.createdAt
    ..isBundled = r.isBundled
    ..isSynced = r.isSynced
    ..missingIngredientCount = r.missingIngredientCount
    ..isFavourite = r.isFavourite
    ..glassware = r.glassware
    ..prepMinutes = r.prepMinutes
    ..cookMinutes = r.cookMinutes
    ..story = r.story
    ..tastingLog = (jsonDecode(r.tastingLog) as List)
        .map((e) => TastingRecord.fromJson(e as Map<String, dynamic>))
        .toList()
    ..cuisine = stringListFromJson(
        r.cuisine.startsWith('[') ? jsonDecode(r.cuisine) : r.cuisine)
    ..flavorProfiles = stringListFromJson(r.flavorProfiles.startsWith('[')
        ? jsonDecode(r.flavorProfiles)
        : r.flavorProfiles)
    ..cookingMethod = r.cookingMethod
    ..imageAsset = r.imageAsset
    ..localPath = r.localPath
    ..lastModified = r.lastModified;

  RecipeIngredient _recipeIngDomain(RecipeIngredientRow r) => RecipeIngredient()
    ..id = r.id
    ..supabaseId = r.supabaseId
    ..recipeSupabaseId = r.recipeSupabaseId
    ..name = r.name
    ..quantity = r.quantity
    ..unit = r.unit
    ..substitute = r.substitute
    ..isGarnish = r.isGarnish
    ..garnishNotes = r.garnishNotes
    ..isOptional = r.isOptional
    ..photoUrl = r.photoUrl
    ..sortOrder = r.sortOrder
    ..isSynced = r.isSynced
    ..lastModified = r.lastModified;

  BarIngredient _barDomain(BarIngredientRow r) => BarIngredient()
    ..id = r.id
    ..supabaseId = r.supabaseId
    ..boatSupabaseId = r.boatSupabaseId
    ..name = r.name
    ..inMyBar = r.inMyBar
    ..sortOrder = r.sortOrder
    ..isBundled = r.isBundled
    ..isSynced = r.isSynced
    ..category = r.category
    ..flavorProfiles = (jsonDecode(r.flavorProfiles) as List).cast<String>()
    ..alcoholByVolume = r.alcoholByVolume
    ..substitute1 = r.substitute1
    ..substitute2 = r.substitute2
    ..localPhotoPath = r.localPhotoPath
    ..imageUrl = r.imageUrl
    ..lastKnownPrice = r.lastKnownPrice
    ..priceCurrency = r.priceCurrency
    ..lastKnownPriceUnit = r.lastKnownPriceUnit
    ..lastPurchasePlace = r.lastPurchasePlace
    ..purchaseHistory = (jsonDecode(r.purchaseHistory) as List)
        .map((e) => PurchaseRecord.fromJson(e as Map<String, dynamic>))
        .toList()
    ..lastModified = r.lastModified;

  PantryIngredient _pantryDomain(PantryIngredientRow r) => PantryIngredient()
    ..id = r.id
    ..supabaseId = r.supabaseId
    ..boatSupabaseId = r.boatSupabaseId
    ..name = r.name
    ..inMyPantry = r.inMyPantry
    ..quantity = r.quantity
    ..unit = r.unit
    ..sortOrder = r.sortOrder
    ..isBundled = r.isBundled
    ..isSynced = r.isSynced
    ..category = r.category
    ..flavorProfiles = (jsonDecode(r.flavorProfiles) as List).cast<String>()
    ..cuisineTypes = (jsonDecode(r.cuisineTypes) as List).cast<String>()
    ..allergenTags = (jsonDecode(r.allergenTags) as List).cast<String>()
    ..dietaryTags = (jsonDecode(r.dietaryTags) as List).cast<String>()
    ..substitute1 = r.substitute1
    ..substitute2 = r.substitute2
    ..localPhotoPath = r.localPhotoPath
    ..imageUrl = r.imageUrl
    ..expiryDate = r.expiryDate
    ..lastKnownPrice = r.lastKnownPrice
    ..priceCurrency = r.priceCurrency
    ..lastKnownPriceUnit = r.lastKnownPriceUnit
    ..lastPurchasePlace = r.lastPurchasePlace
    ..purchaseHistory = (jsonDecode(r.purchaseHistory) as List)
        .map((e) => PurchaseRecord.fromJson(e as Map<String, dynamic>))
        .toList()
    ..caloriesPer100g = r.caloriesPer100g
    ..proteinPer100g = r.proteinPer100g
    ..fatPer100g = r.fatPer100g
    ..carbsPer100g = r.carbsPer100g
    ..lastModified = r.lastModified;

  Future<void> _upsertBoat(Boat b) async {
    final existing = await (db.select(db.boats)
          ..where((t) => t.supabaseId.equals(b.supabaseId)))
        .getSingleOrNull();
    final c = BoatsCompanion(
      supabaseId: Value(b.supabaseId),
      name: Value(b.name),
      isBought: Value(b.isBought),
      isHidden: Value(b.isHidden),
      isSynced: Value(b.isSynced),
      lastPurchasePrice: Value(b.lastPurchasePrice),
      notes: Value(b.notes),
      origin: Value(b.origin),
      photoUrl: Value(b.photoUrl),
      ownerId: Value(b.ownerId),
      shareCode: Value(b.shareCode),
      lastModified: Value(b.lastModified),
      llmApiKeyShared: Value(b.llmApiKeyShared),
      // #215: only ever adopt an inbound key when it's actively being
      // shared by the owner — Value.absent() leaves the column untouched,
      // so a device's own local (unshared) key survives an inbound sync of
      // someone else's "not sharing" state instead of being silently wiped.
      llmApiKey: b.llmApiKeyShared ? Value(b.llmApiKey) : const Value.absent(),
      llmApiKeyProvider: b.llmApiKeyShared
          ? Value(b.llmApiKeyProvider)
          : const Value.absent(),
    );
    if (existing == null) {
      await db.into(db.boats).insert(c);
    } else {
      await (db.update(db.boats)..where((t) => t.id.equals(existing.id)))
          .write(c);
    }
  }

  Future<void> _upsertGroup(ChecklistGroup g) async {
    final existing = await (db.select(db.checklistGroups)
          ..where((t) => t.supabaseId.equals(g.supabaseId)))
        .getSingleOrNull();
    final c = ChecklistGroupsCompanion(
      supabaseId: Value(g.supabaseId),
      boatSupabaseId: Value(g.boatSupabaseId),
      appType: Value(g.appType),
      title: Value(g.title),
      description: Value(g.description),
      iconName: Value(g.iconName),
      isBought: Value(g.isBought),
      isBundled: Value(g.isBundled),
      isExpanded: Value(g.isExpanded),
      isHidden: Value(g.isHidden),
      isSynced: Value(g.isSynced),
      lastPurchasePrice: Value(g.lastPurchasePrice),
      notes: Value(g.notes),
      origin: Value(g.origin),
      sortOrder: Value(g.sortOrder),
      lastModified: Value(g.lastModified),
      communityTemplateId: Value(g.communityTemplateId),
      communityTemplateVersion: Value(g.communityTemplateVersion),
    );
    if (existing == null) {
      await db.into(db.checklistGroups).insert(c);
    } else {
      await (db.update(db.checklistGroups)
            ..where((t) => t.id.equals(existing.id)))
          .write(c);
    }
  }

  Future<void> _upsertItem(ChecklistItem i) async {
    final existing = await (db.select(db.checklistItems)
          ..where((t) => t.supabaseId.equals(i.supabaseId)))
        .getSingleOrNull();
    final c = ChecklistItemsCompanion(
      supabaseId: Value(i.supabaseId),
      boatSupabaseId: Value(i.boatSupabaseId),
      groupSupabaseId: Value(i.groupSupabaseId),
      title: Value(i.title),
      name: Value(i.name),
      description: Value(i.description),
      assetName: Value(i.assetName),
      photoUrl: Value(i.photoUrl),
      userPhotoUrl: Value(i.userPhotoUrl),
      userPhotoPath: Value(i.userPhotoPath),
      notes: Value(i.notes),
      isCompleted: Value(i.isCompleted),
      completedAt: Value(i.completedAt),
      completionHistory: Value(jsonEncode(i.completionHistory)),
      isBundled: Value(i.isBundled),
      isHidden: Value(i.isHidden),
      isPermanentlyDeleted: Value(i.isPermanentlyDeleted),
      isSynced: Value(i.isSynced),
      createdAt: Value(i.createdAt),
      sortOrder: Value(i.sortOrder),
      lastModified: Value(i.lastModified),
    );
    if (existing == null) {
      await db.into(db.checklistItems).insert(c);
    } else {
      await (db.update(db.checklistItems)
            ..where((t) => t.id.equals(existing.id)))
          .write(c);
    }
  }

  Future<void> _upsertShopCat(ShoppingCategory cat) async {
    final existing = await (db.select(db.shoppingCategories)
          ..where((t) => t.supabaseId.equals(cat.supabaseId)))
        .getSingleOrNull();
    final c = ShoppingCategoriesCompanion(
      supabaseId: Value(cat.supabaseId),
      boatSupabaseId: Value(cat.boatSupabaseId),
      name: Value(cat.name),
      sortOrder: Value(cat.sortOrder),
      isSynced: Value(cat.isSynced),
      lastModified: Value(cat.lastModified),
    );
    if (existing == null) {
      await db.into(db.shoppingCategories).insert(c);
    } else {
      await (db.update(db.shoppingCategories)
            ..where((t) => t.id.equals(existing.id)))
          .write(c);
    }
  }

  Future<void> _upsertShopItem(ShoppingItem i) async {
    final existing = await (db.select(db.shoppingItems)
          ..where((t) => t.supabaseId.equals(i.supabaseId)))
        .getSingleOrNull();
    final c = ShoppingItemsCompanion(
      supabaseId: Value(i.supabaseId),
      boatSupabaseId: Value(i.boatSupabaseId),
      categorySupabaseId: Value(i.categorySupabaseId),
      name: Value(i.name),
      quantity: Value(i.quantity),
      unit: Value(i.unit),
      isBought: Value(i.isBought),
      isBundled: Value(i.isBundled),
      isSynced: Value(i.isSynced),
      isHidden: Value(i.isHidden),
      notes: Value(i.notes),
      origin: Value(i.origin),
      lastPurchasePrice: Value(i.lastPurchasePrice),
      lastPurchasePlace: Value(i.lastPurchasePlace),
      userPhotoUrl: Value(i.userPhotoUrl),
      lastModified: Value(i.lastModified),
    );
    if (existing == null) {
      await db.into(db.shoppingItems).insert(c);
    } else {
      await (db.update(db.shoppingItems)
            ..where((t) => t.id.equals(existing.id)))
          .write(c);
    }
  }

  Future<void> _upsertLog(CaptainLogEntry l) async {
    final existing = await (db.select(db.captainLogEntries)
          ..where((t) => t.supabaseId.equals(l.supabaseId)))
        .getSingleOrNull();
    final c = CaptainLogEntriesCompanion(
      supabaseId: Value(l.supabaseId),
      boatSupabaseId: Value(l.boatSupabaseId),
      logDate: Value(l.logDate),
      title: Value(l.title),
      logTime: Value(l.logTime),
      positionLat: Value(l.positionLat),
      positionLng: Value(l.positionLng),
      weather: Value(l.weather),
      windSpeedKt: Value(l.windSpeedKt),
      windDir: Value(l.windDir),
      crewOnBoard: Value(jsonEncode(l.crewOnBoard)),
      notes: Value(l.notes),
      photos: Value(jsonEncode(l.photos)),
      isSynced: Value(l.isSynced),
      lastModified: Value(l.lastModified),
    );
    if (existing == null) {
      await db.into(db.captainLogEntries).insert(c);
    } else {
      await (db.update(db.captainLogEntries)
            ..where((t) => t.id.equals(existing.id)))
          .write(c);
    }
  }

  Future<void> _upsertMaint(MaintenanceTask task) async {
    final existing = await (db.select(db.maintenanceTasks)
          ..where((t) => t.supabaseId.equals(task.supabaseId)))
        .getSingleOrNull();
    final c = MaintenanceTasksCompanion(
      supabaseId: Value(task.supabaseId),
      boatSupabaseId: Value(task.boatSupabaseId),
      description: Value(task.description),
      intervalHours: Value(task.intervalHours),
      intervalMonths: Value(task.intervalMonths),
      lastDoneHours: Value(task.lastDoneHours),
      lastDoneDate: Value(task.lastDoneDate),
      doneBy: Value(task.doneBy),
      notes: Value(task.notes),
      isHidden: Value(task.isHidden),
      isSynced: Value(task.isSynced),
      lastModified: Value(task.lastModified),
    );
    if (existing == null) {
      await db.into(db.maintenanceTasks).insert(c);
    } else {
      await (db.update(db.maintenanceTasks)
            ..where((t) => t.id.equals(existing.id)))
          .write(c);
    }
  }

  Future<void> _upsertDoc(Document d) async {
    final existing = await (db.select(db.documents)
          ..where((t) => t.supabaseId.equals(d.supabaseId)))
        .getSingleOrNull();
    final c = DocumentsCompanion(
      supabaseId: Value(d.supabaseId),
      boatSupabaseId: Value(d.boatSupabaseId),
      title: Value(d.title),
      type: Value(d.type),
      fileUrl: Value(d.fileUrl),
      localPath: Value(d.localPath),
      notes: Value(d.notes),
      expiry: Value(d.expiry),
      isSynced: Value(d.isSynced),
      lastModified: Value(d.lastModified),
    );
    if (existing == null) {
      await db.into(db.documents).insert(c);
    } else {
      await (db.update(db.documents)..where((t) => t.id.equals(existing.id)))
          .write(c);
    }
  }

  Future<void> _upsertCrew(CrewMember m) async {
    final existing = await (db.select(db.crewMembers)
          ..where((t) => t.supabaseId.equals(m.supabaseId)))
        .getSingleOrNull();
    final c = CrewMembersCompanion(
      supabaseId: Value(m.supabaseId),
      boatSupabaseId: Value(m.boatSupabaseId),
      name: Value(m.name),
      role: Value(m.role),
      phone: Value(m.phone),
      email: Value(m.email),
      iceContact: Value(m.iceContact),
      certifications: Value(m.certifications),
      localPath: Value(m.localPath),
      isSynced: Value(m.isSynced),
      lastModified: Value(m.lastModified),
    );
    if (existing == null) {
      await db.into(db.crewMembers).insert(c);
    } else {
      await (db.update(db.crewMembers)..where((t) => t.id.equals(existing.id)))
          .write(c);
    }
  }

  Future<void> _upsertInv(InventoryItem i) async {
    final existing = await (db.select(db.inventoryItems)
          ..where((t) => t.supabaseId.equals(i.supabaseId)))
        .getSingleOrNull();
    final c = InventoryItemsCompanion(
      supabaseId: Value(i.supabaseId),
      boatSupabaseId: Value(i.boatSupabaseId),
      name: Value(i.name),
      location: Value(i.location),
      quantity: Value(i.quantity),
      unit: Value(i.unit),
      serialNumber: Value(i.serialNumber),
      notes: Value(i.notes),
      localPath: Value(i.localPath),
      isSynced: Value(i.isSynced),
      lastModified: Value(i.lastModified),
    );
    if (existing == null) {
      await db.into(db.inventoryItems).insert(c);
    } else {
      await (db.update(db.inventoryItems)
            ..where((t) => t.id.equals(existing.id)))
          .write(c);
    }
  }

  Future<void> _upsertFuel(FuelLogEntry e) async {
    final existing = await (db.select(db.fuelLogEntries)
          ..where((t) => t.supabaseId.equals(e.supabaseId)))
        .getSingleOrNull();
    final c = FuelLogEntriesCompanion(
      supabaseId: Value(e.supabaseId),
      boatSupabaseId: Value(e.boatSupabaseId),
      date: Value(e.date),
      type: Value(e.type),
      liters: Value(e.liters),
      pricePerLiter: Value(e.pricePerLiter),
      totalCost: Value(e.totalCost),
      notes: Value(e.notes),
      isSynced: Value(e.isSynced),
      lastModified: Value(e.lastModified),
    );
    if (existing == null) {
      await db.into(db.fuelLogEntries).insert(c);
    } else {
      await (db.update(db.fuelLogEntries)
            ..where((t) => t.id.equals(existing.id)))
          .write(c);
    }
  }

  Future<void> _upsertRecipe(Recipe r) async {
    final existing = await (db.select(db.recipes)
          ..where((t) => t.supabaseId.equals(r.supabaseId)))
        .getSingleOrNull();
    final c = RecipesCompanion(
      supabaseId: Value(r.supabaseId),
      boatSupabaseId: Value(r.boatSupabaseId),
      name: Value(r.name),
      description: Value(r.description),
      instructions: Value(r.instructions),
      recipeType: Value(r.recipeType),
      createdAt: Value(r.createdAt),
      isBundled: Value(r.isBundled),
      isSynced: Value(r.isSynced),
      missingIngredientCount: Value(r.missingIngredientCount),
      isFavourite: Value(r.isFavourite),
      glassware: Value(r.glassware),
      prepMinutes: Value(r.prepMinutes),
      cookMinutes: Value(r.cookMinutes),
      story: Value(r.story),
      tastingLog:
          Value(jsonEncode(r.tastingLog.map((t) => t.toJson()).toList())),
      cuisine: Value(jsonEncode(r.cuisine)),
      flavorProfiles: Value(jsonEncode(r.flavorProfiles)),
      cookingMethod: Value(r.cookingMethod),
      imageAsset: Value(r.imageAsset),
      localPath: Value(r.localPath),
      lastModified: Value(r.lastModified),
    );
    if (existing == null) {
      await db.into(db.recipes).insert(c);
    } else {
      await (db.update(db.recipes)..where((t) => t.id.equals(existing.id)))
          .write(c);
    }
  }

  Future<void> _upsertRecipeIng(RecipeIngredient i) async {
    final existing = await (db.select(db.recipeIngredients)
          ..where((t) => t.supabaseId.equals(i.supabaseId)))
        .getSingleOrNull();
    final c = RecipeIngredientsCompanion(
      supabaseId: Value(i.supabaseId),
      recipeSupabaseId: Value(i.recipeSupabaseId),
      name: Value(i.name),
      quantity: Value(i.quantity),
      unit: Value(i.unit),
      substitute: Value(i.substitute),
      isGarnish: Value(i.isGarnish),
      garnishNotes: Value(i.garnishNotes),
      isOptional: Value(i.isOptional),
      photoUrl: Value(i.photoUrl),
      sortOrder: Value(i.sortOrder),
      isSynced: Value(i.isSynced),
      lastModified: Value(i.lastModified),
    );
    if (existing == null) {
      await db.into(db.recipeIngredients).insert(c);
    } else {
      await (db.update(db.recipeIngredients)
            ..where((t) => t.id.equals(existing.id)))
          .write(c);
    }
  }

  Future<void> _upsertBar(BarIngredient i) async {
    final existing = await (db.select(db.barIngredients)
          ..where((t) => t.supabaseId.equals(i.supabaseId)))
        .getSingleOrNull();
    final c = BarIngredientsCompanion(
      supabaseId: Value(i.supabaseId),
      boatSupabaseId: Value(i.boatSupabaseId),
      name: Value(i.name),
      inMyBar: Value(i.inMyBar),
      sortOrder: Value(i.sortOrder),
      isBundled: Value(i.isBundled),
      isSynced: Value(i.isSynced),
      category: Value(i.category),
      flavorProfiles: Value(jsonEncode(i.flavorProfiles)),
      alcoholByVolume: Value(i.alcoholByVolume),
      substitute1: Value(i.substitute1),
      substitute2: Value(i.substitute2),
      localPhotoPath: Value(i.localPhotoPath),
      imageUrl: Value(i.imageUrl),
      lastKnownPrice: Value(i.lastKnownPrice),
      priceCurrency: Value(i.priceCurrency),
      lastKnownPriceUnit: Value(i.lastKnownPriceUnit),
      lastPurchasePlace: Value(i.lastPurchasePlace),
      purchaseHistory: Value(
          jsonEncode(i.purchaseHistory.map((p) => p.toJson()).toList())),
      lastModified: Value(i.lastModified),
    );
    if (existing == null) {
      await db.into(db.barIngredients).insert(c);
    } else {
      await (db.update(db.barIngredients)
            ..where((t) => t.id.equals(existing.id)))
          .write(c);
    }
  }

  Future<void> _upsertPantry(PantryIngredient i) async {
    final existing = await (db.select(db.pantryIngredients)
          ..where((t) => t.supabaseId.equals(i.supabaseId)))
        .getSingleOrNull();
    final c = PantryIngredientsCompanion(
      supabaseId: Value(i.supabaseId),
      boatSupabaseId: Value(i.boatSupabaseId),
      name: Value(i.name),
      inMyPantry: Value(i.inMyPantry),
      quantity: Value(i.quantity),
      unit: Value(i.unit),
      sortOrder: Value(i.sortOrder),
      isBundled: Value(i.isBundled),
      isSynced: Value(i.isSynced),
      category: Value(i.category),
      flavorProfiles: Value(jsonEncode(i.flavorProfiles)),
      cuisineTypes: Value(jsonEncode(i.cuisineTypes)),
      allergenTags: Value(jsonEncode(i.allergenTags)),
      dietaryTags: Value(jsonEncode(i.dietaryTags)),
      substitute1: Value(i.substitute1),
      substitute2: Value(i.substitute2),
      localPhotoPath: Value(i.localPhotoPath),
      imageUrl: Value(i.imageUrl),
      expiryDate: Value(i.expiryDate),
      lastKnownPrice: Value(i.lastKnownPrice),
      priceCurrency: Value(i.priceCurrency),
      lastKnownPriceUnit: Value(i.lastKnownPriceUnit),
      lastPurchasePlace: Value(i.lastPurchasePlace),
      purchaseHistory: Value(
          jsonEncode(i.purchaseHistory.map((p) => p.toJson()).toList())),
      caloriesPer100g: Value(i.caloriesPer100g),
      proteinPer100g: Value(i.proteinPer100g),
      fatPer100g: Value(i.fatPer100g),
      carbsPer100g: Value(i.carbsPer100g),
      lastModified: Value(i.lastModified),
    );
    if (existing == null) {
      await db.into(db.pantryIngredients).insert(c);
    } else {
      await (db.update(db.pantryIngredients)
            ..where((t) => t.id.equals(existing.id)))
          .write(c);
    }
  }
}
