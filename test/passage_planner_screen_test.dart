import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/ui/weather/passage_planner_screen.dart';

/// Widget-level coverage for the passage planner (TEST1b, "weather UI pump").
/// `WeatherScreen` itself isn't pumped here — its `initState` chains real
/// Geolocator platform-channel calls and a live Open-Meteo network fetch with
/// no injection seam, which `weather_service_test.dart` already sidesteps by
/// testing only the pure parsing/calculation functions. PassagePlannerScreen
/// is self-contained (no Riverpod, no network/platform calls in initState),
/// so it's the one weather screen safely pumpable without those hazards.
void main() {
  // The default 800x600 test surface clips the 3rd waypoint editor below the
  // fold (a growing ListView + map + stats card overflow it), so `find.text`
  // (skipOffstage: true by default) can't see it. Use a tall surface instead
  // of scrolling, so every test can assert directly without extra drag steps.
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(800, 2400);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    addTearDown(binding.platformDispatcher.views.first.resetPhysicalSize);
  });

  testWidgets('shows two default waypoints and a computed passage summary',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PassagePlannerScreen()));
    await tester.pump();

    expect(find.text('Passage Planner'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Departure'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Waypoint 1'), findsOneWidget);
    expect(find.text('Distance'), findsOneWidget);
    expect(find.text('ETA'), findsOneWidget);
    expect(find.text('Fuel'), findsOneWidget);
    // No delete button with only 2 waypoints (minimum kept).
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('Add waypoint appends a new stop and enables delete on all rows',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PassagePlannerScreen()));
    await tester.pump();

    await tester.tap(find.byTooltip('Add waypoint'));
    await tester.pump();

    expect(find.widgetWithText(TextFormField, 'Waypoint 2'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsNWidgets(3));
  });

  testWidgets('changing speed updates the field and recomputes without crashing',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PassagePlannerScreen()));
    await tester.pump();

    await tester.enterText(find.widgetWithText(TextField, 'Speed (kn)'), '12');
    await tester.pump();

    final speedField =
        tester.widget<TextField>(find.widgetWithText(TextField, 'Speed (kn)'));
    expect(speedField.controller!.text, '12');
    expect(find.text('ETA'), findsOneWidget);
  });
}
