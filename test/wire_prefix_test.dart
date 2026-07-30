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
}
