part of 'models.dart';

class CommunityTemplate {
  CommunityTemplate();

  int id = 0;
  String supabaseId = '';
  String name = '';
  String description = '';
  bool isApproved = false;
  String authorId = '';
  String title = '';
  String category = '';
  String subcategory = '';
  String content = '';
  bool isSynced = false;
  DateTime lastModified = DateTime.now().toUtc();
  // Server-maintained (Postgres triggers on community_downloads/
  // community_ratings insert) — never sent by the client.
  int downloadCount = 0;
  double avgRating = 0;
  int ratingCount = 0;
  // Bumped by the author on republish (community_author_update RLS already
  // allows updating their own row) — see CommunityRepository.republishTemplate.
  int version = 1;

  factory CommunityTemplate.fromJson(Map<String, dynamic> json) {
    return CommunityTemplate()
      ..supabaseId = json['id'] as String? ?? ''
      ..name = json['name'] as String? ?? ''
      ..title = json['title'] as String? ?? ''
      ..description = json['description'] as String? ?? ''
      ..category = json['category'] as String? ?? ''
      ..subcategory = json['subcategory'] as String? ?? ''
      ..authorId = json['author_id'] as String? ?? ''
      ..content = json['content'] as String? ?? ''
      ..isApproved = json['is_approved'] as bool? ?? false
      ..isSynced = true
      ..lastModified = json['last_modified'] != null
          ? DateTime.parse(json['last_modified'] as String)
          : DateTime.now()
      ..downloadCount = json['download_count'] as int? ?? 0
      ..avgRating = (json['avg_rating'] as num?)?.toDouble() ?? 0
      ..ratingCount = json['rating_count'] as int? ?? 0
      ..version = json['version'] as int? ?? 1;
  }

  // `id` is only included when non-empty (an existing row). Postgres only
  // applies a column's `default gen_random_uuid()` when the column is
  // OMITTED from the insert — an explicit `id: null` sets the column to
  // NULL instead, which violates the primary key's not-null constraint and
  // silently fails every publish (found live, 2026-07 — the pre-S5 blank
  // publish dialog had this exact same bug and always failed under it).
  Map<String, dynamic> toJson() => {
    if (supabaseId.isNotEmpty) 'id': supabaseId,
    'name': name,
    'title': title,
    'description': description,
    'category': category,
    'subcategory': subcategory,
    'author_id': authorId,
    'content': content,
    'is_approved': isApproved,
    'last_modified': lastModified.toIso8601String(),
    'version': version,
  };

  /// Serializes a real [ChecklistGroup] + its [items] into a publishable
  /// template — replaces the old blank-form publish flow (which produced
  /// `content: {items: []}` regardless of what the user typed). `category`
  /// is taken from [group.appType] ('checklist'/'maintenance'/'safety'), not
  /// user-chosen, so browsing by category always matches what import creates.
  factory CommunityTemplate.fromChecklistGroup({
    required ChecklistGroup group,
    required List<ChecklistItem> items,
    required String description,
    required String subcategory,
    required String authorId,
  }) {
    final content = jsonEncode({
      'kind': 'checklist',
      'title': group.title,
      'appType': group.appType,
      'iconName': group.iconName,
      'items': items
          .map((i) => {
                'name': i.name,
                'title': i.title,
                'description': i.description,
              })
          .toList(),
    });
    return CommunityTemplate()
      ..title = group.title
      ..name = group.title.toLowerCase().replaceAll(' ', '_')
      ..description = description
      ..category = group.appType
      ..subcategory = subcategory
      ..authorId = authorId
      ..content = content
      ..lastModified = DateTime.now().toUtc();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommunityTemplate &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          supabaseId == other.supabaseId &&
          name == other.name &&
          description == other.description &&
          isApproved == other.isApproved &&
          authorId == other.authorId &&
          title == other.title &&
          category == other.category &&
          subcategory == other.subcategory &&
          content == other.content &&
          isSynced == other.isSynced &&
          lastModified == other.lastModified &&
          downloadCount == other.downloadCount &&
          avgRating == other.avgRating &&
          ratingCount == other.ratingCount &&
          version == other.version;

  @override
  int get hashCode => Object.hashAll([
        id,
        supabaseId,
        name,
        description,
        isApproved,
        authorId,
        title,
        category,
        subcategory,
        content,
        isSynced,
        lastModified,
        downloadCount,
        avgRating,
        ratingCount,
        version,
      ]);

  @override
  String toString() => 'CommunityTemplate(id: $id, supabaseId: $supabaseId, '
      'title: $title, name: $name, description: $description, '
      'category: $category, subcategory: $subcategory, '
      'authorId: $authorId, isApproved: $isApproved, isSynced: $isSynced, '
      'lastModified: $lastModified, downloadCount: $downloadCount, '
      'avgRating: $avgRating, ratingCount: $ratingCount, version: $version)';
}