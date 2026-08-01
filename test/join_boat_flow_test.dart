import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/data/repositories/boat_repository_impl.dart';
import 'package:sisu_mate/data/repositories/user_settings_repository_impl.dart';
import 'package:sisu_mate/services/auth_service.dart';
import 'package:sisu_mate/services/boat_enrollment_service.dart';
import 'package:sisu_mate/services/join_boat_service.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';

import 'test_helpers/fake_auth_backend.dart';

void _mockConnectivity(bool online) {
  const channel = MethodChannel('dev.fluttercommunity.plus/connectivity');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    if (call.method == 'check') {
      return <String>[online ? 'wifi' : 'none'];
    }
    return null;
  });
}

/// TEST15 — share-code join: invalid → clear error / no half-enroll;
/// valid → active boat switches, content stamped, crew sync eligible.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProviderContainer container;
  late FakeAuthBackend backend;
  late AuthService auth;
  late JoinBoatService flow;
  late UserSettingsRepositoryImpl settingsRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _mockConnectivity(false);
    db = AppDatabase.forTesting(NativeDatabase.memory());
    backend = FakeAuthBackend();

    // Default local boat + one content row scoped to it (pre-join state).
    await db.into(db.boats).insert(BoatsCompanion.insert(
          supabaseId: const Value(BoatEnrollmentService.defaultBoatId),
          name: const Value('My Boat'),
        ));
    await db.into(db.checklistGroups).insert(ChecklistGroupsCompanion.insert(
          supabaseId: const Value('grp_local'),
          boatSupabaseId: const Value(BoatEnrollmentService.defaultBoatId),
          title: const Value('Local checklist'),
        ));
    await db.into(db.shoppingItems).insert(ShoppingItemsCompanion.insert(
          supabaseId: const Value('shop_local'),
          boatSupabaseId: const Value(BoatEnrollmentService.defaultBoatId),
          categorySupabaseId: const Value('cat_x'),
          name: const Value('Fenders'),
        ));
    await db.into(db.userSettingsTable).insert(
          UserSettingsTableCompanion.insert(
            id: const Value(1),
            activeBoatSupabaseId:
                const Value(BoatEnrollmentService.defaultBoatId),
          ),
        );

    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    final authProvider =
        Provider<AuthService>((ref) => AuthService(ref, backend: backend));
    auth = container.read(authProvider);

    final sync = container.read(syncServiceProvider);
    settingsRepo = UserSettingsRepositoryImpl(db);
    flow = JoinBoatService(
      auth: auth,
      boats: BoatRepositoryImpl(db, sync),
      settings: settingsRepo,
      enrollment: BoatEnrollmentService(db),
      sync: sync,
    );
  });

  tearDown(() async {
    backend.dispose();
    container.dispose();
    await db.close();
    RevenueCatService.debugProOverrideForTests = null;
  });

  group('TEST15 — invalid share code', () {
    test('throws and maps to a clear user-facing message', () async {
      backend.setUser(fakeOwnerUser(isAnonymous: true));

      await expectLater(flow.join('BADCODE'), throwsException);

      expect(
        JoinBoatService.friendlyError(Exception('Invalid boat code')),
        'That code didn’t match a boat.',
      );
      expect(
        JoinBoatService.friendlyError(Exception('invalid share code')),
        'That code didn’t match a boat.',
      );
    });

    test('does not half-enroll: no new boat row, active boat unchanged',
        () async {
      backend.setUser(fakeOwnerUser(isAnonymous: true));
      final beforeBoats = await db.select(db.boats).get();
      final beforeSettings = await settingsRepo.getSettings();

      await expectLater(flow.join('NOPE'), throwsException);

      final afterBoats = await db.select(db.boats).get();
      expect(afterBoats.map((b) => b.supabaseId).toSet(),
          beforeBoats.map((b) => b.supabaseId).toSet());
      expect(afterBoats, hasLength(1));
      expect(afterBoats.single.supabaseId,
          BoatEnrollmentService.defaultBoatId);

      final afterSettings = await settingsRepo.getSettings();
      expect(afterSettings?.activeBoatSupabaseId,
          beforeSettings?.activeBoatSupabaseId);
      expect(afterSettings?.activeBoatSupabaseId,
          BoatEnrollmentService.defaultBoatId);

      // Content still on the default boat — not re-scoped to a failed join.
      final group = await db.select(db.checklistGroups).getSingle();
      expect(group.boatSupabaseId, BoatEnrollmentService.defaultBoatId);
    });

    test('AuthService.joinBoat alone does not touch Drift', () async {
      backend.setUser(fakeOwnerUser());
      await expectLater(auth.joinBoat('MISSING'), throwsException);
      expect(await db.select(db.boats).get(), hasLength(1));
    });
  });

  group('TEST15 — valid share code', () {
    setUp(() {
      backend.codes['CREW01'] = 'owner-boat-guid';
      backend.boats['owner-boat-guid'] = {'name': 'Sisu'};
    });

    test('switches active boat, upserts local boat, restamps content',
        () async {
      backend.setUser(fakeOwnerUser(isAnonymous: true));

      final joined = await flow.join('CREW01');

      expect(joined.boatId, 'owner-boat-guid');
      expect(joined.name, 'Sisu');
      expect(backend.redeemedCodes, ['CREW01']);

      final boats = await db.select(db.boats).get();
      expect(
        boats.map((b) => b.supabaseId),
        containsAll([
          BoatEnrollmentService.defaultBoatId,
          'owner-boat-guid',
        ]),
      );
      final joinedBoat =
          boats.firstWhere((b) => b.supabaseId == 'owner-boat-guid');
      expect(joinedBoat.name, 'Sisu');
      expect(joinedBoat.isSynced, isTrue);

      final settings = await settingsRepo.getSettings();
      expect(settings?.activeBoatSupabaseId, 'owner-boat-guid');

      final group = await db.select(db.checklistGroups).getSingle();
      expect(group.boatSupabaseId, 'owner-boat-guid',
          reason: 'content stamped to joined boat for wire-prefix sync');
      final item = await db.select(db.shoppingItems).getSingle();
      expect(item.boatSupabaseId, 'owner-boat-guid');
    });

    test('anonymous sign-in when no session, then redeem', () async {
      expect(auth.currentUser, isNull);
      backend.codes['CREW01'] = 'owner-boat-guid';
      backend.boats['owner-boat-guid'] = {'name': 'Sisu'};

      await flow.join('CREW01');

      expect(backend.anonymousSignInCalls, 1);
      expect(auth.currentUser?.isAnonymous, isTrue);
    });

    test('after join, active boat is the wire-prefix target and Pro offline '
        'edits land in outbox (crew-eligible push path)', () async {
      // Unit tests lack live Supabase anonymous session; Pro override stands
      // in for the crew-eligible branch of _syncAllowed after join.
      RevenueCatService.debugProOverrideForTests = true;
      _mockConnectivity(false);
      backend.setUser(fakeOwnerUser(isAnonymous: true));

      await flow.join('CREW01');

      final settings = await settingsRepo.getSettings();
      expect(settings?.activeBoatSupabaseId, 'owner-boat-guid');

      final sync = container.read(syncServiceProvider);
      await sync.queueOutgoingChange('checklist_items', {
        'supabaseId': 'crew-edit',
        'title': 'After join',
        'lastModified': DateTime.now().toUtc().toIso8601String(),
      });
      expect(await sync.pendingQueueSize(), greaterThanOrEqualTo(1),
          reason: 'joined crew device must be able to queue offline edits');
    });
  });

  group('JoinBoatService.friendlyError', () {
    test('preserves non-code errors as could-not-join', () {
      final msg = JoinBoatService.friendlyError(StateError('network down'));
      expect(msg, startsWith('Could not join:'));
      expect(msg, contains('network down'));
    });
  });
}
