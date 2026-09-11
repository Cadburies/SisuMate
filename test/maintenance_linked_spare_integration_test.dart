import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/image_service.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/checklists/check_page_viewer.dart';
import 'package:sisu_mate/ui/inventory/inventory_screen.dart';
import 'package:sisu_mate/ui/maintenance/maintenance_items_screen.dart';

import 'test_helpers/platform_mocks.dart';

/// #319 TEST6: completing a maintenance item offers a skippable
/// "decrement linked spare" prompt that writes through the real
/// InventoryItem repository.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  const groupId = 'grp_eng';
  const itemId = 'maint_impeller';
  const invId = 'inv_impeller';

  final group = ChecklistGroup()
    ..supabaseId = groupId
    ..boatSupabaseId = 'boat_1'
    ..appType = 'maintenance'
    ..title = 'Engine Room'
    ..isBundled = false;

  setUp(() {
    mockConnectivityChannel();
    mockPathProviderChannel();
    mockSharedPreferencesChannel();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    RevenueCatService.debugProOverrideForTests = true;
    // #349 — mockPathProviderChannel() mocks the legacy MethodChannel, but
    // path_provider_foundation (macOS/iOS, what `flutter test` resolves to
    // here) calls a Pigeon BasicMessageChannel instead, which nothing
    // answers — getApplicationDocumentsDirectory() hangs forever rather
    // than erroring. ImageService's debugDocumentsOverride is the
    // purpose-built seam for exactly this.
    ImageService().debugDocumentsOverride = Directory('/tmp/sisu_mate_test');
  });

  tearDown(() async {
    RevenueCatService.debugProOverrideForTests = null;
    ImageService().debugDocumentsOverride = null;
    await db.close();
  });

  Future<void> seed({double qty = 3}) async {
    await db.into(db.checklistGroups).insert(
          ChecklistGroupsCompanion.insert(
            supabaseId: const Value(groupId),
            boatSupabaseId: const Value('boat_1'),
            appType: const Value('maintenance'),
            title: const Value('Engine Room'),
          ),
        );
    await db.into(db.checklistItems).insert(
          ChecklistItemsCompanion.insert(
            supabaseId: const Value(itemId),
            boatSupabaseId: const Value('boat_1'),
            groupSupabaseId: const Value(groupId),
            title: const Value('Replace impeller'),
            name: const Value('Replace impeller'),
          ),
        );
    await db.into(db.inventoryItems).insert(
          InventoryItemsCompanion.insert(
            supabaseId: const Value(invId),
            name: const Value('Spare impeller'),
            quantity: Value(qty),
            unit: const Value('pcs'),
            linkedMaintenanceItemSupabaseId: const Value(itemId),
          ),
        );
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(true)),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: MaintenanceItemsScreen(group: group)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> swipeAndTapComplete(WidgetTester tester) async {
    final title = find.text('Replace impeller');
    expect(title, findsOneWidget);
    await tester.drag(title, const Offset(-400, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Complete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
  }

  /// #349 — a maintenance item with no linked spare yet (so "Add spare"
  /// starts from an empty `inventoryItems` table, keeping `.single`
  /// assertions valid after the new row lands).
  Future<void> seedMaintenanceItemOnly({
    String? description,
    String? photoPath,
  }) async {
    await db.into(db.checklistGroups).insert(
          ChecklistGroupsCompanion.insert(
            supabaseId: const Value(groupId),
            boatSupabaseId: const Value('boat_1'),
            appType: const Value('maintenance'),
            title: const Value('Engine Room'),
          ),
        );
    await db.into(db.checklistItems).insert(
          ChecklistItemsCompanion.insert(
            supabaseId: const Value(itemId),
            boatSupabaseId: const Value('boat_1'),
            groupSupabaseId: const Value(groupId),
            title: const Value('Replace impeller'),
            name: const Value('Replace impeller'),
            description: Value(description),
            userPhotoPath: Value(photoPath),
          ),
        );
  }

  Future<double> inventoryQty() async {
    final rows = await db.select(db.inventoryItems).get();
    return rows.single.quantity;
  }

  testWidgets(
      '#319: complete + Decrement writes qty-1 into Drift', (tester) async {
    await seed();
    await pumpScreen(tester);

    await swipeAndTapComplete(tester);

    expect(find.text('Decrement linked spare?'), findsOneWidget);
    await tester.tap(find.text('Decrement'));
    await tester.pumpAndSettle();

    expect(await inventoryQty(), 2);
    final checks = await db.select(db.checklistItems).get();
    expect(checks.single.isCompleted, isTrue);
  });

  testWidgets('#319: complete + Skip leaves inventory qty unchanged',
      (tester) async {
    await seed();
    await pumpScreen(tester);

    await swipeAndTapComplete(tester);

    expect(find.text('Decrement linked spare?'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(await inventoryQty(), 3);
    final checks = await db.select(db.checklistItems).get();
    expect(checks.single.isCompleted, isTrue);
  });

  testWidgets('#319: CheckPageViewer shows spare-on-hand for a linked item',
      (tester) async {
    await seed();
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(true)),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: CheckPageViewer(
            items: [
              ChecklistItem()
                ..supabaseId = itemId
                ..groupSupabaseId = groupId
                ..title = 'Replace impeller'
                ..name = 'Replace impeller',
            ],
            initialIndex: 0,
            groupName: 'Engine Room',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Spare on hand'), findsOneWidget);
    expect(
      find.text('Spare impeller: 3 pcs on hand, min 1'),
      findsOneWidget,
    );
  });

  // Note: this deliberately seeds no photo — real dart:io file operations
  // triggered from inside a testWidgets body hang under this project's
  // flutter_tester harness (AutomatedTestWidgetsFlutterBinding's fake-async
  // zone doesn't service dart:io's real I/O isolate port). The photo-copy
  // behavior (ImageService.persistPickedPath called from
  // seedFromMaintenanceItem) is covered separately below in a plain test(),
  // which runs in a normal zone where real file I/O is safe.
  testWidgets(
      '#349: Add spare prefills name/notes from the maintenance item and '
      'links it automatically', (tester) async {
    await seedMaintenanceItemOnly(description: 'Oil filter, part# ABC-123');
    await pumpScreen(tester);

    await tester.tap(find.byIcon(Icons.inventory_2_outlined));
    await tester.pumpAndSettle();

    final dialog = find.byType(AddEditInventoryItemDialog);
    expect(dialog, findsOneWidget);
    expect(
      find.descendant(of: dialog, matching: find.text('Replace impeller')),
      findsOneWidget,
    );
    expect(
      find.descendant(
          of: dialog, matching: find.text('Oil filter, part# ABC-123')),
      findsOneWidget,
    );

    await tester
        .tap(find.descendant(of: dialog, matching: find.text('Save')));
    await tester.pumpAndSettle();

    final rows = await db.select(db.inventoryItems).get();
    expect(rows, hasLength(1));
    final spare = rows.single;
    expect(spare.name, 'Replace impeller');
    expect(spare.notes, 'Oil filter, part# ABC-123');
    expect(spare.linkedMaintenanceItemSupabaseId, itemId);
  });

  testWidgets('#319: uncomplete does not prompt', (tester) async {
    await seed();
    await db.update(db.checklistItems).write(
          const ChecklistItemsCompanion(isCompleted: Value(true)),
        );
    await pumpScreen(tester);

    final title = find.text('Replace impeller');
    await tester.drag(title, const Offset(-400, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uncomplete'));
    await tester.pumpAndSettle();

    expect(find.text('Decrement linked spare?'), findsNothing);
    expect(await inventoryQty(), 3);
  });

  // Plain test() — normal Dart zone, so real dart:io file I/O is safe here
  // (unlike inside testWidgets — see the note on the "Add spare" test above).
  test(
      '#349: ImageService.persistPickedPath durably copies a maintenance '
      "item's photo for a new spare, rather than aliasing the source path",
      () async {
    final tempDir = await Directory.systemTemp.createTemp('sisu_mate_349_');
    addTearDown(() => tempDir.delete(recursive: true));
    ImageService().debugDocumentsOverride = tempDir;
    addTearDown(() => ImageService().debugDocumentsOverride = null);

    final source = File('${tempDir.path}/maint_item_photo.jpg');
    await source.writeAsBytes([1, 2, 3, 4]);

    final copiedPath =
        await ImageService().persistPickedPath(source.path, prefix: 'spare');

    expect(copiedPath, isNot(source.path));
    expect(await File(copiedPath).exists(), isTrue);
    expect(await File(copiedPath).readAsBytes(), [1, 2, 3, 4]);
  });
}
