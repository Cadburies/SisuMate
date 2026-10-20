import 'dart:async';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/lan/game_lan_service.dart';
import 'package:sisu_mate/services/lan/lan_engine.dart';
import 'package:sisu_mate/services/lan/lan_message.dart';
import 'package:sisu_mate/services/lan/share_lan_service.dart';

import 'test_helpers/fake_lan_engine.dart';

/// #435: anyone on the same Wi-Fi can reach the LAN host, so the engine only
/// admits peers that present the host's access code, caps frame size and
/// locks out repeat guessers; seats rebind only with the secret rejoin token;
/// shares go out only after host approval.
void main() {
  Future<LanEngine> startHost() async {
    final engine = LanEngine();
    try {
      await engine.startHost('Access test');
    } catch (_) {
      // mDNS is unavailable in the test env; the WebSocket server is bound first.
    }
    expect(engine.hostPort, isNotNull);
    expect(engine.accessCode, matches(RegExp(r'^\d{6}$')));
    return engine;
  }

  Future<WebSocket> raw(LanEngine host) =>
      WebSocket.connect('ws://127.0.0.1:${host.hostPort}');

  String hello(String code) => LanMessage(
        channel: kLanAccessChannel,
        type: 'hello',
        payload: {'code': code},
      ).encode();

  String gameJoin(String name) =>
      LanMessage(channel: 'game', type: 'join', payload: {'name': name})
          .encode();

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 80));

  group('LanEngine access gate', () {
    late LanEngine host;
    late List<String> joins;
    late List<LanMessage> inbound;

    setUp(() async {
      host = await startHost();
      joins = [];
      inbound = [];
      host.peerJoins.listen(joins.add);
      host.incoming.listen((r) => inbound.add(r.message));
    });

    tearDown(() => host.dispose());

    test('peer without the code is never admitted and gets closed', () async {
      final ws = await raw(host);
      final closed = Completer<void>();
      ws.listen((_) {}, onDone: closed.complete);
      ws.add(gameJoin('Mallory'));
      await closed.future.timeout(const Duration(seconds: 2));
      expect(joins, isEmpty);
      expect(inbound, isEmpty);
      expect(host.connectedPeerIds, isEmpty);
    });

    test('wrong code is denied and closed', () async {
      final ws = await raw(host);
      final got = <String>[];
      final closed = Completer<void>();
      ws.listen((d) => got.add(d as String), onDone: closed.complete);
      ws.add(hello(host.accessCode == '000000' ? '111111' : '000000'));
      await closed.future.timeout(const Duration(seconds: 2));
      expect(got.map(LanMessage.decode).map((m) => m.type), contains('denied'));
      expect(joins, isEmpty);
    });

    test('right code admits the peer and later messages flow', () async {
      final ws = await raw(host);
      ws.listen((_) {});
      ws.add(hello(host.accessCode!));
      await settle();
      ws.add(gameJoin('Alex'));
      await settle();
      expect(joins, hasLength(1));
      expect(inbound.single.type, 'join');
      await ws.close();
    });

    test('oversized frame closes the peer, host keeps serving', () async {
      final ws = await raw(host);
      final closed = Completer<void>();
      ws.listen((_) {}, onDone: closed.complete);
      ws.add(hello(host.accessCode!));
      await settle();
      ws.add('x' * (LanEngine.maxFrameChars + 1));
      await closed.future.timeout(const Duration(seconds: 2));
      expect(inbound, isEmpty);

      final ok = await raw(host);
      ok.listen((_) {});
      ok.add(hello(host.accessCode!));
      await settle();
      expect(joins, hasLength(2));
      await ok.close();
    });

    test('an address that keeps guessing is locked out', () async {
      final wrong = host.accessCode == '000000' ? '111111' : '000000';
      for (var i = 0; i < LanEngine.maxFailedAttemptsPerAddress; i++) {
        final ws = await raw(host);
        final closed = Completer<void>();
        ws.listen((_) {}, onDone: closed.complete);
        ws.add(hello(wrong));
        await closed.future.timeout(const Duration(seconds: 2));
      }
      // Even the right code is refused now.
      Object? error;
      try {
        final ws = await raw(host);
        final closed = Completer<void>();
        ws.listen((_) {}, onDone: closed.complete);
        ws.add(hello(host.accessCode!));
        await closed.future.timeout(const Duration(seconds: 2));
      } catch (e) {
        error = e;
      }
      expect(error != null || joins.isEmpty, isTrue);
      expect(joins, isEmpty);
    });
  });

  group('GameLanService seat ownership', () {
    late FakeLanEngine hostEngine;
    late GameLanService host;
    late GameLanService alex;
    late FakeLanEngine alexEngine;
    final dummy =
        BonsoirService(name: 'Seat', type: '_sisumate._tcp', port: 0);

    setUp(() async {
      hostEngine = FakeLanEngine();
      alexEngine = FakeLanEngine();
      hostEngine.connectClient(alexEngine, clientPeerId: 'peer_1');
      host = GameLanService(hostEngine);
      alex = GameLanService(alexEngine);
      await host.hostGame(gameName: 'Seat', hostPlayerName: 'Host');
      await alex.joinGame(service: dummy, playerName: 'Alex', accessCode: '1');
      await Future<void>.delayed(Duration.zero);
      host.startGame();
      await Future<void>.delayed(Duration.zero);
    });

    test('same name without the rejoin token cannot take a live seat', () async {
      final mallEngine = FakeLanEngine();
      hostEngine.connectClient(mallEngine, clientPeerId: 'peer_2');
      final mallory = GameLanService(mallEngine);
      await mallory.joinGame(service: dummy, playerName: 'Alex', accessCode: '1');
      await Future<void>.delayed(Duration.zero);

      expect(mallory.myAssignedId, isNull,
          reason: 'no welcome: mid-game strangers are not seated');
      final moves = <String>[];
      host.incomingMoves.listen((m) => moves.add(m.peerId));
      alex.sendMove('bid', {});
      await Future<void>.delayed(Duration.zero);
      expect(moves, ['peer_1'], reason: 'Alex still owns peer_1');
    });

    test('guessed preferredId without token cannot take a dropped seat',
        () async {
      alexEngine.disconnect();
      await Future<void>.delayed(Duration.zero);
      expect(host.pendingReconnectPeerIds, contains('peer_1'));

      final mallEngine = FakeLanEngine();
      hostEngine.connectClient(mallEngine, clientPeerId: 'peer_2');
      mallEngine.sendToHost(LanMessage(
        channel: 'game',
        type: 'join',
        payload: {'name': 'Mallory', 'preferredId': 'peer_1'},
      ));
      await Future<void>.delayed(Duration.zero);
      expect(host.pendingReconnectPeerIds, contains('peer_1'));
    });

    test('the real player rejoins with their token', () async {
      expect(alex.myRejoinToken, isNotNull);
      alexEngine.disconnect();
      await Future<void>.delayed(Duration.zero);
      hostEngine.connectClient(alexEngine, clientPeerId: 'peer_3');
      final ok = await alex.reconnect();
      await Future<void>.delayed(Duration.zero);
      expect(ok, isTrue);
      expect(host.pendingReconnectPeerIds, isEmpty);
      expect(alex.myAssignedId, 'peer_1');
    });

    test('host ignores state pushed by a client', () async {
      final states = <Map<String, dynamic>>[];
      host.remoteStates.listen(states.add);
      alexEngine.sendToHost(const LanMessage(
          channel: 'game', type: 'state', payload: {'winner': 'Alex'}));
      await Future<void>.delayed(Duration.zero);
      expect(states, isEmpty);
    });
  });

  group('ShareLanService approval', () {
    late FakeLanEngine hostEngine;
    late FakeLanEngine clientEngine;
    late ShareLanService host;
    late ShareLanService client;
    final dummy =
        BonsoirService(name: 'Crew', type: '_sisumate._tcp', port: 0);
    final payload = SharePayload.crew([CrewMember()..name = 'Alex']);

    setUp(() {
      hostEngine = FakeLanEngine();
      clientEngine = FakeLanEngine();
      hostEngine.connectClient(clientEngine, clientPeerId: 'peer_1');
      host = ShareLanService(hostEngine);
      client = ShareLanService(clientEngine);
    });

    test('nothing is sent when the host declines', () async {
      final got = <SharePayload>[];
      client.incomingContent.listen(got.add);
      await host.hostShare(
          shareName: 'Crew', payload: payload, approve: (_) async => false);
      await client.joinShare(service: dummy, accessCode: '1');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(got, isEmpty);
    });

    test('content is sent after approval', () async {
      final asked = <String>[];
      final got = <SharePayload>[];
      client.incomingContent.listen(got.add);
      await host.hostShare(
          shareName: 'Crew',
          payload: payload,
          approve: (peer) async {
            asked.add(peer);
            return true;
          });
      await client.joinShare(service: dummy, accessCode: '1');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(asked, ['peer_1']);
      expect(got.single.crew.single.name, 'Alex');
    });

    test('malformed content is dropped, not thrown', () async {
      final got = <SharePayload>[];
      client.incomingContent.listen(got.add);
      await client.joinShare(service: dummy, accessCode: '1');
      hostEngine.sendTo(
          'peer_1',
          const LanMessage(
              channel: 'share', type: 'content', payload: {'kind': 'nope'}));
      await Future<void>.delayed(Duration.zero);
      expect(got, isEmpty);
    });
  });
}
