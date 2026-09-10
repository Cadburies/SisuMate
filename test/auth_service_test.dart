import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/auth_service.dart';
import 'package:sisu_mate/services/auth_backend.dart';

import 'test_helpers/fake_auth_backend.dart';

void main() {
  late ProviderContainer container;
  late FakeAuthBackend backend;
  late AuthService auth;

  setUp(() {
    backend = FakeAuthBackend();
    // Resolve AuthService through a real Ref (Riverpod 3).
    final authProvider =
        Provider<AuthService>((ref) => AuthService(ref, backend: backend));
    container = ProviderContainer();
    auth = container.read(authProvider);
  });

  tearDown(() {
    backend.dispose();
    container.dispose();
  });

  group('AuthService display helpers', () {
    test('isDeveloper is true only for the hard-coded developer email', () {
      backend.setUser(fakeOwnerUser(email: AuthService.developerEmail));
      expect(auth.isDeveloper, isTrue);

      backend.setUser(fakeOwnerUser(email: 'other@example.com'));
      expect(auth.isDeveloper, isFalse);

      backend.setUser(null);
      expect(auth.isDeveloper, isFalse);
    });

    test('isAnonymous follows the current user', () {
      expect(auth.isAnonymous, isFalse);

      backend.setUser(fakeOwnerUser(isAnonymous: true));
      expect(auth.isAnonymous, isTrue);

      backend.setUser(fakeOwnerUser(isAnonymous: false));
      expect(auth.isAnonymous, isFalse);
    });

    test('displayName prefers full_name metadata, then email local part', () {
      backend.setUser(fakeOwnerUser(
        email: 'ada@example.com',
        userMetadata: {'full_name': 'Ada Lovelace'},
      ));
      expect(auth.displayName, 'Ada Lovelace');

      backend.setUser(fakeOwnerUser(
        email: 'ada@example.com',
        userMetadata: {'name': '  Ada  '},
      ));
      expect(auth.displayName, 'Ada');

      backend.setUser(fakeOwnerUser(email: 'ada@example.com'));
      expect(auth.displayName, 'ada');

      backend.setUser(null);
      expect(auth.displayName, isNull);
    });
  });

  group('AuthService auth actions', () {
    test('signInWithMagicLink records the email on the backend', () async {
      await auth.signInWithMagicLink('crew@example.com');
      expect(backend.signedInWithOtp, ['crew@example.com']);
    });

    test('signIn / signUp / signOut hit the backend', () async {
      await auth.signUp('new@example.com', 'secret');
      expect(backend.signedUp, [('new@example.com', 'secret')]);
      expect(auth.currentUser?.email, 'new@example.com');

      await auth.signOut();
      expect(backend.signOutCalls, 1);
      expect(auth.currentUser, isNull);

      await auth.signIn('new@example.com', 'secret');
      expect(backend.signedInWithPassword, [('new@example.com', 'secret')]);
    });

    test('claimBoatOwnership no-ops without a user or empty id', () async {
      await auth.claimBoatOwnership('boat-1');
      expect(backend.claimedOwnership, isEmpty);

      backend.setUser(fakeOwnerUser(id: 'owner-9'));
      await auth.claimBoatOwnership('');
      expect(backend.claimedOwnership, isEmpty);

      await auth.claimBoatOwnership('boat-1');
      expect(backend.claimedOwnership, [('boat-1', 'owner-9')]);
    });

    test('fetchBoatShareCode reads shareCode from the boat row', () async {
      backend.boats['boat-1'] = {'shareCode': 'SISU-42'};
      expect(await auth.fetchBoatShareCode('boat-1'), 'SISU-42');
      expect(await auth.fetchBoatShareCode('missing'), isNull);
    });

    test('deleteAccount hits the backend and clears the session', () async {
      backend.setUser(fakeOwnerUser());
      await auth.deleteAccount();
      expect(backend.deleteAccountCalls, 1);
      expect(auth.currentUser, isNull);
    });

    test('deleteAccount propagates backend failures', () async {
      backend.setUser(fakeOwnerUser());
      backend.shouldFail = true;
      await expectLater(auth.deleteAccount(), throwsException);
    });
  });

  group('AuthService joinBoat', () {
    test('signs in anonymously when no session, then redeems the code',
        () async {
      backend.codes['ABC'] = 'boat-guid';
      backend.boats['boat-guid'] = {'name': 'Sisu'};

      final joined = await auth.joinBoat('ABC');

      expect(backend.anonymousSignInCalls, 1);
      expect(backend.redeemedCodes, ['ABC']);
      expect(joined.boatId, 'boat-guid');
      expect(joined.name, 'Sisu');
    });

    test('skips anonymous sign-in when already signed in', () async {
      backend.setUser(fakeOwnerUser());
      backend.codes['XYZ'] = 'boat-2';
      backend.boats['boat-2'] = {'name': 'Mirror'};

      final joined = await auth.joinBoat('XYZ');

      expect(backend.anonymousSignInCalls, 0);
      expect(joined.boatId, 'boat-2');
      expect(joined.name, 'Mirror');
    });

    test('defaults name when the boat row is missing a name', () async {
      backend.setUser(fakeOwnerUser());
      backend.codes['NO_NAME'] = 'boat-3';
      backend.boats['boat-3'] = {};

      final joined = await auth.joinBoat('NO_NAME');
      expect(joined.name, 'Shared Boat');
    });

    test('propagates invalid share-code failures', () async {
      backend.setUser(fakeOwnerUser());
      await expectLater(auth.joinBoat('BAD'), throwsException);
    });
  });

  group('LiveAuthBackend smoke', () {
    test('constructs without throwing (production default path)', () {
      expect(const LiveAuthBackend(), isA<AuthBackend>());
    });
  });
}
