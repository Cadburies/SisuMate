import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'dart:async';

import '../core/supabase_client.dart';
import '../data/drift/app_database.dart';
import 'error_log_service.dart';

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
  /// Auth uid the persisted [_prefsKey] guid was minted under (#156). A
  /// device that signs out of one account and enrolls a different one (e.g.
  /// the debug bootstrap owner, then the real sign-up flow) must not reuse
  /// the previous identity's boat guid — that identity has no ownership/
  /// membership claim to it, so every subsequent push (the boat row itself,
  /// via `boats_insert`/`update`'s `ownerId = auth.uid()` check, and all
  /// content, via `accessible_boat_ids()`) gets rejected with 42501.
  static const _prefsOwnerUidKey = 'boat_guid_owner_uid';

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
    final currentUid = _currentUid();

    // Only trust a persisted local guid if it was minted under this same
    // signed-in identity (#156) — otherwise a stale guid from a previously
    // signed-in account on this device gets silently "adopted" by whoever
    // is signed in now, and every push for it is rejected by RLS.
    final storedGuid = prefs.getString(_prefsKey);
    final storedOwnerUid = prefs.getString(_prefsOwnerUidKey);
    // Trust the stored guid unless we have a *recorded* owner uid that
    // conflicts with who's signed in now — no recorded owner (legacy state,
    // or an earlier anonymous/offline enroll that had no uid to record)
    // still reuses it, preserving idempotency for that case.
    final trustedStoredGuid = storedGuid != null &&
            (storedOwnerUid == null || storedOwnerUid == currentUid)
        ? storedGuid
        : null;

    final guid = trustedStoredGuid ?? await _remoteGuid() ?? const Uuid().v4();
    await prefs.setString(_prefsKey, guid);
    if (currentUid != null) {
      await prefs.setString(_prefsOwnerUidKey, currentUid);
    }
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

    await restampContentToBoat(guid);
    return guid;
  }

  /// Stamp every sync-participating content row onto [guid] (crew join or
  /// owner enroll). Public so [JoinBoatService] can re-scope local data when a
  /// device links to an existing shared boat without minting a new GUID.
  Future<void> restampContentToBoat(String guid) => _restampContentToBoat(guid);

  /// Best-effort: no session / offline / test process (no Supabase) → null.
  String? _currentUid() {
    try {
      return SupabaseClientWrapper.instance.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  /// The account's remembered boat GUID from Supabase `profiles`, or null.
  /// Best-effort: no session / offline / test process (no Supabase) → null.
  ///
  /// Also guards against a *stale* remembered guid (#156): `profiles.boatGuid`
  /// can end up pointing at a boat this account has no ownership/membership
  /// claim to (e.g. corrupted by the SharedPreferences-reuse bug this same
  /// change fixes, before the fix landed) — reusing it would keep every push
  /// permanently RLS-rejected instead of self-healing on the next enroll. The
  /// `boats` row is only visible under `boats_select`'s
  /// `accessible_boat_ids()` check, so an inaccessible guid simply returns no
  /// row here rather than an error.
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
      if (guid == null || guid.isEmpty) return null;

      final visible = await SupabaseClientWrapper.instance
          .from('boats')
          .select('supabaseId')
          .eq('supabaseId', guid)
          .maybeSingle();
      if (visible == null) {
        unawaited(ErrorLogService().logWarning(
          'profiles.boatGuid=$guid is not accessible to this account — ignoring stale remembered guid',
          context: 'boat_enrollment_service: _remoteGuid',
        ));
        return null;
      }
      return guid;
    } catch (e) {
      unawaited(ErrorLogService()
          .logWarning('remote boat GUID lookup failed: $e', context: 'boat_enrollment_service: _remoteGuid'));
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
    } catch (e) {
      // Offline / anonymous / test process — harmless, retried on next enroll.
      unawaited(ErrorLogService().logWarning(
        'remote boat GUID save failed: $e',
        context: 'boat_enrollment_service: _saveRemoteGuid',
      ));
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
