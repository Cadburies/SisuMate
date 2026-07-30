import 'checklist_drift_seed.dart';
import '../../models/models.dart';

final engine500Id = 'engine500Id';

Future<void> seedYanmar_4JH45_500HoursService(
  String defaultBoatSupabaseId,
) async {
  // ===================================================================
  // CHECKLIST GROUP - Yanmar 4JH45 Engine 500 Hours Service
  // ===================================================================
  final group = ChecklistGroup()
    ..supabaseId = engine500Id
    ..boatSupabaseId = defaultBoatSupabaseId
    // ..name = 'Yanmar 4JH45 - 500-Hour Engine Service' // Undefined setter, commented out temporarily
    // ..icon = 'wrench' // Undefined setter, commented out temporarily
    ..title = 'Yanmar 4JH45 - 500-Hour Engine Service'
    ..iconName = 'wrench'
    ..sortOrder = 13
    ..appType = 'maintenance'
    ..isBundled = true;

  await seedChecklistGroupToDrift(group);

  // ===================================================================
  // CHECKLIST ITEMS - Engine 500 Hours Service
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
    engine500Id,
    'Important Disclaimer',
    'This checklist follows Yanmar 4JH45 marine diesel engine maintenance schedule. Always consult the engine manual for your specific model and operating conditions.',
    'lib/assets/Disclaimer.jpg',
  );
  add(
    engine500Id,
    'Complete 250-Hour Service',
    'Perform all 250-hour service items.',
    'lib/assets/lists/250HourEngineService/EngineOilFilter.jpg',
  );
  add(
    engine500Id,
    'Fuel Injectors',
    'Test and clean or replace fuel injectors.',
    'injector',
  );
  add(
    engine500Id,
    'Turbocharger Inspection',
    'Inspect turbocharger for wear and carbon buildup.',
    'turbo',
  );
  add(
    engine500Id,
    'Heat Exchanger Cleaning',
    'Clean and inspect heat exchanger tubes.',
    'heat-exchanger',
  );
  add(
    engine500Id,
    'Exhaust System Inspection',
    'Inspect exhaust manifold and system for leaks.',
    'exhaust',
  );
  add(
    engine500Id,
    'Engine Mounts',
    'Check engine mount condition and tightness.',
    'mounting',
  );

  // Hidden items from old seeding data
  add(
    engine500Id,
    'Exhaust/Water Mixing Elbow',
    'Replace the Exhaust/Water Mixing Elbow',
    'lib/assets/lists/500HourEngineService/MixingElbow.jpg',
  );
  items.last.isHidden = true;

  add(
    engine500Id,
    'Rubber Hoses',
    'Replace the rubber hoses',
    'lib/assets/lists/500HourEngineService/RubberHoses.jpg',
  );
  items.last.isHidden = true;

  add(
    engine500Id,
    'Propeller Shaft',
    'Lubricate the propeller shaft splines and tighten the propellor nuts',
    'lib/assets/lists/500HourEngineService/NoPicture.jpg',
  );
  items.last.isHidden = true;

  add(
    engine500Id,
    'SD Pipe Fitting',
    'Check that the pipe fitting are properly tight',
    'lib/assets/lists/500HourEngineService/SDPipeFitting.jpg',
  );
  items.last.isHidden = true;

  add(
    engine500Id,
    'SD Grounding',
    'Check that the grounding circuit (continuity) are not loose or damaged connections',
    'lib/assets/lists/500HourEngineService/SDGrounding.jpg',
  );
  items.last.isHidden = true;

  add(
    engine500Id,
    'SD Antifoul',
    'Apply antifouling without copper material',
    'lib/assets/lists/500HourEngineService/SDAntifoul.jpg',
  );
  items.last.isHidden = true;

  await seedChecklistItemsToDrift(items);
}
