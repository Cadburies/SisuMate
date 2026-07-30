part of 'models.dart';

// Nested data class, stored as JSON inside the Drift MealPlan row.
class MealPlanSlot {
  int dayOffset = 0; // 0=Mon .. 6=Sun, relative to MealPlan.startDate
  String mealType = ''; // breakfast | lunch | dinner
  String recipeSupabaseId = '';
  String recipeName = ''; // denormalized snapshot for display resilience

  MealPlanSlot();

  Map<String, dynamic> toJson() => {
        'dayOffset': dayOffset,
        'mealType': mealType,
        'recipeSupabaseId': recipeSupabaseId,
        'recipeName': recipeName,
      };

  factory MealPlanSlot.fromJson(Map<String, dynamic> json) => MealPlanSlot()
    ..dayOffset = json['dayOffset'] ?? 0
    ..mealType = json['mealType'] ?? ''
    ..recipeSupabaseId = json['recipeSupabaseId'] ?? ''
    ..recipeName = json['recipeName'] ?? '';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealPlanSlot &&
          runtimeType == other.runtimeType &&
          dayOffset == other.dayOffset &&
          mealType == other.mealType &&
          recipeSupabaseId == other.recipeSupabaseId &&
          recipeName == other.recipeName;

  @override
  int get hashCode => Object.hashAll(
      [dayOffset, mealType, recipeSupabaseId, recipeName]);

  @override
  String toString() => 'MealPlanSlot(dayOffset: $dayOffset, '
      'mealType: $mealType, recipeSupabaseId: $recipeSupabaseId, '
      'recipeName: $recipeName)';
}
