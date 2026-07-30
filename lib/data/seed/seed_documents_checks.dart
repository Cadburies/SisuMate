import 'checklist_drift_seed.dart';
import '../../models/models.dart';

final documentsId = 'documentsId';

Future<void> seedDocumentsChecks(String defaultBoatSupabaseId) async {
  final group = ChecklistGroup()
    ..supabaseId = documentsId
    ..boatSupabaseId = defaultBoatSupabaseId
    ..title = 'Documents Checks'
    ..iconName = 'documents'
    ..sortOrder = 3
    ..appType = 'checklist'
    ..isBundled = true;

  await seedChecklistGroupToDrift(group);

  final items = <ChecklistItem>[];

  void add(String groupId, String title, String description, String assetName) {
    items.add(
      ChecklistItem()
        ..supabaseId =
            '${groupId}_${title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}'
        ..groupSupabaseId = groupId
        ..title = title
        ..description = description
        ..assetName = assetName
        ..isCompleted = false
        ..isHidden = false
        ..isPermanentlyDeleted = false
        ..sortOrder = items.length,
    );
  }

  // Available assets: BoatRegistration.jpg, BoatInsurance.jpg,
  // ValidityOfPassports.jpg, VisaRequirements.jpg,
  // OnlineRequirements.jpg, NoPicture.jpg

  add(documentsId, 'Boat Registration',
      'Ensure boat registration is current and documentation is on board.',
      'lib/assets/lists/DocumentsChecks/BoatRegistration.jpg');

  add(documentsId, 'Insurance Documents',
      'Verify insurance policy is active and coverage documents are accessible.',
      'lib/assets/lists/DocumentsChecks/BoatInsurance.jpg');

  add(documentsId, 'Crew Passports',
      'Check that all crew passports are valid for at least 6 months beyond travel dates.',
      'lib/assets/lists/DocumentsChecks/ValidityOfPassports.jpg');

  add(documentsId, 'Visas',
      'Confirm required visas are obtained for all destinations and crew nationalities.',
      'lib/assets/lists/DocumentsChecks/VisaRequirements.jpg');

  add(documentsId, "Captain's License",
      "Ensure captain's license or certification is current and appropriate for vessel size/location.",
      'captain-license');

  add(documentsId, 'Radio License',
      "Verify ship's radio station license and operator certificates are current.",
      'radio');

  add(documentsId, 'Cruising Permits',
      'Obtain necessary cruising permits for domestic and international waters.',
      'lib/assets/lists/DocumentsChecks/OnlineRequirements.jpg');

  add(documentsId, 'Fishing Licenses',
      'Secure fishing licenses if planning to fish in regulated waters.',
      'fishing');

  add(documentsId, 'Pet Documentation',
      'Ensure pet vaccination records and entry permits are prepared for all ports.',
      'pets');

  add(documentsId, 'Medical Prescriptions',
      'Carry sufficient prescription medications with copies of scripts for customs.',
      'medkit');

  add(documentsId, 'Customs Declarations',
      'Prepare customs declaration forms and inventory of dutiable items on board.',
      'lib/assets/lists/DocumentsChecks/OnlineRequirements.jpg');

  add(documentsId, 'Zarpe/Clearance',
      'Obtain outbound clearance (zarpe) from last port before international departure.',
      'zarpe');

  await seedChecklistItemsToDrift(items);
}
