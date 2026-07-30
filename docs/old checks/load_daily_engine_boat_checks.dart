import '../models/constants.dart';
import '../models/database_helper.dart';
import '../models/check.dart';
import '../models/group.dart';

Future<void> loadDailyEngineChecks(DatabaseHelper dbHelper) async {
  await dbHelper.addGroup(Group(
    groupId: dailyEngineChecksId,
    name: 'Daily Engine Boat Checks',
    isDeleted: false,
    dateChecked: DateTime.parse('1800-01-01'),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));

  await dbHelper.addCheck(Check(
    name: 'Important Disclaimer (a.k.a. the "Don\'t Blame Me" Notice)',
    description:
        "This comprehensive checklist is based on the Leopard 45 2018 Catamaran model, as featured on the SailingSisu YouTube channel ((www.YouTube.com/c/SailingSisu), 'Boat Life and Boat Checks' playlist). However, please note that each vessel has unique characteristics and requirements. Before departing, it's essential to tailor this list to your specific boat, engine(s), needs, and circumstances. Additionally, ensure compliance with your country's legal regulations to avoid any potential issues. As the Skipper/Captain, the safety of your vessel, crew, and passengers is your responsibility. Use this application wisely and at your own risk. The developer shall not be held liable for any damage, loss, or injury resulting from the use of this product. Pro Version Users: Please acknowledge this notice by deleting this message, indicating your understanding of the terms.",
    groupId: dailyEngineChecksId,
    assetName: 'lib/assets/Disclaimer.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Raw Water',
    description: 'Check raw water strainer for debris and seacocks are open',
    groupId: dailyEngineChecksId,
    assetName: 'lib/assets/lists/DailyEngineChecks/RawWater.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Secondary Water',
    description: 'Check Water Level in expansion tank and engine cap',
    groupId: dailyEngineChecksId,
    assetName: 'lib/assets/lists/DailyEngineChecks/SecondaryWater.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Engine Oil',
    description: 'Check Oil',
    groupId: dailyEngineChecksId,
    assetName: 'lib/assets/lists/DailyEngineChecks/EngineOil.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Sail Drive Oil',
    description: 'Check sail drive oil level',
    groupId: dailyEngineChecksId,
    assetName: 'lib/assets/lists/DailyEngineChecks/SailDriveOil.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Transmission Oil',
    description: 'Check transmission oil level',
    groupId: dailyEngineChecksId,
    isDeleted: true,
    assetName: 'lib/assets/lists/DailyEngineChecks/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Belts',
    description: 'Check alternator and water pump belts for tension and wear',
    groupId: dailyEngineChecksId,
    assetName: 'lib/assets/lists/DailyEngineChecks/Belts.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Leaks',
    description: 'Check bilge for oil or water leaks',
    groupId: dailyEngineChecksId,
    assetName: 'lib/assets/lists/DailyEngineChecks/Leaks.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Electrics',
    description:
        'Check all wires for oxidation or loose connectors such battery terminals, charging cables, alternators, engine management',
    groupId: dailyEngineChecksId,
    assetName: 'lib/assets/lists/DailyEngineChecks/Electrics.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Battery Electrolite',
    description: 'Check battery electrolite levels and top up if required',
    groupId: dailyEngineChecksId,
    isDeleted: true,
    assetName: 'lib/assets/lists/DailyEngineChecks/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Drain Fuel/Water Seperator',
    description: 'Drain the water from the Fuel/Water seperator',
    groupId: dailyEngineChecksId,
    assetName: 'lib/assets/lists/DailyEngineChecks/DrainSeperator.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Throttle/Gear Cables',
    description:
        'Check & tighten all throttle/gear cables and screws, replace if required',
    groupId: dailyEngineChecksId,
    assetName: 'lib/assets/lists/DailyEngineChecks/ThrottleCable.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Bilge Blowers',
    description:
        'Check that bilge/engine room blower is working and exit are clear',
    groupId: dailyEngineChecksId,
    assetName: 'lib/assets/lists/DailyEngineChecks/BilgeBlowers.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Bilge Water Trap',
    description:
        'Check that water trap around bilge pump and float switch are clean and clear of any debris',
    groupId: dailyEngineChecksId,
    assetName: 'lib/assets/lists/DailyEngineChecks/BilgeWaterTrap.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Bilge',
    description:
        'Check that bilge around engine are clean and look for signs of wear such as salt spray, mounting chucks, belt chafings',
    groupId: dailyEngineChecksId,
    assetName: 'lib/assets/lists/DailyEngineChecks/Bilge.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
}
