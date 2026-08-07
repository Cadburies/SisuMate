import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/maintenance_risk_scorer.dart';

void main() {
  final asOf = DateTime.utc(2026, 8, 1);

  test('overdue critical keyword ranks high', () {
    final ranked = MaintenanceRiskScorer.rank(
      asOf: asOf,
      tasks: [
        (
          description: 'Bilge pump service',
          intervalHours: null,
          intervalMonths: 6,
          lastDoneHours: null,
          lastDoneDate: DateTime.utc(2025, 1, 1),
        ),
        (
          description: 'Polish stainless',
          intervalHours: null,
          intervalMonths: 12,
          lastDoneHours: null,
          lastDoneDate: DateTime.utc(2026, 7, 1),
        ),
      ],
    );
    expect(ranked.first.description, contains('Bilge'));
    expect(ranked.first.severity, anyOf('critical', 'high', 'medium'));
    expect(MaintenanceRiskScorer.formatReport(ranked), contains('Offline'));
  });

  test('fresh tasks score ok', () {
    final ranked = MaintenanceRiskScorer.rank(
      asOf: asOf,
      tasks: [
        (
          description: 'Winch grease',
          intervalHours: null,
          intervalMonths: 12,
          lastDoneHours: null,
          lastDoneDate: DateTime.utc(2026, 7, 15),
        ),
      ],
    );
    expect(ranked.single.severity, anyOf('ok', 'low'));
  });
}
