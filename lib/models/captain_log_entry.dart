part of 'models.dart';

class CaptainLogEntry {
  CaptainLogEntry();

  int id = 0;
  String supabaseId = '';
  String boatSupabaseId = '';
  DateTime logDate = DateTime.now();
  String title = '';
  String? logTime;
  double? positionLat;
  double? positionLng;
  String? weather;
  int? windSpeedKt;
  String? windDir;
  // #213: speed/course over ground from a single GPS fix (or manual entry).
  double? sogKt;
  double? cogDeg;
  double? barometricPressureHpa;
  String? seaState;
  // Distinct from [crewOnBoard] — who's actively on watch at [logTime],
  // not just aboard.
  List<String> watchCrew = [];
  double? engineHours;
  double? fuelLevelPercent;
  List<String> crewOnBoard = [];
  String? notes;
  List<String> photos = [];
  bool isSynced = false;
  DateTime lastModified = DateTime.now().toUtc();

  factory CaptainLogEntry.fromJson(Map<String, dynamic> json) {
    return CaptainLogEntry()
      ..supabaseId = json['supabaseId'] ?? ''
      ..boatSupabaseId = json['boatSupabaseId'] ?? ''
      ..logDate = DateTime.parse(json['logDate'])
      ..title = json['title'] ?? ''
      ..logTime = json['logTime']
      ..positionLat = json['positionLat']?.toDouble()
      ..positionLng = json['positionLng']?.toDouble()
      ..weather = json['weather']
      ..windSpeedKt = json['windSpeedKt']
      ..windDir = json['windDir']
      ..sogKt = json['sogKt']?.toDouble()
      ..cogDeg = json['cogDeg']?.toDouble()
      ..barometricPressureHpa = json['barometricPressureHpa']?.toDouble()
      ..seaState = json['seaState']
      ..watchCrew = List<String>.from(json['watchCrew'] ?? [])
      ..engineHours = json['engineHours']?.toDouble()
      ..fuelLevelPercent = json['fuelLevelPercent']?.toDouble()
      ..crewOnBoard = List<String>.from(json['crewOnBoard'] ?? [])
      ..notes = json['notes']
      ..photos = List<String>.from(json['photos'] ?? [])
      ..isSynced = json['isSynced'] ?? false
      ..lastModified = DateTime.parse(json['lastModified']);
  }

  Map<String, dynamic> toJson() => {
    'supabaseId': supabaseId,
    'boatSupabaseId': boatSupabaseId,
    'logDate': logDate.toIso8601String(),
    'title': title,
    'logTime': logTime,
    'positionLat': positionLat,
    'positionLng': positionLng,
    'weather': weather,
    'windSpeedKt': windSpeedKt,
    'windDir': windDir,
    'sogKt': sogKt,
    'cogDeg': cogDeg,
    'barometricPressureHpa': barometricPressureHpa,
    'seaState': seaState,
    'watchCrew': watchCrew,
    'engineHours': engineHours,
    'fuelLevelPercent': fuelLevelPercent,
    'crewOnBoard': crewOnBoard,
    'notes': notes,
    'photos': photos,
    'isSynced': isSynced,
    'lastModified': lastModified.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaptainLogEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          supabaseId == other.supabaseId &&
          boatSupabaseId == other.boatSupabaseId &&
          logDate == other.logDate &&
          title == other.title &&
          logTime == other.logTime &&
          positionLat == other.positionLat &&
          positionLng == other.positionLng &&
          weather == other.weather &&
          windSpeedKt == other.windSpeedKt &&
          windDir == other.windDir &&
          sogKt == other.sogKt &&
          cogDeg == other.cogDeg &&
          barometricPressureHpa == other.barometricPressureHpa &&
          seaState == other.seaState &&
          listEquals(watchCrew, other.watchCrew) &&
          engineHours == other.engineHours &&
          fuelLevelPercent == other.fuelLevelPercent &&
          listEquals(crewOnBoard, other.crewOnBoard) &&
          notes == other.notes &&
          listEquals(photos, other.photos) &&
          isSynced == other.isSynced &&
          lastModified == other.lastModified;

  @override
  int get hashCode => Object.hashAll([
        id,
        supabaseId,
        boatSupabaseId,
        logDate,
        title,
        logTime,
        positionLat,
        positionLng,
        weather,
        windSpeedKt,
        windDir,
        sogKt,
        cogDeg,
        barometricPressureHpa,
        seaState,
        Object.hashAll(watchCrew),
        engineHours,
        fuelLevelPercent,
        Object.hashAll(crewOnBoard),
        notes,
        Object.hashAll(photos),
        isSynced,
        lastModified,
      ]);

  @override
  String toString() => 'CaptainLogEntry(id: $id, supabaseId: $supabaseId, '
      'boatSupabaseId: $boatSupabaseId, logDate: $logDate, title: $title, '
      'logTime: $logTime, positionLat: $positionLat, '
      'positionLng: $positionLng, weather: $weather, '
      'windSpeedKt: $windSpeedKt, windDir: $windDir, sogKt: $sogKt, '
      'cogDeg: $cogDeg, barometricPressureHpa: $barometricPressureHpa, '
      'seaState: $seaState, watchCrew: $watchCrew, '
      'engineHours: $engineHours, fuelLevelPercent: $fuelLevelPercent, '
      'crewOnBoard: $crewOnBoard, notes: $notes, photos: $photos, '
      'isSynced: $isSynced, lastModified: $lastModified)';
}