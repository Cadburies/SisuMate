import 'checklist_drift_seed.dart';
import '../../models/models.dart';

final monthlyId = 'monthlyId';

Future<void> seedMonthlyChecks(String defaultBoatSupabaseId) async {
  // ===================================================================
  // CHECKLIST GROUP - Monthly
  // ===================================================================
  final group = ChecklistGroup()
    ..supabaseId = monthlyId
    ..boatSupabaseId = defaultBoatSupabaseId
    // ..name = 'Monthly Checks' // Undefined setter, commented out temporarily
    // ..icon = 'calendar-month' // Undefined setter, commented out temporarily
    ..title = 'Monthly Checks'
    ..iconName = 'calendar-month'
    ..sortOrder = 2
    ..appType = 'checklist'
    ..isBundled = true;

  await seedChecklistGroupToDrift(group);

  // ===================================================================
  // CHECKLIST ITEMS - Monthly
  // ===================================================================
  final items = <ChecklistItem>[];

  // Helper to reduce boilerplate
  void add(String groupId, String name, String description, String assetName) {
    items.add(
      ChecklistItem()
        ..supabaseId =
            '${groupId}_${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}'
        ..groupSupabaseId = groupId
        // ..name = name // Undefined setter, commented out temporarily
        ..title = name
        ..description = description
        ..assetName = assetName
        ..isCompleted = false
        // ..expiryDate = null // Undefined setter, commented out temporarily
        ..isHidden = false
        ..isPermanentlyDeleted = false
        ..sortOrder = items.length,
    );
  }

  add(
    monthlyId,
    'Zincs/Anodes',
    'Inspect and replace sacrificial anodes if <50%.',
    'zincs',
  );
  add(
    monthlyId,
    'Through-Hulls & Seacocks',
    'Exercise all seacocks, check hoses.',
    'seacocks',
  );
  add(
    monthlyId,
    'Life Raft Inspection',
    'Check expiry, mounting, painter.',
    'life-ring',
  );

  await seedChecklistItemsToDrift(items);
}
