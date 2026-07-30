import 'checklist_drift_seed.dart';
import '../../models/models.dart';

final engine50Id = 'engine50Id';

Future<void> seedYanmar_4JH45_50HoursService(
  String defaultBoatSupabaseId,
) async {
  // ===================================================================
  // CHECKLIST GROUP - Yanmar 4JH45 Engine 50 Hours Service
  // ===================================================================
  final group = ChecklistGroup()
    ..supabaseId = engine50Id
    ..boatSupabaseId = defaultBoatSupabaseId
    // ..name = 'Yanmar 4JH45 - First 50-Hour Engine Service' // Undefined setter, commented out temporarily
    // ..icon = 'wrench' // Undefined setter, commented out temporarily
    ..title = 'Yanmar 4JH45 - First 50-Hour Engine Service'
    ..iconName = 'wrench'
    ..sortOrder = 11
    ..appType = 'maintenance'
    ..isBundled = true;

  await seedChecklistGroupToDrift(group);

  // ===================================================================
  // CHECKLIST ITEMS - Engine 50 Hours Service
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
    engine50Id,
    'Important Disclaimer',
    'This checklist follows Yanmar 4JH45 marine diesel engine maintenance schedule. Always consult the engine manual for your specific model and operating conditions.',
    'lib/assets/Disclaimer.jpg',
  );
  add(
    engine50Id,
    'Engine Oil Change',
    'Change engine oil using Yanmar recommended oil. Capacity: approximately 7.5 liters.',
    'lib/assets/lists/50HourEngineService/EngineOil.jpg',
  );
  add(
    engine50Id,
    'Oil Filter Replacement',
    'Replace oil filter (Yanmar part #129150-35170).',
    'filter',
  );
  add(
    engine50Id,
    'Fuel Filter Check',
    'Inspect and clean primary fuel filter. Replace if necessary.',
    'filter',
  );
  add(
    engine50Id,
    'Air Filter Check',
    'Inspect air filter element and clean or replace as needed.',
    'filter',
  );
  add(
    engine50Id,
    'Cooling System Check',
    'Check coolant level and condition. Inspect hoses and connections.',
    'coolant',
  );
  add(
    engine50Id,
    'Drive Belt Inspection',
    'Check alternator and water pump belts for tension and wear.',
    'lib/assets/lists/DailyEngineChecks/Belts.jpg',
  );
  add(
    engine50Id,
    'Impeller Inspection',
    'Inspect raw water pump impeller for wear.',
    'impeller',
  );

  // Hidden items from old seeding data
  add(
    engine50Id,
    'Gear Oil',
    'Changing the Marine Gear Oil (SAE Viscosity #20 or #30)',
    'lib/assets/lists/50HourEngineService/NoPicture.jpg',
  );
  items.last.isHidden = true;

  add(
    engine50Id,
    'Gear Oil Filter',
    'Replacing Marine Gear Oil Filter Element (part # ???)',
    'lib/assets/lists/50HourEngineService/NoPicture.jpg',
  );
  items.last.isHidden = true;

  add(
    engine50Id,
    'Propellor Shaft',
    'Adjusting Propellor Shaft Alignment',
    'lib/assets/lists/50HourEngineService/NoPicture.jpg',
  );
  items.last.isHidden = true;

  await seedChecklistItemsToDrift(items);
}
