import '../models/constants.dart';
import '../models/database_helper.dart';
import '../models/check.dart';
import '../models/group.dart';

Future<void> loadLongTripSafetyBriefing(DatabaseHelper dbHelper) async {
  await dbHelper.addGroup(Group(
    groupId: longTripSafetyBriefingId,
    name: 'Long Trip Safety Briefing',
    isDeleted: false,
    dateChecked: DateTime.parse('1800-01-01'),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));

  await dbHelper.addCheck(Check(
    name: 'Important Disclaimer (a.k.a. the "Don\'t Blame Me" Notice)',
    description:
        "This comprehensive checklist is based on the Leopard 45 2018 Catamaran model, as featured on the SailingSisu YouTube channel ((www.YouTube.com/c/SailingSisu), 'Boat Life and Boat Checks' playlist). However, please note that each vessel has unique characteristics and requirements. Before departing, it's essential to tailor this list to your specific boat, engine(s), needs, and circumstances. Additionally, ensure compliance with your country's legal regulations to avoid any potential issues. As the Skipper/Captain, the safety of your vessel, crew, and passengers is your responsibility. Use this application wisely and at your own risk. The developer shall not be held liable for any damage, loss, or injury resulting from the use of this product. Pro Version Users: Please acknowledge this notice by deleting this message, indicating your understanding of the terms.",
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/Disclaimer.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Welcome onboard Sisu!',
    description:
        ' Welcome onboard Sisu we are happy to have you here!\n For those who have yet to notice, this is a boat, therefore, we all need to work together to keep everyone safe and \n for everyone to enjoy this trip.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Personal: Getting on and of the boat/dinghy',
    description:
        'The sea changes state all the time, waves get bigger or faster all the time.\n Make sure to wait for the right moment before stepping on/off.\n The right moment is when the dinghy and boat are moving to close the gap.\n Step off smartly as soon as the gap closes. DO NOT PUSH ON YOUR BACK FOOT. This will open the gap again and you might fall through into the gap.\n Use the momentum of the closing vessel to transfer your weight completely and smartly to the front foot. DO NOT JUMP.\n Ask the crew member to assist you',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Personal: Stowage of Personal Belonings',
    description:
        'Under each of your cabin beds are a drawer. There is also a hanging closet. You may use both these spaces to stow your belongings.\n The drawer can be opened by pushing the latch button in and depress. The drawer can be opened now.\n Please ensure that the drawer latch is always pushed in and latched if not in use.\n Inside the closet is the fire extinguisher.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Personal: Water Hydration',
    description: 'Please drink water often to prevent dehydration',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Personal: Sunscreen',
    description: 'Please apply sunscreen often, especially after a swim',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Personal: How to Use the Heads/Toilets',
    description:
        'This boat has freshwater handheld bidets. We do not through anything down the toilet that did not went through your own body.\n No paper, no sanitary towels, tampons, loose hair, or any other manufacturered product.\n There are three basic flush operations. Fill and Flush. Flush only. Fill only.\n We normally Fill Flash first. Then use the freshwater bidet to clean. Yes, your hands will get dirty with peanut butter,\n but as your Mom always said... Wash your hands! No you know why :-)\n You can use the paper to wipe dry and deposes of it in the bin provided. DO NOT THROW THE PAPER IN THE TOILET.\n We then flush only and wait a minute. Fill only the basin again and then flush only. Repeat the fill only and flash only one more time.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Personal: Freshwater Use',
    description:
        'We make our own freshwater through reverse osmosis where we convert seawater into freshwater. This is the purest of water.\n That said, it is a long process, which can only be done in clear seawater so, we have to use freshwater sparingly.\n For example, do not let the tap run while you brush your teeth. We can all hear the freshwater pressure pump running :-)',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Personal: Fresh Warm Water',
    description:
        'There is a freshwater washdown shower at at the ladder to wash of the saltwater after a swim.\n However, if you desire a hotwater shower, then please ask a crew member at least one hour before your intended shower.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Personal: Life Jackets',
    description:
        'This boat has 13 Life Jackets. They are stored in the forward cockpit in the starboard locker.\n They work very much the same as the airplane ones.\n Unfold and pull the Life Jacket over your head. Take each straps around to the back and then further around to the front and tie off.\n It is advised to wear the Life Jackets throughout the trip.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Personal: Harnasses',
    description:
        'This boat has 4 Harnasses. They are stored in the aft cockpit below the window in the locker.\n They have a built-in inflation device and MOB AIS device, which will be activated when the harnass hits the water.\n Pull the Harnass over your head. Take the strap from the back and string it between your legs and clip in at the front.\n Lastly ensure the clip in front is fastened and the adjustable straps is tighten.\n When it is absolutely required to go on the roof with the permission of the Skipper, use the tether strap and clips to clip the harnass in and\n then attach to the yellow line (jack stay) on the roof.\n It is mandatory to wear the harnasses whenever one leaves the enclosure or at night watch.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Personal: Jack Stays',
    description:
        'Sometimes it is necessary to go onto the roof to the mast or to undo a fouled reef line at the end of the boom.\n Always call or wake the Skipper if this happens. If the Skipper or crew member is hurt or incapacitated,\n don the harnass and tether strap with clips. The coach roof Jack Stay starts at the helm station.\n Always ensure that the boom is secured and that it will not knock you off the roof. Eventhough you are strapped in, is it still a bad experience!\n While holding onto the rails, clip into the Jack Stay. Carefully with both hands on railings, step up to the roof.\n Be prepared that the boat will be bucking like a wild horse. Crawl towards the mast while holding onto the Jack Stay or Running Rigging.\n If the mast is your destination, grab the rails on the mast and stand up. DO what needs to be done and return the same way.\n If you are required to go to the back, then follow the Jack Stay towards the back. It is one continuous line. Use the main sheets and boom to pull you up.\n Do what needs to be done and return the same way.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Personal: First Aid Kit',
    description:
        'We have a Grabber Bag, which is only to be used in the event of evacuation and has big word "GRABBER" on it.\n We also have First Aid Kit and is mark with a red cross. \n Both are in the aft cockpit below the window seat. Make sure to retrieve the correct one!\n Please, if you do have a headache, ask the Skipper or crew member first, we have a Medicine Kit with headache pills too.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Personal: Gybing or Tacking',
    description:
        'Catamarans are more forgiving while tacking and gybing, but the Skipper will make the call "Gybing!" or "Tacking!".\n During the manoeuvre, the boat will react very different and may even become like a bucking horse.\n Ensure that you are holding onto something during this period. It normally lasts for 20-30 seconds.\n For this reason, no one is allowed on the coach roof while sailing. The boom is very dangerous during a Gybe or Tack.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Flooding: Prevention: Sources of Flooding',
    description:
        'The main reasons for water ingress are open taps, burst pipes, and damage to the hull. In short, freshwater leaks or saltwater from leaks/damage\n The catamaran will not sink immediately.  Let\'s discuss these sources and how to prevent flooding.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Flooding: Prevention: Close All Taps',
    description: 'Close any tap you open.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Flooding: Prevention: Wash Down Pump',
    description:
        'Close the shut off valve and depresurises the pipe by pushing the hand lever.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Flooding: Prevention: Bidet Valve',
    description: 'Close the bidet shut off valve after use',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Flooding: Action: Detection',
    description:
        'Notify the Skipper or crew member immediately if you see an unusual amount of water in the boat or if you hear water sloshing around\n Freshwater leaks will have an accompaning sound and light of  the freshwater pressure pump coming on every few seconds.\n You can also determine the source of the water by smelling and then tasting the water. If it stinks, well, you know not to taste.\n If it does not smell like sewerage water, then if it taste like salt water, we know to look for possible leaks in the hull or\n saltwater system such as toilet flush. If it is sweet/freshwater, then we know that our drinking water is getting less.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Fire: Prevention: Sources for Fire',
    description:
        'Fire is the worst that can happen on a catamaran and needs special attention and swift actions.\n There are three sources for fire. LPG Gas, electrical circuit overloading, diesel.\n Let\'s discuss these sources and how to prevent fires.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Fire: Prevention: No Open Fires',
    description:
        'No open fires are allowed on the boat other than controlled LPG Gas burners. Only use the gas heating from the braai, stove and burners.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Fire: Prevention: No Smoking',
    description:
        'No matches are allowed. Smoking is NOT allowed inside the boat. Smoking are only on the downwind suger scoop.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Fire: Prevention: LPG Gas',
    description:
        'This boat uses LPG gas for cooking, baking, and braai. If you at anytime smell LPG Gas, notify the Skipper or crew member immediately.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Fire: Prevention: Cooking or Boiling Water',
    description:
        'The gas burners or to braai LPG all work through an electrical and mechanical safety mechanism.\n There are also LPG Gas Detectors in the hull, but even then, let us be vigilant and careful when using the LPG Gas.\n The LPG Electrical switch is in the electrical panel. Switch it on and open the LPG bottle in the gas locker.\n It will take up to a minute to check the sensors before it is ready to switch the gas solenoid.\n The solenoid switch is at the stove and when it stops flickering, it is ready. Press the "ON" button.\n Turn the appropriate hob gas knob and press down. THE GAS WILL START TO FLOW IMMEDIATELY.\n While pressing the knob down, press the lightning bolt button to create sparks, which will ignite the LPG.\n If the LPG does not ignite within the first 5 sparks, notify the Skipper or crew member, because it may indicate a leak.\n After you used the hob, remember to close the knob, switch off the solenoid, switch off the LPG power, and close the LPG gas bottle.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Fire: Prevention: Charging devices',
    description:
        'There are plenty USB charging ports on the boat. Use only the existing charging ports. Do not overload charging wires.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Fire: Prevention: Any 110/220V Electrical Device',
    description:
        'The boat is configured for 220V 60Hz. There are plenty European 220V plugs.\n Ask Skipper or crew member if you can use any of your electrical devices and/or private adaptors',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Fire: Action: Detection',
    description:
        'Notify the Skipper or crew member immediately if you smell smoke or see a flame, whether electrical or wood, or plastic.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Fire: Action: Fire Extinguishers',
    description:
        'There are six fire extinguishers on this boat, they are all marked with a red label and white fire extinguisher.\n There is one in each room/cabin, one next to mast in the kitchen, one in forward cockpit, one in aft cockpit.\n Please familiarise yourself with the locations of each one.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Fire: Action: Use of Fire Extinguishers',
    description:
        'In the event of a fire, shout out load for the Skipper or crew member and\n retrieve the closest fire extinguishers as soon as possible and if it is safe to do so.\n If the SKipper and crew member is non-reactive, pull the safety pin, aim for the base of the fire, and squeeze the lever.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Fire: Action: Fire in Engine Room or Gas Locker',
    description:
        'In the event of a fire, shout out load for the Skipper or crew member and\n retrieve the closest fire extinguishers as soon as possible and if it is safe to do so.\n If the SKipper and crew member is non-reactive, pull the safety pin, insert nozzle into special port, and squeeze the lever.\n DO NOT OPEN THE ENGINE ROOM OR GAS LOCKER DOOR!!',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Fire: Action: Fire on Stove Burners',
    description:
        'There is a fire blanket located in the cabinet at the base of the mast in the saloon. \n Open and unfold the blanket. Firts drape it around your hands and let it hang in front of you and your hands.\n Approach the stove and through the banket over the fire. Be careful not to get burned, but at the same time, to cover the whole fire.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Disaster: Start the Engine',
    description:
        'It may be that a person needs to start the engine during night shift when our boat speed drops below 3kts.\n Very similar to a car, but with buttons. First press the "ON" button. A beep should sound to confirm power is at the engine.\n Press the "CYCLE" button and the engine will swing over and start.\n Verify that water is coming out of the exhaust before reving the engine. If no water is coming out, stop the engine and inspect the strainers.\n DO NOT RUN THE ENGINE WITHOUT WATER COMING OUT OF THE EXHAUST!!\n Confirm no person is in the water around the hulls. Push the throttle slowly forward to engage the propellor.\n Do the reverse to shut down the engine. Place throttle in the middle/neutral position. Press "CYCLE" button until engine stops,\n push "ON/OFF" button until engine instruments switch of.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Disaster: Man Over Board (MOB)',
    description:
        'If you are the one falling over board, shout/scream as load as possible in the direction of a crew member or the boat.\n If you are the one who see a person falling over boar, shout as load as possible "Man Over Board!!!" and point your finger at the MOB.\n Keep your eyes always on the person and keep your finger pointed at the person. That will be your soul task. \n It is super easy to loose track of a MOB so, this is the most important job. Keep pointing your finger at him and keep drawing the attention of fellow crew.\n The Skipper or crew member will take it from there.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Disaster: MOB Equipment',
    description:
        'This boat has several MOB equipment.\n The harnasses are equiped with a inflation device and a MOB AIS device, which will active when coming in contact with water.\n This will show up on the chart plotters and raise alarms on all VHF radios in the vicinity.\n In the case the person did not wear a harnass, we have floatation devices on the aft starboard rail. There is a flashing light too.\n Only throw the devices if the MOB would for sure see and reach the devices. Remember that the MOB cannot see far and you may have wasted a chance to safe the MOB.\n The Skipper and crew members are trained to do MOB procedures and one of the first things are to get back to the MOB and throw the devices when only under sail.\n Normally, the Skipper will immediately depower the sails, switch on the engines and turn the boat towards to pointed finger.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Disaster: Rigging Cutters',
    description:
        'In the event off catastrophe and a person is caught in entangled rigging, you can find a few ways to cut the rigging.\n All the tools can be found in the port forward cabin under the bed. We have cordless power grinder for when the rigging is not submerged\n and one can cut safely without fear that the sparks will hurt someone or start a fire. \n The second option is big ball cutters, which can be used under water and close to a person.\n There is also a long crow bar, which can be used to lever heavy fallen objects or bend open a space or door or hatch.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Disaster: Engine Spare Parts',
    description:
        'In the event of Skipper and crew is incapicitated and engine needs spare parts such as impeller,\n all servicable engine spares can be found in the back of each engine room.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Disaster: Command for Evacuation',
    description:
        'DO NOT JUMP OVER BOARD UNLESS TOLD BY THE SKIPPER! Only the Skipper will give the command to abandon ship.\n If you preemptively jump over board then the SKipper needs to handle two crises. The current crisis and a man over board.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Disaster: Use of VHF',
    description:
        'The VHF Radio works different from a phone in the manner that it has a Push To Talk (PTT) button.\n Further, one can only talk or listen, not both at the same time. Therefore, a language was developed to assist in this awkward "one-way-conversation"\n One selected the channel, normally 16, press the PTT and while holding in, say your sentence and end your sentence with "over". This way the other people\n yes, everyone in range will be on channel 16 and be able to hear you, nothing is private on VHF. The other person will know you are finished with your sentence when you say "OVER"\n The very first sentence must start with the name of the boat you call repeated three times, followed by your boat\'s name repeated three times, followed by "OVER".\n Release the PTT and wait for the answer. You may have to repeat before the other person will answer.\n Remember to switch to another open channel such as 10, to have a conversation, because 16 is reserved for distress calls and to initiate a call',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Disaster: Mayday Call',
    description:
        'One person will be assigned to perform this task, but all need to know for in case something happens to the Skipper and crew.\n The Mayday procedure is written on a card glued to the VHF radio in the electrical panel on your right as you enter the saloon.\n You can read it word for word except for the parts in the {} brackets.\n The first one is the GPS Coordinates, which you can read from the VHF Radio Display.\n The second one is problem/cause of evacuation such as "serious engine fire".\n The third is the number of people on board so, count us now and remember.\n The last one is our intended action, which could be to abandon the boat and get into the attached liferaft.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Disaster: EBIRB',
    description:
        'An Emergency Position Indicating Radio Beacon or EPIRB is used to alert search and rescue services in the event of an emergency.\n It does this by transmitting a coded message via the free to use, multinational Cospas Sarsat network.\n We have an yellow EBIRB on board and it is located on the rightside wall as one go down in the starboard hull.\n Only the Skipper has the permission to activate the EBIRB.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Disaster: Evacuation Tasks',
    description:
        'Should the Skipper give the command to abandon ship, then everyone will be assign a task.\n Stronger person to handle liferaft.\n One person to collect GRABBER Bag in the aft cockpit below the window locker.\n One person to collect FLARE Container in the aft cockpit below the window locker.\n One/two person(s) to collect all life jackets in forward cockpit.\n One person to collect all floatable objects such as cusshions/pillows and throw it into liferaft or next to liferaft. We will sort it out later.\n One person to collect the spare handheld VHF radio at the nav station.\n One person to collect the spare Iridium Go, Phones, and charging devices located in the safe.\n One person to collect freshwater [containers] and throw it over board next to lifraft.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Disaster: Liferaft Launch',
    description:
        'It is pretty easy to launch the Liferaft on this boat. The Liferaft is located on the aft rail on the port side.\n Confirm that the red/pink painter line is still attached to the boat.\n Pull the two release clips strings to open the snap shackles.\n The liferaft will fall into the sea behind the catamaran. \n You may need to push the dinghy out of the way a bit, but normally the dinghy will be higher on long passages.\n The liferaft may deploy on its own as the painter line tightens, but if not, give a hard pull to trigger the deployment.\n Do not untie/cut the tether between the liferaft and the catamaran unless the cat sinks because of fire and starts to drag the liferaft down.\n The liferaft will act as safeharbor, while the cat will still hold supplies for freshwater and food. \n It also makes for a much bigger target for search parties to see.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Disaster: Thermal Protection',
    description:
        'Inside the liferaft and inside the GRABBER bag are space blankets to protect against heat or cold tempratures.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Disaster: Flares',
    description:
        'The flare container is located in the aft cockpit inside the locker under the window seat.\n Inside the container are all sorts of attraction devices, which each one has a specific purpose.\n For example, smoke cannot be seen at night, but is very useful during the day for helicopters to understand wind speed and direction.\n Deploy smoke always downwind of the vessel. Only deploy the flares or smoke when you are sure of a chance to be seen from potential rescue parties.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Disaster: Drogue',
    description:
        'The Skipper and crew will deploy a drogue in the event of the boat going too fast in a storm and we need to slow it down.\n We use two 100m lines in a bridal fashion, with a fender attached to the bridal triangle end.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Disaster: Spare Iridium Go and Phones',
    description:
        'In the event of an electronic disaster such as a lightning strike, do we carry a spare Iridium Go, Phones, and charging devices in the safe.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Disaster: Emergency/Backup VHF',
    description:
        'We do have a handheld VHF radio on board and it is located at the nav station in the saloon.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Disaster: Radar Reflectors',
    description:
        'We carry emergency metal radar reflectors, which is located in forward cockpit port locker.',
    groupId: longTripSafetyBriefingId,
    assetName: 'lib/assets/lists/LongTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
}
