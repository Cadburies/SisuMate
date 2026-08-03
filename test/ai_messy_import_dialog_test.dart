import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/import_service.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/components/ai_messy_import_dialog.dart';
import 'package:sisu_mate/ui/components/import_export.dart';

import 'test_helpers/platform_mocks.dart';

/// #221: messy import parsing — the AI maps pasted text/CSV into the app's
/// import JSON envelope, and the result is run through the exact same
/// `ImportService.parse` validation a manual JSON paste would get, so a bad
/// AI response can't bypass it. Reached via each module's Import/Export
/// sheet, per #208 separation.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('stripJsonCodeFence', () {
    test('strips a ```json ... ``` fence', () {
      const fenced = '```json\n{"a": 1}\n```';
      expect(stripJsonCodeFence(fenced), '{"a": 1}');
    });

    test('strips a bare ``` fence with no language tag', () {
      const fenced = '```\n{"a": 1}\n```';
      expect(stripJsonCodeFence(fenced), '{"a": 1}');
    });

    test('leaves unfenced text untouched (aside from trimming)', () {
      expect(stripJsonCodeFence('  {"a": 1}  '), '{"a": 1}');
    });
  });

  group('AI output -> ImportService.parse pipeline', () {
    test('a well-formed AI response (fenced) parses into a correct batch',
        () {
      const aiResponse = '```json\n'
          '{"sisuMateImport": 1, "kind": "inventory", "items": '
          '[{"name": "Spare impeller", "quantity": 2, "unit": "pcs"}, '
          '{"name": "Fuel filters", "quantity": 5}]}\n'
          '```';
      final batch = ImportService.parse(stripJsonCodeFence(aiResponse));

      expect(batch.kind, ImportService.kindInventory);
      expect(batch.count, 2);
      expect(batch.inventoryItems.map((e) => e.name),
          containsAll(['Spare impeller', 'Fuel filters']));
    });

    test('garbage AI output (not JSON at all) is rejected by validation, '
        'not silently accepted', () {
      const garbage = 'Sorry, I can\'t help map that list.';
      expect(
        () => ImportService.parse(stripJsonCodeFence(garbage)),
        throwsA(isA<ImportException>()),
      );
    });

    test('AI output that is valid JSON but the wrong shape (missing '
        '"items") is still rejected', () {
      const wrongShape = '{"sisuMateImport": 1, "kind": "inventory"}';
      expect(
        () => ImportService.parse(stripJsonCodeFence(wrongShape)),
        throwsA(isA<ImportException>()),
      );
    });
  });

  group('AiMessyImportDialog', () {
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

    ModuleImportExport testIo() => ModuleImportExport(
          kind: ImportService.kindInventory,
          label: 'Inventory',
          fileBaseName: 'sisu_inventory',
          exportCurrent: () async => ImportService.sampleFor('inventory'),
          persist: (batch) async =>
              ImportPersistResult.allInserted(batch.count),
        );

    Future<ProviderContainer> pumpDialog(WidgetTester tester) async {
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

      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => AiMessyImportDialog(io: testIo()),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('shows a paste field mentioning the module label',
        (tester) async {
      await pumpDialog(tester);

      expect(find.byType(AiMessyImportDialog), findsOneWidget);
      expect(find.text('Paste your list'), findsOneWidget);
    });

    testWidgets('with no key configured, parsing says so instead of '
        'silently failing', (tester) async {
      await pumpDialog(tester);

      await tester.enterText(
          find.widgetWithText(TextField, 'Paste your list'),
          'impeller x2, fuel filters x5');
      await tester.tap(find.text('Parse with AI'));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('No AI API key is configured'), findsOneWidget);
      expect(find.text('Go to Settings'), findsOneWidget);
    });
  });
}
