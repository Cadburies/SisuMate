import 'dart:math' as math;

import '../models/models.dart';
import '../models/sailing_polar_sample.dart';
import 'fuel_burn_estimator.dart';

/// #301 — offline passage debrief from log, polar samples, and fuel fills.
class PassageDebriefStats {
  final DateTime? windowStart;
  final DateTime? windowEnd;
  final int logEntryCount;
  final double? milesNm;
  final double? hours;
  final double? avgSogKt;
  final int polarSampleCount;
  final Map<String, int> seaStateMix;
  final double? fuelUsedLiters;
  final double? fuelEstimateLiters;
  final int checklistCompleted;
  final int checklistTotal;
  final List<String> summaryLines;

  const PassageDebriefStats({
    this.windowStart,
    this.windowEnd,
    required this.logEntryCount,
    this.milesNm,
    this.hours,
    this.avgSogKt,
    required this.polarSampleCount,
    required this.seaStateMix,
    this.fuelUsedLiters,
    this.fuelEstimateLiters,
    required this.checklistCompleted,
    required this.checklistTotal,
    required this.summaryLines,
  });
}

class PassageDebriefService {
  PassageDebriefService._();

  /// Aggregate local stats for a time window (defaults: last 7 days).
  static PassageDebriefStats aggregate({
    required List<CaptainLogEntry> logs,
    List<SailingPolarSample> polarSamples = const [],
    List<FuelLogEntry> fuelEntries = const [],
    List<ChecklistItem> checklistItems = const [],
    DateTime? windowStart,
    DateTime? windowEnd,
    DateTime? now,
  }) {
    final at = (now ?? DateTime.now()).toUtc();
    final end = (windowEnd ?? at).toUtc();
    final start =
        (windowStart ?? end.subtract(const Duration(days: 7))).toUtc();

    final inLogs = logs.where((e) {
      final d = e.logDate.toUtc();
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList()
      ..sort((a, b) => a.logDate.compareTo(b.logDate));

    final sogs = <double>[];
    for (final e in inLogs) {
      if (e.sogKt != null && e.sogKt! > 0) sogs.add(e.sogKt!);
    }

    double? miles;
    var nmAcc = 0.0;
    var nmSegs = 0;
    for (var i = 1; i < inLogs.length; i++) {
      final a = inLogs[i - 1];
      final b = inLogs[i];
      if (a.positionLat == null ||
          a.positionLng == null ||
          b.positionLat == null ||
          b.positionLng == null) {
        continue;
      }
      nmAcc += _haversineNm(
        a.positionLat!,
        a.positionLng!,
        b.positionLat!,
        b.positionLng!,
      );
      nmSegs++;
    }
    if (nmSegs > 0) miles = nmAcc;

    final hours = end.difference(start).inMinutes / 60.0;
    final avgSog = sogs.isEmpty
        ? null
        : sogs.reduce((a, b) => a + b) / sogs.length;

    final inSamples = polarSamples.where((s) {
      final d = s.observedAt.toUtc();
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
    final seaMix = <String, int>{};
    for (final s in inSamples) {
      final k = s.seaState.isEmpty ? 'unknown' : s.seaState;
      seaMix[k] = (seaMix[k] ?? 0) + 1;
    }

    double? fuelUsed;
    final fuelIn = fuelEntries
        .where((e) =>
            e.type == 'Fuel' &&
            e.liters > 0 &&
            !e.date.toUtc().isBefore(start) &&
            !e.date.toUtc().isAfter(end))
        .toList();
    if (fuelIn.isNotEmpty) {
      fuelUsed = fuelIn.fold<double>(0, (s, e) => s + e.liters);
    }
    double? fuelEst;
    final burn = const FuelBurnEstimator().estimate(
      entries: fuelEntries,
      now: end,
    );
    final fuelSeries = burn.where((e) => e.type == 'Fuel').firstOrNull;
    if (fuelSeries?.litersPerDay != null && hours > 0) {
      fuelEst = fuelSeries!.litersPerDay! * (hours / 24.0);
    }

    final visible = checklistItems.where((i) => !i.isHidden).toList();
    final done = visible.where((i) => i.isCompleted).length;

    final lines = <String>[
      'Passage debrief (offline) · ${_fmt(start)} → ${_fmt(end)}',
      'Log entries: ${inLogs.length}',
      if (miles != null)
        'Distance (from positions): ${miles.toStringAsFixed(1)} NM',
      if (avgSog != null) 'Avg SOG (logged): ${avgSog.toStringAsFixed(1)} kn',
      'Window length: ${hours.toStringAsFixed(1)} h',
      'Polar samples: ${inSamples.length}'
          '${seaMix.isEmpty ? '' : ' · sea-state mix: ${seaMix.entries.map((e) => '${e.key}:${e.value}').join(', ')}'}',
      if (fuelUsed != null)
        'Fuel top-ups in window: ${fuelUsed.toStringAsFixed(1)} L'
            '${fuelEst != null ? ' · est. burn ~${fuelEst.toStringAsFixed(1)} L' : ''}',
      if (visible.isNotEmpty) 'Checklists: $done / ${visible.length} complete',
    ];

    return PassageDebriefStats(
      windowStart: start,
      windowEnd: end,
      logEntryCount: inLogs.length,
      milesNm: miles,
      hours: hours,
      avgSogKt: avgSog,
      polarSampleCount: inSamples.length,
      seaStateMix: seaMix,
      fuelUsedLiters: fuelUsed,
      fuelEstimateLiters: fuelEst,
      checklistCompleted: done,
      checklistTotal: visible.length,
      summaryLines: lines,
    );
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static double _haversineNm(
      double lat1, double lon1, double lat2, double lon2) {
    const rNm = 3440.065;
    final p1 = lat1 * math.pi / 180;
    final p2 = lat2 * math.pi / 180;
    final dP = (lat2 - lat1) * math.pi / 180;
    final dL = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dP / 2) * math.sin(dP / 2) +
        math.cos(p1) * math.cos(p2) * math.sin(dL / 2) * math.sin(dL / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return rNm * c;
  }
}
