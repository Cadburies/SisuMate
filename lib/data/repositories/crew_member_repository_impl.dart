import 'dart:convert';
import 'package:drift/drift.dart';
import '../../domain/repositories/crew_member_repository.dart';
import '../../models/models.dart';
import '../drift/app_database.dart';
import '../../services/sync_service.dart';

/// CrewMember on Drift (S1); still sync-participating (queues `toJson()`).
class CrewMemberRepositoryImpl implements CrewMemberRepository {
  final AppDatabase db;
  final SyncService syncService;

  CrewMemberRepositoryImpl(this.db, this.syncService);

  CrewMember _toDomain(CrewMemberRow r) => CrewMember()
    ..id = r.id
    ..supabaseId = r.supabaseId
    ..boatSupabaseId = r.boatSupabaseId
    ..name = r.name
    ..role = r.role
    ..phone = r.phone
    ..email = r.email
    ..iceContact = r.iceContact
    ..certifications = r.certifications
    ..localPath = r.localPath
    ..dateOfBirth = r.dateOfBirth
    ..nationality = r.nationality
    ..passportNumber = r.passportNumber
    ..allergenRestrictions =
        (jsonDecode(r.allergenRestrictions) as List).cast<String>()
    ..dietaryRequirements =
        (jsonDecode(r.dietaryRequirements) as List).cast<String>()
    ..isSynced = r.isSynced
    ..lastModified = r.lastModified;

  CrewMembersCompanion _toCompanion(CrewMember m) => CrewMembersCompanion(
        supabaseId: Value(m.supabaseId),
        boatSupabaseId: Value(m.boatSupabaseId),
        name: Value(m.name),
        role: Value(m.role),
        phone: Value(m.phone),
        email: Value(m.email),
        iceContact: Value(m.iceContact),
        certifications: Value(m.certifications),
        localPath: Value(m.localPath),
        dateOfBirth: Value(m.dateOfBirth),
        nationality: Value(m.nationality),
        passportNumber: Value(m.passportNumber),
        allergenRestrictions: Value(jsonEncode(m.allergenRestrictions)),
        dietaryRequirements: Value(jsonEncode(m.dietaryRequirements)),
        isSynced: Value(m.isSynced),
        lastModified: Value(m.lastModified),
      );

  @override
  Stream<List<CrewMember>> watchCrewMembers() {
    return db.select(db.crewMembers).watch().map((rows) {
      final all = rows.map(_toDomain).toList();
      return all
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    });
  }

  @override
  Future<void> addCrewMember(CrewMember member) async {
    member.lastModified = DateTime.now().toUtc();
    await db.into(db.crewMembers).insert(_toCompanion(member));
    await syncService.queueOutgoingChange('crew_members', member.toJson());
  }

  @override
  Future<void> updateCrewMember(CrewMember member) async {
    member.lastModified = DateTime.now().toUtc();
    await (db.update(db.crewMembers)
          ..where((t) => t.supabaseId.equals(member.supabaseId)))
        .write(_toCompanion(member));
    await syncService.queueOutgoingChange('crew_members', member.toJson());
  }

  @override
  Future<void> deleteCrewMember(CrewMember member) async {
    await (db.delete(db.crewMembers)
          ..where((t) => t.supabaseId.equals(member.supabaseId)))
        .go();
    await syncService.queueOutgoingChange(
      'crew_members',
      {'supabaseId': member.supabaseId},
      isDelete: true,
    );
  }
}
