import '../data/repositories/sailing_polar_sample_repository.dart';
import '../models/sailing_polar_sample.dart';
import 'polar_sample_eligibility.dart';
import 'predictwind_datahub_service.dart';

/// #274/#275 — accept instrument readings; store under-sail samples when
/// eligibility passes (engines not showing revs; STW preferred over SOG).
class SailingPolarCollector {
  SailingPolarCollector(this._repo);
  final SailingPolarSampleRepository _repo;

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

    final last = await _repo.lastObservedAt(boatSupabaseId);
    if (!PolarSampleEligibility.enoughTimeSince(last, sample.observedAt)) {
      return false;
    }

    await _repo.insert(sample);
    return true;
  }

  Future<int> sampleCount(String boatSupabaseId) =>
      _repo.countForBoat(boatSupabaseId);

  Future<List<SailingPolarSample>> recent(
    String boatSupabaseId, {
    int limit = 500,
  }) =>
      _repo.listForBoat(boatSupabaseId, limit: limit);
}
