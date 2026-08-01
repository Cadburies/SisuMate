import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_client.dart';

/// TEST3 seam: injectable auth + boat RPC surface used by [AuthService].
///
/// Production uses [LiveAuthBackend] over Supabase. Unit tests inject a fake
/// so sign-in / join / claim paths are coverable without a real session.
abstract class AuthBackend {
  User? get currentUser;

  Stream<AuthState> get onAuthStateChange;

  Future<void> signInWithOtp({
    required String email,
    String? emailRedirectTo,
  });

  Future<void> signOut();

  Future<void> signInWithPassword({
    required String email,
    required String password,
  });

  Future<void> signUp({
    required String email,
    required String password,
  });

  Future<void> signInAnonymously();

  /// Redeems a boat share code; returns the joined boat's `supabaseId`.
  Future<String> redeemBoatCode(String code);

  /// Selects a single boat column map, or null if missing.
  Future<Map<String, dynamic>?> fetchBoatRow(
    String boatSupabaseId, {
    required String select,
  });

  Future<void> updateBoatOwner({
    required String boatSupabaseId,
    required String ownerId,
  });
}

/// Production [AuthBackend] over [SupabaseClientWrapper.instance].
class LiveAuthBackend implements AuthBackend {
  const LiveAuthBackend();

  SupabaseClient get _c => SupabaseClientWrapper.instance;

  @override
  User? get currentUser => _c.auth.currentUser;

  @override
  Stream<AuthState> get onAuthStateChange => _c.auth.onAuthStateChange;

  @override
  Future<void> signInWithOtp({
    required String email,
    String? emailRedirectTo,
  }) =>
      _c.auth.signInWithOtp(email: email, emailRedirectTo: emailRedirectTo);

  @override
  Future<void> signOut() => _c.auth.signOut();

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) =>
      _c.auth.signInWithPassword(email: email, password: password);

  @override
  Future<void> signUp({
    required String email,
    required String password,
  }) =>
      _c.auth.signUp(email: email, password: password);

  @override
  Future<void> signInAnonymously() => _c.auth.signInAnonymously();

  @override
  Future<String> redeemBoatCode(String code) async {
    final result =
        await _c.rpc('redeem_boat_code', params: {'p_code': code});
    return result as String;
  }

  @override
  Future<Map<String, dynamic>?> fetchBoatRow(
    String boatSupabaseId, {
    required String select,
  }) async {
    final row = await _c
        .from('boats')
        .select(select)
        .eq('supabaseId', boatSupabaseId)
        .maybeSingle();
    return row;
  }

  @override
  Future<void> updateBoatOwner({
    required String boatSupabaseId,
    required String ownerId,
  }) async {
    await _c
        .from('boats')
        .update({'ownerId': ownerId}).eq('supabaseId', boatSupabaseId);
  }
}
