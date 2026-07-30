import 'checklist_drift_seed.dart';
import '../../models/models.dart';

final weeklyId = 'weeklyId';

Future<void> seedWeeklyChecks(String defaultBoatSupabaseId) async {
  // ===================================================================
  // CHECKLIST GROUP - Weekly
  // ===================================================================
  final group = ChecklistGroup()
    ..supabaseId = weeklyId
    ..boatSupabaseId = defaultBoatSupabaseId
    // ..name = 'Weekly Checks' // Undefined setter, commented out temporarily
    // ..icon = 'calendar-week' // Undefined setter, commented out temporarily
    ..title = 'Weekly Checks'
    ..iconName = 'calendar-week'
    ..sortOrder = 1
    ..appType = 'checklist'
    ..isBundled = true;

  await seedChecklistGroupToDrift(group);

  // ===================================================================
  // CHECKLIST ITEMS - Weekly
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
    weeklyId,
    'Battery Voltage & Connections',
    'Check house and start battery voltages and clean terminals.',
    'battery',
  );
  add(
    weeklyId,
    'Fridge & Freezer Temps',
    'Confirm temperatures and defrost if needed.',
    'refrigerator',
  );
  add(
    weeklyId,
    'Anchor Windlass & Chain',
    'Run windlass, inspect chain and locker.',
    'anchor',
  );
  add(
    weeklyId,
    'Running Rigging Inspection',
    'Look for chafe on sheets and halyards.',
    'rigging',
  );
  add(
    weeklyId,
    'Sails UV Cover Check',
    'Inspect sail covers and UV strips.',
    'sail',
  );

  await seedChecklistItemsToDrift(items);
}
