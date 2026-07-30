import 'checklist_drift_seed.dart';
import '../../models/models.dart';

final dayTripId = 'dayTripId';

Future<void> seedDayTripSafetyBriefing(String defaultBoatSupabaseId) async {
  final group = ChecklistGroup()
    ..supabaseId = dayTripId
    ..boatSupabaseId = defaultBoatSupabaseId
    ..title = 'Day Trip Safety Briefing'
    ..iconName = 'safety'
    ..sortOrder = 2
    ..appType = 'safety'
    ..isBundled = true;

  await seedChecklistGroupToDrift(group);

  final items = <ChecklistItem>[];

  void add(String groupId, String title, String description, String icon) {
    items.add(
      ChecklistItem()
        ..supabaseId =
            '${groupId}_${title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}'
        ..groupSupabaseId = groupId
        ..title = title
        ..description = description
        ..assetName = icon
        ..isCompleted = false
        ..isHidden = false
        ..isPermanentlyDeleted = false
        ..sortOrder = items.length,
    );
  }

  // ===================================================================
  // Welcome
  // ===================================================================
  add(
    dayTripId,
    'Welcome Aboard Sisu!',
    "Welcome onboard Sisu, we are happy to have you here! For those who have yet to notice, this is a boat, therefore we all need to work together to keep everyone safe and for everyone to enjoy this trip.",
    'hand-wave',
  );
  add(
    dayTripId,
    'Important Disclaimer',
    "This comprehensive checklist is based on the Leopard 45 2018 Catamaran model, as featured on the SailingSisu YouTube channel (www.YouTube.com/c/SailingSisu, 'Boat Life and Boat Checks' playlist). However, please note that each vessel has unique characteristics and requirements. Before departing, it's essential to tailor this list to your specific boat, engine(s), needs, and circumstances. Additionally, ensure compliance with your country's legal regulations to avoid any potential issues. As the Skipper/Captain, the safety of your vessel, crew, and passengers is your responsibility. Use this application wisely and at your own risk. The developer shall not be held liable for any damage, loss, or injury resulting from the use of this product.",
    'shield-alert',
  );

  // ===================================================================
  // Personal Care
  // ===================================================================
  add(
    dayTripId,
    'Stowage of Personal Belongings',
    'The crew will show you where to store your belongings in the two port side cabins on the bed.',
    'briefcase',
  );
  add(
    dayTripId,
    'Fresh Warm Water Showers',
    'There is a freshwater washdown shower at the ladder to wash off the saltwater after a swim. However, if you desire a hot water shower, please ask a crew member at least one hour before your intended shower so that we can turn the heater on.',
    'shower',
  );
  add(
    dayTripId,
    'Sunscreen',
    'Please apply sunscreen often, especially after a swim.',
    'sun',
  );
  add(
    dayTripId,
    'Water Hydration',
    'Please drink water often to prevent dehydration.',
    'droplet',
  );
  add(
    dayTripId,
    'All Taps Are Pure RO Drinking Water',
    'We make our own freshwater through reverse osmosis, where we convert seawater into freshwater. This is the purest of water — every tap on board serves this same pure RO drinking water.',
    'watermaker',
  );
  add(
    dayTripId,
    'How to Use the Heads/Toilets',
    'This boat has freshwater handheld bidets. We do not flush anything down the toilet that did not go through your own body.\nNo paper, no sanitary towels, tampons, loose hair, or any other manufactured product.\nThere are three basic flush operations: Fill and Flush, Flush only, Fill only.\nWe normally Fill and Flush first, then use the freshwater bidet to clean. Yes, your hands will get dirty, but as your Mom always said... wash your hands! Now you know why :-)\nYou can use the paper to wipe dry and dispose of it in the bin provided. DO NOT THROW THE PAPER IN THE TOILET.\nWe then flush only and wait a minute. Fill only the basin again and then flush only. Repeat the fill only and flush only one more time.',
    'toilet',
  );
  add(
    dayTripId,
    'Getting On and Off the Boat/Dinghy',
    'The sea state changes all the time, waves get bigger or faster all the time.\nMake sure to wait for the right moment before stepping on/off. The right moment is when the gap between the dinghy and boat closes enough for you to step on/off comfortably.\nStep off smartly as soon as the gap closes. DO NOT PUSH ON YOUR BACK FOOT. This will open the gap again and you might fall through the gap.\nUse the momentum of the closing vessel to transfer your weight completely and smartly to the front foot. DO NOT JUMP.\nAsk the crew member to assist you.',
    'waves',
  );
  add(
    dayTripId,
    'Gybing or Tacking',
    'Catamarans are more forgiving whilst tacking and gybing, the Skipper will call out "Gybing!" or "Tacking!" to prepare you for the manoeuvre.\nDuring the manoeuvre, the boat will react differently and may even become like a bucking horse. Ensure that you are holding onto something during this period. It normally lasts for 20-30 seconds.\nFor this reason, no one is allowed on the coach roof whilst sailing. The boom is very dangerous during a Gybe or Tack.',
    'sail',
  );
  add(
    dayTripId,
    'Life Jackets',
    'This boat has 13 Life Jackets. They are stored in the forward cockpit in the starboard locker.\nThey work very much the same as the airplane ones. Unfold and pull the Life Jacket over your head. Fold the straps around your waist backwards and then forward again to tie off.\nIt is advised to wear the Life Jackets throughout the trip.',
    'life-ring',
  );
  add(
    dayTripId,
    'First Aid Kit',
    'We have a Grabber Bag, which is only to be used in the event of evacuation and has the big word "GRABBER" on it.\nWe also have a First Aid Kit, marked with a red cross. Both are in the aft cockpit below the window seat. Make sure to retrieve the correct one!\nPlease, if you do have a headache, ask the Skipper or crew member first, we have a Medicine Kit with headache pills too.',
    'medkit',
  );

  // ===================================================================
  // Water Ingress
  // ===================================================================
  add(
    dayTripId,
    'Sources of Flooding',
    'The main reasons for water ingress are open taps, burst pipes, and damage to the hull. In short, freshwater or saltwater from leaks/damage.\nThe catamaran will not sink immediately. Let\'s discuss these sources and how to prevent flooding.',
    'droplet',
  );
  add(dayTripId, 'Close All Taps', 'Close any tap you open.', 'faucet');
  add(
    dayTripId,
    'Wash Down Pump',
    'Close the shut off valve and depressurize the pipe by pushing the hand lever.',
    'water-pump',
  );
  add(
    dayTripId,
    'Bidet Valve',
    'Close the bidet shut off valve after use.',
    'plumbing',
  );
  add(
    dayTripId,
    'Conserve Freshwater',
    'Making RO water is a long process, which can only be done in clear seawater, so we have to use freshwater sparingly.\nFor example, turn the tap off whilst you brush your teeth, then only turn it on to rinse. We can all hear the freshwater pressure pump running :-)',
    'droplet',
  );
  add(
    dayTripId,
    'Detect & Report Flooding',
    'Notify the Skipper or crew member immediately if you see an unusual amount of water in the boat or if you hear water sloshing around.',
    'shield-alert',
  );

  // ===================================================================
  // Fire
  // ===================================================================
  add(
    dayTripId,
    'Fire Is the Greatest Danger Onboard',
    'Fire is the worst thing that can happen on a catamaran and needs special attention and swift action.',
    'flame',
  );
  add(
    dayTripId,
    'Sources of Fire',
    'There are three sources for fire: LPG gas, electrical circuit overloading, and diesel. Let\'s discuss these sources and how to prevent fires.',
    'flame',
  );
  add(
    dayTripId,
    'No Open Fires',
    'No open fires are allowed on the boat other than controlled LPG gas burners. Only use the gas heating from the BBQ, stove and burners.',
    'flame',
  );
  add(
    dayTripId,
    'No Smoking',
    'No matches are allowed. Smoking is NOT allowed inside the boat. Smoking is only permitted on the downwind sugar scoop.',
    'alert-triangle',
  );
  add(
    dayTripId,
    'LPG Gas',
    'This boat uses LPG gas for cooking, baking, and BBQ. If you at any time smell LPG gas, notify the Skipper or crew member immediately.',
    'propane',
  );
  add(
    dayTripId,
    'Cooking or BBQ',
    'You need the permission of the Skipper to use the gas burners or to BBQ.\nEven making coffee/tea, first ask the Skipper or crew member for permission and to show you how it works.',
    'chef-hat',
  );
  add(
    dayTripId,
    'Charging Devices',
    'There are plenty of USB charging ports on the boat. Use only the existing charging ports. Do not overload charging wires.',
    'zap',
  );
  add(
    dayTripId,
    'Any 110/220V Electrical Device',
    'The boat is configured for 220V 50Hz. There are plenty of European 220V plugs.\nAsk the Skipper or crew member if you can use any of your electrical devices and/or private adapters.',
    'electrical',
  );
  add(
    dayTripId,
    'Fire Extinguisher Locations',
    'There are six fire extinguishers on this boat, they are all marked with a red and white fire extinguisher label.\nThere is one in each room/cabin, one next to the mast in the kitchen, one in the forward cockpit, and one in the aft cockpit. Please familiarise yourself with the locations of each one.',
    'fire-extinguisher',
  );
  add(
    dayTripId,
    'Fire Detection',
    'Notify the Skipper or crew member immediately if you smell smoke or see a flame, whether electrical, wood, or plastic.',
    'shield-alert',
  );
  add(
    dayTripId,
    'Using a Fire Extinguisher',
    'In the event of a fire, shout out loud for the Skipper or crew member and retrieve the fire extinguisher closest to you as soon as possible and if it is safe to do so.\nIf the Skipper and crew member are non-reactive, pull the safety pin, aim for the base of the fire, and squeeze the lever.',
    'fire-extinguisher',
  );
  add(
    dayTripId,
    'Abandon Boat Command',
    'DO NOT JUMP OVERBOARD UNLESS TOLD TO BY THE SKIPPER! Only the Skipper will give the command to abandon ship.\nIf you preemptively jump overboard the Skipper will need to handle two crises: the current crisis and a man overboard.',
    'life-ring',
  );
  add(
    dayTripId,
    'Any Questions?',
    'Invite questions and ensure all guests understand the safety briefing before getting underway.',
    'message-circle',
  );

  await seedChecklistItemsToDrift(items);
}
