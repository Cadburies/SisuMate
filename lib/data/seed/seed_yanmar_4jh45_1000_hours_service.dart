import 'checklist_drift_seed.dart';
import '../../models/models.dart';

final engine1000Id = 'engine1000Id';

Future<void> seedYanmar_4JH45_1000HoursService(
  String defaultBoatSupabaseId,
) async {
  // ===================================================================
  // CHECKLIST GROUP - Yanmar 4JH45 Engine 1000 Hours Service
  // ===================================================================
  final group = ChecklistGroup()
    ..supabaseId = engine1000Id
    ..boatSupabaseId = defaultBoatSupabaseId
    // ..name = 'Yanmar 4JH45 - 1000-Hour Engine Service' // Undefined setter, commented out temporarily
    // ..icon = 'wrench' // Undefined setter, commented out temporarily
    ..title = 'Yanmar 4JH45 - 1000-Hour Engine Service'
    ..iconName = 'wrench'
    ..sortOrder = 14
    ..appType = 'maintenance'
    ..isBundled = true;

  await seedChecklistGroupToDrift(group);

  // ===================================================================
  // CHECKLIST ITEMS - Engine 1000 Hours Service
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
    engine1000Id,
    'Important Disclaimer',
    'This checklist follows Yanmar 4JH45 marine diesel engine maintenance schedule. Always consult the engine manual for your specific model and operating conditions.',
    'lib/assets/Disclaimer.jpg',
  );
  add(
    engine1000Id,
    'Complete 500-Hour Service',
    'Perform all 500-hour service items.',
    'lib/assets/lists/250HourEngineService/EngineOilFilter.jpg',
  );
  add(
    engine1000Id,
    'Cylinder Head Inspection',
    'Remove and inspect cylinder head for wear.',
    'cylinder',
  );
  add(
    engine1000Id,
    'Piston Rings',
    'Inspect and replace piston rings if worn.',
    'piston',
  );
  add(
    engine1000Id,
    'Main Bearings',
    'Check main bearing clearances.',
    'engine',
  );
  add(
    engine1000Id,
    'Timing Belt',
    'Replace timing belt and check tensioner.',
    'belt',
  );
  add(
    engine1000Id,
    'Valve Seat Inspection',
    'Inspect valve seats and guides.',
    'engine-valves',
  );

  // Hidden items from old seeding data
  add(
    engine1000Id,
    '250 Hour Checks',
    'First complete all 250 hour Checks',
    'lib/assets/lists/1000HourEngineService/250HourChecks.jpg',
  );
  items.last.isHidden = true;

  add(
    engine1000Id,
    '500 Hour Checks',
    'Second complete all 500 hour Checks',
    'lib/assets/lists/1000HourEngineService/500HourChecks.jpg',
  );
  items.last.isHidden = true;

  add(
    engine1000Id,
    'Impeller',
    'Replace the Seawater Impeller',
    'lib/assets/lists/1000HourEngineService/Impeller.jpg',
  );
  items.last.isHidden = true;

  add(
    engine1000Id,
    'Seawater Passages',
    'Checking and cleaning all Seawater Passages',
    'lib/assets/lists/1000HourEngineService/SeawaterPassages.jpg',
  );
  items.last.isHidden = true;

  add(
    engine1000Id,
    'Diaphragm',
    'Checking Diaphragm Assembly',
    'lib/assets/lists/1000HourEngineService/Diaphragm.jpg',
  );
  items.last.isHidden = true;

  add(
    engine1000Id,
    'V-Belt',
    'Replace Alternator V-Belt Tension',
    'lib/assets/lists/1000HourEngineService/Belts.jpg',
  );
  items.last.isHidden = true;

  add(
    engine1000Id,
    'Valve Clearance',
    'Inspecting and adjusting intake/exhaust valve clearance',
    'lib/assets/lists/1000HourEngineService/ValveClearance.jpg',
  );
  items.last.isHidden = true;

  add(
    engine1000Id,
    'Remote Control Throttle/Gear',
    'Check remote control throttle/gear cables are calibrated and screws are tight',
    'lib/assets/lists/1000HourEngineService/RemoteControlThrottle.jpg',
  );
  items.last.isHidden = true;

  add(
    engine1000Id,
    'Propellor Shaft',
    'Adjusting Propellor Shaft Alignment',
    'lib/assets/lists/1000HourEngineService/NoPicture.jpg',
  );
  items.last.isHidden = true;

  await seedChecklistItemsToDrift(items);
}
