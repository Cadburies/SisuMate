import '../../models/models.dart';

abstract class CrewMemberRepository {
  Stream<List<CrewMember>> watchCrewMembers();
  Future<void> addCrewMember(CrewMember member);
  Future<void> updateCrewMember(CrewMember member);
  Future<void> deleteCrewMember(CrewMember member);
}
