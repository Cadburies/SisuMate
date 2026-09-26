import 'package:flutter_test/flutter_test.dart';

import '_reach.dart';

/// Feature Map scripts for `.ai_context/feature_map/home/weather*`. Live
/// forecasts, GPS and GRIB files need a device (host tests block HTTP).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home/weather', (tester) async {
    await reach(tester, 'home/weather');
    expect(find.text('Get forecast'), findsOneWidget);
  });

  testWidgets('home/weather/save_place', (tester) async {
    await reach(tester, 'home/weather/save_place');
    expect(find.text('Saved places'), findsOneWidget);
    expect(find.text('Saved "Cape Town"'), findsOneWidget);
  });

  testWidgets('home/weather/passage_planner', (tester) async {
    await reach(tester, 'home/weather/passage_planner');
    expect(find.text('Distance'), findsOneWidget);
    expect(find.text('ETA'), findsOneWidget);
  });

  testWidgets('home/weather/passage_planner/add_waypoint', (tester) async {
    await reach(tester, 'home/weather/passage_planner/add_waypoint');
    expect(find.text('3'), findsWidgets);
  });

  testWidgets('home/weather/passage_planner/isochrone', (tester) async {
    await reach(tester, 'home/weather/passage_planner/isochrone');
    expect(find.text('Set boat polar data in Settings (Boat Polar Data) first.'), findsOneWidget);
  });

  testWidgets('home/weather/passage_planner/safety_briefing', (tester) async {
    await reach(tester, 'home/weather/passage_planner/safety_briefing');
    expect(find.text('AI: Weather safety briefing'), findsOneWidget);
  });

  testWidgets('home/weather/departure_window', (tester) async {
    await reach(tester, 'home/weather/departure_window');
    expect(find.textContaining('No cached weather yet'), findsOneWidget);
  });

  testWidgets('home/weather/grib_viewer', (tester) async {
    await reach(tester, 'home/weather/grib_viewer');
    expect(find.byTooltip('Import GRIB file'), findsOneWidget);
  });

  testWidgets('home/weather/grib_download', (tester) async {
    await reach(tester, 'home/weather/grib_download');
    expect(find.text('Download free GFS wind for this area'), findsOneWidget);
  });
}
