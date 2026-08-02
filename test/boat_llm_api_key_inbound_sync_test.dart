import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/inbound_sync_applier.dart';

/// #215: the critical guarantee behind "local by default, opt-in sync" —
/// an inbound `boats` sync must never silently wipe a device's own local
/// (unshared) key just because the incoming row says `llmApiKeyShared:
/// false`. Only an *actively* shared incoming key gets adopted.
void main() {
  late AppDatabase db;
  late InboundSyncApplier applier;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    applier = InboundSyncApplier(db);
  });

  tearDown(() async => db.close());

  Map<String, dynamic> boatJson({
    required bool shared,
    String? key,
    String? provider,
  }) =>
      {
        'supabaseId': 'boat_1',
        'name': 'Sisu',
        'isBought': false,
        'isHidden': false,
        'isSynced': true,
        'lastModified': DateTime.now().toUtc().toIso8601String(),
        'llmApiKeyShared': shared,
        'llmApiKey': key,
        'llmApiKeyProvider': provider,
      };

  test('an incoming shared key is adopted into local storage', () async {
    await applier.applyRemote(
      'boats',
      boatJson(shared: true, key: 'sk-from-owner', provider: 'openai'),
    );

    final row = await (db.select(db.boats)
          ..where((t) => t.supabaseId.equals('boat_1')))
        .getSingle();
    expect(row.llmApiKey, 'sk-from-owner');
    expect(row.llmApiKeyProvider, 'openai');
    expect(row.llmApiKeyShared, isTrue);
  });

  test(
      'an inbound update with sharing OFF never touches an existing local '
      'key this device set independently', () async {
    // This device already has its own local (unshared) key.
    await db.into(db.boats).insert(BoatsCompanion.insert(
          supabaseId: const Value('boat_1'),
          name: const Value('Sisu'),
          llmApiKey: const Value('sk-my-own-local-key'),
          llmApiKeyProvider: const Value('xai'),
          llmApiKeyShared: const Value(false),
        ));

    // Someone else's boat update comes in — e.g. a name change — carrying
    // llmApiKeyShared: false (the wire-level default for an unshared boat).
    await applier.applyRemote(
      'boats',
      boatJson(shared: false, key: null, provider: null)
        ..['name'] = 'Sisu (renamed)',
    );

    final row = await (db.select(db.boats)
          ..where((t) => t.supabaseId.equals('boat_1')))
        .getSingle();
    expect(row.name, 'Sisu (renamed)', reason: 'other fields do sync');
    expect(row.llmApiKey, 'sk-my-own-local-key',
        reason: '#215: must survive an inbound sync of an unrelated field '
            'change — this is the core bug this design has to avoid');
    expect(row.llmApiKeyProvider, 'xai');
  });

  test(
      'once the owner starts sharing, a later sync with sharing OFF still '
      'does not clear it locally (last-known-shared value is preserved, '
      'not force-cleared)', () async {
    await applier.applyRemote(
      'boats',
      boatJson(shared: true, key: 'sk-shared', provider: 'openai'),
    );
    await applier.applyRemote(
      'boats',
      boatJson(shared: false, key: null, provider: null),
    );

    final row = await (db.select(db.boats)
          ..where((t) => t.supabaseId.equals('boat_1')))
        .getSingle();
    expect(row.llmApiKey, 'sk-shared',
        reason: 'Value.absent() on the unshared branch means "don\'t '
            'touch this column", not "clear it" — a deliberate choice so a '
            'stray off-flag can\'t nuke a key a device is actively using');
  });

  test('a fresh device (no existing row) with sharing OFF inserts null key',
      () async {
    await applier.applyRemote(
      'boats',
      boatJson(shared: false, key: null, provider: null),
    );

    final row = await (db.select(db.boats)
          ..where((t) => t.supabaseId.equals('boat_1')))
        .getSingle();
    expect(row.llmApiKey, isNull);
    expect(row.llmApiKeyShared, isFalse);
  });
}
