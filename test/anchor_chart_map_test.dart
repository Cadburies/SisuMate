import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/ui/anchor/anchor_chart_map.dart';

/// #256 follow-up — the satellite/chart view's draggable geofence circle
/// and danger-zone sector. Drag handles are plain `Positioned` +
/// `GestureDetector` pairs (flutter_map has no built-in draggable-marker
/// widget) — exercised here by driving their `onPanUpdate`/`onPanEnd`
/// callbacks directly (equivalent to `tester.drag`, but immune to the
/// exact screen-pixel math flutter_map's tile rendering produces in a
/// headless test).
void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<AnchorWatch> dropAnchor() {
    return container.read(anchorWatchRepositoryProvider).dropAnchor(
          AnchorWatch()
            ..anchorLat = 12.0
            ..anchorLon = -61.7
            ..radiusMeters = 30,
        );
  }

  Future<void> pumpMap(
    WidgetTester tester,
    AnchorWatch watch, {
    double? boatLat,
    double? boatLon,
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: AnchorChartMap(
              activeWatch: watch,
              boatLat: boatLat,
              boatLon: boatLon,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the map with the geofence circle', (tester) async {
    final watch = await dropAnchor();
    await pumpMap(tester, watch);

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(CircleLayer), findsOneWidget);
    // Danger zone is off by default — no sector polygon yet.
    expect(find.byType(PolygonLayer), findsNothing);
  });

  testWidgets('shows a boat marker when a position is known', (tester) async {
    final watch = await dropAnchor();
    await pumpMap(tester, watch, boatLat: 12.0005, boatLon: -61.7005);

    expect(find.byIcon(Icons.directions_boat), findsOneWidget);
  });

  testWidgets('shows the danger-zone sector polygon once enabled',
      (tester) async {
    final watch = await dropAnchor();
    await container.read(anchorWatchRepositoryProvider).updateWatch(
          watch
            ..dangerZoneEnabled = true
            ..dangerZoneCenterDeg = 90
            ..dangerZoneWidthDeg = 60
            ..dangerZoneInnerRadiusMeters = 30
            ..dangerZoneOuterRadiusMeters = 40,
        );
    await pumpMap(tester, watch);

    expect(find.byType(PolygonLayer), findsOneWidget);
    // Anchor + geofence + danger-outer + danger-inner + danger-edge handles.
    expect(find.byType(GestureDetector), findsNWidgets(5));
  });

  testWidgets('dragging the geofence handle outward increases the radius',
      (tester) async {
    final watch = await dropAnchor();
    await pumpMap(tester, watch);

    // Handles: [0] anchor, [1] geofence radius.
    final handle = find.byType(GestureDetector).at(1);
    final gesture = await tester.startGesture(tester.getCenter(handle));
    // Drag east (positive dx) — away from the anchor — to grow the radius.
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    final active =
        await container.read(anchorWatchRepositoryProvider).watchActive().first;
    // #261 — a plain `greaterThan(30)` would also pass under the runaway
    // bug this was written to catch (any wildly-inflated value is still
    // "greater than 30"), so it must bound the *magnitude* too: at the
    // ~300m view fitted into this test's viewport, a 40px drag should
    // land within a couple hundred meters, not thousands.
    expect(active!.radiusMeters, greaterThan(30));
    expect(active.radiusMeters, lessThan(230));
  });

  testWidgets(
      '#261 — the radius change is roughly proportionate to the drag '
      'distance (not runaway/exponential)', (tester) async {
    final watch = await dropAnchor();
    await pumpMap(tester, watch);

    final handle = find.byType(GestureDetector).at(1);
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    final afterSmallDrag = (await container
            .read(anchorWatchRepositoryProvider)
            .watchActive()
            .first)!
        .radiusMeters;
    final smallDelta = afterSmallDrag - 30;

    // A second, independent gesture (fresh onPanStart, so no carried-over
    // drag state) dragging twice as far should move roughly twice as much
    // — under the old bug, a second drag from an already-inflated position
    // would compound further rather than scale linearly with the new
    // gesture's own distance.
    final handle2 = find.byType(GestureDetector).at(1);
    final gesture2 = await tester.startGesture(tester.getCenter(handle2));
    await gesture2.moveBy(const Offset(40, 0));
    await tester.pump();
    await gesture2.up();
    await tester.pumpAndSettle();
    final afterDoubleDrag = (await container
            .read(anchorWatchRepositoryProvider)
            .watchActive()
            .first)!
        .radiusMeters;

    // afterDoubleDrag is an absolute position (not a further delta from
    // afterSmallDrag), so it should land close to 30 + 2*smallDelta, not
    // wildly beyond it.
    expect(afterDoubleDrag, lessThan(30 + smallDelta * 2 + 100));
  });

  testWidgets('dragging the anchor handle moves the anchor position',
      (tester) async {
    final watch = await dropAnchor();
    await pumpMap(tester, watch);

    final anchorHandle = find.byType(GestureDetector).first;
    final gesture = await tester.startGesture(tester.getCenter(anchorHandle));
    await gesture.moveBy(const Offset(20, 20));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    final active =
        await container.read(anchorWatchRepositoryProvider).watchActive().first;
    expect(active!.anchorLat, isNot(12.0));
    expect(active.anchorLon, isNot(-61.7));
  });
}
