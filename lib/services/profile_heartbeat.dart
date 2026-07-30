import '../core/supabase_client.dart';
import 'revenuecat_service.dart';

/// STALE-DATA: on every signed-in (owner) launch, stamp the account's profile
/// with `lastSeenAt` and the REAL RevenueCat entitlement expiration
/// (`proUntil`). The developer admin tools use these to find boats whose owner
/// lapsed long ago and purge their cloud copies. Best-effort: offline / crew /
/// test processes are silent no-ops.
class ProfileHeartbeat {
  const ProfileHeartbeat._();

  static Future<void> stamp() async {
    try {
      final user = SupabaseClientWrapper.instance.auth.currentUser;
      if (user == null || user.isAnonymous) return;
      final proUntil = await RevenueCatService().proExpiresAt();
      await SupabaseClientWrapper.instance.from('profiles').upsert({
        'id': user.id,
        'lastSeenAt': DateTime.now().toUtc().toIso8601String(),
        if (proUntil != null) 'proUntil': proUntil.toUtc().toIso8601String(),
      });
    } catch (_) {
      // No session / offline / missing platform channel — retried next launch.
    }
  }
}
