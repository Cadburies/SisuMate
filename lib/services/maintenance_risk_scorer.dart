/// #289 — offline maintenance risk ranking (no LLM).
class MaintenanceRiskItem {
  final String description;
  final double score;
  final String severity; // critical | high | medium | low | ok
  final String reasoning;

  const MaintenanceRiskItem({
    required this.description,
    required this.score,
    required this.severity,
    required this.reasoning,
  });
}

class MaintenanceRiskScorer {
  MaintenanceRiskScorer._();

  static const _criticalKeywords = [
    'bilge',
    'fire',
    'epirb',
    'steering',
    'rudder',
    'through-hull',
    'through hull',
    'seacock',
    'gas',
    'lpg',
    'propane',
    'battery',
    'engine',
    'cooling',
    'raw water',
    'raw-water',
    'anchor',
    'windlass',
  ];

  /// Rank tasks most risky first. Pure — no I/O.
  static List<MaintenanceRiskItem> rank({
    required DateTime asOf,
    required Iterable<({
      String description,
      int? intervalHours,
      int? intervalMonths,
      int? lastDoneHours,
      DateTime? lastDoneDate,
    })> tasks,
    int? currentEngineHours,
  }) {
    final out = <MaintenanceRiskItem>[];
    for (final t in tasks) {
      out.add(_scoreOne(asOf, t, currentEngineHours));
    }
    out.sort((a, b) => b.score.compareTo(a.score));
    return out;
  }

  /// Human-readable offline report (dialog body).
  static String formatReport(List<MaintenanceRiskItem> ranked) {
    if (ranked.isEmpty) {
      return 'No maintenance tasks to triage.';
    }
    final risky = ranked.where((r) => r.severity != 'ok').toList();
    if (risky.isEmpty) {
      return 'Nothing looks urgently risky offline. Keep logging hours and '
          'service dates so overdue ratios stay accurate.';
    }
    final buf = StringBuffer('Offline risk triage (local rules):\n');
    for (var i = 0; i < risky.length && i < 12; i++) {
      final r = risky[i];
      buf.writeln();
      buf.writeln('${i + 1}. [${r.severity.toUpperCase()}] ${r.description}');
      buf.writeln('   ${r.reasoning}');
    }
    return buf.toString().trimRight();
  }

  static MaintenanceRiskItem _scoreOne(
    DateTime asOf,
    ({
      String description,
      int? intervalHours,
      int? intervalMonths,
      int? lastDoneHours,
      DateTime? lastDoneDate,
    }) t,
    int? currentEngineHours,
  ) {
    final desc = t.description.trim().isEmpty ? '(untitled task)' : t.description.trim();
    final lower = desc.toLowerCase();
    var score = 0.0;
    final reasons = <String>[];

    final critical = _criticalKeywords.any(lower.contains);
    if (critical) {
      score += 40;
      reasons.add('Safety-critical keyword in description.');
    }

    // Calendar overdue ratio
    if (t.intervalMonths != null &&
        t.intervalMonths! > 0 &&
        t.lastDoneDate != null) {
      final due = t.lastDoneDate!
          .add(Duration(days: (t.intervalMonths! * 30.44).round()));
      final windowDays = t.intervalMonths! * 30.44;
      final overdueDays = asOf.difference(due).inDays;
      if (overdueDays > 0) {
        final ratio = (overdueDays / windowDays).clamp(0.0, 3.0);
        score += 35 * ratio;
        reasons.add(
          'Calendar overdue by ~$overdueDays days '
          '(interval ${t.intervalMonths} mo).',
        );
      } else if (overdueDays > -14) {
        score += 10;
        reasons.add('Due within two weeks on calendar interval.');
      }
    } else if (t.intervalMonths != null && t.lastDoneDate == null) {
      score += 15;
      reasons.add('Has calendar interval but no last-done date.');
    }

    // Hours overdue ratio
    if (t.intervalHours != null &&
        t.intervalHours! > 0 &&
        t.lastDoneHours != null &&
        currentEngineHours != null) {
      final since = currentEngineHours - t.lastDoneHours!;
      if (since > t.intervalHours!) {
        final ratio =
            ((since - t.intervalHours!) / t.intervalHours!).clamp(0.0, 3.0);
        score += 35 * ratio;
        reasons.add(
          'Hours overdue: $since h since service vs ${t.intervalHours} h interval.',
        );
      }
    } else if (t.intervalHours != null && t.lastDoneHours == null) {
      score += 12;
      reasons.add('Has hours interval but no last-done hours.');
    }

    if (reasons.isEmpty) {
      reasons.add('Within interval or insufficient history to score.');
    }

    final severity = score >= 70
        ? 'critical'
        : score >= 45
            ? 'high'
            : score >= 25
                ? 'medium'
                : score >= 10
                    ? 'low'
                    : 'ok';

    return MaintenanceRiskItem(
      description: desc,
      score: score,
      severity: severity,
      reasoning: reasons.join(' '),
    );
  }
}
