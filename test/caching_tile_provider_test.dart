import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sisu_mate/services/map_tile_cache_service.dart';
import 'package:sisu_mate/ui/weather/caching_tile_provider.dart';

/// A minimal valid PNG (1x1 transparent pixel) — real bytes are needed
/// since this exercises the actual image decode pipeline, not just file IO.
final _onePixelPng = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, //
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, //
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, //
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, //
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, //
  0x42, 0x60, 0x82, //
]);

Future<ui.Image> _resolve(ImageProvider provider) {
  final completer = Completer<ui.Image>();
  final stream = provider.resolve(ImageConfiguration.empty);
  late ImageStreamListener listener;
  listener = ImageStreamListener(
    (image, synchronousCall) {
      completer.complete(image.image);
      stream.removeListener(listener);
    },
    onError: (error, stack) {
      completer.completeError(error);
      stream.removeListener(listener);
    },
  );
  stream.addListener(listener);
  return completer.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late MapTileCacheService cacheService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('caching_tile_test');
    cacheService = MapTileCacheService();
    await cacheService.setCacheFolderOverride(tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('#240: a cache miss fetches over the network and writes the tile '
      'to disk for next time', () async {
    var requestCount = 0;
    final client = MockClient((request) async {
      requestCount++;
      return http.Response.bytes(_onePixelPng, 200);
    });

    final provider = CachingTileProvider(
      providerId: 'osm',
      cacheService: cacheService,
      httpClient: client,
    );
    final image = provider.getImage(
      const TileCoordinates(5, 6, 7),
      TileLayer(urlTemplate: 'https://tile.example/{z}/{x}/{y}.png'),
    );

    final decoded = await _resolve(image);
    expect(decoded.width, 1);
    expect(requestCount, 1);

    // The disk write is fire-and-forget (unawaited) so the decoded image
    // isn't held up by slow disk I/O — poll briefly rather than asserting
    // immediately, which would race it.
    final file = await cacheService.tileFile('osm', 7, 5, 6);
    var wrote = false;
    for (var i = 0; i < 20 && !wrote; i++) {
      wrote = await file.exists();
      if (!wrote) await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    expect(wrote, isTrue,
        reason: 'a fetched tile must be written through to disk');
  });

  test('#240: a cache hit reads from disk and never touches the network',
      () async {
    final file = await cacheService.tileFile('osm', 3, 1, 2);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(_onePixelPng);

    final client = MockClient((request) async {
      fail('a cached tile must not trigger a network request');
    });

    final provider = CachingTileProvider(
      providerId: 'osm',
      cacheService: cacheService,
      httpClient: client,
    );
    final image = provider.getImage(
      const TileCoordinates(1, 2, 3),
      TileLayer(urlTemplate: 'https://tile.example/{z}/{x}/{y}.png'),
    );

    final decoded = await _resolve(image);
    expect(decoded.width, 1);
  });
}
