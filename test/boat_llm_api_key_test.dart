import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/data/repositories/boat_repository_impl.dart';
import 'package:sisu_mate/models/models.dart';

import 'test_helpers/db_test_helper.dart';

/// #203/#215: llmApiKey/llmApiKeyProvider/llmApiKeyShared round-trip
/// through Drift (always full-fidelity, local storage) and
/// Boat.fromJson/toJson (the wire shape pushed to Supabase — local-only by
/// default, only actually carries the real key when llmApiKeyShared).
void main() {
  late AppDatabase db;
  late BoatRepositoryImpl repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = BoatRepositoryImpl(db, testSyncService());
  });

  tearDown(() async => db.close());

  test('llmApiKey/llmApiKeyProvider persist through the repository (local, '
      'full fidelity regardless of sharing)', () async {
    await repo.addBoat(Boat()
      ..supabaseId = 'boat_1'
      ..name = 'Sisu'
      ..llmApiKey = 'sk-test-123'
      ..llmApiKeyProvider = 'openai');

    final saved = await repo.getBoatById('boat_1');
    expect(saved, isNotNull);
    expect(saved!.llmApiKey, 'sk-test-123');
    expect(saved.llmApiKeyProvider, 'openai');
    expect(saved.llmApiKeyShared, isFalse, reason: 'local-only by default');
  });

  test('llmApiKey defaults to null when never set', () async {
    await repo.addBoat(Boat()
      ..supabaseId = 'boat_2'
      ..name = 'No Key Boat');

    final saved = await repo.getBoatById('boat_2');
    expect(saved!.llmApiKey, isNull);
    expect(saved.llmApiKeyProvider, isNull);
    expect(saved.llmApiKeyShared, isFalse);
  });

  test('update can clear a previously-set key', () async {
    final boat = Boat()
      ..supabaseId = 'boat_3'
      ..name = 'Sisu'
      ..llmApiKey = 'sk-test-456'
      ..llmApiKeyProvider = 'xai';
    await repo.addBoat(boat);

    boat
      ..llmApiKey = null
      ..llmApiKeyProvider = null;
    await repo.updateBoat(boat);

    final saved = await repo.getBoatById('boat_3');
    expect(saved!.llmApiKey, isNull);
    expect(saved.llmApiKeyProvider, isNull);
  });

  test(
      '#215: toJson excludes the real key when NOT shared (local-only '
      'default) even though it is set locally', () {
    final boat = Boat()
      ..supabaseId = 'boat_4'
      ..name = 'Sisu'
      ..llmApiKey = 'sk-test-789'
      ..llmApiKeyProvider = 'openai'
      ..llmApiKeyShared = false;

    final json = boat.toJson();
    expect(json['llmApiKeyShared'], isFalse);
    expect(json['llmApiKey'], isNull,
        reason: 'the wire payload must never carry an unshared key');
    expect(json['llmApiKeyProvider'], isNull);
  });

  test('#215: toJson includes the real key only when explicitly shared', () {
    final boat = Boat()
      ..supabaseId = 'boat_5'
      ..name = 'Sisu'
      ..llmApiKey = 'sk-test-shared'
      ..llmApiKeyProvider = 'xai'
      ..llmApiKeyShared = true;

    final json = boat.toJson();
    expect(json['llmApiKeyShared'], isTrue);
    expect(json['llmApiKey'], 'sk-test-shared');
    expect(json['llmApiKeyProvider'], 'xai');
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
      'llmApiKey': 'sk-from-owner',
      'llmApiKeyProvider': 'openai',
      'llmApiKeyShared': true,
    });

    expect(restored.llmApiKey, 'sk-from-owner');
    expect(restored.llmApiKeyShared, isTrue);
  });

  test('Boat.toString never includes the raw key, only the provider',
      () {
    final boat = Boat()
      ..supabaseId = 'boat_7'
      ..llmApiKey = 'sk-super-secret-should-not-print'
      ..llmApiKeyProvider = 'openai';

    expect(boat.toString(), isNot(contains('sk-super-secret-should-not-print')));
    expect(boat.toString(), contains('openai'));
  });
}
