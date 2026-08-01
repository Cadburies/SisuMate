import '../core/units.dart';
import '../models/models.dart';
import 'fuel_burn_estimator.dart';
import 'weather_service.dart';

/// Offline-rules suggestions (S4). No LLM required — pure deterministic rules
/// over local Drift data. Optional weather/log cues when present.
enum SuggestionSeverity { info, watch, urgent }

/// BAI1: single go/no-go verdict for the home screen, distinct from the
/// scrolling tip list [SuggestionEngine.build] — combines safety checklist
/// completion, maintenance overdue, cached weather, and fuel/water runway
/// into "Ready" or a short list of things to fix first.
enum ReadinessStatus { ready, needsAttention }

class PassageReadiness {
  final ReadinessStatus status;
  final List<String> blockers;
  const PassageReadiness({required this.status, required this.blockers});

  bool get isReady => status == ReadinessStatus.ready;

  String get headline => isReady
      ? 'Ready for passage'
      : 'Fix ${blockers.length} thing${blockers.length == 1 ? '' : 's'} first';
}

/// BAI3: one checklist group the autopilot thinks is worth running now,
/// with a short human reason.
class ChecklistAutopilotSuggestion {
  final ChecklistGroup group;
  final String reason;
  const ChecklistAutopilotSuggestion({required this.group, required this.reason});
}

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

  /// Days without a captain's log before [build] suggests writing one (BAI7).
  static const int logStaleDays = 14;

  /// Tank runway (days) at or below which [build] surfaces a fuel/water tip.
  static const int fuelWatchDays = 5;

  List<BoatSuggestion> build({
    required List<MaintenanceTask> maintenanceTasks,
    DateTime? now,
    /// Recent captain-log weather strings (free text), newest first.
    List<String> recentWeatherNotes = const [],
    /// Optional current wind speed (knots) if weather module has a reading.
    double? windKnots,
    /// BAI7: most recent captain-log date (any boat), if any exist.
    DateTime? lastLogDate,
    /// BAI7: optional fuel/water runway estimates (same shape as readiness).
    List<TankBurnEstimate> fuelEstimates = const [],
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

    // BAI7: fog / low visibility cues from free-text log notes.
    if (_looksFoggy(weatherBlob)) {
      out.add(const BoatSuggestion(
        id: 'wx_fog',
        title: 'Low visibility noted',
        detail: 'Recent log mentions fog or poor visibility — confirm nav lights, '
            'radar/AIS if fitted, and a sound signal plan.',
        severity: SuggestionSeverity.watch,
        routePath: '/weather',
      ));
    }

    // BAI7: lightning / thunderstorm cues (distinct from generic gale).
    if (_looksElectric(weatherBlob)) {
      out.add(const BoatSuggestion(
        id: 'wx_lightning',
        title: 'Thunderstorm risk noted',
        detail: 'Recent log mentions lightning or thunder — avoid mast work, '
            'unplug shore power if storming, and review crew shelter plan.',
        severity: SuggestionSeverity.watch,
        routePath: '/safety',
      ));
    }

    // BAI7: stale or missing captain's log.
    final logTip = _logStaleTip(lastLogDate, at);
    if (logTip != null) out.add(logTip);

    // BAI7: fuel/water runway watch (milder than passage-readiness blockers).
    for (final e in fuelEstimates) {
      final days = e.daysUntilEmpty;
      if (days == null || days > fuelWatchDays) continue;
      out.add(BoatSuggestion(
        id: 'fuel_${e.type.toLowerCase()}',
        title: days <= 2
            ? '${e.type} nearly empty'
            : '${e.type} running low',
        detail: 'Estimated ~$days day${days == 1 ? '' : 's'} of ${e.type.toLowerCase()} '
            'left from recent fills — top up before a longer passage.',
        severity: days <= 2 ? SuggestionSeverity.urgent : SuggestionSeverity.watch,
        routePath: '/fuel',
      ));
    }

    // Stable order: urgent first, then watch, then info; cap list.
    out.sort((a, b) => b.severity.index.compareTo(a.severity.index));
    if (out.length > 8) return out.sublist(0, 8);
    return out;
  }

  BoatSuggestion? _logStaleTip(DateTime? lastLogDate, DateTime at) {
    if (lastLogDate == null) {
      return const BoatSuggestion(
        id: 'log_missing',
        title: 'No captain\'s log yet',
        detail: 'Start a short entry after each passage — weather and position '
            'notes power offline tips later.',
        severity: SuggestionSeverity.info,
        routePath: '/logbook',
      );
    }
    final last = lastLogDate.toUtc();
    final days = at.difference(last).inDays;
    if (days < logStaleDays) return null;
    return BoatSuggestion(
      id: 'log_stale',
      title: 'Captain\'s log is $days days old',
      detail: 'Last entry ${_fmt(last)}. A quick log keeps weather/maintenance '
          'tips honest when you are offline.',
      severity: SuggestionSeverity.info,
      routePath: '/logbook',
    );
  }

  /// BAI1: "Ready for passage?" verdict. Reuses the same overdue detection
  /// as [build] so the two never disagree about what counts as overdue.
  PassageReadiness passageReadiness({
    required List<ChecklistItem> safetyItems,
    required List<MaintenanceTask> maintenanceTasks,
    WeatherBundle? weather,
    List<TankBurnEstimate> fuelEstimates = const [],
    DateTime? now,
  }) {
    final at = now ?? DateTime.now().toUtc();
    final blockers = <String>[];

    final uncheckedSafety =
        safetyItems.where((i) => !i.isHidden && !i.isCompleted).length;
    if (uncheckedSafety > 0) {
      blockers.add('$uncheckedSafety safety item'
          '${uncheckedSafety == 1 ? '' : 's'} not checked off');
    }

    final overdueMaint = maintenanceTasks.where((t) {
      if (t.isHidden) return false;
      return _dueInfo(t, at)?.overdue ?? false;
    }).length;
    if (overdueMaint > 0) {
      blockers.add('$overdueMaint maintenance task'
          '${overdueMaint == 1 ? '' : 's'} overdue');
    }

    final windMs = weather?.windMs;
    if (windMs != null) {
      final windKn = windMs / UnitConverter.msPerKnot;
      if (windKn >= 25) {
        blockers.add('Cached forecast shows ${windKn.round()} kn wind — '
            'recheck before departure');
      }
    }

    for (final e in fuelEstimates) {
      final days = e.daysUntilEmpty;
      if (days != null && days <= 2) {
        blockers.add('${e.type} estimated $days day${days == 1 ? '' : 's'} '
            'from empty');
      }
    }

    return PassageReadiness(
      status:
          blockers.isEmpty ? ReadinessStatus.ready : ReadinessStatus.needsAttention,
      blockers: blockers,
    );
  }

  /// BAI3: which checklists to run next, from days-until-departure, trip
  /// length, and cached weather. Matches by keyword against whatever
  /// checklist titles the boat actually has (bundled or custom) — no schema
  /// change, same style as [_looksStormy] above. Nothing is suggested twice
  /// even if it matches more than one rule.
  List<ChecklistAutopilotSuggestion> checklistAutopilot({
    required List<ChecklistGroup> checklistGroups,
    int? daysUntilDeparture,
    int? tripLengthDays,
    WeatherBundle? weather,
  }) {
    final out = <ChecklistAutopilotSuggestion>[];
    final suggested = <String>{};

    void suggest(String keyword, String reason) {
      final group = checklistGroups
          .where((g) =>
              !g.isHidden && g.title.toLowerCase().contains(keyword))
          .firstOrNull;
      if (group == null) return;
      if (!suggested.add(group.supabaseId)) return; // already suggested
      out.add(ChecklistAutopilotSuggestion(group: group, reason: reason));
    }

    // Nothing trip-specific to say without a known departure.
    if (daysUntilDeparture != null) {
      if (daysUntilDeparture <= 1) {
        suggest('last minute', 'Departing very soon');
        suggest('one day', 'Departing very soon');
      } else if (daysUntilDeparture <= 7) {
        suggest('one week', 'Departing within a week');
      }
      suggest('document', 'Good to review before any departure');
    }

    final windMs = weather?.windMs;
    if (windMs != null && windMs / UnitConverter.msPerKnot >= 25) {
      suggest('last minute', 'Rough weather ahead — recheck before you leave');
    }

    if (tripLengthDays != null && tripLengthDays > 1) {
      suggest('watch', 'Multi-day passage — plan watch monitoring');
    }

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

  bool _looksFoggy(String text) {
    if (text.isEmpty) return false;
    const keys = [
      'fog',
      'foggy',
      'mist',
      'low visibility',
      'poor visibility',
      'visibility zero',
      'haar',
    ];
    return keys.any(text.contains);
  }

  bool _looksElectric(String text) {
    if (text.isEmpty) return false;
    const keys = [
      'lightning',
      'thunder',
      'thunderstorm',
      'electrical storm',
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
