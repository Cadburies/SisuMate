import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/maintenance/maintenance_items_screen.dart';

import 'test_helpers/platform_mocks.dart';

/// #339 TEST6: Maintenance swipe → Shopping uses the real shopping repo
/// (ensurePacksInShopping), with a confirm dialog so part numbers are not
/// silently dropped.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  const groupId = 'grp_eng';
  const itemId = 'maint_oil';

  final group = ChecklistGroup()
    ..supabaseId = groupId
    ..boatSupabaseId = 'boat_1'
    ..appType = 'maintenance'
    ..title = 'Engine Room'
    ..isBundled = false;

  setUp(() {
    mockConnectivityChannel();
    mockPathProviderChannel();
    mockSharedPreferencesChannel();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    RevenueCatService.debugProOverrideForTests = true;
  });

  tearDown(() async {
    RevenueCatService.debugProOverrideForTests = null;
    await db.close();
  });

  Future<void> seed() async {
    await db.into(db.checklistGroups).insert(
          ChecklistGroupsCompanion.insert(
            supabaseId: const Value(groupId),
            boatSupabaseId: const Value('boat_1'),
            appType: const Value('maintenance'),
            title: const Value('Engine Room'),
          ),
        );
    await db.into(db.checklistItems).insert(
          ChecklistItemsCompanion.insert(
            supabaseId: const Value(itemId),
            boatSupabaseId: const Value('boat_1'),
            groupSupabaseId: const Value(groupId),
            title: const Value('250-hour engine service'),
            name: const Value('250-hour engine service'),
            description: const Value('Yanmar 129470-55710 oil filter'),
          ),
        );
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(true)),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: MaintenanceItemsScreen(group: group)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> swipeAndTapShopping(WidgetTester tester) async {
    final title = find.text('250-hour engine service');
    expect(title, findsOneWidget);
    await tester.drag(title, const Offset(400, 0));
    await tester.pumpAndSettle();
    final shopping = find.text('Shopping');
    expect(shopping, findsOneWidget);
    await tester.tap(shopping);
    await tester.pumpAndSettle();
  }

  testWidgets(
      'swipe Shopping on a maintenance item adds a shopping line via '
      'ensurePacksInShopping, keeping description as notes', (tester) async {
    await seed();
    await pumpScreen(tester);
    await swipeAndTapShopping(tester);

    expect(find.text('Add to shopping'), findsOneWidget);
    expect(find.text('Yanmar 129470-55710 oil filter'), findsWidgets);

    final field = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    expect(field, findsOneWidget);
    await tester.enterText(field, 'Yanmar 129470-55710');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
    await tester.pumpAndSettle();

    final rows = await db.select(db.shoppingItems).get();
    expect(rows, hasLength(1));
    expect(rows.single.name, 'Yanmar 129470-55710');
    expect(rows.single.origin, 'maintenance');
    expect(rows.single.notes, 'Yanmar 129470-55710 oil filter');
    expect(rows.single.isBought, isFalse);
  });
}
