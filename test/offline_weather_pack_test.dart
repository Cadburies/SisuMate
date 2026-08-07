import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/grib_download_service.dart';
import 'package:sisu_mate/services/offline_weather_pack.dart';

void main() {
  group('OfflineWeatherPack (#291)', () {
    test('fromDownload stamps TTL and isFresh until expiry', () {
      final at = DateTime.utc(2026, 8, 1);
      final e = OfflineWeatherPack.fromDownload(
        path: '/tmp/gfs.grib2',
        kind: 'wind',
        box: const GribBBox(
            latMin: 10, latMax: 12, lonMin: -62, lonMax: -60),
        downloadedAt: at,
      );
      expect(e.kind, 'wind');
      expect(e.minLat, 10);
      expect(OfflineWeatherPack.isFresh(e, at.add(const Duration(days: 1))),
          isTrue);
      expect(OfflineWeatherPack.isFresh(e, at.add(const Duration(days: 6))),
          isFalse);
    });

    test('freshOnly filters expired', () {
      final at = DateTime.utc(2026, 8, 1);
      final fresh = OfflineWeatherPack.fromDownload(
        path: 'a',
        kind: 'wave',
        downloadedAt: at,
      );
      final stale = OfflineWeatherPackEntry(
        path: 'b',
        kind: 'wind',
        downloadedAt: at.subtract(const Duration(days: 10)),
        expiresAt: at.subtract(const Duration(days: 5)),
      );
      final list = OfflineWeatherPack.freshOnly([fresh, stale], at);
      expect(list, hasLength(1));
      expect(list.single.path, 'a');
    });

    test('json round-trip', () {
      final e = OfflineWeatherPack.fromDownload(
        path: '/x',
        kind: 'wave',
        downloadedAt: DateTime.utc(2026, 8, 1, 12),
      );
      final back = OfflineWeatherPackEntry.fromJson(e.toJson());
      expect(back.path, e.path);
      expect(back.kind, e.kind);
      expect(back.downloadedAt, e.downloadedAt);
    });
  });
}
