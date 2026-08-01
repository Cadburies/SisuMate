import '../domain/repositories/boat_repository.dart';
import '../domain/repositories/user_settings_repository.dart';
import '../models/models.dart';
import 'auth_service.dart';
import 'boat_enrollment_service.dart';
import 'sync_service.dart';

/// TEST15 orchestration: redeem share code first, then apply local side
/// effects. Invalid codes throw before any Drift write (no half-enrolled boat).
class JoinBoatService {
  JoinBoatService({
    required this.auth,
    required this.boats,
    required this.settings,
    required this.enrollment,
    required this.sync,
  });

  final AuthService auth;
  final BoatRepository boats;
  final UserSettingsRepository settings;
  final BoatEnrollmentService enrollment;
  final SyncService sync;

  /// Redeem [code], upsert the boat locally, switch the active boat, restamp
  /// content, and start crew-eligible sync. Returns the joined boat id + name.
  Future<({String boatId, String name})> join(String code) async {
    // Remote redeem first — must throw before any local mutation on bad codes.
    final joined = await auth.joinBoat(code);

    final boat = Boat()
      ..supabaseId = joined.boatId
      ..name = joined.name
      ..isSynced = true
      ..lastModified = DateTime.now().toUtc();
    // Local-only: never queue the owner's boat row for outbound push.
    await boats.upsertLocal(boat);

    final s = await settings.getSettings();
    if (s != null) {
      s.activeBoatSupabaseId = joined.boatId;
      await settings.updateSettings(s);
    }

    await enrollment.restampContentToBoat(joined.boatId);
    await sync.ensureStarted();
    return joined;
  }

  /// User-facing copy for join failures (matches [JoinBoatScreen] dialog).
  static String friendlyError(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('invalid boat code') ||
        s.contains('invalid share code') ||
        s.contains('invalid code')) {
      return 'That code didn’t match a boat.';
    }
    return 'Could not join: $e';
  }
}
