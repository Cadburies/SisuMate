import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/providers/shopping_provider.dart';
import 'package:sisu_mate/services/imu_sea_state_service.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/settings/polar_chart_screen.dart';

import 'test_helpers/platform_mocks.dart';

/// Polar chart shows live instrument fields that a sample would log.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ImuSeaStateService imu;

  setUp(() {
    mockConnectivityChannel();
    mockPathProviderChannel();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    imu = ImuSeaStateService();
    RevenueCatService.debugProOverrideForTests = false;
  });

  tearDown(() async {
    imu.stop();
    RevenueCatService.debugProOverrideForTests = null;
    await db.close();
  });

  testWidgets('shows Live sample fields with boat speed / TWA / TWS labels',
      (tester) async {
    await db.into(db.boats).insert(BoatsCompanion.insert(
          supabaseId: const Value('boat-polar-1'),
          name: const Value('Test Boat'),
        ));
    await db.into(db.userSettingsTable).insert(
          UserSettingsTableCompanion.insert(
            id: const Value(1),
            activeBoatSupabaseId: const Value('boat-polar-1'),
          ),
        );

    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(false)),
      // Avoid real sensors_plus platform channels in host tests.
      imuSeaStateServiceProvider.overrideWithValue(imu),
    ]);
    addTearDown(container.dispose);

    // Warm active boat so the screen leaves the "no boat" empty state.
    final boat = await container.read(activeBoatProvider.future);
    expect(boat, isNotNull);
    expect(boat!.supabaseId, 'boat-polar-1');

    await tester.binding.setSurfaceSize(const Size(400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PolarChartScreen()),
      ),
    );

    // Bounded settle for FutureProviders + post-frame IMU/instrument refresh.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Polar diagram'), findsOneWidget);
    expect(find.text('Phone IMU suggested sea state'), findsOneWidget);
    expect(find.text('Proxy Hs'), findsOneWidget);

    // ListView may lazily build below the fold — scroll into sample fields.
    await tester.scrollUntilVisible(
      find.text('Live sample fields'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.text('Live sample fields'), findsOneWidget);
    expect(find.text('Boat speed'), findsOneWidget);
    expect(find.text('TWA'), findsOneWidget);
    expect(find.text('TWS'), findsOneWidget);
    expect(find.text('SOG'), findsOneWidget);
    expect(find.text('STW'), findsOneWidget);
    expect(find.text('Sea state'), findsOneWidget);
  });
}
