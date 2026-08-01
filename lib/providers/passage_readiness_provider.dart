import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/di.dart';
import '../models/models.dart';
import '../services/fuel_burn_estimator.dart';
import '../services/suggestion_engine.dart';
import '../services/weather_service.dart';
import '../ui/fuel/fuel_screen.dart' show fuelLogEntriesProvider;
import 'checklist_provider.dart';

/// BAI1: every checklist item across all `appType == 'safety'` groups,
/// combined for the passage-readiness score.
final safetyChecklistItemsProvider = Provider<List<ChecklistItem>>((ref) {
  final groups = ref.watch(checklistGroupsProvider('safety')).asData?.value ??
      const <ChecklistGroup>[];
  final items = <ChecklistItem>[];
  for (final g in groups) {
    items.addAll(
      ref.watch(checklistItemsProvider(g.supabaseId)).asData?.value ??
          const <ChecklistItem>[],
    );
  }
  return items;
});

/// BAI1: last cached weather bundle — reads local cache only, never fetches.
final cachedWeatherProvider = FutureProvider<WeatherBundle?>((ref) {
  return WeatherService().loadCache();
});

/// BAI1: "Ready for passage?" verdict combining safety checklist completion,
/// maintenance overdue, cached weather, and fuel/water runway.
final passageReadinessProvider = Provider<PassageReadiness>((ref) {
  final safetyItems = ref.watch(safetyChecklistItemsProvider);
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
