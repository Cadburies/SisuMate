part of 'models.dart';

class Document {
  Document();

  int id = 0;
  String supabaseId = '';
  String boatSupabaseId = '';
  String title = '';
  String type = 'Other';
  String? fileUrl;
  String? localPath;
  String? notes;
  DateTime? expiry;
  bool isSynced = false;
  DateTime lastModified = DateTime.now().toUtc();

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document()
      ..supabaseId = json['supabaseId'] ?? ''
      ..boatSupabaseId = json['boatSupabaseId'] ?? ''
      ..title = json['title'] ?? ''
      ..type = json['type'] ?? 'Other'
      ..fileUrl = json['fileUrl']
      ..localPath = json['localPath']
      ..notes = json['notes']
      ..expiry = json['expiry'] != null ? DateTime.parse(json['expiry']) : null
      ..isSynced = json['isSynced'] ?? false
      ..lastModified = DateTime.parse(json['lastModified']);
  }

  Map<String, dynamic> toJson() => {
    'supabaseId': supabaseId,
    'boatSupabaseId': boatSupabaseId,
    'title': title,
    'type': type,
    'fileUrl': fileUrl,
    'localPath': localPath,
    'notes': notes,
    'expiry': expiry?.toIso8601String(),
    'isSynced': isSynced,
    'lastModified': lastModified.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Document &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          supabaseId == other.supabaseId &&
          boatSupabaseId == other.boatSupabaseId &&
          title == other.title &&
          type == other.type &&
          fileUrl == other.fileUrl &&
          localPath == other.localPath &&
          notes == other.notes &&
          expiry == other.expiry &&
          isSynced == other.isSynced &&
          lastModified == other.lastModified;

  @override
  int get hashCode => Object.hashAll([
        id,
        supabaseId,
        boatSupabaseId,
        title,
        type,
        fileUrl,
        localPath,
        notes,
        expiry,
        isSynced,
        lastModified,
      ]);

  @override
  String toString() => 'Document(id: $id, supabaseId: $supabaseId, '
      'boatSupabaseId: $boatSupabaseId, title: $title, type: $type, '
      'fileUrl: $fileUrl, localPath: $localPath, notes: $notes, '
      'expiry: $expiry, isSynced: $isSynced, lastModified: $lastModified)';
}
