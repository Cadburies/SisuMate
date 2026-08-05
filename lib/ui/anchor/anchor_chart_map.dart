import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/di.dart';
import '../../models/models.dart';
import '../../services/anchor_alarm_service.dart';
import '../../services/boat_polar_service.dart' show bearingDeg;
import '../../services/weather_routing_service.dart' show destinationPoint;
import '../../services/map_tile_providers.dart';

/// #256 follow-up — a satellite/chart view of the anchorage, zoomed to a
/// fixed ~300m radius, with the geofence circle and danger-zone sector
/// drawn as real overlays the user can tap-and-drag directly (not just
/// edit via the sliders in [AnchorAlarmScreen]'s other cards, which stay
/// as the precise-numeric-entry alternative).
///
/// Three drag handles, each a plain [Positioned] + [GestureDetector] pair
/// (flutter_map has no built-in draggable-marker widget) repositioned via
/// [MapCamera.latLngToScreenOffset]/[screenOffsetToLatLng] — the package's
/// own documented seam for exactly this ("convert a latLng to a position
/// we could use with a widget outside of FlutterMap layer space"):
/// - the anchor itself (moves the anchor position — same effect as the
///   "Edit position" dialog),
/// - the geofence circle's edge (due east of the anchor — drag changes
///   only the radius),
/// - the danger-zone sector's centerline tip (drag changes the sector's
///   bearing *and* radius, like moving a clock hand) and its edge (drag
///   changes only the sector's angular width, center bearing held fixed).
///
/// While any handle is actively being dragged, the map's own one-finger
/// pan gesture is disabled (`InteractiveFlag.drag` off) so it can't steal
/// the pointer from the handle — pinch-zoom stays available throughout.
class AnchorChartMap extends ConsumerStatefulWidget {
  final AnchorWatch activeWatch;
  final double? boatLat;
  final double? boatLon;
  const AnchorChartMap({
    super.key,
    required this.activeWatch,
    required this.boatLat,
    required this.boatLon,
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
  late double _anchorLat;
  late double _anchorLon;
  late double _radiusMeters;
  late double _dangerCenterDeg;
  late double _dangerWidthDeg;
  late double _dangerRadiusMeters;
  bool _dragging = false;
  String _tileProviderId = 'esri_world_imagery';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _syncFromWatch();
  }

  @override
  void didUpdateWidget(covariant AnchorChartMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeWatch.id != widget.activeWatch.id) _syncFromWatch();
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
    _dangerRadiusMeters = widget.activeWatch.dangerZoneRadiusMeters;
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
    final updated = widget.activeWatch
      ..anchorLat = _anchorLat
      ..anchorLon = _anchorLon
      ..radiusMeters = _radiusMeters
      ..dangerZoneCenterDeg = _dangerCenterDeg
      ..dangerZoneWidthDeg = _dangerWidthDeg
      ..dangerZoneRadiusMeters = _dangerRadiusMeters;
    await ref.read(anchorWatchRepositoryProvider).updateWatch(updated);
  }

  void _setDragging(bool value) {
    if (_dragging == value) return;
    setState(() => _dragging = value);
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
                TileLayer(
                  urlTemplate: tileConfig.urlTemplate,
                  userAgentPackageName: 'com.sisumate.app',
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
                      }),
                    ),
                    if (widget.activeWatch.dangerZoneEnabled) ...[
                      _handle(
                        camera: camera,
                        point: _dangerCenterHandlePoint(),
                        icon: Icons.warning_amber,
                        color: Colors.red,
                        onDragUpdate: (newPoint) => setState(() {
                          _dangerCenterDeg = bearingDeg(
                              _anchorLat, _anchorLon, newPoint.latitude, newPoint.longitude);
                          _dangerRadiusMeters = _alarmService
                              .distanceMeters(
                                lat1: _anchorLat,
                                lon1: _anchorLon,
                                lat2: newPoint.latitude,
                                lon2: newPoint.longitude,
                              )
                              .clamp(_handleMinMeters, _handleMaxMeters);
                        }),
                      ),
                      _handle(
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
                onChanged: (id) => setState(() => _tileProviderId = id),
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

  LatLng _dangerCenterHandlePoint() {
    final p = destinationPoint(
      lat: _anchorLat,
      lon: _anchorLon,
      bearingDeg: _dangerCenterDeg,
      distanceNm: _dangerRadiusMeters / 1852,
    );
    return LatLng(p.lat, p.lon);
  }

  LatLng _dangerEdgeHandlePoint() {
    final p = destinationPoint(
      lat: _anchorLat,
      lon: _anchorLon,
      bearingDeg: _dangerCenterDeg + _dangerWidthDeg / 2,
      distanceNm: _dangerRadiusMeters / 1852,
    );
    return LatLng(p.lat, p.lon);
  }

  /// A pie-slice polygon approximating the danger-zone sector: the anchor,
  /// then points every 5° from the left edge to the right edge at
  /// [_dangerRadiusMeters], back to the anchor.
  List<LatLng> _sectorPoints() {
    final points = <LatLng>[LatLng(_anchorLat, _anchorLon)];
    final start = _dangerCenterDeg - _dangerWidthDeg / 2;
    final steps = math.max(2, (_dangerWidthDeg / 5).ceil());
    for (var i = 0; i <= steps; i++) {
      final bearing = start + _dangerWidthDeg * i / steps;
      final p = destinationPoint(
        lat: _anchorLat,
        lon: _anchorLon,
        bearingDeg: bearing,
        distanceNm: _dangerRadiusMeters / 1852,
      );
      points.add(LatLng(p.lat, p.lon));
    }
    return points;
  }

  Widget _handle({
    required MapCamera camera,
    required LatLng point,
    required IconData icon,
    required Color color,
    required ValueChanged<LatLng> onDragUpdate,
  }) {
    const handleSize = 32.0;
    final offset = camera.latLngToScreenOffset(point);
    return Positioned(
      left: offset.dx - handleSize / 2,
      top: offset.dy - handleSize / 2,
      child: GestureDetector(
        onPanStart: (_) => _setDragging(true),
        onPanUpdate: (details) {
          final local = camera.latLngToScreenOffset(point) +
              (details.localPosition - Offset(handleSize / 2, handleSize / 2));
          onDragUpdate(camera.screenOffsetToLatLng(local));
        },
        onPanEnd: (_) {
          _setDragging(false);
          _persist();
        },
        child: Container(
          width: handleSize,
          height: handleSize,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
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
