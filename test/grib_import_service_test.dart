import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sisu_mate/services/grib_import_service.dart';

import 'test_helpers/grib_test_fixtures.dart';

/// #244: persisting an imported GRIB file into app storage and reloading
/// it fully offline afterward.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late GribImportService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('grib_import_test');
    service = GribImportService()..debugDocumentsOverride = tempDir;
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('lastImportPath / loadLastImport are null before anything is '
      'imported', () async {
    expect(await service.lastImportPath(), isNull);
    expect(await service.loadLastImport(), isNull);
  });

  test('persistImport copies the file into app storage and remembers it',
      () async {
    final bytes = buildGrib2(
      ni: 2,
      nj: 1,
      la1: 1.0,
      lo1: 1.0,
      la2: 0.0,
      lo2: 2.0,
      packedValues: [5, 15],
      refValue: 0.0,
      binaryScale: 0,
      decimalScale: 0,
      bitCount: 8,
    );
    final source = File('${tempDir.path}/picked.grb2');
    await source.writeAsBytes(bytes);

    final destPath = await service.persistImport(source.path);

    expect(destPath, isNot(source.path),
        reason: 'must copy into app storage, not just remember the '
            'original (OS-purgeable) temp path');
    expect(await File(destPath).exists(), isTrue);
    expect(await service.lastImportPath(), destPath);
  });

  test('loadLastImport re-parses the persisted file fully offline — no '
      'network involved', () async {
    final bytes = buildGrib2(
      ni: 2,
      nj: 1,
      la1: 1.0,
      lo1: 1.0,
      la2: 0.0,
      lo2: 2.0,
      packedValues: [5, 15],
      refValue: 0.0,
      binaryScale: 0,
      decimalScale: 0,
      bitCount: 8,
    );
    final source = File('${tempDir.path}/picked.grb2');
    await source.writeAsBytes(bytes);
    await service.persistImport(source.path);

    final grid = await service.loadLastImport();
    expect(grid, isNotNull);
    expect(grid!.ni, 2);
    expect(grid.valueAt(0, 0), closeTo(5.0, 1e-6));
    expect(grid.valueAt(0, 1), closeTo(15.0, 1e-6));
  });

  test('loadLastImport returns null (not an error) if the previously-'
      'imported file has since gone missing on disk', () async {
    final bytes = buildGrib2(
      ni: 1,
      nj: 1,
      la1: 0.0,
      lo1: 0.0,
      la2: 0.0,
      lo2: 0.0,
      packedValues: [1],
      refValue: 0.0,
      binaryScale: 0,
      decimalScale: 0,
      bitCount: 8,
    );
    final source = File('${tempDir.path}/picked.grb2');
    await source.writeAsBytes(bytes);
    final destPath = await service.persistImport(source.path);
    await File(destPath).delete();

    expect(await service.loadLastImport(), isNull);
  });

  test('loadLastImport returns null (not a crash) if the persisted file '
      'is corrupt', () async {
    final prefs = await SharedPreferences.getInstance();
    final corruptPath = '${tempDir.path}/corrupt.grb2';
    await File(corruptPath).writeAsBytes([1, 2, 3, 4]);
    await prefs.setString('grib_last_import_path', corruptPath);

    expect(await service.loadLastImport(), isNull);
  });
}
