import '../models/models.dart';

/// Offline-rules suggestions (S4). No LLM required — pure deterministic rules
/// over local Drift data. Optional weather/log cues when present.
enum SuggestionSeverity { info, watch, urgent }

class BoatSuggestion {
  final String id;
  final String title;
  final String detail;
  final SuggestionSeverity severity;
  /// Optional deep-link route path (e.g. [AppRoutes.maintenance]).
  final String? routePath;

  const BoatSuggestion({
    required this.id,
    required this.title,
    required this.detail,
    required this.severity,
    this.routePath,
  });
}

/// Builds predictive maintenance / weather-aware tips from local state only.
class SuggestionEngine {
  const SuggestionEngine();

  List<BoatSuggestion> build({
    required List<MaintenanceTask> maintenanceTasks,
    DateTime? now,
    /// Recent captain-log weather strings (free text), newest first.
    List<String> recentWeatherNotes = const [],
    /// Optional current wind speed (knots) if weather module has a reading.
    double? windKnots,
  }) {
    final at = now ?? DateTime.now().toUtc();
    final out = <BoatSuggestion>[];

    for (final task in maintenanceTasks) {
      if (task.isHidden) continue;
      final due = _dueInfo(task, at);
      if (due == null) continue;
      out.add(BoatSuggestion(
        id: 'maint_${task.supabaseId.isNotEmpty ? task.supabaseId : task.id}',
        title: due.overdue
            ? 'Overdue: ${task.description}'
            : 'Due soon: ${task.description}',
        detail: due.detail,
        severity:
            due.overdue ? SuggestionSeverity.urgent : SuggestionSeverity.watch,
        routePath: '/maintenance',
      ));
    }

    // Weather-aware (offline rules on free-text log / optional wind).
    final weatherBlob =
        recentWeatherNotes.take(5).join(' ').toLowerCase();
    if (_looksStormy(weatherBlob) || (windKnots != null && windKnots >= 25)) {
      out.add(const BoatSuggestion(
        id: 'wx_storm',
        title: 'Rough conditions noted',
        detail: 'Recent log/weather suggests strong wind or stormy seas — '
            'recheck deck gear, dinghy, and safety kit before next passage.',
        severity: SuggestionSeverity.watch,
        routePath: '/safety',
      ));
    } else if (windKnots != null && windKnots >= 15) {
      out.add(BoatSuggestion(
        id: 'wx_breeze',
        title: 'Breezy conditions (${windKnots.toStringAsFixed(0)} kn)',
        detail: 'Consider reefing early and securing loose cockpit items.',
        severity: SuggestionSeverity.info,
        routePath: '/weather',
      ));
    }

    // Stable order: urgent first, then watch, then info; cap list.
    out.sort((a, b) => b.severity.index.compareTo(a.severity.index));
    if (out.length > 8) return out.sublist(0, 8);
    return out;
  }

  _DueInfo? _dueInfo(MaintenanceTask task, DateTime at) {
    final months = task.intervalMonths;
    final hours = task.intervalHours;
    if (months == null && hours == null) return null;

    // Calendar interval (months).
    if (months != null && months > 0) {
      final last = task.lastDoneDate?.toUtc();
      if (last == null) {
        return _DueInfo(
          overdue: true,
          detail: 'No completion date recorded — interval is every $months mo.',
        );
      }
      final dueAt = DateTime.utc(last.year, last.month + months, last.day);
      final days = dueAt.difference(at).inDays;
      if (days < 0) {
        return _DueInfo(
          overdue: true,
          detail: 'Last done ${_fmt(last)}; overdue by ${-days} day(s).',
        );
      }
      if (days <= 14) {
        return _DueInfo(
          overdue: false,
          detail: 'Last done ${_fmt(last)}; due in $days day(s).',
        );
      }
      return null;
    }

    // Engine-hour style interval without a live hour meter: only flag if never done.
    if (hours != null && hours > 0 && task.lastDoneHours == null) {
      return _DueInfo(
        overdue: false,
        detail: 'Interval every $hours engine hours — log completion when done.',
      );
    }
    return null;
  }

  bool _looksStormy(String text) {
    if (text.isEmpty) return false;
    const keys = [
      'storm',
      'gale',
      'squall',
      'hurricane',
      'force 7',
      'force 8',
      'force 9',
      'rough sea',
      'heavy weather',
    ];
    return keys.any(text.contains);
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _DueInfo {
  final bool overdue;
  final String detail;
  const _DueInfo({required this.overdue, required this.detail});
}
