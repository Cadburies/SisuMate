import '../../models/models.dart';

/// #328 — named anchorage catalog. Independent of the live [AnchorWatch].
abstract class AnchorSpotRepository {
  Stream<List<AnchorSpot>> watchAll();

  Future<List<AnchorSpot>> getAll();

  /// Insert or update by [AnchorSpot.id] (0 = insert). Returns the row
  /// with its assigned id.
  Future<AnchorSpot> save(AnchorSpot spot);

  Future<void> delete(int id);
}
