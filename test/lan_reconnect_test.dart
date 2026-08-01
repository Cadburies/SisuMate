import 'dart:async';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/game_ai/game_ai_difficulty.dart';
import 'package:sisu_mate/services/game_ai/game_ai_persona.dart';
import 'package:sisu_mate/services/lan/game_lan_service.dart';
import 'package:sisu_mate/services/lan/lan_engine.dart';
import 'package:sisu_mate/services/lan/lan_message.dart';

import 'test_helpers/fake_lan_engine.dart';

// Covers F6 client reconnect helpers and LT7 mid-game same-seat rejoin.
// Full mDNS discovery is not required — host binds a real WebSocket server
// and clients connect by hostPort.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('LanEngine.reconnectToLastHost (F6)', () {
    test('returns false when nothing has ever been connected', () async {
      final engine = LanEngine();
      final result = await engine.reconnectToLastHost();
      expect(result, isFalse);
    });

    test('rebindPeerId returns false when ephemeral id is unknown', () {
      final engine = LanEngine();
      expect(engine.rebindPeerId('peer_1', 'peer_old'), isFalse);
    });
  });

  group('GameLanService.reconnect (F6)', () {
    test('returns false when joinGame was never called', () async {
      final service = GameLanService(LanEngine());
      final result = await service.reconnect();
      expect(result, isFalse);
    });

    test('myPlayerName is null until joinGame is called', () {
      final service = GameLanService(LanEngine());
      expect(service.myPlayerName, isNull);
    });
  });

  group('LobbyPlayer.isAI', () {
    test('defaults to false and round-trips through toJson/fromJson', () {
      const human = LobbyPlayer(id: 'host', name: 'Host');
      expect(human.isAI, isFalse);
      expect(LobbyPlayer.fromJson(human.toJson()).isAI, isFalse);

      const bot = LobbyPlayer(id: 'ai_1', name: 'AI 1', isAI: true);
      expect(LobbyPlayer.fromJson(bot.toJson()).isAI, isTrue);
    });

    test('fromJson defaults isAI to false when the key is missing', () {
      final legacy = LobbyPlayer.fromJson({'id': 'peer_1', 'name': 'Alex'});
      expect(legacy.isAI, isFalse);
    });

    test('GAI5 aiPersona round-trips and defaults to balanced', () {
      const bot = LobbyPlayer(
        id: 'ai_1',
        name: 'Bluffer 1 (Hard)',
        isAI: true,
        aiDifficulty: GameAiDifficulty.hard,
        aiPersona: GameAiPersona.aggressive,
      );
      final round = LobbyPlayer.fromJson(bot.toJson());
      expect(round.aiPersona, GameAiPersona.aggressive);
      expect(round.aiDifficulty, GameAiDifficulty.hard);
      expect(round.toJson()['aiPersona'], 'aggressive');

      final legacy = LobbyPlayer.fromJson(
          {'id': 'ai_x', 'name': 'AI', 'isAI': true});
      expect(legacy.aiPersona, GameAiPersona.balanced);
    });
  });

  group('GameLanService.addLocalPlayer / removeLocalPlayer (host-only)', () {
    test('adding then removing a local AI seat updates lobbyPlayers', () async {
      final service = GameLanService(LanEngine());
      try {
        await service.hostGame(gameName: 'Test Game', hostPlayerName: 'Host');
      } catch (_) {}

      service.addLocalPlayer(
          const LobbyPlayer(id: 'ai_1', name: 'AI 1', isAI: true));
      expect(service.lobbyPlayers.map((p) => p.id), contains('ai_1'));
      expect(
          service.lobbyPlayers.firstWhere((p) => p.id == 'ai_1').isAI, isTrue);

      service.removeLocalPlayer('ai_1');
      expect(service.lobbyPlayers.map((p) => p.id), isNot(contains('ai_1')));
      await service.endSession();
    });
  });

  group('LT7 mid-game same-seat rejoin', () {
    test('grace constant is 15 seconds', () {
      expect(kMidGameReconnectGrace, const Duration(seconds: 15));
    });

    test(
        'client that drops mid-game and rejoins under the same name keeps '
        'the same peer id and receives the last broadcast state', () async {
      final hostEngine = LanEngine();
      final host = GameLanService(hostEngine);

      // Host without mDNS if possible — startHost binds HTTP first.
      try {
        await host.hostGame(gameName: 'LT7 Poker', hostPlayerName: 'Host');
      } catch (_) {
        // mDNS may fail in unit-test env; WebSocket server may still be up.
      }
      final port = hostEngine.hostPort;
      expect(port, isNotNull,
          reason: 'host must bind a WebSocket port even if mDNS fails');

      // Client A connects + joins.
      final clientA = await WebSocket.connect('ws://127.0.0.1:$port');
      final welcomeA = Completer<String>();
      final statesA = <Map<String, dynamic>>[];
      clientA.listen((data) {
        if (data is! String) return;
        final msg = LanMessage.decode(data);
        if (msg.type == 'welcome') {
          welcomeA.complete(msg.payload['yourId'] as String);
        }
        if (msg.type == 'state') {
          statesA.add(Map<String, dynamic>.from(msg.payload));
        }
      });
      // Allow host attach to register the peer.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      clientA.add(LanMessage(
        channel: 'game',
        type: 'join',
        payload: {'name': 'Alex'},
      ).encode());

      final peerId = await welcomeA.future.timeout(const Duration(seconds: 2));
      expect(peerId, startsWith('peer_'));
      expect(host.lobbyPlayers.map((p) => p.name), contains('Alex'));

      host.startGame();
      host.broadcastState({
        'phase': 'betting1',
        'pot': 40,
        'marker': 'pre-drop',
      });
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(statesA, isNotEmpty);
      expect(statesA.last['marker'], 'pre-drop');

      // Drop client A — host should reserve the seat (no leave until grace).
      final leaveEvents = <String>[];
      final leaveSub = host.playerLeaves.listen(leaveEvents.add);
      await clientA.close();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(host.pendingReconnectPeerIds, contains(peerId));
      expect(leaveEvents, isEmpty,
          reason: 'leave must be deferred during reconnect grace');
      expect(host.lobbyPlayers.map((p) => p.id), contains(peerId));

      // Client B reconnects with same name + preferredId (simulates reconnect()).
      final clientB = await WebSocket.connect('ws://127.0.0.1:$port');
      final welcomeB = Completer<String>();
      final statesB = <Map<String, dynamic>>[];
      final rejoinEvents = <LobbyPlayer>[];
      final rejoinSub = host.playerRejoins.listen(rejoinEvents.add);
      clientB.listen((data) {
        if (data is! String) return;
        final msg = LanMessage.decode(data);
        if (msg.type == 'welcome') {
          welcomeB.complete(msg.payload['yourId'] as String);
        }
        if (msg.type == 'state') {
          statesB.add(Map<String, dynamic>.from(msg.payload));
        }
      });
      await Future<void>.delayed(const Duration(milliseconds: 50));
      clientB.add(LanMessage(
        channel: 'game',
        type: 'join',
        payload: {'name': 'Alex', 'preferredId': peerId},
      ).encode());

      final rejoinId =
          await welcomeB.future.timeout(const Duration(seconds: 2));
      expect(rejoinId, peerId,
          reason: 'must rebind to the original seat id, not mint peer_N+1');
      expect(host.pendingReconnectPeerIds, isEmpty);
      expect(rejoinEvents.map((p) => p.id), contains(peerId));
      expect(statesB, isNotEmpty,
          reason: 'host must push last broadcast state on rejoin');
      expect(statesB.last['marker'], 'pre-drop');
      expect(leaveEvents, isEmpty);

      // Moves from the rebound socket must still carry the stable peer id.
      final moves = <String>[];
      final moveSub = host.incomingMoves.listen((m) => moves.add(m.peerId));
      clientB.add(LanMessage(
        channel: 'game',
        type: 'move',
        payload: {
          'action': 'check',
          'data': <String, dynamic>{},
        },
      ).encode());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(moves, contains(peerId));

      await leaveSub.cancel();
      await rejoinSub.cancel();
      await moveSub.cancel();
      await clientB.close();
      await host.endSession();
    });

    test(
        'mid-game join with a brand-new name is not admitted (no new seat)',
        () async {
      final hostEngine = LanEngine();
      final host = GameLanService(hostEngine);
      try {
        await host.hostGame(gameName: 'LT7 Gate', hostPlayerName: 'Host');
      } catch (_) {}
      final port = hostEngine.hostPort!;
      host.startGame();

      final stranger = await WebSocket.connect('ws://127.0.0.1:$port');
      final welcomes = <String>[];
      stranger.listen((data) {
        if (data is! String) return;
        final msg = LanMessage.decode(data);
        if (msg.type == 'welcome') {
          welcomes.add(msg.payload['yourId'] as String);
        }
      });
      await Future<void>.delayed(const Duration(milliseconds: 50));
      stranger.add(LanMessage(
        channel: 'game',
        type: 'join',
        payload: {'name': 'Stranger'},
      ).encode());
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(welcomes, isEmpty, reason: 'no welcome for late strangers');
      expect(host.lobbyPlayers.map((p) => p.name), isNot(contains('Stranger')));

      await stranger.close();
      await host.endSession();
    });

    test(
        'when reconnect grace expires, playerLeaves fires and seat is released',
        () async {
      final hostEngine = LanEngine();
      final host = GameLanService(hostEngine);
      try {
        await host.hostGame(gameName: 'LT7 Grace', hostPlayerName: 'Host');
      } catch (_) {}
      final port = hostEngine.hostPort!;

      final client = await WebSocket.connect('ws://127.0.0.1:$port');
      final welcome = Completer<String>();
      client.listen((data) {
        if (data is! String) return;
        final msg = LanMessage.decode(data);
        if (msg.type == 'welcome') {
          welcome.complete(msg.payload['yourId'] as String);
        }
      });
      await Future<void>.delayed(const Duration(milliseconds: 50));
      client.add(LanMessage(
        channel: 'game',
        type: 'join',
        payload: {'name': 'Bob'},
      ).encode());
      final peerId = await welcome.future.timeout(const Duration(seconds: 2));
      host.startGame();

      final leaves = <String>[];
      final sub = host.playerLeaves.listen(leaves.add);

      await client.close();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(host.pendingReconnectPeerIds, contains(peerId));
      expect(leaves, isEmpty);

      // Real wall-clock grace (15s) — acceptable for this one coverage test.
      await Future<void>.delayed(
          kMidGameReconnectGrace + const Duration(milliseconds: 200));
      expect(leaves, contains(peerId));
      expect(host.pendingReconnectPeerIds, isEmpty);
      expect(host.lobbyPlayers.map((p) => p.id), isNot(contains(peerId)));

      await sub.cancel();
      await host.endSession();
    }, timeout: const Timeout(Duration(seconds: 25)));
  });

  group('LT7 rejoin client-side entry (TEST18)', () {
    Future<void> flush() =>
        Future<void>.delayed(const Duration(milliseconds: 50));

    test(
        'pre-game welcome alone does not fire gameStarted (only start does)',
        () async {
      final hostEngine = FakeLanEngine();
      final clientEngine = FakeLanEngine();
      hostEngine.connectClient(clientEngine, clientPeerId: 'peer_1');
      final host = GameLanService(hostEngine);
      final client = GameLanService(clientEngine);

      await host.hostGame(gameName: 'LT7 Lobby', hostPlayerName: 'Skipper');
      final dummy =
          BonsoirService(name: 'LT7 Lobby', type: '_sisumate._tcp', port: 0);

      var started = 0;
      final sub = client.gameStarted.listen((_) => started++);
      await client.joinGame(service: dummy, playerName: 'Alex');
      await flush();
      expect(started, 0,
          reason: 'lobby welcome must not route the client into the game');
      expect(client.myAssignedId, 'peer_1');

      host.startGame();
      await flush();
      expect(started, 1);

      await sub.cancel();
      await host.endSession();
    });

    test(
        'mid-game rejoin fires gameStarted off the welcome and replays the '
        'last state to a late remoteStates subscriber', () async {
      final hostEngine = FakeLanEngine();
      final clientEngine = FakeLanEngine();
      hostEngine.connectClient(clientEngine, clientPeerId: 'peer_1');
      final host = GameLanService(hostEngine);
      final client = GameLanService(clientEngine);

      await host.hostGame(gameName: 'LT7 Rejoin', hostPlayerName: 'Skipper');
      final dummy =
          BonsoirService(name: 'LT7 Rejoin', type: '_sisumate._tcp', port: 0);
      await client.joinGame(service: dummy, playerName: 'Alex');
      await flush();

      host.startGame();
      host.broadcastState({'phase': 'declare', 'marker': 'pre-drop'});
      await flush();

      // App killed on the client: host reserves the seat; nothing but the
      // player name carries over to the "relaunched" client below.
      clientEngine.disconnect();
      await flush();
      expect(host.pendingReconnectPeerIds, contains('peer_1'));

      final clientEngine2 = FakeLanEngine();
      hostEngine.connectClient(clientEngine2, clientPeerId: 'peer_9');
      final client2 = GameLanService(clientEngine2);

      var started = 0;
      final startSub = client2.gameStarted.listen((_) => started++);
      await client2.joinGame(service: dummy, playerName: 'Alex');
      await flush();

      expect(started, 1,
          reason:
              'rejoin welcome (inProgress) must fire gameStarted — there is '
              'no second start broadcast to wait for');
      expect(client2.myAssignedId, 'peer_1',
          reason: 'client must be rebound to its original seat id');
      expect(host.pendingReconnectPeerIds, isEmpty);

      // The host pushed its last broadcast immediately after the welcome,
      // before any game notifier could have subscribed — a late subscriber
      // must still receive it via the replay.
      final replayed = await client2.remoteStates.first
          .timeout(const Duration(seconds: 2));
      expect(replayed['marker'], 'pre-drop');

      await startSub.cancel();
      await host.endSession();
    });

    test('joinGame clears a stale cached snapshot from a prior game',
        () async {
      final hostEngine = FakeLanEngine();
      final clientEngine = FakeLanEngine();
      hostEngine.connectClient(clientEngine, clientPeerId: 'peer_1');
      final host = GameLanService(hostEngine);
      final client = GameLanService(clientEngine);

      await host.hostGame(gameName: 'Game A', hostPlayerName: 'Skipper');
      final dummyA =
          BonsoirService(name: 'Game A', type: '_sisumate._tcp', port: 0);
      await client.joinGame(service: dummyA, playerName: 'Alex');
      await flush();
      host.startGame();
      host.broadcastState({'marker': 'game-a-state'});
      await flush();

      // Same process joins a different host/game: no stale replay allowed.
      final hostEngine2 = FakeLanEngine();
      hostEngine2.connectClient(clientEngine, clientPeerId: 'peer_1');
      final host2 = GameLanService(hostEngine2);
      await host2.hostGame(gameName: 'Game B', hostPlayerName: 'Other');
      final dummyB =
          BonsoirService(name: 'Game B', type: '_sisumate._tcp', port: 0);
      await client.joinGame(service: dummyB, playerName: 'Alex');
      await flush();

      final events = <Map<String, dynamic>>[];
      final sub = client.remoteStates.listen(events.add);
      await flush();
      expect(events, isEmpty,
          reason: 'a fresh join must not replay the previous game’s state');

      await sub.cancel();
      await host.endSession();
      await host2.endSession();
    });
  });
}
