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
import 'package:sisu_mate/ui/maintenance/warranty_check_dialog.dart';

import 'test_helpers/platform_mocks.dart';

/// #222: warranty/manual coverage assistant — reached via the maintenance
/// item's AI menu (#208 separation from Complete/Hide), reasons only over
/// pasted text (no OCR/document pipeline exists), and never claims to be a
/// legal/warranty determination.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  const groupId = 'grp_maint';
  const itemId = 'maint_bilge';

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

  Future<ProviderContainer> pumpScreen(WidgetTester tester,
      {String? llmApiKey, String? llmApiKeyProvider}) async {
    await db.into(db.boats).insert(BoatsCompanion.insert(
          supabaseId: const Value('boat_1'),
          name: const Value('Sisu'),
          llmApiKey: Value(llmApiKey),
          llmApiKeyProvider: Value(llmApiKeyProvider),
        ));
    await db.into(db.userSettingsTable).insert(
          UserSettingsTableCompanion.insert(
            id: const Value(1),
            activeBoatSupabaseId: const Value('boat_1'),
          ),
        );
    await db.into(db.checklistGroups).insert(ChecklistGroupsCompanion.insert(
          supabaseId: const Value(groupId),
          boatSupabaseId: const Value('boat_1'),
          appType: const Value('maintenance'),
          title: const Value('Engine Room'),
        ));
    await db.into(db.checklistItems).insert(ChecklistItemsCompanion.insert(
          supabaseId: const Value(itemId),
          boatSupabaseId: const Value('boat_1'),
          groupSupabaseId: const Value(groupId),
          title: const Value('Check bilge pump'),
          name: const Value('Check bilge pump'),
        ));

    final group = ChecklistGroup()
      ..supabaseId = groupId
      ..boatSupabaseId = 'boat_1'
      ..appType = 'maintenance'
      ..title = 'Engine Room';

    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(true)),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: MaintenanceItemsScreen(group: group)),
    ));
    await tester.pump();
    await tester.pump();
    return container;
  }

  Future<void> openWarrantyDialog(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.auto_awesome));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check warranty coverage'));
    await tester.pumpAndSettle();
  }

  testWidgets('picking "Check warranty coverage" from the AI menu opens the '
      'warranty dialog', (tester) async {
    await pumpScreen(tester);
    await openWarrantyDialog(tester);

    expect(find.byType(WarrantyCheckDialog), findsOneWidget);
    expect(find.text('What broke?'), findsOneWidget);
    expect(find.text('Manual / warranty excerpt'), findsOneWidget);
  });

  testWidgets('with no key configured, asking says so instead of silently '
      'failing', (tester) async {
    await pumpScreen(tester);
    await openWarrantyDialog(tester);

    await tester.enterText(
        find.widgetWithText(TextField, 'What broke?'),
        'Bilge pump float switch stopped cycling after 3 months');
    await tester.enterText(
        find.widgetWithText(TextField, 'Manual / warranty excerpt'),
        'Electrical components are warranted for 12 months from purchase.');
    await tester.tap(find.text('Ask'));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('No AI API key is configured'), findsOneWidget);
    expect(find.text('Go to Settings'), findsOneWidget);
  });
}
