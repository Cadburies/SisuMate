import 'dart:convert';
import 'package:drift/drift.dart';
import '../../models/models.dart';
import '../drift/app_database.dart';
import '../../services/trip_schedule.dart';
import '../../domain/repositories/meal_plan_repository.dart';

/// MealPlan on Drift (S1). `guestProfileIds` and the embedded `slots` list are
/// JSON text columns. Local-only.
class MealPlanRepositoryImpl implements MealPlanRepository {
  final AppDatabase _db;
  MealPlanRepositoryImpl(this._db);

  MealPlan _toDomain(MealPlanRow r) {
    final plan = MealPlan()
      ..id = r.id
      ..name = r.name
      ..startDate = r.startDate
      ..numberOfDays = r.numberOfDays
      ..guestCount = r.guestCount
      ..guestProfileIds = (jsonDecode(r.guestProfileIds) as List).cast<int>()
      ..createdAt = r.createdAt
      ..lastModified = r.lastModified
      ..slots = (jsonDecode(r.slots) as List)
          .map((e) => MealPlanSlot.fromJson(e as Map<String, dynamic>))
          .toList();
    // Legacy-safe normalization: a 0 day-count means an old plan; drop slots
    // that fall outside the plan's current shape.
    if (plan.numberOfDays <= 0) plan.numberOfDays = 7;
    plan.slots = plan.slots
        .where((s) =>
            s.dayOffset >= 0 &&
            s.dayOffset < plan.numberOfDays &&
            mealTypesForDay(s.dayOffset, plan.numberOfDays).contains(s.mealType))
        .toList();
    return plan;
  }

  MealPlansCompanion _toCompanion(MealPlan p) => MealPlansCompanion(
        name: Value(p.name),
        startDate: Value(p.startDate),
        numberOfDays: Value(p.numberOfDays),
        guestCount: Value(p.guestCount),
        guestProfileIds: Value(jsonEncode(p.guestProfileIds)),
        slots: Value(jsonEncode(p.slots.map((s) => s.toJson()).toList())),
        createdAt: Value(p.createdAt),
        lastModified: Value(p.lastModified),
      );

  @override
  Stream<List<MealPlan>> watchPlans() {
    return _db.select(_db.mealPlans).watch().map((rows) {
      final all = rows.map(_toDomain).toList();
      return all..sort((a, b) => a.startDate.compareTo(b.startDate));
    });
  }

  @override
  Future<void> addPlan(MealPlan plan) async {
    plan.lastModified = DateTime.now().toUtc();
    await _db.into(_db.mealPlans).insert(_toCompanion(plan));
  }

  @override
  Future<void> updatePlan(MealPlan plan) async {
    plan.lastModified = DateTime.now().toUtc();
    await (_db.update(_db.mealPlans)..where((t) => t.id.equals(plan.id)))
        .write(_toCompanion(plan));
  }

  @override
  Future<void> deletePlan(MealPlan plan) async {
    await (_db.delete(_db.mealPlans)..where((t) => t.id.equals(plan.id))).go();
  }
}
