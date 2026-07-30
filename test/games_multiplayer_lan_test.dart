import 'package:bonsoir/bonsoir.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/lan/game_lan_service.dart';

import 'test_helpers/fake_lan_engine.dart';

/// End-to-end coverage of [GameLanService]'s message-passing over a fake
/// [FakeLanEngine] pair — the join handshake, state broadcast, moves, and
/// mid-game disconnect grace window that today are only verified by live
/// adb/idb device scripts (`scripts/liars_dice_4sim_setup.sh`).
void main() {
  Future<void> flush() => Future.delayed(Duration.zero);

  late FakeLanEngine hostEngine;
  late FakeLanEngine clientEngine;
  late GameLanService hostService;
  late GameLanService clientService;

  setUp(() {
    hostEngine = FakeLanEngine();
    clientEngine = FakeLanEngine();
    hostEngine.connectClient(clientEngine, clientPeerId: 'peer_1');
    hostService = GameLanService(hostEngine);
    clientService = GameLanService(clientEngine);
  });

  Future<void> joinAsClient({String playerName = 'Mate'}) async {
    await hostService.hostGame(gameName: 'Test Game', hostPlayerName: 'Skipper');
    final dummyService =
        BonsoirService(name: 'Test Game', type: '_sisumate._tcp', port: 0);
    await clientService.joinGame(service: dummyService, playerName: playerName);
    await flush();
  }

  group('Join handshake', () {
    test('host sees the client join and the client gets its assigned id',
        () async {
      await joinAsClient();

      expect(hostService.lobbyPlayers.map((p) => p.name), contains('Mate'));
      expect(clientService.myAssignedId, 'peer_1');
    });
  });

  group('Game start + state broadcast', () {
    test('startGame fires gameStarted on the client', () async {
      await joinAsClient();

      final startedFuture = clientService.gameStarted.first;
      hostService.startGame();
      await startedFuture;
      // Reaching here without timing out proves the event fired.
    });

    test('broadcastState delivers the same JSON to the client', () async {
      await joinAsClient();

      final stateFuture = clientService.remoteStates.first;
      hostService.broadcastState({'round': 1, 'bid': null});
      final received = await stateFuture;

      expect(received, {'round': 1, 'bid': null});
    });
  });

  group('Moves', () {
    test('a client move arrives at the host with the assigned peer id',
        () async {
      await joinAsClient();

      final moveFuture = hostService.incomingMoves.first;
      clientService.sendMove('declareBid', {'quantity': 3, 'face': 4});
      final move = await moveFuture;

      expect(move.peerId, 'peer_1');
      expect(move.action, 'declareBid');
      expect(move.data, {'quantity': 3, 'face': 4});
    });
  });

  group('Mid-game disconnect grace (LT7)', () {
    test(
        'a dropped seat is held in pendingReconnectPeerIds and only leaves '
        'after the grace window elapses', () {
      fakeAsync((async) {
        // Built inside the fake zone (not setUp's real zone) so the
        // reconnect-grace Timer that GameLanService schedules internally is
        // one `async.elapse` can actually control — a Stream's listener
        // callback runs in whatever zone was current at `.listen()` time,
        // not at event-delivery time.
        final hostEngine = FakeLanEngine();
        final clientEngine = FakeLanEngine();
        hostEngine.connectClient(clientEngine, clientPeerId: 'peer_1');
        final hostService = GameLanService(hostEngine);
        final clientService = GameLanService(clientEngine);

        hostService.hostGame(gameName: 'Test Game', hostPlayerName: 'Skipper');
        async.flushMicrotasks();

        final dummyService =
            BonsoirService(name: 'Test Game', type: '_sisumate._tcp', port: 0);
        clientService.joinGame(service: dummyService, playerName: 'Mate');
        async.flushMicrotasks();

        hostService.startGame();
        async.flushMicrotasks();

        var leftPeerId = '';
        hostService.playerLeaves.listen((id) => leftPeerId = id);

        clientEngine.disconnect();
        async.flushMicrotasks();

        expect(hostService.pendingReconnectPeerIds, contains('peer_1'));
        expect(leftPeerId, isEmpty,
            reason: 'a mid-game drop must not immediately vacate the seat');

        async.elapse(kMidGameReconnectGrace + const Duration(seconds: 1));

        expect(hostService.pendingReconnectPeerIds, isNot(contains('peer_1')));
        expect(leftPeerId, 'peer_1');
      });
    });
  });
}
