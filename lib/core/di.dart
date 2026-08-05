import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/database_service.dart';
import '../data/drift/app_database.dart';
import '../services/revenuecat_service.dart';
import '../services/auth_service.dart';
import '../services/boat_enrollment_service.dart';
import '../services/sync_service.dart';
import '../services/suggestion_engine.dart';
import '../services/supabase_remote.dart';
import 'supabase_client.dart';
import '../models/models.dart';
import '../domain/repositories/checklist_repository.dart';
import '../data/repositories/checklist_repository_impl.dart';
import '../domain/repositories/shopping_repository.dart';
import '../data/repositories/shopping_repository_impl.dart';
import '../domain/repositories/recipe_repository.dart';
import '../data/repositories/recipe_repository_impl.dart';
import '../domain/repositories/bar_ingredient_repository.dart';
import '../data/repositories/bar_ingredient_repository_impl.dart';
import '../domain/repositories/pantry_ingredient_repository.dart';
import '../data/repositories/pantry_ingredient_repository_impl.dart';
import '../domain/repositories/guest_profile_repository.dart';
import '../data/repositories/guest_profile_repository_impl.dart';
import '../domain/repositories/meal_plan_repository.dart';
import '../data/repositories/meal_plan_repository_impl.dart';
import '../domain/repositories/collection_repository.dart';
import '../data/repositories/collection_repository_impl.dart';
import '../domain/repositories/captain_log_repository.dart';
import '../data/repositories/captain_log_repository_impl.dart';
import '../domain/repositories/user_settings_repository.dart';
import '../data/repositories/user_settings_repository_impl.dart';
import '../domain/repositories/boat_repository.dart';
import '../data/repositories/boat_repository_impl.dart';
import '../domain/repositories/maintenance_repository.dart';
import '../domain/repositories/community_repository.dart';
import '../data/repositories/community_repository_impl.dart';
import '../data/repositories/maintenance_repository_impl.dart';
import '../domain/repositories/document_repository.dart';
import '../data/repositories/document_repository_impl.dart';
import '../domain/repositories/error_log_repository.dart';
import '../data/repositories/error_log_repository_impl.dart';
import '../domain/repositories/crew_member_repository.dart';
import '../data/repositories/crew_member_repository_impl.dart';
import '../domain/repositories/inventory_item_repository.dart';
import '../data/repositories/inventory_item_repository_impl.dart';
import '../domain/repositories/fuel_log_repository.dart';
import '../data/repositories/fuel_log_repository_impl.dart';
import '../domain/repositories/anchor_watch_repository.dart';
import '../data/repositories/anchor_watch_repository_impl.dart';
import '../data/repositories/sailing_polar_sample_repository.dart';
import '../services/sailing_polar_collector.dart';
import '../services/polar_llm_improve_service.dart';

final databaseServiceProvider =
    Provider<DatabaseService>((ref) => DatabaseService());
final supabaseProvider = Provider<SupabaseClient>(
  (ref) => SupabaseClientWrapper.instance,
);
final revenueCatProvider = Provider<RevenueCatService>(
  (ref) => RevenueCatService(),
);

final authServiceProvider = Provider<AuthService>((ref) => AuthService(ref));
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authState;
});
/// TEST2 seam — live Supabase by default; override in tests with a fake.
final supabaseRemoteProvider =
    Provider<SupabaseRemote>((ref) => const LiveSupabaseRemote());

final syncServiceProvider = Provider<SyncService>((ref) => SyncService(ref));

/// Pending concurrent-edit conflicts (T5).
final pendingConflictsProvider = StreamProvider<List<ConflictLog>>((ref) {
  return ref.watch(syncServiceProvider).watchPendingConflicts();
});

final pendingConflictCountProvider = StreamProvider<int>((ref) {
  return ref.watch(syncServiceProvider).watchPendingConflicts().map((c) => c.length);
});

final maintenanceTasksProvider = StreamProvider<List<MaintenanceTask>>((ref) {
  return ref.watch(maintenanceRepositoryProvider).watchTasks();
});

final captainLogsListProvider = StreamProvider<List<CaptainLogEntry>>((ref) {
  return ref.watch(captainLogRepositoryProvider).watchLogs();
});

/// S4 / BAI7 offline-rules suggestions (maintenance, weather/log cues, fuel).
final boatSuggestionsProvider = Provider<List<BoatSuggestion>>((ref) {
  final tasks = ref.watch(maintenanceTasksProvider).asData?.value ??
      const <MaintenanceTask>[];
  final logs = ref.watch(captainLogsListProvider).asData?.value ??
      const <CaptainLogEntry>[];
  final weatherNotes = logs
      .map((e) => e.weather ?? '')
      .where((w) => w.trim().isNotEmpty)
      .take(8)
      .toList();
  DateTime? lastLogDate;
  for (final e in logs) {
    final d = e.logDate.toUtc();
    if (lastLogDate == null || d.isAfter(lastLogDate)) lastLogDate = d;
  }
  return const SuggestionEngine().build(
    maintenanceTasks: tasks,
    recentWeatherNotes: weatherNotes,
    lastLogDate: lastLogDate,
  );
});

final userSettingsProvider = FutureProvider<UserSettings?>((ref) async {
  final repository = ref.watch(userSettingsRepositoryProvider);
  return await repository.getSettings();
});

final checklistRepositoryProvider = Provider<ChecklistRepository>((ref) {
  return ChecklistRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(syncServiceProvider),
  );
});

final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  return ShoppingRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(syncServiceProvider),
  );
});

final shoppingItemNamesProvider = StreamProvider<Set<String>>((ref) {
  return ref.watch(shoppingRepositoryProvider).watchAllItemNames();
});

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(syncServiceProvider),
  );
});

final syncIngredientCountsProvider = Provider<Future<void> Function()>((ref) {
  return () => ref.read(recipeRepositoryProvider).syncMissingIngredientCounts();
});

final barIngredientRepositoryProvider =
    Provider<BarIngredientRepository>((ref) {
  return BarIngredientRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(syncServiceProvider),
  );
});

final pantryIngredientRepositoryProvider =
    Provider<PantryIngredientRepository>((ref) {
  return PantryIngredientRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(syncServiceProvider),
  );
});

/// The app's Drift database — sole local store as of the S1 migration.
final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);

final guestProfileRepositoryProvider =
    Provider<GuestProfileRepository>((ref) {
  return GuestProfileRepositoryImpl(ref.watch(appDatabaseProvider));
});

final guestProfilesProvider = StreamProvider<List<GuestProfile>>((ref) {
  return ref.watch(guestProfileRepositoryProvider).watchProfiles();
});

final mealPlanRepositoryProvider = Provider<MealPlanRepository>((ref) {
  return MealPlanRepositoryImpl(ref.watch(appDatabaseProvider));
});

final mealPlansProvider = StreamProvider<List<MealPlan>>((ref) {
  return ref.watch(mealPlanRepositoryProvider).watchPlans();
});

final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  return CollectionRepositoryImpl(ref.watch(appDatabaseProvider));
});

final collectionsProvider = StreamProvider<List<RecipeCollection>>((ref) {
  return ref.watch(collectionRepositoryProvider).watchCollections();
});

final captainLogRepositoryProvider = Provider<CaptainLogRepository>((ref) {
  return CaptainLogRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(syncServiceProvider),
  );
});

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(syncServiceProvider),
  );
});

final crewMemberRepositoryProvider = Provider<CrewMemberRepository>((ref) {
  return CrewMemberRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(syncServiceProvider),
  );
});

final inventoryItemRepositoryProvider = Provider<InventoryItemRepository>((ref) {
  return InventoryItemRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(syncServiceProvider),
  );
});

final fuelLogRepositoryProvider = Provider<FuelLogRepository>((ref) {
  return FuelLogRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(syncServiceProvider),
  );
});

final userSettingsRepositoryProvider = Provider<UserSettingsRepository>((ref) {
  return UserSettingsRepositoryImpl(ref.watch(appDatabaseProvider));
});

final anchorWatchRepositoryProvider = Provider<AnchorWatchRepository>((ref) {
  return AnchorWatchRepositoryImpl(ref.watch(appDatabaseProvider));
});

final boatRepositoryProvider = Provider<BoatRepository>((ref) {
  return BoatRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(syncServiceProvider),
  );
});

/// #274 — under-sail polar sample store (local-only).
final sailingPolarSampleRepositoryProvider =
    Provider<SailingPolarSampleRepository>((ref) {
  return SailingPolarSampleRepository(ref.watch(appDatabaseProvider));
});

final sailingPolarCollectorProvider = Provider<SailingPolarCollector>((ref) {
  return SailingPolarCollector(ref.watch(sailingPolarSampleRepositoryProvider));
});

final polarLlmImproveServiceProvider = Provider<PolarLlmImproveService>((ref) {
  return PolarLlmImproveService(
    samples: ref.watch(sailingPolarSampleRepositoryProvider),
    boats: ref.watch(boatRepositoryProvider),
  );
});

final boatEnrollmentServiceProvider = Provider<BoatEnrollmentService>((ref) {
  return BoatEnrollmentService(ref.watch(appDatabaseProvider));
});

final errorLogRepositoryProvider = Provider<ErrorLogRepository>((ref) {
  return ErrorLogRepositoryImpl(ref.watch(appDatabaseProvider));
});

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  return MaintenanceRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(syncServiceProvider),
  );
});

final boatsProvider = FutureProvider<List<Boat>>((ref) async {
  final boatRepository = ref.watch(boatRepositoryProvider);
  return await boatRepository.getBoats();
});

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(syncServiceProvider),
    ref.watch(supabaseRemoteProvider),
  );
});

/// Pending outbox depth — drives the title-bar "Syncing (N)" status suffix.
final syncOutboxCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.select(db.syncOutboxItems).watch().map((rows) => rows.length);
});

/// Pro entitlement — re-emits when RevenueCat customer info changes (PRO2)
/// so purchase/restore/login update Free/Pro UI without manual invalidate.
final isProProvider = StreamProvider<bool>((ref) async* {
  final rc = ref.watch(revenueCatProvider);
  yield await rc.isPro();
  await for (final _ in rc.onCustomerInfoUpdated) {
    yield await rc.isPro();
  }
});

// Toggles hint display in game screens
class _HintModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
}

final hintModeProvider =
    NotifierProvider<_HintModeNotifier, bool>(_HintModeNotifier.new);
