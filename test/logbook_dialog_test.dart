import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/location_service.dart';
import 'package:sisu_mate/ui/logbook/logbook_screen.dart';

/// Injectable [LocationService] test double — returns whatever canned
/// [LocationResult] the test sets, no real GPS/platform channel involved.
class _FakeLocationService implements LocationService {
  final LocationResult result;
  const _FakeLocationService(this.result);

  @override
  Future<LocationResult> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.medium,
    Duration timeLimit = const Duration(seconds: 12),
  }) async =>
      result;
}

Position _fakePosition({
  double lat = 33.4484,
  double lon = -112.0740,
  double speed = 0.0,
  double speedAccuracy = 0.0,
  double heading = 0.0,
  double headingAccuracy = 0.0,
}) =>
    Position(
      latitude: lat,
      longitude: lon,
      timestamp: DateTime(2026, 1, 1),
      accuracy: 5.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: heading,
      headingAccuracy: headingAccuracy,
      speed: speed,
      speedAccuracy: speedAccuracy,
    );

Future<void> _pump(
  WidgetTester tester, {
  CaptainLogEntry? existing,
  CaptainLogEntry? previousEntry,
  LocationService? locationService,
  required Future<void> Function(CaptainLogEntry) onSave,
}) {
  return tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: AddEditCaptainLogDialog(
        existing: existing,
        previousEntry: previousEntry,
        locationService: locationService,
        onSave: onSave,
      ),
    ),
  ));
}

void main() {
  group('AddEditCaptainLogDialog', () {
    testWidgets('saves a new log entry with notes and weather', (tester) async {
      CaptainLogEntry? saved;
      await _pump(tester, onSave: (e) async => saved = e);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Notes'), 'Left anchorage at 0800');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Weather'), 'Clear, light breeze');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Wind (kt)'), '12');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(saved, isNotNull);
      expect(saved!.notes, 'Left anchorage at 0800');
      expect(saved!.weather, 'Clear, light breeze');
      expect(saved!.windSpeedKt, 12);
      expect(saved!.supabaseId, startsWith('log_'));
    });

    testWidgets('rejects invalid wind speed number', (tester) async {
      var saveCalled = false;
      await _pump(tester, onSave: (_) async => saveCalled = true);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Wind (kt)'), 'not-a-number');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(saveCalled, isFalse);
      expect(find.text('Invalid number'), findsOneWidget);
    });

    testWidgets('pre-fills fields when editing an existing entry',
        (tester) async {
      final existing = CaptainLogEntry()
        ..supabaseId = 'log_existing'
        ..boatSupabaseId = '00000000-0000-0000-0000-000000000000'
        ..notes = 'Night watch'
        ..weather = 'Overcast'
        ..windSpeedKt = 8
        ..crewOnBoard = ['Alex', 'Sam'];

      CaptainLogEntry? saved;
      await _pump(
        tester,
        existing: existing,
        onSave: (e) async => saved = e,
      );

      expect(find.text('Night watch'), findsOneWidget);
      expect(find.text('Overcast'), findsOneWidget);
      expect(find.text('Alex, Sam'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(saved!.supabaseId, 'log_existing');
      expect(saved!.notes, 'Night watch');
      expect(saved!.crewOnBoard, ['Alex', 'Sam']);
    });

    testWidgets('saves the new #213 fields (SOG/COG/pressure/sea state/'
        'watch crew/engine hours/fuel level)', (tester) async {
      CaptainLogEntry? saved;
      await _pump(tester, onSave: (e) async => saved = e);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'SOG (kt)'), '6.5');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'COG (°true)'), '180');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Pressure (hPa)'), '1013');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Sea state'), 'Slight');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Engine hrs'), '412.5');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Fuel level (%)'), '75');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'On watch'), 'Jamie, Robin');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(saved!.sogKt, 6.5);
      expect(saved!.cogDeg, 180);
      expect(saved!.barometricPressureHpa, 1013);
      expect(saved!.seaState, 'Slight');
      expect(saved!.engineHours, 412.5);
      expect(saved!.fuelLevelPercent, 75);
      expect(saved!.watchCrew, ['Jamie', 'Robin']);
    });

    testWidgets(
        '"Use GPS" fills Lat/Lng and SOG/COG from a fix that reports them',
        (tester) async {
      CaptainLogEntry? saved;
      final fix = _fakePosition(
        lat: 33.4484,
        lon: -112.0740,
        speed: 3.086664, // ~6.0 kt
        speedAccuracy: 1.0,
        heading: 270.0,
        headingAccuracy: 5.0,
      );
      await _pump(
        tester,
        locationService: _FakeLocationService(LocationResult.success(fix)),
        onSave: (e) async => saved = e,
      );

      await tester.tap(find.text('Use GPS'));
      await tester.pump();

      expect(find.text('33.4484'), findsOneWidget);
      expect(find.text('-112.0740'), findsOneWidget);
      expect(find.text('6.0'), findsOneWidget); // SOG converted m/s -> kt
      expect(find.text('270'), findsOneWidget); // COG

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(saved!.positionLat, 33.4484);
      expect(saved!.positionLng, -112.0740);
      expect(saved!.sogKt, closeTo(6.0, 0.05));
      expect(saved!.cogDeg, 270);
    });

    testWidgets(
        '"Use GPS" leaves SOG/COG blank when the fix reports zero accuracy '
        'for them (geolocator\'s "unavailable" signal, not a real 0)',
        (tester) async {
      final fix = _fakePosition(speed: 0.0, speedAccuracy: 0.0,
          heading: 0.0, headingAccuracy: 0.0);
      await _pump(
        tester,
        locationService: _FakeLocationService(LocationResult.success(fix)),
        onSave: (_) async {},
      );

      await tester.tap(find.text('Use GPS'));
      await tester.pump();

      expect(find.widgetWithText(TextFormField, 'SOG (kt)').evaluate().length,
          1);
      final sogField =
          tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'SOG (kt)'));
      expect(sogField.controller!.text, isEmpty);
    });

    testWidgets('"Use GPS" surfaces a snackbar and fills nothing on failure',
        (tester) async {
      await _pump(
        tester,
        locationService: const _FakeLocationService(
          LocationResult.failure(LocationFailureReason.permissionDenied),
        ),
        onSave: (_) async {},
      );

      await tester.tap(find.text('Use GPS'));
      await tester.pump();

      expect(find.textContaining('Location permission denied'), findsOneWidget);
      final latField =
          tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'Latitude'));
      expect(latField.controller!.text, isEmpty);
    });

    testWidgets(
        'new entry pre-fills crew/on-watch from the previous entry, but '
        'NOT position/SOG/COG (#213 — those must come from an explicit '
        'GPS tap, never stale carry-forward)', (tester) async {
      final previous = CaptainLogEntry()
        ..supabaseId = 'log_prev'
        ..boatSupabaseId = '00000000-0000-0000-0000-000000000000'
        ..crewOnBoard = ['Alex', 'Sam']
        ..watchCrew = ['Alex']
        ..positionLat = 10.0
        ..positionLng = 20.0
        ..sogKt = 5.0
        ..cogDeg = 90.0;

      CaptainLogEntry? saved;
      await _pump(
        tester,
        previousEntry: previous,
        onSave: (e) async => saved = e,
      );

      expect(find.text('Alex, Sam'), findsOneWidget); // crew carried forward
      expect(find.text('Alex'), findsOneWidget); // watch crew carried forward
      final latField =
          tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'Latitude'));
      expect(latField.controller!.text, isEmpty,
          reason: 'position must never be carried forward, only from GPS');
      final sogField =
          tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'SOG (kt)'));
      expect(sogField.controller!.text, isEmpty);

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(saved!.crewOnBoard, ['Alex', 'Sam']);
      expect(saved!.watchCrew, ['Alex']);
      expect(saved!.positionLat, isNull);
    });

    testWidgets('editing an existing entry ignores previousEntry entirely',
        (tester) async {
      final existing = CaptainLogEntry()
        ..supabaseId = 'log_existing'
        ..boatSupabaseId = '00000000-0000-0000-0000-000000000000'
        ..crewOnBoard = ['Taylor'];
      final previous = CaptainLogEntry()
        ..supabaseId = 'log_prev'
        ..boatSupabaseId = '00000000-0000-0000-0000-000000000000'
        ..crewOnBoard = ['SomeoneElse'];

      await _pump(
        tester,
        existing: existing,
        previousEntry: previous,
        onSave: (_) async {},
      );

      expect(find.text('Taylor'), findsOneWidget);
      expect(find.text('SomeoneElse'), findsNothing);
    });
  });
}
