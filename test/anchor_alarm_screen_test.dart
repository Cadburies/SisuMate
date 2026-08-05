import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/predictwind_datahub_service.dart';
import 'package:sisu_mate/ui/anchor/anchor_alarm_screen.dart';

/// #256 — Anchor Alarm screen: PredictWind Hub connection status + GPS
/// (Hub if available, else phone GPS fallback) + wind, plus anchor
/// set/edit/weigh, the scope/radius geofence sliders, the danger-zone
/// switch+sliders, and the alarm banner. Fakes the network (`MockClient`),
/// GPS (`GeolocatorPlatform.instance`), and the Drift DB (in-memory,
/// overriding `appDatabaseProvider`) so no real device I/O or on-disk
/// state happens in `flutter test`.
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
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    fakeGeo = _FakeGeolocatorPlatform();
    GeolocatorPlatform.instance = fakeGeo;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    http.Client? httpClient,
    PredictWindDatahubService hubService = const PredictWindDatahubService(),
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: AnchorAlarmScreen(
            hubService: hubService,
            httpClient: httpClient,
            // A live real-clock Timer.periodic left running is a classic
            // flutter_test hang source at teardown — tests drive refresh
            // explicitly instead (tap the refresh icon, or the drop/edit/
            // weigh actions, all of which call _refresh()/_recomputeAlarm()
            // directly).
            pollInterval: null,
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

  testWidgets(
      'a connected Hub with live nmead data shows GPS+wind from the Hub, '
      'not the phone', (tester) async {
    // No GPS fix set on fakeGeo — if the screen fell back to phone GPS
    // here, it would show "Position unavailable", not a real position.
    final client = MockClient((request) async {
      if (request.method == 'POST') {
        return http.Response('', 302,
            headers: {'set-cookie': 'sysauth=abc123; path=/cgi-bin/luci/'});
      }
      return http.Response(
        '{"lat":12.005442,"lon":-61.731507,"tws":6.837343,"twd":115.384747,'
        '"unixtime":1785872083}',
        200,
      );
    });

    await pumpScreen(
      tester,
      httpClient: client,
      hubService: const PredictWindDatahubService(
        baseUrlOverride: 'https://fake-hub.test',
        usernameOverride: 'user',
        passwordOverride: 'pass',
      ),
    );

    expect(find.text('PredictWind Hub connected'), findsOneWidget);
    expect(find.text('12.00544, -61.73151'), findsOneWidget);
    expect(find.text('Source: PredictWind Hub'), findsOneWidget);
    expect(find.text('6.8 kt @ 115°'), findsOneWidget);
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

  group('anchor set/edit/weigh', () {
    testWidgets('no active anchor: Drop Anchor is disabled without a GPS fix',
        (tester) async {
      fakeGeo.serviceEnabled = false;

      await pumpScreen(tester);

      expect(find.text('No anchor set'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Drop Anchor Here'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets(
        'Drop Anchor Here creates the active watch at the current GPS position',
        (tester) async {
      fakeGeo.position = _position(lat: 12.0, lon: -61.7);

      await pumpScreen(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Drop Anchor Here'));
      await tester.pumpAndSettle();

      expect(find.text('No anchor set'), findsNothing);
      // Appears twice: the anchor-status card and the boat-position card
      // legitimately show the same text right after dropping anchor at the
      // current GPS position (anchor == boat position at that instant).
      expect(find.text('12.00000, -61.70000'), findsNWidgets(2));
      // Default scope ratio (no UserSettings row seeded) is 5:1, no depth
      // known (phone-GPS-only), so radius falls back to the fixed default.
      expect(find.text('30 m'), findsOneWidget);

      final active = await container.read(anchorWatchRepositoryProvider).watchActive().first;
      expect(active, isNotNull);
      expect(active!.scopeRatio, 5.0);
      expect(active.radiusMeters, 30.0);
    });

    testWidgets('Edit position "Use current GPS" moves the anchor',
        (tester) async {
      fakeGeo.position = _position(lat: 12.0, lon: -61.7);
      await pumpScreen(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Drop Anchor Here'));
      await tester.pumpAndSettle();

      // Move the boat before editing, so "use current GPS" is a real change.
      fakeGeo.position = _position(lat: 13.0, lon: -62.0);

      await tester.tap(find.widgetWithText(TextButton, 'Edit position'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use current GPS position'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      final active = await container.read(anchorWatchRepositoryProvider).watchActive().first;
      expect(active!.anchorLat, 13.0);
      expect(active.anchorLon, -62.0);
    });

    testWidgets('Weigh anchor returns to the Drop Anchor state', (tester) async {
      fakeGeo.position = _position(lat: 12.0, lon: -61.7);
      await pumpScreen(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Drop Anchor Here'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Weigh anchor'));
      await tester.pumpAndSettle();

      expect(find.text('No anchor set'), findsOneWidget);
      final active = await container.read(anchorWatchRepositoryProvider).watchActive().first;
      expect(active, isNull);
    });
  });

  group('scope + danger zone editing', () {
    testWidgets('dragging the radius slider to its end and releasing persists it',
        (tester) async {
      fakeGeo.position = _position(lat: 12.0, lon: -61.7);
      await pumpScreen(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Drop Anchor Here'));
      await tester.pumpAndSettle();

      // Radius is the 2nd Slider (index 1): scope ratio, then radius.
      final radiusSlider = tester.widget<Slider>(find.byType(Slider).at(1));
      radiusSlider.onChanged!(150);
      await tester.pump();
      radiusSlider.onChangeEnd!(150);
      await tester.pumpAndSettle();

      final active = await container.read(anchorWatchRepositoryProvider).watchActive().first;
      expect(active!.radiusMeters, 150);
    });

    testWidgets('the danger zone switch reveals sliders and persists enabled',
        (tester) async {
      fakeGeo.position = _position(lat: 12.0, lon: -61.7);
      await pumpScreen(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Drop Anchor Here'));
      await tester.pumpAndSettle();

      expect(find.text('Center bearing'), findsNothing);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('Center bearing'), findsOneWidget);
      expect(find.text('Width'), findsOneWidget);
      final active = await container.read(anchorWatchRepositoryProvider).watchActive().first;
      expect(active!.dangerZoneEnabled, isTrue);
    });

    testWidgets('adjusting the danger-zone width slider persists on release',
        (tester) async {
      fakeGeo.position = _position(lat: 12.0, lon: -61.7);
      await pumpScreen(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Drop Anchor Here'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Sliders now: [0]=scope ratio, [1]=radius, [2]=center bearing,
      // [3]=width, [4]=danger-zone radius.
      final widthSlider = tester.widget<Slider>(find.byType(Slider).at(3));
      widthSlider.onChanged!(90);
      await tester.pump();
      widthSlider.onChangeEnd!(90);
      await tester.pumpAndSettle();

      final active = await container.read(anchorWatchRepositoryProvider).watchActive().first;
      expect(active!.dangerZoneWidthDeg, 90);
    });
  });

  group('alarm', () {
    testWidgets('the alarm banner appears once the boat drags outside the circle',
        (tester) async {
      fakeGeo.position = _position(lat: 12.0, lon: -61.7);
      await pumpScreen(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Drop Anchor Here'));
      await tester.pumpAndSettle();
      expect(find.textContaining('ANCHOR ALARM'), findsNothing);

      // Radius defaulted to 30m; move the boat ~11km away — unmistakably
      // outside any reasonable geofence radius.
      fakeGeo.position = _position(lat: 12.1, lon: -61.7);

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('dragged outside the safe circle'),
        findsOneWidget,
      );
    });

    testWidgets('no alarm banner while the boat stays inside the circle',
        (tester) async {
      fakeGeo.position = _position(lat: 12.0, lon: -61.7);
      await pumpScreen(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Drop Anchor Here'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(find.textContaining('ANCHOR ALARM'), findsNothing);
    });
  });
}
