import 'dart:async' show unawaited;
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/di.dart';
import '../../models/models.dart';
import '../../services/anchor_alarm_service.dart';
import '../../services/boat_polar_service.dart' show bearingDeg;
import '../../services/map_tile_cache_service.dart';
import '../../services/map_tile_providers.dart';
import '../../services/weather_routing_service.dart' show destinationPoint;
import '../weather/caching_tile_provider.dart';

/// #268 — under `flutter test`, TileLayer ImageStreams deadlock dispose.
bool get _underFlutterTest =>
    Platform.environment.containsKey('FLUTTER_TEST');

/// #256 follow-up — a satellite/chart view of the anchorage, zoomed to a
/// fixed ~300m radius, with the geofence circle and danger-zone sector
/// drawn as real overlays the user can tap-and-drag directly (not just
/// edit via the sliders in [AnchorAlarmScreen]'s other cards, which stay
/// as the precise-numeric-entry alternative).
///
/// Drag handles are plain [Positioned] + [GestureDetector] pairs
/// (flutter_map has no built-in draggable-marker widget) repositioned via
/// [MapCamera.latLngToScreenOffset]/[screenOffsetToLatLng] — the package's
/// own documented seam for exactly this ("convert a latLng to a position we
/// could use with a widget outside of FlutterMap layer space") — converted
/// back from a drag via [RenderBox.globalToLocal] on each frame (#261:
/// recomputing the drag's reference position from the handle's own
/// already-moved point compounds into a runaway feedback loop; using the
/// pointer's true global position every frame avoids it):
/// - the anchor itself (moves the anchor position — same effect as the
///   "Edit position" dialog),
/// - the geofence circle's edge (due east of the anchor — drag changes
///   only the radius; #273 also pins the danger-zone outer edge to this),
/// - when the danger zone is on (#262 ring segment on the geofence, not a
///   pie from the anchor): its **inner** tip (bearing + inner radius) and
///   its arc-width edge on the geofence perimeter. Outer radius is not
///   independently draggable (#273).
///
/// While any handle is actively being dragged, the map's own one-finger
/// pan gesture is disabled (`InteractiveFlag.drag` off) so it can't steal
/// the pointer from the handle — pinch-zoom stays available throughout.
class AnchorChartMap extends ConsumerStatefulWidget {
  final AnchorWatch activeWatch;
  final double? boatLat;
  final double? boatLon;
  /// #304 — when set, geofence radius drags also update [AnchorWatch.scopeRatio].
  final double? depthMeters;
  const AnchorChartMap({
    super.key,
    required this.activeWatch,
    required this.boatLat,
    required this.boatLon,
    this.depthMeters,
  });

  @override
  ConsumerState<AnchorChartMap> createState() => _AnchorChartMapState();
}

class _AnchorChartMapState extends ConsumerState<AnchorChartMap> {
  static const _alarmService = AnchorAlarmService();
  static const _viewRadiusMeters = 300.0;
  static const _handleMinMeters = 5.0;
  static const _handleMaxMeters = 280.0; // stays inside the 300m view

  late final MapController _mapController;
  final _mapAreaKey = GlobalKey();
  late double _anchorLat;
  late double _anchorLon;
  late double _radiusMeters;
  late double _dangerCenterDeg;
  late double _dangerWidthDeg;
  late double _dangerInnerRadiusMeters;
  late double _dangerOuterRadiusMeters;
  bool _dragging = false;
  /// #265 — which handle is armed after long-press (null = map pan free).
  String? _armedHandleId;
  /// #264 — same SharedPreferences key as Weather so basemap choice is shared.
  String _tileProviderId = 'esri_world_imagery';
  /// Per-screen instance is fine: [MapTileCacheService] is disk-keyed under
  /// a shared folder (no in-memory tile map that must be singleton). Weather
  /// keeps its own instance the same way — both point at the same on-disk tree.
  final _tileCacheService = MapTileCacheService();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _syncFromWatch();
    unawaited(_restoreBasemapPreference());
  }

  Future<void> _restoreBasemapPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(kMapTileProviderIdPrefKey);
    if (saved == null || !mounted) return;
    // Only accept known basemap ids (ignore overlay-only ids like seamarks).
    final known = mapTileBaseProviders.any((p) => p.id == saved);
    if (!known) return;
    setState(() => _tileProviderId = saved);
  }

  Future<void> _setBasemap(String id) async {
    setState(() => _tileProviderId = id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kMapTileProviderIdPrefKey, id);
  }

  @override
  void didUpdateWidget(covariant AnchorChartMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // #304 — pull radius/anchor/danger changes from the scope sliders while
    // not mid-handle-drag (dragging owns local geometry until persist).
    if (_dragging) return;
    final old = oldWidget.activeWatch;
    final next = widget.activeWatch;
    if (old.id != next.id ||
        old.anchorLat != next.anchorLat ||
        old.anchorLon != next.anchorLon ||
        old.radiusMeters != next.radiusMeters ||
        old.dangerZoneCenterDeg != next.dangerZoneCenterDeg ||
        old.dangerZoneWidthDeg != next.dangerZoneWidthDeg ||
        old.dangerZoneInnerRadiusMeters != next.dangerZoneInnerRadiusMeters ||
        old.dangerZoneEnabled != next.dangerZoneEnabled) {
      _syncFromWatch();
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _syncFromWatch() {
    _anchorLat = widget.activeWatch.anchorLat;
    _anchorLon = widget.activeWatch.anchorLon;
    _radiusMeters = widget.activeWatch.radiusMeters;
    _dangerCenterDeg = widget.activeWatch.dangerZoneCenterDeg;
    _dangerWidthDeg = widget.activeWatch.dangerZoneWidthDeg;
    _dangerInnerRadiusMeters = widget.activeWatch.dangerZoneInnerRadiusMeters;
    // #273 — outer radius is pinned to the geofence (not independently set).
    _dangerOuterRadiusMeters = _radiusMeters;
    if (_dangerInnerRadiusMeters >= _dangerOuterRadiusMeters) {
      _dangerInnerRadiusMeters =
          (_dangerOuterRadiusMeters - 5).clamp(_handleMinMeters, _handleMaxMeters);
    }
  }

  LatLngBounds get _viewBounds {
    final n = destinationPoint(
        lat: _anchorLat, lon: _anchorLon, bearingDeg: 0, distanceNm: _viewRadiusMeters / 1852);
    final s = destinationPoint(
        lat: _anchorLat, lon: _anchorLon, bearingDeg: 180, distanceNm: _viewRadiusMeters / 1852);
    final e = destinationPoint(
        lat: _anchorLat, lon: _anchorLon, bearingDeg: 90, distanceNm: _viewRadiusMeters / 1852);
    final w = destinationPoint(
        lat: _anchorLat, lon: _anchorLon, bearingDeg: 270, distanceNm: _viewRadiusMeters / 1852);
    return LatLngBounds(LatLng(s.lat, w.lon), LatLng(n.lat, e.lon));
  }

  Future<void> _persist() async {
    // #273 — always store outer == geofence radius so the column stays
    // consistent without a schema drop (still used by isInDangerZone).
    // #304 — when live depth is known, keep scope ratio matched to radius.
    var scopeRatio = widget.activeWatch.scopeRatio;
    final depth = widget.depthMeters;
    if (depth != null && depth > 0) {
      final next = _alarmService.scopeFromRadius(
        radiusMeters: _radiusMeters,
        depthMeters: depth,
      );
      if (next != null) scopeRatio = next;
    }
    final updated = widget.activeWatch
      ..anchorLat = _anchorLat
      ..anchorLon = _anchorLon
      ..radiusMeters = _radiusMeters
      ..scopeRatio = scopeRatio
      ..dangerZoneCenterDeg = _dangerCenterDeg
      ..dangerZoneWidthDeg = _dangerWidthDeg
      ..dangerZoneInnerRadiusMeters = _dangerInnerRadiusMeters
      ..dangerZoneOuterRadiusMeters = _radiusMeters;
    await ref.read(anchorWatchRepositoryProvider).updateWatch(updated);
  }

  @override
  Widget build(BuildContext context) {
    final anchorPoint = LatLng(_anchorLat, _anchorLon);
    final tileConfig = mapTileProviderById(_tileProviderId);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 360,
        child: Stack(
          key: _mapAreaKey,
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCameraFit: CameraFit.bounds(
                  bounds: _viewBounds,
                  padding: const EdgeInsets.all(24),
                ),
                interactionOptions: InteractionOptions(
                  flags: _dragging
                      ? InteractiveFlag.all & ~InteractiveFlag.drag
                      : InteractiveFlag.all,
                ),
              ),
              children: [
                // #268 — omit TileLayer under flutter_test (ImageStream dispose
                // deadlock). #264 — production uses the same CachingTileProvider
                // + disk cache folder as Weather so tiles share across modules.
                if (!_underFlutterTest)
                  TileLayer(
                    urlTemplate: tileConfig.urlTemplate,
                    userAgentPackageName: 'com.sisumate.app',
                    tileProvider: CachingTileProvider(
                      providerId: _tileProviderId,
                      cacheService: _tileCacheService,
                    ),
                  ),
                CircleLayer(circles: [
                  CircleMarker(
                    point: anchorPoint,
                    radius: _radiusMeters,
                    useRadiusInMeter: true,
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderColor: Colors.blue,
                    borderStrokeWidth: 2,
                  ),
                ]),
                if (widget.activeWatch.dangerZoneEnabled)
                  PolygonLayer(polygons: [
                    Polygon(
                      points: _sectorPoints(),
                      color: Colors.red.withValues(alpha: 0.18),
                      borderColor: Colors.red,
                      borderStrokeWidth: 2,
                    ),
                  ]),
                MarkerLayer(markers: [
                  if (widget.boatLat != null && widget.boatLon != null)
                    Marker(
                      point: LatLng(widget.boatLat!, widget.boatLon!),
                      width: 28,
                      height: 28,
                      child: const Icon(Icons.directions_boat,
                          color: Colors.white, shadows: [
                        Shadow(color: Colors.black, blurRadius: 4),
                      ]),
                    ),
                ]),
              ],
            ),
            StreamBuilder<MapEvent>(
              stream: _mapController.mapEventStream,
              builder: (context, _) {
                final camera = _mapController.camera;
                return Stack(
                  children: [
                    _handle(
                      id: 'anchor',
                      camera: camera,
                      point: anchorPoint,
                      icon: Icons.anchor,
                      color: Colors.white,
                      onDragUpdate: (newPoint) => setState(() {
                        _anchorLat = newPoint.latitude;
                        _anchorLon = newPoint.longitude;
                      }),
                    ),
                    _handle(
                      id: 'geofence',
                      camera: camera,
                      point: _geofenceHandlePoint(),
                      icon: Icons.radio_button_unchecked,
                      color: Colors.blue,
                      onDragUpdate: (newPoint) => setState(() {
                        _radiusMeters = _alarmService
                            .distanceMeters(
                              lat1: _anchorLat,
                              lon1: _anchorLon,
                              lat2: newPoint.latitude,
                              lon2: newPoint.longitude,
                            )
                            .clamp(_handleMinMeters, _handleMaxMeters);
                        // #273 — outer ring edge tracks the geofence.
                        _dangerOuterRadiusMeters = _radiusMeters;
                        if (_dangerInnerRadiusMeters >= _radiusMeters) {
                          _dangerInnerRadiusMeters =
                              (_radiusMeters - 5).clamp(_handleMinMeters, _handleMaxMeters);
                        }
                      }),
                    ),
                    if (widget.activeWatch.dangerZoneEnabled) ...[
                      // #273 — outer radius is the geofence (no separate outer
                      // handle). Inner tip sets bearing *and* inner radius
                      // (clock-hand control the outer tip used to own).
                      _handle(
                        id: 'danger_inner',
                        camera: camera,
                        point: _dangerInnerHandlePoint(),
                        icon: Icons.remove_circle_outline,
                        color: Colors.orange,
                        onDragUpdate: (newPoint) => setState(() {
                          _dangerCenterDeg = bearingDeg(
                              _anchorLat, _anchorLon, newPoint.latitude, newPoint.longitude);
                          final dragged = _alarmService.distanceMeters(
                            lat1: _anchorLat,
                            lon1: _anchorLon,
                            lat2: newPoint.latitude,
                            lon2: newPoint.longitude,
                          );
                          // Outer is the geofence; keep a 5m ring thickness.
                          _dangerInnerRadiusMeters = dragged.clamp(
                              _handleMinMeters, _radiusMeters - 5);
                        }),
                      ),
                      // Width edge sits on the geofence perimeter; drag
                      // changes only angular width, center bearing fixed.
                      _handle(
                        id: 'danger_edge',
                        camera: camera,
                        point: _dangerEdgeHandlePoint(),
                        icon: Icons.unfold_more,
                        color: Colors.redAccent,
                        onDragUpdate: (newPoint) => setState(() {
                          final bearing = bearingDeg(
                              _anchorLat, _anchorLon, newPoint.latitude, newPoint.longitude);
                          _dangerWidthDeg =
                              (2 * _alarmService.angleDiff(bearing, _dangerCenterDeg).abs())
                                  .clamp(10, 180);
                        }),
                      ),
                    ],
                  ],
                );
              },
            ),
            Positioned(
              top: 8,
              right: 8,
              child: _BasemapSwitcher(
                current: _tileProviderId,
                onChanged: _setBasemap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  LatLng _geofenceHandlePoint() {
    final p = destinationPoint(
      lat: _anchorLat,
      lon: _anchorLon,
      bearingDeg: 90,
      distanceNm: _radiusMeters / 1852,
    );
    return LatLng(p.lat, p.lon);
  }

  LatLng _dangerInnerHandlePoint() {
    final p = destinationPoint(
      lat: _anchorLat,
      lon: _anchorLon,
      bearingDeg: _dangerCenterDeg,
      distanceNm: _dangerInnerRadiusMeters / 1852,
    );
    return LatLng(p.lat, p.lon);
  }

  LatLng _dangerEdgeHandlePoint() {
    // #273 — outer arc is the geofence perimeter.
    final p = destinationPoint(
      lat: _anchorLat,
      lon: _anchorLon,
      bearingDeg: _dangerCenterDeg + _dangerWidthDeg / 2,
      distanceNm: _radiusMeters / 1852,
    );
    return LatLng(p.lat, p.lon);
  }

  /// #262 — an annular ring segment (pie slice with a hole), not a pie
  /// slice from the anchor: walks the inner arc left-to-right at
  /// [_dangerInnerRadiusMeters], then the outer arc right-to-left at
  /// the geofence ([_radiusMeters] / #273), closing the ring.
  List<LatLng> _sectorPoints() {
    final points = <LatLng>[];
    final start = _dangerCenterDeg - _dangerWidthDeg / 2;
    final steps = math.max(2, (_dangerWidthDeg / 5).ceil());
    for (var i = 0; i <= steps; i++) {
      final bearing = start + _dangerWidthDeg * i / steps;
      final p = destinationPoint(
        lat: _anchorLat,
        lon: _anchorLon,
        bearingDeg: bearing,
        distanceNm: _dangerInnerRadiusMeters / 1852,
      );
      points.add(LatLng(p.lat, p.lon));
    }
    for (var i = steps; i >= 0; i--) {
      final bearing = start + _dangerWidthDeg * i / steps;
      final p = destinationPoint(
        lat: _anchorLat,
        lon: _anchorLon,
        bearingDeg: bearing,
        distanceNm: _radiusMeters / 1852,
      );
      points.add(LatLng(p.lat, p.lon));
    }
    return points;
  }

  Widget _handle({
    required String id,
    required MapCamera camera,
    required LatLng point,
    required IconData icon,
    required Color color,
    required ValueChanged<LatLng> onDragUpdate,
  }) {
    // #261 — the touch target is deliberately larger than typical (44px,
    // Apple/Android's own minimum recommended tap-target size) since these
    // sit over a busy map background and were reported hard to grab.
    const handleSize = 44.0;
    final offset = camera.latLngToScreenOffset(point);
    // #268 — before CameraFit.bounds has a real non-zero layout (first
    // frames in widget tests, and potentially on a cold map open on device),
    // latLngToScreenOffset can return Infinity/NaN. Positioning a handle
    // with that produces a non-finite SemanticsNode rect and crashes the
    // scheduler. Skip the handle until the camera can project finite pixels.
    if (!offset.dx.isFinite || !offset.dy.isFinite) {
      return const SizedBox.shrink();
    }
    // #265 — long-press to arm, then drag. Instant pan on a handle used to
    // steal map pans / move the fence by accident; armed state scales up
    // and swaps to a grip icon so the user sees the grab before moving.
    final armed = _armedHandleId == id;
    final size = armed ? handleSize * 1.25 : handleSize;
    return Positioned(
      left: offset.dx - size / 2,
      top: offset.dy - size / 2,
      // #268 — ExcludeSemantics: even a finite Positioned can briefly
      // hand the semantics pipeline a non-finite rect while flutter_map's
      // camera is mid-fit (widget-test symptom: "SemanticsNode tried to
      // set a non-finite rect"). Handles are pure drag targets; a11y for
      // the anchorage itself lives on the surrounding screen chrome.
      child: ExcludeSemantics(
        child: GestureDetector(
          onLongPressStart: (_) {
            setState(() {
              _armedHandleId = id;
              _dragging = true;
            });
          },
          onLongPressMoveUpdate: (details) {
            if (_armedHandleId != id) return;
            // #261 — convert the pointer's true global position each frame
            // (not a delta from an already-moved handle) so tracking is 1:1.
            final box =
                _mapAreaKey.currentContext!.findRenderObject()! as RenderBox;
            final local = box.globalToLocal(details.globalPosition);
            onDragUpdate(camera.screenOffsetToLatLng(local));
          },
          onLongPressEnd: (_) {
            setState(() {
              _armedHandleId = null;
              _dragging = false;
            });
            _persist();
          },
          onLongPressCancel: () {
            setState(() {
              _armedHandleId = null;
              _dragging = false;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: armed ? Colors.amberAccent : Colors.white,
                width: armed ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: armed ? color.withValues(alpha: 0.7) : Colors.black45,
                  blurRadius: armed ? 12 : 4,
                  spreadRadius: armed ? 2 : 0,
                ),
              ],
            ),
            child: Icon(
              armed ? Icons.open_with : icon,
              color: Colors.white,
              size: armed ? 22 : 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _BasemapSwitcher extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;
  const _BasemapSwitcher({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(20),
      child: PopupMenuButton<String>(
        initialValue: current,
        onSelected: onChanged,
        tooltip: 'Chart / satellite view',
        icon: const Icon(Icons.layers, color: Colors.white),
        itemBuilder: (context) => mapTileBaseProviders
            .map((p) => PopupMenuItem(value: p.id, child: Text(p.label)))
            .toList(),
      ),
    );
  }
}
