import '../models/constants.dart';
import '../models/database_helper.dart';
import '../models/check.dart';
import '../models/group.dart';

Future<void> loadEngine50HoursService(DatabaseHelper dbHelper) async {
  await dbHelper.addGroup(Group(
    groupId: engine50HoursServiceId,
    name: 'First 50 Hour Engine Service (Pg. 89)',
    isDeleted: false,
    dateChecked: DateTime.parse('1800-01-01'),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));

  await dbHelper.addCheck(Check(
    name: 'Important Disclaimer (a.k.a. the "Don\'t Blame Me" Notice)',
    description:
        "This comprehensive checklist is based on the Leopard 45 2018 Catamaran model, as featured on the SailingSisu YouTube channel ((www.YouTube.com/c/SailingSisu), 'Boat Life and Boat Checks' playlist). However, please note that each vessel has unique characteristics and requirements. Before departing, it's essential to tailor this list to your specific boat, engine(s), needs, and circumstances. Additionally, ensure compliance with your country's legal regulations to avoid any potential issues. As the Skipper/Captain, the safety of your vessel, crew, and passengers is your responsibility. Use this application wisely and at your own risk. The developer shall not be held liable for any damage, loss, or injury resulting from the use of this product. Pro Version Users: Please acknowledge this notice by deleting this message, indicating your understanding of the terms.",
    groupId: engine50HoursServiceId,
    assetName: 'lib/assets/Disclaimer.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Drain Fuel Tank',
    description:
        'Draining the Fuel Tank at the water trap drain and inspect for debris or water. If found, drain the tank completely and fill again through a debris/water filter funnel. \nAlso drain and check water trap at fuel filter for water.',
    groupId: engine50HoursServiceId,
    assetName: 'lib/assets/lists/50HourEngineService/DrainFuelTank.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Engine Oil',
    description: 'Changing the Engine Oil (SAE Viscosity 15W-40)',
    groupId: engine50HoursServiceId,
    assetName: 'lib/assets/lists/50HourEngineService/EngineOil.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Engine Oil Filter',
    description: 'Replacing Engine Oil Filter (Part #129150-35170)',
    groupId: engine50HoursServiceId,
    assetName: 'lib/assets/lists/50HourEngineService/EngineOilFilter.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Gear Oil',
    description: 'Changing the Marine Gear Oil (SAE Viscosity #20 or #30)',
    groupId: engine50HoursServiceId,
    isDeleted: true,
    assetName: 'lib/assets/lists/50HourEngineService/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Gear Oil Filter',
    description: 'Replacing Marine Gear Oil Filter Element (part # ???)',
    groupId: engine50HoursServiceId,
    isDeleted: true,
    assetName: 'lib/assets/lists/50HourEngineService/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Sail Drive Oil',
    description: 'Changing the Sail Drive Oil (SAE Viscosity 15W-40)',
    groupId: engine50HoursServiceId,
    assetName: 'lib/assets/lists/50HourEngineService/SailDriveOil.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'V-Belt',
    description: 'Check and Adjust V-Belt Tension',
    groupId: engine50HoursServiceId,
    assetName: 'lib/assets/lists/50HourEngineService/Belts.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Valve Clearance',
    description: 'Inspecting and adjusting intake/exhaust valve clearance',
    groupId: engine50HoursServiceId,
    assetName: 'lib/assets/lists/50HourEngineService/ValveClearance.jpg',
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
    groupId: engine50HoursServiceId,
    assetName: 'lib/assets/lists/50HourEngineService/RemoteControlThrottle.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Propellor Shaft',
    description: 'Adjusting Propellor Shaft Alignment',
    groupId: engine50HoursServiceId,
    isDeleted: true,
    assetName: 'lib/assets/lists/50HourEngineService/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
}
