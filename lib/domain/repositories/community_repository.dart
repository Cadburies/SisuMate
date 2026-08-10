import '../../models/models.dart';

enum CommunitySortOrder { recent, mostDownloaded }

abstract class CommunityRepository {
  Future<CommunityTemplate> publishTemplate(CommunityTemplate template);

  /// Republish an already-published template with new content — an UPDATE
  /// (not insert) on the same row, author-only per RLS, bumps `version` so
  /// importers can detect an update is available (S5).
  Future<CommunityTemplate> updateTemplate(CommunityTemplate template);

  Future<List<CommunityTemplate>> browseCommunity({
    String? category,
    String? subcategory,
    bool onlyApproved = true,
    CommunitySortOrder sortBy = CommunitySortOrder.recent,
  });
  Future<bool> importTemplate(String templateId, String boatId);
  Future<int> getDownloadCount(String templateId);

  /// Upsert the current user's 1-5 star rating for a template.
  Future<bool> rateTemplate(String templateId, int rating);

  /// The current user's own rating for a template, or null if unrated.
  Future<int?> getMyRating(String templateId);

  /// #321 — flag a template for human review. Returns false on failure
  /// (unauthenticated, network) so the UI can show "try again" without
  /// pretending the report landed.
  Future<bool> reportTemplate(
    String templateId, {
    required String reason,
    String? note,
  });

  /// Merges a newer version of [localGroup]'s source template into it in
  /// place: new items are added, matched items get their title/description
  /// updated but keep local state (isCompleted/history/notes/photos), and
  /// local items with no match in the new source are left untouched — never
  /// destructive (S5, per explicit product decision).
  Future<bool> applyCommunityUpdate({
    required ChecklistGroup localGroup,
    required String boatId,
  });

  /// Stamps a locally-authored group with the template it was just
  /// published/republished as, so the author's own copy doesn't show
  /// "update available" against its own just-published content.
  Future<void> linkGroupToTemplate({
    required String groupSupabaseId,
    required String templateId,
    required int version,
  });

  /// Local-only (no network) read of a previously published/imported
  /// template from the Drift cache — used to pre-fill the republish dialog
  /// without risking wiping the description/subcategory on an empty resubmit.
  Future<CommunityTemplate?> getCachedTemplate(String templateId);
}
