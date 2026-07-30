part of 'models.dart';

// Nested data class, serialized as JSON inside the Drift `recipes.tastingLog`
// column.
class TastingRecord {
  DateTime? tastedAt;
  String? location;
  String? notes;
  int rating = 3; // 1–5 stars

  factory TastingRecord.fromJson(Map<String, dynamic> json) {
    final record = TastingRecord()
      ..location = json['location']
      ..notes = json['notes']
      ..rating = json['rating'] ?? 3;
    final tastedAt = json['tastedAt'];
    if (tastedAt != null) record.tastedAt = DateTime.parse(tastedAt);
    return record;
  }

  TastingRecord();

  Map<String, dynamic> toJson() => {
    'tastedAt': tastedAt?.toIso8601String(),
    'location': location,
    'notes': notes,
    'rating': rating,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TastingRecord &&
          runtimeType == other.runtimeType &&
          tastedAt == other.tastedAt &&
          location == other.location &&
          notes == other.notes &&
          rating == other.rating;

  @override
  int get hashCode => Object.hashAll([tastedAt, location, notes, rating]);

  @override
  String toString() => 'TastingRecord(tastedAt: $tastedAt, '
      'location: $location, notes: $notes, rating: $rating)';
}
