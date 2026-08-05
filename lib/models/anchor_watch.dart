part of 'models.dart';

/// #256 — anchor watch/drag alarm. Local-only (never synced): meaningful
/// only to the device actively watching the anchor, and simplest to keep
/// that way for v1 (mirrors [ErrorLogEntry]'s local-only shape).
class AnchorWatch {
  AnchorWatch();

  int id = 0;
  double anchorLat = 0.0;
  double anchorLon = 0.0;

  /// Chain-scope ratio (chain paid out : depth), e.g. `5.0` for 5:1.
  /// Pre-filled from the Settings default at drop time, editable per-drop.
  double scopeRatio = 5.0;

  /// Geofence circle radius in meters — the authoritative alarm boundary.
  /// Suggested from depth × [scopeRatio] at drop time when depth is known,
  /// but always directly editable (the user must be able to override it
  /// regardless of how it was first computed).
  double radiusMeters = 30.0;

  bool dangerZoneEnabled = false;

  /// Center bearing of the danger-zone sector, degrees true, measured from
  /// the anchor position (0-360).
  double dangerZoneCenterDeg = 0.0;

  /// Full angular width of the danger-zone sector, degrees.
  double dangerZoneWidthDeg = 60.0;

  double dangerZoneRadiusMeters = 50.0;

  bool isActive = true;
  DateTime droppedAt = DateTime.now().toUtc();
  DateTime lastModified = DateTime.now().toUtc();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnchorWatch &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          anchorLat == other.anchorLat &&
          anchorLon == other.anchorLon &&
          scopeRatio == other.scopeRatio &&
          radiusMeters == other.radiusMeters &&
          dangerZoneEnabled == other.dangerZoneEnabled &&
          dangerZoneCenterDeg == other.dangerZoneCenterDeg &&
          dangerZoneWidthDeg == other.dangerZoneWidthDeg &&
          dangerZoneRadiusMeters == other.dangerZoneRadiusMeters &&
          isActive == other.isActive &&
          droppedAt == other.droppedAt &&
          lastModified == other.lastModified;

  @override
  int get hashCode => Object.hashAll([
        id,
        anchorLat,
        anchorLon,
        scopeRatio,
        radiusMeters,
        dangerZoneEnabled,
        dangerZoneCenterDeg,
        dangerZoneWidthDeg,
        dangerZoneRadiusMeters,
        isActive,
        droppedAt,
        lastModified,
      ]);

  @override
  String toString() => 'AnchorWatch(id: $id, anchorLat: $anchorLat, '
      'anchorLon: $anchorLon, scopeRatio: $scopeRatio, '
      'radiusMeters: $radiusMeters, dangerZoneEnabled: $dangerZoneEnabled, '
      'dangerZoneCenterDeg: $dangerZoneCenterDeg, '
      'dangerZoneWidthDeg: $dangerZoneWidthDeg, '
      'dangerZoneRadiusMeters: $dangerZoneRadiusMeters, '
      'isActive: $isActive, droppedAt: $droppedAt, '
      'lastModified: $lastModified)';
}
