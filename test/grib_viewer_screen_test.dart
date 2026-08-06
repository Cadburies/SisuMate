import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/grib_import_service.dart';
import 'package:sisu_mate/services/grib_parser_service.dart';
import 'package:sisu_mate/ui/weather/grib_viewer_screen.dart';

import 'test_helpers/grib_test_fixtures.dart';

/// #244: GRIB viewer screen. Uses an in-memory fake [GribImportService]
/// (see [_FakeGribImportService]) rather than real dart:io File I/O —
/// GribImportService's actual disk-persistence/reload behavior is already
/// thoroughly covered directly by grib_import_service_test.dart. Real I/O
/// inside a `testWidgets` body needs every single call wrapped in
/// `tester.runAsync()` (not just the pump) or it hangs for the full test
/// timeout instead of failing fast — a fake sidesteps that entirely and
/// keeps this file testing what it's actually meant to: does the UI react
/// correctly to whatever the service returns.
class _FakeGribImportService extends GribImportService {
  final GribGrid? canned;
  _FakeGribImportService(this.canned);

  @override
  Future<GribGrid?> loadLastImport() async => canned;
}

void main() {
  test('isGribFilePath accepts marine GRIB suffixes only', () {
    expect(isGribFilePath('/tmp/a.grb'), isTrue);
    expect(isGribFilePath('/tmp/a.GRB2'), isTrue);
    expect(isGribFilePath('/tmp/a.grib'), isTrue);
    expect(isGribFilePath('/tmp/a.grib2'), isTrue);
    expect(isGribFilePath('/tmp/a.jpg'), isFalse);
    expect(isGribFilePath('/tmp/a'), isFalse);
  });

  testWidgets('with no prior import, says so instead of showing a blank '
      'screen', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: GribViewerScreen(importService: _FakeGribImportService(null)),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('No GRIB file imported yet'), findsOneWidget);
  });

  testWidgets(
      'a previously-imported grid renders its metadata and values on '
      'screen open — no re-pick, no network', (tester) async {
    final bytes = buildGrib2(
      ni: 3,
      nj: 2,
      la1: 10.0,
      lo1: 20.0,
      la2: 9.0,
      lo2: 21.0,
      packedValues: [0, 10, 20, 30, 40, 50],
      refValue: 50.0,
      binaryScale: 0,
      decimalScale: 1,
      bitCount: 8,
    );
    final grid = parseGrib2(bytes);

    await tester.pumpWidget(MaterialApp(
      home: GribViewerScreen(importService: _FakeGribImportService(grid)),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('3 × 2 points'), findsOneWidget);
    expect(find.textContaining('No GRIB file imported yet'), findsNothing);
  });

  testWidgets('a grid too large for the cell-by-cell preview shows summary '
      'stats instead, not a runaway widget tree', (tester) async {
    final grid = GribGrid(
      ni: 20,
      nj: 20, // 400 points > the 200-point preview cap
      la1: 0,
      lo1: 0,
      la2: -1,
      lo2: 1,
      values: List<double>.filled(400, 5.0),
      parameterCategory: 2,
      parameterNumber: 2,
      forecastTimeUnit: 1,
      forecastTime: 0,
    );

    await tester.pumpWidget(MaterialApp(
      home: GribViewerScreen(importService: _FakeGribImportService(grid)),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('too many to show cell-by-cell'),
        findsOneWidget);
  });
}
