import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/units.dart';

void main() {
  group('UnitConverter.toMetric', () {
    test('converts culinary volume to ml', () {
      expect(UnitConverter.toMetric(2, 'tbsp')!.quantity, 30);
      expect(UnitConverter.toMetric(2, 'tbsp')!.unit, 'ml');
      expect(UnitConverter.toMetric(1, 'tsp')!.quantity, 5);
      expect(UnitConverter.toMetric(1, 'cup')!.quantity, 240);
      expect(UnitConverter.toMetric(1, 'oz')!.unit, 'ml');
      expect(UnitConverter.toMetric(1, 'oz')!.quantity, closeTo(29.57, 0.1));
    });

    test('converts weight to g', () {
      expect(UnitConverter.toMetric(1, 'lb')!.quantity, closeTo(453.6, 0.1));
      expect(UnitConverter.toMetric(1, 'lb')!.unit, 'g');
      expect(UnitConverter.toMetric(2, 'oz wt')!.unit, 'g');
    });

    test('leaves metric and count units alone', () {
      expect(UnitConverter.toMetric(60, 'ml')!.unit, 'ml');
      expect(UnitConverter.toMetric(60, 'ml')!.quantity, 60);
      expect(UnitConverter.toMetric(1, 'dash')!.unit, 'dash');
      expect(UnitConverter.toMetric(2, 'cloves')!.unit, 'cloves');
    });

    test('converts Fahrenheit to Celsius', () {
      final m = UnitConverter.toMetric(212, '°F')!;
      expect(m.unit, '°C');
      expect(m.quantity, closeTo(100, 0.1));
    });
  });

  group('UnitConverter.forDisplay bar units', () {
    test('30 ml → 1 oz (not tbsp)', () {
      final m = UnitConverter.forDisplay(
        30,
        'ml',
        UnitSystem.imperial,
        preferBarUnits: true,
      )!;
      expect(m.unit, 'oz');
      expect(m.quantity, 1);
    });

    test('15 ml → ½ oz', () {
      final m = UnitConverter.forDisplay(
        15,
        'ml',
        UnitSystem.imperial,
        preferBarUnits: true,
      )!;
      expect(m.unit, 'oz');
      expect(m.quantity, 0.5);
      expect(
        UnitConverter.format(15, 'ml', UnitSystem.imperial, preferBarUnits: true),
        '½ oz',
      );
    });

    test('7.5 ml → ¼ oz', () {
      expect(
        UnitConverter.format(7.5, 'ml', UnitSystem.imperial, preferBarUnits: true),
        '¼ oz',
      );
    });

    test('45 ml → 1½ oz', () {
      expect(
        UnitConverter.format(45, 'ml', UnitSystem.imperial, preferBarUnits: true),
        '1½ oz',
      );
    });

    test('culinary path still uses tbsp for 15 ml', () {
      final m = UnitConverter.forDisplay(15, 'ml', UnitSystem.imperial)!;
      expect(m.unit, 'tbsp');
      expect(m.quantity, 1);
    });

    test('metric passthrough', () {
      final m = UnitConverter.forDisplay(60, 'ml', UnitSystem.metric)!;
      expect(m.unit, 'ml');
      expect(m.quantity, 60);
    });

    test('format with scale', () {
      final s = UnitConverter.format(30, 'ml', UnitSystem.metric, scale: 2);
      expect(s, '60 ml');
    });
  });

  group('fuel volume', () {
    test('liters ↔ gallons', () {
      final gal = UnitConverter.litersToDisplay(3.78541, UnitSystem.imperial);
      expect(gal, closeTo(1.0, 0.01));
      final liters =
          UnitConverter.displayVolumeToLiters(1, UnitSystem.imperial);
      expect(liters, closeTo(3.785, 0.01));
      expect(UnitConverter.fuelVolumeLabel(UnitSystem.metric), 'L');
      expect(UnitConverter.fuelVolumeLabel(UnitSystem.imperial), 'gal');
    });

    test('price per litre ↔ per gallon', () {
      // $1.00/L → ~$3.79/gal display
      final perGal =
          UnitConverter.pricePerLiterToDisplay(1.0, UnitSystem.imperial);
      expect(perGal, closeTo(3.785, 0.01));
      // Enter $3.785/gal → store $1.00/L
      final perL =
          UnitConverter.displayPriceToPerLiter(3.78541, UnitSystem.imperial);
      expect(perL, closeTo(1.0, 0.01));
      expect(UnitConverter.fuelPriceVolumeWord(UnitSystem.imperial), 'gallon');
      expect(UnitConverter.fuelPriceVolumeWord(UnitSystem.metric), 'litre');
      // totalCost invariant: gal * $/gal == L * $/L
      const liters = 37.8541;
      const pricePerL = 1.5;
      final gals =
          UnitConverter.litersToDisplay(liters, UnitSystem.imperial);
      final pricePerG =
          UnitConverter.pricePerLiterToDisplay(pricePerL, UnitSystem.imperial);
      expect(gals * pricePerG, closeTo(liters * pricePerL, 0.05));
    });
  });

  group('temperature text', () {
    test('F to C for storage', () {
      final out = UnitConverter.convertTemperaturesInText(
        'Bake at 350°F for 20 min',
        UnitSystem.metric,
      );
      expect(out.contains('°C'), isTrue);
      expect(out.contains('°F'), isFalse);
    });

    test('C to F for imperial display', () {
      final out = UnitConverter.convertTemperaturesInText(
        'Bake at 180°C for 20 min',
        UnitSystem.imperial,
      );
      expect(out.contains('°F'), isTrue);
      expect(out.contains('°C'), isFalse);
    });
  });

  group('normalizePair', () {
    test('import path converts oz to ml', () {
      final (q, u) = UnitConverter.normalizePair(2, 'oz');
      expect(u, 'ml');
      expect(q, closeTo(59.15, 0.2));
    });
  });

  group('weather display (metric source only)', () {
    test('temp C stays C in metric, becomes F in imperial', () {
      expect(UnitConverter.formatTempC(0, UnitSystem.metric), '0 C');
      expect(UnitConverter.formatTempC(0, UnitSystem.imperial), '32 F');
    });

    test('speed prefs: kn vs km/h vs m/s from stored m/s', () {
      expect(
        UnitConverter.formatSpeedFromMs(10, SpeedUnitPref.knots),
        contains('kn'),
      );
      expect(
        UnitConverter.formatSpeedFromMs(10, SpeedUnitPref.kmh),
        contains('km/h'),
      );
      expect(
        UnitConverter.formatSpeedFromMs(10, SpeedUnitPref.metersPerSecond),
        contains('m/s'),
      );
    });

    test('depth prefs: m / ft / fathoms', () {
      expect(
        UnitConverter.formatLengthM(30, UnitSystem.metric,
            depth: DepthUnitPref.meters),
        contains('m'),
      );
      expect(
        UnitConverter.formatLengthM(30, UnitSystem.imperial,
            depth: DepthUnitPref.feet),
        contains('ft'),
      );
      expect(
        UnitConverter.formatLengthM(30, UnitSystem.metric,
            depth: DepthUnitPref.fathoms),
        contains('fm'),
      );
    });

    test('distance prefs: NM / km / mi', () {
      expect(
        UnitConverter.formatDistanceNm(10, DistanceUnitPref.nauticalMiles),
        contains('NM'),
      );
      expect(
        UnitConverter.formatDistanceNm(10, DistanceUnitPref.kilometers),
        contains('km'),
      );
    });

    test('fuel liters always converted for imperial display', () {
      expect(UnitConverter.formatLiters(3.78541, UnitSystem.metric), contains('L'));
      expect(UnitConverter.formatLiters(3.78541, UnitSystem.imperial), contains('gal'));
    });

    test('AppUnitPrefs presets and JSON round-trip', () {
      expect(AppUnitPrefs.marine.matchingPreset, UnitPreset.marine);
      expect(AppUnitPrefs.us.matchingPreset, UnitPreset.us);
      final custom = AppUnitPrefs.marine.copyWith(windSpeed: SpeedUnitPref.kmh);
      expect(custom.matchingPreset, isNull);
      final back = AppUnitPrefs.fromJson(custom.toJson());
      expect(back, custom);
    });

    // SUG5 — wind and boat/SOG speed are independent prefs.
    test('windSpeed and boatSpeed convert independently', () {
      final prefs = AppUnitPrefs.marine.copyWith(
        windSpeed: SpeedUnitPref.knots,
        boatSpeed: SpeedUnitPref.kmh,
      );

      // 10 m/s wind stays in knots; 10 m/s boat speed shows km/h — the two
      // reads of the same stored value must differ once split.
      final windDisplay =
          UnitConverter.formatSpeedFromMs(10, prefs.windSpeed);
      final boatDisplay =
          UnitConverter.formatSpeedFromMs(10, prefs.boatSpeed);
      expect(windDisplay, contains('kn'));
      expect(boatDisplay, contains('km/h'));
      expect(windDisplay, isNot(equals(boatDisplay)));
    });

    test('windSpeed and boatSpeed each survive copyWith + JSON round-trip independently', () {
      final base = AppUnitPrefs.marine;
      expect(base.windSpeed, SpeedUnitPref.knots);
      expect(base.boatSpeed, SpeedUnitPref.knots);

      final windOnly = base.copyWith(windSpeed: SpeedUnitPref.mph);
      expect(windOnly.windSpeed, SpeedUnitPref.mph);
      expect(windOnly.boatSpeed, SpeedUnitPref.knots);

      final boatOnly = base.copyWith(boatSpeed: SpeedUnitPref.metersPerSecond);
      expect(boatOnly.windSpeed, SpeedUnitPref.knots);
      expect(boatOnly.boatSpeed, SpeedUnitPref.metersPerSecond);

      final roundTripped = AppUnitPrefs.fromJson(boatOnly.toJson());
      expect(roundTripped, boatOnly);
      expect(roundTripped.windSpeed, SpeedUnitPref.knots);
      expect(roundTripped.boatSpeed, SpeedUnitPref.metersPerSecond);
    });

    test('AppUnitPrefs.fromJson defaults missing windSpeed/boatSpeed keys to marine', () {
      final prefs = AppUnitPrefs.fromJson(const {'volume': 'usGallons'});
      expect(prefs.windSpeed, AppUnitPrefs.marine.windSpeed);
      expect(prefs.boatSpeed, AppUnitPrefs.marine.boatSpeed);
    });
  });

  /// TEST27 — edge quantities (0 / null / huge / negative) must not throw and
  /// must keep storage-metric contracts.
  group('TEST27 unit conversion edges', () {
    test('null/empty unit + null quantity → null or empty-safe', () {
      expect(UnitConverter.toMetric(null, null), isNull);
      expect(UnitConverter.toMetric(null, ''), isNull);
      expect(UnitConverter.forDisplay(null, null, UnitSystem.metric), isNull);
      expect(UnitConverter.forDisplay(null, '', UnitSystem.imperial), isNull);
      expect(UnitConverter.isConvertible(null), isFalse);
      expect(UnitConverter.isConvertible(''), isFalse);
      expect(UnitConverter.isConvertible('   '), isFalse);
    });

    test('null quantity with known unit canonicalizes unit only', () {
      final m = UnitConverter.toMetric(null, 'oz');
      expect(m, isNotNull);
      expect(m!.unit, 'ml');
      // Placeholder 0 — normalizePair restores null quantity.
      expect(m.quantity, 0);

      final (q, u) = UnitConverter.normalizePair(null, 'tbsp');
      expect(q, isNull);
      expect(u, 'ml');

      final (q2, u2) = UnitConverter.normalizePair(null, null);
      expect(q2, isNull);
      expect(u2, isNull);
    });

    test('zero quantities stay zero through metric and display', () {
      expect(UnitConverter.toMetric(0, 'cup')!.quantity, 0);
      expect(UnitConverter.toMetric(0, 'lb')!.quantity, 0);
      expect(UnitConverter.toMetric(0, '°F')!.quantity, closeTo(-17.78, 0.1));
      expect(
        UnitConverter.forDisplay(0, 'ml', UnitSystem.imperial)!.quantity,
        0,
      );
      expect(UnitConverter.litersToDisplay(0, UnitSystem.imperial), 0);
      expect(UnitConverter.displayVolumeToLiters(0, UnitSystem.imperial), 0);
      expect(UnitConverter.format(0, 'ml', UnitSystem.metric), '0 ml');
      expect(UnitConverter.formatLiters(0, UnitSystem.metric), '0 L');
    });

    test('huge values convert without throwing or NaN', () {
      const huge = 1e12;
      final m = UnitConverter.toMetric(huge, 'gal');
      expect(m, isNotNull);
      expect(m!.quantity.isFinite, isTrue);
      expect(m.quantity, closeTo(huge * UnitConverter.mlPerGallon, huge * 1e-6));

      final display = UnitConverter.forDisplay(
        huge,
        'ml',
        UnitSystem.imperial,
        preferBarUnits: true,
      );
      expect(display, isNotNull);
      expect(display!.quantity.isFinite, isTrue);

      final liters = UnitConverter.displayVolumeToLiters(huge, UnitSystem.imperial);
      expect(liters.isFinite, isTrue);
      expect(liters, greaterThan(huge));

      final speed = UnitConverter.formatSpeedFromMs(huge, SpeedUnitPref.knots);
      expect(speed, isNotEmpty);
      expect(speed, isNot(contains('NaN')));
    });

    test('negative temperatures convert correctly', () {
      // -40 F == -40 C
      final m = UnitConverter.toMetric(-40, '°F')!;
      expect(m.unit, '°C');
      expect(m.quantity, closeTo(-40, 0.01));

      expect(
        UnitConverter.formatTempC(-40, UnitSystem.imperial),
        '-40 F',
      );
      expect(
        UnitConverter.convertTemperaturesInText('Chill at -10°F', UnitSystem.metric),
        contains('°C'),
      );
    });

    test('format with null quantity shows unit-only or empty', () {
      expect(UnitConverter.format(null, 'ml', UnitSystem.metric), 'ml');
      expect(UnitConverter.format(null, null, UnitSystem.metric), '');
      expect(UnitConverter.format(null, '', UnitSystem.imperial), '');
    });

    test('formatTempCRange handles null min/max', () {
      expect(
        UnitConverter.formatTempCRange(null, null, UnitSystem.metric),
        '- / -',
      );
      expect(
        UnitConverter.formatTempCRange(10, null, UnitSystem.metric),
        '10 C / -',
      );
      expect(
        UnitConverter.formatTempCRange(null, 20, UnitSystem.metric),
        '- / 20 C',
      );
    });

    test('speed display ↔ knots round-trip edges', () {
      expect(UnitConverter.speedDisplayToKnots(0, SpeedUnitPref.knots), 0);
      expect(UnitConverter.knotsToSpeedDisplay(0, SpeedUnitPref.kmh), 0);
      const big = 1e6;
      final kn = UnitConverter.speedDisplayToKnots(big, SpeedUnitPref.kmh);
      expect(kn.isFinite, isTrue);
      expect(
        UnitConverter.knotsToSpeedDisplay(kn, SpeedUnitPref.kmh),
        closeTo(big, big * 1e-9),
      );
    });

    test('unknown count units pass through at zero and huge', () {
      expect(UnitConverter.toMetric(0, 'cloves')!.unit, 'cloves');
      expect(UnitConverter.toMetric(0, 'cloves')!.quantity, 0);
      expect(UnitConverter.toMetric(1e9, 'dash')!.quantity, 1e9);
      expect(UnitConverter.toMetric(1e9, 'dash')!.unit, 'dash');
    });

    test('isConvertible true for known units, false for junk', () {
      expect(UnitConverter.isConvertible('ml'), isTrue);
      expect(UnitConverter.isConvertible('TBSP'), isTrue);
      expect(UnitConverter.isConvertible('cloves'), isFalse);
      expect(UnitConverter.isConvertible('xyzzy'), isFalse);
    });
  });
}
