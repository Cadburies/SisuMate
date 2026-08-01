import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/shopping/shopping_screen.dart';

import 'test_helpers/platform_mocks.dart';

/// TEST6: first "real screen + live provider tree + real (in-memory) Drift"
/// integration test in this repo. Every other widget test pumps a dialog in
/// isolation or overrides the terminal provider directly (see
/// conflict_resolution_screen_test.dart's own comment on why) — this instead
/// backs `appDatabaseProvider` with a genuine in-memory database and lets the
/// full Repository -> Provider -> ConsumerWidget stack run for real, same as
/// the app does at runtime. Shopping was picked over Fuel: purest deps,
/// already has dialog-level coverage, and (per the parallel-lane plan) Fuel
/// is Grok's territory for SUG6/SUG7 follow-ups.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  setUp(() {
    mockConnectivityChannel();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // Keeps SyncService's Free/offline check (inside ShoppingRepositoryImpl's
    // writes) from touching a real RevenueCat/Supabase platform channel —
    // established seam (TEST1b), honored only under FLUTTER_TEST.
    RevenueCatService.debugProOverrideForTests = false;
  });

  tearDown(() async {
    RevenueCatService.debugProOverrideForTests = null;
    await db.close();
  });

  Future<void> seedCategoryAndItem({
    required String catId,
    required String catName,
    required String itemName,
  }) async {
    await db.into(db.shoppingCategories).insert(
          ShoppingCategoriesCompanion.insert(
            supabaseId: Value(catId),
            name: Value(catName),
          ),
        );
    await db.into(db.shoppingItems).insert(
          ShoppingItemsCompanion.insert(
            supabaseId: Value('${catId}_item'),
            categorySupabaseId: Value(catId),
            name: Value(itemName),
          ),
        );
  }

  Future<ProviderContainer> pumpShopping(
    WidgetTester tester, {
    bool isPro = true,
  }) async {
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(isPro)),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ShoppingScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
    return container;
  }

  testWidgets(
      'a row seeded straight into Drift renders on screen through the real '
      'repository + provider stack', (tester) async {
    await seedCategoryAndItem(
      catId: 'cat_spares',
      catName: 'Spares',
      itemName: 'Fenders',
    );
    await pumpShopping(tester);

    // Origin group header renders from a real watchCategories() + item
    // stream join, not a fake.
    expect(find.text('Spares'), findsOneWidget);

    // Items are nested under a collapsed ExpansionTile until tapped open.
    await tester.tap(find.text('Spares'));
    await tester.pumpAndSettle();
    expect(find.text('Fenders'), findsOneWidget);
  });

  testWidgets(
      'adding an item through the real Add dialog reaches Drift via '
      'ShoppingRepositoryImpl.addItem — not just local widget state',
      (tester) async {
    // The Add dialog hardcodes new items onto category id 'cat-misc' (a
    // known UI quirk, see its own code comment) and defaults the Origin
    // dropdown to 'spares' — seed under that same id/origin so the new item
    // lands in the same on-screen group as the pre-existing one.
    await seedCategoryAndItem(
      catId: 'cat-misc',
      catName: 'Spares',
      itemName: 'Existing item',
    );
    await pumpShopping(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextField, 'Item Name'), 'Spare Impeller');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Item'));
    await tester.pumpAndSettle();

    // The live screen picked up the write via its Stream provider.
    await tester.tap(find.text('Spares'));
    await tester.pumpAndSettle();
    expect(find.text('Spare Impeller'), findsOneWidget);

    // And the row is genuinely persisted — read it back straight from Drift,
    // independent of whatever the widget tree currently shows.
    final rows = await db.select(db.shoppingItems).get();
    expect(rows.map((r) => r.name), contains('Spare Impeller'));
    final saved = rows.firstWhere((r) => r.name == 'Spare Impeller');
    expect(saved.categorySupabaseId, 'cat-misc');
    expect(saved.origin, 'spares');
  });

  testWidgets('Free tier cannot add items — FAB opens the paywall, not the '
      'dialog, and nothing reaches Drift', (tester) async {
    await pumpShopping(tester, isPro: false);

    // The FAB always shows the same "+" icon; gating happens inside its
    // onPressed (Pro check), not via a swapped icon.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Add Shopping Item'), findsNothing);
    expect(find.text('Sisu Mate Pro Required'), findsOneWidget);
    expect(await db.select(db.shoppingItems).get(), isEmpty);
  });
}
