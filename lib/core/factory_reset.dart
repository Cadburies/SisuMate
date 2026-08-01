import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/shopping_provider.dart';
import 'di.dart';

/// TEST29: after [DatabaseService.factoryReset], FutureProviders that cached
/// pre-wipe rows must reload. StreamProviders over Drift usually re-emit on
/// their own; these FutureProviders do not.
///
/// Call from every UI path that runs factory reset (settings, drawer, …).
void invalidateAfterFactoryReset(WidgetRef ref) {
  ref.invalidate(userSettingsProvider);
  ref.invalidate(boatsProvider);
  ref.invalidate(activeBoatProvider);
  ref.invalidate(captainLogsListProvider);
}

/// Same invalidations for unit tests that hold a [ProviderContainer].
void invalidateAfterFactoryResetContainer(ProviderContainer container) {
  container.invalidate(userSettingsProvider);
  container.invalidate(boatsProvider);
  container.invalidate(activeBoatProvider);
  container.invalidate(captainLogsListProvider);
}
