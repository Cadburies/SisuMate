import 'dart:async';

import 'package:sisu_mate/services/auth_backend.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// In-memory [AuthBackend] for TEST3 AuthService unit tests.
class FakeAuthBackend implements AuthBackend {
  FakeAuthBackend({User? user}) : _user = user;

  User? _user;
  bool shouldFail = false;

  final List<String> signedInWithOtp = [];
  final List<(String email, String password)> signedInWithPassword = [];
  final List<(String email, String password)> signedUp = [];
  int signOutCalls = 0;
  int deleteAccountCalls = 0;
  int anonymousSignInCalls = 0;
  final List<String> redeemedCodes = [];
  final List<(String boatId, String ownerId)> claimedOwnership = [];

  /// boatId → column values.
  final Map<String, Map<String, dynamic>> boats = {};

  /// code → boatId for [redeemBoatCode].
  final Map<String, String> codes = {};

  final _authController = StreamController<AuthState>.broadcast();

  void setUser(User? user) {
    _user = user;
    // AuthService maps onAuthStateChange → session?.user; session may be null.
    _authController.add(
      AuthState(
        user == null ? AuthChangeEvent.signedOut : AuthChangeEvent.signedIn,
        null,
      ),
    );
  }

  void dispose() {
    _authController.close();
  }

  void _throwIfFailing() {
    if (shouldFail) throw Exception('FakeAuthBackend: forced failure');
  }

  @override
  User? get currentUser => _user;

  @override
  Stream<AuthState> get onAuthStateChange => _authController.stream;

  @override
  Future<void> signInWithOtp({
    required String email,
    String? emailRedirectTo,
  }) async {
    _throwIfFailing();
    signedInWithOtp.add(email);
  }

  @override
  Future<void> signOut() async {
    _throwIfFailing();
    signOutCalls++;
    _user = null;
  }

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    _throwIfFailing();
    signedInWithPassword.add((email, password));
    _user = User(
      id: 'user-${email.hashCode}',
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      email: email,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    _throwIfFailing();
    signedUp.add((email, password));
    _user = User(
      id: 'user-${email.hashCode}',
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      email: email,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  @override
  Future<void> signInAnonymously() async {
    _throwIfFailing();
    anonymousSignInCalls++;
    _user = User(
      id: 'anon-$anonymousSignInCalls',
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: DateTime.now().toUtc().toIso8601String(),
      isAnonymous: true,
    );
  }

  @override
  Future<String> redeemBoatCode(String code) async {
    _throwIfFailing();
    redeemedCodes.add(code);
    final boatId = codes[code];
    // Match live RPC wording so JoinBoatService.friendlyError maps cleanly.
    if (boatId == null) throw Exception('Invalid boat code');
    return boatId;
  }

  @override
  Future<Map<String, dynamic>?> fetchBoatRow(
    String boatSupabaseId, {
    required String select,
  }) async {
    _throwIfFailing();
    final row = boats[boatSupabaseId];
    if (row == null) return null;
    // Return only requested columns when comma-separated, else full row.
    final cols = select.split(',').map((s) => s.trim()).toList();
    if (cols.length == 1 && cols.single == '*') {
      return Map<String, dynamic>.from(row);
    }
    return {
      for (final c in cols)
        if (row.containsKey(c)) c: row[c],
    };
  }

  @override
  Future<void> updateBoatOwner({
    required String boatSupabaseId,
    required String ownerId,
  }) async {
    _throwIfFailing();
    claimedOwnership.add((boatSupabaseId, ownerId));
    final existing = boats[boatSupabaseId] ?? {};
    boats[boatSupabaseId] = {...existing, 'ownerId': ownerId};
  }

  @override
  Future<void> deleteAccount() async {
    _throwIfFailing();
    deleteAccountCalls++;
    _user = null;
  }
}

/// Convenience factory for a non-anonymous owner [User].
User fakeOwnerUser({
  String id = 'owner-1',
  String email = 'skipper@example.com',
  Map<String, dynamic>? userMetadata,
  bool isAnonymous = false,
}) {
  return User(
    id: id,
    appMetadata: const {},
    userMetadata: userMetadata,
    aud: 'authenticated',
    email: email,
    createdAt: DateTime.now().toUtc().toIso8601String(),
    isAnonymous: isAnonymous,
  );
}
