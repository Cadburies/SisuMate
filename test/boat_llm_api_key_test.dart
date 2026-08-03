import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/data/repositories/boat_repository_impl.dart';
import 'package:sisu_mate/models/models.dart';

import 'test_helpers/db_test_helper.dart';

/// #203/#215/#211: llmApiKeys (one entry per provider)/activeLlmProvider
/// round-trip through Drift (always full-fidelity, local storage) and
/// Boat.fromJson/toJson (the wire shape pushed to Supabase — local-only by
/// default, only actually carries a real key when that entry is shared;
/// activeLlmProvider never syncs at all — see its doc comment on `Boat`).
void main() {
  late AppDatabase db;
  late BoatRepositoryImpl repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = BoatRepositoryImpl(db, testSyncService());
  });

  tearDown(() async => db.close());

  test('llmApiKeys/activeLlmProvider persist through the repository (local, '
      'full fidelity regardless of sharing)', () async {
    await repo.addBoat(Boat()
      ..supabaseId = 'boat_1'
      ..name = 'Sisu'
      ..llmApiKeys = [LlmApiKeyEntry(provider: 'openai', apiKey: 'sk-test-123')]
      ..activeLlmProvider = 'openai');

    final saved = await repo.getBoatById('boat_1');
    expect(saved, isNotNull);
    expect(saved!.llmApiKeys, hasLength(1));
    expect(saved.llmApiKeys.first.provider, 'openai');
    expect(saved.llmApiKeys.first.apiKey, 'sk-test-123');
    expect(saved.llmApiKeys.first.shared, isFalse,
        reason: 'local-only by default');
    expect(saved.activeLlmProvider, 'openai');
  });

  test('llmApiKeys defaults to empty when never set', () async {
    await repo.addBoat(Boat()
      ..supabaseId = 'boat_2'
      ..name = 'No Key Boat');

    final saved = await repo.getBoatById('boat_2');
    expect(saved!.llmApiKeys, isEmpty);
    expect(saved.activeLlmProvider, isNull);
  });

  test('a boat can hold one entry per provider at once', () async {
    await repo.addBoat(Boat()
      ..supabaseId = 'boat_3a'
      ..name = 'Sisu'
      ..llmApiKeys = [
        LlmApiKeyEntry(provider: 'openai', apiKey: 'sk-openai'),
        LlmApiKeyEntry(provider: 'xai', apiKey: 'sk-xai'),
        LlmApiKeyEntry(provider: 'anthropic', apiKey: 'sk-ant'),
      ]
      ..activeLlmProvider = 'xai');

    final saved = await repo.getBoatById('boat_3a');
    expect(saved!.llmApiKeys, hasLength(3));
    expect(saved.activeLlmApiKeyEntry?.provider, 'xai');
    expect(saved.activeLlmApiKeyEntry?.apiKey, 'sk-xai');
  });

  test('update can clear a previously-set key', () async {
    final boat = Boat()
      ..supabaseId = 'boat_3'
      ..name = 'Sisu'
      ..llmApiKeys = [LlmApiKeyEntry(provider: 'xai', apiKey: 'sk-test-456')]
      ..activeLlmProvider = 'xai';
    await repo.addBoat(boat);

    boat
      ..llmApiKeys = []
      ..activeLlmProvider = null;
    await repo.updateBoat(boat);

    final saved = await repo.getBoatById('boat_3');
    expect(saved!.llmApiKeys, isEmpty);
    expect(saved.activeLlmProvider, isNull);
  });

  test(
      '#215: toJson excludes the real key when NOT shared (local-only '
      'default) even though it is set locally', () {
    final boat = Boat()
      ..supabaseId = 'boat_4'
      ..name = 'Sisu'
      ..llmApiKeys = [
        LlmApiKeyEntry(
            provider: 'openai', apiKey: 'sk-test-789', shared: false),
      ];

    final json = boat.toJson();
    final entries = json['llmApiKeys'] as List;
    expect(entries, hasLength(1));
    final entry = entries.first as Map;
    expect(entry['shared'], isFalse);
    expect(entry['apiKey'], isNull,
        reason: 'the wire payload must never carry an unshared key');
    expect(entry['provider'], 'openai');
  });

  test('#215: toJson includes the real key only when explicitly shared', () {
    final boat = Boat()
      ..supabaseId = 'boat_5'
      ..name = 'Sisu'
      ..llmApiKeys = [
        LlmApiKeyEntry(provider: 'xai', apiKey: 'sk-test-shared', shared: true),
      ];

    final json = boat.toJson();
    final entry = (json['llmApiKeys'] as List).first as Map;
    expect(entry['shared'], isTrue);
    expect(entry['apiKey'], 'sk-test-shared');
    expect(entry['provider'], 'xai');
  });

  test('toJson never includes activeLlmProvider — per-device only', () {
    final boat = Boat()
      ..supabaseId = 'boat_5b'
      ..name = 'Sisu'
      ..activeLlmProvider = 'xai';

    expect(boat.toJson().containsKey('activeLlmProvider'), isFalse);
  });

  test(
      '#215: fromJson still parses an incoming shared key faithfully — the '
      'selective-adopt guard lives in InboundSyncApplier, not here', () {
    final restored = Boat.fromJson({
      'supabaseId': 'boat_6',
      'name': 'Sisu',
      'isBought': false,
      'isHidden': false,
      'isSynced': true,
      'lastModified': DateTime.now().toUtc().toIso8601String(),
      'llmApiKeys': [
        {'provider': 'openai', 'apiKey': 'sk-from-owner', 'shared': true},
      ],
    });

    expect(restored.llmApiKeys.single.apiKey, 'sk-from-owner');
    expect(restored.llmApiKeys.single.shared, isTrue);
  });

  test('Boat.toString never includes the raw key, only the provider', () {
    final boat = Boat()
      ..supabaseId = 'boat_7'
      ..llmApiKeys = [
        LlmApiKeyEntry(
            provider: 'openai', apiKey: 'sk-super-secret-should-not-print'),
      ];

    expect(boat.toString(), isNot(contains('sk-super-secret-should-not-print')));
    expect(boat.toString(), contains('openai'));
  });
}
