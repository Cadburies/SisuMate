import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/data/repositories/community_repository_impl.dart';
import 'package:sisu_mate/domain/repositories/community_repository.dart';
import 'package:sisu_mate/models/models.dart';

import 'test_helpers/fake_supabase_remote.dart';

void main() {
  late AppDatabase db;
  late CommunityRepository repository;

  setUp(() {
    // Construct with an in-memory Drift DB and no SyncService. All methods
    // catch network failures gracefully, so no Supabase connection is needed
    // to verify the fallback contract.
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = CommunityRepositoryImpl(db);
  });

  tearDown(() async => db.close());

  group('CommunityRepository', () {
    test('publishTemplate returns the template when network is unavailable', () async {
      final template = CommunityTemplate()
        ..title = 'Volvo Penta D6 500hr Service'
        ..description = 'Comprehensive 500-hour service schedule'
        ..category = 'maintenance'
        ..subcategory = 'volvo'
        ..content = '{"title":"Volvo Penta D6 500hr Service","items":[]}'
        ..authorId = 'test-user-id';

      final result = await repository.publishTemplate(template);
      expect(result, isNotNull);
      expect(result.title, template.title);
    });

    test('browseCommunity returns empty list when network is unavailable', () async {
      final templates = await repository.browseCommunity(category: 'maintenance');
      expect(templates, isEmpty);
    });

    test(
        'browseCommunity with sortBy: mostDownloaded also falls back to '
        'empty when network is unavailable (S5)', () async {
      final templates = await repository.browseCommunity(
        sortBy: CommunitySortOrder.mostDownloaded,
      );
      expect(templates, isEmpty);
    });

    test('importTemplate returns false when network is unavailable', () async {
      final ok = await repository.importTemplate('nonexistent-id', 'boat-id');
      expect(ok, isFalse);
    });

    test('getDownloadCount returns 0 when network is unavailable', () async {
      final count = await repository.getDownloadCount('nonexistent-id');
      expect(count, 0);
    });
  });

  group('CommunityRepository — S5 ratings + versioning', () {
    test('updateTemplate returns the template when network is unavailable',
        () async {
      final template = CommunityTemplate()
        ..supabaseId = 'existing-id'
        ..title = 'Updated Title';
      final result = await repository.updateTemplate(template);
      expect(result, isNotNull);
      expect(result.title, 'Updated Title');
    });

    test('rateTemplate returns false when network is unavailable', () async {
      final ok = await repository.rateTemplate('template-id', 5);
      expect(ok, isFalse);
    });

    test('getMyRating returns null when network is unavailable', () async {
      final rating = await repository.getMyRating('template-id');
      expect(rating, isNull);
    });

    test('#321: reportTemplate returns false when network is unavailable',
        () async {
      final ok = await repository
          .reportTemplate('template-id', reason: 'Inappropriate');
      expect(ok, isFalse);
    });

    test('applyCommunityUpdate returns false when network is unavailable',
        () async {
      final group = ChecklistGroup()
        ..supabaseId = 'group-1'
        ..communityTemplateId = 'template-1';
      final ok = await repository.applyCommunityUpdate(
        localGroup: group,
        boatId: 'boat-1',
      );
      expect(ok, isFalse);
    });

    test('getCachedTemplate returns null for a template never cached locally',
        () async {
      final cached = await repository.getCachedTemplate('nonexistent-id');
      expect(cached, isNull);
    });

    test(
        'getCachedTemplate reads back a locally-cached template (local-only, '
        'no network needed)', () async {
      await db.into(db.communityTemplates).insert(
            CommunityTemplatesCompanion.insert(
              supabaseId: const Value('cached-id'),
              title: const Value('Cached Template'),
              description: const Value('A description'),
              subcategory: const Value('Yanmar'),
              version: const Value(3),
            ),
          );
      final cached = await repository.getCachedTemplate('cached-id');
      expect(cached, isNotNull);
      expect(cached!.title, 'Cached Template');
      expect(cached.subcategory, 'Yanmar');
      expect(cached.version, 3);
    });

    test(
        'linkGroupToTemplate stamps communityTemplateId/Version on the local '
        'group (local-only, no network needed)', () async {
      await db.into(db.checklistGroups).insert(
            ChecklistGroupsCompanion.insert(
              supabaseId: const Value('group-1'),
              title: const Value('My List'),
            ),
          );
      await repository.linkGroupToTemplate(
        groupSupabaseId: 'group-1',
        templateId: 'template-1',
        version: 2,
      );
      final row = await (db.select(db.checklistGroups)
            ..where((t) => t.supabaseId.equals('group-1')))
          .getSingle();
      expect(row.communityTemplateId, 'template-1');
      expect(row.communityTemplateVersion, 2);
    });
  });

  // TEST2 — success paths with injectable FakeSupabaseRemote.
  group('CommunityRepository — network succeeds (TEST2)', () {
    late FakeSupabaseRemote remote;
    late CommunityRepositoryImpl liveRepo;

    setUp(() {
      remote = FakeSupabaseRemote(userId: 'auth-uid-1');
      liveRepo = CommunityRepositoryImpl(db, null, remote);
    });

    test('publishTemplate inserts remotely, stamps author, caches in Drift',
        () async {
      final template = CommunityTemplate()
        ..title = 'Volvo Penta D6 500hr Service'
        ..name = 'volvo_penta_d6_500hr_service'
        ..description = 'Comprehensive 500-hour service schedule'
        ..category = 'maintenance'
        ..subcategory = 'volvo'
        ..content = '{"title":"Volvo Penta D6 500hr Service","items":[]}'
        ..authorId = 'local-settings-id';

      final result = await liveRepo.publishTemplate(template);

      expect(result.supabaseId, isNotEmpty);
      expect(result.title, 'Volvo Penta D6 500hr Service');
      expect(result.authorId, 'auth-uid-1',
          reason: 'RLS requires author_id = auth uid, not local settings id');
      expect(result.isApproved, isTrue);
      expect(result.isSynced, isTrue);
      expect(remote.templates.containsKey(result.supabaseId), isTrue);

      final cached = await liveRepo.getCachedTemplate(result.supabaseId);
      expect(cached, isNotNull);
      expect(cached!.title, result.title);
      expect(cached.authorId, 'auth-uid-1');
    });

    test('rateTemplate returns true and records rating when signed in',
        () async {
      final ok = await liveRepo.rateTemplate('tmpl-abc', 4);
      expect(ok, isTrue);
      expect(remote.ratings['tmpl-abc|auth-uid-1'], 4);

      final mine = await liveRepo.getMyRating('tmpl-abc');
      expect(mine, 4);
    });

    test('rateTemplate returns false when signed out', () async {
      remote.userId = null;
      final ok = await liveRepo.rateTemplate('tmpl-abc', 5);
      expect(ok, isFalse);
      expect(remote.ratings, isEmpty);
    });

    test('#321: reportTemplate records a report with reason and note when '
        'signed in', () async {
      final ok = await liveRepo.reportTemplate(
        'tmpl-abc',
        reason: 'Incorrect or unsafe content',
        note: 'Missing a critical safety step',
      );
      expect(ok, isTrue);
      expect(remote.reports, hasLength(1));
      expect(remote.reports.single.templateId, 'tmpl-abc');
      expect(remote.reports.single.userId, 'auth-uid-1');
      expect(remote.reports.single.reason, 'Incorrect or unsafe content');
      expect(remote.reports.single.note, 'Missing a critical safety step');
    });

    test('#321: reportTemplate works without a note (optional)', () async {
      final ok = await liveRepo.reportTemplate('tmpl-abc', reason: 'Other');
      expect(ok, isTrue);
      expect(remote.reports.single.note, isNull);
    });

    test('#321: reportTemplate returns false when signed out', () async {
      remote.userId = null;
      final ok = await liveRepo.reportTemplate('tmpl-abc', reason: 'Other');
      expect(ok, isFalse);
      expect(remote.reports, isEmpty);
    });

    test('#321: reportTemplate allows more than one report per user '
        '(unlike rating, not a one-per-user upsert)', () async {
      await liveRepo.reportTemplate('tmpl-abc', reason: 'Duplicate of another template');
      await liveRepo.reportTemplate('tmpl-abc', reason: 'Other', note: 'follow-up');
      expect(remote.reports, hasLength(2));
    });

    test('browseCommunity returns remote templates when available', () async {
      await remote.communityInsert({
        'id': 't1',
        'title': 'Engine checks',
        'name': 'engine_checks',
        'description': 'd',
        'category': 'maintenance',
        'subcategory': 'yanmar',
        'author_id': 'u1',
        'content': '{}',
        'is_approved': true,
        'last_modified': '2026-07-01T00:00:00.000Z',
        'version': 1,
      });

      final list = await liveRepo.browseCommunity(category: 'maintenance');
      expect(list, hasLength(1));
      expect(list.single.title, 'Engine checks');
      expect(list.single.supabaseId, 't1');
    });

    test('updateTemplate bumps version and writes remote + local cache',
        () async {
      await remote.communityInsert({
        'id': 't-upd',
        'title': 'Old title',
        'name': 'old',
        'description': 'd',
        'category': 'checklist',
        'subcategory': '',
        'author_id': 'auth-uid-1',
        'content': '{}',
        'is_approved': true,
        'last_modified': '2026-07-01T00:00:00.000Z',
        'version': 2,
      });
      await db.into(db.communityTemplates).insert(
            CommunityTemplatesCompanion.insert(
              supabaseId: const Value('t-upd'),
              title: const Value('Old title'),
              version: const Value(2),
            ),
          );

      final updated = CommunityTemplate()
        ..supabaseId = 't-upd'
        ..title = 'New title'
        ..name = 'new'
        ..description = 'd'
        ..category = 'checklist'
        ..content = '{"title":"New title"}'
        ..authorId = 'local-id';

      final result = await liveRepo.updateTemplate(updated);
      expect(result.version, 3);
      expect(result.title, 'New title');
      expect(result.authorId, 'auth-uid-1');
      expect(remote.templates['t-upd']?['version'], 3);

      final cached = await liveRepo.getCachedTemplate('t-upd');
      expect(cached?.title, 'New title');
      expect(cached?.version, 3);
    });
  });
}
