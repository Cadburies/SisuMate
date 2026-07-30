import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/data/repositories/guest_profile_repository_impl.dart';
import 'package:sisu_mate/models/models.dart';

// GuestProfile is on Drift (S1) — these run against an in-memory Drift database
// through the repository interface, so no Isar is involved.
void main() {
  late AppDatabase db;
  late GuestProfileRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = GuestProfileRepositoryImpl(db);
  });

  tearDown(() async => db.close());

  group('GuestProfileRepositoryImpl (Drift) CRUD', () {
    test('Create: addProfile persists a new profile', () async {
      await repo.addProfile(GuestProfile()
        ..name = 'Alex'
        ..allergenRestrictions = ['nuts']);

      final all = await repo.watchProfiles().first;
      expect(all, hasLength(1));
      expect(all.single.name, 'Alex');
      expect(all.single.allergenRestrictions, ['nuts']);
    });

    test('Read: watchProfiles emits profiles sorted by name', () async {
      await repo.addProfile(GuestProfile()..name = 'Zoe');
      await repo.addProfile(GuestProfile()..name = 'Amir');

      final profiles = await repo.watchProfiles().first;
      expect(profiles.map((p) => p.name), ['Amir', 'Zoe']);
    });

    test('Update: updateProfile persists field changes', () async {
      await repo.addProfile(GuestProfile()
        ..name = 'Draft'
        ..dietaryRequirements = ['vegan']);

      final saved = (await repo.watchProfiles().first).single;
      saved.name = 'Final';
      saved.dietaryRequirements = ['keto'];
      await repo.updateProfile(saved);

      final all = await repo.watchProfiles().first;
      expect(all, hasLength(1));
      expect(all.single.name, 'Final');
      expect(all.single.dietaryRequirements, ['keto']);
    });

    test('Delete: deleteProfile removes it from the database', () async {
      await repo.addProfile(GuestProfile()..name = 'To remove');

      final saved = (await repo.watchProfiles().first).single;
      await repo.deleteProfile(saved);

      expect(await repo.watchProfiles().first, isEmpty);
    });
  });
}
