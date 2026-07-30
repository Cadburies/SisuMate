part of 'models.dart';

class MealPlan {
  int id = 0;
  String name = '';
  DateTime startDate = DateTime.now(); // Any day — trips don't have to start on a Monday
  int numberOfDays = 7; // Arbitrary trip length, not locked to a 7-day week
  int guestCount = 4;
  List<int> guestProfileIds = []; // GuestProfile.id references
  DateTime createdAt = DateTime.now();
  DateTime lastModified = DateTime.now().toUtc();
  List<MealPlanSlot> slots = [];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealPlan &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          startDate == other.startDate &&
          numberOfDays == other.numberOfDays &&
          guestCount == other.guestCount &&
          listEquals(guestProfileIds, other.guestProfileIds) &&
          createdAt == other.createdAt &&
          lastModified == other.lastModified &&
          listEquals(slots, other.slots);

  @override
  int get hashCode => Object.hashAll([
        id,
        name,
        startDate,
        numberOfDays,
        guestCount,
        Object.hashAll(guestProfileIds),
        createdAt,
        lastModified,
        Object.hashAll(slots),
      ]);

  @override
  String toString() => 'MealPlan(id: $id, name: $name, '
      'startDate: $startDate, numberOfDays: $numberOfDays, '
      'guestCount: $guestCount, guestProfileIds: $guestProfileIds, '
      'createdAt: $createdAt, lastModified: $lastModified, slots: $slots)';
}
