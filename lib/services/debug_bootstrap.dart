import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di.dart';
import '../providers/shopping_provider.dart';
import 'revenuecat_service.dart';

/// Debug-only convenience: when the Pro testing bypass is on, sign the fixed
/// owner account in and make sure a boat named [kDebugBoatName] is the active
/// boat, so on-device Pro sync runs against Supabase without the (not-yet-built)
/// sign-up / boat-picker UI. No-op in profile/release builds.
class DebugBootstrap {
  const DebugBootstrap._();

  static const _email =
      String.fromEnvironment('SUPABASE_DEBUG_EMAIL');
  static const _password =
      String.fromEnvironment('SUPABASE_DEBUG_PASSWORD');

  static Future<void> run(ProviderContainer ref) async {
    if (!kDebugMode || !kForceProForTesting) return;

    // An anonymous session means this device deliberately joined a boat as
    // CREW ("Join a boat") — leave it alone so crew testing survives relaunch.
    if (ref.read(authServiceProvider).isAnonymous) return;

    await _ensureOwnerSignedIn(ref);

    // The boat-rename + ownership-claim side effects below are scoped to the
    // developer's own device: without a real signed-in owner (no credentials
    // configured, wrong credentials, or offline), a plain `flutter run` from
    // a clean clone must not rename a contributor's local boat or force a
    // boat-account context under nobody's identity (#178).
    if (ref.read(authServiceProvider).currentUser == null) return;

    await _ensureActiveDebugBoat(ref);
  }

  static Future<void> _ensureOwnerSignedIn(ProviderContainer ref) async {
    final auth = ref.read(authServiceProvider);
    if (auth.currentUser != null) return; // already the owner
    if (_email.isEmpty || _password.isEmpty) return;
    try {
      await auth.signIn(_email, _password);
    } catch (_) {
      // Offline or wrong creds — keep going; sync just stays off.
    }
  }

  static Future<void> _ensureActiveDebugBoat(ProviderContainer ref) async {
    // Enroll: adopt-and-rename the default boat into a persisted GUID named Sisu.
    final auth = ref.read(authServiceProvider);
    final guid = await ref
        .read(boatEnrollmentServiceProvider)
        .enroll(name: kDebugBoatName, ownerId: auth.currentUser?.id);

    // Push the boat so it exists in Supabase (DB-generates its shareCode so crew
    // can join), then stamp ownership. Both awaited → no race.
    final boatRepo = ref.read(boatRepositoryProvider);
    final boat = await boatRepo.getBoatById(guid);
    if (boat != null) {
      await boatRepo.updateBoat(boat);
      try {
        await auth.claimBoatOwnership(guid);
      } catch (_) {
        // Offline — harmless under permissive RLS.
      }
    }

    final settingsRepo = ref.read(userSettingsRepositoryProvider);
    final settings = await ref.read(userSettingsProvider.future);
    if (settings != null && settings.activeBoatSupabaseId != guid) {
      settings.activeBoatSupabaseId = guid;
      await settingsRepo.updateSettings(settings);
      ref.invalidate(userSettingsProvider);
      ref.invalidate(activeBoatProvider);
    }
  }
}
