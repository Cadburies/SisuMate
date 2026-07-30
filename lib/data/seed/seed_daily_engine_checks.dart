import 'checklist_drift_seed.dart';
import '../../models/models.dart';

final dailyEngineId = 'dailyEngineId';

Future<void> seedDailyEngineChecks(String defaultBoatSupabaseId) async {
  final group = ChecklistGroup()
    ..supabaseId = dailyEngineId
    ..boatSupabaseId = defaultBoatSupabaseId
    ..title = 'Daily Engine Checks'
    ..iconName = 'engine'
    ..sortOrder = 1
    ..appType = 'maintenance'
    ..isBundled = true;

  await seedChecklistGroupToDrift(group);

  final items = <ChecklistItem>[];

  void add(String groupId, String title, String description, String assetName) {
    items.add(
      ChecklistItem()
        ..supabaseId =
            '${groupId}_${title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}'
        ..groupSupabaseId = groupId
        ..title = title
        ..description = description
        ..assetName = assetName
        ..isCompleted = false
        ..isHidden = false
        ..isPermanentlyDeleted = false
        ..sortOrder = items.length,
    );
  }

  // Available assets in DailyEngineChecks/:
  // Belts, Bilge, BilgeBlowers, BilgeWaterTrap, DrainSeperator,
  // Electrics, EngineOil, Leaks, NoPicture, RawWater,
  // SailDriveOil, SecondaryWater, ThrottleCable, passagePlanning

  add(dailyEngineId, 'Engine Oil Level',
      'Check engine oil level using dipstick; top up if low with correct oil type.',
      'lib/assets/lists/DailyEngineChecks/EngineOil.jpg');

  add(dailyEngineId, 'Coolant Level',
      'Check coolant level in expansion tank; top up with premixed coolant if low.',
      'lib/assets/lists/DailyEngineChecks/SecondaryWater.jpg');

  add(dailyEngineId, 'Belt Tension',
      'Check alternator and water pump belt tension and condition.',
      'lib/assets/lists/DailyEngineChecks/Belts.jpg');

  add(dailyEngineId, 'Visual Inspection',
      'Visually inspect engine for leaks, loose connections, or unusual wear.',
      'lib/assets/lists/DailyEngineChecks/Leaks.jpg');

  add(dailyEngineId, 'Fuel Water Separator',
      'Check fuel water separator for water accumulation; drain if necessary.',
      'lib/assets/lists/DailyEngineChecks/DrainSeperator.jpg');

  add(dailyEngineId, 'Raw Water Strainer',
      'Check raw water strainer for debris; clean if necessary.',
      'lib/assets/lists/DailyEngineChecks/RawWater.jpg');

  add(dailyEngineId, 'Exhaust System',
      'Inspect exhaust system for leaks or unusual discoloration.',
      'exhaust');

  await seedChecklistItemsToDrift(items);
}
