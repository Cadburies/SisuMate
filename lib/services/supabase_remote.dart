import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_client.dart';

/// TEST2 seam: injectable remote API for community + outbox sync.
///
/// Production uses [LiveSupabaseRemote]. Unit tests inject a fake so
/// "network succeeds" paths (publish/rate, outbox upsert/delete) are coverable
/// without a real Supabase session.
abstract class SupabaseRemote {
  String? get currentUserId;

  // ── Community ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> communityBrowse({
    String? category,
    String? subcategory,
    bool onlyApproved = true,
    required String orderColumn,
  });

  Future<Map<String, dynamic>> communityInsert(Map<String, dynamic> json);

  Future<Map<String, dynamic>> communityUpdate(
    String id,
    Map<String, dynamic> json,
  );

  Future<int> communityFetchVersion(String id);

  Future<void> communityRate({
    required String templateId,
    required String userId,
    required int rating,
  });

  Future<int?> communityMyRating({
    required String templateId,
    required String userId,
  });

  /// #321 — flag a template for human review (wrong/unsafe content,
  /// duplicate, etc.). Insert-only: a user can report the same template
  /// more than once (e.g. for a different reason later), unlike rating
  /// which is one-per-user-per-template.
  Future<void> communityReport({
    required String templateId,
    required String userId,
    required String reason,
    String? note,
  });

  Future<Map<String, dynamic>> communityFetchTemplate(String id);

  Future<void> communityRecordDownload(String templateId);

  Future<int> communityDownloadCount(String templateId);

  // ── Sync outbox / online push ─────────────────────────────────────────────

  Future<void> upsert(String table, Map<String, dynamic> wireData);

  Future<void> deleteBySupabaseId(String table, String wireId);

  Future<Map<String, dynamic>?> fetchBySupabaseId(String table, String wireId);
}

/// Production implementation over [SupabaseClientWrapper.instance].
class LiveSupabaseRemote implements SupabaseRemote {
  const LiveSupabaseRemote();

  SupabaseClient get _c => SupabaseClientWrapper.instance;

  @override
  String? get currentUserId => _c.auth.currentUser?.id;

  @override
  Future<List<Map<String, dynamic>>> communityBrowse({
    String? category,
    String? subcategory,
    bool onlyApproved = true,
    required String orderColumn,
  }) async {
    // Listing columns only — omit `content` so a viral catalog cannot
    // push megabytes of checklist bodies on every browse (#322).
    var query = _c.from('community_templates').select(
          'id,name,title,description,category,subcategory,author_id,'
          'is_approved,last_modified,download_count,avg_rating,'
          'rating_count,version',
        );
    if (onlyApproved) query = query.eq('is_approved', true);
    if (category != null && category != 'all') {
      query = query.eq('category', category);
    }
    if (subcategory != null) query = query.eq('subcategory', subcategory);
    final rows = await query.order(orderColumn, ascending: false);
    return (rows as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> communityInsert(Map<String, dynamic> json) async {
    final row = await _c
        .from('community_templates')
        .insert(json)
        .select()
        .single();
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<Map<String, dynamic>> communityUpdate(
    String id,
    Map<String, dynamic> json,
  ) async {
    final row = await _c
        .from('community_templates')
        .update(json)
        .eq('id', id)
        .select()
        .single();
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<int> communityFetchVersion(String id) async {
    final existing = await _c
        .from('community_templates')
        .select('version')
        .eq('id', id)
        .single();
    return (existing['version'] as int?) ?? 1;
  }

  @override
  Future<void> communityRate({
    required String templateId,
    required String userId,
    required int rating,
  }) async {
    await _c.from('community_ratings').upsert(
      {
        'template_id': templateId,
        'user_id': userId,
        'rating': rating,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'template_id,user_id',
    );
  }

  @override
  Future<int?> communityMyRating({
    required String templateId,
    required String userId,
  }) async {
    final row = await _c
        .from('community_ratings')
        .select('rating')
        .eq('template_id', templateId)
        .eq('user_id', userId)
        .maybeSingle();
    return row?['rating'] as int?;
  }

  @override
  Future<void> communityReport({
    required String templateId,
    required String userId,
    required String reason,
    String? note,
  }) async {
    await _c.from('community_template_reports').insert({
      'template_id': templateId,
      'reporter_id': userId,
      'reason': reason,
      'note': note,
    });
  }

  @override
  Future<Map<String, dynamic>> communityFetchTemplate(String id) async {
    final row =
        await _c.from('community_templates').select().eq('id', id).single();
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<void> communityRecordDownload(String templateId) async {
    await _c.from('community_downloads').insert({'template_id': templateId});
  }

  @override
  Future<int> communityDownloadCount(String templateId) async {
    final result = await _c
        .from('community_downloads')
        .select()
        .eq('template_id', templateId)
        .count();
    return result.count;
  }

  @override
  Future<void> upsert(String table, Map<String, dynamic> wireData) async {
    await _c.from(table).upsert(wireData);
  }

  @override
  Future<void> deleteBySupabaseId(String table, String wireId) async {
    await _c.from(table).delete().eq('supabaseId', wireId);
  }

  @override
  Future<Map<String, dynamic>?> fetchBySupabaseId(
    String table,
    String wireId,
  ) async {
    final row = await _c
        .from(table)
        .select()
        .eq('supabaseId', wireId)
        .maybeSingle();
    if (row == null) return null;
    return Map<String, dynamic>.from(row);
  }
}
