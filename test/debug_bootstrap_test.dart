import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/auth_service.dart';
import 'package:sisu_mate/services/boat_enrollment_service.dart';
import 'package:sisu_mate/services/debug_bootstrap.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';

import 'test_helpers/fake_auth_backend.dart';

// #178: DebugBootstrap's boat-rename + ownership-claim side effects must not
// fire for an unauthenticated session — only kDebugMode + kForceProForTesting
// being true is not enough on its own (a clean clone with no owner
// credentials configured must not touch a contributor's local boat).
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

  test('no signed-in user (no/failed owner credentials): local boat is left untouched', () async {
    // FakeAuthBackend starts with no user — mirrors a clean clone with empty
    // SUPABASE_DEBUG_EMAIL/PASSWORD, where _ensureOwnerSignedIn no-ops.
    await DebugBootstrap.run(container);

    final boat = await db.select(db.boats).getSingle();
    expect(boat.supabaseId, BoatEnrollmentService.defaultBoatId,
        reason: 'must not rename/enroll the local boat without a real signed-in owner');
    expect(boat.name, 'My Boat');
  });

  test('anonymous (crew) session: left alone, same as before this fix', () async {
    backend.setUser(fakeOwnerUser(id: 'anon-1', isAnonymous: true));
    await DebugBootstrap.run(container);

    final boat = await db.select(db.boats).getSingle();
    expect(boat.supabaseId, BoatEnrollmentService.defaultBoatId);
  });

  test('already signed in as a real user: boat is still enrolled/renamed (gate does not regress the intended flow)', () async {
    backend.setUser(fakeOwnerUser());
    await DebugBootstrap.run(container);

    final boat = await db.select(db.boats).getSingle();
    expect(boat.supabaseId, isNot(BoatEnrollmentService.defaultBoatId));
    expect(boat.name, kDebugBoatName);
  });
}
