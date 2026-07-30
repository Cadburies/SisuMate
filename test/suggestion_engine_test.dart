import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/suggestion_engine.dart';

void main() {
  const engine = SuggestionEngine();

  MaintenanceTask task({
    String desc = 'Oil change',
    int? intervalMonths,
    DateTime? lastDone,
    bool hidden = false,
  }) =>
      MaintenanceTask()
        ..supabaseId = 't1'
        ..description = desc
        ..intervalMonths = intervalMonths
        ..lastDoneDate = lastDone
        ..isHidden = hidden;

  group('SuggestionEngine (S4)', () {
    test('flags overdue maintenance when past interval months', () {
      final now = DateTime.utc(2026, 7, 1);
      final list = engine.build(
        maintenanceTasks: [
          task(
            intervalMonths: 6,
            lastDone: DateTime.utc(2025, 1, 1),
          ),
        ],
        now: now,
      );
      expect(list, isNotEmpty);
      expect(list.first.severity, SuggestionSeverity.urgent);
      expect(list.first.title, contains('Overdue'));
    });

    test('flags due soon within 14 days', () {
      final now = DateTime.utc(2026, 7, 20);
      final list = engine.build(
        maintenanceTasks: [
          task(
            intervalMonths: 1,
            lastDone: DateTime.utc(2026, 6, 25), // due 2026-07-25 → 5 days
          ),
        ],
        now: now,
      );
      expect(list, isNotEmpty);
      expect(list.first.severity, SuggestionSeverity.watch);
      expect(list.first.title, contains('Due soon'));
    });

    test('ignores hidden tasks and tasks without intervals', () {
      final list = engine.build(
        maintenanceTasks: [
          task(intervalMonths: 6, lastDone: DateTime.utc(2020, 1, 1), hidden: true),
          task(intervalMonths: null, lastDone: null),
        ],
        now: DateTime.utc(2026, 7, 1),
      );
      expect(list.where((s) => s.id.startsWith('maint_')), isEmpty);
    });

    test('weather notes trigger rough-conditions tip', () {
      final list = engine.build(
        maintenanceTasks: const [],
        recentWeatherNotes: ['Gale force winds overnight'],
      );
      expect(list.any((s) => s.id == 'wx_storm'), isTrue);
    });

    test('high wind knots produce breeze tip', () {
      final list = engine.build(
        maintenanceTasks: const [],
        windKnots: 18,
      );
      expect(list.any((s) => s.id == 'wx_breeze'), isTrue);
    });
  });
}
