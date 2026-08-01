import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/wire_prefix.dart';

void main() {
  const guid = 'boat-guid-123';

  group('WirePrefix.encode', () {
    test('prefixes supabaseId + parent refs, leaves boatSupabaseId alone', () {
      final out = WirePrefix.encode('checklist_items', {
        'supabaseId': 'dailyEngine_oil',
        'groupSupabaseId': 'dailyEngine',
        'boatSupabaseId': guid,
        'isCompleted': true,
      }, guid);
      expect(out['supabaseId'], 'boat-guid-123::dailyEngine_oil');
      expect(out['groupSupabaseId'], 'boat-guid-123::dailyEngine');
      expect(out['boatSupabaseId'], guid, reason: 'boat id is not prefixed');
      expect(out['isCompleted'], true);
    });

    test('is idempotent — never double-prefixes', () {
      final once = WirePrefix.encode(
          'recipes', {'supabaseId': 'r1'}, guid);
      final twice = WirePrefix.encode('recipes', once, guid);
      expect(twice['supabaseId'], 'boat-guid-123::r1');
    });

    test('no-op for the boats table and for an empty guid', () {
      expect(WirePrefix.encode('boats', {'supabaseId': guid}, guid)['supabaseId'],
          guid);
      expect(
          WirePrefix.encode('recipes', {'supabaseId': 'r1'}, '')['supabaseId'],
          'r1');
    });
  });

  test('decode strips the prefix (round-trips encode)', () {
    final wire = WirePrefix.encode('shopping_items', {
      'supabaseId': 'i1',
      'categorySupabaseId': 'c1',
      'boatSupabaseId': guid,
    }, guid);
    final local = WirePrefix.decode('shopping_items', wire);
    expect(local['supabaseId'], 'i1');
    expect(local['categorySupabaseId'], 'c1');
    expect(local['boatSupabaseId'], guid);
  });

  test('encodeRecordId prefixes scoped tables, no-op for boats', () {
    expect(WirePrefix.encodeRecordId('checklist_items', 'x', guid),
        'boat-guid-123::x');
    expect(WirePrefix.encodeRecordId('boats', guid, guid), guid);
    expect(WirePrefix.encodeRecordId('checklist_items', 'x', ''), 'x');
  });

  test('decodeRecordId strips guid prefix', () {
    expect(WirePrefix.decodeRecordId('boat-guid-123::dailyEngine_oil'),
        'dailyEngine_oil');
    expect(WirePrefix.decodeRecordId('no-prefix'), 'no-prefix');
    expect(
      WirePrefix.decodeRecordId(
        WirePrefix.encodeRecordId('recipes', 'r1', guid),
      ),
      'r1',
    );
  });

  /// TEST25 — boat-scoped isolation: wrong prefix = cross-boat bleed.
  group('TEST25 WirePrefix cross-boat isolation', () {
    const boatA = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    const boatB = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

    test('same local id on two boats produces distinct wire ids', () {
      for (final table in WirePrefix.scopedTables) {
        final idA = WirePrefix.encodeRecordId(table, 'shared_seed_id', boatA);
        final idB = WirePrefix.encodeRecordId(table, 'shared_seed_id', boatB);
        expect(idA, isNot(idB), reason: table);
        expect(idA, startsWith('$boatA::'), reason: table);
        expect(idB, startsWith('$boatB::'), reason: table);
        expect(WirePrefix.decodeRecordId(idA), 'shared_seed_id');
        expect(WirePrefix.decodeRecordId(idB), 'shared_seed_id');
      }
    });

    test('encode never mutates boatSupabaseId for any scoped table', () {
      for (final table in WirePrefix.scopedTables) {
        final out = WirePrefix.encode(table, {
          'supabaseId': 'item1',
          'boatSupabaseId': boatA,
        }, boatA);
        expect(out['boatSupabaseId'], boatA, reason: table);
        expect(out['supabaseId'], '$boatA::item1', reason: table);
      }
    });

    test('encode/decode round-trips every scoped table + parent ref fields',
        () {
      final samples = <String, Map<String, dynamic>>{
        'checklist_groups': {'supabaseId': 'g1', 'boatSupabaseId': boatA},
        'checklist_items': {
          'supabaseId': 'i1',
          'groupSupabaseId': 'g1',
          'boatSupabaseId': boatA,
        },
        'shopping_categories': {'supabaseId': 'c1', 'boatSupabaseId': boatA},
        'shopping_items': {
          'supabaseId': 's1',
          'categorySupabaseId': 'c1',
          'boatSupabaseId': boatA,
        },
        'recipes': {'supabaseId': 'r1', 'boatSupabaseId': boatA},
        'recipe_ingredients': {
          'supabaseId': 'ri1',
          'recipeSupabaseId': 'r1',
          'boatSupabaseId': boatA,
        },
        'captain_logs': {'supabaseId': 'log1', 'boatSupabaseId': boatA},
        'maintenance_tasks': {'supabaseId': 'm1', 'boatSupabaseId': boatA},
        'documents': {'supabaseId': 'd1', 'boatSupabaseId': boatA},
        'crew_members': {'supabaseId': 'crew1', 'boatSupabaseId': boatA},
        'inventory_items': {'supabaseId': 'inv1', 'boatSupabaseId': boatA},
        'fuel_logs': {'supabaseId': 'f1', 'boatSupabaseId': boatA},
        'bar_ingredients': {'supabaseId': 'bar1', 'boatSupabaseId': boatA},
        'pantry_ingredients': {'supabaseId': 'pan1', 'boatSupabaseId': boatA},
      };

      for (final e in samples.entries) {
        final wire = WirePrefix.encode(e.key, e.value, boatA);
        final local = WirePrefix.decode(e.key, wire);
        for (final f in WirePrefix.fieldsFor(e.key)) {
          expect(local[f], e.value[f], reason: '${e.key}.$f');
        }
        expect(local['boatSupabaseId'], boatA, reason: e.key);
      }
    });

    test('fuzz: random boat guids + local ids stay isolated and round-trip',
        () {
      final rng = Random(42);
      String guid() {
        // UUID-ish without '::'
        final hex = List.generate(8, (_) => rng.nextInt(16).toRadixString(16))
            .join();
        return 'boat-$hex';
      }

      String localId() {
        final n = rng.nextInt(1 << 20);
        return 'id_$n';
      }

      final tables = WirePrefix.scopedTables.toList();
      for (var i = 0; i < 80; i++) {
        final table = tables[rng.nextInt(tables.length)];
        final a = guid();
        final b = guid();
        // Ensure distinct boats for isolation check.
        if (a == b) continue;
        final local = localId();

        final wa = WirePrefix.encodeRecordId(table, local, a);
        final wb = WirePrefix.encodeRecordId(table, local, b);
        expect(wa, isNot(wb), reason: 'iter $i $table');
        expect(WirePrefix.decodeRecordId(wa), local);
        expect(WirePrefix.decodeRecordId(wb), local);

        // Full record round-trip for primary + optional parent field.
        final fields = WirePrefix.fieldsFor(table);
        final record = <String, dynamic>{
          for (final f in fields) f: localId(),
          'boatSupabaseId': a,
          'payload': i,
        };
        // Use consistent local for first field.
        if (fields.isNotEmpty) record[fields.first] = local;

        final encoded = WirePrefix.encode(table, record, a);
        final decoded = WirePrefix.decode(table, encoded);
        for (final f in fields) {
          expect(decoded[f], record[f], reason: 'iter $i $table.$f');
        }
        expect(decoded['boatSupabaseId'], a);
        expect(decoded['payload'], i);
      }
    });

    test('empty local id strings are not prefixed', () {
      final out = WirePrefix.encode('recipes', {
        'supabaseId': '',
        'boatSupabaseId': boatA,
      }, boatA);
      expect(out['supabaseId'], '');
      expect(WirePrefix.encodeRecordId('recipes', '', boatA), '');
    });

    test('unknown table is a pure no-op (no bleed surface)', () {
      final rec = {'supabaseId': 'x', 'boatSupabaseId': boatA};
      expect(WirePrefix.encode('not_a_table', rec, boatA), rec);
      expect(WirePrefix.decode('not_a_table', rec), rec);
      expect(WirePrefix.encodeRecordId('not_a_table', 'x', boatA), 'x');
    });
  });
}
