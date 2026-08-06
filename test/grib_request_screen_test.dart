import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/ui/weather/grib_request_screen.dart';

/// #245: GRIB request screen. Doesn't tap the Copy/"Open in email app"
/// buttons — those call Clipboard.setData/url_launcher's launchUrl, real
/// platform channels with no existing mock precedent in this codebase
/// (matching the same pragmatic boundary already documented for
/// file_picker's actual pick interaction). The query-string logic itself
/// is already directly covered by saildocs_query_service_test.dart; this
/// file proves the UI reflects form state into that logic correctly and
/// the actions are present.
void main() {
  // The default 800x600 test surface clips the query preview/action
  // buttons below the fold (a form with 7 fields + chips above them) — a
  // tall surface avoids needing to scroll before every assertion, same
  // fix passage_planner_screen_test.dart already documents for the same
  // reason.
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(800, 2000);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    addTearDown(binding.platformDispatcher.views.first.resetPhysicalSize);
  });

  Future<void> pumpScreen(WidgetTester tester,
      {double? initialLat, double? initialLon}) async {
    await tester.pumpWidget(MaterialApp(
      home: GribRequestScreen(initialLat: initialLat, initialLon: initialLon),
    ));
    await tester.pump();
  }

  testWidgets('shows a query preview built from the default area/params',
      (tester) async {
    await pumpScreen(tester, initialLat: 40, initialLon: -120);

    // Default box is initial +/- 2 degrees, default resolution 1,1,
    // hours include 0 for NOAA but Saildocs query drops analysis (0).
    expect(
      find.textContaining(
          'send gfs:38N,42N,122W,118W|1,1|24,48,72|WIND'),
      findsOneWidget,
    );
    expect(find.textContaining('Download free GFS for this area'), findsOneWidget);
  });

  testWidgets('editing a field updates the query preview live',
      (tester) async {
    await pumpScreen(tester, initialLat: 40, initialLon: -120);

    await tester.enterText(find.widgetWithText(TextField, 'Lat max (N)'), '50');
    await tester.pump();

    expect(find.textContaining('38N,50N'), findsOneWidget);
  });

  testWidgets('selecting an additional parameter chip adds it to the query',
      (tester) async {
    await pumpScreen(tester, initialLat: 40, initialLon: -120);

    await tester.tap(find.widgetWithText(FilterChip, 'WAVES'));
    await tester.pump();

    expect(find.textContaining('WIND,WAVES'), findsOneWidget);
  });

  testWidgets('deselecting the only parameter shows a clear "enter valid" '
      'message instead of an empty/broken query', (tester) async {
    await pumpScreen(tester, initialLat: 40, initialLon: -120);

    await tester.tap(find.widgetWithText(FilterChip, 'WIND'));
    await tester.pump();

    expect(find.textContaining('Enter valid area/resolution/hours'),
        findsOneWidget);
  });

  testWidgets('Copy and "Open in email app" actions are present',
      (tester) async {
    await pumpScreen(tester, initialLat: 40, initialLon: -120);

    expect(find.widgetWithText(ElevatedButton, 'Copy'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Open in email app'),
        findsOneWidget);
  });
}
