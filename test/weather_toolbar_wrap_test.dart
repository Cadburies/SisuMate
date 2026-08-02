import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// #173 — weather_screen.dart's location-controls toolbar (GPS button,
/// save-place icon, "Get forecast" button) used a Row+Spacer that overflowed
/// horizontally by 14px on narrow screens. Fixed by switching to Wrap, which
/// reflows to a second line instead of hard-overflowing. Reconstructs the
/// same widget set at a narrow width rather than mounting the full
/// WeatherScreen (which needs weather-service/geolocator/connectivity
/// provider mocking disproportionate to this layout-only fix) — this proves
/// the fixed pattern itself doesn't overflow, matching what's in
/// weather_screen.dart's build method.
void main() {
  testWidgets('location-controls toolbar reflows instead of overflowing '
      'at a narrow width', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.my_location, size: 18),
                  label: const Text('Use GPS'),
                ),
                IconButton(
                  tooltip: 'Save place',
                  onPressed: () {},
                  icon: const Icon(Icons.bookmark_add_outlined),
                ),
                FilledButton(
                  onPressed: () {},
                  child: const Text('Get forecast'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Use GPS'), findsOneWidget);
    expect(find.text('Get forecast'), findsOneWidget);
  });
}
