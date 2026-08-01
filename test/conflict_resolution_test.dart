import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/conflict_resolution_service.dart';
import 'package:sisu_mate/services/sync_service.dart';
import 'package:drift/drift.dart';

void main() {
  group('ConflictResolutionService.evaluate', () {
    const svc = ConflictResolutionService();

    test('missing local → applyRemote', () {
      expect(
        svc.evaluate(
          localExists: false,
          localDirty: false,
          localLastModified: null,
          remoteLastModified: DateTime(2026, 1, 2),
        ),
        InboundAction.applyRemote,
      );
    });

    test('clean local, remote newer → applyRemote', () {
      expect(
        svc.evaluate(
          localExists: true,
          localDirty: false,
          localLastModified: DateTime(2026, 1, 1),
          remoteLastModified: DateTime(2026, 1, 2),
        ),
        InboundAction.applyRemote,
      );
    });

    test('clean local, remote older → skip', () {
      expect(
        svc.evaluate(
          localExists: true,
          localDirty: false,
          localLastModified: DateTime(2026, 1, 2),
          remoteLastModified: DateTime(2026, 1, 1),
        ),
        InboundAction.skip,
      );
    });

    test('dirty local, remote newer → conflict', () {
      expect(
        svc.evaluate(
          localExists: true,
          localDirty: true,
          localLastModified: DateTime(2026, 1, 1),
          remoteLastModified: DateTime(2026, 1, 2),
        ),
        InboundAction.conflict,
      );
    });

    test('dirty local, remote older → skip (local will push)', () {
      expect(
        svc.evaluate(
          localExists: true,
          localDirty: true,
          localLastModified: DateTime(2026, 1, 2),
          remoteLastModified: DateTime(2026, 1, 1),
        ),
        InboundAction.skip,
      );
    });
  });

  group('ConflictResolutionService.tryFieldMerge (S6)', () {
    const svc = ConflictResolutionService();

    test('fills empty local notes from remote without hard conflict', () {
      final merge = svc.tryFieldMerge(
        {
          'name': 'Anchor',
          'notes': '',
          'lastModified': '2026-01-01T00:00:00.000Z',
        },
        {
          'name': 'Anchor',
          'notes': '10mm chain',
          'lastModified': '2026-01-02T00:00:00.000Z',
        },
      );
      expect(merge, isA<FieldMergeResult>());
      expect(merge!.merged['notes'], '10mm chain');
      expect(merge.filledFromRemote, contains('notes'));
    });

    test('returns null when both sides have different non-empty names', () {
      final merge = svc.tryFieldMerge(
        {
          'name': 'Mine',
          'lastModified': '2026-01-01T00:00:00.000Z',
        },
        {
          'name': 'Theirs',
          'lastModified': '2026-01-02T00:00:00.000Z',
        },
      );
      expect(merge == null, isTrue);
    });

    test('keeps local non-empty when remote empty', () {
      final merge = svc.tryFieldMerge(
        {
          'description': 'Oil change',
          'notes': 'Done at 1200h',
          'lastModified': '2026-01-02T00:00:00.000Z',
        },
        {
          'description': 'Oil change',
          'notes': '',
          'lastModified': '2026-01-03T00:00:00.000Z',
        },
      );
      expect(merge, isA<FieldMergeResult>());
      expect(merge!.merged['notes'], 'Done at 1200h');
      expect(merge.keptLocal, contains('notes'));
    });
  });

  group('ConflictResolutionService.buildConflictDiff (BAI5)', () {
    const svc = ConflictResolutionService();

    test('humanizeFieldName splits camelCase', () {
      expect(
        ConflictResolutionService.humanizeFieldName('lastPurchasePlace'),
        'Last Purchase Place',
      );
      expect(
        ConflictResolutionService.humanizeFieldName('notes'),
        'Notes',
      );
    });

    test('suggests merge when only empty-vs-filled fields differ', () {
      final report = svc.buildConflictDiff(
        {
          'name': 'Anchor',
          'notes': '',
          'lastModified': '2026-01-01T00:00:00.000Z',
        },
        {
          'name': 'Anchor',
          'notes': '10mm chain',
          'lastModified': '2026-01-02T00:00:00.000Z',
        },
      );
      expect(report.canAutoMerge, isTrue);
      expect(report.overall, OverallConflictSuggestion.mergeFields);
      expect(report.hardConflictCount, 0);
      final notes = report.fields.firstWhere((f) => f.key == 'notes');
      expect(notes.kind, FieldDiffKind.onlyRemote);
      expect(notes.suggestion, FieldSideSuggestion.mergeable);
      expect(notes.remoteDisplay, '10mm chain');
    });

    test('hard name clash prefers cloud when remote is newer', () {
      final report = svc.buildConflictDiff(
        {
          'name': 'Mine',
          'lastModified': '2026-01-01T00:00:00.000Z',
        },
        {
          'name': 'Theirs',
          'lastModified': '2026-01-03T00:00:00.000Z',
        },
      );
      expect(report.canAutoMerge, isFalse);
      expect(report.overall, OverallConflictSuggestion.keepCloud);
      expect(report.hardConflictCount, 1);
      final name = report.fields.firstWhere((f) => f.key == 'name');
      expect(name.kind, FieldDiffKind.conflict);
      expect(name.suggestion, FieldSideSuggestion.preferTheirs);
      expect(report.overallReason, contains('Keep cloud'));
    });

    test('hard name clash prefers mine when local is newer', () {
      final report = svc.buildConflictDiff(
        {
          'name': 'Mine',
          'lastModified': '2026-01-04T00:00:00.000Z',
        },
        {
          'name': 'Theirs',
          'lastModified': '2026-01-01T00:00:00.000Z',
        },
      );
      expect(report.overall, OverallConflictSuggestion.keepMine);
      expect(report.overallReason, contains('Keep mine'));
    });

    test('differing list skips equal fields', () {
      final report = svc.buildConflictDiff(
        {
          'name': 'Same',
          'notes': 'A',
          'lastModified': '2026-01-01T00:00:00.000Z',
        },
        {
          'name': 'Same',
          'notes': 'B',
          'lastModified': '2026-01-02T00:00:00.000Z',
        },
      );
      expect(report.differing.map((f) => f.key), ['notes']);
      expect(report.fields.where((f) => f.key == 'name').single.kind,
          FieldDiffKind.same);
    });
  });

  group('SyncService inbound + conflict resolve (in-memory Drift)', () {
    late AppDatabase db;
    late ProviderContainer container;
    late SyncService sync;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      sync = container.read(syncServiceProvider);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    Future<void> insertLocalBoat({
      required String id,
      required String name,
      required DateTime lm,
      required bool isSynced,
    }) async {
      await db.into(db.boats).insert(BoatsCompanion.insert(
            supabaseId: Value(id),
            name: Value(name),
            isSynced: Value(isSynced),
            lastModified: Value(lm),
          ));
    }

    test('new remote boat is inserted when missing locally', () async {
      await sync.processIncomingChanges('boats', [
        {
          'supabaseId': 'boat-1',
          'name': 'Sisu',
          'lastModified': '2026-01-02T00:00:00.000',
          'isSynced': true,
        },
      ]);

      final rows = await db.select(db.boats).get();
      expect(rows, hasLength(1));
      expect(rows.first.name, 'Sisu');
      expect(rows.first.isSynced, isTrue);
    });

    test('clean local overwritten by newer remote (LWW)', () async {
      await insertLocalBoat(
        id: 'boat-1',
        name: 'Old',
        lm: DateTime(2026, 1, 1),
        isSynced: true,
      );

      await sync.processIncomingChanges('boats', [
        {
          'supabaseId': 'boat-1',
          'name': 'New from cloud',
          'lastModified': '2026-01-03T00:00:00.000',
        },
      ]);

      final row = (await db.select(db.boats).get()).single;
      expect(row.name, 'New from cloud');
      final conflicts = await (db.select(db.conflictLogs)
            ..where((t) => t.resolution.equals('pending')))
          .get();
      expect(conflicts, isEmpty);
    });

    test('dirty local + newer remote → conflict log, local preserved',
        () async {
      await insertLocalBoat(
        id: 'boat-1',
        name: 'My offline edit',
        lm: DateTime(2026, 1, 1),
        isSynced: false,
      );

      await sync.processIncomingChanges('boats', [
        {
          'supabaseId': 'boat-1',
          'name': 'Other device edit',
          'lastModified': '2026-01-05T00:00:00.000',
        },
      ]);

      final boat = (await db.select(db.boats).get()).single;
      expect(boat.name, 'My offline edit');

      final conflicts = await (db.select(db.conflictLogs)
            ..where((t) => t.resolution.equals('pending')))
          .get();
      expect(conflicts, hasLength(1));
      expect(conflicts.first.targetTable, 'boats');
      expect(conflicts.first.localSupabaseId, 'boat-1');
    });

    test('resolve keep_remote applies cloud version', () async {
      await insertLocalBoat(
        id: 'boat-1',
        name: 'Mine',
        lm: DateTime(2026, 1, 1),
        isSynced: false,
      );
      await sync.processIncomingChanges('boats', [
        {
          'supabaseId': 'boat-1',
          'name': 'Cloud',
          'lastModified': '2026-01-05T00:00:00.000',
        },
      ]);
      final conflict =
          (await (db.select(db.conflictLogs)
                ..where((t) => t.resolution.equals('pending')))
              .get())
              .single;

      await sync.resolveConflict(conflictId: conflict.id, keepLocal: false);

      final boat = (await db.select(db.boats).get()).single;
      expect(boat.name, 'Cloud');
      expect(boat.isSynced, isTrue);
      final pending = await (db.select(db.conflictLogs)
            ..where((t) => t.resolution.equals('pending')))
          .get();
      expect(pending, isEmpty);
    });

    test('resolve keep_local preserves local name', () async {
      await insertLocalBoat(
        id: 'boat-1',
        name: 'Mine',
        lm: DateTime(2026, 1, 1),
        isSynced: false,
      );
      await sync.processIncomingChanges('boats', [
        {
          'supabaseId': 'boat-1',
          'name': 'Cloud',
          'lastModified': '2026-01-05T00:00:00.000',
        },
      ]);
      final conflict =
          (await (db.select(db.conflictLogs)
                ..where((t) => t.resolution.equals('pending')))
              .get())
              .single;

      await sync.resolveConflict(conflictId: conflict.id, keepLocal: true);

      final boat = (await db.select(db.boats).get()).single;
      expect(boat.name, 'Mine');
      expect(boat.isSynced, isFalse);
      final pending = await (db.select(db.conflictLogs)
            ..where((t) => t.resolution.equals('pending')))
          .get();
      expect(pending, isEmpty);
    });
  });
}
