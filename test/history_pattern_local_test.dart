import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/history_pattern_local.dart';

void main() {
  group('HistoryPatternLocal (#288)', () {
    test('returns empty when fewer than 3 notes', () {
      final hits = HistoryPatternLocal.detect([
        (date: DateTime(2026, 1, 1), source: 'log', text: 'vibration at high rpm'),
        (date: DateTime(2026, 1, 2), source: 'log', text: 'vibration again'),
      ]);
      expect(hits, isEmpty);
    });

    test('finds recurring vibration theme across notes', () {
      final hits = HistoryPatternLocal.detect([
        (
          date: DateTime(2026, 7, 1),
          source: 'log',
          text: 'Noticed vibration at 2400 RPM under load'
        ),
        (
          date: DateTime(2026, 7, 10),
          source: 'log',
          text: 'Vibration returned after motor hours'
        ),
        (
          date: DateTime(2026, 7, 20),
          source: 'maintenance',
          text: 'Checked mounts — still feel vibration near shaft'
        ),
      ]);
      expect(hits, isNotEmpty);
      expect(hits.any((h) => h.theme.contains('vibration')), isTrue);
      expect(hits.first.noteCount, greaterThanOrEqualTo(2));
    });

    test('formatReport mentions offline and no hits message', () {
      final empty = HistoryPatternLocal.formatReport(const []);
      expect(empty, contains('No recurring themes'));
      final report = HistoryPatternLocal.formatReport([
        HistoryPatternHit(
          theme: 'vibration',
          noteCount: 3,
          dates: [DateTime(2026, 7, 20)],
        ),
      ]);
      expect(report, contains('Offline scan'));
      expect(report, contains('vibration'));
      expect(report, contains('3 notes'));
    });
  });
}
