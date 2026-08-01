import '../models/models.dart';

/// Per-tank burn / range estimate (Fuel or Water). Pure offline rules over
/// fill-up logs — no sensors required.
class TankBurnEstimate {
  /// `Fuel` or `Water`.
  final String type;

  /// Average daily burn (L/day) from consecutive top-ups, if computable.
  final double? litersPerDay;

  /// Optional L/h when [hoursMotored] was provided to the estimator.
  final double? litersPerHour;

  /// Optional L/NM when [distanceNm] was provided.
  final double? litersPerNm;

  /// Estimated liters still aboard (after last full fill, decayed by burn).
  /// Null when remaining is unknown (e.g. only one fill — no burn rate yet).
  final double? estimatedRemainingLiters;

  /// Capacity used for remaining/ETA (user override or max fill).
  final double? inferredCapacityLiters;

  /// Calendar day when tanks hit empty at current burn rate.
  final DateTime? etaEmpty;

  /// Whole days until empty (floor); 0 if already empty.
  final int? daysUntilEmpty;

  /// Number of fill samples used for the rate.
  final int sampleFills;

  /// Short ASCII summary for banners.
  final String summary;

  const TankBurnEstimate({
    required this.type,
    this.litersPerDay,
    this.litersPerHour,
    this.litersPerNm,
    this.estimatedRemainingLiters,
    this.inferredCapacityLiters,
    this.etaEmpty,
    this.daysUntilEmpty,
    required this.sampleFills,
    required this.summary,
  });
}

/// BAI4: fuel/water burn estimator from fill logs (+ optional hours / distance).
///
/// Assumptions (documented for the crew, not hidden magic):
/// - Consecutive fills of the same type are treated as top-ups to full, so the
///   liters on fill *i+1* approximate consumption since fill *i*.
/// - Capacity defaults to the largest single fill of that type when not given.
/// - After the latest fill the tank is treated as full; remaining decays by the
///   (recency-weighted) daily burn until the next top-up.
/// - With fewer than 2 fills there is no burn rate, so remaining is **unknown**
///   (not "full") — a single fill cannot tell how much has been burned since.
/// - L/day uses the last [maxRateIntervals] top-up intervals, weighted so more
///   recent intervals count more (linear weights 1…n).
class FuelBurnEstimator {
  const FuelBurnEstimator();

  /// Max consecutive fill-to-fill intervals used for the L/day average.
  static const int maxRateIntervals = 6;

  /// Estimate burn for Fuel and Water from [entries].
  ///
  /// [fuelCapacityLiters] / [waterCapacityLiters] override inferred capacity.
  /// [hoursMotored] / [distanceNm] apply only to the Fuel series (engine use).
  List<TankBurnEstimate> estimate({
    required List<FuelLogEntry> entries,
    double? fuelCapacityLiters,
    double? waterCapacityLiters,
    double? hoursMotored,
    double? distanceNm,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now().toUtc();
    final out = <TankBurnEstimate>[];

    final fuel = _forType(
      type: 'Fuel',
      entries: entries,
      capacityOverride: fuelCapacityLiters,
      hoursMotored: hoursMotored,
      distanceNm: distanceNm,
      now: at,
    );
    if (fuel != null) out.add(fuel);

    final water = _forType(
      type: 'Water',
      entries: entries,
      capacityOverride: waterCapacityLiters,
      hoursMotored: null,
      distanceNm: null,
      now: at,
    );
    if (water != null) out.add(water);

    return out;
  }

  TankBurnEstimate? _forType({
    required String type,
    required List<FuelLogEntry> entries,
    double? capacityOverride,
    double? hoursMotored,
    double? distanceNm,
    required DateTime now,
  }) {
    final fills = entries
        .where((e) => e.type == type && e.liters > 0)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (fills.isEmpty) return null;

    final maxFill =
        fills.map((e) => e.liters).reduce((a, b) => a > b ? a : b);
    final capacity = (capacityOverride != null && capacityOverride > 0)
        ? capacityOverride
        : maxFill;

    double? litersPerDay;
    if (fills.length >= 2) {
      final rates = <double>[];
      for (var i = 1; i < fills.length; i++) {
        final prev = fills[i - 1];
        final cur = fills[i];
        final days = cur.date.difference(prev.date).inDays;
        final span = days < 1 ? 1.0 : days.toDouble();
        // Top-up volume ≈ consumption since previous fill (full-to-full).
        rates.add(cur.liters / span);
      }
      litersPerDay = _weightedRecentAverage(rates);
    }

    double? litersPerHour;
    double? litersPerNm;
    if (type == 'Fuel' && fills.length >= 2) {
      // Consumption window ≈ sum of top-ups after the first fill.
      final consumed = fills.skip(1).fold<double>(0, (s, e) => s + e.liters);
      if (hoursMotored != null && hoursMotored > 0) {
        litersPerHour = consumed / hoursMotored;
      }
      if (distanceNm != null && distanceNm > 0) {
        litersPerNm = consumed / distanceNm;
      }
    }

    double? remaining;
    DateTime? eta;
    int? daysLeft;
    final last = fills.last;
    final daysSinceLast = now.difference(last.date.toUtc()).inDays;
    final since = daysSinceLast < 0 ? 0 : daysSinceLast;

    if (litersPerDay != null && litersPerDay > 0) {
      remaining = (capacity - litersPerDay * since).clamp(0.0, capacity);
      if (remaining <= 0) {
        daysLeft = 0;
        eta = now;
      } else {
        final d = remaining / litersPerDay;
        daysLeft = d.floor();
        eta = now.add(Duration(days: daysLeft));
      }
    }
    // No burn rate (single fill / zero rate): remaining is unknown — not full.

    final summary = _summary(
      type: type,
      litersPerDay: litersPerDay,
      litersPerHour: litersPerHour,
      litersPerNm: litersPerNm,
      remaining: remaining,
      daysLeft: daysLeft,
      sampleFills: fills.length,
    );

    return TankBurnEstimate(
      type: type,
      litersPerDay: litersPerDay,
      litersPerHour: litersPerHour,
      litersPerNm: litersPerNm,
      estimatedRemainingLiters: remaining,
      inferredCapacityLiters: capacity,
      etaEmpty: eta,
      daysUntilEmpty: daysLeft,
      sampleFills: fills.length,
      summary: summary,
    );
  }

  /// Average of the most recent [maxRateIntervals] rates, with linear recency
  /// weights (oldest in window = 1, newest = n) so usage-pattern changes show
  /// up sooner than a flat all-time mean.
  static double? _weightedRecentAverage(List<double> ratesChronological) {
    if (ratesChronological.isEmpty) return null;
    final start = ratesChronological.length > maxRateIntervals
        ? ratesChronological.length - maxRateIntervals
        : 0;
    final window = ratesChronological.sublist(start);
    var weightedSum = 0.0;
    var weightTotal = 0.0;
    for (var i = 0; i < window.length; i++) {
      final w = (i + 1).toDouble();
      weightedSum += window[i] * w;
      weightTotal += w;
    }
    if (weightTotal <= 0) return null;
    return weightedSum / weightTotal;
  }

  String _summary({
    required String type,
    required double? litersPerDay,
    required double? litersPerHour,
    required double? litersPerNm,
    required double? remaining,
    required int? daysLeft,
    required int sampleFills,
  }) {
    if (litersPerDay == null) {
      // Single fill: capacity may be known, but remaining is not.
      return '$type: unknown remaining — log another fill '
          '($sampleFills logged)';
    }
    final parts = <String>[
      '$type: ${_fmt(litersPerDay)} L/day',
    ];
    if (litersPerHour != null) {
      parts.add('${_fmt(litersPerHour)} L/h');
    }
    if (litersPerNm != null) {
      parts.add('${_fmt(litersPerNm)} L/NM');
    }
    if (daysLeft != null) {
      if (daysLeft <= 0) {
        parts.add('tanks empty or overdue for fill');
      } else {
        parts.add('~$daysLeft day${daysLeft == 1 ? '' : 's'} to empty');
      }
    }
    if (remaining != null) {
      parts.add('${_fmt(remaining)} L est. left');
    }
    return parts.join(' · ');
  }

  static String _fmt(double v) {
    if (v >= 100) return v.toStringAsFixed(0);
    if (v >= 10) return v.toStringAsFixed(1);
    return v.toStringAsFixed(2);
  }
}
