import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/data/repositories/anchor_spot_repository_impl.dart';
import 'package:sisu_mate/data/repositories/anchor_watch_repository_impl.dart';
import 'package:sisu_mate/models/models.dart';

/// #328 — catalog is independent of the live watch.
void main() {
  late AppDatabase db;
  late AnchorSpotRepositoryImpl spots;
  late AnchorWatchRepositoryImpl watches;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    spots = AnchorSpotRepositoryImpl(db);
    watches = AnchorWatchRepositoryImpl(db);
  });

  tearDown(() async => db.close());

  AnchorWatch watch() => AnchorWatch()
    ..anchorLat = 26.5412
    ..anchorLon = -77.0634
    ..scopeRatio = 5
    ..radiusMeters = 40
    ..dangerZoneEnabled = true
    ..dangerZoneCenterDeg = 45
    ..dangerZoneWidthDeg = 80
    ..dangerZoneInnerRadiusMeters = 40
    ..dangerZoneOuterRadiusMeters = 70;

  test('save snapshot from a watch keeps name, scope, danger zone, metadata',
      () async {
    final dropped = await watches.dropAnchor(watch());
    final saved = await spots.save(
      AnchorSpot.fromWatch(dropped, name: 'Marsh Harbour', comments: 'Reef NE')
        ..bottom = AnchorBottom.sand
        ..holdingQuality = AnchorHolding.good
        ..depthMeters = 4.5
        ..windProtection = ['N', 'NE']
        ..swellExposure = AnchorSwell.sheltered
        ..dinghyLanding = AnchorDinghy.beach
        ..amenities = 'Village',
    );

    expect(saved.id, greaterThan(0));
    final all = await spots.getAll();
    expect(all, hasLength(1));
    final row = all.single;
    expect(row.name, 'Marsh Harbour');
    expect(row.comments, 'Reef NE');
    expect(row.lat, 26.5412);
    expect(row.lon, -77.0634);
    expect(row.scopeRatio, 5);
    expect(row.radiusMeters, 40);
    expect(row.dangerZoneEnabled, isTrue);
    expect(row.dangerZoneCenterDeg, 45);
    expect(row.dangerZoneWidthDeg, 80);
    expect(row.bottom, AnchorBottom.sand);
    expect(row.holdingQuality, AnchorHolding.good);
    expect(row.depthMeters, 4.5);
    expect(row.windProtection, ['N', 'NE']);
    expect(row.swellExposure, AnchorSwell.sheltered);
    expect(row.dinghyLanding, AnchorDinghy.beach);
    expect(row.amenities, 'Village');
  });

  test('weighing and dropping again does not delete saved spots', () async {
    final dropped = await watches.dropAnchor(watch());
    await spots.save(AnchorSpot.fromWatch(dropped, name: 'Marsh Harbour'));
    await watches.weighAnchor(dropped.id);
    await watches.dropAnchor(watch()..anchorLat = 26.6);

    final all = await spots.getAll();
    expect(all, hasLength(1));
    expect(all.single.name, 'Marsh Harbour');
    expect(all.single.lat, 26.5412);
    expect(await watches.watchActive().first, isNotNull);
  });
}
