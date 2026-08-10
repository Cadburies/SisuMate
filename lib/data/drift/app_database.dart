import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Guest profiles. List fields are stored as JSON text (Drift has no native
/// list type). The row class is named `GuestProfileRow` to avoid clashing with
/// the `GuestProfile` domain model the repository interface uses.
@DataClassName('GuestProfileRow')
class GuestProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get allergenRestrictions =>
      text().withDefault(const Constant('[]'))();
  TextColumn get dietaryRequirements =>
      text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Themed recipe collections (CF16).
@DataClassName('RecipeCollectionRow')
class RecipeCollections extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get recipeSupabaseIds =>
      text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastModified =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Crew & Contacts (F16) — sync-participating:
/// the repository keeps queueing `toJson()` into the sync outbox.
@DataClassName('CrewMemberRow')
class CrewMembers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get supabaseId => text().withDefault(const Constant(''))();
  TextColumn get boatSupabaseId => text().withDefault(const Constant(''))();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get role => text().withDefault(const Constant('Crew'))();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get iceContact => text().nullable()();
  TextColumn get certifications => text().nullable()();
  TextColumn get localPath => text().nullable()();
  /// #326 — optional port-entry/customs fields.
  DateTimeColumn get dateOfBirth => dateTime().nullable()();
  TextColumn get nationality => text().nullable()();
  TextColumn get passportNumber => text().nullable()();
  /// #324 — JSON `List<String>`, same tag vocabularies as GuestProfile's.
  TextColumn get allergenRestrictions =>
      text().withDefault(const Constant('[]'))();
  TextColumn get dietaryRequirements =>
      text().withDefault(const Constant('[]'))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Inventory (F17) — sync-participating.
@DataClassName('InventoryItemRow')
class InventoryItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get supabaseId => text().withDefault(const Constant(''))();
  TextColumn get boatSupabaseId => text().withDefault(const Constant(''))();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get location => text().nullable()();
  RealColumn get quantity => real().withDefault(const Constant(1))();
  TextColumn get unit => text().nullable()();
  TextColumn get serialNumber => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get localPath => text().nullable()();
  /// #318 — scanned/typed barcode (UPC/EAN), for quickly re-finding an item
  /// on restock ("scan it, jump straight to its record") rather than a
  /// product-name lookup (unlike Cocktails' bottle-barcode database, boat
  /// spares have no equivalent curated catalog to look up against).
  TextColumn get barcode => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Fuel & Water Log (F22) — sync-participating.
@DataClassName('FuelLogEntryRow')
class FuelLogEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get supabaseId => text().withDefault(const Constant(''))();
  TextColumn get boatSupabaseId => text().withDefault(const Constant(''))();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  TextColumn get type => text().withDefault(const Constant('Fuel'))();
  RealColumn get liters => real().withDefault(const Constant(0))();
  RealColumn get pricePerLiter => real().withDefault(const Constant(0))();
  RealColumn get totalCost => real().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Documents Vault (F15) — sync-participating.
@DataClassName('DocumentRow')
class Documents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get supabaseId => text().withDefault(const Constant(''))();
  TextColumn get boatSupabaseId => text().withDefault(const Constant(''))();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get type => text().withDefault(const Constant('Other'))();
  TextColumn get fileUrl => text().nullable()();
  TextColumn get localPath => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get expiry => dateTime().nullable()();
  /// #325 — CrewMembers.supabaseId this document belongs to, or null for
  /// boat-level documents.
  TextColumn get crewMemberSupabaseId => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Meal plans (CF1). `guestProfileIds` and the
/// embedded `slots` list are JSON text columns. Local-only (not synced).
@DataClassName('MealPlanRow')
class MealPlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withDefault(const Constant(''))();
  DateTimeColumn get startDate => dateTime().withDefault(currentDateAndTime)();
  IntColumn get numberOfDays => integer().withDefault(const Constant(7))();
  IntColumn get guestCount => integer().withDefault(const Constant(4))();
  TextColumn get guestProfileIds =>
      text().withDefault(const Constant('[]'))();
  TextColumn get slots => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastModified =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Boats — sync-participating.
@DataClassName('BoatRow')
class Boats extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get supabaseId => text().withDefault(const Constant(''))();
  TextColumn get name => text().withDefault(const Constant(''))();
  BoolColumn get isBought => boolean().withDefault(const Constant(false))();
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  RealColumn get lastPurchasePrice => real().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get origin => text().nullable()();
  TextColumn get photoUrl => text().nullable()();
  // SHARE4: owner (auth uid) + crew join code. Both are read-only inbound from
  // Supabase (owner stamped server-side, shareCode DB-generated) — never pushed.
  TextColumn get ownerId => text().nullable()();
  TextColumn get shareCode => text().nullable()();
  // #203/#215/#211: bring-your-own-key LLM support — local-only by default,
  // one entry per provider (JSON list of {provider, apiKey, shared} —
  // see `LlmApiKeyEntry`). Never validated/billed by this app.
  TextColumn get llmApiKeys => text().withDefault(const Constant('[]'))();
  // Which stored provider is active right now — per-device only, never
  // synced (see `Boat.activeLlmProvider`'s doc comment).
  TextColumn get activeLlmProvider => text().nullable()();
  // #236: boat polar performance data — JSON list of {twaDeg, twsKt,
  // boatSpeedKt} triples (see `PolarPoint`), manually entered. Foundation
  // for real weather routing (#238) — no privacy/sync-gating concerns
  // unlike llmApiKeys, so it's pushed/pulled plainly like any other field.
  TextColumn get polarJson => text().withDefault(const Constant('[]'))();
  // #276: per-sea-state polars — JSON map calm|moderate|rough → PolarPoint[].
  TextColumn get polarBySeaStateJson =>
      text().withDefault(const Constant('{}'))();
  DateTimeColumn get lastModified =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Captain's Log — sync-participating. `crewOnBoard`
/// and `photos` are JSON text columns.
@DataClassName('CaptainLogEntryRow')
class CaptainLogEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get supabaseId => text().withDefault(const Constant(''))();
  TextColumn get boatSupabaseId => text().withDefault(const Constant(''))();
  DateTimeColumn get logDate => dateTime().withDefault(currentDateAndTime)();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get logTime => text().nullable()();
  RealColumn get positionLat => real().nullable()();
  RealColumn get positionLng => real().nullable()();
  TextColumn get weather => text().nullable()();
  IntColumn get windSpeedKt => integer().nullable()();
  TextColumn get windDir => text().nullable()();
  RealColumn get sogKt => real().nullable()();
  RealColumn get cogDeg => real().nullable()();
  RealColumn get barometricPressureHpa => real().nullable()();
  TextColumn get seaState => text().nullable()();
  TextColumn get watchCrew => text().withDefault(const Constant('[]'))();
  RealColumn get engineHours => real().nullable()();
  RealColumn get fuelLevelPercent => real().nullable()();
  TextColumn get crewOnBoard => text().withDefault(const Constant('[]'))();
  TextColumn get notes => text().nullable()();
  TextColumn get photos => text().withDefault(const Constant('[]'))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Maintenance tasks (the `MaintenanceTask` model — note the Maintenance *UI*
/// uses checklist items) — sync-participating.
@DataClassName('MaintenanceTaskRow')
class MaintenanceTasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get supabaseId => text().withDefault(const Constant(''))();
  TextColumn get boatSupabaseId => text().withDefault(const Constant(''))();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get intervalHours => integer().nullable()();
  IntColumn get intervalMonths => integer().nullable()();
  IntColumn get lastDoneHours => integer().nullable()();
  DateTimeColumn get lastDoneDate => dateTime().nullable()();
  TextColumn get doneBy => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Shopping categories (F…) — sync-participating.
@DataClassName('ShoppingCategoryRow')
class ShoppingCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get supabaseId => text().withDefault(const Constant(''))();
  TextColumn get boatSupabaseId => text().withDefault(const Constant(''))();
  TextColumn get name => text().withDefault(const Constant(''))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Shopping items — sync-participating.
@DataClassName('ShoppingItemRow')
class ShoppingItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get supabaseId => text().withDefault(const Constant(''))();
  TextColumn get boatSupabaseId => text().nullable()();
  TextColumn get categorySupabaseId =>
      text().withDefault(const Constant(''))();
  TextColumn get name => text().withDefault(const Constant(''))();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  TextColumn get unit => text().nullable()();
  BoolColumn get isBought => boolean().withDefault(const Constant(false))();
  BoolColumn get isBundled => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  TextColumn get origin => text().withDefault(const Constant('spares'))();
  RealColumn get lastPurchasePrice => real().nullable()();
  TextColumn get lastPurchasePlace => text().nullable()();
  TextColumn get userPhotoUrl => text().nullable()();
  DateTimeColumn get lastModified =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Checklist groups — sync-participating.
@DataClassName('ChecklistGroupRow')
class ChecklistGroups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get supabaseId => text().withDefault(const Constant(''))();
  TextColumn get boatSupabaseId => text().withDefault(const Constant(''))();
  TextColumn get appType => text().withDefault(const Constant(''))();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get description => text().nullable()();
  TextColumn get iconName => text().withDefault(const Constant(''))();
  BoolColumn get isBought => boolean().withDefault(const Constant(false))();
  BoolColumn get isBundled => boolean().withDefault(const Constant(false))();
  BoolColumn get isExpanded => boolean().withDefault(const Constant(false))();
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  RealColumn get lastPurchasePrice => real().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get origin => text().withDefault(const Constant(''))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastModified =>
      dateTime().withDefault(currentDateAndTime)();
  // S5: which community_templates row (and version) this group was imported
  // from, if any — null for user-created groups. Drives "update available".
  TextColumn get communityTemplateId => text().nullable()();
  IntColumn get communityTemplateVersion => integer().nullable()();
}

/// Checklist items — sync-participating.
/// `completionHistory` is a JSON text column.
@DataClassName('ChecklistItemRow')
class ChecklistItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get supabaseId => text().withDefault(const Constant(''))();
  TextColumn get boatSupabaseId => text().withDefault(const Constant(''))();
  TextColumn get groupSupabaseId => text().withDefault(const Constant(''))();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get description => text().nullable()();
  TextColumn get assetName => text().nullable()();
  TextColumn get photoUrl => text().nullable()();
  TextColumn get userPhotoUrl => text().nullable()();
  TextColumn get userPhotoPath => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get completionHistory =>
      text().withDefault(const Constant('[]'))();
  BoolColumn get isBundled => boolean().withDefault(const Constant(false))();
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();
  BoolColumn get isPermanentlyDeleted =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastModified =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Recipes (menus, cocktails, syrups). `tastingLog`, `cuisine`, and
/// `flavorProfiles` are JSON text columns. Local-only (not synced).
@DataClassName('RecipeRow')
class Recipes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get supabaseId => text().withDefault(const Constant(''))();
  TextColumn get boatSupabaseId => text().withDefault(const Constant(''))();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get description => text().nullable()();
  TextColumn get instructions => text().nullable()();
  TextColumn get recipeType => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isBundled => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  IntColumn get missingIngredientCount =>
      integer().withDefault(const Constant(0))();
  BoolColumn get isFavourite => boolean().withDefault(const Constant(false))();
  TextColumn get glassware => text().nullable()();
  IntColumn get prepMinutes => integer().nullable()();
  IntColumn get cookMinutes => integer().nullable()();
  TextColumn get story => text().nullable()();
  TextColumn get winePairing => text().nullable()();
  TextColumn get cocktailPairing => text().nullable()();
  TextColumn get tastingLog => text().withDefault(const Constant('[]'))();
  /// JSON string list, e.g. `["Tiki","Classic"]`. Pre-v2 rows may hold a
  /// plain string; repositories coerce both shapes.
  TextColumn get cuisine => text().withDefault(const Constant('[]'))();
  TextColumn get flavorProfiles => text().withDefault(const Constant('[]'))();
  TextColumn get cookingMethod => text().nullable()();
  /// Bundled asset path under `assets/` (offline). e.g. `cocktails/mai_tai.jpg`.
  TextColumn get imageAsset => text().nullable()();
  /// User photo on device (app documents path).
  TextColumn get localPath => text().nullable()();
  DateTimeColumn get lastModified =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Recipe ingredients — local-only (not synced).
@DataClassName('RecipeIngredientRow')
class RecipeIngredients extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get supabaseId => text().withDefault(const Constant(''))();
  TextColumn get recipeSupabaseId => text().withDefault(const Constant(''))();
  TextColumn get name => text().withDefault(const Constant(''))();
  RealColumn get quantity => real().nullable()();
  TextColumn get unit => text().nullable()();
  TextColumn get substitute => text().nullable()();
  BoolColumn get isGarnish => boolean().withDefault(const Constant(false))();
  TextColumn get garnishNotes => text().nullable()();
  BoolColumn get isOptional => boolean().withDefault(const Constant(false))();
  TextColumn get photoUrl => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Bar ingredients (My Bar). `flavorProfiles` and
/// `purchaseHistory` are JSON text columns. Local-only (not synced).
@DataClassName('BarIngredientRow')
class BarIngredients extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get supabaseId => text().withDefault(const Constant(''))();
  TextColumn get boatSupabaseId => text().withDefault(const Constant(''))();
  TextColumn get name => text().withDefault(const Constant(''))();
  BoolColumn get inMyBar => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isBundled => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  TextColumn get category => text().withDefault(const Constant(''))();
  TextColumn get flavorProfiles => text().withDefault(const Constant('[]'))();
  RealColumn get alcoholByVolume => real().nullable()();
  TextColumn get substitute1 => text().nullable()();
  TextColumn get substitute2 => text().nullable()();
  TextColumn get localPhotoPath => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  RealColumn get lastKnownPrice => real().nullable()();
  TextColumn get priceCurrency => text().withDefault(const Constant('USD'))();
  TextColumn get lastKnownPriceUnit => text().nullable()();
  TextColumn get lastPurchasePlace => text().nullable()();
  TextColumn get purchaseHistory => text().withDefault(const Constant('[]'))();
  DateTimeColumn get lastModified =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Pantry ingredients (My Pantry). List fields and
/// `purchaseHistory` are JSON text columns. Sync-participating (SYN2).
@DataClassName('PantryIngredientRow')
class PantryIngredients extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get supabaseId => text().withDefault(const Constant(''))();
  TextColumn get boatSupabaseId => text().withDefault(const Constant(''))();
  TextColumn get name => text().withDefault(const Constant(''))();
  BoolColumn get inMyPantry => boolean().withDefault(const Constant(false))();
  RealColumn get quantity => real().nullable()();
  TextColumn get unit => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isBundled => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  TextColumn get category => text().withDefault(const Constant(''))();
  TextColumn get flavorProfiles => text().withDefault(const Constant('[]'))();
  TextColumn get cuisineTypes => text().withDefault(const Constant('[]'))();
  TextColumn get allergenTags => text().withDefault(const Constant('[]'))();
  TextColumn get dietaryTags => text().withDefault(const Constant('[]'))();
  TextColumn get substitute1 => text().nullable()();
  TextColumn get substitute2 => text().nullable()();
  TextColumn get localPhotoPath => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  RealColumn get lastKnownPrice => real().nullable()();
  TextColumn get priceCurrency => text().withDefault(const Constant('USD'))();
  TextColumn get lastKnownPriceUnit => text().nullable()();
  TextColumn get lastPurchasePlace => text().nullable()();
  TextColumn get purchaseHistory => text().withDefault(const Constant('[]'))();
  RealColumn get caloriesPer100g => real().nullable()();
  RealColumn get proteinPer100g => real().nullable()();
  RealColumn get fatPer100g => real().nullable()();
  RealColumn get carbsPer100g => real().nullable()();
  DateTimeColumn get lastModified =>
      dateTime().withDefault(currentDateAndTime)();
}

/// User settings — a single-row (`id` = 1) table.
/// `recentEmails` is a JSON text column. Row class `UserSettingsRow` avoids
/// clashing with the `UserSettings` domain model.
@DataClassName('UserSettingsRow')
class UserSettingsTable extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get activeBoatSupabaseId => text().nullable()();
  BoolColumn get showHiddenItems =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isPro => boolean().withDefault(const Constant(false))();
  DateTimeColumn get proExpiresAt => dateTime().nullable()();
  TextColumn get selectedBoatId => text().nullable()();
  TextColumn get userId => text().nullable()();
  BoolColumn get isDarkMode => boolean().withDefault(const Constant(true))();
  /// JSON [AppUnitPrefs]: volume, temperature, speed, depth, distance.
  TextColumn get unitPrefsJson => text().withDefault(const Constant(''))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified =>
      dateTime().withDefault(currentDateAndTime)();
  TextColumn get recentEmails => text().withDefault(const Constant('[]'))();
  TextColumn get fromName => text().nullable()();
  TextColumn get replyToEmail => text().nullable()();
  TextColumn get boatName => text().nullable()();
  /// FREE-EDITS: how many of the free-tier's teaser edits/completions have
  /// been used. Local-only — Free never syncs. See `FreeEditGate`.
  IntColumn get freeEditsUsed => integer().withDefault(const Constant(0))();

  /// #256 — default chain-scope ratio (chain paid out : depth) new anchor
  /// drops are pre-filled with, e.g. `5.0` for 5:1. Editable per-drop.
  RealColumn get defaultAnchorScopeRatio =>
      real().withDefault(const Constant(5.0))();

  /// #307 — bow roller / rode lead height above water (m). Added to depth
  /// for scope = (depth + roller) × ratio. 0 = depth-only.
  RealColumn get anchorRollerHeightMeters =>
      real().withDefault(const Constant(0.0))();

  /// #307 — min depth alarm (m). 0 = disabled.
  RealColumn get anchorMinDepthMeters =>
      real().withDefault(const Constant(0.0))();

  /// #307 — strong wind alarm (kn, AWS preferred). 0 = disabled.
  RealColumn get anchorMaxWindKt =>
      real().withDefault(const Constant(0.0))();

  /// #307 — AIS collision alarm armed in UI. No AIS feed yet — evaluation
  /// is a no-op until a source exists; setting is retained for config UX.
  BoolColumn get anchorAisAlarmEnabled =>
      boolean().withDefault(const Constant(false))();

  /// #263 — set via the Anchor Alarm's gateway setup screen (auto-discover
  /// or manual IP:port); overrides the dart-defines default when non-empty.
  TextColumn get predictwindHubLocalUrl =>
      text().withDefault(const Constant(''))();
  TextColumn get predictwindHubUsername =>
      text().withDefault(const Constant(''))();
  TextColumn get predictwindHubPassword =>
      text().withDefault(const Constant(''))();

  /// #263 — YDWG-02 (or equivalent) web/NMEA gateway settings.
  TextColumn get ydwgUrl => text().withDefault(const Constant(''))();
  TextColumn get ydwgUsername => text().withDefault(const Constant(''))();
  TextColumn get ydwgPassword => text().withDefault(const Constant(''))();

  /// #263 — Home Assistant (local + optional remote URL, token, entities).
  TextColumn get homeAssistantUrl => text().withDefault(const Constant(''))();
  TextColumn get homeAssistantRemoteUrl =>
      text().withDefault(const Constant(''))();
  TextColumn get homeAssistantToken => text().withDefault(const Constant(''))();
  TextColumn get homeAssistantGpsEntity =>
      text().withDefault(const Constant(''))();
  TextColumn get homeAssistantLatEntity =>
      text().withDefault(const Constant(''))();
  TextColumn get homeAssistantLonEntity =>
      text().withDefault(const Constant(''))();
  TextColumn get homeAssistantWindSpeedEntity =>
      text().withDefault(const Constant(''))();
  TextColumn get homeAssistantWindDirEntity =>
      text().withDefault(const Constant(''))();
  TextColumn get homeAssistantDepthEntity =>
      text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Community templates — a local cache of published templates. Write-only
/// today (`browseCommunity` reads from Supabase).
@DataClassName('CommunityTemplateRow')
class CommunityTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get supabaseId => text().withDefault(const Constant(''))();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get description => text().withDefault(const Constant(''))();
  BoolColumn get isApproved => boolean().withDefault(const Constant(false))();
  TextColumn get authorId => text().withDefault(const Constant(''))();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get category => text().withDefault(const Constant(''))();
  TextColumn get subcategory => text().withDefault(const Constant(''))();
  TextColumn get content => text().withDefault(const Constant(''))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified =>
      dateTime().withDefault(currentDateAndTime)();
  IntColumn get downloadCount => integer().withDefault(const Constant(0))();
  RealColumn get avgRating => real().withDefault(const Constant(0))();
  IntColumn get ratingCount => integer().withDefault(const Constant(0))();
  IntColumn get version => integer().withDefault(const Constant(1))();
}

/// Offline sync outbox — pending outbound changes.
/// `SyncService` upserts/deletes rows here; the row class is `SyncOutboxRow`
/// to avoid clashing with the `SyncOutbox` domain model.
@DataClassName('SyncOutboxRow')
class SyncOutboxItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get targetTable => text().withDefault(const Constant(''))();
  TextColumn get recordId => text().withDefault(const Constant(''))();
  TextColumn get operation => text().withDefault(const Constant('create'))();
  TextColumn get data => text().withDefault(const Constant(''))();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  BoolColumn get isDelete => boolean().withDefault(const Constant(false))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
}

/// Conflict log — concurrent offline edits (T5). [resolution] is
/// `pending` | `keep_local` | `keep_remote`. Snapshots are JSON text.
@DataClassName('ConflictLogRow')
class ConflictLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get targetTable => text().withDefault(const Constant(''))();
  TextColumn get localSupabaseId => text().withDefault(const Constant(''))();
  TextColumn get remoteSupabaseId => text().withDefault(const Constant(''))();
  TextColumn get conflictType =>
      text().withDefault(const Constant('concurrent_edit'))();
  TextColumn get resolution =>
      text().withDefault(const Constant('pending'))();
  TextColumn get localData => text().withDefault(const Constant('{}'))();
  TextColumn get remoteData => text().withDefault(const Constant('{}'))();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get resolvedAt => dateTime().nullable()();
}

/// App error/exception/warning telemetry (#121) — captured globally via
/// `FlutterError.onError` / `PlatformDispatcher.onError` and explicit
/// `ErrorLogService` calls, then read by `scripts/triage_error_logs.sh` to
/// file one deduped GitHub issue per [fingerprint]. Local-only; never synced
/// to Supabase (no `boatSupabaseId`/`isSynced` columns).
@DataClassName('ErrorLogRow')
class ErrorLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  /// `warning` | `error` | `exception`
  TextColumn get level => text().withDefault(const Constant('error'))();
  TextColumn get message => text().withDefault(const Constant(''))();
  TextColumn get stackTrace => text().nullable()();
  /// Top app-frame parsed from the stack, e.g. `lib/services/sync_service.dart`.
  TextColumn get sourceFile => text().nullable()();
  TextColumn get routeHint => text().nullable()();
  TextColumn get appVersion => text().withDefault(const Constant(''))();
  TextColumn get platform => text().withDefault(const Constant(''))();
  BoolColumn get isPro => boolean().withDefault(const Constant(false))();
  /// Dedupe key: hash of level + sourceFile + a digit-normalized message.
  TextColumn get fingerprint => text().withDefault(const Constant(''))();
  IntColumn get occurrences => integer().withDefault(const Constant(1))();
  /// Set once `scripts/triage_error_logs.sh` has filed/updated a GitHub issue
  /// for this fingerprint.
  DateTimeColumn get processedAt => dateTime().nullable()();
  TextColumn get issueUrl => text().nullable()();
  /// `exception`-level only: newline-joined recent Riverpod provider
  /// lifecycle events (see `lib/services/provider_breadcrumbs.dart`) at the
  /// moment this was captured — which provider was updating/failing right
  /// before a rare, timing-dependent crash (e.g. "setState() called during
  /// build" races). Deliberately excluded from [fingerprint]/[message] since
  /// it differs on every occurrence of the same underlying bug and would
  /// otherwise break dedupe (#147/#176 follow-up).
  TextColumn get debugBreadcrumbs => text().nullable()();
}

/// #256 — anchor watch/drag alarm. Local-only; never synced (meaningful
/// only to the device actively watching the anchor — see [AnchorWatch]).
@DataClassName('AnchorWatchRow')
class AnchorWatches extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get anchorLat => real().withDefault(const Constant(0))();
  RealColumn get anchorLon => real().withDefault(const Constant(0))();
  RealColumn get scopeRatio => real().withDefault(const Constant(5.0))();
  RealColumn get radiusMeters => real().withDefault(const Constant(30.0))();
  BoolColumn get dangerZoneEnabled =>
      boolean().withDefault(const Constant(false))();
  RealColumn get dangerZoneCenterDeg =>
      real().withDefault(const Constant(0))();
  RealColumn get dangerZoneWidthDeg =>
      real().withDefault(const Constant(60.0))();
  // #262 — a ring segment, not a pie slice from the anchor: inner defaults
  // to the geofence radiusMeters (the alarm perimeter) the moment the
  // danger zone is first enabled.
  RealColumn get dangerZoneInnerRadiusMeters =>
      real().withDefault(const Constant(30.0))();
  RealColumn get dangerZoneOuterRadiusMeters =>
      real().withDefault(const Constant(50.0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get droppedAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastModified =>
      dateTime().withDefault(currentDateAndTime)();
}

/// #274/#275 — under-sail polar learning samples. Anonymized sync when Pro.
@DataClassName('SailingPolarSampleRow')
class SailingPolarSamples extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get supabaseId => text().withDefault(const Constant(''))();
  TextColumn get boatSupabaseId => text().withDefault(const Constant(''))();
  DateTimeColumn get observedAt =>
      dateTime().withDefault(currentDateAndTime)();
  RealColumn get sogKt => real().nullable()();
  RealColumn get stwKt => real().nullable()();
  /// Preferred polar speed (STW if available else SOG).
  RealColumn get boatSpeedKt => real().withDefault(const Constant(0))();
  TextColumn get speedSource => text().withDefault(const Constant('sog'))();
  RealColumn get cogDeg => real().nullable()();
  RealColumn get twsKt => real().withDefault(const Constant(0))();
  RealColumn get twdDeg => real().nullable()();
  RealColumn get twaDeg => real().withDefault(const Constant(0))();
  RealColumn get awsKt => real().nullable()();
  RealColumn get awaDeg => real().nullable()();
  RealColumn get depthMeters => real().nullable()();
  RealColumn get enginePortRpm => real().nullable()();
  RealColumn get engineStbdRpm => real().nullable()();
  TextColumn get sourceLabel => text().withDefault(const Constant(''))();
  /// #276 — calm | moderate | rough | unknown
  TextColumn get seaState => text().withDefault(const Constant('unknown'))();
  RealColumn get speedCv => real().nullable()();
  RealColumn get twaStdDeg => real().nullable()();
  /// #280 — phone IMU local diagnostics (not synced).
  RealColumn get imuHsM => real().nullable()();
  RealColumn get imuAccelRms => real().nullable()();
  RealColumn get imuAccelP90 => real().nullable()();
  RealColumn get imuDominantPeriodS => real().nullable()();
  TextColumn get imuSuggestedSeaState => text().nullable()();
  BoolColumn get usedInPolarBuild =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified =>
      dateTime().withDefault(currentDateAndTime)();
}

/// The app's Drift database — the sole local store. Every table the app
/// persists is registered in the `@DriftDatabase(tables: [...])` list below.
@DriftDatabase(tables: [
  GuestProfiles,
  RecipeCollections,
  CrewMembers,
  InventoryItems,
  FuelLogEntries,
  Documents,
  MealPlans,
  Boats,
  CaptainLogEntries,
  MaintenanceTasks,
  ShoppingCategories,
  ShoppingItems,
  ChecklistGroups,
  ChecklistItems,
  Recipes,
  RecipeIngredients,
  BarIngredients,
  PantryIngredients,
  UserSettingsTable,
  CommunityTemplates,
  SyncOutboxItems,
  ConflictLogs,
  ErrorLogs,
  AnchorWatches,
  SailingPolarSamples,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  /// Singleton for app use. Mutable so a hard reset can close a corrupt file
  /// and reopen a fresh connection (see [deleteAndRecreate]).
  static AppDatabase _instance = AppDatabase._();
  static AppDatabase get instance => _instance;

  /// For tests — pass `NativeDatabase.memory()`.
  AppDatabase.forTesting(super.executor);

  /// Test-only: point the singleton at an in-memory database so code paths that
  /// use [AppDatabase.instance] directly (e.g. the bundled data seeder) can run
  /// against an isolated DB. Not for production use.
  static void setInstanceForTesting(AppDatabase db) => _instance = db;

  // No install base (dev/sim only). schemaVersion tracks changes; wipe local
  // DBs rather than writing upgrade branches for dropped/renamed columns.
  @override
  int get schemaVersion => 23;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        // #250/#253: no install base yet, so per CLAUDE.md a schema bump
        // never needs a column-preserving upgrade path — wipe and recreate
        // every table. Without this, `onUpgrade` used to be a no-op: bumping
        // `schemaVersion` only changes `PRAGMA user_version`, so an
        // already-installed device kept its physically stale table
        // structure (e.g. `boats` missing `polar_json`, added at
        // schemaVersion 11), and Drift's generated non-nullable column read
        // crashed. Safe to wipe: `DatabaseService.init()` already detects an
        // empty `checklistGroups` table and re-seeds on every app startup.
        onUpgrade: (m, from, to) async {
          for (final table in allTables) {
            await m.drop(table);
          }
          await m.createAll();
        },
      );

  /// Hard reset: close the current connection, delete the on-disk sqlite file,
  /// and reopen a fresh (empty) database. Used when the DB is unopenable.
  static Future<void> deleteAndRecreate() async {
    try {
      await _instance.close();
    } catch (_) {}
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/sisu_mate.sqlite');
    if (await file.exists()) await file.delete();
    _instance = AppDatabase._();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/sisu_mate.sqlite');
    return NativeDatabase.createInBackground(file);
  });
}
