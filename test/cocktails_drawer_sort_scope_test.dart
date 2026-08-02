import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/auth_service.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/cocktails/cocktails_screen.dart';

import 'test_helpers/fake_auth_backend.dart';
import 'test_helpers/platform_mocks.dart';

/// #136: the drawer's "My Bar sort" menu only affects My Bar — it must not
/// appear (and silently no-op) on the Cocktails/House tabs; House gains its
/// own local sort instead.
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
      child: const MaterialApp(home: CocktailsScreen()),
    ));
    await tester.pump();
    await tester.pump();
    return container;
  }

  testWidgets('"My Bar sort" is present on My Bar', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('My Bar'));
    await tester.pumpAndSettle();

    final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffold.openEndDrawer();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('My Bar sort'), findsOneWidget);
  });

  testWidgets('"My Bar sort" is hidden on the Cocktails tab', (tester) async {
    await pumpScreen(tester);
    // Cocktails is the default (index 0) tab.
    final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffold.openEndDrawer();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('My Bar sort'), findsNothing);
  });

  testWidgets('"My Bar sort" is hidden on the House tab', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('House'));
    await tester.pumpAndSettle();

    final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffold.openEndDrawer();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('My Bar sort'), findsNothing);
  });

  testWidgets('House tab has its own working sort', (tester) async {
    await db.into(db.recipes).insert(RecipesCompanion.insert(
          supabaseId: const Value('syrup_b'),
          name: const Value('B Mix'),
          recipeType: const Value('syrup'),
        ));
    await db.into(db.recipes).insert(RecipesCompanion.insert(
          supabaseId: const Value('syrup_a'),
          name: const Value('A Mix'),
          recipeType: const Value('syrup'),
        ));

    await pumpScreen(tester);
    await tester.tap(find.text('House'));
    await tester.pumpAndSettle();

    // Default ascending: A Mix before B Mix.
    var aOffset = tester.getTopLeft(find.text('A Mix')).dy;
    var bOffset = tester.getTopLeft(find.text('B Mix')).dy;
    expect(aOffset, lessThan(bOffset));

    await tester.tap(find.text('Name A–Z'));
    await tester.pumpAndSettle();

    expect(find.text('Name Z–A'), findsOneWidget,
        reason: 'House tab sort toggle must actually flip and re-sort (#136)');
    aOffset = tester.getTopLeft(find.text('A Mix')).dy;
    bOffset = tester.getTopLeft(find.text('B Mix')).dy;
    expect(bOffset, lessThan(aOffset));
  });
}
