import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/auth_service.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/chef/chef_screen.dart';

import 'test_helpers/fake_auth_backend.dart';
import 'test_helpers/platform_mocks.dart';

/// #137: the drawer's "My Pantry sort" menu only affects My Pantry — it must
/// not appear (and silently no-op) on the Chef tab; Chef gains its own local
/// sort instead. Same pattern/fix as #136 (Cocktails screen).
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
    RevenueCatService.debugProOverrideForTests = false;
  });

  tearDown(() async {
    RevenueCatService.debugProOverrideForTests = null;
    authBackend.dispose();
    await db.close();
  });

  Future<ProviderContainer> pumpScreen(WidgetTester tester) async {
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(true)),
      authServiceProvider
          .overrideWith((ref) => AuthService(ref, backend: authBackend)),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ChefScreen()),
    ));
    await tester.pump();
    await tester.pump();
    return container;
  }

  testWidgets('"My Pantry sort" is present on My Pantry', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('My Pantry'));
    await tester.pumpAndSettle();

    final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffold.openEndDrawer();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('My Pantry sort'), findsOneWidget);
  });

  testWidgets('"My Pantry sort" is hidden on the Chef tab', (tester) async {
    await pumpScreen(tester);
    // Chef is the default (index 0) tab.
    final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffold.openEndDrawer();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('My Pantry sort'), findsNothing);
  });

  testWidgets('Chef tab has its own working sort', (tester) async {
    await db.into(db.recipes).insert(RecipesCompanion.insert(
          supabaseId: const Value('menu_b'),
          name: const Value('B Menu'),
          recipeType: const Value('menu'),
        ));
    await db.into(db.recipes).insert(RecipesCompanion.insert(
          supabaseId: const Value('menu_a'),
          name: const Value('A Menu'),
          recipeType: const Value('menu'),
        ));

    await pumpScreen(tester);

    // 2-column grid: same row, so compare X (left slot = earlier in order).
    // Default ascending: A Menu before B Menu.
    var aOffset = tester.getTopLeft(find.text('A Menu')).dx;
    var bOffset = tester.getTopLeft(find.text('B Menu')).dx;
    expect(aOffset, lessThan(bOffset));

    await tester.tap(find.text('Name A–Z'));
    await tester.pumpAndSettle();

    expect(find.text('Name Z–A'), findsOneWidget,
        reason: 'Chef tab sort toggle must actually flip and re-sort (#137)');
    aOffset = tester.getTopLeft(find.text('A Menu')).dx;
    bOffset = tester.getTopLeft(find.text('B Menu')).dx;
    expect(bOffset, lessThan(aOffset));
  });
}
