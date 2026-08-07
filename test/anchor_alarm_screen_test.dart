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

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
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
    double? dpt,
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
          'dpt': ?dpt,
          'quality': quality,
          'unixtime': unixtime,
        }),
        200,
      );
    });
  }

  /// Finite pumps — avoid pumpAndSettle (never settles with pending frames).
  /// Connectivity check has a short timeout inside failover (~250ms) plus
  /// hub HTTP; budget enough real pumps for that to finish.
  Future<void> settleUi(WidgetTester tester) async {
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// After Drop Anchor the active watch StreamProvider rebuilds the body;
  /// keep this short so we don't sit inside a long pump loop.
  Future<void> settleAfterDrop(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  ProviderContainer containerOf(WidgetTester tester) {
    return ProviderScope.containerOf(
      tester.element(find.byType(AnchorAlarmScreen)),
    );
  }

  /// #268 — Drift StreamQueryStore schedules a zero-duration Timer when a
  /// query stream is cancelled (StreamProvider dispose / `.watchActive().first`).
  /// Flush those timers or the test binding asserts `!timersPending` / hangs.
  Future<void> flushDriftTimers(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await flushDriftTimers(tester);
  }

  Future<dynamic> readActive(WidgetTester tester) async {
    final active = await containerOf(tester)
        .read(anchorWatchRepositoryProvider)
        .watchActive()
        .first
        .timeout(const Duration(seconds: 2));
    // Cancel timer from the short-lived watch stream.
    await flushDriftTimers(tester);
    return active;
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    http.Client? httpClient,
    PredictWindDatahubService hubService = const PredictWindDatahubService(),
    bool allowPhoneFallback = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
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
            // Chart-map MapController dispose is flaky under flutter_test;
            // chart coverage is in anchor_chart_map_test.dart.
            showChartMap: false,
            // #303 — production enables phone fallback; host tests keep
            // instruments-only so Geolocator is never invoked.
            allowPhoneFallback: allowPhoneFallback,
          ),
        ),
      ),
    );
    await settleUi(tester);
  }

  testWidgets(
      'Hub not configured shows a clear state (tests disable phone fallback)',
      (tester) async {
    await pumpScreen(tester);

    expect(find.text('Anchor Alarm'), findsOneWidget);
    expect(find.text('Watch'), findsOneWidget);
    expect(find.text('Info'), findsOneWidget);
    expect(find.text('No instrument source configured'), findsOneWidget);
    expect(find.text('Position unavailable'), findsOneWidget);
    expect(find.text('No instruments and no phone GPS fix.'), findsOneWidget);
    expect(find.text('Wind data unavailable'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('#266 — Info tab shows instrument rows', (tester) async {
    await pumpScreen(tester,
        httpClient: hubClient(), hubService: connectedHubService);

    await tester.tap(find.text('Info'));
    await settleUi(tester);

    expect(find.text('SOG'), findsOneWidget);
    expect(find.text('COG'), findsOneWidget);
    expect(find.text('Apparent wind'), findsOneWidget);
    expect(find.text('Boat GPS'), findsOneWidget);
    expect(find.text('Depth'), findsOneWidget);
    expect(find.text('No anchor set'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('#305 — Info tab shows live depth from Hub dpt', (tester) async {
    await pumpScreen(
      tester,
      httpClient: hubClient(dpt: 8.25),
      hubService: connectedHubService,
    );

    await tester.tap(find.text('Info'));
    await settleUi(tester);

    expect(find.text('Depth'), findsOneWidget);
    expect(find.text('8.3 m'), findsOneWidget); // toStringAsFixed(1)
    await unmount(tester);
  });

  testWidgets('a connected Hub with a good fix shows GPS+wind', (tester) async {
    await pumpScreen(tester,
        httpClient: hubClient(), hubService: connectedHubService);

    expect(find.textContaining('DataHub'), findsWidgets);
    expect(find.text('12.00000, -61.70000'), findsOneWidget);
    expect(find.textContaining('Source:'), findsOneWidget);
    expect(find.text('6.8 kt @ 115°'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets(
      'a Hub reading with quality 0 (no fix) shows unavailable, not a '
      'false position', (tester) async {
    await pumpScreen(tester,
        httpClient: hubClient(quality: 0), hubService: connectedHubService);

    expect(find.text('Position unavailable'), findsOneWidget);
    // #303 — with phone fallback disabled in tests, no lat/lon is invented.
    expect(
      find.textContaining('Waiting for instrument fix or phone GPS'),
      findsOneWidget,
    );
    await unmount(tester);
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
      find.textContaining('Instrument reading stale'),
      findsOneWidget,
    );
    await unmount(tester);
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
    expect(find.text('No instrument source configured'), findsOneWidget);
    final before = requestCount;

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();
    // Must never fall back to a full-page spinner after the first load —
    // that used to tear down in-progress edits on every refresh (#256
    // follow-up: "in your face refresh" made editing the anchor
    // effectively impossible). A small inline spinner on the refresh icon
    // is fine; the body must stay mounted (cards still findable).
    expect(find.text('No instrument source configured'), findsOneWidget);
    await settleUi(tester);

    // Not configured in this test env, so checkConnection short-circuits
    // before any request — refresh must not throw and the screen must
    // still render its cards afterward.
    expect(requestCount, before);
    expect(find.text('Anchor Alarm'), findsOneWidget);
    await unmount(tester);
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
      await unmount(tester);
    });

    testWidgets(
        'Drop Anchor Here creates the active watch at the current Hub GPS '
        'position', (tester) async {
      await pumpScreen(tester,
          httpClient: hubClient(), hubService: connectedHubService);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Drop Anchor Here'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('No anchor set'), findsNothing);
      expect(find.text('12.00000, -61.70000'), findsAtLeastNWidgets(1));
      // UI + radius label path: default 30m text field value.
      expect(find.text('30'), findsWidgets);

      // Flush any Drift cancel timers from intermediate rebuilds, then unmount.
      await tester.pump(const Duration(milliseconds: 1));
      await unmount(tester);
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
      await settleAfterDrop(tester);

      lat = 13.0;
      lon = -62.0;
      await tester.tap(find.byIcon(Icons.refresh));
      await settleAfterDrop(tester);

      await tester.tap(find.widgetWithText(TextButton, 'Edit position'));
      await tester.pump(); // dialog open
      await tester.tap(find.text('Use current GPS position'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await settleAfterDrop(tester);

      final active = await readActive(tester);
      expect(active!.anchorLat, 13.0);
      expect(active.anchorLon, -62.0);
      await unmount(tester);
    }, skip: true); // dialog/post-drop Drift timer hang

    testWidgets('Weigh anchor returns to the Drop Anchor state', (tester) async {
      await pumpScreen(tester,
          httpClient: hubClient(), hubService: connectedHubService);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Drop Anchor Here'));
      await settleAfterDrop(tester);

      await tester.tap(find.widgetWithText(TextButton, 'Weigh anchor'));
      await settleUi(tester);

      expect(find.text('No anchor set'), findsOneWidget);
      final active =
          await readActive(tester);
      expect(active, isNull);
      await unmount(tester);
    }, skip: true); // post-drop Drift timer hang
  });

  group('scope + danger zone editing', () {
    testWidgets('dragging the radius slider to its end and releasing persists it',
        (tester) async {
      await pumpScreen(tester,
          httpClient: hubClient(), hubService: connectedHubService);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Drop Anchor Here'));
      await settleAfterDrop(tester);

      // Radius is the 2nd Slider (index 1): scope ratio, then radius. Capped
      // at 120m — real cruisers rarely pay out more rode than that.
      final radiusSlider = tester.widget<Slider>(find.byType(Slider).at(1));
      expect(radiusSlider.max, 120);
      radiusSlider.onChanged!(120);
      await tester.pump();
      radiusSlider.onChangeEnd!(120);
      await settleUi(tester);

      final active =
          await readActive(tester);
      expect(active!.radiusMeters, 120);
      await unmount(tester);
    }, skip: true); // post-drop Drift timer hang

    testWidgets(
        'the radius text field accepts a value beyond the 120m slider cap',
        (tester) async {
      await pumpScreen(tester,
          httpClient: hubClient(), hubService: connectedHubService);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Drop Anchor Here'));
      await settleAfterDrop(tester);

      // Radius row's TextField is the first one on screen.
      await tester.enterText(find.byType(TextField).first, '150');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settleUi(tester);

      final active =
          await readActive(tester);
      expect(active!.radiusMeters, 150);
      await unmount(tester);
    }, skip: true); // post-drop Drift timer hang

    testWidgets('the danger zone switch reveals sliders and persists enabled',
        (tester) async {
      await pumpScreen(tester,
          httpClient: hubClient(), hubService: connectedHubService);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Drop Anchor Here'));
      await settleAfterDrop(tester);

      expect(find.text('Center bearing'), findsNothing);

      await tester.tap(find.byType(Switch));
      await settleUi(tester);

      expect(find.text('Center bearing'), findsOneWidget);
      expect(find.text('Width'), findsOneWidget);
      expect(find.text('Inner radius'), findsOneWidget);
      // #273 — outer radius is the geofence (no separate editor).
      expect(find.text('Outer radius'), findsNothing);
      expect(find.textContaining('Outer edge = alarm radius'), findsOneWidget);
      final active = await readActive(tester);
      expect(active!.dangerZoneEnabled, isTrue);
      // #273 — outer pinned to geofence (30m default); inner just inside it.
      expect(active.dangerZoneOuterRadiusMeters, 30.0);
      expect(active.dangerZoneInnerRadiusMeters, lessThan(30.0));
      await unmount(tester);
    }, skip: true); // post-drop Drift timer hang

    testWidgets('adjusting the danger-zone width slider persists on release',
        (tester) async {
      await pumpScreen(tester,
          httpClient: hubClient(), hubService: connectedHubService);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Drop Anchor Here'));
      await settleAfterDrop(tester);
      await tester.tap(find.byType(Switch));
      await settleUi(tester);

      // Sliders now: [0]=scope ratio, [1]=radius, [2]=center bearing,
      // [3]=width, [4]=danger-zone inner radius, [5]=danger-zone outer radius.
      final widthSlider = tester.widget<Slider>(find.byType(Slider).at(3));
      widthSlider.onChanged!(90);
      await tester.pump();
      widthSlider.onChangeEnd!(90);
      await settleUi(tester);

      final active =
          await readActive(tester);
      expect(active!.dangerZoneWidthDeg, 90);
      await unmount(tester);
    }, skip: true); // post-drop Drift timer hang
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
      await settleAfterDrop(tester);
      expect(find.textContaining('ANCHOR ALARM'), findsNothing);

      // Radius defaulted to 30m; move the boat ~11km away — unmistakably
      // outside any reasonable geofence radius.
      lat = 12.1;

      await tester.tap(find.byIcon(Icons.refresh));
      await settleUi(tester);

      expect(
        find.textContaining('dragged outside the safe circle'),
        findsOneWidget,
      );
      await unmount(tester);
    }, skip: true); // post-drop Drift timer hang

    testWidgets('no alarm banner while the boat stays inside the circle',
        (tester) async {
      await pumpScreen(tester,
          httpClient: hubClient(), hubService: connectedHubService);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Drop Anchor Here'));
      await settleAfterDrop(tester);

      await tester.tap(find.byIcon(Icons.refresh));
      await settleUi(tester);

      expect(find.textContaining('ANCHOR ALARM'), findsNothing);
      await unmount(tester);
    }, skip: true); // post-drop Drift timer hang

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
      await settleAfterDrop(tester);

      // Simulate losing the fix (e.g. instruments switched off).
      quality = 0;
      await tester.tap(find.byIcon(Icons.refresh));
      await settleUi(tester);

      expect(find.textContaining('ANCHOR ALARM'), findsNothing);
      expect(find.text('Anchor position unknown'), findsOneWidget);
      expect(
        find.textContaining('Connected to the Hub, but no live GPS fix'),
        findsOneWidget,
      );
      await unmount(tester);
    }, skip: true); // post-drop Drift timer hang
  });
}
