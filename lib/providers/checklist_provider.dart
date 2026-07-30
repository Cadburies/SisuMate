import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../core/di.dart';

// Service is replaced by Repository usage, but we can keep a provider for easy access if needed
// or just access repository directly in UI commands.

final checklistGroupsProvider =
    StreamProvider.family<List<ChecklistGroup>, String?>((ref, appType) {
      final repository = ref.watch(checklistRepositoryProvider);
      return repository.watchGroups(appType: appType);
    });

final checklistItemsProvider =
    StreamProvider.family<List<ChecklistItem>, String>((ref, groupSupabaseId) {
      final repository = ref.watch(checklistRepositoryProvider);
      return repository.watchItems(groupSupabaseId);
    });
