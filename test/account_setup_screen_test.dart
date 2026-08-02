import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/providers/shopping_provider.dart';
import 'package:sisu_mate/services/auth_service.dart';
import 'package:sisu_mate/services/boat_enrollment_service.dart';

import 'test_helpers/fake_auth_backend.dart';

// #128: after sign-up + boat naming, Settings -> Active Boat must show the
// entered name immediately, without an app restart. Root cause was
// account_setup_screen.dart's _createOwnedBoat invalidating
// userSettingsProvider/activeBoatProvider but never boatsProvider — a
// FutureProvider that caches its value once read, so a Settings screen that
// had already resolved it once (common on a fresh install) kept showing the
// stale pre-signup "My Boat" name even though the boat row itself was
// correctly renamed. This exercises the exact same sequence of calls
// _createOwnedBoat makes (enroll -> push -> claim -> settings -> invalidate),
// not just BoatEnrollmentService in isolation (already covered by
// boat_enrollment_service_test.dart) — the bug was specifically about a
// stale Riverpod cache, not stale DB data.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FakeAuthBackend backend;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    backend = FakeAuthBackend();

    await db.into(db.boats).insert(BoatsCompanion.insert(
        supabaseId: const Value(BoatEnrollmentService.defaultBoatId),
        name: const Value('My Boat')));
    await db.into(db.userSettingsTable).insert(
          UserSettingsTableCompanion.insert(
            id: const Value(1),
            activeBoatSupabaseId:
                const Value(BoatEnrollmentService.defaultBoatId),
          ),
        );

    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      authServiceProvider.overrideWith((ref) => AuthService(ref, backend: backend)),
    ]);
  });

  tearDown(() {
    backend.dispose();
    container.dispose();
    db.close();
  });

  Future<void> createOwnedBoat(AuthService auth, String boatName) async {
    final guid = await container
        .read(boatEnrollmentServiceProvider)
        .enroll(name: boatName, ownerId: auth.currentUser?.id);
    final boat = await container.read(boatRepositoryProvider).getBoatById(guid);
    if (boat != null) {
      await container.read(boatRepositoryProvider).updateBoat(boat);
      await auth.claimBoatOwnership(guid);
    }
    final settings = await container.read(userSettingsProvider.future);
    if (settings != null) {
      settings.activeBoatSupabaseId = guid;
      await container.read(userSettingsRepositoryProvider).updateSettings(settings);
    }
    container.invalidate(userSettingsProvider);
    container.invalidate(activeBoatProvider);
    container.invalidate(boatsProvider); // the #128 fix
  }

  test(
      'boatsProvider reflects the renamed boat after sign-up, even when read '
      'once beforehand (Settings already open pre-signup)', () async {
    final auth = container.read(authServiceProvider);
    await auth.signUp('skipper@example.com', 'hunter22');

    // Settings resolved boatsProvider once before sign-up — exactly what
    // made the cache go stale in the reported bug.
    final before = await container.read(boatsProvider.future);
    expect(before.single.name, 'My Boat');

    await createOwnedBoat(auth, 'Sisu');

    final after = await container.read(boatsProvider.future);
    expect(after, hasLength(1));
    expect(after.single.name, 'Sisu',
        reason: 'boatsProvider must be invalidated so Settings shows the '
            'renamed boat immediately, without an app restart (#128)');
  });

  test(
      'regression guard: without invalidating boatsProvider, the cache would '
      'stay stale (proves the fix is load-bearing)', () async {
    final auth = container.read(authServiceProvider);
    await auth.signUp('skipper@example.com', 'hunter22');
    await container.read(boatsProvider.future); // cache it, pre-signup

    // Same sequence as createOwnedBoat, minus the boatsProvider invalidation
    // — reproduces the pre-fix bug directly against the DB + provider layer.
    final guid = await container
        .read(boatEnrollmentServiceProvider)
        .enroll(name: 'Sisu', ownerId: auth.currentUser?.id);
    final boat = await container.read(boatRepositoryProvider).getBoatById(guid);
    expect(boat, isNotNull);

    final stale = await container.read(boatsProvider.future);
    expect(stale.single.name, 'My Boat',
        reason: 'without invalidation the FutureProvider cache is stale even '
            'though the underlying boat row was already renamed to "$guid" / '
            'Sisu — this is the exact bug #128 reported');

    final dbBoat = await (db.select(db.boats)
          ..where((t) => t.supabaseId.equals(guid)))
        .getSingle();
    expect(dbBoat.name, 'Sisu',
        reason: 'the DB write itself is correct; only the cached provider is stale');
  });
}
