import '../data/repositories/sailing_polar_sample_repository.dart';
import '../models/sailing_polar_sample.dart';
import '../models/sea_state.dart';
import 'polar_sample_eligibility.dart';
import 'predictwind_datahub_service.dart';
import 'sea_state_estimator.dart';

/// #274/#275/#276 — accept instrument readings; store under-sail samples when
/// eligibility + steady-state pass. Maintains a rolling window for sea-state
/// estimation (instrument variance) and live UI.
class SailingPolarCollector {
  SailingPolarCollector(this._repo);
  final SailingPolarSampleRepository _repo;

  /// Per-boat rolling instrument windows for sea-state / steady-state.
  final Map<String, List<InstrumentReading>> _windows = {};

  SeaState _lastSeaState = SeaState.unknown;
  SeaStateMetrics? _lastMetrics;

  /// Latest estimated sea state (for polar chart chip).
  SeaState get currentSeaState => _lastSeaState;

  SeaStateMetrics? get lastMetrics => _lastMetrics;

  /// Returns true if a new row was stored.
  Future<bool> maybeRecord({
    required PredictWindBoatData data,
    required String boatSupabaseId,
    double? enginePortRpm,
    double? engineStbdRpm,
  }) async {
    final sample = PolarSampleEligibility.tryBuild(
      data: data,
      boatSupabaseId: boatSupabaseId,
      enginePortRpm: enginePortRpm ?? data.enginePortRpm,
      engineStbdRpm: engineStbdRpm ?? data.engineStbdRpm,
    );
    if (sample == null) return false;

    final reading = InstrumentReading(
      at: sample.observedAt,
      boatSpeedKt: sample.boatSpeedKt,
      twaDeg: sample.twaDeg,
      twsKt: sample.twsKt,
      sogKt: sample.sogKt,
      stwKt: sample.stwKt,
    );

    final window = _windows.putIfAbsent(boatSupabaseId, () => <InstrumentReading>[]);
    window.add(reading);
    while (window.length > SeaStateEstimator.maxWindow) {
      window.removeAt(0);
    }

    final metrics = SeaStateEstimator.evaluate(window);
    _lastMetrics = metrics;
    _lastSeaState = metrics.seaState;

    // #276 — reject hard turns / accel (still update sea-state window).
    if (!SeaStateEstimator.isSteadyState(window)) {
      return false;
    }

    sample.seaState = metrics.seaState.wireValue;
    sample.speedCv = metrics.speedCv;
    sample.twaStdDeg = metrics.twaStdDeg;

    final last = await _repo.lastObservedAt(boatSupabaseId);
    if (!PolarSampleEligibility.enoughTimeSince(last, sample.observedAt)) {
      return false;
    }

    await _repo.insert(sample);
    return true;
  }

  /// Push a reading for sea-state UI without requiring full eligibility
  /// (e.g. motorsailing) — only updates the window + currentSeaState.
  void observeForSeaState({
    required String boatSupabaseId,
    required double boatSpeedKt,
    required double twaDeg,
    required double twsKt,
    double? sogKt,
    double? stwKt,
    DateTime? at,
  }) {
    if (boatSupabaseId.isEmpty || boatSpeedKt <= 0) return;
    final reading = InstrumentReading(
      at: (at ?? DateTime.now()).toUtc(),
      boatSpeedKt: boatSpeedKt,
      twaDeg: twaDeg,
      twsKt: twsKt,
      sogKt: sogKt,
      stwKt: stwKt,
    );
    final window =
        _windows.putIfAbsent(boatSupabaseId, () => <InstrumentReading>[]);
    window.add(reading);
    while (window.length > SeaStateEstimator.maxWindow) {
      window.removeAt(0);
    }
    final metrics = SeaStateEstimator.evaluate(window);
    _lastMetrics = metrics;
    _lastSeaState = metrics.seaState;
  }

  Future<int> sampleCount(String boatSupabaseId) =>
      _repo.countForBoat(boatSupabaseId);

  Future<Map<String, int>> sampleCountsBySeaState(String boatSupabaseId) async {
    final all = await _repo.listForBoat(boatSupabaseId, limit: 10000);
    final counts = <String, int>{
      for (final s in SeaState.chartOrder) s.wireValue: 0,
      SeaState.unknown.wireValue: 0,
    };
    for (final s in all) {
      counts[s.seaState] = (counts[s.seaState] ?? 0) + 1;
    }
    return counts;
  }

  Future<List<SailingPolarSample>> recent(
    String boatSupabaseId, {
    int limit = 500,
  }) =>
      _repo.listForBoat(boatSupabaseId, limit: limit);
}
