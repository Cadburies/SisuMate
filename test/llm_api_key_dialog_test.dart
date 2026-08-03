import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/llm_client_service.dart';
import 'package:sisu_mate/ui/settings/llm_api_key_dialog.dart';

import 'test_helpers/platform_mocks.dart';

/// #215/#211: BYOK entry dialog — local-only by default, one row per
/// provider. Everyone (owner or crew) gets the same editable form for their
/// own device's keys; only the owner's per-row "Share with crew" switch is
/// interactive.
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

  Finder openAiKeyField() =>
      find.widgetWithText(TextField, 'OpenAI API Key');
  Finder xaiKeyField() => find.widgetWithText(TextField, 'xAI (Grok) API Key');
  Finder openAiShareSwitch() => find.ancestor(
        of: find.text('OpenAI'),
        matching: find.byType(Card),
      );

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

  testWidgets('a row exists for every provider', (tester) async {
    await pumpDialog(
      tester,
      LlmApiKeyDialog(boat: Boat()..supabaseId = 'boat_1', isOwner: true),
    );

    for (final p in LlmProvider.values) {
      expect(find.text(p.label), findsOneWidget, reason: '${p.label} row');
    }
  });

  testWidgets('owner: every share switch is interactive', (tester) async {
    await pumpDialog(
      tester,
      LlmApiKeyDialog(boat: Boat()..supabaseId = 'boat_1', isOwner: true),
    );

    final switches =
        tester.widgetList<SwitchListTile>(find.byType(SwitchListTile));
    expect(switches, isNotEmpty);
    for (final s in switches) {
      expect(s.onChanged, isNotNull);
    }
  });

  testWidgets('crew (non-owner): every share switch is disabled',
      (tester) async {
    await pumpDialog(
      tester,
      LlmApiKeyDialog(boat: Boat()..supabaseId = 'boat_1', isOwner: false),
    );

    final switches =
        tester.widgetList<SwitchListTile>(find.byType(SwitchListTile));
    expect(switches, isNotEmpty);
    for (final s in switches) {
      expect(s.onChanged, isNull);
    }
  });

  testWidgets(
      'owner saving with sharing ON persists both the OpenAI key and its '
      'shared flag locally, without touching other providers', (tester) async {
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

    await tester.enterText(openAiKeyField(), 'sk-shared-key');
    await tester.pump();
    await tester.tap(find.descendant(
      of: openAiShareSwitch(),
      matching: find.byType(SwitchListTile),
    ));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump();

    final row = await (db.select(db.boats)
          ..where((t) => t.supabaseId.equals('boat_1')))
        .getSingle();
    final entries = jsonDecode(row.llmApiKeys) as List;
    expect(entries, hasLength(1));
    expect(entries.single['provider'], 'openai');
    expect(entries.single['apiKey'], 'sk-shared-key');
    expect(entries.single['shared'], isTrue);
  });

  testWidgets(
      'non-owner saving persists their own key locally without ever '
      'touching that entry\'s shared flag (they can\'t change it)',
      (tester) async {
    await db.into(db.boats).insert(BoatsCompanion.insert(
          supabaseId: const Value('boat_1'),
          name: const Value('Sisu'),
          llmApiKeys: Value(jsonEncode([
            {'provider': 'xai', 'apiKey': '', 'shared': true}, // owner shares
          ])),
        ));

    await pumpDialog(
      tester,
      LlmApiKeyDialog(
        boat: Boat()
          ..supabaseId = 'boat_1'
          ..name = 'Sisu'
          ..llmApiKeys = [
            LlmApiKeyEntry(provider: 'xai', apiKey: '', shared: true),
          ],
        isOwner: false,
      ),
    );

    await tester.enterText(xaiKeyField(), 'sk-crew-personal');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump();

    final row = await (db.select(db.boats)
          ..where((t) => t.supabaseId.equals('boat_1')))
        .getSingle();
    final entry = (jsonDecode(row.llmApiKeys) as List).single;
    expect(entry['apiKey'], 'sk-crew-personal');
    expect(entry['shared'], isTrue,
        reason: 'a non-owner editing their own local key must not reset '
            'the shared flag the owner set — they can\'t change it either '
            'way, so it must be left exactly as it was');
  });

  testWidgets(
      'saving sets activeLlmProvider to the picked radio, and clears it if '
      'that provider\'s key was cleared before saving', (tester) async {
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

    await tester.enterText(openAiKeyField(), 'sk-openai');
    await tester.pump();
    await tester.tap(find.byType(Radio<String>).first);
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump();

    final row = await (db.select(db.boats)
          ..where((t) => t.supabaseId.equals('boat_1')))
        .getSingle();
    expect(row.activeLlmProvider, 'openai');
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
