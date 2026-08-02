import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sisu_mate/core/app_router.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/maintenance/maintenance_items_screen.dart';

import 'test_helpers/platform_mocks.dart';

/// #179: tapping a maintenance item must open the shared CheckPageViewer
/// (same as Checklists/Safety), not the old bespoke AlertDialog.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  const groupId = 'grp_maint';
  const itemId = 'maint_bilge';

  setUp(() {
    mockConnectivityChannel();
    mockPathProviderChannel();
    mockSharedPreferencesChannel();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    RevenueCatService.debugProOverrideForTests = true;
  });

  tearDown(() async {
    RevenueCatService.debugProOverrideForTests = null;
    await db.close();
  });

  testWidgets('tapping a maintenance item opens CheckPageViewer via the '
      'shared route, not an AlertDialog', (tester) async {
    await db.into(db.checklistGroups).insert(ChecklistGroupsCompanion.insert(
          supabaseId: const Value(groupId),
          boatSupabaseId: const Value('boat_1'),
          appType: const Value('maintenance'),
          title: const Value('Engine Room'),
        ));
    await db.into(db.checklistItems).insert(ChecklistItemsCompanion.insert(
          supabaseId: const Value(itemId),
          boatSupabaseId: const Value('boat_1'),
          groupSupabaseId: const Value(groupId),
          title: const Value('Check bilge pump'),
          name: const Value('Check bilge pump'),
        ));

    final group = ChecklistGroup()
      ..supabaseId = groupId
      ..boatSupabaseId = 'boat_1'
      ..appType = 'maintenance'
      ..title = 'Engine Room';

    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(true)),
    ]);
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => MaintenanceItemsScreen(group: group),
        ),
        GoRoute(
          path: AppRoutes.maintenanceItemDetail,
          builder: (context, state) =>
              const Scaffold(body: Text('check page viewer stub')),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Check bilge pump'));
    await tester.pumpAndSettle();

    expect(find.text('check page viewer stub'), findsOneWidget,
        reason: 'must navigate via showCheckPageViewer, not open an '
            'AlertDialog (#179)');
    expect(find.byType(AlertDialog), findsNothing);
  });
}
