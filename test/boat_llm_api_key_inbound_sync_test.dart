import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/inbound_sync_applier.dart';

/// #215/#211: the critical guarantee behind "local by default, opt-in sync"
/// — an inbound `boats` sync must never silently wipe a device's own local
/// (unshared) key just because the incoming row doesn't mention that
/// provider (or mentions it with shared: false). Only an *actively shared*
/// incoming entry is adopted, now per provider entry instead of per-boat.
void main() {
  late AppDatabase db;
  late InboundSyncApplier applier;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    applier = InboundSyncApplier(db);
  });

  tearDown(() async => db.close());

  Map<String, dynamic> boatJson({
    List<Map<String, dynamic>> llmApiKeys = const [],
  }) =>
      {
        'supabaseId': 'boat_1',
        'name': 'Sisu',
        'isBought': false,
        'isHidden': false,
        'isSynced': true,
        'lastModified': DateTime.now().toUtc().toIso8601String(),
        'llmApiKeys': llmApiKeys,
      };

  List<Map<String, dynamic>> storedEntries(String llmApiKeysJson) =>
      (jsonDecode(llmApiKeysJson) as List).cast<Map<String, dynamic>>();

  test('an incoming shared key is adopted into local storage', () async {
    await applier.applyRemote(
      'boats',
      boatJson(llmApiKeys: [
        {'provider': 'openai', 'apiKey': 'sk-from-owner', 'shared': true},
      ]),
    );

    final row = await (db.select(db.boats)
          ..where((t) => t.supabaseId.equals('boat_1')))
        .getSingle();
    final entries = storedEntries(row.llmApiKeys);
    expect(entries, hasLength(1));
    expect(entries.first['provider'], 'openai');
    expect(entries.first['apiKey'], 'sk-from-owner');
    expect(entries.first['shared'], isTrue);
  });

  test(
      'an inbound update that never mentions this provider never touches an '
      'existing local key this device set independently', () async {
    // This device already has its own local (unshared) key.
    await db.into(db.boats).insert(BoatsCompanion.insert(
          supabaseId: const Value('boat_1'),
          name: const Value('Sisu'),
          llmApiKeys: Value(jsonEncode([
            {'provider': 'xai', 'apiKey': 'sk-my-own-local-key', 'shared': false},
          ])),
        ));

    // Someone else's boat update comes in — e.g. a name change — carrying
    // no llmApiKeys at all (the wire-level shape for "nothing shared").
    await applier.applyRemote(
      'boats',
      boatJson()..['name'] = 'Sisu (renamed)',
    );

    final row = await (db.select(db.boats)
          ..where((t) => t.supabaseId.equals('boat_1')))
        .getSingle();
    expect(row.name, 'Sisu (renamed)', reason: 'other fields do sync');
    final entries = storedEntries(row.llmApiKeys);
    expect(entries, hasLength(1),
        reason: '#215: must survive an inbound sync of an unrelated field '
            'change — this is the core bug this design has to avoid');
    expect(entries.first['apiKey'], 'sk-my-own-local-key');
    expect(entries.first['provider'], 'xai');
  });

  test(
      'once the owner starts sharing, a later sync that omits the provider '
      'still does not clear it locally (last-known-shared value is '
      'preserved, not force-cleared)', () async {
    await applier.applyRemote(
      'boats',
      boatJson(llmApiKeys: [
        {'provider': 'openai', 'apiKey': 'sk-shared', 'shared': true},
      ]),
    );
    await applier.applyRemote('boats', boatJson());

    final row = await (db.select(db.boats)
          ..where((t) => t.supabaseId.equals('boat_1')))
        .getSingle();
    final entries = storedEntries(row.llmApiKeys);
    expect(entries.single['apiKey'], 'sk-shared',
        reason: 'an incoming list that omits a provider means "don\'t '
            'touch this entry", not "clear it" — a deliberate choice so a '
            'stray unshared sync can\'t nuke a key a device is actively '
            'using');
  });

  test('a fresh device (no existing row) with nothing shared inserts an '
      'empty key list', () async {
    await applier.applyRemote('boats', boatJson());

    final row = await (db.select(db.boats)
          ..where((t) => t.supabaseId.equals('boat_1')))
        .getSingle();
    expect(storedEntries(row.llmApiKeys), isEmpty);
  });

  test('a shared entry for one provider does not disturb a separately '
      'shared entry for another provider', () async {
    await applier.applyRemote(
      'boats',
      boatJson(llmApiKeys: [
        {'provider': 'openai', 'apiKey': 'sk-openai', 'shared': true},
      ]),
    );
    await applier.applyRemote(
      'boats',
      boatJson(llmApiKeys: [
        {'provider': 'xai', 'apiKey': 'sk-xai', 'shared': true},
      ]),
    );

    final row = await (db.select(db.boats)
          ..where((t) => t.supabaseId.equals('boat_1')))
        .getSingle();
    final entries = storedEntries(row.llmApiKeys);
    expect(entries, hasLength(2));
    expect(entries.firstWhere((e) => e['provider'] == 'openai')['apiKey'],
        'sk-openai');
    expect(entries.firstWhere((e) => e['provider'] == 'xai')['apiKey'],
        'sk-xai');
  });
}
