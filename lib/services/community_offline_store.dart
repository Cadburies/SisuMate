import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/models.dart';
import '../domain/repositories/community_repository.dart';

/// #322 — does this template match any of the sailor's "on this boat"
/// interest phrases? Each phrase is AND-of-tokens ("Yanmar 4HJ45" needs
/// both tokens); phrases themselves are OR. Empty interests match everything.
bool communityTemplateMatchesInterests(
  CommunityTemplate template,
  Iterable<String> interests,
) {
  final phrases = interests
      .map((s) => s.trim().toLowerCase())
      .where((s) => s.isNotEmpty)
      .toList();
  if (phrases.isEmpty) return true;
  final hay =
      '${template.title} ${template.description} ${template.subcategory} ${template.name}'
          .toLowerCase();
  for (final phrase in phrases) {
    final tokens = phrase.split(RegExp(r'\s+'));
    if (tokens.every(hay.contains)) return true;
  }
  return false;
}

/// Listing-only copy (no [CommunityTemplate.content]) so a last-browse
/// snapshot cannot balloon into the full community catalog.
CommunityTemplate communityListingOnly(CommunityTemplate t) {
  return CommunityTemplate()
    ..supabaseId = t.supabaseId
    ..name = t.name
    ..title = t.title
    ..description = t.description
    ..category = t.category
    ..subcategory = t.subcategory
    ..authorId = t.authorId
    ..content = ''
    ..isApproved = t.isApproved
    ..isSynced = t.isSynced
    ..lastModified = t.lastModified
    ..downloadCount = t.downloadCount
    ..avgRating = t.avgRating
    ..ratingCount = t.ratingCount
    ..version = t.version;
}

Map<String, dynamic> communityTemplateToCacheJson(CommunityTemplate t) => {
      'id': t.supabaseId,
      'name': t.name,
      'title': t.title,
      'description': t.description,
      'category': t.category,
      'subcategory': t.subcategory,
      'author_id': t.authorId,
      'content': t.content,
      'is_approved': t.isApproved,
      'last_modified': t.lastModified.toIso8601String(),
      'download_count': t.downloadCount,
      'avg_rating': t.avgRating,
      'rating_count': t.ratingCount,
      'version': t.version,
    };

/// File-backed Community cache. Lives outside Drift on purpose so this
/// work stays disjoint from schema hotspots (quantity layers / #327).
///
/// * Last successful **browse listing** (content stripped) — one snapshot.
/// * User-selected **kept** templates (full body, for offline import).
/// * "On this boat" interest phrases.
class CommunityOfflineStore {
  CommunityOfflineStore({this.overrideFile});

  /// Tests inject a temp file; production uses the documents directory.
  final File? overrideFile;

  Future<File> _file() async {
    if (overrideFile != null) return overrideFile!;
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/community_offline_cache.json');
  }

  Future<Map<String, dynamic>> _read() async {
    try {
      final f = await _file();
      if (!await f.exists()) return {};
      final decoded = jsonDecode(await f.readAsString());
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      // Corrupt/unreadable cache — start empty. Expected control flow.
    }
    return {};
  }

  Future<void> _write(Map<String, dynamic> data) async {
    final f = await _file();
    await f.parent.create(recursive: true);
    await f.writeAsString(jsonEncode(data));
  }

  Future<List<String>> loadInterests() async {
    final raw = (await _read())['interests'];
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
  }

  Future<void> saveInterests(List<String> interests) async {
    final data = await _read();
    data['interests'] = interests
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    await _write(data);
  }

  static String browseKey({
    required String? category,
    required CommunitySortOrder sortBy,
    required List<String> interests,
  }) {
    final cat = (category == null || category == 'all') ? 'all' : category;
    final sort = sortBy == CommunitySortOrder.mostDownloaded
        ? 'downloads'
        : 'recent';
    final tags = List<String>.from(interests.map((s) => s.trim().toLowerCase()))
      ..sort();
    return '$cat|$sort|${tags.join(',')}';
  }

  Future<void> saveBrowseSnapshot({
    required String key,
    required DateTime fetchedAt,
    required List<CommunityTemplate> templates,
  }) async {
    final data = await _read();
    data['browse'] = {
      'key': key,
      'fetchedAt': fetchedAt.toUtc().toIso8601String(),
      'templates': templates
          .map(communityListingOnly)
          .map(communityTemplateToCacheJson)
          .toList(),
    };
    await _write(data);
  }

  Future<({DateTime fetchedAt, List<CommunityTemplate> templates})?>
      loadBrowseSnapshot(String key) async {
    final browse = (await _read())['browse'];
    if (browse is! Map) return null;
    if (browse['key'] != key) return null;
    final atRaw = browse['fetchedAt'] as String?;
    final fetchedAt =
        atRaw == null ? DateTime.now().toUtc() : DateTime.parse(atRaw);
    final raw = browse['templates'];
    if (raw is! List) return null;
    final templates = raw
        .whereType<Map>()
        .map((e) => CommunityTemplate.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return (fetchedAt: fetchedAt, templates: templates);
  }

  Future<void> keepTemplate(CommunityTemplate template) async {
    final data = await _read();
    final kept = Map<String, dynamic>.from(
      (data['kept'] as Map?) ?? const {},
    );
    kept[template.supabaseId] = communityTemplateToCacheJson(template);
    data['kept'] = kept;
    await _write(data);
  }

  Future<void> unkeepTemplate(String templateId) async {
    final data = await _read();
    final kept = Map<String, dynamic>.from(
      (data['kept'] as Map?) ?? const {},
    );
    kept.remove(templateId);
    data['kept'] = kept;
    await _write(data);
  }

  Future<Set<String>> keptIds() async {
    final kept = (await _read())['kept'];
    if (kept is! Map) return {};
    return kept.keys.map((e) => e.toString()).toSet();
  }

  Future<CommunityTemplate?> keptTemplate(String templateId) async {
    final kept = (await _read())['kept'];
    if (kept is! Map) return null;
    final raw = kept[templateId];
    if (raw is! Map) return null;
    return CommunityTemplate.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<List<CommunityTemplate>> keptTemplates() async {
    final kept = (await _read())['kept'];
    if (kept is! Map) return const [];
    return kept.values
        .whereType<Map>()
        .map((e) => CommunityTemplate.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
