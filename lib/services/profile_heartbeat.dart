import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_client.dart';
import 'error_log_service.dart';
import 'revenuecat_service.dart';

/// STALE-DATA: on every signed-in (owner) launch, stamp the account's profile
/// with `lastSeenAt` and the REAL RevenueCat entitlement expiration
/// (`proUntil`). The developer admin tools use these to find boats whose owner
/// lapsed long ago and purge their cloud copies. Best-effort: offline / crew /
/// test processes are silent no-ops.
class ProfileHeartbeat {
  const ProfileHeartbeat._();

  /// TEST3: optional hooks so [stamp] is unit-testable without Supabase /
  /// RevenueCat platform channels. Null in production (live path).
  static Future<User?> Function()? debugCurrentUser;
  static Future<DateTime?> Function()? debugProExpiresAt;
  static Future<void> Function(Map<String, dynamic> row)? debugUpsertProfile;

  /// Clears TEST3 hooks (call from test tearDown).
  static void resetDebugHooks() {
    debugCurrentUser = null;
    debugProExpiresAt = null;
    debugUpsertProfile = null;
  }

  static Future<void> stamp() async {
    try {
      final user = debugCurrentUser != null
          ? await debugCurrentUser!()
          : SupabaseClientWrapper.instance.auth.currentUser;
      if (user == null || user.isAnonymous) return;

      final proUntil = debugProExpiresAt != null
          ? await debugProExpiresAt!()
          : await RevenueCatService().proExpiresAt();

      final row = <String, dynamic>{
        'id': user.id,
        'lastSeenAt': DateTime.now().toUtc().toIso8601String(),
        if (proUntil != null) 'proUntil': proUntil.toUtc().toIso8601String(),
      };

      if (debugUpsertProfile != null) {
        await debugUpsertProfile!(row);
      } else {
        await SupabaseClientWrapper.instance.from('profiles').upsert(row);
      }
    } catch (e) {
      // No session / offline / missing platform channel — retried next launch.
      unawaited(ErrorLogService()
          .logWarning('profile heartbeat stamp failed: $e', context: 'profile_heartbeat: stamp'));
    }
  }
}
