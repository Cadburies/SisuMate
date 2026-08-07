import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/shopping/customs_check_dialog.dart';
import 'package:sisu_mate/ui/shopping/shopping_screen.dart';

import 'test_helpers/platform_mocks.dart';

/// #228: customs/provisioning import-restriction check — reached via a
/// shopping item's AI badge (#208 separation from the swipe-revealed
/// Complete/Hide/Email actions), reasons only over pasted text (no live
/// search — that's #224's shape), and never claims to be an official
/// customs determination.
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
    // Origin group header is a collapsed ExpansionTile until tapped open.
    await tester.tap(find.text('Spares'));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('tapping a shopping item\'s AI badge opens the customs-check '
      'dialog', (tester) async {
    await pumpScreen(tester);

    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    await tester.tap(find.byIcon(Icons.auto_awesome));
    await tester.pumpAndSettle();

    expect(find.byType(CustomsCheckDialog), findsOneWidget);
    expect(find.text('Item(s) you\'re carrying'), findsOneWidget);
    expect(find.text('Check offline pack'), findsOneWidget);
  });

  testWidgets('offline pack flags drones without needing an AI key',
      (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.byIcon(Icons.auto_awesome));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextField, 'Item(s) you\'re carrying'),
        'DJI mini drone');
    await tester.tap(find.text('Check offline pack'));
    await tester.pump();

    expect(find.textContaining('Drones often restricted'), findsOneWidget);
  });
}
