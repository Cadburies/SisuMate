import 'checklist_drift_seed.dart';
import '../../models/models.dart';

final oneDayId = 'oneDayId';

Future<void> seedOneDayChecks(String defaultBoatSupabaseId) async {
  // ===================================================================
  // CHECKLIST GROUP - One Day
  // ===================================================================
  final group = ChecklistGroup()
    ..supabaseId = oneDayId
    ..boatSupabaseId = defaultBoatSupabaseId
    // ..name = 'One Day Before Departure Checks' // Undefined setter, commented out temporarily
    // ..icon = 'calendar-day' // Undefined setter, commented out temporarily
    ..title = 'One Day Before Departure Checks'
    ..iconName = 'calendar-day'
    ..sortOrder = 6
    ..appType = 'checklist'
    ..isBundled = true;

  await seedChecklistGroupToDrift(group);

  // ===================================================================
  // CHECKLIST ITEMS - One Day
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
    oneDayId,
    'Important Disclaimer',
    'This checklist is derived from final pre-departure procedures performed on a 2018 Leopard 45 catamaran... Users must adapt this checklist to their specific vessel.',
    'lib/assets/Disclaimer.jpg',
  );
  add(
    oneDayId,
    'Replenish Perishables',
    'Purchase and stow all perishable provisions (fresh produce, dairy, meat, bread). Verify market opening times to avoid last-minute shortages.',
    'lib/assets/lists/OneDay/Perishable.jpg',
  );
  add(
    oneDayId,
    'Engine Check',
    'Perform a complete daily engine and systems check in accordance with the standard engine-room checklist.',
    'lib/assets/lists/DailyEngineChecks/EngineOil.jpg',
  );
  add(
    oneDayId,
    'Liferaft',
    'Confirm liferaft is correctly mounted, painter line is secured yet readily accessible, and hydrostatic release (if fitted) is armed.',
    'lib/assets/lists/AnualChecks/Liferaft.jpg',
  );
  add(
    oneDayId,
    'Tender Drain Plugs',
    'Install all drain plugs in the tender and verify they are securely seated.',
    'lib/assets/lists/OneDay/PlugTender.jpg',
  );
  add(
    oneDayId,
    'Wet Locker Drains',
    'Install plugs in all wet-locker and cockpit drain holes to prevent down-flooding in heavy weather.',
    'lib/assets/lists/OneDay/PlugDrainHoles.jpg',
  );
  add(
    oneDayId,
    'Anchor Readiness',
    'Verify primary anchor is ready for immediate deployment. For offshore passages, secure anchor and lock chain to prevent accidental release.',
    'lib/assets/lists/OneDay/Anchor.jpg',
  );
  add(
    oneDayId,
    'Ditch Bag / Grab Bag',
    'Inspect ditch bag contents and position it for immediate access (e.g., top of lazarette).',
    'lib/assets/lists/OneDay/DitchBag.jpg',
  );
  add(
    oneDayId,
    'Secure Tender',
    'Secure tender on davits or deck with additional tie-downs and bow painter; confirm no loose gear inside.',
    'lib/assets/lists/OneDay/SecureTender.jpg',
  );
  add(
    oneDayId,
    'Tender Outboard',
    'Secure outboard engine in its bracket or stow position and verify it is locked or lashed.',
    'lib/assets/lists/OneDay/TenderOutboard.jpg',
  );
  add(
    oneDayId,
    'Jacklines',
    'Rig jacklines port and starboard. Verify no lines cross over them and that a tethered crew member can reach all working areas without unhooking. Confirm tether length prevents going overboard.',
    'lib/assets/lists/OneDay/JackStay.jpg',
  );
  add(
    oneDayId,
    'Preventers & Barber Haulers',
    'Position boom preventers and barber haulers for rapid deployment without entanglement.',
    'lib/assets/lists/OneDay/Preventers.jpg',
  );
  add(
    oneDayId,
    'Cockpit Speakers',
    'Cover external cockpit speakers with waterproof plastic bags to protect from spray.',
    'lib/assets/lists/OneDay/Speakers.jpg',
  );
  add(
    oneDayId,
    'Bilge Pumps',
    'Manually lift float switches on all bilge pumps to confirm operation and verify high-water alarms sound.',
    'lib/assets/lists/AnualChecks/BilgePumps.jpg',
  );
  add(
    oneDayId,
    'Batteries',
    'Confirm all battery banks are switched on, fully charged, and isolators are in correct positions.',
    'lib/assets/lists/OneDay/Batteries.jpg',
  );
  add(
    oneDayId,
    'Stow Loose Gear',
    'Secure or stow all loose items on deck and below. Ensure clear passage on deck and in cockpit for emergency movement.',
    'lib/assets/lists/OneDay/LooseGear.jpg',
  );
  add(
    oneDayId,
    'Drinking Water',
    'Top up all drinking water containers and verify adequate supply for the passage.',
    'lib/assets/lists/AnualChecks/FreshWaterTanks.jpg',
  );
  add(
    oneDayId,
    'Final Weather Forecast',
    'Obtain and review the latest weather forecast; adjust departure time or route if conditions have deteriorated.',
    'lib/assets/lists/OneWeek/Weather.jpg',
  );
  add(
    oneDayId,
    'Finalize Passage & Pilotage Plans',
    'Complete detailed passage and pilotage plans. Record VHF frequencies, telephone numbers, and email contacts for ports of call and ports of refuge.',
    'lib/assets/lists/AnualChecks/PassagePlanning.jpg',
  );
  add(
    oneDayId,
    'Notify Shore Contacts',
    'Provide final passage plan, expected ETA, tracking link, and satellite contact details (Iridium number/email) to designated shore contacts.',
    'lib/assets/lists/OneDay/NoPicture.jpg',
  );
  add(
    oneDayId,
    'Outbound Clearance',
    'Complete all formal outbound clearance procedures with Health, Police, Immigration, and Customs authorities; obtain zarpe/exit clearance and ensure passports are stamped.',
    'lib/assets/lists/DocumentsChecks/OnlineRequirements.jpg',
  );

  // Hidden items from old seeding data
  add(
    oneDayId,
    'Topping Lift',
    'Remove Topping Lift',
    'lib/assets/lists/OneDay/NoPicture.jpg',
  );
  items.last.isHidden = true;

  await seedChecklistItemsToDrift(items);
}
