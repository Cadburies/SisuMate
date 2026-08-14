import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/repositories/anchor_spot_repository.dart';
import '../../models/models.dart';
import '../drift/app_database.dart';

/// #328 — local-only catalog (never synced). Community publish copies a
/// snapshot into a [CommunityTemplate]; it does not stream the live GPS.
class AnchorSpotRepositoryImpl implements AnchorSpotRepository {
  final AppDatabase db;

  AnchorSpotRepositoryImpl(this.db);

  AnchorSpot _toDomain(AnchorSpotRow r) {
    List<String> sectors = const [];
    if (r.windProtectionJson.isNotEmpty) {
      try {
        final raw = jsonDecode(r.windProtectionJson);
        if (raw is List) {
          sectors = raw.map((e) => e.toString()).toList();
        }
      } catch (_) {
        // Corrupt-but-recoverable JSON — keep the rest of the row.
      }
    }
    return AnchorSpot()
      ..id = r.id
      ..name = r.name
      ..comments = r.comments
      ..lat = r.lat
      ..lon = r.lon
      ..scopeRatio = r.scopeRatio
      ..radiusMeters = r.radiusMeters
      ..dangerZoneEnabled = r.dangerZoneEnabled
      ..dangerZoneCenterDeg = r.dangerZoneCenterDeg
      ..dangerZoneWidthDeg = r.dangerZoneWidthDeg
      ..dangerZoneInnerRadiusMeters = r.dangerZoneInnerRadiusMeters
      ..dangerZoneOuterRadiusMeters = r.dangerZoneOuterRadiusMeters
      ..bottom = r.bottom
      ..holdingQuality = r.holdingQuality
      ..depthMeters = r.depthMeters
      ..windProtection = sectors
      ..swellExposure = r.swellExposure
      ..dinghyLanding = r.dinghyLanding
      ..dinghyNotes = r.dinghyNotes
      ..amenities = r.amenities
      ..photoPath = r.photoPath
      ..savedAt = r.savedAt
      ..lastModified = r.lastModified;
  }

  AnchorSpotsCompanion _toCompanion(AnchorSpot s, {required bool forInsert}) {
    return AnchorSpotsCompanion(
      id: forInsert ? const Value.absent() : Value(s.id),
      name: Value(s.name),
      comments: Value(s.comments),
      lat: Value(s.lat),
      lon: Value(s.lon),
      scopeRatio: Value(s.scopeRatio),
      radiusMeters: Value(s.radiusMeters),
      dangerZoneEnabled: Value(s.dangerZoneEnabled),
      dangerZoneCenterDeg: Value(s.dangerZoneCenterDeg),
      dangerZoneWidthDeg: Value(s.dangerZoneWidthDeg),
      dangerZoneInnerRadiusMeters: Value(s.dangerZoneInnerRadiusMeters),
      dangerZoneOuterRadiusMeters: Value(s.dangerZoneOuterRadiusMeters),
      bottom: Value(s.bottom),
      holdingQuality: Value(s.holdingQuality),
      depthMeters: Value(s.depthMeters),
      windProtectionJson: Value(jsonEncode(s.windProtection)),
      swellExposure: Value(s.swellExposure),
      dinghyLanding: Value(s.dinghyLanding),
      dinghyNotes: Value(s.dinghyNotes),
      amenities: Value(s.amenities),
      photoPath: Value(s.photoPath),
      savedAt: Value(s.savedAt),
      lastModified: Value(s.lastModified),
    );
  }

  @override
  Stream<List<AnchorSpot>> watchAll() {
    return (db.select(db.anchorSpots)
          ..orderBy([(t) => OrderingTerm.desc(t.savedAt)]))
        .watch()
        .map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<List<AnchorSpot>> getAll() async {
    final rows = await (db.select(db.anchorSpots)
          ..orderBy([(t) => OrderingTerm.desc(t.savedAt)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<AnchorSpot> save(AnchorSpot spot) async {
    spot.lastModified = DateTime.now().toUtc();
    if (spot.id == 0) {
      spot.savedAt = spot.lastModified;
      final id = await db.into(db.anchorSpots).insert(
            _toCompanion(spot, forInsert: true),
          );
      spot.id = id;
      return spot;
    }
    await (db.update(db.anchorSpots)..where((t) => t.id.equals(spot.id)))
        .write(_toCompanion(spot, forInsert: false));
    return spot;
  }

  @override
  Future<void> delete(int id) async {
    await (db.delete(db.anchorSpots)..where((t) => t.id.equals(id))).go();
  }
}
