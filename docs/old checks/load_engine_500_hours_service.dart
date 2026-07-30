import '../models/constants.dart';
import '../models/database_helper.dart';
import '../models/check.dart';
import '../models/group.dart';

Future<void> loadEngine500HoursService(DatabaseHelper dbHelper) async {
  await dbHelper.addGroup(Group(
    groupId: engine500HoursServiceId,
    name: '500 Hour Engine Service (Pg. 104)',
    isDeleted: false,
    dateChecked: DateTime.parse('1800-01-01'),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin,
  ));

  await dbHelper.addCheck(Check(
    name: 'Important Disclaimer (a.k.a. the "Don\'t Blame Me" Notice)',
    description:
        "This comprehensive checklist is based on the Leopard 45 2018 Catamaran model, as featured on the SailingSisu YouTube channel ((www.YouTube.com/c/SailingSisu), 'Boat Life and Boat Checks' playlist). However, please note that each vessel has unique characteristics and requirements. Before departing, it's essential to tailor this list to your specific boat, engine(s), needs, and circumstances. Additionally, ensure compliance with your country's legal regulations to avoid any potential issues. As the Skipper/Captain, the safety of your vessel, crew, and passengers is your responsibility. Use this application wisely and at your own risk. The developer shall not be held liable for any damage, loss, or injury resulting from the use of this product. Pro Version Users: Please acknowledge this notice by deleting this message, indicating your understanding of the terms.",
    groupId: engine500HoursServiceId,
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
    groupId: engine500HoursServiceId,
    assetName: 'lib/assets/lists/500HourEngineService/250HourChecks.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Exhaust/Water Mixing Elbow',
    description: 'Replace the Exhaust/Water Mixing Elbow',
    groupId: engine500HoursServiceId,
    assetName: 'lib/assets/lists/500HourEngineService/MixingElbow.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Rubber Hoses',
    description: 'Replace the rubber hoses',
    groupId: engine500HoursServiceId,
    assetName: 'lib/assets/lists/500HourEngineService/RubberHoses.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'Propeller Shaft',
    description:
        'Lubricate the propeller shaft splines and tighten the propellor nuts',
    groupId: engine500HoursServiceId,
    assetName: 'lib/assets/lists/500HourEngineService/NoPicture.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
    isDeleted: true,
  ));
  await dbHelper.addCheck(Check(
    name: 'SD Pipe Fitting',
    description: 'Check that the pipe fitting are properly tight',
    groupId: engine500HoursServiceId,
    assetName: 'lib/assets/lists/500HourEngineService/SDPipeFitting.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'SD Grounding',
    description:
        'Check that the grounding circuit (continuity) are not loose or damaged connections',
    groupId: engine500HoursServiceId,
    assetName: 'lib/assets/lists/500HourEngineService/SDGrounding.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
  await dbHelper.addCheck(Check(
    name: 'SD Antifoul',
    description: 'Apply antifouling without copper material',
    groupId: engine500HoursServiceId,
    assetName: 'lib/assets/lists/500HourEngineService/SDAntifoul.jpg',
    dateCompleted: DateTime.parse('1800-01-01'),
    dateDue: DateTime.parse('1800-01-01'),
    dateEntered: DateTime.now(),
    dateEdited: DateTime.now(),
    userEdited: '', //ToDo: Get userEdited from signin
  ));
}
