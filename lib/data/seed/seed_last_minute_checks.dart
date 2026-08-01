import 'checklist_drift_seed.dart';
import '../../models/models.dart';

final lastMinuteId = 'lastMinuteId';

Future<void> seedLastMinuteChecks(
  String defaultBoatSupabaseId,
) async {
  // ===================================================================
  // CHECKLIST GROUP - Last Minute
  // ===================================================================
  final group = ChecklistGroup()
    ..supabaseId = lastMinuteId
    ..boatSupabaseId = defaultBoatSupabaseId
    // ..name = 'Last Minute Departure Checks' // Undefined setter, commented out temporarily
    // ..icon = 'clock' // Undefined setter, commented out temporarily
    ..title = 'Last Minute Departure Checks'
    ..iconName = 'clock'
    ..sortOrder = 10
    ..appType = 'checklist'
    ..isBundled = true;

  await seedChecklistGroupToDrift(group);

  // ===================================================================
  // CHECKLIST ITEMS - Last Minute
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
    lastMinuteId,
    'Important Disclaimer',
    'This checklist is derived from final departure procedures performed on a 2018 Leopard 45 catamaran... Users must adapt this checklist to their specific vessel.',
    'lib/assets/Disclaimer.jpg',
  );
  add(
    lastMinuteId,
    'Final Weather Check',
    'Obtain and review the very latest weather forecast. Adjust departure time, route, and crew clothing if required.',
    'lib/assets/lists/LastMinute/Weather.jpg',
  );
  add(
    lastMinuteId,
    'Enter Passage Plan into Chartplotter',
    'Input the final passage plan (waypoints and route) into the primary chartplotter and verify on a second system if available.',
    'lib/assets/lists/LastMinute/ChartPlotter.jpg',
  );
  add(
    lastMinuteId,
    'Dispose of Rubbish Ashore',
    'Remove all remaining rubbish, especially plastics and non-biodegradable waste, to shore facilities. This is the final opportunity before departure.',
    'lib/assets/lists/LastMinute/Rubbish.jpg',
  );
  add(
    lastMinuteId,
    'Disconnect Shore Power & Services',
    'Switch off shore power at the distribution board, unplug cable from pedestal and vessel inlet, stow cable. Disconnect and stow water hose and any shore antennae or other services.',
    'lib/assets/lists/LastMinute/ShorePower.jpg',
  );
  add(
    lastMinuteId,
    'Final Engine Check',
    'Perform a complete daily engine and systems check immediately before departure.',
    'lib/assets/lists/DailyEngineChecks/EngineOil.jpg',
  );
  add(
    lastMinuteId,
    'Close All Hatches & Portlights',
    'Ensure every hatch, portlight, and companionway is securely closed and dogged.',
    'lib/assets/lists/LastMinute/Hatches.jpg',
  );
  add(
    lastMinuteId,
    'Secure Lazarettes & Lockers',
    'Confirm all lazarettes, deck lockers, and cockpit seats are closed and latched.',
    'lib/assets/lists/LastMinute/Lazarette.jpg',
  );
  add(
    lastMinuteId,
    'Crew Dress Code',
    'Verify all crew are wearing appropriate clothing and footwear for the expected conditions (non-marking soles, layers, foul-weather gear if required).',
    'lib/assets/lists/LastMinute/DressCode.jpg',
  );
  add(
    lastMinuteId,
    'Secure Saloon Loose Items',
    'Stow or secure all loose items in the saloon and cabins. Imagine the vessel heeled 90 in both directions to identify potential projectiles.',
    'lib/assets/lists/LastMinute/Saloon.jpg',
  );
  add(
    lastMinuteId,
    'Lock All Drawers & Cupboards',
    'Ensure every drawer, cupboard, and fridge/freezer door is securely latched or locked.',
    'lib/assets/lists/LastMinute/Drawers.jpg',
  );
  add(
    lastMinuteId,
    'Mainsail Ready to Hoist',
    'Confirm mainsail halyard is attached, clear to run, and sail is ready for immediate hoisting.',
    'lib/assets/lists/LastMinute/MainSail.jpg',
  );
  add(
    lastMinuteId,
    'Remove Sail Cover / Lazy Bag',
    'Unzip, remove, and stow the mainsail cover or lazy bag below.',
    'lib/assets/lists/LastMinute/SailCover.jpg',
  );
  add(
    lastMinuteId,
    'Day Shapes / Radar Reflector',
    'Remove motoring cone / anchor ball if displayed. Hoist appropriate day shapes (e.g., motoring cone if proceeding under power).',
    'lib/assets/lists/AnualChecks/RadarReflector.jpg',
  );
  add(
    lastMinuteId,
    'Start Engines',
    'Start both engines and confirm steady cooling-water flow from each exhaust before casting off.',
    'lib/assets/lists/LastMinute/StartEngines.jpg',
  );
  add(
    lastMinuteId,
    'Obtain Marina Departure Permission',
    'Contact marina office or traffic control on VHF/working channel for permission to leave berth or exit the marina.',
    'lib/assets/lists/LastMinute/Permission.jpg',
  );
  add(
    lastMinuteId,
    'Stow Fenders & Lines',
    'Retrieve and securely stow all fenders and dock lines once clear of the berth. Safe passage!',
    'lib/assets/lists/AnualChecks/MooringFenders.jpg',
  );

  await seedChecklistItemsToDrift(items);
}
