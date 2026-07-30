import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/data/repositories/crew_member_repository_impl.dart';
import 'package:sisu_mate/models/models.dart';

import '../test_helpers/db_test_helper.dart';

// CrewMember is on Drift (S1) but still sync-participating: the repo uses an
// in-memory Drift database plus a real (no-op) SyncService whose outbox is Isar.
void main() {
  late AppDatabase db;
  late CrewMemberRepositoryImpl repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = CrewMemberRepositoryImpl(db, testSyncService());
  });

  tearDown(() async => db.close());

  group('CrewMemberRepositoryImpl (Drift) CRUD', () {
    test('Create: addCrewMember persists a new member', () async {
      await repo.addCrewMember(CrewMember()
        ..supabaseId = 'crew_1'
        ..name = 'Skipper Ada'
        ..role = 'Captain');

      final all = await repo.watchCrewMembers().first;
      expect(all, hasLength(1));
      expect(all.single.name, 'Skipper Ada');
      expect(all.single.role, 'Captain');
    });

    test('Read: watchCrewMembers emits members sorted by name', () async {
      await repo.addCrewMember(CrewMember()
        ..supabaseId = 'crew_z'
        ..name = 'Zara');
      await repo.addCrewMember(CrewMember()
        ..supabaseId = 'crew_a'
        ..name = 'Anders');

      final members = await repo.watchCrewMembers().first;
      expect(members.map((m) => m.name), ['Anders', 'Zara']);
    });

    test('Update: updateCrewMember persists field changes', () async {
      final member = CrewMember()
        ..supabaseId = 'crew_1'
        ..name = 'Draft Name';
      await repo.addCrewMember(member);

      member
        ..name = 'Final Name'
        ..phone = '+358 40 123 4567';
      await repo.updateCrewMember(member);

      final all = await repo.watchCrewMembers().first;
      expect(all, hasLength(1));
      expect(all.single.name, 'Final Name');
      expect(all.single.phone, '+358 40 123 4567');
    });

    test('Delete: deleteCrewMember removes it from the database', () async {
      final member = CrewMember()
        ..supabaseId = 'crew_1'
        ..name = 'To Be Deleted';
      await repo.addCrewMember(member);
      expect(await repo.watchCrewMembers().first, hasLength(1));

      await repo.deleteCrewMember(member);
      expect(await repo.watchCrewMembers().first, isEmpty);
    });
  });
}
