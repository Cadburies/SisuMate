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
        isSynced,
        lastModified,
      ]);

  @override
  String toString() => 'CrewMember(id: $id, supabaseId: $supabaseId, '
      'boatSupabaseId: $boatSupabaseId, name: $name, role: $role, '
      'phone: $phone, email: $email, iceContact: $iceContact, '
      'certifications: $certifications, localPath: $localPath, '
      'isSynced: $isSynced, lastModified: $lastModified)';
}
