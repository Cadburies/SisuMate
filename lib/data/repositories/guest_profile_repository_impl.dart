import 'dart:convert';
import 'package:drift/drift.dart';
import '../../models/models.dart';
import '../drift/app_database.dart';
import '../../domain/repositories/guest_profile_repository.dart';

/// GuestProfile on Drift. The repository interface returns the domain
/// `GuestProfile`; rows are mapped to/from Drift's `GuestProfileRow`. Two
/// `List<String>` fields are stored as JSON text columns.
class GuestProfileRepositoryImpl implements GuestProfileRepository {
  final AppDatabase _db;
  GuestProfileRepositoryImpl(this._db);

  GuestProfile _toDomain(GuestProfileRow r) => GuestProfile()
    ..id = r.id
    ..name = r.name
    ..allergenRestrictions =
        (jsonDecode(r.allergenRestrictions) as List).cast<String>()
    ..dietaryRequirements =
        (jsonDecode(r.dietaryRequirements) as List).cast<String>()
    ..preferredDrinks =
        (jsonDecode(r.preferredDrinks) as List).cast<String>()
    ..createdAt = r.createdAt;

  @override
  Stream<List<GuestProfile>> watchProfiles() {
    return _db.select(_db.guestProfiles).watch().map((rows) {
      final all = rows.map(_toDomain).toList();
      all.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return all;
    });
  }

  @override
  Future<void> addProfile(GuestProfile profile) async {
    profile.createdAt = DateTime.now();
    await _db.into(_db.guestProfiles).insert(GuestProfilesCompanion.insert(
          name: Value(profile.name),
          allergenRestrictions: Value(jsonEncode(profile.allergenRestrictions)),
          dietaryRequirements: Value(jsonEncode(profile.dietaryRequirements)),
          preferredDrinks: Value(jsonEncode(profile.preferredDrinks)),
          createdAt: Value(profile.createdAt),
        ));
  }

  @override
  Future<void> updateProfile(GuestProfile profile) async {
    await (_db.update(_db.guestProfiles)..where((t) => t.id.equals(profile.id)))
        .write(GuestProfilesCompanion(
      name: Value(profile.name),
      allergenRestrictions: Value(jsonEncode(profile.allergenRestrictions)),
      dietaryRequirements: Value(jsonEncode(profile.dietaryRequirements)),
      preferredDrinks: Value(jsonEncode(profile.preferredDrinks)),
    ));
  }

  @override
  Future<void> deleteProfile(GuestProfile profile) async {
    await (_db.delete(_db.guestProfiles)..where((t) => t.id.equals(profile.id)))
        .go();
  }
}
