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
}
