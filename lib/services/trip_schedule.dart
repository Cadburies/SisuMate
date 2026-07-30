/// Boarding day has no breakfast (guests arrive mid-day) but does have lunch
/// and dinner, plus a snack; departure day ends before lunch (breakfast
/// only). Middle days get the full breakfast/lunch/dinner set. A 1-day trip
/// falls back to the full set.
List<String> mealTypesForDay(int dayOffset, int numberOfDays) {
  if (numberOfDays <= 1) return const ['breakfast', 'lunch', 'dinner'];
  if (dayOffset == 0) return const ['snack', 'lunch', 'dinner'];
  if (dayOffset == numberOfDays - 1) return const ['breakfast'];
  return const ['breakfast', 'lunch', 'dinner'];
}

int totalSlotsForTrip(int numberOfDays) {
  var total = 0;
  for (var d = 0; d < numberOfDays; d++) {
    total += mealTypesForDay(d, numberOfDays).length;
  }
  return total;
}
