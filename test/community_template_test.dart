import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';

// Covers CommunityTemplate.fromChecklistGroup (S5) — the real "share an
// existing list" serialization that replaced the old blank-form publish
// dialog, which always produced `content: {"items": []}` regardless of what
// the user typed. This is what CommunityRepositoryImpl.importTemplate's
// content parsing depends on for round-tripping correctly.
void main() {
  group('CommunityTemplate.fromChecklistGroup', () {
    late ChecklistGroup group;
    late List<ChecklistItem> items;

    setUp(() {
      group = ChecklistGroup()
        ..supabaseId = 'group_1'
        ..title = 'Daily Engine Checks'
        ..appType = 'maintenance'
        ..iconName = 'engine';
      items = [
        ChecklistItem()
          ..name = 'oil_level'
          ..title = 'Check oil level'
          ..description = 'Dipstick should read full',
        ChecklistItem()
          ..name = 'belt_tension'
          ..title = 'Check belt tension'
          ..description = null,
      ];
    });

    test('category comes from the group\'s appType, not user input', () {
      final t = CommunityTemplate.fromChecklistGroup(
        group: group,
        items: items,
        description: 'A thorough pre-departure engine check',
        subcategory: 'Yanmar',
        authorId: 'user_1',
      );
      expect(t.category, 'maintenance');
    });

    test('title/name/description/subcategory/authorId map correctly', () {
      final t = CommunityTemplate.fromChecklistGroup(
        group: group,
        items: items,
        description: 'A thorough pre-departure engine check',
        subcategory: 'Yanmar',
        authorId: 'user_1',
      );
      expect(t.title, 'Daily Engine Checks');
      expect(t.name, 'daily_engine_checks');
      expect(t.description, 'A thorough pre-departure engine check');
      expect(t.subcategory, 'Yanmar');
      expect(t.authorId, 'user_1');
    });

    test('content JSON round-trips into the shape importTemplate expects',
        () {
      final t = CommunityTemplate.fromChecklistGroup(
        group: group,
        items: items,
        description: '',
        subcategory: '',
        authorId: 'user_1',
      );
      final parsed = jsonDecode(t.content) as Map<String, dynamic>;
      expect(parsed['title'], 'Daily Engine Checks');
      expect(parsed['appType'], 'maintenance');
      expect(parsed['iconName'], 'engine');
      final parsedItems = parsed['items'] as List;
      expect(parsedItems.length, 2);
      expect(parsedItems[0]['name'], 'oil_level');
      expect(parsedItems[0]['title'], 'Check oil level');
      expect(parsedItems[0]['description'], 'Dipstick should read full');
      expect(parsedItems[1]['description'], isNull);
    });

    test('an empty items list serializes to an empty (not null) array', () {
      final t = CommunityTemplate.fromChecklistGroup(
        group: group,
        items: const [],
        description: '',
        subcategory: '',
        authorId: 'user_1',
      );
      final parsed = jsonDecode(t.content) as Map<String, dynamic>;
      expect(parsed['items'], isEmpty);
    });
  });

  group('CommunityTemplate.toJson — id handling (regression)', () {
    test(
        'a new (unpublished) template omits the id key entirely, rather '
        'than sending an explicit null — an explicit null overrides '
        "Postgres's default gen_random_uuid() and fails the insert (found "
        'live via on-device testing, 2026-07)', () {
      final t = CommunityTemplate()..title = 'New Template';
      expect(t.supabaseId, isEmpty);
      expect(t.toJson().containsKey('id'), isFalse);
    });

    test('an existing template (has a supabaseId) includes its real id', () {
      final t = CommunityTemplate()
        ..supabaseId = 'existing-uuid'
        ..title = 'Existing Template';
      expect(t.toJson()['id'], 'existing-uuid');
    });
  });

  group('CommunityTemplate.fromJson — ratings + version (S5)', () {
    test('maps avg_rating/rating_count/version, defaulting when absent', () {
      final rated = CommunityTemplate.fromJson({
        'id': 'x',
        'avg_rating': 4.5,
        'rating_count': 12,
        'version': 3,
      });
      expect(rated.avgRating, 4.5);
      expect(rated.ratingCount, 12);
      expect(rated.version, 3);

      final unrated = CommunityTemplate.fromJson({'id': 'y'});
      expect(unrated.avgRating, 0);
      expect(unrated.ratingCount, 0);
      expect(unrated.version, 1);
    });

    test('toJson always includes version (unlike id, it is never null)', () {
      final t = CommunityTemplate()
        ..title = 'New'
        ..version = 2;
      expect(t.toJson()['version'], 2);
    });
  });

  group('ChecklistGroup — communityTemplateId/Version round-trip (S5)', () {
    test('toJson/fromJson round-trips both fields', () {
      final g = ChecklistGroup()
        ..title = 'Imported List'
        ..communityTemplateId = 'template-123'
        ..communityTemplateVersion = 2
        ..lastModified = DateTime.utc(2026, 1, 1);
      final json = g.toJson();
      expect(json['communityTemplateId'], 'template-123');
      expect(json['communityTemplateVersion'], 2);

      final roundTripped = ChecklistGroup.fromJson(json);
      expect(roundTripped.communityTemplateId, 'template-123');
      expect(roundTripped.communityTemplateVersion, 2);
    });

    test('a user-created (non-community) group leaves both fields null', () {
      final g = ChecklistGroup()
        ..title = 'My Own List'
        ..lastModified = DateTime.utc(2026, 1, 1);
      expect(g.communityTemplateId, isNull);
      expect(g.communityTemplateVersion, isNull);
      final roundTripped = ChecklistGroup.fromJson(g.toJson());
      expect(roundTripped.communityTemplateId, isNull);
      expect(roundTripped.communityTemplateVersion, isNull);
    });
  });
}
