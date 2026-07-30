import '../../models/models.dart';

abstract class BoatRepository {
  Stream<List<Boat>> watchBoats();
  Future<List<Boat>> getBoats();
  Future<Boat?> getBoatById(String supabaseId);
  Future<void> addBoat(Boat boat);
  Future<void> updateBoat(Boat boat);
  Future<void> deleteBoat(Boat boat);

  /// Insert/update a boat locally only (no outbound sync). Used when a crew
  /// member joins a shared boat — we must not push the owner's boat back.
  Future<void> upsertLocal(Boat boat);
}
