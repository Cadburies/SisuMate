import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sisu_mate/services/grib_download_service.dart';
import 'package:sisu_mate/services/grib_import_service.dart';

import 'test_helpers/grib_test_fixtures.dart';

Uint8List _tinyGrib() => buildGrib2(
      ni: 2,
      nj: 2,
      la1: 13,
      lo1: -63,
      la2: 11,
      lo2: -60,
      packedValues: [0, 1, 2, 3],
      refValue: 0,
      binaryScale: 0,
      decimalScale: 0,
      bitCount: 8,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GribBBox', () {
    test('fromPoints pads a single point into a usable box', () {
      final box = GribBBox.fromPoints(
        [(lat: 12.0, lon: -61.75)],
        marginDeg: 1.0,
        minHalfSpanDeg: 0.5,
      );
      expect(box.latMin, lessThan(12.0));
      expect(box.latMax, greaterThan(12.0));
      expect(box.lonMin, lessThan(-61.75));
      expect(box.lonMax, greaterThan(-61.75));
    });

    test('fromPoints covers a route and pads', () {
      final box = GribBBox.fromPoints([
        (lat: 12.0, lon: -61.8),
        (lat: 13.0, lon: -61.0),
      ], marginDeg: 0.5);
      expect(box.latMin, lessThan(12.0));
      expect(box.latMax, greaterThan(13.0));
      expect(box.lonMin, lessThan(-61.8));
      expect(box.lonMax, greaterThan(-61.0));
    });
  });

  group('buildNomadsGfs025Url', () {
    test('targets filter_gfs_0p25.pl with wind + subregion', () {
      final uri = GribDownloadService.buildNomadsGfs025Url(
        box: const GribBBox(
          latMin: 11,
          latMax: 13,
          lonMin: -63,
          lonMax: -60,
        ),
        cycleUtc: DateTime.utc(2026, 8, 6, 6),
        forecastHour: 24,
      );
      expect(uri.host, 'nomads.ncep.noaa.gov');
      expect(uri.path, '/cgi-bin/filter_gfs_0p25.pl');
      expect(uri.queryParameters['file'], 'gfs.t06z.pgrb2.0p25.f024');
      expect(uri.queryParameters['var_UGRD'], 'on');
      expect(uri.queryParameters['var_VGRD'], 'on');
      expect(uri.queryParameters['lev_10_m_above_ground'], 'on');
      // -63°E → 297 in 0–360
      expect(double.parse(uri.queryParameters['leftlon']!), closeTo(297, 0.01));
      expect(double.parse(uri.queryParameters['rightlon']!), closeTo(300, 0.01));
      expect(uri.queryParameters['toplat'], '13.00');
      expect(uri.queryParameters['bottomlat'], '11.00');
      expect(uri.queryParameters['dir'], '/gfs.20260806/06/atmos');
    });

    test('lon0to360 maps negative longitudes', () {
      expect(GribDownloadService.lon0to360(-61.75), closeTo(298.25, 0.01));
      expect(GribDownloadService.lon0to360(10), 10);
    });

    test('buildNomadsGfsWaveUrl targets filter_gfswave.pl', () {
      final uri = GribDownloadService.buildNomadsGfsWaveUrl(
        box: const GribBBox(
          latMin: 11,
          latMax: 13,
          lonMin: -63,
          lonMax: -60,
        ),
        cycleUtc: DateTime.utc(2026, 8, 6, 6),
        forecastHour: 24,
      );
      expect(uri.path, '/cgi-bin/filter_gfswave.pl');
      expect(uri.queryParameters['var_HTSGW'], 'on');
      expect(uri.queryParameters['file'], contains('gfswave'));
    });
  });

  group('candidateCycles', () {
    test('returns 6-hour steps newest first', () {
      final cycles = GribDownloadService.candidateCycles(
        DateTime.utc(2026, 8, 6, 15),
        max: 4,
      );
      expect(cycles.length, 4);
      for (final c in cycles) {
        expect(c.hour % 6, 0);
      }
      expect(cycles.first.isAfter(cycles.last), isTrue);
    });
  });

  group('downloadNoaaGfs', () {
    test('concatenates multi-hour GRIBs and persists', () async {
      final grib = _tinyGrib();
      final dir = await Directory.systemTemp.createTemp('grib_dl_');
      addTearDown(() => dir.delete(recursive: true));

      final import = GribImportService()..debugDocumentsOverride = dir;
      final client = MockClient((request) async {
        // f000 probe + f0/f24 downloads
        final file = request.url.queryParameters['file'] ?? '';
        if (file.contains('f000') || file.contains('f024')) {
          return http.Response.bytes(grib, 200);
        }
        return http.Response('missing', 404);
      });

      final svc = GribDownloadService(client: client, importService: import);
      addTearDown(svc.close);

      final result = await svc.downloadNoaaGfs(
        box: const GribBBox(
          latMin: 11,
          latMax: 13,
          lonMin: -63,
          lonMax: -60,
        ),
        forecastHours: const [0, 24],
      );

      expect(result.ok, isTrue, reason: result.message);
      expect(result.path, isNotNull);
      expect(File(result.path!).existsSync(), isTrue);
      final saved = await File(result.path!).readAsBytes();
      // Two messages concatenated (probe also may hit f000 then download f000+f024).
      expect(saved.length, greaterThanOrEqualTo(grib.length * 2));
      expect(result.hoursDownloaded, 2);
      expect(result.source, FreeGribSource.noaaGfs025);
    });

    test('failure when no cycle returns GRIB', () async {
      final client = MockClient((_) async => http.Response('no', 404));
      final svc = GribDownloadService(client: client);
      addTearDown(svc.close);
      final result = await svc.downloadNoaaGfs(
        box: const GribBBox(latMin: 0, latMax: 1, lonMin: 0, lonMax: 1),
        forecastHours: const [0],
      );
      expect(result.ok, isFalse);
      expect(result.message, contains('No free NOAA'));
    });
  });

  group('persistBytes', () {
    test('writes and remembers last path', () async {
      final dir = await Directory.systemTemp.createTemp('grib_bytes_');
      addTearDown(() => dir.delete(recursive: true));
      final import = GribImportService()..debugDocumentsOverride = dir;
      final path = await import.persistBytes(
        Uint8List.fromList([0x47, 0x52, 0x49, 0x42, 0, 0, 0, 2]),
        suggestedName: 'test_gfs',
      );
      expect(File(path).existsSync(), isTrue);
      expect(await import.lastImportPath(), path);
    });
  });
}
