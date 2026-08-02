import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/di.dart';
import '../models/models.dart';
import '../services/fuel_burn_estimator.dart';
import '../services/suggestion_engine.dart';
import '../services/weather_service.dart';
import '../ui/fuel/fuel_screen.dart' show fuelLogEntriesProvider;

/// BAI1: every checklist item across all `appType == 'safety'` groups,
/// combined for the passage-readiness score.
///
/// #207: was a plain Provider watching one `checklistItemsProvider(groupId)`
/// family instance per safety group in a loop — each of those independently
/// re-filters the *same* whole-table watch, so any single checklist_items
/// write anywhere in the app re-emitted every mounted instance near-
/// simultaneously, cascading into this provider (and its dependent
/// passageReadinessProvider) disposing/rebuilding multiple times in the same
/// frame. That cascade landing exactly when HomeScreen.build was watching
/// passageReadinessProvider is what produced the "setState() called during
/// build" crash. A single repository-level watch removes both the
/// redundant recomputation and the multi-provider simultaneous-rebuild
/// cascade that made the race likely enough to actually hit.
final safetyChecklistItemsProvider = StreamProvider<List<ChecklistItem>>((ref) {
  final repository = ref.watch(checklistRepositoryProvider);
  return repository.watchItemsForAppType('safety');
});

/// BAI1: last cached weather bundle — reads local cache only, never fetches.
final cachedWeatherProvider = FutureProvider<WeatherBundle?>((ref) {
  return WeatherService().loadCache();
});

/// BAI1: "Ready for passage?" verdict combining safety checklist completion,
/// maintenance overdue, cached weather, and fuel/water runway.
final passageReadinessProvider = Provider<PassageReadiness>((ref) {
  final safetyItems = ref.watch(safetyChecklistItemsProvider).asData?.value ??
      const <ChecklistItem>[];
  final maintenanceTasks = ref.watch(maintenanceTasksProvider).asData?.value ??
      const <MaintenanceTask>[];
  final weather = ref.watch(cachedWeatherProvider).asData?.value;
  final fuelEntries = ref.watch(fuelLogEntriesProvider).asData?.value ??
      const <FuelLogEntry>[];
  final fuelEstimates = const FuelBurnEstimator().estimate(entries: fuelEntries);

  return const SuggestionEngine().passageReadiness(
    safetyItems: safetyItems,
    maintenanceTasks: maintenanceTasks,
    weather: weather,
    fuelEstimates: fuelEstimates,
  );
});
