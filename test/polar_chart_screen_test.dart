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

/// #281 — Polar chart tabs: Diagram · Boat · Sea state.
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

  Future<void> pumpPolar(WidgetTester tester) async {
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
      imuSeaStateServiceProvider.overrideWithValue(imu),
    ]);
    addTearDown(container.dispose);

    final boat = await container.read(activeBoatProvider.future);
    expect(boat, isNotNull);

    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PolarChartScreen()),
      ),
    );

    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('shows three tabs: Diagram, Boat, Sea state', (tester) async {
    await pumpPolar(tester);

    expect(find.text('Polar diagram'), findsOneWidget);
    expect(find.text('Diagram'), findsOneWidget);
    expect(find.text('Boat'), findsOneWidget);
    expect(find.text('Sea state'), findsOneWidget);
  });

  testWidgets('Diagram tab has improve action; instrument fields are on Boat',
      (tester) async {
    await pumpPolar(tester);

    // Default tab = Diagram
    expect(find.text('Improve offline'), findsOneWidget);
    // #292 — coverage line always present (0% with no samples).
    expect(find.textContaining('Measured coverage:'), findsOneWidget);
    expect(find.text('Live sample fields'), findsNothing);
    expect(find.text('Phone IMU suggested sea state'), findsNothing);

    await tester.tap(find.text('Boat'));
    await tester.pumpAndSettle();

    expect(find.text('Live sample fields'), findsOneWidget);
    expect(find.text('Boat speed'), findsOneWidget);
    expect(find.text('TWA'), findsOneWidget);
    expect(find.text('TWS'), findsOneWidget);
    expect(find.text('SOG'), findsOneWidget);
    expect(find.text('STW'), findsOneWidget);
    // Sea-state IMU card not on Boat tab.
    expect(find.text('Phone IMU suggested sea state'), findsNothing);
  });

  testWidgets('Sea state tab shows working sea state + phone IMU card',
      (tester) async {
    await pumpPolar(tester);

    await tester.tap(find.text('Sea state'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Working sea state'), findsOneWidget);
    expect(find.text('Samples by sea state'), findsOneWidget);
    expect(find.text('Phone IMU suggested sea state'), findsOneWidget);
    expect(find.text('Proxy Hs'), findsOneWidget);
    expect(find.text('Live sample fields'), findsNothing);
    expect(find.text('Improve offline'), findsNothing);
  });
}
