import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/data/repositories/boat_repository_impl.dart';
import 'package:sisu_mate/models/models.dart';

import 'test_helpers/db_test_helper.dart';

/// #203: llmApiKey/llmApiKeyProvider round-trip through Drift and
/// Boat.fromJson/toJson (the wire shape pushed to Supabase).
void main() {
  late AppDatabase db;
  late BoatRepositoryImpl repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = BoatRepositoryImpl(db, testSyncService());
  });

  tearDown(() async => db.close());

  test('llmApiKey/llmApiKeyProvider persist through the repository', () async {
    await repo.addBoat(Boat()
      ..supabaseId = 'boat_1'
      ..name = 'Sisu'
      ..llmApiKey = 'sk-test-123'
      ..llmApiKeyProvider = 'openai');

    final saved = await repo.getBoatById('boat_1');
    expect(saved, isNotNull);
    expect(saved!.llmApiKey, 'sk-test-123');
    expect(saved.llmApiKeyProvider, 'openai');
  });

  test('llmApiKey defaults to null when never set', () async {
    await repo.addBoat(Boat()
      ..supabaseId = 'boat_2'
      ..name = 'No Key Boat');

    final saved = await repo.getBoatById('boat_2');
    expect(saved!.llmApiKey, isNull);
    expect(saved.llmApiKeyProvider, isNull);
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

  test('Boat.fromJson/toJson round-trips the key fields', () {
    final boat = Boat()
      ..supabaseId = 'boat_4'
      ..name = 'Sisu'
      ..llmApiKey = 'sk-test-789'
      ..llmApiKeyProvider = 'openai';

    final json = boat.toJson();
    expect(json['llmApiKey'], 'sk-test-789');
    expect(json['llmApiKeyProvider'], 'openai');

    final restored = Boat.fromJson(json);
    expect(restored, boat);
  });

  test('Boat.toString never includes the raw key, only the provider',
      () {
    final boat = Boat()
      ..supabaseId = 'boat_5'
      ..llmApiKey = 'sk-super-secret-should-not-print'
      ..llmApiKeyProvider = 'openai';

    expect(boat.toString(), isNot(contains('sk-super-secret-should-not-print')));
    expect(boat.toString(), contains('openai'));
  });
}
