import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/units.dart';
import 'package:sisu_mate/ui/weather/passage_planner_screen.dart';

/// Widget-level coverage for the passage planner (TEST1b, "weather UI pump").
/// `WeatherScreen` itself isn't pumped here - its `initState` chains real
/// Geolocator / network. Passage planner only needs Riverpod for unit system.
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

  Future<ProviderContainer> pumpPlanner(
    WidgetTester tester, {
    bool imperial = false,
  }) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    if (imperial) {
      container.read(unitPrefsProvider.notifier).restore(AppUnitPrefs.us);
    }
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PassagePlannerScreen()),
      ),
    );
    await tester.pump();
    return container;
  }

  testWidgets('shows two default waypoints and a computed passage summary',
      (tester) async {
    await pumpPlanner(tester);

    expect(find.text('Passage Planner'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Departure'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Waypoint 1'), findsOneWidget);
    expect(find.text('Distance'), findsOneWidget);
    expect(find.text('ETA'), findsOneWidget);
    expect(find.text('Fuel'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Fuel L/h'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Speed (kn)'), findsOneWidget);
    // No delete button with only 2 waypoints (minimum kept).
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('SUG3: US unit prefs label fuel as gal/h', (tester) async {
    await pumpPlanner(tester, imperial: true);
    expect(find.widgetWithText(TextField, 'Fuel gal/h'), findsOneWidget);
  });

  testWidgets('Add waypoint appends a new stop and enables delete on all rows',
      (tester) async {
    await pumpPlanner(tester);

    await tester.tap(find.byTooltip('Add waypoint'));
    await tester.pump();

    expect(find.widgetWithText(TextFormField, 'Waypoint 2'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsNWidgets(3));
  });

  testWidgets('changing speed updates the field and recomputes without crashing',
      (tester) async {
    await pumpPlanner(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Speed (kn)'), '12');
    await tester.pump();

    final speedField =
        tester.widget<TextField>(find.widgetWithText(TextField, 'Speed (kn)'));
    expect(speedField.controller!.text, '12');
    expect(find.text('ETA'), findsOneWidget);
  });
}
