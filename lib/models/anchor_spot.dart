part of 'models.dart';

/// #328 — named anchorage catalog (not the live [AnchorWatch] alarm).
/// Local-only: weighing/dropping a watch never deletes these rows.
class AnchorSpot {
  AnchorSpot();

  int id = 0;
  String name = '';
  String comments = '';

  /// Drop coordinates. Null when a Community import stripped them.
  double? lat;
  double? lon;

  double scopeRatio = 5.0;
  double radiusMeters = 30.0;
  bool dangerZoneEnabled = false;
  double dangerZoneCenterDeg = 0.0;
  double dangerZoneWidthDeg = 60.0;
  double dangerZoneInnerRadiusMeters = 30.0;
  double dangerZoneOuterRadiusMeters = 50.0;

  /// sand / mud / grass / rock / coral / mixed / unknown
  String bottom = AnchorBottom.unknown;

  /// excellent / good / fair / poor, or empty.
  String holdingQuality = '';

  double? depthMeters;

  /// Compass sectors this cove is protected from, e.g. `['N', 'NE']`.
  List<String> windProtection = const [];

  /// sheltered / moderate / exposed, or empty.
  String swellExposure = '';

  /// beach / dock / none, or empty.
  String dinghyLanding = '';
  String dinghyNotes = '';
  String amenities = '';

  /// Local photo path (Inventory pattern). Never synced / never shared.
  String? photoPath;

  DateTime savedAt = DateTime.now().toUtc();
  DateTime lastModified = DateTime.now().toUtc();

  bool get hasCoordinates => lat != null && lon != null;

  /// Snapshot the live drop into a catalog row. Name is required by the UI.
  factory AnchorSpot.fromWatch(
    AnchorWatch watch, {
    required String name,
    String comments = '',
    double? depthMeters,
  }) =>
      AnchorSpot()
        ..name = name
        ..comments = comments
        ..lat = watch.anchorLat
        ..lon = watch.anchorLon
        ..scopeRatio = watch.scopeRatio
        ..radiusMeters = watch.radiusMeters
        ..dangerZoneEnabled = watch.dangerZoneEnabled
        ..dangerZoneCenterDeg = watch.dangerZoneCenterDeg
        ..dangerZoneWidthDeg = watch.dangerZoneWidthDeg
        ..dangerZoneInnerRadiusMeters = watch.dangerZoneInnerRadiusMeters
        ..dangerZoneOuterRadiusMeters = watch.dangerZoneOuterRadiusMeters
        ..depthMeters = depthMeters
        ..savedAt = DateTime.now().toUtc()
        ..lastModified = DateTime.now().toUtc();

  Map<String, dynamic> toJson({bool includeCoordinates = true}) => {
        'name': name,
        'comments': comments,
        if (includeCoordinates && lat != null) 'lat': lat,
        if (includeCoordinates && lon != null) 'lon': lon,
        'scopeRatio': scopeRatio,
        'radiusMeters': radiusMeters,
        'dangerZoneEnabled': dangerZoneEnabled,
        'dangerZoneCenterDeg': dangerZoneCenterDeg,
        'dangerZoneWidthDeg': dangerZoneWidthDeg,
        'dangerZoneInnerRadiusMeters': dangerZoneInnerRadiusMeters,
        'dangerZoneOuterRadiusMeters': dangerZoneOuterRadiusMeters,
        'bottom': bottom,
        if (holdingQuality.isNotEmpty) 'holdingQuality': holdingQuality,
        if (depthMeters != null) 'depthMeters': depthMeters,
        if (windProtection.isNotEmpty) 'windProtection': windProtection,
        if (swellExposure.isNotEmpty) 'swellExposure': swellExposure,
        if (dinghyLanding.isNotEmpty) 'dinghyLanding': dinghyLanding,
        if (dinghyNotes.isNotEmpty) 'dinghyNotes': dinghyNotes,
        if (amenities.isNotEmpty) 'amenities': amenities,
      };

  factory AnchorSpot.fromJson(Map<String, dynamic> json) {
    List<String> sectors() {
      final raw = json['windProtection'];
      if (raw is! List) return const [];
      return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }

    return AnchorSpot()
      ..name = (json['name'] as String?) ?? ''
      ..comments = (json['comments'] as String?) ?? ''
      ..lat = (json['lat'] as num?)?.toDouble()
      ..lon = (json['lon'] as num?)?.toDouble()
      ..scopeRatio = (json['scopeRatio'] as num?)?.toDouble() ?? 5.0
      ..radiusMeters = (json['radiusMeters'] as num?)?.toDouble() ?? 30.0
      ..dangerZoneEnabled = json['dangerZoneEnabled'] == true
      ..dangerZoneCenterDeg =
          (json['dangerZoneCenterDeg'] as num?)?.toDouble() ?? 0.0
      ..dangerZoneWidthDeg =
          (json['dangerZoneWidthDeg'] as num?)?.toDouble() ?? 60.0
      ..dangerZoneInnerRadiusMeters =
          (json['dangerZoneInnerRadiusMeters'] as num?)?.toDouble() ?? 30.0
      ..dangerZoneOuterRadiusMeters =
          (json['dangerZoneOuterRadiusMeters'] as num?)?.toDouble() ?? 50.0
      ..bottom = (json['bottom'] as String?) ?? AnchorBottom.unknown
      ..holdingQuality = (json['holdingQuality'] as String?) ?? ''
      ..depthMeters = (json['depthMeters'] as num?)?.toDouble()
      ..windProtection = sectors()
      ..swellExposure = (json['swellExposure'] as String?) ?? ''
      ..dinghyLanding = (json['dinghyLanding'] as String?) ?? ''
      ..dinghyNotes = (json['dinghyNotes'] as String?) ?? ''
      ..amenities = (json['amenities'] as String?) ?? '';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnchorSpot &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          comments == other.comments &&
          lat == other.lat &&
          lon == other.lon &&
          scopeRatio == other.scopeRatio &&
          radiusMeters == other.radiusMeters &&
          dangerZoneEnabled == other.dangerZoneEnabled &&
          dangerZoneCenterDeg == other.dangerZoneCenterDeg &&
          dangerZoneWidthDeg == other.dangerZoneWidthDeg &&
          dangerZoneInnerRadiusMeters == other.dangerZoneInnerRadiusMeters &&
          dangerZoneOuterRadiusMeters == other.dangerZoneOuterRadiusMeters &&
          bottom == other.bottom &&
          holdingQuality == other.holdingQuality &&
          depthMeters == other.depthMeters &&
          listEquals(windProtection, other.windProtection) &&
          swellExposure == other.swellExposure &&
          dinghyLanding == other.dinghyLanding &&
          dinghyNotes == other.dinghyNotes &&
          amenities == other.amenities &&
          photoPath == other.photoPath &&
          savedAt == other.savedAt &&
          lastModified == other.lastModified;

  @override
  int get hashCode => Object.hashAll([
        id,
        name,
        comments,
        lat,
        lon,
        scopeRatio,
        radiusMeters,
        dangerZoneEnabled,
        dangerZoneCenterDeg,
        dangerZoneWidthDeg,
        dangerZoneInnerRadiusMeters,
        dangerZoneOuterRadiusMeters,
        bottom,
        holdingQuality,
        depthMeters,
        Object.hashAll(windProtection),
        swellExposure,
        dinghyLanding,
        dinghyNotes,
        amenities,
        photoPath,
        savedAt,
        lastModified,
      ]);

  @override
  String toString() =>
      'AnchorSpot(id: $id, name: $name, lat: $lat, lon: $lon)';
}

abstract final class AnchorBottom {
  static const unknown = 'unknown';
  static const sand = 'sand';
  static const mud = 'mud';
  static const grass = 'grass';
  static const rock = 'rock';
  static const coral = 'coral';
  static const mixed = 'mixed';
  static const values = [unknown, sand, mud, grass, rock, coral, mixed];
}

abstract final class AnchorHolding {
  static const excellent = 'excellent';
  static const good = 'good';
  static const fair = 'fair';
  static const poor = 'poor';
  static const values = [excellent, good, fair, poor];
}

abstract final class AnchorSwell {
  static const sheltered = 'sheltered';
  static const moderate = 'moderate';
  static const exposed = 'exposed';
  static const values = [sheltered, moderate, exposed];
}

abstract final class AnchorDinghy {
  static const none = 'none';
  static const beach = 'beach';
  static const dock = 'dock';
  static const values = [none, beach, dock];
}

abstract final class AnchorWindSector {
  static const values = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
}
