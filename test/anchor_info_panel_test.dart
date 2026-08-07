import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/predictwind_datahub_service.dart';
import 'package:sisu_mate/ui/anchor/anchor_info_panel.dart';

/// #305 — Info tab shows live instrument depth independent of GPS fix.
void main() {
  PredictWindBoatData boat({
    double? depthMeters,
    double? lat,
    double? lon,
  }) =>
      PredictWindBoatData(
        latitude: lat,
        longitude: lon,
        depthMeters: depthMeters,
        observedAt: DateTime.utc(2026, 8, 1),
      );

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('shows depth when instruments report it (no GPS required)',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        AnchorInfoPanel(
          activeWatch: null,
          boatData: boat(depthMeters: 7.5),
        ),
      ),
    );

    expect(find.text('Depth'), findsOneWidget);
    expect(find.text('7.5 m'), findsOneWidget);
    expect(
      find.text('Water depth below transducer (instruments)'),
      findsOneWidget,
    );
  });

  testWidgets('shows Unavailable when depth is missing', (tester) async {
    await tester.pumpWidget(
      wrap(
        AnchorInfoPanel(
          activeWatch: null,
          boatData: boat(lat: 12, lon: -61),
        ),
      ),
    );

    expect(find.text('Depth'), findsOneWidget);
    // Depth row uses the same "Unavailable" string as other empty metrics.
    expect(find.text('Unavailable'), findsWidgets);
    expect(
      find.text('Needs a depth reading from boat instruments.'),
      findsOneWidget,
    );
  });

  testWidgets('depth still shown when an active watch exists', (tester) async {
    final watch = AnchorWatch()
      ..id = 1
      ..anchorLat = 12
      ..anchorLon = -61
      ..radiusMeters = 30
      ..scopeRatio = 5;

    await tester.pumpWidget(
      wrap(
        AnchorInfoPanel(
          activeWatch: watch,
          boatData: boat(depthMeters: 6.0, lat: 12.0001, lon: -61),
        ),
      ),
    );

    expect(find.text('Depth'), findsOneWidget);
    expect(find.text('6.0 m'), findsOneWidget);
  });
}
