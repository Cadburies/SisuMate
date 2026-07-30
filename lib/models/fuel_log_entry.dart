part of 'models.dart';

class FuelLogEntry {
  int id = 0;
  String supabaseId = '';
  String boatSupabaseId = '';
  DateTime date = DateTime.now();
  String type = 'Fuel';
  double liters = 0.0;
  double pricePerLiter = 0.0;
  double totalCost = 0.0;
  String? notes;
  bool isSynced = false;
  DateTime lastModified = DateTime.now().toUtc();

  factory FuelLogEntry.fromJson(Map<String, dynamic> json) {
    return FuelLogEntry()
      ..supabaseId = json['supabaseId'] ?? ''
      ..boatSupabaseId = json['boatSupabaseId'] ?? ''
      ..date = DateTime.parse(json['date'])
      ..type = json['type'] ?? 'Fuel'
      ..liters = (json['liters'] as num?)?.toDouble() ?? 0.0
      ..pricePerLiter = (json['pricePerLiter'] as num?)?.toDouble() ?? 0.0
      ..totalCost = (json['totalCost'] as num?)?.toDouble() ?? 0.0
      ..notes = json['notes']
      ..isSynced = json['isSynced'] ?? false
      ..lastModified = DateTime.parse(json['lastModified']);
  }

  FuelLogEntry();

  Map<String, dynamic> toJson() => {
    'supabaseId': supabaseId,
    'boatSupabaseId': boatSupabaseId,
    'date': date.toIso8601String(),
    'type': type,
    'liters': liters,
    'pricePerLiter': pricePerLiter,
    'totalCost': totalCost,
    'notes': notes,
    'isSynced': isSynced,
    'lastModified': lastModified.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FuelLogEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          supabaseId == other.supabaseId &&
          boatSupabaseId == other.boatSupabaseId &&
          date == other.date &&
          type == other.type &&
          liters == other.liters &&
          pricePerLiter == other.pricePerLiter &&
          totalCost == other.totalCost &&
          notes == other.notes &&
          isSynced == other.isSynced &&
          lastModified == other.lastModified;

  @override
  int get hashCode => Object.hashAll([
        id,
        supabaseId,
        boatSupabaseId,
        date,
        type,
        liters,
        pricePerLiter,
        totalCost,
        notes,
        isSynced,
        lastModified,
      ]);

  @override
  String toString() => 'FuelLogEntry(id: $id, supabaseId: $supabaseId, '
      'boatSupabaseId: $boatSupabaseId, date: $date, type: $type, '
      'liters: $liters, pricePerLiter: $pricePerLiter, '
      'totalCost: $totalCost, notes: $notes, isSynced: $isSynced, '
      'lastModified: $lastModified)';
}
