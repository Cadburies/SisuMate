import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/logbook/ai_log_entry_parse_dialog.dart';

import 'test_helpers/platform_mocks.dart';

/// #220 acceptance: well-formed/partial/malformed LLM JSON responses must
/// all degrade gracefully (missing fields stay blank, no crash). Tested as
/// a plain unit test against the extracted pure function — the dialog
/// widget tests below separately cover the no-key fallback (#18's pattern).
void main() {
  group('parseAiLogEntryResponse', () {
    test('well-formed JSON maps every field', () {
      final draft = parseAiLogEntryResponse(
          '{"weather": "Sunny", "windSpeedKt": 12, "windDir": "SW", '
          '"notes": "saw dolphins"}');

      expect(draft.weather, 'Sunny');
      expect(draft.windSpeedKt, 12);
      expect(draft.windDir, 'SW');
      expect(draft.notes, 'saw dolphins');
    });

    test('partial JSON leaves missing fields null instead of crashing', () {
      final draft =
          parseAiLogEntryResponse('{"notes": "engine ran rough at first"}');

      expect(draft.notes, 'engine ran rough at first');
      expect(draft.weather, isNull);
      expect(draft.windSpeedKt, isNull);
      expect(draft.windDir, isNull);
    });

    test('malformed (non-JSON) text returns an empty draft, not a crash', () {
      final draft = parseAiLogEntryResponse('Sorry, I cannot help with that.');

      expect(draft.notes, isNull);
      expect(draft.weather, isNull);
      expect(draft.windSpeedKt, isNull);
      expect(draft.windDir, isNull);
    });

    test('a JSON array (valid JSON, wrong shape) returns an empty draft, '
        'not a crash', () {
      final draft = parseAiLogEntryResponse('["Sunny", 12]');

      expect(draft.weather, isNull);
      expect(draft.windSpeedKt, isNull);
    });

    test('strips a markdown code fence some providers wrap JSON in', () {
      final draft = parseAiLogEntryResponse(
          '```json\n{"weather": "Overcast", "windDir": "NE"}\n```');

      expect(draft.weather, 'Overcast');
      expect(draft.windDir, 'NE');
    });

    test('explicit JSON null and empty-string fields both stay null, not '
        'an empty string', () {
      final draft = parseAiLogEntryResponse(
          '{"weather": null, "windDir": "", "notes": "   "}');

      expect(draft.weather, isNull);
      expect(draft.windDir, isNull);
      expect(draft.notes, isNull);
    });

    test('a non-numeric windSpeedKt value is ignored rather than throwing',
        () {
      final draft =
          parseAiLogEntryResponse('{"windSpeedKt": "about twelve"}');

      expect(draft.windSpeedKt, isNull);
    });
  });

  group('AiLogEntryParseDialog', () {
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

    Future<void> pumpDialog(WidgetTester tester) async {
      await db.into(db.boats).insert(BoatsCompanion.insert(
            supabaseId: const Value('boat_1'),
            name: const Value('Sisu'),
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
        child: const MaterialApp(
          home: Scaffold(body: AiLogEntryParseDialog()),
        ),
      ));
      await tester.pump();
    }

    testWidgets('shows a text box first, not a blocking form',
        (tester) async {
      await pumpDialog(tester);

      expect(find.text('AI: Parse Log Entry'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Parse'), findsOneWidget);
    });

    testWidgets(
        'with no key configured, parsing says so instead of silently '
        'failing', (tester) async {
      await pumpDialog(tester);

      await tester.enterText(find.byType(TextField), 'calm day, no issues');
      await tester.tap(find.text('Parse'));
      await tester.pump();
      await tester.pump();

      expect(
          find.textContaining('No AI API key is configured'), findsOneWidget);
      expect(find.text('Go to Settings'), findsOneWidget);
    });
  });
}
