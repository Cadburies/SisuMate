import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/crew/crew_screen.dart';
import 'package:sisu_mate/ui/crew/travel_safety_dialog.dart';

import 'test_helpers/platform_mocks.dart';

/// #224 (built on #223's grounded search): the crew-screen AI badge is
/// distinct from the offline add/share/import actions (#208), and — since
/// this feature must never silently degrade to an ungrounded guess — an
/// unsupported provider (or no key at all) says so clearly rather than
/// answering anyway.
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

    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(true)),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: CrewScreen()),
    ));
    await tester.pump();
    await tester.pump();
    return container;
  }

  testWidgets('the AI badge renders distinct from share/import icons',
      (tester) async {
    await pumpScreen(tester);

    expect(find.byIcon(Icons.auto_awesome), findsOneWidget,
        reason: '#208: AI entry point must have its own icon, not reuse '
            'the offline share/import actions');
  });

  testWidgets('tapping the AI badge opens the travel safety dialog',
      (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byIcon(Icons.auto_awesome));
    await tester.pump();

    expect(find.byType(TravelSafetyDialog), findsOneWidget);
    expect(find.text('Destination country'), findsOneWidget);
    expect(
        find.textContaining('Nationality only'), findsOneWidget,
        reason: 'must warn against typing passport details even though '
            'this is a free-text field');
  });

  testWidgets('with no key configured, asking says so instead of silently '
      'answering ungrounded', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byIcon(Icons.auto_awesome));
    await tester.pump();
    await tester.enterText(
        find.widgetWithText(TextField, 'Destination country'), 'Taiwan');
    await tester.enterText(
        find.widgetWithText(
            TextField, 'Crew nationalities (comma-separated)'),
        'British');
    await tester.tap(find.text('Ask'));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('No AI API key is configured'), findsOneWidget);
    expect(find.text('Go to Settings'), findsOneWidget);
  });

  testWidgets(
      'with a provider that doesn\'t support grounded search, asking says '
      'so instead of answering with a plain (possibly stale) completion',
      (tester) async {
    await pumpScreen(tester,
        llmApiKey: 'sk-test', llmApiKeyProvider: 'openai');

    await tester.tap(find.byIcon(Icons.auto_awesome));
    await tester.pump();
    await tester.enterText(
        find.widgetWithText(TextField, 'Destination country'), 'Taiwan');
    await tester.enterText(
        find.widgetWithText(
            TextField, 'Crew nationalities (comma-separated)'),
        'British');
    await tester.tap(find.text('Ask'));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('doesn\'t support live web/X search'),
        findsOneWidget);
    expect(find.text('Go to Settings'), findsOneWidget);
  });
}
