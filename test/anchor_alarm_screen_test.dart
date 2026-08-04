import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sisu_mate/services/predictwind_datahub_service.dart';
import 'package:sisu_mate/ui/anchor/anchor_alarm_screen.dart';

/// #256 — first cut of the Anchor Alarm screen: PredictWind Hub connection
/// status + a GPS position (Hub if available, else phone GPS fallback) +
/// wind. Fakes both the network (`MockClient`, mirroring
/// `passage_planner_screen_test.dart`'s pattern) and GPS
/// (`GeolocatorPlatform.instance`, mirroring `location_service_test.dart`'s
/// pattern) so no real device I/O happens in `flutter test`.
class _FakeGeolocatorPlatform extends GeolocatorPlatform
    with MockPlatformInterfaceMixin {
  bool serviceEnabled = true;
  LocationPermission permission = LocationPermission.always;
  Position? position;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async => permission;

  @override
  Future<Position> getCurrentPosition(
      {LocationSettings? locationSettings}) async {
    final p = position;
    if (p == null) throw Exception('no fix');
    return p;
  }
}

Position _position({double lat = 33.4484, double lon = -112.0740}) => Position(
      latitude: lat,
      longitude: lon,
      timestamp: DateTime(2026, 1, 1),
      accuracy: 5.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );

void main() {
  late _FakeGeolocatorPlatform fakeGeo;

  setUp(() {
    fakeGeo = _FakeGeolocatorPlatform();
    GeolocatorPlatform.instance = fakeGeo;
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    http.Client? httpClient,
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ProviderContainer(),
        child: MaterialApp(
          home: AnchorAlarmScreen(
            hubService: const PredictWindDatahubService(),
            httpClient: httpClient,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
      'Hub not configured (no dart-defines in tests) falls back to phone GPS',
      (tester) async {
    fakeGeo.position = _position();

    await pumpScreen(tester);

    expect(find.text('Anchor Alarm'), findsOneWidget);
    expect(find.text('PredictWind Hub not configured'), findsOneWidget);
    expect(find.text('33.44840, -112.07400'), findsOneWidget);
    expect(find.text('Source: Phone GPS'), findsOneWidget);
    expect(find.text('Wind data unavailable'), findsOneWidget);
  });

  testWidgets('no GPS fix and no Hub shows a clear unavailable reason',
      (tester) async {
    fakeGeo.serviceEnabled = false;

    await pumpScreen(tester);

    expect(find.text('Position unavailable'), findsOneWidget);
    expect(find.text('Location services are turned off.'), findsOneWidget);
  });

  testWidgets('refresh button re-runs the connection check', (tester) async {
    fakeGeo.position = _position();
    var requestCount = 0;
    final client = MockClient((request) async {
      requestCount++;
      return http.Response('', 200);
    });

    await pumpScreen(tester, httpClient: client);
    expect(find.text('PredictWind Hub not configured'), findsOneWidget);
    final before = requestCount;

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();

    // Not configured in this test env, so checkConnection short-circuits
    // before any request — refresh must not throw and the screen must
    // still render its cards afterward.
    expect(requestCount, before);
    expect(find.text('Anchor Alarm'), findsOneWidget);
  });
}
