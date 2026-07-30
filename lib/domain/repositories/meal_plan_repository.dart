import '../../models/models.dart';

abstract class MealPlanRepository {
  Stream<List<MealPlan>> watchPlans();
  Future<void> addPlan(MealPlan plan);
  Future<void> updatePlan(MealPlan plan);
  Future<void> deletePlan(MealPlan plan);
}
