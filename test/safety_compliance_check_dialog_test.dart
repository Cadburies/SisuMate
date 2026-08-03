import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/safety/safety_briefing_screen.dart';
import 'package:sisu_mate/ui/safety/safety_compliance_check_dialog.dart';

import 'test_helpers/platform_mocks.dart';

/// #226: safety-equipment compliance check — reached via the safety item's
/// AI badge (#208 separation from Complete/Hide), reasons only over pasted
/// text (no OCR/document pipeline exists), and never claims to be a
/// certified inspection.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  const groupId = 'grp_safety';
  const itemId = 'safety_liferaft';

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
          llmApiKeys: Value(llmApiKey == null || llmApiKeyProvider == null
              ? '[]'
              : jsonEncode([
                  {'provider': llmApiKeyProvider, 'apiKey': llmApiKey, 'shared': false},
                ])),
          activeLlmProvider: Value(llmApiKeyProvider),
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
          appType: const Value('safety'),
          title: const Value('Abandon Ship'),
        ));
    await db.into(db.checklistItems).insert(ChecklistItemsCompanion.insert(
          supabaseId: const Value(itemId),
          boatSupabaseId: const Value('boat_1'),
          groupSupabaseId: const Value(groupId),
          title: const Value('Check life raft'),
          name: const Value('Check life raft'),
        ));

    final group = ChecklistGroup()
      ..supabaseId = groupId
      ..boatSupabaseId = 'boat_1'
      ..appType = 'safety'
      ..title = 'Abandon Ship';

    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(true)),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: SafetyBriefingItemsScreen(group: group)),
    ));
    await tester.pump();
    await tester.pump();
    return container;
  }

  Future<void> openComplianceDialog(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.auto_awesome));
    await tester.pumpAndSettle();
  }

  testWidgets('tapping the AI badge opens the compliance-check dialog',
      (tester) async {
    await pumpScreen(tester);
    await openComplianceDialog(tester);

    expect(find.byType(SafetyComplianceCheckDialog), findsOneWidget);
    expect(find.text('Item & current state'), findsOneWidget);
    expect(find.text('Manual / certification excerpt'), findsOneWidget);
  });

  testWidgets('with no key configured, asking says so instead of silently '
      'failing', (tester) async {
    await pumpScreen(tester);
    await openComplianceDialog(tester);

    await tester.enterText(
        find.widgetWithText(TextField, 'Item & current state'),
        'Offshore life raft, last serviced 2023-01, tag looks intact');
    await tester.enterText(
        find.widgetWithText(TextField, 'Manual / certification excerpt'),
        'Life rafts must be serviced every 12 months from date of packing.');
    await tester.tap(find.text('Ask'));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('No AI API key is configured'), findsOneWidget);
    expect(find.text('Go to Settings'), findsOneWidget);
  });
}
