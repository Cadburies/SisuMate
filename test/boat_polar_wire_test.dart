import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';

/// #258/#259 — Boat polar must round-trip on the sync wire as `polar`
/// (matches Supabase `public.boats.polar` jsonb after migration
/// `20260805180000_boats_polar.sql`).
void main() {
  test('Boat.toJson includes polar array for outbox push', () {
    final boat = Boat()
      ..supabaseId = 'boat-1'
      ..name = 'Sisu'
      ..lastModified = DateTime.utc(2026, 8, 5)
      ..polar = const [
        PolarPoint(twaDeg: 45, twsKt: 12, boatSpeedKt: 6.5),
        PolarPoint(twaDeg: 90, twsKt: 15, boatSpeedKt: 7.2),
      ];

    final json = boat.toJson();
    expect(json.containsKey('polar'), isTrue);
    expect(json['polar'], isA<List>());
    expect((json['polar'] as List).length, 2);
    expect((json['polar'] as List).first['twaDeg'], 45);
  });

  test('Boat.fromJson restores polar from wire payload', () {
    final boat = Boat.fromJson({
      'supabaseId': 'boat-1',
      'name': 'Sisu',
      'isBought': false,
      'isHidden': false,
      'isSynced': true,
      'lastModified': '2026-08-05T00:00:00.000Z',
      'polar': [
        {'twaDeg': 60, 'twsKt': 10, 'boatSpeedKt': 5.5},
      ],
    });

    expect(boat.polar, hasLength(1));
    expect(boat.polar.single.twaDeg, 60);
    expect(boat.polar.single.boatSpeedKt, 5.5);
  });

  test('encodePolarTable / parsePolarTable round-trip', () {
    const points = [
      PolarPoint(twaDeg: 30, twsKt: 8, boatSpeedKt: 4.0),
    ];
    final encoded = encodePolarTable(points);
    final parsed = parsePolarTable(encoded);
    expect(parsed, hasLength(1));
    expect(parsed.single.twaDeg, 30);
    expect(parsed.single.twsKt, 8);
    expect(parsed.single.boatSpeedKt, 4.0);
  });
}
