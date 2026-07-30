import '../models/constants.dart';
import '../models/database_helper.dart';
import '../models/check.dart';
import '../models/group.dart';

Future<void> loadEngine250HoursService(DatabaseHelper dbHelper) async {
  await dbHelper.addGroup(Group(
    groupId: engine250HoursServiceId,
    name: '250 Hour Engine Service (Pg. 97)',
    isDeleted: false,
    dateChecked: DateTime.parse('1800-01-01'),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));

  await dbHelper.addCheck(Check(
    name: 'Important Disclaimer (a.k.a. the "Don\'t Blame Me" Notice)',
    description:
        "This comprehensive checklist is based on the Leopard 45 2018 Catamaran model, as featured on the SailingSisu YouTube channel ((www.YouTube.com/c/SailingSisu), 'Boat Life and Boat Checks' playlist). However, please note that each vessel has unique characteristics and requirements. Before departing, it's essential to tailor this list to your specific boat, engine(s), needs, and circumstances. Additionally, ensure compliance with your country's legal regulations to avoid any potential issues. As the Skipper/Captain, the safety of your vessel, crew, and passengers is your responsibility. Use this application wisely and at your own risk. The developer shall not be held liable for any damage, loss, or injury resulting from the use of this product. Pro Version Users: Please acknowledge this notice by deleting this message, indicating your understanding of the terms.",
    groupId: engine250HoursServiceId,
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
    groupId: engine250HoursServiceId,
    assetName: 'lib/assets/lists/250HourEngineService/DrainFuelTank.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Fuel Filter',
    description: 'Replacing Fuel Filter element (Part #129A00-55800)',
    groupId: engine250HoursServiceId,
    assetName: 'lib/assets/lists/250HourEngineService/FuelFilter.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Fuel Filter/Seperator',
    description:
        'Replacing fuel filter/ water seperator element (Part #121857-55710)',
    groupId: engine250HoursServiceId,
    assetName: 'lib/assets/lists/250HourEngineService/FuelSeperator.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Engine Oil',
    description: 'Changing the Engine Oil (SAE Viscosity 15W-40)',
    groupId: engine250HoursServiceId,
    assetName: 'lib/assets/lists/250HourEngineService/EngineOil.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Engine Oil Filter',
    description: 'Replacing Engine Oil Filter (Part #129150-35170)',
    groupId: engine250HoursServiceId,
    assetName: 'lib/assets/lists/250HourEngineService/EngineOilFilter.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Gear Oil',
    description: 'Changing the Marine Gear Oil (SAE Viscosity #20 or #30)',
    groupId: engine250HoursServiceId,
    isDeleted: true,
    assetName: 'lib/assets/lists/250HourEngineService/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Gear Oil Filter',
    description: 'Replacing Marine Gear Oil Filter Element (part # ???)',
    groupId: engine250HoursServiceId,
    isDeleted: true,
    assetName: 'lib/assets/lists/250HourEngineService/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Sail Drive Oil',
    description: 'Changing the Sail Drive Oil (SAE Viscosity 15W-40)',
    groupId: engine250HoursServiceId,
    assetName: 'lib/assets/lists/250HourEngineService/SailDriveOil.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Impeller',
    description: 'Checking or replacing the Seawater Impeller',
    groupId: engine250HoursServiceId,
    assetName: 'lib/assets/lists/250HourEngineService/Impeller.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Coolant',
    description: 'Change the Coolant',
    groupId: engine250HoursServiceId,
    assetName: 'lib/assets/lists/250HourEngineService/SecondaryWater.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Intake Silencer',
    description: 'Cleaning the Intake Silencer (Air Cleaner) element',
    groupId: engine250HoursServiceId,
    assetName: 'lib/assets/lists/250HourEngineService/IntakeSilencer.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Mixing Elbow',
    description: 'Cleaning the Exhaust/Water Mixing Elbow',
    groupId: engine250HoursServiceId,
    assetName: 'lib/assets/lists/250HourEngineService/MixingElbow.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Strainers',
    description: 'Check and clean water strainers',
    groupId: engine250HoursServiceId,
    assetName: 'lib/assets/lists/250HourEngineService/Strainers.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Exhaust Fittings',
    description: 'Check all exhaust fittings & pipes for leaks',
    groupId: engine250HoursServiceId,
    assetName: 'lib/assets/lists/250HourEngineService/ExhaustFittings.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Exhaust Hose',
    description: 'Check & tighten all exhaust hose clamps, replace if required',
    groupId: engine250HoursServiceId,
    assetName: 'lib/assets/lists/250HourEngineService/ExhaustFittings.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Turbocharger',
    description: 'Wash the Turbocharger blower',
    groupId: engine250HoursServiceId,
    isDeleted: true,
    assetName: 'lib/assets/lists/250HourEngineService/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'V-Belt',
    description: 'Check and Adjust Alternator V-Belt Tension',
    groupId: engine250HoursServiceId,
    assetName: 'lib/assets/lists/250HourEngineService/Belts.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Wire Connections',
    description: 'Check all wire connectors for chafe, wear and tear',
    groupId: engine250HoursServiceId,
    assetName: 'lib/assets/lists/250HourEngineService/Electrics.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Major Nuts and Bolts',
    description: 'Tighten all Major Nuts and Bolts',
    groupId: engine250HoursServiceId,
    assetName: 'lib/assets/lists/250HourEngineService/MajorNutsAndBolts.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
}
