import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/ui/anchor/save_anchor_spot_dialog.dart';
import 'package:sisu_mate/ui/anchor/share_anchor_spot_dialog.dart';

void main() {
  testWidgets('#328: Save is disabled-by-validation until name is filled',
      (tester) async {
    AnchorSpot? result;
    final watch = AnchorWatch()
      ..anchorLat = 12
      ..anchorLon = -61
      ..radiusMeters = 30
      ..scopeRatio = 5;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showSaveAnchorSpotDialog(context, watch: watch);
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(find.text('Name is required'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Marsh Harbour');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result!.name, 'Marsh Harbour');
    expect(result!.lat, 12);
    expect(result!.lon, -61);
    expect(result!.radiusMeters, 30);
  });

  testWidgets('#328: share dialog returns includeCoordinates choice',
      (tester) async {
    ShareAnchorSpotResult? result;
    final spot = AnchorSpot()
      ..name = 'Marsh Harbour'
      ..lat = 26.54
      ..lon = -77.06;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showShareAnchorSpotDialog(context, spot);
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Include drop coordinates'), findsOneWidget);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Publish'));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result!.includeCoordinates, isFalse);
  });
}
