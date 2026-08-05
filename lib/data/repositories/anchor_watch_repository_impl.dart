import 'package:drift/drift.dart';
import '../../domain/repositories/anchor_watch_repository.dart';
import '../../models/models.dart';
import '../drift/app_database.dart';

/// AnchorWatch on Drift (#256). Local-only — never synced.
class AnchorWatchRepositoryImpl implements AnchorWatchRepository {
  final AppDatabase db;

  AnchorWatchRepositoryImpl(this.db);

  AnchorWatch _toDomain(AnchorWatchRow r) => AnchorWatch()
    ..id = r.id
    ..anchorLat = r.anchorLat
    ..anchorLon = r.anchorLon
    ..scopeRatio = r.scopeRatio
    ..radiusMeters = r.radiusMeters
    ..dangerZoneEnabled = r.dangerZoneEnabled
    ..dangerZoneCenterDeg = r.dangerZoneCenterDeg
    ..dangerZoneWidthDeg = r.dangerZoneWidthDeg
    ..dangerZoneRadiusMeters = r.dangerZoneRadiusMeters
    ..isActive = r.isActive
    ..droppedAt = r.droppedAt
    ..lastModified = r.lastModified;

  AnchorWatchesCompanion _toCompanion(AnchorWatch w) => AnchorWatchesCompanion(
        anchorLat: Value(w.anchorLat),
        anchorLon: Value(w.anchorLon),
        scopeRatio: Value(w.scopeRatio),
        radiusMeters: Value(w.radiusMeters),
        dangerZoneEnabled: Value(w.dangerZoneEnabled),
        dangerZoneCenterDeg: Value(w.dangerZoneCenterDeg),
        dangerZoneWidthDeg: Value(w.dangerZoneWidthDeg),
        dangerZoneRadiusMeters: Value(w.dangerZoneRadiusMeters),
        isActive: Value(w.isActive),
        droppedAt: Value(w.droppedAt),
        lastModified: Value(w.lastModified),
      );

  @override
  Stream<AnchorWatch?> watchActive() {
    return (db.select(db.anchorWatches)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.droppedAt)])
          ..limit(1))
        .watchSingleOrNull()
        .map((row) => row == null ? null : _toDomain(row));
  }

  @override
  Future<AnchorWatch> dropAnchor(AnchorWatch watch) async {
    return db.transaction(() async {
      await (db.update(db.anchorWatches)..where((t) => t.isActive.equals(true)))
          .write(const AnchorWatchesCompanion(isActive: Value(false)));
      watch.lastModified = DateTime.now().toUtc();
      final id = await db.into(db.anchorWatches).insert(_toCompanion(watch));
      watch.id = id;
      return watch;
    });
  }

  @override
  Future<void> updateWatch(AnchorWatch watch) async {
    watch.lastModified = DateTime.now().toUtc();
    await (db.update(db.anchorWatches)..where((t) => t.id.equals(watch.id)))
        .write(_toCompanion(watch));
  }

  @override
  Future<void> weighAnchor(int id) async {
    await (db.update(db.anchorWatches)..where((t) => t.id.equals(id))).write(
      AnchorWatchesCompanion(
        isActive: const Value(false),
        lastModified: Value(DateTime.now().toUtc()),
      ),
    );
  }
}
