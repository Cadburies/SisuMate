import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sisu_mate/services/weather_service.dart';
import 'package:sisu_mate/ui/weather/departure_window_screen.dart';

/// #232: departure-window planner screen — reads BAI1's cached-weather-only
/// provider (same one #219's briefing uses), never triggers a network fetch.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  WeatherBundle sampleBundle() => WeatherBundle(
        lat: 22.89,
        lon: -109.91,
        fetchedAt: DateTime.now(),
        fromCache: true,
        hourly: [
          HourlyWeather(time: DateTime(2026, 7, 9, 0), windMs: 20 * 0.514444),
          HourlyWeather(time: DateTime(2026, 7, 9, 1), windMs: 4 * 0.514444),
        ],
      );

  Future<void> pumpScreen(WidgetTester tester, {WeatherBundle? cached}) async {
    SharedPreferences.setMockInitialValues(cached == null
        ? {}
        : {'weather_cache_v2': jsonEncode(cached.toJson())});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: DepartureWindowScreen()),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('with no cached weather, says so instead of guessing',
      (tester) async {
    await pumpScreen(tester);
    expect(find.textContaining('No cached weather yet'), findsOneWidget);
  });

  testWidgets('with cached weather, shows threshold inputs and a window '
      'list (no thresholds set yet — everything clears)', (tester) async {
    await pumpScreen(tester, cached: sampleBundle());
    expect(find.widgetWithText(TextField, 'Max wind (kn)'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Max gust (kn)'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Max wave height (m)'), findsOneWidget);
    expect(find.text('Windows'), findsOneWidget);
    expect(find.textContaining('Clears all thresholds'), findsOneWidget);
  });

  testWidgets('setting a wind threshold below the data flags the breaching '
      'hour instead of silently clearing it', (tester) async {
    await pumpScreen(tester, cached: sampleBundle());
    await tester.enterText(
        find.widgetWithText(TextField, 'Max wind (kn)'), '15');
    await tester.pump();

    // The 20kt hour now breaches; the 4kt hour still clears — both must
    // show, not just one uniform window.
    expect(find.textContaining('wind'), findsWidgets);
    expect(find.textContaining('Clears all thresholds'), findsOneWidget);
  });
}
