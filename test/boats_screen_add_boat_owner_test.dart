import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/auth_service.dart';
import 'package:sisu_mate/ui/boats/boats_screen.dart';

import 'test_helpers/fake_auth_backend.dart';
import 'test_helpers/platform_mocks.dart';

/// #200/#201 follow-up: "Add New Boat" (Manage Boats, Pro multi-boat) never
/// set ownerId, so boats_insert's `ownerId = auth.uid()` RLS check always
/// rejected the push — the boat could never sync, silently staying
/// local-only forever (confirmed live: no such boat row ever reached
/// Supabase).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late FakeAuthBackend authBackend;

  setUp(() {
    mockConnectivityChannel();
    mockPathProviderChannel();
    mockSharedPreferencesChannel();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    authBackend = FakeAuthBackend();
  });

  tearDown(() async {
    authBackend.dispose();
    await db.close();
  });

  testWidgets('a newly added boat is stamped with the signed-in owner id',
      (tester) async {
    authBackend.setUser(fakeOwnerUser(id: 'owner-live-uid'));
    await db.into(db.boats).insert(BoatsCompanion.insert(
          supabaseId: const Value('existing-boat'),
          name: const Value('Sisu'),
          ownerId: const Value('owner-live-uid'),
        ));
    await db.into(db.userSettingsTable).insert(
          UserSettingsTableCompanion.insert(
            id: const Value(1),
            activeBoatSupabaseId: const Value('existing-boat'),
          ),
        );

    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(true)),
      authServiceProvider
          .overrideWith((ref) => AuthService(ref, backend: authBackend)),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: BoatsScreen()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Second Boat');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Boat'));
    await tester.pumpAndSettle();

    final added = await (db.select(db.boats)
          ..where((t) => t.name.equals('Second Boat')))
        .getSingle();
    expect(added.ownerId, 'owner-live-uid',
        reason: 'without ownerId, boats_insert RLS always rejects the push '
            '(#200/#201) and the boat can never sync');
  });
}
