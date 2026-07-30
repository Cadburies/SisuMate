import '../models/constants.dart';
import '../models/database_helper.dart';
import '../models/check.dart';
import '../models/group.dart';

Future<void> loadDayTripSafetyBriefing(DatabaseHelper dbHelper) async {
  await dbHelper.addGroup(Group(
    groupId: dayTripSafetyBriefingId,
    name: 'Day Trip Safety Briefing',
    isDeleted: false,
    dateChecked: DateTime.parse('1800-01-01'),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));

  await dbHelper.addCheck(Check(
    name: 'Important Disclaimer (a.k.a. the "Don\'t Blame Me" Notice)',
    description:
        "This comprehensive checklist is based on the Leopard 45 2018 Catamaran model, as featured on the SailingSisu YouTube channel ((www.YouTube.com/c/SailingSisu), 'Boat Life and Boat Checks' playlist). However, please note that each vessel has unique characteristics and requirements. Before departing, it's essential to tailor this list to your specific boat, engine(s), needs, and circumstances. Additionally, ensure compliance with your country's legal regulations to avoid any potential issues. As the Skipper/Captain, the safety of your vessel, crew, and passengers is your responsibility. Use this application wisely and at your own risk. The developer shall not be held liable for any damage, loss, or injury resulting from the use of this product. Pro Version Users: Please acknowledge this notice by deleting this message, indicating your understanding of the terms.",
    groupId: dayTripSafetyBriefingId,
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
    groupId: dayTripSafetyBriefingId,
    assetName: 'lib/assets/lists/DayTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Personal: Getting on and of the boat/dinghy',
    description:
        'The sea state changes all the time, waves get bigger or faster all the time.\n Make sure to wait for the right moment before stepping on/off.\n The right moment is when the gap between the dinghy and boat closes enough for you to step on/off comfortably.\n Step off smartly as soon as the gap closes. DO NOT PUSH ON YOUR BACK FOOT. This will open the gap again and you might fall through the gap.\n Use the momentum of the closing vessel to transfer your weight completely and smartly to the front foot. DO NOT JUMP.\n Ask the crew member to assist you',
    groupId: dayTripSafetyBriefingId,
    assetName: 'lib/assets/lists/DayTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Personal: Stowage of Personal Belonings',
    description:
        ' The crew will show you where to store your belongings in the two port side cabins on the bed.',
    groupId: dayTripSafetyBriefingId,
    assetName: 'lib/assets/lists/DayTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Personal: Water Hydration',
    description: 'Please drink water often to prevent dehydration',
    groupId: dayTripSafetyBriefingId,
    assetName: 'lib/assets/lists/DayTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Personal: Sunscreen',
    description: 'Please apply sunscreen often, especially after a swim',
    groupId: dayTripSafetyBriefingId,
    assetName: 'lib/assets/lists/DayTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Personal: How to Use the Heads/Toilets',
    description:
        'This boat has freshwater handheld bidets. We do not flush anything down the toilet that did not go through your own body.\n No paper, no sanitary towels, tampons, loose hair, or any other manufacturered product.\n There are three basic flush operations. Fill and Flush. Flush only. Fill only.\n We normally Fill Flash first. Then use the freshwater bidet to clean. Yes, your hands will get dirty with peanut butter,\n but as your Mom always said... Wash your hands! Now you know why :-)\n You can use the paper to wipe dry and depose of it in the bin provided. DO NOT THROW THE PAPER IN THE TOILET.\n We then flush only and wait a minute. Fill only the basin again and then flush only. Repeat the fill only and flush only one more time.',
    groupId: dayTripSafetyBriefingId,
    assetName: 'lib/assets/lists/DayTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Personal: Freshwater Use',
    description:
        'We make our own freshwater through reverse osmosis, where we convert seawater into freshwater. This is the purest of water.\n That said, it is a long process, which can only be done in clear seawater so, we have to use freshwater sparingly.\n For example, turn the tap off whilst you brush your teeth, then only turn it on to rinse. We can all hear the freshwater pressure pump running :-)',
    groupId: dayTripSafetyBriefingId,
    assetName: 'lib/assets/lists/DayTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Personal: Fresh Warm Water',
    description:
        'There is a freshwater washdown shower at the ladder to wash off the saltwater after a swim.\n However, if you desire a hotwater shower, then please ask a crew member at least one hour before your intended shower so that we can turn the heater on.',
    groupId: dayTripSafetyBriefingId,
    assetName: 'lib/assets/lists/DayTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Personal: Life Jackets',
    description:
        'This boat has 13 Life Jackets. They are stored in the forward cockpit in the starboard locker.\n They work very much the same as the airplane ones.\n Unfold and pull the Life Jacket over your head. Fold the straps around your waist backwards and then forward again to tie off.\n It is advised to wear the Life Jackets throughout the trip.',
    groupId: dayTripSafetyBriefingId,
    assetName: 'lib/assets/lists/DayTripSafetyBriefing/NoPicture.jpg',
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
    groupId: dayTripSafetyBriefingId,
    assetName: 'lib/assets/lists/DayTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Personal: Gybing or Tacking',
    description:
        'Catamarans are more forgiving whilst tacking and gybing, the Skipper will call out "Gybing!" or "Tacking!" to prepare you for the manoeuvre.\n During the manoeuvre, the boat will react differently and may even become like a bucking horse.\n Ensure that you are holding onto something during this period. It normally lasts for 20-30 seconds.\n For this reason, no one is allowed on the coach roof whilst sailing. The boom is very dangerous during a Gybe or Tack.',
    groupId: dayTripSafetyBriefingId,
    assetName: 'lib/assets/lists/DayTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Flooding: Prevention: Sources of Flooding',
    description:
        'The main reasons for water ingress are open taps, burst pipes, and damage to the hull. In short, freshwater or saltwater from leaks/damage\n The catamaran will not sink immediately.  Let\'s discuss these sources and how to prevent flooding.',
    groupId: dayTripSafetyBriefingId,
    assetName: 'lib/assets/lists/DayTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Flooding: Prevention: Close All Taps',
    description: 'Close any tap you open.',
    groupId: dayTripSafetyBriefingId,
    assetName: 'lib/assets/lists/DayTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Flooding: Prevention: Wash Down Pump',
    description:
        'Close the shut off valve and depressurize the pipe by pushing the hand lever.',
    groupId: dayTripSafetyBriefingId,
    assetName: 'lib/assets/lists/DayTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Flooding: Prevention: Bidet Valve',
    description: 'Close the bidet shut off valve after use',
    groupId: dayTripSafetyBriefingId,
    assetName: 'lib/assets/lists/DayTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Flooding: Action: Detection',
    description:
        'Notify the Skipper or crew member immediately if you see an unusual amount of water in the boat or if you hear water sloshing around',
    groupId: dayTripSafetyBriefingId,
    assetName: 'lib/assets/lists/DayTripSafetyBriefing/NoPicture.jpg',
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
    groupId: dayTripSafetyBriefingId,
    assetName: 'lib/assets/lists/DayTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Fire: Prevention: No Open Fires',
    description:
        'No open fires are allowed on the boat other than controlled LPG Gas burners. Only use the gas heating from the BBQ, stove and burners.',
    groupId: dayTripSafetyBriefingId,
    assetName: 'lib/assets/lists/DayTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Fire: Prevention: No Smoking',
    description:
        'No matches are allowed. Smoking is NOT allowed inside the boat. Smoking only permitted on the downwind suger scoop.',
    groupId: dayTripSafetyBriefingId,
    assetName: 'lib/assets/lists/DayTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Fire: Prevention: LPG Gas',
    description:
        'This boat uses LPG gas for cooking, baking, and BBQ. If you at anytime smell LPG Gas, notify the Skipper or crew member immediately.',
    groupId: dayTripSafetyBriefingId,
    assetName: 'lib/assets/lists/DayTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Fire: Prevention: Cooking or BBQ',
    description:
        'You need the permission of the Skipper to use the gas burners or to BBQ.\n Even making coffee/tea, first ask the Skipper or crew member for permission and to show you how it works.',
    groupId: dayTripSafetyBriefingId,
    assetName: 'lib/assets/lists/DayTripSafetyBriefing/NoPicture.jpg',
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
    groupId: dayTripSafetyBriefingId,
    assetName: 'lib/assets/lists/DayTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Fire: Prevention: Any 110/220V Electrical Device',
    description:
        'The boat is configured for 220V 60Hz. There are plenty European 220V plugs.\n Ask the Skipper or crew member if you can use any of your electrical devices and/or private adapters',
    groupId: dayTripSafetyBriefingId,
    assetName: 'lib/assets/lists/DayTripSafetyBriefing/NoPicture.jpg',
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
    groupId: dayTripSafetyBriefingId,
    assetName: 'lib/assets/lists/DayTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Fire: Action: Fire Extinguishers',
    description:
        'There are six fire extinguishers on this boat, they are all marked with a red and white fire extinguisher label.\n There is one in each room/cabin, one next to mast in the kitchen, one in forward cockpit, one in aft cockpit.\n Please familiarise yourself with the locations of each one.',
    groupId: dayTripSafetyBriefingId,
    assetName: 'lib/assets/lists/DayTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Fire: Action: Use of Fire Extinguishers',
    description:
        'In the event of a fire, shout out load for the Skipper or crew member and\n retrieve the fire extinguisher closest to you as soon as possible and if it is safe to do so.\n If the Skipper and crew member is non-reactive, pull the safety pin, aim for the base of the fire, and squeeze the lever.',
    groupId: dayTripSafetyBriefingId,
    assetName: 'lib/assets/lists/DayTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Disaster: Command for Evacuation',
    description:
        'DO NOT JUMP OVERBOARD UNLESS TOLD SO BY THE SKIPPER! Only the Skipper will give the command to abandon ship.\n If you preemptively jump overboard the Skipper will need to handle two crises. The current crisis and a man overboard.',
    groupId: dayTripSafetyBriefingId,
    assetName: 'lib/assets/lists/DayTripSafetyBriefing/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
}
