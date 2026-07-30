import '../models/constants.dart';
import '../models/database_helper.dart';
import '../models/check.dart';
import '../models/group.dart';

Future<void> loadWatchChecks(DatabaseHelper dbHelper) async {
  await dbHelper.addGroup(Group(
    groupId: watchChecksId,
    name: 'Watch Boat Checks',
    isDeleted: false,
    dateChecked: DateTime.parse('1800-01-01'),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));

  await dbHelper.addCheck(Check(
    name: 'Important Disclaimer (a.k.a. the "Don\'t Blame Me" Notice)',
    description:
        'This extensive list is based on the Leopard 45 2018 Catamaran model, lovingly showcased on the SailingSisu YouTube channel. (www.YouTube.com/c/SailingSisu under the "Boat Life and Boat Checks" playlist)\n  However, it\'s crucial to remember that every boat is unique, like a snowflake (but less... flaky).\n  Before setting sail, make sure to customize this list to fit your specific vessel, engine(s), needs, and circumstances. Don\'t forget to check your country\'s legal requirements, or you might find yourself in hot water (not the fun, tropical kind). Remember, as the Skipper/Captain, the safety of your vessel and crew/pax is always in your hands. So, be sure to take responsibility and keep everyone safe and sound. And, just to cover our bases, the developer of this application can\'t be held liable for any damage, loss, or injury resulting from the use of this product. So, please use it wisely and at your own risk.\n  Pro Version Users: Feel free to delete this message once you\'ve read it, and we\'ll consider it a virtual "thumbs up" that you\'re aware of the terms!',
    groupId: watchChecksId,
    assetName: 'lib/assets/Disclaimer.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Wind Speed',
    description:
        'Change in wind speed (As a rule of thumb a 6mb drop in 3 hours indicates a force 6 and 8mb drop in 3hrs a force 8)',
    groupId: watchChecksId,
    assetName: 'lib/assets/lists/WatchChecks/WindSpeed.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Wind Direction',
    description:
        'Change in wind direction which will affect the course steered and the sail plan or sail trimming.',
    groupId: watchChecksId,
    assetName: 'lib/assets/lists/WatchChecks/WindDirection.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Visibility',
    description:
        'Visibility decreasing/increasing. Constantly where possible, verify distance you can see an approaching vessel with distance reported by instruments',
    groupId: watchChecksId,
    assetName: 'lib/assets/lists/WatchChecks/Visibility.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Barometric Pressure',
    description:
        'Barometric change (especially if it is a change greater than 7mb in 3 hours)',
    groupId: watchChecksId,
    assetName: 'lib/assets/lists/WatchChecks/BarometricPressure.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Sea State',
    description:
        'Worsening Sea State may indicate something is coming. Also check whether to reef if conditions get worse, even before the wind speed indicates reefing time.',
    groupId: watchChecksId,
    assetName: 'lib/assets/lists/WatchChecks/SeaState.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Weather Broadcast',
    description:
        'Listen for "Imminent" weather warning in broadcast when available on VHF or SSB. Also, download the latest weather and weather routing and compare it with current conditions. Change course accordingly.',
    groupId: watchChecksId,
    assetName: 'lib/assets/lists/OneWeek/Weather.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Traffic Ships',
    description:
        'Monitor for other boats and try to determine if they saw you if on collision course and you are stand-on vessel. Do not assume they saw you and do not assume they think you are the stand-on vessel.',
    groupId: watchChecksId,
    assetName: 'lib/assets/lists/WatchChecks/TrafficShips.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Traffic Small Boats and fishing nets',
    description:
        'Watch out for unlit small fishing boats or fishing nets close to shore, look for changes in patterns from marked to unmarked fishing nets',
    groupId: watchChecksId,
    assetName: 'lib/assets/lists/WatchChecks/TrafficSmallBoats.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
}
