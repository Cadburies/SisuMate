import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/data/repositories/meal_plan_repository_impl.dart';
import 'package:sisu_mate/models/models.dart';

// MealPlan on Drift (S1); local-only. Slots + guestProfileIds are JSON columns.
void main() {
  late AppDatabase db;
  late MealPlanRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = MealPlanRepositoryImpl(db);
  });

  tearDown(() async => db.close());

  group('MealPlanRepositoryImpl (Drift) CRUD', () {
    test('Create: addPlan persists a new plan', () async {
      await repo.addPlan(MealPlan()
        ..name = 'Weekend Trip'
        ..startDate = DateTime(2026, 7, 10)
        ..numberOfDays = 3);

      final all = await repo.watchPlans().first;
      expect(all, hasLength(1));
      expect(all.single.name, 'Weekend Trip');
      expect(all.single.numberOfDays, 3);
    });

    test('Read: watchPlans emits plans sorted by startDate', () async {
      await repo.addPlan(MealPlan()
        ..name = 'Later Trip'
        ..startDate = DateTime(2026, 8, 1));
      await repo.addPlan(MealPlan()
        ..name = 'Sooner Trip'
        ..startDate = DateTime(2026, 7, 1));

      final plans = await repo.watchPlans().first;
      expect(plans.map((p) => p.name), ['Sooner Trip', 'Later Trip']);
    });

    test('embedded slots + guestProfileIds round-trip through JSON', () async {
      await repo.addPlan(MealPlan()
        ..name = 'Provisioned'
        ..startDate = DateTime(2026, 7, 1)
        ..numberOfDays = 3
        ..guestProfileIds = [1, 2, 3]
        ..slots = [
          MealPlanSlot()
            ..dayOffset = 0
            ..mealType = 'dinner'
            ..recipeName = 'Chili',
        ]);

      final plan = (await repo.watchPlans().first).single;
      expect(plan.guestProfileIds, [1, 2, 3]);
      expect(plan.slots, hasLength(1));
      expect(plan.slots.single.recipeName, 'Chili');
      expect(plan.slots.single.mealType, 'dinner');
    });

    test('Update: updatePlan persists field changes', () async {
      await repo.addPlan(MealPlan()
        ..name = 'Draft Trip'
        ..guestCount = 2);

      final saved = (await repo.watchPlans().first).single;
      saved.guestCount = 6;
      await repo.updatePlan(saved);

      final all = await repo.watchPlans().first;
      expect(all.single.guestCount, 6);
    });

    test('Delete: deletePlan removes it from the database', () async {
      await repo.addPlan(MealPlan()..name = 'To remove');

      final saved = (await repo.watchPlans().first).single;
      await repo.deletePlan(saved);

      expect(await repo.watchPlans().first, isEmpty);
    });
  });
}
