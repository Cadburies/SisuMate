part of 'models.dart';

class CrewMember {
  CrewMember();

  int id = 0;
  String supabaseId = '';
  String boatSupabaseId = '';
  String name = '';
  String role = 'Crew';
  String? phone;
  String? email;
  String? iceContact;
  String? certifications;
  String? localPath;
  /// #326 — optional; only needed for international passages, but a real,
  /// common cruiser requirement: the crew-list PDF port authorities expect
  /// (name, DOB, nationality, passport #, role) can't be built without them.
  DateTime? dateOfBirth;
  String? nationality;
  String? passportNumber;
  /// #324 — same tag vocabularies as [GuestProfile]. Kept directly on
  /// CrewMember (which syncs) rather than linked to a GuestProfile (which
  /// is local-only, no supabaseId — a link would silently break on any
  /// other device sharing this boat). Chef's Guest Profiles screen can
  /// still offer "copy from crew" as a one-time prefill.
  List<String> allergenRestrictions = [];
  List<String> dietaryRequirements = [];
  bool isSynced = false;
  DateTime lastModified = DateTime.now().toUtc();

  factory CrewMember.fromJson(Map<String, dynamic> json) {
    return CrewMember()
      ..supabaseId = json['supabaseId'] ?? ''
      ..boatSupabaseId = json['boatSupabaseId'] ?? ''
      ..name = json['name'] ?? ''
      ..role = json['role'] ?? 'Crew'
      ..phone = json['phone']
      ..email = json['email']
      ..iceContact = json['iceContact']
      ..certifications = json['certifications']
      ..localPath = json['localPath']
      ..dateOfBirth = json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null
      ..nationality = json['nationality']
      ..passportNumber = json['passportNumber']
      ..allergenRestrictions =
          List<String>.from(json['allergenRestrictions'] as List? ?? [])
      ..dietaryRequirements =
          List<String>.from(json['dietaryRequirements'] as List? ?? [])
      ..isSynced = json['isSynced'] ?? false
      ..lastModified = DateTime.parse(json['lastModified']);
  }

  Map<String, dynamic> toJson() => {
    'supabaseId': supabaseId,
    'boatSupabaseId': boatSupabaseId,
    'name': name,
    'role': role,
    'phone': phone,
    'email': email,
    'iceContact': iceContact,
    'certifications': certifications,
    'localPath': localPath,
    'dateOfBirth': dateOfBirth?.toIso8601String(),
    'nationality': nationality,
    'passportNumber': passportNumber,
    'allergenRestrictions': allergenRestrictions,
    'dietaryRequirements': dietaryRequirements,
    'isSynced': isSynced,
    'lastModified': lastModified.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CrewMember &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          supabaseId == other.supabaseId &&
          boatSupabaseId == other.boatSupabaseId &&
          name == other.name &&
          role == other.role &&
          phone == other.phone &&
          email == other.email &&
          iceContact == other.iceContact &&
          certifications == other.certifications &&
          localPath == other.localPath &&
          dateOfBirth == other.dateOfBirth &&
          nationality == other.nationality &&
          passportNumber == other.passportNumber &&
          listEquals(allergenRestrictions, other.allergenRestrictions) &&
          listEquals(dietaryRequirements, other.dietaryRequirements) &&
          isSynced == other.isSynced &&
          lastModified == other.lastModified;

  @override
  int get hashCode => Object.hashAll([
        id,
        supabaseId,
        boatSupabaseId,
        name,
        role,
        phone,
        email,
        iceContact,
        certifications,
        localPath,
        dateOfBirth,
        nationality,
        passportNumber,
        Object.hashAll(allergenRestrictions),
        Object.hashAll(dietaryRequirements),
        isSynced,
        lastModified,
      ]);

  @override
  String toString() => 'CrewMember(id: $id, supabaseId: $supabaseId, '
      'boatSupabaseId: $boatSupabaseId, name: $name, role: $role, '
      'phone: $phone, email: $email, iceContact: $iceContact, '
      'certifications: $certifications, localPath: $localPath, '
      'dateOfBirth: $dateOfBirth, nationality: $nationality, '
      'passportNumber: $passportNumber, '
      'allergenRestrictions: $allergenRestrictions, '
      'dietaryRequirements: $dietaryRequirements, '
      'isSynced: $isSynced, lastModified: $lastModified)';
}
