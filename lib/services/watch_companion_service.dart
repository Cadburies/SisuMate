import '../models/models.dart';

/// #300 — local Watch-standing companion composition (no cloud).
///
/// Builds a rotating watch schedule from crew + timed prompt checklist for
/// night ops. UI can render these; this service stays pure/offline.
class WatchSlot {
  final String crewName;
  final DateTime start;
  final DateTime end;

  const WatchSlot({
    required this.crewName,
    required this.start,
    required this.end,
  });

  Duration get length => end.difference(start);
}

class WatchPrompt {
  final String id;
  final String title;
  final Duration every;
  final String detail;

  const WatchPrompt({
    required this.id,
    required this.title,
    required this.every,
    required this.detail,
  });
}

class WatchCompanionPlan {
  final List<WatchSlot> rotation;
  final List<WatchPrompt> prompts;
  final List<String> summaryLines;

  const WatchCompanionPlan({
    required this.rotation,
    required this.prompts,
    required this.summaryLines,
  });
}

class WatchCompanionService {
  WatchCompanionService._();

  /// Default night-watch prompts (log, engine, weather glance).
  static const defaultPrompts = <WatchPrompt>[
    WatchPrompt(
      id: 'log_entry',
      title: 'Log entry due',
      every: Duration(hours: 1),
      detail: 'Position, SOG, sail plan, anything unusual.',
    ),
    WatchPrompt(
      id: 'engine_check',
      title: 'Engine / systems glance',
      every: Duration(hours: 2),
      detail: 'Temps, bilge, oil pressure if motoring; battery if silent.',
    ),
    WatchPrompt(
      id: 'weather_glance',
      title: 'Weather glance',
      every: Duration(hours: 3),
      detail: 'Sky, wind shift, barometer trend; refresh GRIB if online.',
    ),
  ];

  /// Build a simple rotating schedule: [watchLength] per crew in list order,
  /// repeating until [horizon] is covered. Empty crew → empty rotation.
  static WatchCompanionPlan build({
    required List<CrewMember> crew,
    DateTime? start,
    Duration watchLength = const Duration(hours: 3),
    Duration horizon = const Duration(hours: 12),
    List<WatchPrompt> prompts = defaultPrompts,
  }) {
    final at = (start ?? DateTime.now()).toUtc();
    final names = crew
        .map((c) => c.name.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    final rotation = <WatchSlot>[];
    if (names.isNotEmpty && watchLength.inMinutes > 0) {
      var t = at;
      final endAll = at.add(horizon);
      var i = 0;
      while (t.isBefore(endAll)) {
        final slotEnd = t.add(watchLength);
        rotation.add(WatchSlot(
          crewName: names[i % names.length],
          start: t,
          end: slotEnd.isAfter(endAll) ? endAll : slotEnd,
        ));
        t = slotEnd;
        i++;
        if (i > 48) break; // safety
      }
    }

    final lines = <String>[
      'Watch companion (offline)',
      if (names.isEmpty)
        'Add crew to build a rotation.'
      else
        'Rotation: ${names.join(' → ')} · ${watchLength.inHours}h watches',
      'Prompts: ${prompts.map((p) => p.title).join('; ')}',
      for (final s in rotation.take(8))
        '• ${_hhmm(s.start)}–${_hhmm(s.end)} ${s.crewName}',
      if (rotation.length > 8) '… ${rotation.length - 8} more slots',
    ];

    return WatchCompanionPlan(
      rotation: rotation,
      prompts: prompts,
      summaryLines: lines,
    );
  }

  static String _hhmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
