import '../models/constants.dart';
import '../models/database_helper.dart';
import '../models/check.dart';
import '../models/group.dart';

Future<void> loadOneDayChecks(DatabaseHelper dbHelper) async {
  await dbHelper.addGroup(Group(
    groupId: oneDayChecksId,
    name: 'One Day Before Boat Checks',
    isDeleted: false,
    dateChecked: DateTime.parse('1800-01-01'),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));

  await dbHelper.addCheck(Check(
    name: 'Important Disclaimer (a.k.a. the "Don\'t Blame Me" Notice)',
    description:
        "This comprehensive checklist is based on the Leopard 45 2018 Catamaran model, as featured on the SailingSisu YouTube channel ((www.YouTube.com/c/SailingSisu), 'Boat Life and Boat Checks' playlist). However, please note that each vessel has unique characteristics and requirements. Before departing, it's essential to tailor this list to your specific boat, engine(s), needs, and circumstances. Additionally, ensure compliance with your country's legal regulations to avoid any potential issues. As the Skipper/Captain, the safety of your vessel, crew, and passengers is your responsibility. Use this application wisely and at your own risk. The developer shall not be held liable for any damage, loss, or injury resulting from the use of this product. Pro Version Users: Please acknowledge this notice by deleting this message, indicating your understanding of the terms.",
    groupId: oneDayChecksId,
    assetName: 'lib/assets/Disclaimer.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Replenish Perishable',
    description:
        'Provision Checklist and Replenish Perishable Goods. Keep in mind that fresh markets may have restricted days for business',
    groupId: oneDayChecksId,
    assetName: 'lib/assets/lists/OneDay/Perishable.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Engine Check',
    description: 'Perform a Daily Engine Check',
    groupId: oneDayChecksId,
    assetName: 'lib/assets/lists/DailyEngineChecks/EngineOil.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Life Raft',
    description:
        'Check Life Raft fittings, frame, and painter line is secured and easy to reach',
    groupId: oneDayChecksId,
    assetName: 'lib/assets/lists/AnualChecks/Liferaft.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Plug Tender',
    description: 'Ensure all drain holes are plugged and ready for use',
    groupId: oneDayChecksId,
    assetName: 'lib/assets/lists/OneDay/PlugTender.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Wet Lockers',
    description: 'Plug All Drain Holes in Wet Lockers',
    groupId: oneDayChecksId,
    assetName: 'lib/assets/lists/OneDay/PlugDrainHoles.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Anchor',
    description:
        'Check Anchor ready to use. If going on longer lively passages, ensure that the anchor is secured and chain locked.',
    groupId: oneDayChecksId,
    assetName: 'lib/assets/lists/OneDay/Anchor.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Ditch Bag',
    description: 'Check Ditch Bag and Place at Top of Lazarette',
    groupId: oneDayChecksId,
    assetName: 'lib/assets/lists/OneDay/DitchBag.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Secure Tender',
    description: 'Secure Tender Tie Downs & Line at Tender Bow',
    groupId: oneDayChecksId,
    assetName: 'lib/assets/lists/OneDay/SecureTender.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Tender Outboard',
    description: 'Secure Outboard',
    groupId: oneDayChecksId,
    assetName: 'lib/assets/lists/OneDay/TenderOutboard.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Topping Lift',
    description: 'Remove Topping Lift',
    groupId: oneDayChecksId,
    assetName: 'lib/assets/lists/OneDay/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
    isDeleted: true,
  ));
  await dbHelper.addCheck(Check(
    name: 'Jack Stay Lines',
    description:
        'Set Jack Stay Lines. Ensure no other lines or equipment cross over or above the Jack Stays. If unsure, clip in and walk the entire line to see if it is clear of obstructions and that you can reach the places you need to reach.Also, ensure that the Jack Stays and tether is such that you cannot go over board and get dragged alongside the boat.',
    groupId: oneDayChecksId,
    assetName: 'lib/assets/lists/OneDay/JackStay.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Preventers',
    description:
        'Set Preventers in a easy to reach place but so that it will not get entangled in other equipment or lines. Set up barber haulers if required.',
    groupId: oneDayChecksId,
    assetName: 'lib/assets/lists/OneDay/Preventers.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Speakers',
    description: 'Plastic Bags over outside Cockpit Speakers',
    groupId: oneDayChecksId,
    assetName: 'lib/assets/lists/OneDay/Speakers.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Bilge Pumps',
    description:
        'Dry Test All Bilge Pumps by lifting the float switches. Ensure that you can hear the pump starting and high water level alarms are activated.',
    groupId: oneDayChecksId,
    assetName: 'lib/assets/lists/AnualChecks/BilgePumps.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Batteries',
    description: 'Check batteries are switched on and charged',
    groupId: oneDayChecksId,
    assetName: 'lib/assets/lists/OneDay/Batteries.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Loose Gear',
    description:
        'Stow all loose gear. Ensure that the deck and topsides are clear to navigate in tricky emergency circumstances.',
    groupId: oneDayChecksId,
    assetName: 'lib/assets/lists/OneDay/LooseGear.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Drinking Water',
    description: 'Check All drinking water levels and fill if needed',
    groupId: oneDayChecksId,
    assetName: 'lib/assets/lists/AnualChecks/FreshWaterTanks.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Weather Forecast',
    description: 'Get the weather forecast and adjust passage accordingly',
    groupId: oneDayChecksId,
    assetName: 'lib/assets/lists/OneWeek/Weather.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Passage Plans',
    description:
        'Finalize Passage and pilotage plans. Write down the VHF frequencies, telephone numbers, and/or email addresses for the ports you may visit.',
    groupId: oneDayChecksId,
    assetName: 'lib/assets/lists/AnualChecks/PassagePlanning.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Notify People',
    description:
        'Notify People of Final Passage Plan and provide tracking link and Iridium number/email',
    groupId: oneDayChecksId,
    assetName: 'lib/assets/lists/OneDay/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Health, Police, Immigration, Customs Clearance',
    description:
        'Perform all legal procedures with Health, Police, Immigration, and Customs to obtain Exit Clearance documents and get passports stamped',
    groupId: oneDayChecksId,
    assetName: 'lib/assets/lists/DocumentsChecks/OnlineRequirements.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
}
