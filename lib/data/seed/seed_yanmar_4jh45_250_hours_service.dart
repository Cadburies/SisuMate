import 'checklist_drift_seed.dart';
import '../../models/models.dart';

final engine250Id = 'engine250Id';

Future<void> seedYanmar_4JH45_250HoursService(
  String defaultBoatSupabaseId,
) async {
  // ===================================================================
  // CHECKLIST GROUP - Yanmar 4JH45 Engine 250 Hours Service
  // ===================================================================
  final group = ChecklistGroup()
    ..supabaseId = engine250Id
    ..boatSupabaseId = defaultBoatSupabaseId
    // ..name = 'Yanmar 4JH45 - 250-Hour Engine Service' // Undefined setter, commented out temporarily
    // ..icon = 'wrench' // Undefined setter, commented out temporarily
    ..title = 'Yanmar 4JH45 - 250-Hour Engine Service'
    ..iconName = 'wrench'
    ..sortOrder = 12
    ..appType = 'maintenance'
    ..isBundled = true;

  await seedChecklistGroupToDrift(group);

  // ===================================================================
  // CHECKLIST ITEMS - Engine 250 Hours Service
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
    engine250Id,
    'Important Disclaimer',
    'This checklist follows Yanmar 4JH45 marine diesel engine maintenance schedule. Always consult the engine manual for your specific model and operating conditions.',
    'lib/assets/Disclaimer.jpg',
  );
  add(
    engine250Id,
    'Engine Oil Change',
    'Change engine oil using Yanmar recommended oil.',
    'lib/assets/lists/250HourEngineService/EngineOil.jpg',
  );
  add(
    engine250Id,
    'Oil Filter Replacement',
    'Replace oil filter (Yanmar #129150-35170).',
    'lib/assets/lists/250HourEngineService/EngineOilFilter.jpg',
  );
  add(
    engine250Id,
    'Fuel Filter Replacement',
    'Replace primary fuel filter element.',
    'lib/assets/lists/250HourEngineService/FuelFilter.jpg',
  );
  add(
    engine250Id,
    'Fuel/Water Separator',
    'Replace fuel/water separator element (Racor or equivalent).',
    'lib/assets/lists/250HourEngineService/FuelSeperator.jpg',
  );
  add(
    engine250Id,
    'Air Filter Replacement',
    'Replace air filter element.',
    'filter',
  );
  add(
    engine250Id,
    'Cooling System Service',
    'Flush cooling system and replace coolant. Check thermostat.',
    'coolant',
  );
  add(
    engine250Id,
    'Raw Water Pump Service',
    'Inspect and service raw water pump, replace impeller.',
    'lib/assets/lists/250HourEngineService/Impeller.jpg',
  );
  add(
    engine250Id,
    'Drive Belts Replacement',
    'Replace alternator and water pump drive belts.',
    'lib/assets/lists/250HourEngineService/Belts.jpg',
  );
  add(
    engine250Id,
    'Injection Timing Check',
    'Check and adjust fuel injection timing if necessary.',
    'injector',
  );
  add(
    engine250Id,
    'Valve Clearance Check',
    'Check and adjust valve clearances.',
    'engine-valves',
  );

  // Hidden items from old seeding data
  add(
    engine250Id,
    'Gear Oil',
    'Changing the Marine Gear Oil (SAE Viscosity #20 or #30)',
    'lib/assets/lists/250HourEngineService/NoPicture.jpg',
  );
  items.last.isHidden = true;

  add(
    engine250Id,
    'Gear Oil Filter',
    'Replacing Marine Gear Oil Filter Element (part # ???)',
    'lib/assets/lists/250HourEngineService/NoPicture.jpg',
  );
  items.last.isHidden = true;

  add(
    engine250Id,
    'Turbocharger',
    'Wash the Turbocharger blower',
    'lib/assets/lists/250HourEngineService/NoPicture.jpg',
  );
  items.last.isHidden = true;

  await seedChecklistItemsToDrift(items);
}
