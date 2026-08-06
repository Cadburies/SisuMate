import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../models/sailing_polar_sample.dart';
import '../../services/sync_service.dart';
import '../drift/app_database.dart';

/// #274/#275 — under-sail samples; anonymized push via [SyncService].
class SailingPolarSampleRepository {
  SailingPolarSampleRepository(this.db, [this.syncService]);
  final AppDatabase db;
  final SyncService? syncService;

  SailingPolarSample _toDomain(SailingPolarSampleRow r) => SailingPolarSample()
    ..id = r.id
    ..supabaseId = r.supabaseId
    ..boatSupabaseId = r.boatSupabaseId
    ..observedAt = r.observedAt
    ..sogKt = r.sogKt
    ..stwKt = r.stwKt
    ..boatSpeedKt = r.boatSpeedKt
    ..speedSource = r.speedSource
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
    ..seaState = r.seaState
    ..speedCv = r.speedCv
    ..twaStdDeg = r.twaStdDeg
    ..imuHsM = r.imuHsM
    ..imuAccelRms = r.imuAccelRms
    ..imuAccelP90 = r.imuAccelP90
    ..imuDominantPeriodS = r.imuDominantPeriodS
    ..imuSuggestedSeaState = r.imuSuggestedSeaState
    ..usedInPolarBuild = r.usedInPolarBuild
    ..isSynced = r.isSynced
    ..lastModified = r.lastModified;

  SailingPolarSamplesCompanion _companion(SailingPolarSample s) =>
      SailingPolarSamplesCompanion(
        supabaseId: Value(s.supabaseId),
        boatSupabaseId: Value(s.boatSupabaseId),
        observedAt: Value(s.observedAt),
        sogKt: Value(s.sogKt),
        stwKt: Value(s.stwKt),
        boatSpeedKt: Value(s.boatSpeedKt),
        speedSource: Value(s.speedSource),
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
        seaState: Value(s.seaState),
        speedCv: Value(s.speedCv),
        twaStdDeg: Value(s.twaStdDeg),
        imuHsM: Value(s.imuHsM),
        imuAccelRms: Value(s.imuAccelRms),
        imuAccelP90: Value(s.imuAccelP90),
        imuDominantPeriodS: Value(s.imuDominantPeriodS),
        imuSuggestedSeaState: Value(s.imuSuggestedSeaState),
        usedInPolarBuild: Value(s.usedInPolarBuild),
        isSynced: Value(s.isSynced),
        lastModified: Value(s.lastModified),
      );

  Future<int> insert(SailingPolarSample s) async {
    if (s.supabaseId.isEmpty) {
      s.supabaseId = const Uuid().v4();
    }
    s.lastModified = DateTime.now().toUtc();
    s.isSynced = false;
    final id = await db.into(db.sailingPolarSamples).insert(_companion(s));
    // #275 — anonymized wire payload (performance metrics only).
    await syncService?.queueOutgoingChange(
      'sailing_polar_samples',
      s.toSyncJson(),
    );
    return id;
  }

  Future<void> upsertFromRemote(SailingPolarSample s) async {
    final existing = await (db.select(db.sailingPolarSamples)
          ..where((t) => t.supabaseId.equals(s.supabaseId)))
        .getSingleOrNull();
    s.isSynced = true;
    final companion = _companion(s);
    if (existing == null) {
      await db.into(db.sailingPolarSamples).insert(companion);
    } else {
      await (db.update(db.sailingPolarSamples)
            ..where((t) => t.id.equals(existing.id)))
          .write(companion);
    }
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

  /// #276 — delete samples for [boatSupabaseId], optionally one [seaState] only.
  /// Queues remote deletes when sync is available.
  Future<int> deleteForBoat(
    String boatSupabaseId, {
    String? seaState,
  }) async {
    if (boatSupabaseId.isEmpty) return 0;
    final q = db.select(db.sailingPolarSamples)
      ..where((t) => t.boatSupabaseId.equals(boatSupabaseId));
    if (seaState != null) {
      q.where((t) => t.seaState.equals(seaState));
    }
    final rows = await q.get();
    if (rows.isEmpty) return 0;
    for (final r in rows) {
      if (r.supabaseId.isNotEmpty) {
        await syncService?.queueOutgoingChange(
          'sailing_polar_samples',
          {'supabaseId': r.supabaseId},
          isDelete: true,
        );
      }
    }
    await (db.delete(db.sailingPolarSamples)
          ..where((t) {
            var expr = t.boatSupabaseId.equals(boatSupabaseId);
            if (seaState != null) {
              expr = expr & t.seaState.equals(seaState);
            }
            return expr;
          }))
        .go();
    return rows.length;
  }
}
