import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/predictwind_datahub_service.dart';
import 'package:sisu_mate/ui/anchor/anchor_alarm_screen.dart';

/// #256 — Anchor Alarm screen. GPS/wind come **only** from a mocked
/// PredictWind Hub (`MockClient`) — there is deliberately no phone GPS
/// fallback (see the screen's class doc for why: a phone can be carried
/// off the boat, or be less accurate than the boat's own instrument,
/// either masking a real drag or inventing a false one). The Drift DB is
/// in-memory (overriding `appDatabaseProvider`), so no real device I/O or
/// on-disk state happens in `flutter test`.
void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  const connectedHubService = PredictWindDatahubService(
    baseUrlOverride: 'https://fake-hub.test',
    usernameOverride: 'user',
    passwordOverride: 'pass',
  );

  /// A MockClient that logs in successfully and answers `nmead_status`
  /// with the given fields (mirrors the real device's JSON shape).
  /// [unixtimeOffset] simulates a stale/frozen reading — the Hub can stay
  /// powered and keep answering after the boat's NMEA instruments are
  /// switched off.
  http.Client hubClient({
    double lat = 12.0,
    double lon = -61.7,
    double tws = 6.8,
    double twd = 115,
    int quality = 4,
    Duration unixtimeOffset = Duration.zero,
  }) {
    return MockClient((request) async {
      if (request.method == 'POST') {
        return http.Response('', 302,
            headers: {'set-cookie': 'sysauth=abc123; path=/cgi-bin/luci/'});
      }
      final unixtime = DateTime.now()
              .toUtc()
              .subtract(unixtimeOffset)
              .millisecondsSinceEpoch ~/
          1000;
      return http.Response(
        jsonEncode({
          'lat': lat,
          'lon': lon,
          'tws': tws,
          'twd': twd,
          'quality': quality,
          'unixtime': unixtime,
        }),
        200,
      );
    });
  }

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
      'Hub not configured shows a clear state — no phone GPS fallback',
      (tester) async {
    await pumpScreen(tester);

    expect(find.text('Anchor Alarm'), findsOneWidget);
    expect(find.text('PredictWind Hub not configured'), findsOneWidget);
    expect(find.text('Position unavailable'), findsOneWidget);
    expect(find.text('PredictWind Hub not connected.'), findsOneWidget);
    expect(find.text('Wind data unavailable'), findsOneWidget);
  });

  testWidgets('a connected Hub with a good fix shows GPS+wind', (tester) async {
    await pumpScreen(tester,
        httpClient: hubClient(), hubService: connectedHubService);

    expect(find.text('PredictWind Hub connected'), findsOneWidget);
    expect(find.text('12.00000, -61.70000'), findsOneWidget);
    expect(find.text('Source: PredictWind Hub'), findsOneWidget);
    expect(find.text('6.8 kt @ 115°'), findsOneWidget);
  });

  testWidgets(
      'a Hub reading with quality 0 (no fix) shows unavailable, not a '
      'false position', (tester) async {
    await pumpScreen(tester,
        httpClient: hubClient(quality: 0), hubService: connectedHubService);

    expect(find.text('Position unavailable'), findsOneWidget);
    expect(
        find.text('Connected to the Hub, waiting for a GPS fix.'),
        findsOneWidget);
  });

  testWidgets(
      'a stale Hub reading (instruments off, Hub still answering) shows '
      'unavailable, not a frozen position', (tester) async {
    await pumpScreen(
      tester,
      httpClient: hubClient(unixtimeOffset: const Duration(minutes: 5)),
      hubService: connectedHubService,
    );

    expect(find.text('Position unavailable'), findsOneWidget);
    expect(
        find.text('Last Hub reading is stale — instruments may be off.'),
        findsOneWidget);
  });

  testWidgets(
      'refresh re-runs the connection check without blanking the screen',
      (tester) async {
    var requestCount = 0;
    final client = MockClient((request) async {
      requestCount++;
      return http.Response('', 200);
    });

    await pumpScreen(tester, httpClient: client);
    expect(find.text('PredictWind Hub not configured'), findsOneWidget);
    final before = requestCount;

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();
    // Must never fall back to a full-page spinner after the first load —
    // that used to tear down in-progress edits on every refresh (#256
    // follow-up: "in your face refresh" made editing the anchor
    // effectively impossible).
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pumpAndSettle();

    // Not configured in this test env, so checkConnection short-circuits
    // before any request — refresh must not throw and the screen must
    // still render its cards afterward.
    expect(requestCount, before);
    expect(find.text('Anchor Alarm'), findsOneWidget);
  });

  group('anchor set/edit/weigh', () {
    testWidgets('no active anchor: Drop Anchor is disabled without a Hub fix',
        (tester) async {
      await pumpScreen(tester);

      expect(find.text('No anchor set'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Drop Anchor Here'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets(
        'Drop Anchor Here creates the active watch at the current Hub GPS '
        'position', (tester) async {
      await pumpScreen(tester,
          httpClient: hubClient(), hubService: connectedHubService);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Drop Anchor Here'));
      await tester.pumpAndSettle();

      expect(find.text('No anchor set'), findsNothing);
      // Appears twice: the anchor-status card and the boat-position card
      // legitimately show the same text right after dropping anchor at the
      // current GPS position (anchor == boat position at that instant).
      expect(find.text('12.00000, -61.70000'), findsNWidgets(2));
      // Default scope ratio (no UserSettings row seeded) is 5:1, no depth
      // in this mock response, so radius falls back to the fixed default.
      expect(find.text('30 m'), findsOneWidget);

      final active =
          await container.read(anchorWatchRepositoryProvider).watchActive().first;
      expect(active, isNotNull);
      expect(active!.scopeRatio, 5.0);
      expect(active.radiusMeters, 30.0);
    });

    testWidgets('Edit position "Use current GPS" moves the anchor',
        (tester) async {
      var lat = 12.0, lon = -61.7;
      final client = MockClient((request) async {
        if (request.method == 'POST') {
          return http.Response('', 302,
              headers: {'set-cookie': 'sysauth=abc123; path=/cgi-bin/luci/'});
        }
        return http.Response(
          jsonEncode({
            'lat': lat,
            'lon': lon,
            'quality': 4,
            'unixtime': DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000,
          }),
          200,
        );
      });

      await pumpScreen(tester,
          httpClient: client, hubService: connectedHubService);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Drop Anchor Here'));
      await tester.pumpAndSettle();

      // Move the boat, then refresh so the screen picks up the new fix
      // before editing — "use current GPS" must reflect a real change.
      lat = 13.0;
      lon = -62.0;
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Edit position'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use current GPS position'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      final active =
          await container.read(anchorWatchRepositoryProvider).watchActive().first;
      expect(active!.anchorLat, 13.0);
      expect(active.anchorLon, -62.0);
    });

    testWidgets('Weigh anchor returns to the Drop Anchor state', (tester) async {
      await pumpScreen(tester,
          httpClient: hubClient(), hubService: connectedHubService);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Drop Anchor Here'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Weigh anchor'));
      await tester.pumpAndSettle();

      expect(find.text('No anchor set'), findsOneWidget);
      final active =
          await container.read(anchorWatchRepositoryProvider).watchActive().first;
      expect(active, isNull);
    });
  });

  group('scope + danger zone editing', () {
    testWidgets('dragging the radius slider to its end and releasing persists it',
        (tester) async {
      await pumpScreen(tester,
          httpClient: hubClient(), hubService: connectedHubService);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Drop Anchor Here'));
      await tester.pumpAndSettle();

      // Radius is the 2nd Slider (index 1): scope ratio, then radius. Capped
      // at 120m — real cruisers rarely pay out more rode than that.
      final radiusSlider = tester.widget<Slider>(find.byType(Slider).at(1));
      expect(radiusSlider.max, 120);
      radiusSlider.onChanged!(120);
      await tester.pump();
      radiusSlider.onChangeEnd!(120);
      await tester.pumpAndSettle();

      final active =
          await container.read(anchorWatchRepositoryProvider).watchActive().first;
      expect(active!.radiusMeters, 120);
    });

    testWidgets(
        'the radius text field accepts a value beyond the 120m slider cap',
        (tester) async {
      await pumpScreen(tester,
          httpClient: hubClient(), hubService: connectedHubService);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Drop Anchor Here'));
      await tester.pumpAndSettle();

      // Radius row's TextField is the first one on screen.
      await tester.enterText(find.byType(TextField).first, '150');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      final active =
          await container.read(anchorWatchRepositoryProvider).watchActive().first;
      expect(active!.radiusMeters, 150);
    });

    testWidgets('the danger zone switch reveals sliders and persists enabled',
        (tester) async {
      await pumpScreen(tester,
          httpClient: hubClient(), hubService: connectedHubService);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Drop Anchor Here'));
      await tester.pumpAndSettle();

      expect(find.text('Center bearing'), findsNothing);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('Center bearing'), findsOneWidget);
      expect(find.text('Width'), findsOneWidget);
      expect(find.text('Inner radius'), findsOneWidget);
      expect(find.text('Outer radius'), findsOneWidget);
      final active =
          await container.read(anchorWatchRepositoryProvider).watchActive().first;
      expect(active!.dangerZoneEnabled, isTrue);
      // #262 — inner radius defaults to the geofence (alarm) perimeter the
      // moment the zone is enabled, not 0/the anchor. Drop Anchor's radius
      // defaulted to 30m (no depth in this mock, no UserSettings row).
      expect(active.dangerZoneInnerRadiusMeters, 30.0);
    });

    testWidgets('adjusting the danger-zone width slider persists on release',
        (tester) async {
      await pumpScreen(tester,
          httpClient: hubClient(), hubService: connectedHubService);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Drop Anchor Here'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Sliders now: [0]=scope ratio, [1]=radius, [2]=center bearing,
      // [3]=width, [4]=danger-zone inner radius, [5]=danger-zone outer radius.
      final widthSlider = tester.widget<Slider>(find.byType(Slider).at(3));
      widthSlider.onChanged!(90);
      await tester.pump();
      widthSlider.onChangeEnd!(90);
      await tester.pumpAndSettle();

      final active =
          await container.read(anchorWatchRepositoryProvider).watchActive().first;
      expect(active!.dangerZoneWidthDeg, 90);
    });
  });

  group('alarm', () {
    testWidgets('the alarm banner appears once the boat drags outside the circle',
        (tester) async {
      var lat = 12.0, lon = -61.7;
      final client = MockClient((request) async {
        if (request.method == 'POST') {
          return http.Response('', 302,
              headers: {'set-cookie': 'sysauth=abc123; path=/cgi-bin/luci/'});
        }
        return http.Response(
          jsonEncode({
            'lat': lat,
            'lon': lon,
            'quality': 4,
            'unixtime': DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000,
          }),
          200,
        );
      });

      await pumpScreen(tester,
          httpClient: client, hubService: connectedHubService);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Drop Anchor Here'));
      await tester.pumpAndSettle();
      expect(find.textContaining('ANCHOR ALARM'), findsNothing);

      // Radius defaulted to 30m; move the boat ~11km away — unmistakably
      // outside any reasonable geofence radius.
      lat = 12.1;

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('dragged outside the safe circle'),
        findsOneWidget,
      );
    });

    testWidgets('no alarm banner while the boat stays inside the circle',
        (tester) async {
      await pumpScreen(tester,
          httpClient: hubClient(), hubService: connectedHubService);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Drop Anchor Here'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(find.textContaining('ANCHOR ALARM'), findsNothing);
    });

    testWidgets(
        'losing the Hub GPS fix shows a calm warning, not the loud alarm '
        '(reduces false alarms from comms loss)', (tester) async {
      var quality = 4;
      final client = MockClient((request) async {
        if (request.method == 'POST') {
          return http.Response('', 302,
              headers: {'set-cookie': 'sysauth=abc123; path=/cgi-bin/luci/'});
        }
        return http.Response(
          jsonEncode({
            'lat': 12.0,
            'lon': -61.7,
            'quality': quality,
            'unixtime': DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000,
          }),
          200,
        );
      });

      await pumpScreen(tester,
          httpClient: client, hubService: connectedHubService);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Drop Anchor Here'));
      await tester.pumpAndSettle();

      // Simulate losing the fix (e.g. instruments switched off).
      quality = 0;
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(find.textContaining('ANCHOR ALARM'), findsNothing);
      expect(find.text('Anchor position unknown'), findsOneWidget);
      expect(
        find.textContaining('Connected to the Hub, but no live GPS fix'),
        findsOneWidget,
      );
    });
  });
}
