import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/ui/passage_handoff.dart';

/// #329 — Anchor owns the hook; Weather owns routing. This is the extra
/// contract #328 saved spots will call (`toDestination` + `open`).
void main() {
  group('PassageHandoff', () {
    test('fromHook is start-only (dest left for the planner)', () {
      final h = PassageHandoff.fromHook(lat: 26.5412, lon: -77.0634);
      expect(h.hasStart, isTrue);
      expect(h.hasDest, isFalse);
      expect(h.startName, 'Hook');
      expect(h.startLat, 26.5412);
      expect(h.startLon, -77.0634);
      expect(h.destLat, isNull);
      expect(h.destLon, isNull);
    });

    test('toDestination is the #328 contract: start + named dest', () {
      final h = PassageHandoff.toDestination(
        startName: 'Hook',
        startLat: 26.5412,
        startLon: -77.0634,
        destName: 'Marsh Harbour',
        destLat: 26.5410,
        destLon: -77.0600,
      );
      expect(h.hasStart, isTrue);
      expect(h.hasDest, isTrue);
      expect(h.destName, 'Marsh Harbour');
      expect(h.destLat, 26.5410);
      expect(h.destLon, -77.0600);
    });

    test('toExtra / fromExtra round-trip including dest', () {
      final orig = PassageHandoff.toDestination(
        startName: 'Hook',
        startLat: 12.0,
        startLon: -61.7,
        destName: 'Marsh Harbour',
        destLat: 26.54,
        destLon: -77.06,
      );
      final back = PassageHandoff.fromExtra(orig.toExtra());
      expect(back, isNotNull);
      expect(back!.startName, 'Hook');
      expect(back.startLat, 12.0);
      expect(back.startLon, -61.7);
      expect(back.destName, 'Marsh Harbour');
      expect(back.destLat, 26.54);
      expect(back.destLon, -77.06);
    });

    test('toExtra also writes legacy lat/lon so old Weather extras still work',
        () {
      final extra = PassageHandoff.fromHook(lat: 1.25, lon: 2.5).toExtra();
      expect(extra['lat'], 1.25);
      expect(extra['lon'], 2.5);
      expect(extra['startLat'], 1.25);
      expect(extra['startLon'], 2.5);
    });

    test('fromExtra accepts legacy lat/lon as start', () {
      final h = PassageHandoff.fromExtra({'lat': 1.5, 'lon': 2.5});
      expect(h, isNotNull);
      expect(h!.startLat, 1.5);
      expect(h.startLon, 2.5);
      expect(h.hasDest, isFalse);
    });

    test('fromExtra prefers startLat/startLon over legacy lat/lon', () {
      final h = PassageHandoff.fromExtra({
        'startLat': 10.0,
        'startLon': 20.0,
        'lat': 1.0,
        'lon': 2.0,
      });
      expect(h!.startLat, 10.0);
      expect(h.startLon, 20.0);
    });

    test('fromExtra returns null for missing / non-map extras', () {
      expect(PassageHandoff.fromExtra(null), isNull);
      expect(PassageHandoff.fromExtra('x'), isNull);
    });

    test('fromExtra returns the same instance when already a PassageHandoff',
        () {
      final orig = PassageHandoff.fromHook(lat: 1, lon: 2);
      expect(identical(PassageHandoff.fromExtra(orig), orig), isTrue);
    });
  });

  group('#329 ownership cut (source)', () {
    test('anchor UI does not copy isochrone / polar routing', () {
      const paths = [
        'lib/ui/anchor/anchor_alarm_screen.dart',
        'lib/ui/anchor/anchor_info_panel.dart',
        'lib/ui/anchor/anchor_chart_map.dart',
      ];
      for (final path in paths) {
        final src = File('${Directory.current.path}/$path').readAsStringSync();
        expect(src.contains('IsochroneRoute'), isFalse, reason: path);
        expect(src.contains('computeIsochroneRoute'), isFalse, reason: path);
        expect(src.contains('WeatherRoutingService'), isFalse, reason: path);
      }
    });

    test('home keeps distinct Weather and Anchor Alarm tiles', () {
      final src =
          File('${Directory.current.path}/lib/ui/home/home_modules.dart')
              .readAsStringSync();
      expect(src.contains("id: 'weather'"), isTrue);
      expect(src.contains("title: 'Weather'"), isTrue);
      expect(src.contains("id: 'anchor'"), isTrue);
      expect(src.contains("title: 'Anchor Alarm'"), isTrue);
    });

    test('WeatherScreen prefers seedLat/seedLon over the saved pin', () {
      final src =
          File('${Directory.current.path}/lib/ui/weather/weather_screen.dart')
              .readAsStringSync();
      expect(src.contains('final double? seedLat;'), isTrue);
      expect(
        src.contains('widget.seedLat != null && widget.seedLon != null'),
        isTrue,
      );
    });
  });
}
