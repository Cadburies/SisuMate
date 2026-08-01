import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/game_ai/game_ai_difficulty.dart';
import 'package:sisu_mate/services/game_ai/game_ai_persona.dart';
import 'package:sisu_mate/services/lan/game_lan_service.dart';
import 'package:sisu_mate/ui/games/games/liars_dice/helpers.dart';
import 'package:sisu_mate/ui/games/games/liars_dice/logic.dart';

// ── Test utilities ─────────────────────────────────────────────────────────────

ProviderContainer makeContainer() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

GameStateNotifier notifier(ProviderContainer c) =>
    c.read(gameStateProvider.notifier);

GameState gs(ProviderContainer c) => c.read(gameStateProvider);

/// Adds two players and leaves the notifier in a state where methods can be
/// called directly without needing the full game-flow timer chain.
void addTwoPlayers(
  ProviderContainer c, {
  List<int> p0Dice = const [1, 1, 1, 1, 1],
  List<int> p1Dice = const [2, 3, 4, 5, 6],
  int p0Counters = 10,
  int p1Counters = 10,
}) {
  notifier(c).addPlayer(
    Player(id: 'p0', name: 'Human', isAI: false, dice: p0Dice, counters: p0Counters),
  );
  notifier(c).addPlayer(
    Player(id: 'p1', name: 'AI', isAI: true, dice: p1Dice, counters: p1Counters),
  );
}

// ── evaluateHand ───────────────────────────────────────────────────────────────

void main() {
  group('evaluateHand', () {
    test('five of a kind', () {
      expect(evaluateHand([3, 3, 3, 3, 3]), DiceRank.fiveOfAKind);
    });

    test('four of a kind', () {
      expect(evaluateHand([4, 4, 4, 4, 2]), DiceRank.fourOfAKind);
    });

    test('full house (3 + 2)', () {
      expect(evaluateHand([5, 5, 5, 2, 2]), DiceRank.fullHouse);
    });

    test('full house (2 + 3)', () {
      expect(evaluateHand([1, 1, 6, 6, 6]), DiceRank.fullHouse);
    });

    test('straight high (2-3-4-5-6)', () {
      expect(evaluateHand([2, 3, 4, 5, 6]), DiceRank.straightHigh);
    });

    test('straight high is order-independent', () {
      expect(evaluateHand([6, 4, 2, 5, 3]), DiceRank.straightHigh);
    });

    test('straight low (1-2-3-4-5)', () {
      expect(evaluateHand([1, 2, 3, 4, 5]), DiceRank.straightLow);
    });

    test('straight low is order-independent', () {
      expect(evaluateHand([5, 3, 1, 4, 2]), DiceRank.straightLow);
    });

    test('three of a kind', () {
      expect(evaluateHand([6, 6, 6, 1, 3]), DiceRank.threeOfAKind);
    });

    test('two pair', () {
      expect(evaluateHand([2, 2, 5, 5, 1]), DiceRank.twoPair);
    });

    test('one pair', () {
      expect(evaluateHand([3, 3, 1, 4, 6]), DiceRank.onePair);
    });

    test('high card (all distinct, not a straight)', () {
      expect(evaluateHand([1, 2, 3, 4, 6]), DiceRank.highCard);
    });

    test('hand rank ordering: five-of-a-kind has lowest index', () {
      // Lower index == better hand in DiceRank enum.
      expect(DiceRank.fiveOfAKind.index, lessThan(DiceRank.highCard.index));
    });

    test('five of a kind beats four of a kind', () {
      final a = evaluateHand([2, 2, 2, 2, 2]);
      final b = evaluateHand([2, 2, 2, 2, 3]);
      expect(a.index, lessThan(b.index));
    });

    test('four of a kind beats full house', () {
      final a = evaluateHand([1, 1, 1, 1, 5]);
      final b = evaluateHand([1, 1, 1, 5, 5]);
      expect(a.index, lessThan(b.index));
    });

    test('full house beats straight high', () {
      final a = evaluateHand([3, 3, 3, 6, 6]);
      final b = evaluateHand([2, 3, 4, 5, 6]);
      expect(a.index, lessThan(b.index));
    });

    test('straight high beats straight low', () {
      final a = evaluateHand([2, 3, 4, 5, 6]);
      final b = evaluateHand([1, 2, 3, 4, 5]);
      expect(a.index, lessThan(b.index));
    });

    test('straight low beats three of a kind', () {
      final a = evaluateHand([1, 2, 3, 4, 5]);
      final b = evaluateHand([6, 6, 6, 1, 2]);
      expect(a.index, lessThan(b.index));
    });

    test('three of a kind beats two pair', () {
      final a = evaluateHand([5, 5, 5, 1, 2]);
      final b = evaluateHand([4, 4, 6, 6, 1]);
      expect(a.index, lessThan(b.index));
    });

    test('two pair beats one pair', () {
      final a = evaluateHand([3, 3, 4, 4, 1]);
      final b = evaluateHand([3, 3, 4, 5, 6]);
      expect(a.index, lessThan(b.index));
    });

    test('one pair beats high card', () {
      final a = evaluateHand([2, 2, 3, 4, 6]);
      final b = evaluateHand([1, 2, 3, 4, 6]);
      expect(a.index, lessThan(b.index));
    });
  });

  // ── compareBids ──────────────────────────────────────────────────────────────

  group('compareBids', () {
    test('higher rank (lower index) returns positive', () {
      final a = Bid(DiceRank.fiveOfAKind, 3);
      final b = Bid(DiceRank.highCard, 3);
      expect(compareBids(a, b), greaterThan(0));
    });

    test('lower rank (higher index) returns negative', () {
      final a = Bid(DiceRank.highCard, 3);
      final b = Bid(DiceRank.fiveOfAKind, 3);
      expect(compareBids(a, b), lessThan(0));
    });

    test('same rank, higher face returns positive', () {
      final a = Bid(DiceRank.onePair, 6);
      final b = Bid(DiceRank.onePair, 3);
      expect(compareBids(a, b), greaterThan(0));
    });

    test('same rank, lower face returns negative', () {
      final a = Bid(DiceRank.onePair, 1);
      final b = Bid(DiceRank.onePair, 4);
      expect(compareBids(a, b), lessThan(0));
    });

    test('identical bids return zero', () {
      final a = Bid(DiceRank.twoPair, 5);
      final b = Bid(DiceRank.twoPair, 5);
      expect(compareBids(a, b), 0);
    });
  });

  // ── isValidBid ───────────────────────────────────────────────────────────────

  group('isValidBid', () {
    test('any bid is valid when there is no last bid', () {
      expect(isValidBid(Bid(DiceRank.highCard, 1), null), isTrue);
      expect(isValidBid(Bid(DiceRank.fiveOfAKind, 6), null), isTrue);
    });

    test('strictly higher rank is valid', () {
      final last = Bid(DiceRank.onePair, 3);
      final next = Bid(DiceRank.twoPair, 1);
      expect(isValidBid(next, last), isTrue);
    });

    test('same rank with higher face is valid', () {
      final last = Bid(DiceRank.onePair, 3);
      final next = Bid(DiceRank.onePair, 5);
      expect(isValidBid(next, last), isTrue);
    });

    test('same rank, same face is invalid', () {
      final last = Bid(DiceRank.onePair, 4);
      final next = Bid(DiceRank.onePair, 4);
      expect(isValidBid(next, last), isFalse);
    });

    test('lower rank is invalid even with higher face', () {
      final last = Bid(DiceRank.fullHouse, 1);
      final next = Bid(DiceRank.twoPair, 6);
      expect(isValidBid(next, last), isFalse);
    });

    test('five-of-a-kind ace-6 is the maximum bid', () {
      final last = Bid(DiceRank.fiveOfAKind, 6);
      final next = Bid(DiceRank.fiveOfAKind, 6);
      expect(isValidBid(next, last), isFalse);
    });
  });

  // ── rollDice & rollDiceWithHolds ──────────────────────────────────────────────

  group('rollDice', () {
    test('always returns exactly 5 dice', () {
      for (int i = 0; i < 20; i++) {
        expect(rollDice().length, 5);
      }
    });

    test('all values are in range 1-6', () {
      for (int i = 0; i < 20; i++) {
        for (final d in rollDice()) {
          expect(d, inInclusiveRange(1, 6));
        }
      }
    });
  });

  group('rollDiceWithHolds', () {
    test('all held: returns identical dice', () {
      final original = [1, 2, 3, 4, 5];
      final holds = [true, true, true, true, true];
      final result = rollDiceWithHolds(original, holds);
      expect(result, equals(original));
    });

    test('held positions are preserved exactly', () {
      final original = [6, 6, 6, 6, 6];
      final holds = [true, false, true, false, true];
      final result = rollDiceWithHolds(original, holds);
      expect(result[0], 6);
      expect(result[2], 6);
      expect(result[4], 6);
    });

    test('unheld values are in 1-6 range', () {
      final original = [1, 1, 1, 1, 1];
      final holds = [false, false, false, false, false];
      for (int i = 0; i < 20; i++) {
        final result = rollDiceWithHolds(original, holds);
        for (final d in result) {
          expect(d, inInclusiveRange(1, 6));
        }
      }
    });

    test('returns exactly 5 values', () {
      expect(rollDiceWithHolds([1, 2, 3, 4, 5], [false, false, false, false, false]).length, 5);
    });
  });

  // ── bestHoldMask (AI hold strategy, 2026-07-13) ───────────────────────────────

  group('bestHoldMask', () {
    test('all distinct (high card): holds nothing', () {
      expect(bestHoldMask([1, 2, 3, 4, 5]), [false, false, false, false, false]);
    });

    test('one pair: holds only the pair', () {
      expect(bestHoldMask([5, 5, 1, 2, 3]), [true, true, false, false, false]);
    });

    test('three of a kind: holds all three, rerolls the other two', () {
      expect(bestHoldMask([4, 4, 4, 1, 6]), [true, true, true, false, false]);
    });

    test('two pair: holds the higher-face pair (tie-break by face value)', () {
      // Two pair (3s and 5s) — same count, higher face (5) wins the hold.
      expect(bestHoldMask([3, 3, 5, 5, 1]), [false, false, true, true, false]);
    });

    test('five of a kind: holds everything', () {
      expect(bestHoldMask([6, 6, 6, 6, 6]), [true, true, true, true, true]);
    });

    test('result length always matches input length', () {
      expect(bestHoldMask([1, 2, 3, 4, 5]).length, 5);
    });
  });

  // ── rankToString & faceToString ───────────────────────────────────────────────

  group('rankToString', () {
    test('maps every DiceRank to a non-empty string', () {
      for (final rank in DiceRank.values) {
        final s = rankToString(rank);
        expect(s, isNotEmpty);
      }
    });

    test('exact label for five of a kind', () {
      expect(rankToString(DiceRank.fiveOfAKind), 'Five of a Kind');
    });

    test('exact label for straight high', () {
      expect(rankToString(DiceRank.straightHigh), 'Straight (2-6)');
    });

    test('exact label for straight low', () {
      expect(rankToString(DiceRank.straightLow), 'Straight (1-5)');
    });

    test('all 9 ranks have distinct labels', () {
      final labels = DiceRank.values.map(rankToString).toSet();
      expect(labels.length, DiceRank.values.length);
    });
  });

  group('faceToString', () {
    test('face 1 is Aces', () => expect(faceToString(1), 'Aces'));
    test('face 2 is Twos', () => expect(faceToString(2), 'Twos'));
    test('face 3 is Threes', () => expect(faceToString(3), 'Threes'));
    test('face 4 is Fours', () => expect(faceToString(4), 'Fours'));
    test('face 5 is Fives', () => expect(faceToString(5), 'Fives'));
    test('face 6 is Sixes', () => expect(faceToString(6), 'Sixes'));
    test('unknown face falls back to its string value', () {
      expect(faceToString(7), '7');
    });
  });

  // ── Player model ─────────────────────────────────────────────────────────────

  group('Player', () {
    const base = Player(id: 'x', name: 'Test', isAI: false);

    test('copyWith updates name', () {
      expect(base.copyWith(name: 'New').name, 'New');
    });

    test('copyWith updates dice', () {
      expect(base.copyWith(dice: [2, 2, 2, 2, 2]).dice, [2, 2, 2, 2, 2]);
    });

    test('copyWith updates counters', () {
      expect(base.copyWith(counters: 7).counters, 7);
    });

    test('copyWith preserves unchanged fields', () {
      final copy = base.copyWith(counters: 5);
      expect(copy.id, base.id);
      expect(copy.name, base.name);
      expect(copy.isAI, base.isAI);
      expect(copy.isConnected, base.isConnected);
    });

    test('toJson / fromJson round-trip', () {
      const p = Player(
        id: 'abc',
        name: 'Sailor',
        isAI: true,
        dice: [1, 2, 3, 4, 5],
        counters: 7,
        isConnected: false,
      );
      final json = p.toJson();
      final restored = Player.fromJson(json);
      expect(restored.id, p.id);
      expect(restored.name, p.name);
      expect(restored.isAI, p.isAI);
      expect(restored.dice, p.dice);
      expect(restored.counters, p.counters);
      expect(restored.isConnected, p.isConnected);
    });

    test('fromJson defaults isConnected to true when absent', () {
      final json = {
        'id': 'z', 'name': 'Ghost', 'isAI': false,
        'dice': [1, 1, 1, 1, 1], 'counters': 10,
      };
      expect(Player.fromJson(json).isConnected, isTrue);
    });
  });

  // ── Bid model ────────────────────────────────────────────────────────────────

  group('Bid', () {
    test('toJson / fromJson round-trip', () {
      const bid = Bid(DiceRank.fullHouse, 4);
      final restored = Bid.fromJson(bid.toJson());
      expect(restored.rank, bid.rank);
      expect(restored.face, bid.face);
    });

    test('fromJson handles all DiceRank names', () {
      for (final rank in DiceRank.values) {
        final restored = Bid.fromJson({'rank': rank.name, 'face': 3});
        expect(restored.rank, rank);
      }
    });
  });

  // ── GameState model ──────────────────────────────────────────────────────────

  group('GameState', () {
    test('copyWith changes currentState', () {
      const s = GameState(currentState: GameStateEnum.start, players: []);
      expect(s.copyWith(currentState: GameStateEnum.gameOver).currentState,
          GameStateEnum.gameOver);
    });

    test('copyWith preserves unchanged fields', () {
      const original = GameState(
        currentState: GameStateEnum.rollDice,
        players: [],
        currentTurn: 1,
        isMultiplayer: true,
      );
      final copy = original.copyWith(currentTurn: 0);
      expect(copy.currentState, original.currentState);
      expect(copy.isMultiplayer, original.isMultiplayer);
    });

    test('toJson / fromJson round-trip preserves all fields', () {
      final bid = const Bid(DiceRank.twoPair, 5);
      final s = GameState(
        currentState: GameStateEnum.acceptChallenge,
        players: [
          const Player(id: 'p0', name: 'Alice', isAI: false),
          const Player(id: 'p1', name: 'Bob', isAI: true),
        ],
        currentTurn: 0,
        oppositionPlayer: 1,
        bidHistory: [bid],
        lastDeclaredBid: bid,
        isMultiplayer: false,
        gameMessage: 'Test message',
      );
      final restored = GameState.fromJson(s.toJson());
      expect(restored.currentState, s.currentState);
      expect(restored.players.length, s.players.length);
      expect(restored.currentTurn, s.currentTurn);
      expect(restored.oppositionPlayer, s.oppositionPlayer);
      expect(restored.bidHistory.length, s.bidHistory.length);
      expect(restored.lastDeclaredBid?.rank, bid.rank);
      expect(restored.lastDeclaredBid?.face, bid.face);
      expect(restored.isMultiplayer, s.isMultiplayer);
      expect(restored.gameMessage, s.gameMessage);
    });

    test('fromJson handles null lastDeclaredBid', () {
      final s = GameState.fromJson({
        'currentState': 'start',
        'players': <dynamic>[],
        'lastDeclaredBid': null,
      });
      expect(s.lastDeclaredBid, isNull);
    });

    test('fromJson defaults bidHistory to empty list when absent', () {
      final s = GameState.fromJson({
        'currentState': 'start',
        'players': <dynamic>[],
      });
      expect(s.bidHistory, isEmpty);
    });
  });

  // ── GameStateNotifier — player management ────────────────────────────────────

  group('GameStateNotifier — player management', () {
    test('initial state is start with empty player list', () {
      final c = makeContainer();
      expect(gs(c).currentState, GameStateEnum.start);
      expect(gs(c).players, isEmpty);
    });

    test('addPlayer appends a player', () {
      final c = makeContainer();
      notifier(c).addPlayer(const Player(id: 'p0', name: 'X', isAI: false));
      expect(gs(c).players.length, 1);
      expect(gs(c).players.first.id, 'p0');
    });

    test('addPlayer appends multiple players in order', () {
      final c = makeContainer();
      notifier(c).addPlayer(const Player(id: 'p0', name: 'A', isAI: false));
      notifier(c).addPlayer(const Player(id: 'p1', name: 'B', isAI: true));
      expect(gs(c).players.map((p) => p.id).toList(), ['p0', 'p1']);
    });

    test('removePlayer removes by id', () {
      final c = makeContainer();
      addTwoPlayers(c);
      notifier(c).removePlayer('p0');
      expect(gs(c).players.length, 1);
      expect(gs(c).players.first.id, 'p1');
    });

    test('removePlayer is a no-op for unknown id', () {
      final c = makeContainer();
      addTwoPlayers(c);
      notifier(c).removePlayer('unknown');
      expect(gs(c).players.length, 2);
    });
  });

  // ── GameStateNotifier — startGame ────────────────────────────────────────────

  group('GameStateNotifier — startGame', () {
    test('startGame with fewer than 2 players does not change state', () {
      final c = makeContainer();
      notifier(c).addPlayer(const Player(id: 'p0', name: 'Lone', isAI: false));
      notifier(c).startGame();
      expect(gs(c).currentState, GameStateEnum.start);
    });

    test('startGame with 2+ players transitions to determineStarter', () {
      final c = makeContainer();
      addTwoPlayers(c);
      notifier(c).startGame();
      expect(gs(c).currentState, GameStateEnum.determineStarter);
    });

    test('startGame assigns dice to all players', () {
      final c = makeContainer();
      addTwoPlayers(c);
      notifier(c).startGame();
      for (final p in gs(c).players) {
        expect(p.dice.length, 5);
        for (final d in p.dice) {
          expect(d, inInclusiveRange(1, 6));
        }
      }
    });
  });

  // ── GameStateNotifier — determineStarter ────────────────────────────────────

  group('GameStateNotifier — determineStarter', () {
    test('after calling, state is rollDice OR message contains "Re-rolling"', () {
      final c = makeContainer();
      addTwoPlayers(c);
      notifier(c).startGame();
      notifier(c).determineStarter();
      final s = gs(c);
      final resolved = s.currentState == GameStateEnum.rollDice;
      final tieMessage = s.gameMessage?.contains('Re-rolling') ?? false;
      expect(resolved || tieMessage, isTrue);
    });

    test('winner index is within player bounds', () {
      final c = makeContainer();
      addTwoPlayers(c);
      notifier(c).startGame();
      // Repeat until we get a non-tie result.
      for (int attempt = 0; attempt < 20; attempt++) {
        notifier(c).determineStarter();
        if (gs(c).currentState == GameStateEnum.rollDice) break;
      }
      if (gs(c).currentState == GameStateEnum.rollDice) {
        expect(gs(c).currentTurn, inInclusiveRange(0, 1));
        expect(gs(c).oppositionPlayer, inInclusiveRange(0, 1));
        expect(gs(c).currentTurn, isNot(equals(gs(c).oppositionPlayer)));
      }
    });

    test('a tie marks both players in rerollingPlayerIds (F8)', () {
      final c = makeContainer();
      // Identical dice on both players guarantees an equal hand rank, so
      // this is a deterministic tie on the very first call, not a fluke.
      addTwoPlayers(c, p0Dice: [1, 1, 1, 1, 1], p1Dice: [1, 1, 1, 1, 1]);
      notifier(c).determineStarter();

      // A tie doesn't resolve to rollDice — the notifier just re-rolls the
      // tied players in place and schedules another determineStarter() call.
      expect(gs(c).currentState, isNot(GameStateEnum.rollDice));
      expect(gs(c).gameMessage, contains('Re-rolling'));
      expect(gs(c).rerollingPlayerIds, unorderedEquals(['p0', 'p1']));
    });

    test('once a starter is resolved, rerollingPlayerIds is cleared (F8)', () {
      final c = makeContainer();
      addTwoPlayers(c, p0Dice: [1, 1, 1, 1, 1], p1Dice: [2, 3, 4, 5, 6]);
      notifier(c).determineStarter();

      expect(gs(c).currentState, GameStateEnum.rollDice);
      expect(gs(c).rerollingPlayerIds, isEmpty);
    });
  });

  // ── GameStateNotifier — finalizeRoll ─────────────────────────────────────────

  group('GameStateNotifier — finalizeRoll', () {
    test('updates the current player dice', () {
      final c = makeContainer();
      addTwoPlayers(c);
      notifier(c).finalizeRoll([6, 6, 6, 6, 6]);
      expect(gs(c).players[0].dice, [6, 6, 6, 6, 6]);
    });

    test('transitions to declareHand', () {
      final c = makeContainer();
      addTwoPlayers(c);
      notifier(c).finalizeRoll([1, 2, 3, 4, 5]);
      expect(gs(c).currentState, GameStateEnum.declareHand);
    });

    test('game message names the current player', () {
      final c = makeContainer();
      addTwoPlayers(c);
      notifier(c).finalizeRoll([1, 2, 3, 4, 5]);
      expect(gs(c).gameMessage, contains(gs(c).players[0].name));
    });
  });

  // ── GameStateNotifier — declareBid ───────────────────────────────────────────

  group('GameStateNotifier — declareBid', () {
    test('first bid (no lastDeclaredBid) is always accepted', () {
      final c = makeContainer();
      addTwoPlayers(c);
      notifier(c).finalizeRoll([1, 1, 1, 1, 1]);
      notifier(c).declareBid(const Bid(DiceRank.highCard, 1));
      expect(gs(c).currentState, GameStateEnum.acceptChallenge);
    });

    test('valid escalating bid is accepted and stored', () {
      final c = makeContainer();
      addTwoPlayers(c);
      notifier(c).finalizeRoll([1, 1, 1, 1, 1]);
      notifier(c).declareBid(const Bid(DiceRank.onePair, 3));
      notifier(c).acceptChallenge(true);
      notifier(c).advanceFromAcceptReveal();
      notifier(c).finalizeRoll([2, 2, 2, 2, 2]);
      notifier(c).declareBid(const Bid(DiceRank.twoPair, 1));
      expect(gs(c).currentState, GameStateEnum.acceptChallenge);
      expect(gs(c).lastDeclaredBid?.rank, DiceRank.twoPair);
    });

    // declareBid has no state guard, so it can be called twice in one round.
    // The second call checks isValidBid against lastDeclaredBid set by the first.
    test('invalid bid (same rank and face) is rejected — lastDeclaredBid unchanged', () {
      final c = makeContainer();
      addTwoPlayers(c);
      notifier(c).finalizeRoll([1, 1, 1, 1, 1]);
      notifier(c).declareBid(const Bid(DiceRank.onePair, 4)); // valid first bid
      notifier(c).declareBid(const Bid(DiceRank.onePair, 4)); // same → invalid
      expect(gs(c).gameMessage, contains('Invalid bid'));
      // lastDeclaredBid stays as the first (valid) bid
      expect(gs(c).lastDeclaredBid?.rank, DiceRank.onePair);
      expect(gs(c).lastDeclaredBid?.face, 4);
    });

    test('invalid bid message mentions the required minimum', () {
      final c = makeContainer();
      addTwoPlayers(c);
      notifier(c).finalizeRoll([1, 1, 1, 1, 1]);
      notifier(c).declareBid(const Bid(DiceRank.twoPair, 5)); // valid
      notifier(c).declareBid(const Bid(DiceRank.onePair, 1)); // lower → invalid
      expect(gs(c).gameMessage, contains('Invalid bid'));
    });

    test('bid is added to bidHistory on success', () {
      final c = makeContainer();
      addTwoPlayers(c);
      notifier(c).finalizeRoll([1, 1, 1, 1, 1]);
      expect(gs(c).bidHistory.length, 0);
      notifier(c).declareBid(const Bid(DiceRank.highCard, 2));
      expect(gs(c).bidHistory.length, 1);
    });
  });

  // ── GameStateNotifier — acceptChallenge ──────────────────────────────────────

  group('GameStateNotifier — acceptChallenge', () {
    void setupAtAcceptChallenge(ProviderContainer c) {
      addTwoPlayers(c);
      notifier(c).finalizeRoll([1, 1, 1, 1, 1]);
      notifier(c).declareBid(const Bid(DiceRank.onePair, 1));
    }

    test('accept=true transitions to acceptReveal', () {
      final c = makeContainer();
      setupAtAcceptChallenge(c);
      notifier(c).acceptChallenge(true);
      expect(gs(c).currentState, GameStateEnum.acceptReveal);
    });

    test('accept=false transitions to resolveChallenge', () {
      final c = makeContainer();
      setupAtAcceptChallenge(c);
      notifier(c).acceptChallenge(false);
      expect(gs(c).currentState, GameStateEnum.resolveChallenge);
    });

    test('accept=true message mentions the accepting player', () {
      final c = makeContainer();
      setupAtAcceptChallenge(c);
      final oppositionName = gs(c).players[gs(c).oppositionPlayer].name;
      notifier(c).acceptChallenge(true);
      expect(gs(c).gameMessage, contains(oppositionName));
    });
  });

  // ── GameStateNotifier — advanceFromAcceptReveal ───────────────────────────────

  group('GameStateNotifier — advanceFromAcceptReveal', () {
    test('transitions to rollDice', () {
      final c = makeContainer();
      addTwoPlayers(c);
      notifier(c).finalizeRoll([1, 1, 1, 1, 1]);
      notifier(c).declareBid(const Bid(DiceRank.highCard, 1));
      notifier(c).acceptChallenge(true);
      notifier(c).advanceFromAcceptReveal();
      expect(gs(c).currentState, GameStateEnum.rollDice);
    });

    test('swaps declarer and opponent after advance', () {
      final c = makeContainer();
      addTwoPlayers(c);
      notifier(c).finalizeRoll([1, 1, 1, 1, 1]);
      notifier(c).declareBid(const Bid(DiceRank.highCard, 1));
      final oldOpposition = gs(c).oppositionPlayer;
      notifier(c).acceptChallenge(true);
      notifier(c).advanceFromAcceptReveal();
      // After advancing, the previous oppositionPlayer becomes the new declarer.
      expect(gs(c).currentTurn, oldOpposition);
    });

    test('resets bid history and lastDeclaredBid', () {
      final c = makeContainer();
      addTwoPlayers(c);
      notifier(c).finalizeRoll([1, 1, 1, 1, 1]);
      notifier(c).declareBid(const Bid(DiceRank.highCard, 1));
      notifier(c).acceptChallenge(true);
      notifier(c).advanceFromAcceptReveal();
      expect(gs(c).bidHistory, isEmpty);
      expect(gs(c).lastDeclaredBid, isNull);
    });

    test('new declarer inherits the shared dice (one-box rule)', () {
      final c = makeContainer();
      addTwoPlayers(c);
      final rolledDice = [3, 3, 3, 1, 2]; // a specific set to track
      notifier(c).finalizeRoll(rolledDice);
      notifier(c).declareBid(const Bid(DiceRank.threeOfAKind, 1));
      notifier(c).acceptChallenge(true);
      notifier(c).advanceFromAcceptReveal();
      // The new declarer (p1, index 1) should now hold the dice p0 rolled.
      expect(gs(c).players[gs(c).currentTurn].dice, rolledDice);
    });
  });

  // ── GameStateNotifier — resolveChallenge ─────────────────────────────────────
  //
  // "Common Hand" rules:
  //   Challenge Successful: declared hand is BETTER than actual → Declarer loses.
  //   Challenge Failed:     declared hand is same or WORSE  → Challenger loses.
  //   Challenger ALWAYS starts the next round regardless of outcome.
  //
  // Mechanic: penalty is for OVERCLAIMING (bluffing), not for being conservative.
  //   declared <  actual → compareBids < 0 → bluffFailed = true  → challenger loses
  //   declared =  actual → compareBids = 0 → bluffFailed = true  → challenger loses
  //   declared >  actual → compareBids > 0 → bluffFailed = false → declarer loses

  group('GameStateNotifier — resolveChallenge', () {
    /// declared = actual (honest claim) → challenge fails → challenger loses.
    test('challenger loses counter when declared matches actual hand', () {
      final c = makeContainer();
      addTwoPlayers(c);
      notifier(c).finalizeRoll([1, 1, 1, 1, 1]); // fiveOfAKind
      notifier(c).declareBid(const Bid(DiceRank.fiveOfAKind, 1)); // honest
      notifier(c).acceptChallenge(false);
      final p1Before = gs(c).players[1].counters;
      notifier(c).resolveChallenge();
      expect(gs(c).players[1].counters, p1Before - 1);
      expect(gs(c).players[0].counters, 10);
    });

    /// declared < actual (conservative / underselling) → challenge fails → challenger loses.
    test('challenger loses counter when declared rank is below actual rank', () {
      final c = makeContainer();
      addTwoPlayers(c);
      notifier(c).finalizeRoll([1, 1, 1, 1, 1]); // fiveOfAKind
      notifier(c).declareBid(const Bid(DiceRank.highCard, 1)); // conservative
      notifier(c).acceptChallenge(false);
      final p1Before = gs(c).players[1].counters;
      notifier(c).resolveChallenge();
      expect(gs(c).players[1].counters, p1Before - 1);
      expect(gs(c).players[0].counters, 10);
    });

    /// declared > actual (overclaiming / bluffing) → challenge succeeds → declarer loses.
    test('declarer loses counter when overclaiming (bluffing)', () {
      final c = makeContainer();
      addTwoPlayers(c);
      notifier(c).finalizeRoll([1, 2, 3, 4, 6]); // highCard
      notifier(c).declareBid(const Bid(DiceRank.fiveOfAKind, 1)); // overclaim
      notifier(c).acceptChallenge(false);
      final p0Before = gs(c).players[0].counters;
      notifier(c).resolveChallenge();
      expect(gs(c).players[0].counters, p0Before - 1);
      expect(gs(c).players[1].counters, 10);
    });

    test('transitions to determineGameOver', () {
      final c = makeContainer();
      addTwoPlayers(c);
      notifier(c).finalizeRoll([1, 1, 1, 1, 1]); // fiveOfAKind — honest claim
      notifier(c).declareBid(const Bid(DiceRank.fiveOfAKind, 1));
      notifier(c).acceptChallenge(false);
      notifier(c).resolveChallenge();
      expect(gs(c).currentState, GameStateEnum.determineGameOver);
    });

    /// Bluff detected: p0 overclaims → p1 challenges correctly → challenger (p1) starts next.
    test('challenger starts next round when challenge succeeds (overclaim)', () {
      final c = makeContainer();
      addTwoPlayers(c);
      notifier(c).finalizeRoll([1, 2, 3, 4, 6]); // highCard
      notifier(c).declareBid(const Bid(DiceRank.fiveOfAKind, 1)); // overclaim → p0 loses
      notifier(c).acceptChallenge(false);
      notifier(c).resolveChallenge();
      // Challenger = p1 (index 1) always starts next round.
      expect(gs(c).currentTurn, 1);
    });

    /// Honest claim: p0 honest → p1 challenges wrongly → p1 loses, but still starts next.
    test('challenger starts next round even when challenge fails (honest claim)', () {
      final c = makeContainer();
      addTwoPlayers(c);
      notifier(c).finalizeRoll([1, 1, 1, 1, 1]); // fiveOfAKind — honest
      notifier(c).declareBid(const Bid(DiceRank.fiveOfAKind, 1));
      notifier(c).acceptChallenge(false); // p1 challenges wrongly → p1 loses
      notifier(c).resolveChallenge();
      // Challenger = p1 (index 1) always starts next round, even as the loser.
      expect(gs(c).currentTurn, 1);
    });
  });

  // ── GameStateNotifier — determineGameOver ─────────────────────────────────────

  group('GameStateNotifier — determineGameOver', () {
    /// p0 declares honestly (highCard dice, declare highCard) → p1 challenges
    /// wrongly → challenger (p1) loses counter.
    void reachDetermineGameOverP1Loses(ProviderContainer c) {
      notifier(c).finalizeRoll([1, 2, 3, 4, 6]); // highCard
      notifier(c).declareBid(const Bid(DiceRank.highCard, 1)); // honest → p1 loses
      notifier(c).acceptChallenge(false);
      notifier(c).resolveChallenge();
    }

    /// p0 overclaims (highCard dice, declare fiveOfAKind) → p1 challenges
    /// correctly → declarer (p0) loses counter.
    void reachDetermineGameOverP0Loses(ProviderContainer c) {
      notifier(c).finalizeRoll([1, 2, 3, 4, 6]); // highCard
      notifier(c).declareBid(const Bid(DiceRank.fiveOfAKind, 1)); // overclaim → p0 loses
      notifier(c).acceptChallenge(false);
      notifier(c).resolveChallenge();
    }

    test('game continues when all players have counters > 0', () {
      final c = makeContainer();
      addTwoPlayers(c);
      reachDetermineGameOverP1Loses(c);
      notifier(c).determineGameOver();
      expect(gs(c).currentState, GameStateEnum.rollDice);
    });

    test('game over when a player reaches 0 counters', () {
      final c = makeContainer();
      addTwoPlayers(c, p0Counters: 1); // p0 will sandbag and lose their last counter
      reachDetermineGameOverP0Loses(c);
      notifier(c).determineGameOver();
      expect(gs(c).currentState, GameStateEnum.gameOver);
    });

    test('winner message names the surviving player', () {
      final c = makeContainer();
      addTwoPlayers(c, p0Counters: 1);
      reachDetermineGameOverP0Loses(c);
      notifier(c).determineGameOver();
      // p0 lost → p1 survives → message contains p1's name
      expect(gs(c).gameMessage, contains('AI'));
    });

    test('game continues: bid history and lastDeclaredBid cleared for new round', () {
      final c = makeContainer();
      addTwoPlayers(c);
      reachDetermineGameOverP1Loses(c);
      notifier(c).determineGameOver();
      expect(gs(c).bidHistory, isEmpty);
      expect(gs(c).lastDeclaredBid, isNull);
    });
  });

  // ── GameStateNotifier — resetGame ─────────────────────────────────────────────

  group('GameStateNotifier — resetGame', () {
    test('resets currentState to start', () {
      final c = makeContainer();
      addTwoPlayers(c);
      notifier(c).finalizeRoll([1, 1, 1, 1, 1]);
      notifier(c).declareBid(const Bid(DiceRank.highCard, 1));
      notifier(c).resetGame();
      expect(gs(c).currentState, GameStateEnum.start);
    });

    test('restores all player counters to 10', () {
      final c = makeContainer();
      addTwoPlayers(c, p0Counters: 3, p1Counters: 7);
      notifier(c).resetGame();
      for (final p in gs(c).players) {
        expect(p.counters, 10);
      }
    });

    test('clears bid history', () {
      final c = makeContainer();
      addTwoPlayers(c);
      notifier(c).finalizeRoll([1, 1, 1, 1, 1]);
      notifier(c).declareBid(const Bid(DiceRank.highCard, 1));
      notifier(c).resetGame();
      expect(gs(c).bidHistory, isEmpty);
    });

    test('clears lastDeclaredBid', () {
      final c = makeContainer();
      addTwoPlayers(c);
      notifier(c).finalizeRoll([1, 1, 1, 1, 1]);
      notifier(c).declareBid(const Bid(DiceRank.highCard, 1));
      notifier(c).resetGame();
      expect(gs(c).lastDeclaredBid, isNull);
    });

    test('resets indices to 0 and 1', () {
      final c = makeContainer();
      addTwoPlayers(c);
      notifier(c).resetGame();
      expect(gs(c).currentTurn, 0);
      expect(gs(c).oppositionPlayer, 1);
    });
  });

  // ── GameStateNotifier — AI bid ────────────────────────────────────────────────

  group('GameStateNotifier — AI bid', () {
    test('getAIBid returns a valid bid when no last bid', () {
      final c = makeContainer();
      addTwoPlayers(c);
      notifier(c).finalizeRoll([1, 1, 1, 1, 1]);
      final bid = notifier(c).getAIBid();
      expect(isValidBid(bid, null), isTrue);
    });

    test('getAIBid returns a bid higher than the last declared bid', () {
      final c = makeContainer();
      addTwoPlayers(c);
      notifier(c).finalizeRoll([1, 1, 1, 1, 1]);
      const last = Bid(DiceRank.onePair, 3);
      notifier(c).declareBid(last);
      // Advance to AI turn.
      notifier(c).acceptChallenge(true);
      notifier(c).advanceFromAcceptReveal();
      notifier(c).finalizeRoll([2, 2, 2, 2, 2]);
      final aiBid = notifier(c).getAIBid();
      expect(isValidBid(aiBid, last), isTrue);
    });

    test('getAIBid always returns a bid even when last bid is near maximum', () {
      final c = makeContainer();
      addTwoPlayers(c);
      notifier(c).finalizeRoll([1, 1, 1, 1, 1]);
      // Advance to player 1 as current declarer.
      notifier(c).declareBid(const Bid(DiceRank.fourOfAKind, 6));
      notifier(c).acceptChallenge(true);
      notifier(c).advanceFromAcceptReveal();
      notifier(c).finalizeRoll([2, 2, 2, 2, 2]);
      final bid = notifier(c).getAIBid();
      expect(bid, isNotNull);
    });

    test('getAIBid picks the minimum valid face for its own rank, not the maximum (F7)',
        () {
      final c = makeContainer();
      // [2, 2, 3, 4, 5] is a one-pair hand; with no last bid, any face for
      // that rank is technically valid — the AI should pick the smallest,
      // not (as before this fix) always the maximum face (6).
      addTwoPlayers(c, p0Dice: [2, 2, 3, 4, 5]);
      notifier(c).finalizeRoll([2, 2, 3, 4, 5]);
      final bid = notifier(c).getAIBid();
      expect(bid.rank, DiceRank.onePair);
      expect(bid.face, 1);
    });
  });

  // ── GameStateNotifier — AI accept ────────────────────────────────────────────

  group('GameStateNotifier — AI accept', () {
    test('getAIAccept returns true when there is no lastDeclaredBid', () {
      final c = makeContainer();
      addTwoPlayers(c);
      expect(notifier(c).getAIAccept(), isTrue);
    });

    test('getAIAccept challenges when declared rank far exceeds AI hand', () {
      final c = makeContainer();
      // p0 has five-of-a-kind (best), p1 (AI / oppositionPlayer) has high card.
      addTwoPlayers(c, p0Dice: [1, 1, 1, 1, 1], p1Dice: [1, 2, 3, 4, 6]);
      notifier(c).finalizeRoll([1, 1, 1, 1, 1]);
      notifier(c).declareBid(const Bid(DiceRank.fiveOfAKind, 1));
      // rankDiff = highCard.index(8) - fiveOfAKind.index(0) = 8 >= 3 → always challenge.
      // Run multiple times to confirm the >= 3 rule always challenges.
      int challenges = 0;
      for (int i = 0; i < 20; i++) {
        if (!notifier(c).getAIAccept()) challenges++;
      }
      expect(challenges, 20);
    });

    test('getAIAccept mostly accepts when declared rank matches AI hand', () {
      final c = makeContainer();
      // Both p0 and p1 have identical one-pair hands.
      addTwoPlayers(c, p0Dice: [2, 2, 3, 4, 5], p1Dice: [3, 3, 1, 4, 6]);
      notifier(c).finalizeRoll([2, 2, 3, 4, 5]);
      notifier(c).declareBid(const Bid(DiceRank.onePair, 2));
      // rankDiff = onePair(7) - onePair(7) = 0 → always accept.
      int accepts = 0;
      for (int i = 0; i < 20; i++) {
        if (notifier(c).getAIAccept()) accepts++;
      }
      expect(accepts, 20);
    });

    test(
        'getAIAccept challenges an inherently rare declared rank even at rankDiff 1 (F7)',
        () {
      final c = makeContainer();
      // p1 (AI) holds a full house — one rank better than the declared four
      // of a kind (rankDiff = fullHouse.index(2) - fourOfAKind.index(1) = 1),
      // which previously fell into the flat 70/30 branch regardless of what
      // was actually being claimed. Four of a kind is true on well under 2%
      // of honest rolls, so a rarity-aware AI should doubt it outright.
      addTwoPlayers(c, p0Dice: [1, 1, 1, 1, 2], p1Dice: [3, 3, 3, 5, 5]);
      notifier(c).finalizeRoll([1, 1, 1, 1, 2]);
      notifier(c).declareBid(const Bid(DiceRank.fourOfAKind, 3));
      int challenges = 0;
      for (int i = 0; i < 20; i++) {
        if (!notifier(c).getAIAccept()) challenges++;
      }
      expect(challenges, 20);
    });
  });

  // ── GAI4: prior / escalation Liar's Dice AI ────────────────────────────────

  group('GAI4 Liar\'s Dice AI — pure helpers', () {
    test('computeLiarDiceAiBid uses honest min-face for own rank (F7)', () {
      final bid = computeLiarDiceAiBid([2, 2, 3, 4, 5], null);
      expect(bid.rank, DiceRank.onePair);
      expect(bid.face, 1);
    });

    test('GAI5 aggressive honest bid presses max face (not F7 min)', () {
      final bid = computeLiarDiceAiBid(
        [2, 2, 3, 4, 5],
        null,
        persona: GameAiPersona.aggressive,
        rng: Random(0),
      );
      expect(bid.rank, DiceRank.onePair);
      expect(bid.face, 6);
    });

    test('GAI5 tight challenges earlier than aggressive on mid bluff', () {
      // Claim is three of a kind vs our high-card hand — mid-range challenge.
      var tightChallenges = 0;
      var aggChallenges = 0;
      const n = 40;
      for (var seed = 0; seed < n; seed++) {
        final declared = const Bid(DiceRank.threeOfAKind, 3);
        final dice = [1, 2, 4, 5, 6];
        final hist = const [Bid(DiceRank.threeOfAKind, 3)];
        if (!computeLiarDiceAiAccept(
          declared: declared,
          myDice: dice,
          bidHistory: hist,
          rng: Random(seed),
          persona: GameAiPersona.tight,
        )) {
          tightChallenges++;
        }
        if (!computeLiarDiceAiAccept(
          declared: declared,
          myDice: dice,
          bidHistory: hist,
          rng: Random(seed),
          persona: GameAiPersona.aggressive,
        )) {
          aggChallenges++;
        }
      }
      expect(tightChallenges, greaterThanOrEqualTo(aggChallenges),
          reason: 'tight should challenge at least as often as aggressive');
    });

    test('GAI5 persona wires from LobbyPlayer into multiplayer seats', () {
      final c = makeContainer();
      notifier(c).initHostMode(const [
        LobbyPlayer(id: 'host', name: 'Host'),
        LobbyPlayer(
          id: 'ai_wild',
          name: 'Wildcard 1 (Normal)',
          isAI: true,
          aiPersona: GameAiPersona.chaos,
          aiDifficulty: GameAiDifficulty.normal,
        ),
      ]);
      final bot = gs(c).players.firstWhere((p) => p.id == 'ai_wild');
      expect(bot.aiPersona, GameAiPersona.chaos);
      expect(bot.aiDifficulty, GameAiDifficulty.normal);
    });

    test('computeLiarDiceAiBid escalates past lastBid with a valid raise', () {
      const last = Bid(DiceRank.threeOfAKind, 4);
      // Hand is only one pair — must bluff/escalate above three of a kind.
      final bid = computeLiarDiceAiBid([2, 2, 3, 4, 5], last);
      expect(isValidBid(bid, last), isTrue);
      expect(compareBids(bid, last), 1);
    });

    test('forced pure bluff prefers higher-prior rank when last is max-1', () {
      // Last bid is four of a kind face 6 — only five of a kind remains.
      const last = Bid(DiceRank.fourOfAKind, 6);
      final bid = computeLiarDiceAiBid([1, 2, 3, 4, 6], last);
      expect(bid.rank, DiceRank.fiveOfAKind);
      expect(isValidBid(bid, last), isTrue);
    });

    test('computeLiarDiceAiAccept always accepts when our hand beats claim', () {
      final accept = computeLiarDiceAiAccept(
        declared: const Bid(DiceRank.onePair, 2),
        myDice: [6, 6, 6, 6, 6],
        bidHistory: const [Bid(DiceRank.onePair, 2)],
        rng: Random(1),
      );
      expect(accept, isTrue);
    });

    test('computeLiarDiceAiAccept always challenges five-of-a-kind claim', () {
      for (var seed = 0; seed < 15; seed++) {
        final accept = computeLiarDiceAiAccept(
          declared: const Bid(DiceRank.fiveOfAKind, 3),
          myDice: [1, 2, 3, 4, 6],
          bidHistory: const [Bid(DiceRank.fiveOfAKind, 3)],
          rng: Random(seed),
        );
        expect(accept, isFalse, reason: 'seed $seed');
      }
    });

    test('long bid history makes mid-range claims more challengeable', () {
      // twoPair vs our onePair → rankDiff 1, prior ~0.23 > 0.1
      // With empty history ~15% challenge; with long history challenge rate rises.
      const declared = Bid(DiceRank.twoPair, 3);
      final myDice = [2, 2, 4, 5, 6];
      final longHistory = List.generate(
        5,
        (i) => Bid(DiceRank.onePair, i + 1),
      )..add(declared);

      var challengesLong = 0;
      var challengesShort = 0;
      for (var seed = 0; seed < 200; seed++) {
        if (!computeLiarDiceAiAccept(
          declared: declared,
          myDice: myDice,
          bidHistory: longHistory,
          rng: Random(seed),
        )) {
          challengesLong++;
        }
        if (!computeLiarDiceAiAccept(
          declared: declared,
          myDice: myDice,
          bidHistory: const [declared],
          rng: Random(seed),
        )) {
          challengesShort++;
        }
      }
      expect(challengesLong, greaterThan(challengesShort));
    });
  });

  // ── GameStateNotifier — disconnect handling ───────────────────────────────────

  group('GameStateNotifier — disconnect handling (_handleDisconnect)', () {
    test('game ends when fewer than 2 players remain after disconnect', () {
      final c = makeContainer();
      addTwoPlayers(c);
      // Trigger disconnect by calling the method indirectly — since it's private
      // we simulate it via the public removePlayer path to verify the guard, or
      // we go through the full multiplayer path. Here we verify the related
      // removePlayer + state check logic:
      notifier(c).removePlayer('p0');
      expect(gs(c).players.length, 1);
      // Only 1 player left — if startGame is called it should be a no-op.
      notifier(c).startGame();
      expect(gs(c).currentState, GameStateEnum.start);
    });

    test('player IDs remain correct after removePlayer', () {
      final c = makeContainer();
      notifier(c).addPlayer(const Player(id: 'a', name: 'A', isAI: false));
      notifier(c).addPlayer(const Player(id: 'b', name: 'B', isAI: false));
      notifier(c).addPlayer(const Player(id: 'c', name: 'C', isAI: false));
      notifier(c).removePlayer('b');
      final ids = gs(c).players.map((p) => p.id).toList();
      expect(ids, ['a', 'c']);
    });
  });

  // ── GameStateNotifier — multiplayer AI-seat wiring (2026-07-13) ───────────────

  group('GameStateNotifier.initHostMode — isAI wiring from LobbyPlayer', () {
    test('a LobbyPlayer with isAI: true becomes an AI Player in game state',
        () {
      final c = makeContainer();
      notifier(c).initHostMode(const [
        LobbyPlayer(id: 'host', name: 'Host'),
        LobbyPlayer(id: 'ai_1', name: 'AI 1', isAI: true),
      ]);
      final players = gs(c).players;
      expect(players.firstWhere((p) => p.id == 'host').isAI, isFalse,
          reason: 'a real joined/host seat must never be marked AI');
      expect(players.firstWhere((p) => p.id == 'ai_1').isAI, isTrue,
          reason: 'a host-added bot seat must carry isAI through to Player');
    });
  });
}
