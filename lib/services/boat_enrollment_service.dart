import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/supabase_client.dart';
import '../data/drift/app_database.dart';

/// SHARE-ENROLL: turns the seeded, local-only default boat into a permanent,
/// GUID-identified boat at Pro onboarding (single-boat model — see
/// `plans/pro-sync-sharing.md`).
///
/// The GUID is minted once and persisted in [SharedPreferences] so it survives a
/// Drift wipe (factory reset keeps the same boat identity, so crew stay linked).
class BoatEnrollmentService {
  BoatEnrollmentService(this.db);

  final AppDatabase db;

  static const defaultBoatId = '00000000-0000-0000-0000-000000000000';
  static const _prefsKey = 'boat_guid';

  /// The persisted boat GUID (used by sync as the wire-prefix), or null if the
  /// account has never enrolled.
  Future<String?> currentGuid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKey);
  }

  /// Adopt-and-rename the default boat into a GUID-identified boat named [name].
  /// Idempotent: reuses the persisted GUID (factory reset), falling back to the
  /// account's `profiles.boatGuid` (SHARE-ENROLL-2) so a second device or a
  /// reinstall recovers the SAME boat instead of minting a fork. Returns the
  /// boat GUID, which the caller sets as the active boat.
  Future<String> enroll({required String name, String? ownerId}) async {
    final prefs = await SharedPreferences.getInstance();
    final guid = prefs.getString(_prefsKey) ??
        await _remoteGuid() ??
        const Uuid().v4();
    await prefs.setString(_prefsKey, guid);
    await _saveRemoteGuid(guid);

    final now = DateTime.now();
    final guidBoat = await (db.select(db.boats)
          ..where((t) => t.supabaseId.equals(guid)))
        .getSingleOrNull();

    if (guidBoat != null) {
      // Already enrolled — refresh name/owner and drop any stray default row.
      await (db.update(db.boats)..where((t) => t.supabaseId.equals(guid))).write(
          BoatsCompanion(
              name: Value(name),
              ownerId: Value(ownerId),
              lastModified: Value(now)));
      await (db.delete(db.boats)
            ..where((t) => t.supabaseId.equals(defaultBoatId)))
          .go();
    } else {
      final def = await (db.select(db.boats)
            ..where((t) => t.supabaseId.equals(defaultBoatId)))
          .getSingleOrNull();
      if (def != null) {
        await (db.update(db.boats)..where((t) => t.id.equals(def.id))).write(
            BoatsCompanion(
                supabaseId: Value(guid),
                name: Value(name),
                ownerId: Value(ownerId),
                lastModified: Value(now)));
      } else {
        await db.into(db.boats).insert(BoatsCompanion.insert(
            supabaseId: Value(guid),
            name: Value(name),
            ownerId: Value(ownerId)));
      }
    }

    await _restampContentToBoat(guid);
    return guid;
  }

  /// The account's remembered boat GUID from Supabase `profiles`, or null.
  /// Best-effort: no session / offline / test process (no Supabase) → null.
  Future<String?> _remoteGuid() async {
    try {
      final uid = SupabaseClientWrapper.instance.auth.currentUser?.id;
      if (uid == null) return null;
      final row = await SupabaseClientWrapper.instance
          .from('profiles')
          .select('boatGuid')
          .eq('id', uid)
          .maybeSingle();
      final guid = row?['boatGuid'] as String?;
      return (guid != null && guid.isNotEmpty) ? guid : null;
    } catch (_) {
      return null;
    }
  }

  /// Remember [guid] on the account (`profiles.boatGuid`). Best-effort.
  Future<void> _saveRemoteGuid(String guid) async {
    try {
      final uid = SupabaseClientWrapper.instance.auth.currentUser?.id;
      if (uid == null) return;
      await SupabaseClientWrapper.instance.from('profiles').upsert({
        'id': uid,
        'boatGuid': guid,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Offline / anonymous / test process — harmless, retried on next enroll.
    }
  }

  /// Single-boat model: every piece of content belongs to the one boat, so
  /// stamp `boatSupabaseId` = [guid] across all sync-participating tables.
  Future<void> _restampContentToBoat(String guid) async {
    final v = Value(guid);
    await db.update(db.checklistGroups).write(ChecklistGroupsCompanion(boatSupabaseId: v));
    await db.update(db.checklistItems).write(ChecklistItemsCompanion(boatSupabaseId: v));
    await db.update(db.shoppingCategories).write(ShoppingCategoriesCompanion(boatSupabaseId: v));
    await db.update(db.shoppingItems).write(ShoppingItemsCompanion(boatSupabaseId: v));
    await db.update(db.captainLogEntries).write(CaptainLogEntriesCompanion(boatSupabaseId: v));
    await db.update(db.maintenanceTasks).write(MaintenanceTasksCompanion(boatSupabaseId: v));
    await db.update(db.documents).write(DocumentsCompanion(boatSupabaseId: v));
    await db.update(db.crewMembers).write(CrewMembersCompanion(boatSupabaseId: v));
    await db.update(db.inventoryItems).write(InventoryItemsCompanion(boatSupabaseId: v));
    await db.update(db.fuelLogEntries).write(FuelLogEntriesCompanion(boatSupabaseId: v));
    await db.update(db.recipes).write(RecipesCompanion(boatSupabaseId: v));
    await db.update(db.barIngredients).write(BarIngredientsCompanion(boatSupabaseId: v));
    await db.update(db.pantryIngredients).write(PantryIngredientsCompanion(boatSupabaseId: v));
  }
}
