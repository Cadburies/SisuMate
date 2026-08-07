import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/shopping/customs_check_dialog.dart';
import 'package:sisu_mate/ui/shopping/shopping_item_ai_dialog.dart';
import 'package:sisu_mate/ui/shopping/shopping_screen.dart';

import 'test_helpers/platform_mocks.dart';

/// #228 / #317: per-item AI badge → shopping guide (prefilled); list customs
/// on the title bar. Offline-first; never claims official customs advice.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  setUp(() {
    mockConnectivityChannel();
    mockPathProviderChannel();
    mockSharedPreferencesChannel();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    RevenueCatService.debugProOverrideForTests = false;
  });

  tearDown(() async {
    RevenueCatService.debugProOverrideForTests = null;
    await db.close();
  });

  Future<ProviderContainer> pumpScreen(WidgetTester tester) async {
    await db.into(db.boats).insert(BoatsCompanion.insert(
          supabaseId: const Value('boat_1'),
          name: const Value('Sisu'),
          llmApiKeys: const Value('[]'),
        ));
    await db.into(db.userSettingsTable).insert(
          UserSettingsTableCompanion.insert(
            id: const Value(1),
            activeBoatSupabaseId: const Value('boat_1'),
          ),
        );
    await db.into(db.shoppingCategories).insert(
          ShoppingCategoriesCompanion.insert(
            supabaseId: const Value('cat_spares'),
            name: const Value('Spares'),
          ),
        );
    await db.into(db.shoppingItems).insert(
          ShoppingItemsCompanion.insert(
            supabaseId: const Value('cat_spares_item'),
            categorySupabaseId: const Value('cat_spares'),
            name: const Value('Duty-free rum'),
            origin: const Value('bar'),
          ),
        );

    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(true)),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ShoppingScreen()),
    ));
    await tester.pump();
    await tester.pump();
    // Origin groups are ExpansionTiles (header = capitalized origin).
    final originHeader = find.text('Bar');
    if (originHeader.evaluate().isNotEmpty) {
      await tester.tap(originHeader);
    } else {
      final tiles = find.byType(ExpansionTile);
      if (tiles.evaluate().isNotEmpty) {
        await tester.tap(tiles.first);
      }
    }
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('#317 per-item AI badge opens prefilled shopping guide',
      (tester) async {
    await pumpScreen(tester);

    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    await tester.tap(find.byIcon(Icons.auto_awesome));
    await tester.pumpAndSettle();

    expect(find.byType(ShoppingItemAiDialog), findsOneWidget);
    expect(find.byType(CustomsCheckDialog), findsNothing);
    expect(find.textContaining('Duty-free rum'), findsWidgets);
    expect(find.textContaining('Offline shopping guide'), findsOneWidget);
    expect(find.text('Improve with AI (online)'), findsOneWidget);
    // Alcohol customs pack should auto-appear offline for rum.
    expect(find.textContaining('Alcohol quantities'), findsOneWidget);
  });

  testWidgets('#317 title-bar opens list customs with prefilled names',
      (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('Customs check (list)'));
    await tester.pumpAndSettle();

    expect(find.byType(CustomsCheckDialog), findsOneWidget);
    expect(find.text('Item(s) you\'re carrying'), findsOneWidget);
    // Prefill should include the visible item name.
    expect(find.textContaining('Duty-free rum'), findsWidgets);
    expect(find.textContaining('Alcohol'), findsWidgets);
  });

  testWidgets('list customs offline pack flags drones without an AI key',
      (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.byTooltip('Customs check (list)'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextField, 'Item(s) you\'re carrying'),
        'DJI mini drone');
    await tester.tap(find.text('Check offline pack'));
    await tester.pump();

    expect(find.textContaining('Drones often restricted'), findsOneWidget);
  });
}
