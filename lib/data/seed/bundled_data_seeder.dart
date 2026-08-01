import 'package:drift/drift.dart';
import '../drift/app_database.dart';
import 'shopping_seeder.dart';
import 'seed_watch_checks.dart';
import 'seed_annual_checks.dart';
import 'seed_last_minute_checks.dart';
import 'seed_long_trip_safety_briefing.dart';
import 'seed_one_day_checks.dart';
import 'seed_one_week_checks.dart';
import 'seed_yanmar_4jh45_50_hours_service.dart';
import 'seed_yanmar_4jh45_250_hours_service.dart';
import 'seed_yanmar_4jh45_500_hours_service.dart';
import 'seed_yanmar_4jh45_1000_hours_service.dart';
import 'seed_documents_checks.dart';
import 'seed_day_trip_safety_briefing.dart';
import 'seed_daily_engine_checks.dart';
import 'seed_weekly_checks.dart';
import 'seed_monthly_checks.dart';
import 'seed_recipes.dart';
import '../../models/models.dart';

const _defaultBoatSupabaseId = '00000000-0000-0000-0000-000000000000';

Future<void> seedBundledData() async {
  // Skip if bundled data already exists to prevent duplicates (Drift-backed
  // seed sentinel).
  final db = AppDatabase.instance;
  if ((await db.select(db.checklistGroups).get()).isNotEmpty) return;

  // ===================================================================
  // 1. Default Boat (Free users get one boat automatically)
  // ===================================================================
  final defaultBoat = Boat()
    ..supabaseId = _defaultBoatSupabaseId // special UUID = local-only
    ..name = 'My Boat'
    ..photoUrl = null;
  await db.into(db.boats).insert(
        BoatsCompanion.insert(
          supabaseId: Value(defaultBoat.supabaseId),
          name: Value(defaultBoat.name),
        ),
        mode: InsertMode.insertOrIgnore,
      );

  // Seed checklists and shopping data (all Drift-backed now).
  await seedWatchChecks(defaultBoat.supabaseId);
  await seedAnnualChecks(defaultBoat.supabaseId);
  await seedLastMinuteChecks(defaultBoat.supabaseId);
  await seedLongTripSafetyBriefing(defaultBoat.supabaseId);
  await seedOneDayChecks(defaultBoat.supabaseId);
  await seedOneWeekChecks(defaultBoat.supabaseId);
  await seedYanmar_4JH45_50HoursService(defaultBoat.supabaseId);
  await seedYanmar_4JH45_250HoursService(defaultBoat.supabaseId);
  await seedYanmar_4JH45_500HoursService(defaultBoat.supabaseId);
  await seedYanmar_4JH45_1000HoursService(defaultBoat.supabaseId);
  await seedDocumentsChecks(defaultBoat.supabaseId);
  await seedDayTripSafetyBriefing(defaultBoat.supabaseId);
  await seedDailyEngineChecks(defaultBoat.supabaseId);
  await seedWeeklyChecks(defaultBoat.supabaseId);
  await seedMonthlyChecks(defaultBoat.supabaseId);
  await seedShoppingData(defaultBoat.supabaseId);

  // Carries its own guards / stale-purge logic. Bar/pantry ingredients and
  // the rest of the catalog packs live in seed_expansion_catalog.dart, called
  // from DatabaseService.runDeferredSeeds() - not here (one call site each).
  await seedRecipes(_defaultBoatSupabaseId);
}
