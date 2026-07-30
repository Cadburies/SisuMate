import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/data/repositories/boat_repository_impl.dart';
import 'package:sisu_mate/models/models.dart';

import '../test_helpers/db_test_helper.dart';

// Boat on Drift (S1), sync-participating.
void main() {
  late AppDatabase db;
  late BoatRepositoryImpl repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = BoatRepositoryImpl(db, testSyncService());
  });

  tearDown(() async => db.close());

  group('BoatRepositoryImpl (Drift) CRUD', () {
    test('Create + getBoatById', () async {
      await repo.addBoat(Boat()
        ..supabaseId = 'boat_1'
        ..name = 'Sisu');

      final all = await repo.watchBoats().first;
      expect(all, hasLength(1));
      expect(all.single.name, 'Sisu');

      final byId = await repo.getBoatById('boat_1');
      expect(byId, isNotNull);
      expect(byId!.name, 'Sisu');
      expect(await repo.getBoatById('missing'), isNull);
    });

    test('getBoats returns all', () async {
      await repo.addBoat(Boat()..supabaseId = 'a');
      await repo.addBoat(Boat()..supabaseId = 'b');
      expect(await repo.getBoats(), hasLength(2));
    });

    test('Update persists field changes', () async {
      final boat = Boat()
        ..supabaseId = 'boat_1'
        ..name = 'Draft';
      await repo.addBoat(boat);

      boat.name = 'Final';
      await repo.updateBoat(boat);

      expect((await repo.getBoatById('boat_1'))!.name, 'Final');
    });

    test('Delete removes it', () async {
      final boat = Boat()..supabaseId = 'boat_1';
      await repo.addBoat(boat);
      await repo.deleteBoat(boat);
      expect(await repo.watchBoats().first, isEmpty);
    });

    // SHARE4: ownerId + shareCode round-trip through Drift (inbound-only fields).
    test('ownerId + shareCode persist locally', () async {
      await repo.upsertLocal(Boat()
        ..supabaseId = 'boat_owned'
        ..name = 'Sisu'
        ..ownerId = 'owner-uid-123'
        ..shareCode = '4F2K9X');
      final b = await repo.getBoatById('boat_owned');
      expect(b!.ownerId, 'owner-uid-123');
      expect(b.shareCode, '4F2K9X');
    });

    // Crew join uses upsertLocal so the owner's boat is never pushed back.
    test('upsertLocal inserts then updates in place', () async {
      await repo.upsertLocal(Boat()
        ..supabaseId = 'shared_boat'
        ..name = 'Sisu');
      var all = await repo.getBoats();
      expect(all, hasLength(1));
      expect(all.single.name, 'Sisu');

      await repo.upsertLocal(Boat()
        ..supabaseId = 'shared_boat'
        ..name = 'Sisu Renamed');
      all = await repo.getBoats();
      expect(all, hasLength(1), reason: 'same supabaseId updates, not dupes');
      expect(all.single.name, 'Sisu Renamed');
    });
  });
}
