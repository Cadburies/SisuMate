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

/// #215: BYOK entry dialog — local-only by default. Everyone (owner or
/// crew) gets the same editable form for their own device's key; only the
/// owner's "Share with crew" switch is interactive.
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
    // No isProProvider/RevenueCat override — real entitlement lookups fail
    // gracefully offline and resolve to Free, so _syncAllowed() is false and
    // SyncService never starts its periodic queue monitor. syncServiceProvider
    // is left to construct normally (against the overridden db below) so
    // queueOutgoingChange's writes land in a db.syncOutboxItems this test can
    // actually inspect — a separately-instantiated SyncService (e.g.
    // testSyncService()) would write into its own isolated db instead.
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

  testWidgets('shows the local-only/online/validity/tokens reminder text',
      (tester) async {
    await pumpDialog(
      tester,
      LlmApiKeyDialog(boat: Boat()..supabaseId = 'boat_1', isOwner: true),
    );

    expect(find.textContaining('only work when the app is online'), findsOneWidget);
    expect(find.textContaining('never validates, meters, or bills'), findsOneWidget);
    expect(find.textContaining('Stored only on this device by default'),
        findsOneWidget);
  });

  testWidgets('owner: the share switch is interactive', (tester) async {
    await pumpDialog(
      tester,
      LlmApiKeyDialog(boat: Boat()..supabaseId = 'boat_1', isOwner: true),
    );

    final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(tile.onChanged, isNotNull);
  });

  testWidgets('crew (non-owner): the share switch is disabled', (tester) async {
    await pumpDialog(
      tester,
      LlmApiKeyDialog(boat: Boat()..supabaseId = 'boat_1', isOwner: false),
    );

    final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(tile.onChanged, isNull);
  });

  testWidgets(
      'owner saving with sharing ON persists both the key and the shared '
      'flag locally', (tester) async {
    await db.into(db.boats).insert(BoatsCompanion.insert(
          supabaseId: const Value('boat_1'),
          name: const Value('Sisu'),
        ));

    await pumpDialog(
      tester,
      LlmApiKeyDialog(
        boat: Boat()
          ..supabaseId = 'boat_1'
          ..name = 'Sisu',
        isOwner: true,
      ),
    );

    await tester.enterText(find.byType(TextField), 'sk-shared-key');
    await tester.pump();
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump();

    final row = await (db.select(db.boats)
          ..where((t) => t.supabaseId.equals('boat_1')))
        .getSingle();
    expect(row.llmApiKey, 'sk-shared-key');
    expect(row.llmApiKeyShared, isTrue);
  });

  testWidgets(
      'non-owner saving persists their own key locally without ever '
      'touching llmApiKeyShared (they can\'t change it)', (tester) async {
    await db.into(db.boats).insert(BoatsCompanion.insert(
          supabaseId: const Value('boat_1'),
          name: const Value('Sisu'),
          llmApiKeyShared: const Value(true), // owner already shares
        ));

    await pumpDialog(
      tester,
      LlmApiKeyDialog(
        boat: Boat()
          ..supabaseId = 'boat_1'
          ..name = 'Sisu'
          ..llmApiKeyShared = true,
        isOwner: false,
      ),
    );

    await tester.enterText(find.byType(TextField), 'sk-crew-personal');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump();

    final row = await (db.select(db.boats)
          ..where((t) => t.supabaseId.equals('boat_1')))
        .getSingle();
    expect(row.llmApiKey, 'sk-crew-personal');
    expect(row.llmApiKeyShared, isTrue,
        reason: 'a non-owner editing their own local key must not reset '
            'the shared flag the owner set — they can\'t change it either '
            'way, so it must be left exactly as it was');
  });

  testWidgets('#15: dialog shows a usage summary', (tester) async {
    await pumpDialog(
      tester,
      LlmApiKeyDialog(boat: Boat()..supabaseId = 'boat_1', isOwner: true),
    );
    await tester.pump();

    expect(find.textContaining('No AI usage recorded on this device yet'),
        findsOneWidget);
  });
}
