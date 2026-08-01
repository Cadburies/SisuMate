import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/di.dart';
import '../models/models.dart';
import '../services/suggestion_engine.dart';
import 'checklist_provider.dart';
import 'passage_readiness_provider.dart' show cachedWeatherProvider;

/// BAI3: days until the nearest upcoming (not yet finished) trip's
/// departure, and that trip's length — same "nearest upcoming plan" pick as
/// the BAI2 shopping-priority provider. Null when there's no such plan.
final nearestTripProvider = Provider<({int daysUntil, int lengthDays})?>((ref) {
  final plans = ref.watch(mealPlansProvider).asData?.value ?? const <MealPlan>[];
  if (plans.isEmpty) return null;

  final now = DateTime.now();
  MealPlan? nearest;
  for (final p in plans) {
    final ends = p.startDate.add(Duration(days: p.numberOfDays));
    if (ends.isBefore(now)) continue; // already over
    if (nearest == null || p.startDate.isBefore(nearest.startDate)) {
      nearest = p;
    }
  }
  if (nearest == null) return null;

  return (
    daysUntil: nearest.startDate.difference(now).inDays,
    lengthDays: nearest.numberOfDays,
  );
});

/// BAI3: which checklist groups to run next, for the Checklists screen banner.
final checklistAutopilotProvider =
    Provider<List<ChecklistAutopilotSuggestion>>((ref) {
  final groups = ref.watch(checklistGroupsProvider('checklist')).asData?.value ??
      const <ChecklistGroup>[];
  final trip = ref.watch(nearestTripProvider);
  final weather = ref.watch(cachedWeatherProvider).asData?.value;

  return const SuggestionEngine().checklistAutopilot(
    checklistGroups: groups,
    daysUntilDeparture: trip?.daysUntil,
    tripLengthDays: trip?.lengthDays,
    weather: weather,
  );
});
