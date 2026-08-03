import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di.dart';
import '../models/models.dart';
import '../providers/shopping_provider.dart';
import 'revenuecat_service.dart';

/// Debug-only convenience: when the Pro testing bypass is on, sign the fixed
/// owner account in and make sure a boat named [kDebugBoatName] is the active
/// boat, so on-device Pro sync runs against Supabase without the (not-yet-built)
/// sign-up / boat-picker UI. Also seeds that boat's LLM BYOK key from
/// `XAI_KEY` (dart-defines) if it doesn't already have one, so LLM features
/// (#203+) are testable without opening Settings each run — see [_xaiKey].
/// No-op in profile/release builds.
class DebugBootstrap {
  const DebugBootstrap._();

  static const _email =
      String.fromEnvironment('SUPABASE_DEBUG_EMAIL');
  static const _password =
      String.fromEnvironment('SUPABASE_DEBUG_PASSWORD');

  // Developer convenience only (user request, 2026-08-02): #203/#215 made
  // the LLM BYOK key "purely user-entered, per-boat data" so it never ships
  // baked into a build — this is a narrow, deliberate exception to that for
  // local testing, not a reversal. Same kDebugMode-gated path as the rest of
  // this class; a release build never reads `XAI_KEY` (it isn't passed to
  // `flutter build`) and `dart-defines.json` holding it is gitignored, same
  // as the Supabase debug credentials above. xAI only (not Kimi/Anthropic —
  // no `LlmProvider` enum value exists for either yet; that's #211).
  static const _xaiKey = String.fromEnvironment('XAI_KEY');

  /// Test-only override — `String.fromEnvironment` is resolved at compile
  /// time so [_xaiKey] itself can't be injected; tests set this instead of
  /// passing a dart-define. Mirrors [RevenueCatService.debugProOverrideForTests].
  static String? debugXaiKeyOverrideForTests;
  static String get _resolvedXaiKey => debugXaiKeyOverrideForTests ?? _xaiKey;

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
      // Never overwrite a key the developer deliberately set/changed by hand
      // for a specific test — only fills a genuinely empty xai slot.
      final xaiKey = _resolvedXaiKey;
      final hasXaiKey = boat.llmApiKeys
          .any((e) => e.provider == 'xai' && e.apiKey.isNotEmpty);
      if (!hasXaiKey && xaiKey.isNotEmpty) {
        boat.llmApiKeys = [
          ...boat.llmApiKeys.where((e) => e.provider != 'xai'),
          LlmApiKeyEntry(provider: 'xai', apiKey: xaiKey),
        ];
        boat.activeLlmProvider ??= 'xai';
      }
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
