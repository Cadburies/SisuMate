import '../models/constants.dart';
import '../models/database_helper.dart';
import '../models/check.dart';
import '../models/group.dart';

Future<void> loadEngine1000HoursService(DatabaseHelper dbHelper) async {
  await dbHelper.addGroup(Group(
    groupId: engine1000HoursServiceId,
    name: '1000 Hour Engine Service (Pg. 105)',
    isDeleted: false,
    dateChecked: DateTime.parse('1800-01-01'),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));

  await dbHelper.addCheck(Check(
    name: 'Important Disclaimer (a.k.a. the "Don\'t Blame Me" Notice)',
    description:
        "This comprehensive checklist is based on the Leopard 45 2018 Catamaran model, as featured on the SailingSisu YouTube channel ((www.YouTube.com/c/SailingSisu), 'Boat Life and Boat Checks' playlist). However, please note that each vessel has unique characteristics and requirements. Before departing, it's essential to tailor this list to your specific boat, engine(s), needs, and circumstances. Additionally, ensure compliance with your country's legal regulations to avoid any potential issues. As the Skipper/Captain, the safety of your vessel, crew, and passengers is your responsibility. Use this application wisely and at your own risk. The developer shall not be held liable for any damage, loss, or injury resulting from the use of this product. Pro Version Users: Please acknowledge this notice by deleting this message, indicating your understanding of the terms.",
    groupId: engine1000HoursServiceId,
    assetName: 'lib/assets/Disclaimer.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: '250 Hour Checks',
    description: 'First complete all 250 hour Checks',
    groupId: engine1000HoursServiceId,
    assetName: 'lib/assets/lists/1000HourEngineService/250HourChecks.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: '500 Hour Checks',
    description: 'Second complete all 500 hour Checks',
    groupId: engine1000HoursServiceId,
    assetName: 'lib/assets/lists/1000HourEngineService/500HourChecks.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Impeller',
    description: 'Replace the Seawater Impeller',
    groupId: engine1000HoursServiceId,
    assetName: 'lib/assets/lists/1000HourEngineService/Impeller.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Seawater Passages',
    description: 'Checking and cleaning all Seawater Passages',
    groupId: engine1000HoursServiceId,
    assetName: 'lib/assets/lists/1000HourEngineService/SeawaterPassages.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Diaphragm',
    description: 'Checking Diaphragm Assembly',
    groupId: engine1000HoursServiceId,
    assetName: 'lib/assets/lists/1000HourEngineService/Diaphragm.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'V-Belt',
    description: 'Replace Alternator V-Belt Tension',
    groupId: engine1000HoursServiceId,
    assetName: 'lib/assets/lists/1000HourEngineService/Belts.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Valve Clearance',
    description: 'Inspecting and adjusting intake/exhaust valve clearance',
    groupId: engine1000HoursServiceId,
    assetName: 'lib/assets/lists/1000HourEngineService/ValveClearance.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Remote Control Throttle/Gear',
    description:
        'Check remote control throttle/gear cables are calibrated and screws are tight',
    groupId: engine1000HoursServiceId,
    assetName:
        'lib/assets/lists/1000HourEngineService/RemoteControlThrottle.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Propellor Shaft',
    description: 'Adjusting Propellor Shaft Alignment',
    groupId: engine1000HoursServiceId,
    isDeleted: true,
    assetName: 'lib/assets/lists/1000HourEngineService/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
}
