import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'lan_engine.dart';
import 'game_lan_service.dart';
import 'share_lan_service.dart';

/// Single [LanEngine] instance — owns the mDNS + WebSocket transport.
final lanEngineProvider = Provider<LanEngine>((ref) {
  final engine = LanEngine();
  ref.onDispose(engine.dispose);
  return engine;
});

/// Game-specific protocol layer; all multiplayer games share this instance.
final gameLanServiceProvider = Provider<GameLanService>((ref) {
  return GameLanService(ref.read(lanEngineProvider));
});

/// Content-sharing protocol layer; shares one [LanEngine] instance with games.
final shareLanServiceProvider = Provider<ShareLanService>((ref) {
  return ShareLanService(ref.read(lanEngineProvider));
});

/// The peer-id of the local player in a multiplayer game. Null in
/// single-player mode. Shared across every multiplayer game's notifier
/// (previously duplicated per-game — GAME1 generalization).
final localPlayerIdProvider = NotifierProvider<_NullableStringNotifier, String?>(
    _NullableStringNotifier.new);

class _NullableStringNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? value) => state = value;
}
