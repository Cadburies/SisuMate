import 'package:drift/drift.dart';

import '../../models/sailing_polar_sample.dart';
import '../drift/app_database.dart';

/// #274 — local-only under-sail samples for polar learning.
class SailingPolarSampleRepository {
  SailingPolarSampleRepository(this.db);
  final AppDatabase db;

  SailingPolarSample _toDomain(SailingPolarSampleRow r) => SailingPolarSample()
    ..id = r.id
    ..boatSupabaseId = r.boatSupabaseId
    ..observedAt = r.observedAt
    ..sogKt = r.sogKt
    ..cogDeg = r.cogDeg
    ..twsKt = r.twsKt
    ..twdDeg = r.twdDeg
    ..twaDeg = r.twaDeg
    ..awsKt = r.awsKt
    ..awaDeg = r.awaDeg
    ..depthMeters = r.depthMeters
    ..enginePortRpm = r.enginePortRpm
    ..engineStbdRpm = r.engineStbdRpm
    ..sourceLabel = r.sourceLabel
    ..usedInPolarBuild = r.usedInPolarBuild;

  Future<int> insert(SailingPolarSample s) async {
    return db.into(db.sailingPolarSamples).insert(
          SailingPolarSamplesCompanion.insert(
            boatSupabaseId: Value(s.boatSupabaseId),
            observedAt: Value(s.observedAt),
            sogKt: Value(s.sogKt),
            cogDeg: Value(s.cogDeg),
            twsKt: Value(s.twsKt),
            twdDeg: Value(s.twdDeg),
            twaDeg: Value(s.twaDeg),
            awsKt: Value(s.awsKt),
            awaDeg: Value(s.awaDeg),
            depthMeters: Value(s.depthMeters),
            enginePortRpm: Value(s.enginePortRpm),
            engineStbdRpm: Value(s.engineStbdRpm),
            sourceLabel: Value(s.sourceLabel),
            usedInPolarBuild: Value(s.usedInPolarBuild),
          ),
        );
  }

  Future<DateTime?> lastObservedAt(String boatSupabaseId) async {
    final row = await (db.select(db.sailingPolarSamples)
          ..where((t) => t.boatSupabaseId.equals(boatSupabaseId))
          ..orderBy([(t) => OrderingTerm.desc(t.observedAt)])
          ..limit(1))
        .getSingleOrNull();
    return row?.observedAt;
  }

  Future<int> countForBoat(String boatSupabaseId) async {
    final rows = await (db.select(db.sailingPolarSamples)
          ..where((t) => t.boatSupabaseId.equals(boatSupabaseId)))
        .get();
    return rows.length;
  }

  Future<List<SailingPolarSample>> listForBoat(
    String boatSupabaseId, {
    int? limit,
    bool unusedOnly = false,
  }) async {
    final q = db.select(db.sailingPolarSamples)
      ..where((t) => t.boatSupabaseId.equals(boatSupabaseId))
      ..orderBy([(t) => OrderingTerm.desc(t.observedAt)]);
    if (unusedOnly) {
      q.where((t) => t.usedInPolarBuild.equals(false));
    }
    if (limit != null) q.limit(limit);
    final rows = await q.get();
    return rows.map(_toDomain).toList();
  }

  Future<void> markUsed(Iterable<int> ids) async {
    if (ids.isEmpty) return;
    await (db.update(db.sailingPolarSamples)
          ..where((t) => t.id.isIn(ids.toList())))
        .write(const SailingPolarSamplesCompanion(
      usedInPolarBuild: Value(true),
    ));
  }
}
