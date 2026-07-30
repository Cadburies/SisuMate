import '../models/constants.dart';
import '../models/database_helper.dart';
import '../models/check.dart';
import '../models/group.dart';

Future<void> loadOneWeekChecks(DatabaseHelper dbHelper) async {
  await dbHelper.addGroup(Group(
    groupId: oneWeekChecksId,
    name: 'One Week Before Boat Checks',
    isDeleted: false,
    dateChecked: DateTime.parse('1800-01-01'),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));

  await dbHelper.addCheck(Check(
    name: 'Important Disclaimer (a.k.a. the "Don\'t Blame Me" Notice)',
    description:
        "This comprehensive checklist is based on the Leopard 45 2018 Catamaran model, as featured on the SailingSisu YouTube channel ((www.YouTube.com/c/SailingSisu), 'Boat Life and Boat Checks' playlist). However, please note that each vessel has unique characteristics and requirements. Before departing, it's essential to tailor this list to your specific boat, engine(s), needs, and circumstances. Additionally, ensure compliance with your country's legal regulations to avoid any potential issues. As the Skipper/Captain, the safety of your vessel, crew, and passengers is your responsibility. Use this application wisely and at your own risk. The developer shall not be held liable for any damage, loss, or injury resulting from the use of this product. Pro Version Users: Please acknowledge this notice by deleting this message, indicating your understanding of the terms.",
    groupId: oneWeekChecksId,
    assetName: 'lib/assets/Disclaimer.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Harnasses',
    description: 'Check for wear and tear on harnasses, tethers',
    groupId: oneWeekChecksId,
    assetName: 'lib/assets/lists/OneWeek/Harnasses.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Cartridges',
    description: 'Check PFD Cartridges & Bobbin',
    groupId: oneWeekChecksId,
    assetName: 'lib/assets/lists/OneWeek/Cartridges.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'PFD Equipment',
    description: 'Check the PFD equipment for wear and tear',
    groupId: oneWeekChecksId,
    assetName: 'lib/assets/lists/AnualChecks/PFDEquipment.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Predictwind',
    description:
        'Confirm PredictWind Connectivity, subscriptions, and up to date software',
    groupId: oneWeekChecksId,
    assetName: 'lib/assets/lists/OneWeek/Predictwind.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Iridium',
    description:
        'Confirm Iridium mail Connectivity and updated software as well as firmware',
    groupId: oneWeekChecksId,
    assetName: 'lib/assets/lists/OneWeek/Iridium.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Weather Maps',
    description:
        'Download latest weather/pilot map (rose maps) for the area of passage',
    groupId: oneWeekChecksId,
    assetName: 'lib/assets/lists/OneWeek/WeatherMaps.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'SAS Planet',
    description: 'Download latest SAS satellite images for destination',
    groupId: oneWeekChecksId,
    assetName: 'lib/assets/lists/OneWeek/SASPlanet.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Ant-Siphon',
    description: 'Check Anti-Siphon loops',
    groupId: oneWeekChecksId,
    assetName: 'lib/assets/lists/OneWeek/AntSiphon.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Saildrive / Shaft Seals',
    description:
        'Check Shaft Seal. For Sail Drive, check SD for watery/grey oil on SD dipstick after propellors turned for a few minutes',
    groupId: oneWeekChecksId,
    assetName: 'lib/assets/lists/OneWeek/SaildriveSeals.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Shaft Coupling',
    description: 'Check Shaft Coupling',
    groupId: oneWeekChecksId,
    assetName: 'lib/assets/lists/OneWeek/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
    isDeleted: true,
  ));
  await dbHelper.addCheck(Check(
    name: 'Log Sheets',
    description: 'Add Log Sheets to Clipboard',
    groupId: oneWeekChecksId,
    assetName: 'lib/assets/lists/OneWeek/LogSheets.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Raw Water Strainers',
    description:
        'Check Raw Water Strainers – Genset, Yanmar, Water Maker, pump protectors, aircon',
    groupId: oneWeekChecksId,
    assetName: 'lib/assets/lists/OneWeek/WaterStrainers.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Laundry',
    description: 'Do Laundry such as clothes, bed sheets, pillow cases, towels',
    groupId: oneWeekChecksId,
    assetName: 'lib/assets/lists/OneWeek/Laundry.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Provision Checklist',
    description: 'Provision Checklist and replenish non-perishable goods',
    groupId: oneWeekChecksId,
    assetName: 'lib/assets/lists/OneWeek/Provision.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Precooked Food',
    description:
        'Food prepared especially for a lively passage and those first three days',
    groupId: oneWeekChecksId,
    assetName: 'lib/assets/lists/OneWeek/Precooked.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Diesel',
    description: 'Fill diesel tanks and spare containers if required',
    groupId: oneWeekChecksId,
    assetName: 'lib/assets/lists/OneWeek/Diesel.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Petrol',
    description: 'Fill Petrol for tender main and spare tank',
    groupId: oneWeekChecksId,
    assetName: 'lib/assets/lists/OneWeek/Petrol.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'LPG Gas',
    description:
        'Fill LPG bottles. LPG Systems can take Butane or/and Propane. Butane systems can only take Butane gas, because of Butane\'s low pressure',
    groupId: oneWeekChecksId,
    assetName: 'lib/assets/lists/OneWeek/LPGGas.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Standing Rigging',
    description: 'Inspect Standing Rigging for rust, cracks, and weak spots',
    groupId: oneWeekChecksId,
    assetName: 'lib/assets/lists/OneWeek/StandingRigging.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Running Rigging',
    description:
        'Inspect Running Rigging for chafe, inspect blocks for cracks or wear, inspect clutches. Clean hardware thorougly if it was standing for a while.',
    groupId: oneWeekChecksId,
    assetName: 'lib/assets/lists/OneWeek/RunningRigging.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Water Maker',
    description:
        'Check Water Maker for good operation. Replace the filters if required.',
    groupId: oneWeekChecksId,
    assetName: 'lib/assets/lists/OneWeek/WaterMaker.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Navigation Lights',
    description:
        'Check operation of navigation lights make sure you have spare bulbs for starboard, port, stern, steaming, and deck lights. Some smaller boats uses tri-color light on the mast so, ensure that you have the correct spares.',
    groupId: oneWeekChecksId,
    assetName: 'lib/assets/lists/AnualChecks/NavigationLights.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Weather Forecast',
    description:
        'Get the latest weather forecast and compare with previous forecast. Consider delaying or changing the route if weather changes for the worst.',
    groupId: oneWeekChecksId,
    assetName: 'lib/assets/lists/OneWeek/Weather.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Proposed Routing',
    description:
        'Check Proposed Routing ensure that conditions did not change, low pressure systems, politics, health, current news on destination.',
    groupId: oneWeekChecksId,
    assetName: 'lib/assets/lists/OneWeek/ProposedRouting.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Passage Plan',
    description:
        'Start to finalize passage plan. Look at detailed charts (most zoomed in on electronic) to pick up any shallows, rocks, or danger spots along the route. Keep in mind that you may be tacking long tacks.',
    groupId: oneWeekChecksId,
    assetName: 'lib/assets/lists/AnualChecks/PassagePlanning.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Insurance',
    description:
        'Inform Insurance of intended passage and get confirmation that you are covered for area and time of year. For example, The Caribbean is not covered during huricane season.',
    groupId: oneWeekChecksId,
    assetName: 'lib/assets/lists/DocumentsChecks/BoatInsurance.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Health, Police, Immigration, Customs Clearance',
    description:
        'Familiarize yourself with all legal procedures with Health, Police, Immigration, and Customs to obtain Exit Clearance documents and get passports stamped for you and your crew. Remember, different countries handles different nationalities, differently. Also, ensure that you have completed all pre-health checks such as COVID-19 or yellow fever or other vaccines required for destination country.',
    groupId: oneWeekChecksId,
    assetName: 'lib/assets/lists/DocumentsChecks/OnlineRequirements.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
}
