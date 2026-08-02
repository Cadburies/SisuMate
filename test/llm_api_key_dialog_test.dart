import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/ui/settings/llm_api_key_dialog.dart';

import 'test_helpers/platform_mocks.dart';

/// #203: BYOK entry dialog — reminder text always present, owner form
/// persists via boatRepositoryProvider, non-owner view stays read-only.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  setUp(() {
    mockConnectivityChannel();
    mockPathProviderChannel();
    mockSharedPreferencesChannel();
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  Future<ProviderContainer> pumpDialog(
    WidgetTester tester,
    Widget dialog,
  ) async {
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: Scaffold(body: dialog)),
    ));
    await tester.pump();
    return container;
  }

  testWidgets('shows the online/validity/tokens reminder text', (tester) async {
    await pumpDialog(
      tester,
      LlmApiKeyDialog(boat: Boat()..supabaseId = 'boat_1'),
    );

    expect(find.textContaining('only work when the app is online'), findsOneWidget);
    expect(find.textContaining('never validates, meters, or bills'), findsOneWidget);
  });

  testWidgets('saving a key persists it to the boat via the repository',
      (tester) async {
    await db.into(db.boats).insert(BoatsCompanion.insert(
          supabaseId: const Value('boat_1'),
          name: const Value('Sisu'),
        ));

    await pumpDialog(
      tester,
      LlmApiKeyDialog(boat: Boat()
        ..supabaseId = 'boat_1'
        ..name = 'Sisu'),
    );

    await tester.enterText(find.byType(TextField), 'sk-new-key');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump();

    final row = await (db.select(db.boats)
          ..where((t) => t.supabaseId.equals('boat_1')))
        .getSingle();
    expect(row.llmApiKey, 'sk-new-key');
    expect(row.llmApiKeyProvider, 'openai');
  });

  testWidgets('read-only dialog shows configured state without an edit field',
      (tester) async {
    await pumpDialog(
      tester,
      LlmApiKeyReadOnlyDialog(
        boat: Boat()
          ..supabaseId = 'boat_1'
          ..llmApiKey = 'sk-owner-set'
          ..llmApiKeyProvider = 'xai',
      ),
    );

    expect(find.textContaining('configured for this boat by its owner'),
        findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Save'), findsNothing);
  });

  testWidgets('read-only dialog shows the not-configured state', (tester) async {
    await pumpDialog(
      tester,
      LlmApiKeyReadOnlyDialog(boat: Boat()..supabaseId = 'boat_1'),
    );

    expect(find.textContaining('No AI API key is configured'), findsOneWidget);
  });

  testWidgets('#15: editable dialog shows a usage summary', (tester) async {
    await pumpDialog(
      tester,
      LlmApiKeyDialog(boat: Boat()..supabaseId = 'boat_1'),
    );
    await tester.pump();

    expect(find.textContaining('No AI usage recorded on this device yet'),
        findsOneWidget);
  });
}
