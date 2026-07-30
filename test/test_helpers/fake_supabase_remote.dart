import 'package:sisu_mate/services/supabase_remote.dart';

/// In-memory [SupabaseRemote] for TEST2 success-path unit tests.
///
/// Does not talk to the network. Callers can seed templates, set [userId],
/// and inspect [upserts] / [deletes] / [ratings] after the code under test runs.
class FakeSupabaseRemote implements SupabaseRemote {
  FakeSupabaseRemote({this.userId = 'test-user-id'});

  /// Auth uid returned by [currentUserId]. Null/empty → unauthenticated.
  String? userId;

  /// When true, every remote call throws (for failure-path tests).
  bool shouldFail = false;

  /// Server-shaped community template rows keyed by id.
  final Map<String, Map<String, dynamic>> templates = {};

  /// Ratings keyed by `$templateId|$userId`.
  final Map<String, int> ratings = {};

  /// Download counts keyed by template id.
  final Map<String, int> downloadCounts = {};

  /// Recorded outbox upserts: `(table, wireData)`.
  final List<(String table, Map<String, dynamic> data)> upserts = [];

  /// Recorded outbox deletes: `(table, wireId)`.
  final List<(String table, String wireId)> deletes = [];

  /// Remote rows for [fetchBySupabaseId], keyed by `$table|$wireId`.
  final Map<String, Map<String, dynamic>> remoteRows = {};

  int _idSeq = 0;

  void _throwIfFailing() {
    if (shouldFail) throw Exception('FakeSupabaseRemote: forced failure');
  }

  @override
  String? get currentUserId => userId;

  @override
  Future<List<Map<String, dynamic>>> communityBrowse({
    String? category,
    String? subcategory,
    bool onlyApproved = true,
    required String orderColumn,
  }) async {
    _throwIfFailing();
    var rows = templates.values.toList();
    if (onlyApproved) {
      rows = rows.where((r) => r['is_approved'] == true).toList();
    }
    if (category != null && category != 'all') {
      rows = rows.where((r) => r['category'] == category).toList();
    }
    if (subcategory != null) {
      rows = rows.where((r) => r['subcategory'] == subcategory).toList();
    }
    rows.sort((a, b) {
      final av = a[orderColumn];
      final bv = b[orderColumn];
      if (av is Comparable && bv is Comparable) {
        return bv.compareTo(av);
      }
      return 0;
    });
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  @override
  Future<Map<String, dynamic>> communityInsert(Map<String, dynamic> json) async {
    _throwIfFailing();
    final id = (json['id'] as String?)?.isNotEmpty == true
        ? json['id'] as String
        : 'tmpl-${++_idSeq}';
    final row = {
      ...json,
      'id': id,
      'download_count': 0,
      'avg_rating': 0,
      'rating_count': 0,
      'version': json['version'] ?? 1,
      'is_approved': json['is_approved'] ?? true,
      'last_modified':
          json['last_modified'] ?? DateTime.now().toUtc().toIso8601String(),
    };
    templates[id] = Map<String, dynamic>.from(row);
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<Map<String, dynamic>> communityUpdate(
    String id,
    Map<String, dynamic> json,
  ) async {
    _throwIfFailing();
    final existing = templates[id] ?? {};
    final row = {
      ...existing,
      ...json,
      'id': id,
    };
    templates[id] = Map<String, dynamic>.from(row);
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<int> communityFetchVersion(String id) async {
    _throwIfFailing();
    return (templates[id]?['version'] as int?) ?? 1;
  }

  @override
  Future<void> communityRate({
    required String templateId,
    required String userId,
    required int rating,
  }) async {
    _throwIfFailing();
    ratings['$templateId|$userId'] = rating;
  }

  @override
  Future<int?> communityMyRating({
    required String templateId,
    required String userId,
  }) async {
    _throwIfFailing();
    return ratings['$templateId|$userId'];
  }

  @override
  Future<Map<String, dynamic>> communityFetchTemplate(String id) async {
    _throwIfFailing();
    final row = templates[id];
    if (row == null) throw Exception('template not found: $id');
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<void> communityRecordDownload(String templateId) async {
    _throwIfFailing();
    downloadCounts[templateId] = (downloadCounts[templateId] ?? 0) + 1;
  }

  @override
  Future<int> communityDownloadCount(String templateId) async {
    _throwIfFailing();
    return downloadCounts[templateId] ?? 0;
  }

  @override
  Future<void> upsert(String table, Map<String, dynamic> wireData) async {
    _throwIfFailing();
    upserts.add((table, Map<String, dynamic>.from(wireData)));
    final wireId = wireData['supabaseId'] as String?;
    if (wireId != null) {
      remoteRows['$table|$wireId'] = Map<String, dynamic>.from(wireData);
    }
  }

  @override
  Future<void> deleteBySupabaseId(String table, String wireId) async {
    _throwIfFailing();
    deletes.add((table, wireId));
    remoteRows.remove('$table|$wireId');
  }

  @override
  Future<Map<String, dynamic>?> fetchBySupabaseId(
    String table,
    String wireId,
  ) async {
    _throwIfFailing();
    final row = remoteRows['$table|$wireId'];
    if (row == null) return null;
    return Map<String, dynamic>.from(row);
  }
}
