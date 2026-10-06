import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_backend.dart';

class AuthService {
  AuthService(this.ref, {AuthBackend? backend})
      : _backend = backend ?? const LiveAuthBackend();

  final Ref ref;
  final AuthBackend _backend;

  User? get currentUser => _backend.currentUser;

  Stream<User?> get authState =>
      _backend.onAuthStateChange.map((data) => data.session?.user);

  Future<void> signOut() => _backend.signOut();

  Future<void> signIn(String email, String password) async {
    await _backend.signInWithPassword(email: email, password: password);
  }

  /// Owner sign-up at Pro upgrade (email + password account creation).
  Future<void> signUp(String email, String password) async {
    await _backend.signUp(email: email, password: password);
  }

  /// Crew join: anonymous device identity, then redeem a boat's share code.
  /// Requires "Allow anonymous sign-ins" enabled on the Supabase project.
  Future<void> signInAnonymously() async {
    await _backend.signInAnonymously();
  }

  /// Redeems a per-boat [code] for the current (owner or anonymous) user and
  /// returns the joined boat's `supabaseId`. Throws on an invalid code.
  Future<String> redeemBoatCode(String code) => _backend.redeemBoatCode(code);

  /// Crew flow: ensure a session (anonymous if none), redeem [code], and return
  /// the joined boat's id + name. Throws on an invalid code.
  Future<({String boatId, String name})> joinBoat(String code) async {
    if (currentUser == null) {
      await signInAnonymously();
    }
    final boatId = await redeemBoatCode(code);
    final row = await _backend.fetchBoatRow(boatId, select: 'name');
    return (boatId: boatId, name: (row?['name'] as String?) ?? 'Shared Boat');
  }

  bool get isAnonymous => currentUser?.isAnonymous ?? false;

  /// Developer account — unlocks the hidden admin screen. Server-side the
  /// admin_* RPCs re-verify against `app_admins`, so this is UI gating only.
  static const developerEmail = 'sailingsisu@outlook.com';
  bool get isDeveloper => currentUser?.email == developerEmail;

  /// Best-effort human name for sign-offs: metadata name, else the email's
  /// local part, else null.
  String? get displayName {
    final u = currentUser;
    if (u == null) return null;
    final meta = u.userMetadata;
    final name = (meta?['full_name'] ?? meta?['name']) as String?;
    if (name != null && name.trim().isNotEmpty) return name.trim();
    final email = u.email;
    if (email != null && email.contains('@')) return email.split('@').first;
    return null;
  }

  /// Stamp the current user as a boat's owner in Supabase (RLS ownership).
  /// Best-effort: boats sync with no owner column, so this sets it directly.
  Future<void> claimBoatOwnership(String boatSupabaseId) async {
    final uid = currentUser?.id;
    if (uid == null || boatSupabaseId.isEmpty) return;
    await _backend.updateBoatOwner(
      boatSupabaseId: boatSupabaseId,
      ownerId: uid,
    );
  }

  /// The share code crew use to join [boatSupabaseId], or null if unavailable.
  Future<String?> fetchBoatShareCode(String boatSupabaseId) async {
    final row =
        await _backend.fetchBoatRow(boatSupabaseId, select: 'shareCode');
    return row?['shareCode'] as String?;
  }

  /// Permanently deletes the signed-in user's account + owned cloud data.
  /// Caller is responsible for the local wipe (factory reset) afterward —
  /// this only removes the Supabase side. Throws on failure.
  Future<void> deleteAccount() => _backend.deleteAccount();
}
