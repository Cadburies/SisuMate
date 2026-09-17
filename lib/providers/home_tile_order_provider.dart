import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ui/home/home_modules.dart';

/// Device-local home-grid order. Not synced — this is a phone home-screen
/// layout, like iOS/Android icon placement.
const kHomeTileOrderPrefsKey = 'home_tile_order_v1';

class HomeTileEditModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void enter() => state = true;

  void exit() => state = false;
}

final homeTileEditModeProvider =
    NotifierProvider<HomeTileEditModeNotifier, bool>(
  HomeTileEditModeNotifier.new,
);

class HomeTileOrderNotifier extends Notifier<List<String>> {
  /// Bumped on every user write so an in-flight prefs read cannot clobber it.
  int _writeGen = 0;
  Future<void>? _hydrateFuture;

  @override
  List<String> build() {
    _hydrateFuture = _hydrate();
    return List<String>.from(HomeModules.defaultIds);
  }

  Future<void> _hydrate() async {
    final gen = _writeGen;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!ref.mounted || gen != _writeGen) return;
      state = HomeModules.merge(prefs.getStringList(kHomeTileOrderPrefsKey));
    } catch (_) {
      // Plugin absent in some host tests — keep catalog default.
    }
  }

  /// Wait until the first prefs read finishes (tests).
  @visibleForTesting
  Future<void> loadFromPrefs() async {
    await _hydrateFuture;
  }

  Future<void> moveIdTo(String id, int toIndex) async {
    final next = HomeModules.moveIdTo(state, id, toIndex);
    if (listEquals(next, state)) return;
    _writeGen++;
    state = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(kHomeTileOrderPrefsKey, next);
    } catch (_) {
      // Same as hydrate: host tests without the plugin keep the in-memory order.
    }
  }
}

final homeTileOrderProvider =
    NotifierProvider<HomeTileOrderNotifier, List<String>>(
  HomeTileOrderNotifier.new,
);
