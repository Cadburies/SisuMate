import 'checklist_drift_seed.dart';
import '../../models/models.dart';

final longTripId = 'longTripId';
Future<void> seedLongTripSafetyBriefing(
  String defaultBoatSupabaseId,
) async {
  final group = ChecklistGroup()
    ..supabaseId = longTripId
    ..boatSupabaseId = defaultBoatSupabaseId
    ..title = 'Long Passage Safety Briefing'
    ..iconName = 'skull-crossbones'
    ..sortOrder = 9
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
    longTripId,
    'Welcome Aboard Sisu!',
    "Welcome onboard Sisu, we are happy to have you here! For those who have yet to notice, this is a boat, therefore we all need to work together to keep everyone safe and for everyone to enjoy this trip.",
    'hand-wave',
  );
  add(
    longTripId,
    'Important Disclaimer',
    "This comprehensive checklist is based on the Leopard 45 2018 Catamaran model, as featured on the SailingSisu YouTube channel (www.YouTube.com/c/SailingSisu, 'Boat Life and Boat Checks' playlist). However, please note that each vessel has unique characteristics and requirements. Before departing, it's essential to tailor this list to your specific boat, engine(s), needs, and circumstances. Additionally, ensure compliance with your country's legal regulations to avoid any potential issues. As the Skipper/Captain, the safety of your vessel, crew, and passengers is your responsibility. Use this application wisely and at your own risk. The developer shall not be held liable for any damage, loss, or injury resulting from the use of this product.",
    'shield-alert',
  );

  // ===================================================================
  // Personal Care
  // ===================================================================
  add(
    longTripId,
    'Stowage of Personal Belongings',
    'Under each of your cabin beds is a drawer. There is also a hanging closet. You may use both these spaces to stow your belongings.\nThe drawer can be opened by pushing the latch button in and releasing it.\nPlease ensure that the drawer latch is always pushed in and latched when not in use.\nInside the closet is the fire extinguisher.',
    'briefcase',
  );
  add(
    longTripId,
    'Fresh Warm Water Showers',
    'There is a freshwater washdown shower at the ladder to wash off the saltwater after a swim.\nHowever, if you desire a hot water shower, please ask a crew member at least one hour before your intended shower.',
    'shower',
  );
  add(
    longTripId,
    'Sunscreen',
    'Please apply sunscreen often, especially after a swim.',
    'sun',
  );
  add(
    longTripId,
    'Water Hydration',
    'Please drink water often to prevent dehydration.',
    'droplet',
  );
  add(
    longTripId,
    'All Taps Are Pure RO Drinking Water',
    'We make our own freshwater through reverse osmosis, where we convert seawater into freshwater. This is the purest of water - every tap on board serves this same pure RO drinking water.',
    'watermaker',
  );
  add(
    longTripId,
    'How to Use the Heads/Toilets',
    'This boat has freshwater handheld bidets. We do not flush anything down the toilet that did not go through your own body.\nNo paper, no sanitary towels, tampons, loose hair, or any other manufactured product.\nThere are three basic flush operations: Fill and Flush, Flush only, Fill only.\nWe normally Fill and Flush first, then use the freshwater bidet to clean. Yes, your hands will get dirty, but as your Mom always said... wash your hands! Now you know why :-)\nYou can use the paper to wipe dry and dispose of it in the bin provided. DO NOT THROW THE PAPER IN THE TOILET.\nWe then flush only and wait a minute. Fill only the basin again and then flush only. Repeat the fill only and flush only one more time.',
    'toilet',
  );
  add(
    longTripId,
    'Getting On and Off the Boat/Dinghy',
    'The sea state changes all the time, waves get bigger or faster all the time.\nMake sure to wait for the right moment before stepping on/off. The right moment is when the dinghy and boat are moving to close the gap.\nStep off smartly as soon as the gap closes. DO NOT PUSH ON YOUR BACK FOOT. This will open the gap again and you might fall through the gap.\nUse the momentum of the closing vessel to transfer your weight completely and smartly to the front foot. DO NOT JUMP.\nAsk the crew member to assist you.',
    'waves',
  );
  add(
    longTripId,
    'Gybing or Tacking',
    'Catamarans are more forgiving whilst tacking and gybing, but the Skipper will make the call "Gybing!" or "Tacking!".\nDuring the manoeuvre, the boat will react very differently and may even become like a bucking horse. Ensure that you are holding onto something during this period. It normally lasts for 20-30 seconds.\nFor this reason, no one is allowed on the coach roof while sailing. The boom is very dangerous during a Gybe or Tack.',
    'sail',
  );
  add(
    longTripId,
    'Engine Spare Parts',
    'In the event the Skipper and crew are incapacitated and the engine needs spare parts such as an impeller, all serviceable engine spares can be found in the back of each engine room.',
    'oil',
  );
  add(
    longTripId,
    'Starting the Engine',
    'It may be that a person needs to start the engine during a night shift when our boat speed drops below 3kts. Very similar to a car, but with buttons.\nFirst press the "ON" button. A beep should sound to confirm power is at the engine. Press the "CYCLE" button and the engine will swing over and start.\nVerify that water is coming out of the exhaust before revving the engine. If no water is coming out, stop the engine and inspect the strainers. DO NOT RUN THE ENGINE WITHOUT WATER COMING OUT OF THE EXHAUST!!\nConfirm no person is in the water around the hulls. Push the throttle slowly forward to engage the propeller.\nDo the reverse to shut down the engine. Place the throttle in the middle/neutral position. Press the "CYCLE" button until the engine stops, then press the "ON/OFF" button until the engine instruments switch off.',
    'engine',
  );
  add(
    longTripId,
    'Rigging Cutters',
    'In the event of a catastrophe and a person is caught in entangled rigging, there are a few ways to cut the rigging.\nAll the tools can be found in the port forward cabin under the bed. We have a cordless power grinder for when the rigging is not submerged and one can cut safely without fear that the sparks will hurt someone or start a fire.\nThe second option is bolt cutters, which can be used underwater and close to a person.\nThere is also a long crow bar, which can be used to lever heavy fallen objects or bend open a space, door, or hatch.',
    'rigging',
  );
  add(
    longTripId,
    'Life Jackets',
    'This boat has 13 Life Jackets. They are stored in the forward cockpit in the starboard locker.\nThey work very much the same as the airplane ones. Unfold and pull the Life Jacket over your head. Take each strap around to the back and then further around to the front and tie off.\nIt is advised to wear the Life Jackets throughout the trip.',
    'life-ring',
  );
  add(
    longTripId,
    'Harnesses',
    'This boat has 4 Harnesses. They are stored in the aft cockpit below the window in the locker.\nThey have a built-in inflation device and MOB AIS device, which will activate when the harness hits the water.\nPull the harness over your head. Take the strap from the back and string it between your legs and clip in at the front.\nLastly ensure the clip in front is fastened and the adjustable strap is tightened.\nWhen it is absolutely required to go on the roof with the permission of the Skipper, use the tether strap and clips to clip the harness in and then attach to the yellow line (jack stay) on the roof.\nIt is mandatory to wear the harnesses whenever one leaves the enclosure or at night watch.',
    'shield',
  );
  add(
    longTripId,
    'Jack Stays',
    'Sometimes it is necessary to go onto the roof to reach the mast or to undo a fouled reef line at the end of the boom.\nAlways call or wake the Skipper if this happens. If the Skipper or crew member is hurt or incapacitated, don the harness and tether strap with clips. The coach roof Jack Stay starts at the helm station.\nAlways ensure that the boom is secured and that it will not knock you off the roof. Even though you are strapped in, it is still a bad experience!\nWhile holding onto the rails, clip into the Jack Stay. Carefully, with both hands on the railings, step up to the roof.\nBe prepared that the boat will be bucking like a wild horse. Crawl towards the mast while holding onto the Jack Stay or running rigging.\nIf the mast is your destination, grab the rails on the mast and stand up. Do what needs to be done and return the same way.\nIf you are required to go to the back, then follow the Jack Stay towards the back. It is one continuous line. Use the main sheets and boom to pull you up. Do what needs to be done and return the same way.',
    'cable',
  );
  add(
    longTripId,
    'First Aid Kit',
    'We have a Grabber Bag, which is only to be used in the event of evacuation and has the big word "GRABBER" on it.\nWe also have a First Aid Kit, marked with a red cross. Both are in the aft cockpit below the window seat. Make sure to retrieve the correct one!\nPlease, if you do have a headache, ask the Skipper or crew member first, we have a Medicine Kit with headache pills too.',
    'medkit',
  );

  // ===================================================================
  // Water Ingress
  // ===================================================================
  add(
    longTripId,
    'Sources of Flooding',
    'The main reasons for water ingress are open taps, burst pipes, and damage to the hull. In short, freshwater or saltwater from leaks/damage.\nThe catamaran will not sink immediately. Let\'s discuss these sources and how to prevent flooding.',
    'droplet',
  );
  add(longTripId, 'Close All Taps', 'Close any tap you open.', 'faucet');
  add(
    longTripId,
    'Wash Down Pump',
    'Close the shut off valve and depressurize the pipe by pushing the hand lever.',
    'water-pump',
  );
  add(
    longTripId,
    'Bidet Valve',
    'Close the bidet shut off valve after use.',
    'plumbing',
  );
  add(
    longTripId,
    'Conserve Freshwater',
    'Making RO water is a long process, which can only be done in clear seawater, so we have to use freshwater sparingly.\nFor example, do not let the tap run while you brush your teeth. We can all hear the freshwater pressure pump running :-)',
    'droplet',
  );
  add(
    longTripId,
    'Detect & Report Flooding',
    'Notify the Skipper or crew member immediately if you see an unusual amount of water in the boat or if you hear water sloshing around.\nFreshwater leaks will have an accompanying sound and the light of the freshwater pressure pump coming on every few seconds.\nYou can also determine the source of the water by smelling and then tasting it. If it stinks, well, you know not to taste it.\nIf it does not smell like sewage, then if it tastes like saltwater, we know to look for possible leaks in the hull or saltwater system such as the toilet flush. If it is sweet/freshwater, then we know that our drinking water is getting less.',
    'shield-alert',
  );

  // ===================================================================
  // Fire
  // ===================================================================
  add(
    longTripId,
    'Fire Is the Greatest Danger Onboard',
    'Fire is the worst thing that can happen on a catamaran and needs special attention and swift action.',
    'flame',
  );
  add(
    longTripId,
    'Sources of Fire',
    'There are three sources for fire: LPG gas, electrical circuit overloading, and diesel. Let\'s discuss these sources and how to prevent fires.',
    'flame',
  );
  add(
    longTripId,
    'No Open Fires',
    'No open fires are allowed on the boat other than controlled LPG gas burners. Only use the gas heating from the BBQ, stove and burners.',
    'flame',
  );
  add(
    longTripId,
    'No Smoking',
    'No matches are allowed. Smoking is NOT allowed inside the boat. Smoking is only permitted on the downwind sugar scoop.',
    'alert-triangle',
  );
  add(
    longTripId,
    'LPG Gas',
    'This boat uses LPG gas for cooking, baking, and BBQ. If you at any time smell LPG gas, notify the Skipper or crew member immediately.',
    'propane',
  );
  add(
    longTripId,
    'Cooking or BBQ',
    'The gas burners and BBQ all work through an electrical and mechanical safety mechanism. There are also LPG gas detectors in the hull, but even so, let us be vigilant and careful when using the LPG gas.\nThe LPG electrical switch is in the electrical panel. Switch it on and open the LPG bottle in the gas locker.\nIt will take up to a minute to check the sensors before it is ready to switch the gas solenoid. The solenoid switch is at the stove and when it stops flickering, it is ready. Press the "ON" button.\nTurn the appropriate hob gas knob and press down. THE GAS WILL START TO FLOW IMMEDIATELY. While pressing the knob down, press the lightning bolt button to create sparks, which will ignite the LPG.\nIf the LPG does not ignite within the first 5 sparks, notify the Skipper or crew member, because it may indicate a leak.\nAfter you use the hob, remember to close the knob, switch off the solenoid, switch off the LPG power, and close the LPG gas bottle.',
    'chef-hat',
  );
  add(
    longTripId,
    'Charging Devices',
    'There are plenty of USB charging ports on the boat. Use only the existing charging ports. Do not overload charging wires.',
    'zap',
  );
  add(
    longTripId,
    'Any 110/220V Electrical Device',
    'The boat is configured for 220V 50Hz. There are plenty of European 220V plugs.\nAsk the Skipper or crew member if you can use any of your electrical devices and/or private adapters.',
    'electrical',
  );
  add(
    longTripId,
    'Fire Extinguisher Locations',
    'There are six fire extinguishers on this boat, they are all marked with a red and white fire extinguisher label.\nThere is one in each room/cabin, one next to the mast in the kitchen, one in the forward cockpit, and one in the aft cockpit. Please familiarise yourself with the locations of each one.',
    'fire-extinguisher',
  );
  add(
    longTripId,
    'Fire Detection',
    'Notify the Skipper or crew member immediately if you smell smoke or see a flame, whether electrical, wood, or plastic.',
    'shield-alert',
  );
  add(
    longTripId,
    'Using a Fire Extinguisher',
    'In the event of a fire, shout out loud for the Skipper or crew member and retrieve the closest fire extinguisher as soon as possible and if it is safe to do so.\nIf the Skipper and crew member are non-reactive, pull the safety pin, aim for the base of the fire, and squeeze the lever.',
    'fire-extinguisher',
  );
  add(
    longTripId,
    'Fire in the Engine Room or Gas Locker',
    'In the event of a fire, shout out loud for the Skipper or crew member and retrieve the closest fire extinguisher as soon as possible and if it is safe to do so.\nIf the Skipper and crew member are non-reactive, pull the safety pin, insert the nozzle into the special port, and squeeze the lever.\nDO NOT OPEN THE ENGINE ROOM OR GAS LOCKER DOOR!!',
    'fire-extinguisher',
  );
  add(
    longTripId,
    'Fire on the Stove (Fire Blanket)',
    'There is a fire blanket located in the cabinet at the base of the mast in the saloon.\nOpen and unfold the blanket. First drape it around your hands and let it hang in front of you and your hands.\nApproach the stove and throw the blanket over the fire. Be careful not to get burned, but at the same time cover the whole fire.',
    'flame',
  );
  add(
    longTripId,
    'Radar Reflectors',
    'We carry emergency metal radar reflectors, which are located in the forward cockpit port locker.',
    'radar',
  );
  add(
    longTripId,
    'Spare Iridium GO! and Phones',
    'In the event of an electronic disaster such as a lightning strike, we carry a spare Iridium GO!, phones, and charging devices in the safe.',
    'radio',
  );
  add(
    longTripId,
    'Emergency/Backup VHF',
    'We have a handheld VHF radio on board and it is located at the nav station in the saloon.',
    'radio',
  );
  add(
    longTripId,
    'Using the VHF Radio',
    'The VHF Radio works differently from a phone in that it has a Push To Talk (PTT) button.\nFurther, one can only talk or listen, not both at the same time. Therefore, a language was developed to assist in this awkward "one-way conversation".\nSelect the channel, normally 16, press the PTT and, while holding it in, say your sentence and end it with "over". This way everyone in range will be able to hear you - nothing is private on VHF. The other person will know you are finished with your sentence when you say "over".\nThe very first sentence must start with the name of the boat you are calling repeated three times, followed by your boat\'s name repeated three times, followed by "over".\nRelease the PTT and wait for the answer. You may have to repeat before the other person will answer.\nRemember to switch to another open channel, such as 10, to have a conversation, because 16 is reserved for distress calls and to initiate a call.',
    'radio',
  );
  add(
    longTripId,
    'Mayday Call',
    'One person will be assigned to perform this task, but all need to know in case something happens to the Skipper and crew.\nThe Mayday procedure is written on a card glued to the VHF radio in the electrical panel on your right as you enter the saloon. You can read it word for word except for the parts in the {} brackets.\nThe first one is the GPS coordinates, which you can read from the VHF radio display.\nThe second is the problem/cause of evacuation, such as "serious engine fire".\nThe third is the number of people on board, so count us now and remember.\nThe last one is our intended action, which could be to abandon the boat and get into the attached liferaft.',
    'alert-triangle',
  );
  add(
    longTripId,
    'EPIRB',
    'An Emergency Position Indicating Radio Beacon (EPIRB) is used to alert search and rescue services in the event of an emergency.\nIt does this by transmitting a coded message via the free to use, multinational Cospas-Sarsat network.\nWe have a yellow EPIRB on board and it is located on the right-side wall as one goes down in the starboard hull.\nOnly the Skipper has permission to activate the EPIRB.',
    'radio',
  );
  add(
    longTripId,
    'Man Overboard (MOB)',
    'If you are the one falling overboard, shout/scream as loud as possible in the direction of a crew member or the boat.\nIf you are the one who sees a person falling overboard, shout as loud as possible "Man Overboard!!!" and point your finger at the MOB.\nKeep your eyes always on the person and keep your finger pointed at them. That will be your sole task.\nIt is super easy to lose track of a MOB, so this is the most important job. Keep pointing your finger at them and keep drawing the attention of fellow crew.\nThe Skipper or crew member will take it from there.',
    'life-ring',
  );
  add(
    longTripId,
    'MOB Equipment',
    'This boat has several pieces of MOB equipment.\nThe harnesses are equipped with an inflation device and a MOB AIS device, which will activate when coming into contact with water. This will show up on the chart plotters and raise alarms on all VHF radios in the vicinity.\nIn case the person did not wear a harness, we have flotation devices on the aft starboard rail. There is a flashing light too.\nOnly throw the devices if the MOB would for sure see and reach them. Remember that the MOB cannot see far and you may have wasted a chance to save them.\nThe Skipper and crew members are trained in MOB procedures and one of the first things they do is get back to the MOB and throw the devices when only under sail.\nNormally, the Skipper will immediately depower the sails, switch on the engines, and turn the boat towards the pointed finger.',
    'life-ring',
  );
  add(
    longTripId,
    'Drogue',
    'The Skipper and crew will deploy a drogue in the event of the boat going too fast in a storm and we need to slow it down.\nWe use two 100m lines in a bridle fashion, with a fender attached to the bridle triangle end.',
    'anchor',
  );
  add(
    longTripId,
    'Thermal Protection',
    'Inside the liferaft and inside the GRABBER bag are space blankets to protect against heat or cold temperatures.',
    'ac-unit',
  );
  add(
    longTripId,
    'Flares',
    'The flare container is located in the aft cockpit inside the locker under the window seat.\nInside the container are all sorts of attraction devices, each with a specific purpose.\nFor example, smoke cannot be seen at night, but is very useful during the day for helicopters to understand wind speed and direction.\nDeploy smoke always downwind of the vessel. Only deploy flares or smoke when you are sure of a chance to be seen by potential rescue parties.',
    'flame',
  );
  add(
    longTripId,
    'Evacuation Tasks',
    'Should the Skipper give the command to abandon ship, then everyone will be assigned a task.\nStronger person to handle the liferaft.\nOne person to collect the GRABBER Bag in the aft cockpit below the window locker.\nOne person to collect the FLARE container in the aft cockpit below the window locker.\nOne/two person(s) to collect all life jackets in the forward cockpit.\nOne person to collect all floatable objects, such as cushions/pillows, and throw them into or next to the liferaft. We will sort it out later.\nOne person to collect the spare handheld VHF radio at the nav station.\nOne person to collect the spare Iridium GO!, phones, and charging devices located in the safe.\nOne person to collect freshwater containers and throw them overboard next to the liferaft.',
    'users',
  );
  add(
    longTripId,
    'Liferaft Launch',
    'It is pretty easy to launch the liferaft on this boat. The liferaft is located on the aft rail on the port side.\nConfirm that the red/pink painter line is still attached to the boat.\nPull the two release clip strings to open the snap shackles. The liferaft will fall into the sea behind the catamaran.\nYou may need to push the dinghy out of the way a bit, but normally the dinghy will be higher on long passages.\nThe liferaft may deploy on its own as the painter line tightens, but if not, give a hard pull to trigger the deployment.\nDo not untie/cut the tether between the liferaft and the catamaran unless the cat sinks because of fire and starts to drag the liferaft down.\nThe liferaft will act as a safe harbor, while the cat will still hold supplies for freshwater and food. It also makes for a much bigger target for search parties to see.',
    'life-ring',
  );
  add(
    longTripId,
    'Abandon Boat Command',
    'DO NOT JUMP OVERBOARD UNLESS TOLD TO BY THE SKIPPER! Only the Skipper will give the command to abandon ship.\nIf you preemptively jump overboard, the Skipper will need to handle two crises: the current crisis and a man overboard.',
    'life-ring',
  );
  add(
    longTripId,
    'Any Questions?',
    'Invite questions and ensure all guests understand the safety briefing before getting underway.',
    'message-circle',
  );

  await seedChecklistItemsToDrift(items);
}
