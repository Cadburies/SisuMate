import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/maintenance_local_explain.dart';

void main() {
  group('MaintenanceLocalExplain.explain', () {
    test('seeded oil filter cites the 4JH45 number and why it matters', () {
      final text = MaintenanceLocalExplain.explain(
        title: 'Oil Filter Replacement',
        description: 'Replace oil filter (Yanmar #129150-35170).',
      );

      expect(text, contains('Offline maintenance note'));
      expect(text, contains('129150-35170'));
      expect(text, contains('Oil pressure'));
    });

    test('raw-water pump explains the impeller and overheating', () {
      final text = MaintenanceLocalExplain.explain(
        title: 'Raw Water Pump Service',
        description: 'Inspect and service raw water pump, replace impeller.',
      );

      expect(text, contains('impeller'));
      expect(text, contains('overheat'));
    });

    test('bilge pump covers a stuck float switch', () {
      final text = MaintenanceLocalExplain.explain(
        title: 'Check bilge pump',
        description: 'Verify the automatic float switch cycles',
      );

      expect(text, contains('float switch'));
      expect(text, contains('bilge'));
    });

    test('an unknown task still returns a usable note', () {
      final text = MaintenanceLocalExplain.explain(
        title: 'Polish the bell',
        description: null,
      );

      expect(text, contains('not in the bundled'));
      expect(text, contains('Polish the bell'));
      expect(text, contains('engine must be stopped'));
    });

    test('engine oil copies the seeded volume out of the task text', () {
      final text = MaintenanceLocalExplain.explain(
        title: 'Engine Oil Change',
        description:
            'Change engine oil using Yanmar recommended oil. Capacity: approximately 7.5 liters.',
      );

      expect(text, contains('7.5 liters'));
      expect(text, contains('turbo'));
    });
  });

  group('MaintenanceLocalExplain.partSpec', () {
    test('names the seeded filter and says other engines differ', () {
      final text = MaintenanceLocalExplain.partSpec(
        title: 'Change oil filter',
        description: 'Yanmar 3YM30',
      );

      expect(text, contains('Offline part guide'));
      expect(text, contains('not a live catalog'));
      expect(text, contains('129150-35170'));
      expect(text, contains('3YM30'));
      expect(text, contains('Area: not set'));
    });

    test('a coarse city is where to ask, not a stock check', () {
      final text = MaintenanceLocalExplain.partSpec(
        title: 'Change oil filter',
        description: 'Yanmar 3YM30',
        coarseLocation: 'Kaohsiung',
      );

      expect(text, contains('Area: Kaohsiung'));
      expect(text, contains('does not check who is open'));
    });

    test('impeller spec tells you to measure the old one', () {
      final text = MaintenanceLocalExplain.partSpec(
        title: 'Raw Water Pump Service',
        description: 'replace impeller',
      );

      expect(text, contains('vanes'));
      expect(text, contains('Take the removed part'));
      expect(text, isNot(contains('Area: Kaohsiung')));
    });
  });
}
