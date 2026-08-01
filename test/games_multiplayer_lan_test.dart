import 'package:bonsoir/bonsoir.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/game_ai/game_ai_difficulty.dart';
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

  group('TEST7 multi-seat host + clients', () {
    test('host can join three human clients and sees all in lobby', () async {
      final hostEngine = FakeLanEngine();
      final c1 = FakeLanEngine();
      final c2 = FakeLanEngine();
      final c3 = FakeLanEngine();
      hostEngine.connectClient(c1, clientPeerId: 'peer_1');
      hostEngine.connectClient(c2, clientPeerId: 'peer_2');
      hostEngine.connectClient(c3, clientPeerId: 'peer_3');
      expect(hostEngine.connectedClientCount, 3);

      final host = GameLanService(hostEngine);
      final client1 = GameLanService(c1);
      final client2 = GameLanService(c2);
      final client3 = GameLanService(c3);

      await host.hostGame(gameName: '4-up', hostPlayerName: 'Skipper');
      final dummy =
          BonsoirService(name: '4-up', type: '_sisumate._tcp', port: 0);
      await client1.joinGame(service: dummy, playerName: 'Mate1');
      await client2.joinGame(service: dummy, playerName: 'Mate2');
      await client3.joinGame(service: dummy, playerName: 'Mate3');
      await flush();

      expect(host.lobbyPlayers.map((p) => p.name).toSet(),
          {'Skipper', 'Mate1', 'Mate2', 'Mate3'});
      expect(client1.myAssignedId, 'peer_1');
      expect(client2.myAssignedId, 'peer_2');
      expect(client3.myAssignedId, 'peer_3');
    });

    test('broadcastState reaches every connected client', () async {
      final hostEngine = FakeLanEngine();
      final c1 = FakeLanEngine();
      final c2 = FakeLanEngine();
      hostEngine.connectClient(c1, clientPeerId: 'peer_1');
      hostEngine.connectClient(c2, clientPeerId: 'peer_2');
      final host = GameLanService(hostEngine);
      final client1 = GameLanService(c1);
      final client2 = GameLanService(c2);

      await host.hostGame(gameName: 'Bcast', hostPlayerName: 'H');
      final dummy =
          BonsoirService(name: 'Bcast', type: '_sisumate._tcp', port: 0);
      await client1.joinGame(service: dummy, playerName: 'A');
      await client2.joinGame(service: dummy, playerName: 'B');
      await flush();

      final f1 = client1.remoteStates.first;
      final f2 = client2.remoteStates.first;
      host.broadcastState({'round': 7, 'seat': 'all'});
      final s1 = await f1;
      final s2 = await f2;
      expect(s1, {'round': 7, 'seat': 'all'});
      expect(s2, {'round': 7, 'seat': 'all'});
    });

    test('moves from two clients both arrive at host with correct peer ids',
        () async {
      final hostEngine = FakeLanEngine();
      final c1 = FakeLanEngine();
      final c2 = FakeLanEngine();
      hostEngine.connectClient(c1, clientPeerId: 'peer_1');
      hostEngine.connectClient(c2, clientPeerId: 'peer_2');
      final host = GameLanService(hostEngine);
      final client1 = GameLanService(c1);
      final client2 = GameLanService(c2);

      await host.hostGame(gameName: 'Moves', hostPlayerName: 'H');
      final dummy =
          BonsoirService(name: 'Moves', type: '_sisumate._tcp', port: 0);
      await client1.joinGame(service: dummy, playerName: 'A');
      await client2.joinGame(service: dummy, playerName: 'B');
      await flush();

      final moves = <({String peerId, String action, Map<String, dynamic> data})>[];
      final sub = host.incomingMoves.listen(moves.add);

      client1.sendMove('declareBid', {'q': 1});
      client2.sendMove('declareBid', {'q': 2});
      await flush();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(moves.map((m) => m.peerId).toSet(), {'peer_1', 'peer_2'});
      expect(moves.map((m) => m.data['q']).toSet(), {1, 2});
      await sub.cancel();
    });

    test('AI seats coexist with human clients in lobby roster', () async {
      final hostEngine = FakeLanEngine();
      final c1 = FakeLanEngine();
      hostEngine.connectClient(c1, clientPeerId: 'peer_1');
      final host = GameLanService(hostEngine);
      final client1 = GameLanService(c1);

      await host.hostGame(gameName: 'AI+Human', hostPlayerName: 'Host');
      final dummy =
          BonsoirService(name: 'AI+Human', type: '_sisumate._tcp', port: 0);
      await client1.joinGame(service: dummy, playerName: 'Human');
      await flush();

      host.addLocalPlayer(const LobbyPlayer(
        id: 'ai_1',
        name: 'AI 1 (Hard)',
        isAI: true,
        aiDifficulty: GameAiDifficulty.hard,
      ));
      await flush();

      expect(host.lobbyPlayers.where((p) => p.isAI), hasLength(1));
      expect(host.lobbyPlayers.where((p) => !p.isAI), hasLength(2));
      expect(
        host.lobbyPlayers.firstWhere((p) => p.isAI).aiDifficulty,
        GameAiDifficulty.hard,
      );
      // Client lobby mirror receives AI seat via lobby broadcast.
      expect(client1.lobbyPlayers.any((p) => p.isAI), isTrue);
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
