import '../../models/models.dart';

abstract class GuestProfileRepository {
  Stream<List<GuestProfile>> watchProfiles();
  Future<void> addProfile(GuestProfile profile);
  Future<void> updateProfile(GuestProfile profile);
  Future<void> deleteProfile(GuestProfile profile);
}
