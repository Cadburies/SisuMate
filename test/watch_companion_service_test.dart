import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/watch_companion_service.dart';

void main() {
  group('WatchCompanionService (#300)', () {
    test('empty crew yields empty rotation', () {
      final plan = WatchCompanionService.build(crew: []);
      expect(plan.rotation, isEmpty);
      expect(plan.prompts, isNotEmpty);
    });

    test('rotates crew across horizon', () {
      final crew = [
        CrewMember()..name = 'A',
        CrewMember()..name = 'B',
      ];
      final plan = WatchCompanionService.build(
        crew: crew,
        start: DateTime.utc(2026, 8, 1, 0),
        watchLength: const Duration(hours: 3),
        horizon: const Duration(hours: 9),
      );
      expect(plan.rotation, hasLength(3));
      expect(plan.rotation.map((s) => s.crewName).toList(), ['A', 'B', 'A']);
      expect(plan.summaryLines.any((l) => l.contains('A → B')), isTrue);
    });
  });
}
