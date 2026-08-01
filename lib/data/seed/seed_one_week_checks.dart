import 'checklist_drift_seed.dart';
import '../../models/models.dart';

final oneWeekId = 'oneWeekId';

Future<void> seedOneWeekChecks(String defaultBoatSupabaseId) async {
  // ===================================================================
  // CHECKLIST GROUP - One Week
  // ===================================================================
  final group = ChecklistGroup()
    ..supabaseId = oneWeekId
    ..boatSupabaseId = defaultBoatSupabaseId
    // ..name = 'One Week Before Departure Checks' // Undefined setter, commented out temporarily
    // ..icon = 'calendar-minus' // Undefined setter, commented out temporarily
    ..title = 'One Week Before Departure Checks'
    ..iconName = 'calendar-minus'
    ..sortOrder = 4
    ..appType = 'checklist'
    ..isBundled = true;

  await seedChecklistGroupToDrift(group);

  // ===================================================================
  // CHECKLIST ITEMS - One Week
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
    oneWeekId,
    'Important Disclaimer',
    'This checklist is derived from pre-departure procedures performed on a 2018 Leopard 45 catamaran... Users must adapt this checklist to their specific vessel.',
    'lib/assets/Disclaimer.jpg',
  );
  add(
    oneWeekId,
    'Harnesses',
    'Inspect all safety harnesses and tethers for wear, abrasion, UV damage, and stitching integrity.',
    'lib/assets/lists/OneWeek/Harnasses.jpg',
  );
  add(
    oneWeekId,
    'PFD Cartridges',
    'Inspect inflatable PFD CO2 cartridges and auto-inflation bobbins; verify they are within expiry date and undamaged.',
    'lib/assets/lists/OneWeek/Cartridges.jpg',
  );
  add(
    oneWeekId,
    'PFD Equipment',
    'Examine all personal flotation devices for physical damage, secure fittings, and proper function of whistles, lights, and reflective tape.',
    'lib/assets/lists/AnualChecks/PFDEquipment.jpg',
  );
  add(
    oneWeekId,
    'PredictWind',
    'Confirm active PredictWind subscription, test connectivity, and ensure software is updated to the latest version.',
    'lib/assets/lists/OneWeek/Predictwind.jpg',
  );
  add(
    oneWeekId,
    'Iridium',
    'Verify Iridium GO!/Certus connectivity, confirm email/data functionality, and update device software/firmware as required.',
    'lib/assets/lists/OneWeek/Iridium.jpg',
  );
  add(
    oneWeekId,
    'Weather Maps',
    'Download latest GRIB files and pilot charts (wind roses) for the entire passage area including contingency routes.',
    'lib/assets/lists/OneWeek/WeatherMaps.jpg',
  );
  add(
    oneWeekId,
    'SAS Planet',
    'Download current high-resolution satellite imagery for destination anchorages and approaches using SAS Planet.',
    'lib/assets/lists/OneWeek/SASPlanet.jpg',
  );
  add(
    oneWeekId,
    'Anti-Siphon Loops',
    'Inspect all anti-siphon loops (engines, generator, toilets) to ensure they are clear, correctly positioned above the waterline, and free of blockages.',
    'lib/assets/lists/OneWeek/AntSiphon.jpg',
  );
  add(
    oneWeekId,
    'Saildrive / Shaft Seals',
    'Inspect shaft seals for leaks. For saildrives: rotate propellers by hand for several minutes, then check dipstick for milky/gray oil indicating water ingress.',
    'lib/assets/lists/OneWeek/SaildriveSeals.jpg',
  );
  add(
    oneWeekId,
    'Log Sheets',
    'Place fresh passage log sheets on clipboard and ensure pens are available.',
    'lib/assets/lists/OneWeek/LogSheets.jpg',
  );
  add(
    oneWeekId,
    'Raw Water Strainers',
    'Clean raw water strainers for main engines, generator, watermaker, pump protectors, and air conditioning units.',
    'lib/assets/lists/OneWeek/WaterStrainers.jpg',
  );
  add(
    oneWeekId,
    'Laundry',
    'Complete all laundry including clothing, bed linen, pillowcases, and towels.',
    'lib/assets/lists/OneWeek/Laundry.jpg',
  );
  add(
    oneWeekId,
    'Provision Checklist',
    'Execute provisioning checklist and restock non-perishable food and consumables.',
    'lib/assets/lists/OneWeek/Provision.jpg',
  );
  add(
    oneWeekId,
    'Precooked Food',
    'Prepare and freeze precooked meals suitable for passage and the first three days after arrival.',
    'lib/assets/lists/OneWeek/Precooked.jpg',
  );
  add(
    oneWeekId,
    'Diesel',
    'Fill all diesel tanks to capacity and top up spare jerry cans if carried.',
    'lib/assets/lists/OneWeek/Diesel.jpg',
  );
  add(
    oneWeekId,
    'Petrol',
    'Fill tender outboard fuel tank and spare petrol container.',
    'lib/assets/lists/OneWeek/Petrol.jpg',
  );
  add(
    oneWeekId,
    'LPG Gas',
    'Refill all LPG cylinders. Confirm correct gas type (butane or propane) compatible with vessel system.',
    'lib/assets/lists/OneWeek/LPGGas.jpg',
  );
  add(
    oneWeekId,
    'Standing Rigging',
    'Visually inspect all standing rigging components (shrouds, stays, terminals, tangs) for corrosion, cracks, or deformation.',
    'lib/assets/lists/OneWeek/StandingRigging.jpg',
  );
  add(
    oneWeekId,
    'Running Rigging',
    'Inspect running rigging for chafe and wear; examine blocks, clutches, and organizers for cracks or stiffness. Clean thoroughly if equipment has been unused.',
    'lib/assets/lists/OneWeek/RunningRigging.jpg',
  );
  add(
    oneWeekId,
    'Watermaker',
    'Test watermaker operation and replace pre-filters if pressure or flow indicates need.',
    'lib/assets/lists/OneWeek/WaterMaker.jpg',
  );
  add(
    oneWeekId,
    'Navigation Lights',
    'Test all navigation lights (port, starboard, stern, steaming, anchor, deck) and verify spare bulbs are onboard (including tri-color if fitted).',
    'lib/assets/lists/AnualChecks/NavigationLights.jpg',
  );
  add(
    oneWeekId,
    'Weather Forecast',
    'Obtain latest weather forecast and compare with previous predictions. Consider postponement or route changes if conditions deteriorate.',
    'lib/assets/lists/OneWeek/Weather.jpg',
  );
  add(
    oneWeekId,
    'Proposed Routing',
    'Revalidate planned route considering updated weather, low-pressure systems, geopolitical issues, health alerts, and current destination news.',
    'lib/assets/lists/OneWeek/ProposedRouting.jpg',
  );
  add(
    oneWeekId,
    'Passage Plan',
    'Finalize detailed passage plan using highest-resolution electronic charts; identify shallows, rocks, and hazards along primary and alternate tracks, accounting for potential long tacks.',
    'lib/assets/lists/AnualChecks/PassagePlanning.jpg',
  );
  add(
    oneWeekId,
    'Insurance',
    'Notify insurer of intended passage details and obtain written confirmation of coverage for the area and season (e.g., exclusion of hurricane zones).',
    'lib/assets/lists/DocumentsChecks/BoatInsurance.jpg',
  );
  add(
    oneWeekId,
    'Clearance Procedures',
    'Research and complete all outbound and inbound clearance requirements (Health, Police, Immigration, Customs). Ensure crew passports are valid and required visas/vaccinations (e.g., yellow fever, COVID-19) are in order.',
    'lib/assets/lists/DocumentsChecks/OnlineRequirements.jpg',
  );

  // Hidden items from old seeding data
  add(
    oneWeekId,
    'Shaft Coupling',
    'Check Shaft Coupling',
    'lib/assets/lists/OneWeek/NoPicture.jpg',
  );
  items.last.isHidden = true;

  await seedChecklistItemsToDrift(items);
}
