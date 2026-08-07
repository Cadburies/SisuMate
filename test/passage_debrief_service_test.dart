import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/models/sailing_polar_sample.dart';
import 'package:sisu_mate/services/passage_debrief_service.dart';

void main() {
  group('PassageDebriefService (#301)', () {
    test('aggregates logs sog and checklist rate', () {
      final now = DateTime.utc(2026, 8, 7);
      final logs = [
        CaptainLogEntry()
          ..logDate = DateTime.utc(2026, 8, 5)
          ..sogKt = 5
          ..positionLat = 10
          ..positionLng = -61,
        CaptainLogEntry()
          ..logDate = DateTime.utc(2026, 8, 6)
          ..sogKt = 7
          ..positionLat = 10.1
          ..positionLng = -61,
      ];
      final checks = [
        ChecklistItem()
          ..isCompleted = true
          ..isHidden = false,
        ChecklistItem()
          ..isCompleted = false
          ..isHidden = false,
      ];
      final samples = [
        SailingPolarSample()
          ..observedAt = DateTime.utc(2026, 8, 6)
          ..seaState = 'calm'
          ..twaDeg = 90
          ..twsKt = 10
          ..boatSpeedKt = 5,
      ];
      final stats = PassageDebriefService.aggregate(
        logs: logs,
        polarSamples: samples,
        checklistItems: checks,
        now: now,
        windowStart: DateTime.utc(2026, 8, 1),
        windowEnd: now,
      );
      expect(stats.logEntryCount, 2);
      expect(stats.avgSogKt, closeTo(6, 0.01));
      expect(stats.polarSampleCount, 1);
      expect(stats.seaStateMix['calm'], 1);
      expect(stats.checklistCompleted, 1);
      expect(stats.checklistTotal, 2);
      expect(stats.summaryLines.first, contains('Passage debrief'));
      expect(stats.milesNm, isNotNull);
    });
  });
}
