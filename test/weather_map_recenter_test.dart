import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

/// #212: MapOptions.initialCenter only applies on first load (flutter_map's
/// own doc comment) — it isn't reactive, so a GPS fix moved the marker
/// (rebuilds from the lat/lon controllers) but never the map viewport
/// itself, since no MapController.move() call existed anywhere in the app.
///
/// Two tests, not one: mounting the full WeatherScreen to prove this
/// end-to-end isn't viable here — flutter_map's default tile provider now
/// auto-enables a built-in disk cache that needs path_provider's
/// Pigeon-based getApplicationCacheDirectory channel, which isn't mockable
/// via the legacy MethodChannel this app's other tests use (confirmed: even
/// mocking every path_provider method this app already stubs elsewhere
/// still throws MissingPlatformDirectoryException from inside flutter_map's
/// own tile-cache setup). Same "disproportionate mocking cost" tradeoff
/// already made for this screen in weather_toolbar_wrap_test.dart. So:
///  1. A bare FlutterMap + MapController (no TileLayer, so no cache/network
///     involvement at all) proves the underlying mechanism itself —
///     .move() genuinely recenters .camera.center once the map is ready.
///  2. A source scan proves weather_screen.dart actually wires this up at
///     the right call sites (GPS fix, search-selected place) and disposes
///     the controller.
void main() {
  testWidgets(
      'MapController.move() re-centers the camera once the map is ready',
      (tester) async {
    final controller = MapController();
    var ready = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 300,
          height: 300,
          child: FlutterMap(
            mapController: controller,
            options: MapOptions(
              initialCenter: const LatLng(33.4484, -112.0740),
              initialZoom: 8,
              onMapReady: () => ready = true,
            ),
            children: const [],
          ),
        ),
      ),
    ));

    expect(ready, isTrue);
    final before = controller.camera.center;
    expect(before.latitude, closeTo(33.4484, 0.001));

    final moved = controller.move(const LatLng(-33.9249, 18.4241), 8);
    await tester.pump();

    expect(moved, isTrue, reason: 'move() reports success once ready');
    final after = controller.camera.center;
    expect(after.latitude, closeTo(-33.9249, 0.001));
    expect(after.longitude, closeTo(18.4241, 0.001));
  });

  test('weather_screen.dart wires MapController.move() into the GPS and '
      'place-search flows, and disposes the controller', () {
    final source = File(
      '${Directory.current.path}/lib/ui/weather/weather_screen.dart',
    ).readAsStringSync();

    expect(source.contains('final _mapController = MapController();'), isTrue,
        reason: 'a MapController must exist to recenter the map viewport '
            '(FlutterMap.initialCenter only applies on first load)');
    expect(source.contains('mapController: _mapController'), isTrue,
        reason: 'the controller must actually be attached to FlutterMap');
    expect(source.contains('_mapController.dispose();'), isTrue);

    // Both the GPS-fix success path and search-place selection recenter —
    // via the shared _recenterMap helper, guarded by the map's ready state.
    final useGpsIndex = source.indexOf('case null:');
    final selectPlaceIndex = source.indexOf('Future<void> _selectPlace(');
    final recenterDefIndex = source.indexOf('void _recenterMap(');
    expect(useGpsIndex, greaterThanOrEqualTo(0));
    expect(selectPlaceIndex, greaterThanOrEqualTo(0));
    expect(recenterDefIndex, greaterThanOrEqualTo(0));

    final gpsBlock = source.substring(
        useGpsIndex, source.indexOf('_load();', useGpsIndex) + 10);
    expect(gpsBlock.contains('_recenterMap('), isTrue,
        reason: 'a resolved GPS fix must recenter the map, not just move '
            'the marker');

    final selectPlaceBlock = source.substring(
        selectPlaceIndex,
        source.indexOf('_load(placeName:', selectPlaceIndex) + 20);
    expect(selectPlaceBlock.contains('_recenterMap('), isTrue,
        reason: 'selecting a searched place must recenter the map too');
  });
}
