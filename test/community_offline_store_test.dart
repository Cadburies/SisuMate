import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/domain/repositories/community_repository.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/community_offline_store.dart';

CommunityTemplate _t({
  required String id,
  required String title,
  String description = '',
  String subcategory = '',
  String content = '',
}) =>
    CommunityTemplate()
      ..supabaseId = id
      ..title = title
      ..description = description
      ..subcategory = subcategory
      ..content = content
      ..lastModified = DateTime.utc(2026, 8, 1);

void main() {
  group('communityTemplateMatchesInterests (#322)', () {
    test('empty interests match everything', () {
      expect(
        communityTemplateMatchesInterests(
          _t(id: '1', title: 'Volvo Penta impeller'),
          const [],
        ),
        isTrue,
      );
    });

    test('Yanmar 4HJ45 matches a Yanmar impeller, not a Volvo Penta one', () {
      const mine = ['Yanmar 4HJ45'];
      expect(
        communityTemplateMatchesInterests(
          _t(
            id: 'y',
            title: 'Raw-water impeller — Yanmar 4HJ45',
            subcategory: 'Yanmar',
          ),
          mine,
        ),
        isTrue,
      );
      expect(
        communityTemplateMatchesInterests(
          _t(
            id: 'v',
            title: 'Volvo Penta D2 impeller',
            subcategory: 'Volvo Penta',
          ),
          mine,
        ),
        isFalse,
      );
    });

    test('OR across interests keeps a generator the sailor actually owns', () {
      const mine = ['Yanmar 4HJ45', 'Northern Light 4.5kW'];
      expect(
        communityTemplateMatchesInterests(
          _t(
            id: 'g',
            title: 'Northern Light 4.5kW oil change',
            description: 'Generator service',
          ),
          mine,
        ),
        isTrue,
      );
    });
  });

  group('CommunityOfflineStore', () {
    late Directory tmp;
    late CommunityOfflineStore store;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('sisu_community_offline_');
      store = CommunityOfflineStore(overrideFile: File('${tmp.path}/c.json'));
    });

    tearDown(() {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    });

    test('interests persist', () async {
      await store.saveInterests(['Yanmar 4HJ45', '  ', 'Northern Light 4.5kW']);
      expect(await store.loadInterests(),
          ['Yanmar 4HJ45', 'Northern Light 4.5kW']);
    });

    test('browse snapshot strips content and is keyed', () async {
      final key = CommunityOfflineStore.browseKey(
        category: 'maintenance',
        sortBy: CommunitySortOrder.recent,
        interests: const ['Yanmar 4HJ45'],
      );
      await store.saveBrowseSnapshot(
        key: key,
        fetchedAt: DateTime.utc(2026, 8, 14, 12),
        templates: [
          _t(id: 'a', title: 'Impeller', content: '{"items":[1,2,3]}'),
        ],
      );
      final hit = await store.loadBrowseSnapshot(key);
      expect(hit, isNotNull);
      expect(hit!.templates.single.content, isEmpty,
          reason: 'last-browse must not keep bodies');
      expect(hit.templates.single.title, 'Impeller');

      final miss = await store.loadBrowseSnapshot(
        CommunityOfflineStore.browseKey(
          category: 'safety',
          sortBy: CommunitySortOrder.recent,
          interests: const ['Yanmar 4HJ45'],
        ),
      );
      expect(miss, isNull);
    });

    test('keep / unkeep stores the full body', () async {
      await store.keepTemplate(
        _t(id: 'k1', title: 'Gen service', content: '{"title":"g"}'),
      );
      expect(await store.keptIds(), {'k1'});
      expect((await store.keptTemplate('k1'))!.content, '{"title":"g"}');
      await store.unkeepTemplate('k1');
      expect(await store.keptIds(), isEmpty);
    });
  });
}
