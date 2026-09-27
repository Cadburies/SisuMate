import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/polar_background_collector.dart';
import 'package:sisu_mate/services/predictwind_datahub_service.dart';
import 'package:sisu_mate/services/ydwg_nmea_service.dart';

import 'test_helpers/platform_mocks.dart';

/// #388: focused coverage for platform services the Feature Map points at
/// that had no test of their own (system/platform/*).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('YdwgNmeaService.hostFromUrl', () {
    test('extracts the host from a URL, host:port or bare IP', () {
      expect(YdwgNmeaService.hostFromUrl('http://192.168.10.30'), '192.168.10.30');
      expect(YdwgNmeaService.hostFromUrl('192.168.10.30:1456'), '192.168.10.30');
      expect(YdwgNmeaService.hostFromUrl('  10.0.0.5  '), '10.0.0.5');
    });

    test('empty or missing input gives null', () {
      expect(YdwgNmeaService.hostFromUrl(null), isNull);
      expect(YdwgNmeaService.hostFromUrl('   '), isNull);
    });
  });

  group('polar collection', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      mockConnectivityChannel();
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(db)]);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('SailingPolarCollector never records while an engine is running', () async {
      final collector = container.read(sailingPolarCollectorProvider);
      final stored = await collector.maybeRecord(
        boatSupabaseId: 'boat-1',
        data: PredictWindBoatData(
          observedAt: DateTime.utc(2026, 9, 26, 12),
          windSpeedKt: 14,
          windDirectionDeg: 90,
          stwKt: 6.5,
          sogKt: 6.2,
          cogDeg: 0,
          enginePortRpm: 1800,
        ),
      );
      expect(stored, isFalse);
      expect(await collector.sampleCount('boat-1'), 0);
    });

    test('sample counts by sea state start at zero for every bucket', () async {
      final counts = await container.read(sailingPolarCollectorProvider).sampleCountsBySeaState('boat-1');
      expect(counts, isNotEmpty);
      expect(counts.values.every((v) => v == 0), isTrue);
    });

    test('PolarBackgroundCollector.tick with no active boat stores nothing', () async {
      final collector = container.read(sailingPolarCollectorProvider);
      final background = PolarBackgroundCollector(
        collector: collector,
        boatRepository: container.read(boatRepositoryProvider),
        settingsRepository: container.read(userSettingsRepositoryProvider),
      );
      await background.tick();
      expect(await collector.sampleCount('boat-1'), 0);
    });
  });
}
