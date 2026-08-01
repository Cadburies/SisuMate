import 'checklist_drift_seed.dart';
import '../../models/models.dart';

final annualId = 'anualId';

Future<void> seedAnnualChecks(String defaultBoatSupabaseId) async {
  // ===================================================================
  // CHECKLIST GROUP - Annual
  // ===================================================================
  final group = ChecklistGroup()
    ..supabaseId = annualId
    ..boatSupabaseId = defaultBoatSupabaseId
    ..title = 'Annual Checks'
    ..iconName = 'tools'
    ..sortOrder = 3
    ..appType = 'checklist'
    ..isBundled = true;

  await seedChecklistGroupToDrift(group);

  // ===================================================================
  // CHECKLIST ITEMS - Annual
  // ===================================================================
  final items = <ChecklistItem>[];

  // Helper to reduce boilerplate
void add(String groupId, String title, String description, String assetPath) {
    items.add(
      ChecklistItem()
        ..supabaseId =
            '${groupId}_${title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}'
        ..groupSupabaseId = groupId
        ..title = title
        ..description = description
        ..assetName = assetPath
        ..isCompleted = false
        ..isHidden = false
        ..isPermanentlyDeleted = false
        ..sortOrder = items.length,
    );
  }
  add(
    annualId,
    'Important Disclaimer',
    'This checklist is derived from annual maintenance and preparation tasks performed on a 2018 Leopard 45 catamaran... Users must adapt this checklist to their specific vessel.',
    'lib/assets/Disclaimer.jpg',
  );
  add(
    annualId,
    'Passage Planning',
    'Prepare detailed passage plans including primary and alternate routes, anchorages, ports of refuge, VHF frequencies...',
    'lib/assets/lists/AnualChecks/PassagePlanning.jpg',
  );
  add(
    annualId,
    'Cleaning',
    'Thoroughly clean the hull, deck, and topsides using mild detergent to remove salt, dirt, and marine growth.',
    'lib/assets/lists/AnualChecks/Cleaning.jpg',
  );
  add(
    annualId,
    'Scuppers',
    'Inspect and clear all scuppers and drains of debris to ensure unrestricted water flow from the deck.',
    'lib/assets/lists/AnualChecks/Scuppers.jpg',
  );
  add(
    annualId,
    'Polish Metal',
    'Clean and polish all exterior stainless steel and metal fittings to remove oxidation and restore protection.',
    'lib/assets/lists/AnualChecks/PolishMetal.jpg',
  );
  add(
    annualId,
    'Clean Hatches',
    'Clean hatches and portlights; treat rubber seals with a non-petroleum-based conditioner.',
    'lib/assets/lists/AnualChecks/CleanHatches.jpg',
  );
  add(
    annualId,
    'Clean Canvas',
    'Clean sails, bimini, dodger, and all canvaswork to remove salt, mold, and dirt.',
    'lib/assets/lists/AnualChecks/CleanCanvas.jpg',
  );
  add(
    annualId,
    'Clean Interior',
    'Perform a complete interior cleaning including bilges; inspect for leaks, cracks, or structural damage.',
    'lib/assets/lists/AnualChecks/CleanInterior.jpg',
  );
  add(
    annualId,
    'Spares',
    'Review and replenish inventory of critical spare parts, tools, filters, belts, impellers, and consumables.',
    'lib/assets/lists/AnualChecks/Spares.jpg',
  );
  add(
    annualId,
    'Boat Registration',
    'Verify vessel registration documents are current and kept aboard.',
    'lib/assets/lists/AnualChecks/BoatRegistration.jpg',
  );
  add(
    annualId,
    'Dive Cylinders',
    'Inspect dive cylinders for current visual inspection and hydrostatic test dates; service or replace as required.',
    'lib/assets/lists/AnualChecks/DiveCylinders.jpg',
  );
  add(
    annualId,
    'Dive Compressor Operation',
    'Test operation of the dive compressor and perform required maintenance per manufacturer guidelines.',
    'lib/assets/lists/AnualChecks/DiveCompressor.jpg',
  );
  add(
    annualId,
    'Dive Compressor Oil',
    'Check and top up or replace dive compressor oil using specified #SM107 mineral oil.',
    'lib/assets/lists/AnualChecks/CompressorOil.jpg',
  );
  add(
    annualId,
    'Dive Compressor Filter',
    'Replace the dive compressor filter cartridge (#VM10300100).',
    'lib/assets/lists/AnualChecks/CompressorFilter.jpg',
  );
  add(
    annualId,
    'Hull Condition',
    'Inspect underwater hull for damage, scratches, gouges, osmotic blisters, or stress cracks; repair as necessary.',
    'lib/assets/lists/AnualChecks/HullCondition.jpg',
  );
  add(
    annualId,
    'Zinc Anodes',
    'Inspect and replace propeller, saildrive, and hull zinc anodes based on remaining material.',
    'lib/assets/lists/AnualChecks/ZincAnodes.jpg',
  );
  add(
    annualId,
    'DriveTrain',
    'Inspect saildrives, seals, shafts, cutless bearings, propellers, and folding mechanisms for wear or damage.',
    'lib/assets/lists/AnualChecks/DriveTrain.jpg',
  );
  add(
    annualId,
    'Antifouling',
    'Apply new antifouling paint or perform touch-ups as required based on existing coating condition.',
    'lib/assets/lists/AnualChecks/Antifouling.jpg',
  );
  add(
    annualId,
    'Stanchions',
    'Inspect stanchions, pulpits, pushpits, and lifelines for security, cracks, and corrosion.',
    'lib/assets/lists/AnualChecks/Stanchions.jpg',
  );
  add(
    annualId,
    'Mooring Lines',
    'Inspect all mooring lines for chafe, wear, and UV degradation; replace as necessary.',
    'lib/assets/lists/AnualChecks/MooringLines.jpg',
  );
  add(
    annualId,
    'Mooring Cleats',
    'Inspect mooring cleats and backing plates for tightness, cracks, and signs of water ingress.',
    'lib/assets/lists/AnualChecks/MooringCleats.jpg',
  );
  add(
    annualId,
    'Mooring Fenders',
    'Inspect fenders for pressure and condition; inflate or replace as required.',
    'lib/assets/lists/AnualChecks/MooringFenders.jpg',
  );
  add(
    annualId,
    'Spare Mooring Equipment',
    'Ensure adequate spare mooring lines and fenders are onboard.',
    'lib/assets/lists/AnualChecks/SpareFenders.jpg',
  );
  add(
    annualId,
    'Ground Tackle',
    'Inspect anchor, chain, rope, swivel, and shackles for wear, corrosion, and security.',
    'lib/assets/lists/AnualChecks/GroundTackle.jpg',
  );
  add(
    annualId,
    'Windlass',
    'Service windlass and remote controls; clean and lubricate moving parts.',
    'lib/assets/lists/AnualChecks/Windlass.jpg',
  );
  add(
    annualId,
    'Winches',
    'Perform full service on all winches (disassemble, clean, regrease, reassemble).',
    'lib/assets/lists/AnualChecks/Winches.jpg',
  );
  add(
    annualId,
    'Swim Ladder',
    'Inspect swim ladder mounting, operation, and watertight integrity.',
    'lib/assets/lists/AnualChecks/SwimLadder.jpg',
  );
  add(
    annualId,
    'Port Light Leaks',
    'Inspect all deck hatches, portlights, and windows for leaks and seal condition.',
    'lib/assets/lists/AnualChecks/PortLight.jpg',
  );
  add(
    annualId,
    'Davits',
    'Inspect davits, blocks, cables, and winches for wear and proper operation.',
    'lib/assets/lists/AnualChecks/Davits.jpg',
  );
  add(
    annualId,
    'Seacocks',
    'Exercise, lubricate, and inspect all seacocks and skin fittings.',
    'lib/assets/lists/AnualChecks/Seacocks.jpg',
  );
  add(
    annualId,
    'Hoses Below Decks',
    'Inspect all hoses and hose clamps below deck level; replace cracked or hardened hoses.',
    'lib/assets/lists/AnualChecks/HosesBelowDecks.jpg',
  );
  add(
    annualId,
    'Hoses Below Waterline',
    'Verify all hoses below the waterline are double-clamped with marine-grade stainless clamps.',
    'lib/assets/lists/AnualChecks/HosesBelowWaterline.jpg',
  );
  add(
    annualId,
    'Bilge Pumps',
    'Test all bilge pumps in manual and automatic modes; test high-water alarm.',
    'lib/assets/lists/AnualChecks/BilgePumps.jpg',
  );
  add(
    annualId,
    'Bilges',
    'Inspect bilges for oil/water accumulation and salt crystallization around thru-hulls and seacocks.',
    'lib/assets/lists/AnualChecks/Bilge.jpg',
  );
  add(
    annualId,
    'Limber Holes',
    'Ensure all limber holes are clear of debris to allow proper bilge drainage.',
    'lib/assets/lists/AnualChecks/LimberHoles.jpg',
  );
  add(
    annualId,
    'Batteries',
    'Test batteries, clean terminals, check electrolyte (if applicable), and recharge or replace as needed.',
    'lib/assets/lists/AnualChecks/Batteries.jpg',
  );
  add(
    annualId,
    'Battery Terminals',
    'Clean battery terminals and apply corrosion inhibitor.',
    'lib/assets/lists/AnualChecks/BatteryTerminals.jpg',
  );
  add(
    annualId,
    'Charger/Inverter',
    'Verify correct operation of battery charger and inverter/charger system.',
    'lib/assets/lists/AnualChecks/Inverter.jpg',
  );
  add(
    annualId,
    'Galvanic Isolator',
    'Test galvanic isolator functionality and confirm AC ground connection to shore power.',
    'lib/assets/lists/AnualChecks/GalvanicIsolator.jpg',
  );
  add(
    annualId,
    'Wiring',
    'Inspect visible wiring for chafe, corrosion, and secure connections.',
    'lib/assets/lists/AnualChecks/Wiring.jpg',
  );
  add(
    annualId,
    'Gauges',
    'Test all instrument gauges and displays for accurate operation.',
    'lib/assets/lists/AnualChecks/Gauges.jpg',
  );
  add(
    annualId,
    'Speed Log',
    'Remove, clean, and reinstall speed log transducer/impeller.',
    'lib/assets/lists/AnualChecks/SpeedLog.jpg',
  );
  add(
    annualId,
    'Shore Power Cables',
    'Inspect shore power cables and connectors for damage, corrosion, or overheating signs.',
    'lib/assets/lists/AnualChecks/ShorePower.jpg',
  );
  add(
    annualId,
    'Spare Fuses',
    'Verify adequate stock of spare fuses for all critical systems.',
    'lib/assets/lists/AnualChecks/SpareFuses.jpg',
  );
  add(
    annualId,
    'Light Bulbs',
    'Test all interior/exterior lighting and confirm spare bulbs are onboard.',
    'lib/assets/lists/AnualChecks/LightBulbs.jpg',
  );
  add(
    annualId,
    'Electronics',
    'Power on and test all electronic systems (chartplotter, VHF, AIS, radar, autopilot, instruments).',
    'lib/assets/lists/AnualChecks/Electronics.jpg',
  );
  add(
    annualId,
    'Antennas',
    'Inspect VHF, AIS, GPS, EPIRB, and WiFi antennas and coax connections for corrosion.',
    'lib/assets/lists/AnualChecks/NoPicture.jpg',
  );
  add(
    annualId,
    'Sound Horn',
    'Test sound signalling device (horn).',
    'lib/assets/lists/AnualChecks/SoundHorn.jpg',
  );
  add(
    annualId,
    'Flares',
    'Check expiry dates of pyrotechnic distress signals and replace as required.',
    'lib/assets/lists/AnualChecks/Flares.jpg',
  );
  add(
    annualId,
    'Harnesses',
    'Inspect safety harnesses and tethers for wear, UV damage, and stitching integrity.',
    'lib/assets/lists/OneWeek/Harnasses.jpg',
  );
  add(
    annualId,
    'PFD Cartridges',
    'Inspect inflatable PFD CO2 cartridges and auto-inflation bobbins; replace if expired or used.',
    'lib/assets/lists/AnualChecks/PFDCartridges.jpg',
  );
  add(
    annualId,
    'PFD Equipment',
    'Inspect all personal flotation devices for damage and functionality.',
    'lib/assets/lists/AnualChecks/PFDEquipment.jpg',
  );
  add(
    annualId,
    'Life Rings',
    'Inspect life rings, throwing lines, and rescue lights.',
    'lib/assets/lists/AnualChecks/LifeRings.jpg',
  );
  add(
    annualId,
    'Fire Extinguishers',
    'Check service status and pressure gauges of all fire extinguishers; service if required.',
    'lib/assets/lists/AnualChecks/FireExtinguishers.jpg',
  );
  add(
    annualId,
    'Compass',
    'Verify compass accuracy and illumination; adjust deviation if necessary.',
    'lib/assets/lists/AnualChecks/Compass.jpg',
  );
  add(
    annualId,
    'Navigation Lights',
    'Test all navigation lights and confirm spare bulbs are available.',
    'lib/assets/lists/AnualChecks/NavigationLights.jpg',
  );
  add(
    annualId,
    'Paper Charts',
    'Update or replace paper charts and check for recent Notices to Mariners.',
    'lib/assets/lists/AnualChecks/PaperCharts.jpg',
  );
  add(
    annualId,
    'Electronic Charts',
    'Verify electronic chart coverage and update for intended cruising area including backups.',
    'lib/assets/lists/AnualChecks/ElectronicCharts.jpg',
  );
  add(
    annualId,
    'Medicines',
    'Check expiry dates of all medical supplies and replenish as necessary.',
    'lib/assets/lists/AnualChecks/Medicines.jpg',
  );
  add(
    annualId,
    'Grab Bag',
    'Inspect and update contents of abandon-ship grab bag including food and water expiry dates.',
    'lib/assets/lists/AnualChecks/GrabBag.jpg',
  );
  add(
    annualId,
    'First Aid',
    'Restock and update first-aid kit contents.',
    'lib/assets/lists/AnualChecks/FirstAid.jpg',
  );
  add(
    annualId,
    'Liferaft',
    'Verify liferaft is in date for professional servicing.',
    'lib/assets/lists/AnualChecks/Liferaft.jpg',
  );
  add(
    annualId,
    'Heads',
    'Service marine toilets, inspect seals, hoses, and raw-water strainers.',
    'lib/assets/lists/AnualChecks/Toilets.jpg',
  );
  add(
    annualId,
    'Holding Tanks',
    'Pump out and flush holding tanks in accordance with local regulations.',
    'lib/assets/lists/AnualChecks/HoldingTanks.jpg',
  );
  add(
    annualId,
    'Skin Fittings',
    'Inspect all skin fittings and valves for corrosion or damage.',
    'lib/assets/lists/AnualChecks/HosesBelowDecks.jpg',
  );
  add(
    annualId,
    'Holding Tank Sensor',
    'Test holding tank level sensor and indicator light.',
    'lib/assets/lists/AnualChecks/TankSensor.jpg',
  );
  add(
    annualId,
    'Diesel Tanks',
    'Inspect diesel tanks for water, debris, and microbial contamination.',
    'lib/assets/lists/AnualChecks/DieselTanks.jpg',
  );
  add(
    annualId,
    '250 Hour Engine Service',
    'Perform complete 250-hour engine service per manufacturer manual.',
    'lib/assets/lists/250HourEngineService/EngineOilFilter.jpg',
  );
  add(
    annualId,
    'Inventory of Coolant',
    'Verify adequate stock of engine coolant.',
    'lib/assets/lists/AnualChecks/NoPicture.jpg',
  );
  add(
    annualId,
    'Inventory Engine Oil',
    'Confirm sufficient engine oil inventory.',
    'lib/assets/lists/AnualChecks/InventoryEngineOil.jpg',
  );
  add(
    annualId,
    'Inventory Engine Oil Filters',
    'Confirm stock of engine oil filters.',
    'lib/assets/lists/250HourEngineService/EngineOilFilter.jpg',
  );
  add(
    annualId,
    'Inventory Fuel Filters',
    'Confirm stock of primary and secondary fuel filters.',
    'lib/assets/lists/250HourEngineService/FuelFilter.jpg',
  );
  add(
    annualId,
    'Inventory Fuel Water Separator',
    'Confirm stock of fuel/water separator elements.',
    'lib/assets/lists/250HourEngineService/FuelSeperator.jpg',
  );
  add(
    annualId,
    'Inventory of Spare Belts',
    'Verify spare alternator and water pump belts are onboard.',
    'lib/assets/lists/AnualChecks/SpareBelts.jpg',
  );
  add(
    annualId,
    'Inventory Impellers',
    'Confirm spare raw-water pump impellers are onboard.',
    'lib/assets/lists/250HourEngineService/Impeller.jpg',
  );
  add(
    annualId,
    'Maintenance Log',
    'Update engine and equipment maintenance log with dates and running hours.',
    'lib/assets/lists/AnualChecks/NoPicture.jpg',
  );
  add(
    annualId,
    'Generator Oil',
    'Change generator engine oil and filter.',
    'oil',
  );
  add(
    annualId,
    'Generator Fuel Filters',
    'Replace generator fuel filters.',
    'filter',
  );
  add(
    annualId,
    'Generator Coolant',
    'Check and top up generator coolant level.',
    'coolant',
  );
  add(
    annualId,
    'Generator Drive Belt',
    'Inspect generator drive belt for wear and tension.',
    'belt',
  );
  add(
    annualId,
    'Generator Exhaust',
    'Inspect generator exhaust system for leaks and corrosion.',
    'exhaust',
  );
  add(
    annualId,
    'Generator Raw Water Pump',
    'Inspect generator raw-water pump and replace impeller if worn.',
    'water-pump',
  );
  add(
    annualId,
    'Generator Mounting',
    'Check generator mounting bolts and vibration isolators.',
    'mounting',
  );
  add(
    annualId,
    'Watermaker Prefilters',
    'Replace watermaker prefilters.',
    'water-filter',
  );
  add(
    annualId,
    'Watermaker Membrane',
    'Inspect and clean or replace watermaker membrane.',
    'filter',
  );
  add(
    annualId,
    'Watermaker High Pressure Pump',
    'Check watermaker high-pressure pump oil level and condition.',
    'water-pump',
  );
  add(
    annualId,
    'Watermaker Valves',
    'Inspect watermaker valves and fittings for leaks and corrosion.',
    'seacocks',
  );
  add(
    annualId,
    'Watermaker Performance',
    'Test watermaker output quality and quantity; record performance data.',
    'watermaker-chart',
  );
  add(
    annualId,
    'Fresh Water Tanks',
    'Flush and disinfect fresh water tanks with chlorine solution.',
    'lib/assets/lists/AnualChecks/FreshWaterTanks.jpg',
  );
  add(
    annualId,
    'Fresh Water Pump',
    'Inspect fresh-water pump and accumulator tank for proper operation.',
    'water-pump',
  );
  add(
    annualId,
    'Fresh Water Filters',
    'Replace inline fresh-water filters or carbon cartridges.',
    'water-filter',
  );
  add(
    annualId,
    'Water Heater',
    'Drain, flush, and inspect water heater for scale buildup and anode condition.',
    'water-heater',
  );
  add(
    annualId,
    'Propane System',
    'Inspect propane system, tanks, hoses, and regulators; perform leak test.',
    'propane',
  );
  add(
    annualId,
    'Galley Stove',
    'Clean and test galley stove burners and oven; inspect gimbal mechanism.',
    'stove',
  );
  add(
    annualId,
    'Refrigeration',
    'Defrost and clean refrigerators and freezers; check door seals and compressor operation.',
    'refrigerator',
  );
  add(
    annualId,
    'Air Conditioning',
    'Clean air conditioning strainers and air filters; check condensate drains.',
    'ac-unit',
  );
  add(
    annualId,
    'Dinghy Outboard',
    'Perform annual service on dinghy outboard motor.',
    'outboard',
  );
  add(
    annualId,
    'Dinghy Hull',
    'Inspect dinghy hull for damage, leaks, and UV degradation; check inflation pressure.',
    'hull',
  );
  add(
    annualId,
    'Dinghy Equipment',
    'Verify dinghy equipment (oars, pump, repair kit, anchor) is complete and functional.',
    'hull',
  );
  add(
    annualId,
    'Dinghy Fuel',
    'Ensure adequate dinghy fuel supply and check fuel line condition.',
    'fuel',
  );
  add(
    annualId,
    'Standing Rigging',
    'Inspect standing rigging for broken strands, corrosion, and terminal condition.',
    'rigging',
  );
  add(
    annualId,
    'Running Rigging',
    'Inspect running rigging for chafe, wear, and UV damage; wash lines to remove salt.',
    'rigging',
  );
  add(
    annualId,
    'Sails',
    'Inspect sails for tears, UV damage, and stitching failure; send for repairs if needed.',
    'sail',
  );
  add(
    annualId,
    'Sail Hardware',
    'Inspect sail hardware (battens, cars, slugs) for wear and damage.',
    'hardware',
  );
  add(
    annualId,
    'Blocks',
    'Clean and lubricate all blocks and sheaves.',
    'hardware',
  );
  add(
    annualId,
    'Clutches',
    'Clean, inspect, and lubricate line clutches and jammers.',
    'hardware',
  );
  add(
    annualId,
    'Masthead',
    'Inspect masthead sheaves, fittings, and instruments (sent aloft or lower mast if possible).',
    'masthead',
  );
  add(
    annualId,
    'Spreaders',
    'Inspect spreaders, boots, and rigging attachment points for damage or corrosion.',
    'spreaders',
  );
  add(
    annualId,
    'Steering Cables',
    'Inspect steering cables, chains, and quadrants for wear and proper tension.',
    'lib/assets/lists/AnualChecks/SteeringCables.jpg',
  );
  add(
    annualId,
    'Rudder Bearings',
    'Inspect rudder bearings and stock for play or binding; lubricate as appropriate.',
    'lib/assets/lists/AnualChecks/RudderBearings.jpg',
  );
  add(
    annualId,
    'Autopilot',
    'Test autopilot operation under load and verify drive unit condition.',
    'autopilot',
  );
  add(
    annualId,
    'Emergency Tiller',
    'Verify emergency tiller fits and operates correctly.',
    'tiller',
  );
  add(
    annualId,
    'Keel Bolts',
    'Inspect keel bolts for corrosion and tightness (if accessible).',
    'keel',
  );

  await seedChecklistItemsToDrift(items);
}
