import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/boat_enrollment_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late BoatEnrollmentService svc;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    svc = BoatEnrollmentService(db);

    // Seed the default boat + one bundled group scoped to it.
    await db.into(db.boats).insert(BoatsCompanion.insert(
        supabaseId: const Value(BoatEnrollmentService.defaultBoatId),
        name: const Value('My Boat')));
    await db.into(db.checklistGroups).insert(ChecklistGroupsCompanion.insert(
        supabaseId: const Value('dailyEngineId'),
        boatSupabaseId: const Value(BoatEnrollmentService.defaultBoatId),
        title: const Value('Daily Engine Checks')));
  });

  tearDown(() async => db.close());

  test('enroll renames default boat to a GUID + re-stamps content', () async {
    final guid = await svc.enroll(name: 'Sisu', ownerId: 'owner-1');

    expect(guid, isNotEmpty);
    expect(guid, isNot(BoatEnrollmentService.defaultBoatId));

    final boats = await db.select(db.boats).get();
    expect(boats, hasLength(1), reason: 'default boat adopted, not duplicated');
    expect(boats.single.supabaseId, guid);
    expect(boats.single.name, 'Sisu');
    expect(boats.single.ownerId, 'owner-1');

    final group = await db.select(db.checklistGroups).getSingle();
    expect(group.boatSupabaseId, guid, reason: 'content re-stamped to the boat');

    expect(await svc.currentGuid(), guid, reason: 'GUID persisted');
  });

  test('enroll is idempotent — same GUID, no duplicate boat', () async {
    final first = await svc.enroll(name: 'Sisu');
    final second = await svc.enroll(name: 'Sisu Renamed');

    expect(second, first, reason: 'reuses the persisted GUID');
    final boats = await db.select(db.boats).get();
    expect(boats, hasLength(1));
    expect(boats.single.name, 'Sisu Renamed');
  });
}
