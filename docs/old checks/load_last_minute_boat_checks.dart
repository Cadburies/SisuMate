import '../models/constants.dart';
import '../models/database_helper.dart';
import '../models/check.dart';
import '../models/group.dart';

Future<void> loadLastMinuteChecks(DatabaseHelper dbHelper) async {
  await dbHelper.addGroup(Group(
    groupId: lastMinuteChecksId,
    name: 'Last Minute Boat Checks',
    isDeleted: false,
    dateChecked: DateTime.parse('1800-01-01'),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));

  await dbHelper.addCheck(Check(
    name: 'Important Disclaimer (a.k.a. the "Don\'t Blame Me" Notice)',
    description:
        "This comprehensive checklist is based on the Leopard 45 2018 Catamaran model, as featured on the SailingSisu YouTube channel ((www.YouTube.com/c/SailingSisu), 'Boat Life and Boat Checks' playlist). However, please note that each vessel has unique characteristics and requirements. Before departing, it's essential to tailor this list to your specific boat, engine(s), needs, and circumstances. Additionally, ensure compliance with your country's legal regulations to avoid any potential issues. As the Skipper/Captain, the safety of your vessel, crew, and passengers is your responsibility. Use this application wisely and at your own risk. The developer shall not be held liable for any damage, loss, or injury resulting from the use of this product. Pro Version Users: Please acknowledge this notice by deleting this message, indicating your understanding of the terms.",
    groupId: lastMinuteChecksId,
    assetName: 'lib/assets/Disclaimer.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Weather',
    description:
        'Get the latest weather forecast and adjust the passage and dress code accordingly',
    groupId: lastMinuteChecksId,
    assetName: 'lib/assets/lists/LastMinute/Weather.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Chart Plotter',
    description: 'Enter Final Passage Plan into Chart Plotter',
    groupId: lastMinuteChecksId,
    assetName: 'lib/assets/lists/LastMinute/ChartPlotter.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Rubbish',
    description:
        'Take all rubbish ashore. This is the last time to ditch plastic and other illegal to dump items.',
    groupId: lastMinuteChecksId,
    assetName: 'lib/assets/lists/LastMinute/Rubbish.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Shore Power',
    description:
        'Ensure that shore power is switched off at distrinution board, plugged out of the shore power and boat, and stowed away. Also remove other shore fittings such as water hose or attenae connections.',
    groupId: lastMinuteChecksId,
    assetName: 'lib/assets/lists/LastMinute/ShorePower.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Engine Check',
    description: 'Perform a Daily Engine Check',
    groupId: lastMinuteChecksId,
    assetName: 'lib/assets/lists/DailyEngineChecks/EngineOil.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Hatches',
    description: 'Close all hatches',
    groupId: lastMinuteChecksId,
    assetName: 'lib/assets/lists/LastMinute/Hatches.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Lazarette',
    description: 'Secure all Lazarettes',
    groupId: lastMinuteChecksId,
    assetName: 'lib/assets/lists/LastMinute/Lazarette.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Dress Code',
    description: 'Crew suitably dressed for the trip and weather conditions',
    groupId: lastMinuteChecksId,
    assetName: 'lib/assets/lists/LastMinute/DressCode.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Saloon',
    description:
        'Stow loose things in Saloon. For cats not very appropriate, but for monohulls...take a picture of the saloon and turn it 90 degrees both ways. You will hopefully spot the items that will go flying.',
    groupId: lastMinuteChecksId,
    assetName: 'lib/assets/lists/LastMinute/Saloon.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Drawers',
    description: 'Lock all drawers',
    groupId: lastMinuteChecksId,
    assetName: 'lib/assets/lists/LastMinute/Drawers.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Main Sail',
    description:
        'Ensure Main Sail are ready to hoist, main halyard is in place',
    groupId: lastMinuteChecksId,
    assetName: 'lib/assets/lists/LastMinute/MainSail.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Sail Cover',
    description: 'Unzip/Remove/Stow Sail Cover',
    groupId: lastMinuteChecksId,
    assetName: 'lib/assets/lists/LastMinute/SailCover.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Radar Reflector',
    description: 'Change/Remove Radar Reflector/Day Shape to Sailing/Motoring',
    groupId: lastMinuteChecksId,
    assetName: 'lib/assets/lists/AnualChecks/RadarReflector.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Start Engines',
    description: 'Start Engines and ensure water exiting the exhaust',
    groupId: lastMinuteChecksId,
    assetName: 'lib/assets/lists/LastMinute/StartEngines.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Permission to Leave',
    description: 'Call Marina for Permission to exit Marina',
    groupId: lastMinuteChecksId,
    assetName: 'lib/assets/lists/LastMinute/Permission.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Fenders',
    description: 'Remember to Secure/Stow Fenders. Safe Sailing!',
    groupId: lastMinuteChecksId,
    assetName: 'lib/assets/lists/AnualChecks/MooringFenders.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
}
