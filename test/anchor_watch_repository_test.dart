import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/data/repositories/anchor_watch_repository_impl.dart';
import 'package:sisu_mate/models/models.dart';

/// #256 — AnchorWatchRepositoryImpl: drop/edit/weigh against a real
/// in-memory Drift DB (schemaVersion 12's `AnchorWatches` table).
void main() {
  late AppDatabase db;
  late AnchorWatchRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = AnchorWatchRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('watchActive is null when nothing has been dropped', () async {
    final active = await repo.watchActive().first;
    expect(active, isNull);
  });

  test('dropAnchor inserts and becomes the active watch', () async {
    final watch = AnchorWatch()
      ..anchorLat = 12.005442
      ..anchorLon = -61.731507
      ..scopeRatio = 5.0
      ..radiusMeters = 30.0;

    final dropped = await repo.dropAnchor(watch);

    expect(dropped.id, isNonZero);
    final active = await repo.watchActive().first;
    expect(active, isNotNull);
    expect(active!.anchorLat, 12.005442);
    expect(active.anchorLon, -61.731507);
    expect(active.isActive, isTrue);
  });

  test('dropping a second anchor deactivates the first (only one active at a time)',
      () async {
    final first = await repo.dropAnchor(AnchorWatch()
      ..anchorLat = 1
      ..anchorLon = 1);
    final second = await repo.dropAnchor(AnchorWatch()
      ..anchorLat = 2
      ..anchorLon = 2);

    final active = await repo.watchActive().first;
    expect(active!.id, second.id);
    expect(active.anchorLat, 2);

    // The first row still exists (history), just inactive.
    final allRows = await db.select(db.anchorWatches).get();
    final firstRow = allRows.firstWhere((r) => r.id == first.id);
    expect(firstRow.isActive, isFalse);
  });

  test('updateWatch moves the anchor position ("Edit")', () async {
    final dropped = await repo.dropAnchor(AnchorWatch()
      ..anchorLat = 10
      ..anchorLon = 10);

    await repo.updateWatch(dropped
      ..anchorLat = 11
      ..anchorLon = 12);

    final active = await repo.watchActive().first;
    expect(active!.anchorLat, 11);
    expect(active.anchorLon, 12);
  });

  test('updateWatch changes scope/radius/danger-zone settings', () async {
    final dropped = await repo.dropAnchor(AnchorWatch()
      ..anchorLat = 10
      ..anchorLon = 10);

    await repo.updateWatch(dropped
      ..scopeRatio = 7.0
      ..radiusMeters = 80
      ..dangerZoneEnabled = true
      ..dangerZoneCenterDeg = 200
      ..dangerZoneWidthDeg = 45
      ..dangerZoneRadiusMeters = 120);

    final active = await repo.watchActive().first;
    expect(active!.scopeRatio, 7.0);
    expect(active.radiusMeters, 80);
    expect(active.dangerZoneEnabled, isTrue);
    expect(active.dangerZoneCenterDeg, 200);
    expect(active.dangerZoneWidthDeg, 45);
    expect(active.dangerZoneRadiusMeters, 120);
  });

  test('weighAnchor stops watching without deleting history', () async {
    final dropped = await repo.dropAnchor(AnchorWatch()
      ..anchorLat = 10
      ..anchorLon = 10);

    await repo.weighAnchor(dropped.id);

    final active = await repo.watchActive().first;
    expect(active, isNull);
    final allRows = await db.select(db.anchorWatches).get();
    expect(allRows, hasLength(1));
    expect(allRows.single.isActive, isFalse);
  });
}
