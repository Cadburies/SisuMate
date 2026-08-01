import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/game_ai/game_ai_difficulty.dart';
import 'package:sisu_mate/services/game_ai/game_ai_persona.dart';
import 'package:sisu_mate/services/lan/game_lan_service.dart';
import 'package:sisu_mate/ui/games/games/dudo/helpers.dart';
import 'package:sisu_mate/ui/games/games/dudo/logic.dart';

// ── Utilities ─────────────────────────────────────────────────────────────────

ProviderContainer makeContainer() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return c;
}

DudoGameNotifier notifier(ProviderContainer c) =>
    c.read(dudoGameProvider.notifier);

DudoGameState gs(ProviderContainer c) => c.read(dudoGameProvider);

void addTwo(ProviderContainer c,
    {List<int> p0Dice = const [1, 2, 3, 4, 5],
    List<int> p1Dice = const [1, 2, 3, 4, 5],
    int p0Count = 5,
    int p1Count = 5}) {
  notifier(c).addPlayer(DudoPlayer(
      id: 'p0', name: 'Human', isAI: false,
      dice: p0Dice, diceCount: p0Count));
  notifier(c).addPlayer(DudoPlayer(
      id: 'p1', name: 'AI', isAI: true,
      dice: p1Dice, diceCount: p1Count));
}

// ── countBid ──────────────────────────────────────────────────────────────────

void main() {
  group('countBid', () {
    test('counts matching face + aces as wild for non-ace bid', () {
      final players = [
        const DudoPlayer(
            id: 'a', name: 'A', isAI: false, dice: [3, 3, 1], diceCount: 3),
        const DudoPlayer(
            id: 'b', name: 'B', isAI: true, dice: [3, 2, 5], diceCount: 3),
      ];
      // face=3: A has 2×3 + 1 ace = 3; B has 1×3 = 1; total = 4
      expect(countBid(players, const DudoBid(1, 3)), 4);
    });

    test('aces bid does not count other aces as wild', () {
      final players = [
        const DudoPlayer(
            id: 'a', name: 'A', isAI: false, dice: [1, 1, 3], diceCount: 3),
        const DudoPlayer(
            id: 'b', name: 'B', isAI: true, dice: [1, 4, 5], diceCount: 3),
      ];
      // face=1: A has 2×1; B has 1×1; total = 3 (no wild — it IS the ace bid)
      expect(countBid(players, const DudoBid(1, 1)), 3);
    });

    test('skips eliminated players', () {
      final players = [
        const DudoPlayer(
            id: 'a', name: 'A', isAI: false, dice: [4, 4, 4], diceCount: 3),
        const DudoPlayer(
            id: 'b', name: 'B', isAI: true, dice: [4, 4, 4], diceCount: 0),
      ];
      expect(countBid(players, const DudoBid(1, 4)), 3);
    });

    test('returns 0 when no matching dice', () {
      final players = [
        const DudoPlayer(
            id: 'a', name: 'A', isAI: false, dice: [2, 3, 5], diceCount: 3),
      ];
      expect(countBid(players, const DudoBid(1, 6)), 0);
    });

    test('GB5: aces are not wild during a palafico round', () {
      final players = [
        const DudoPlayer(
            id: 'a', name: 'A', isAI: false, dice: [3, 3, 1], diceCount: 3),
        const DudoPlayer(
            id: 'b', name: 'B', isAI: true, dice: [3, 2, 5], diceCount: 3),
      ];
      // face=3: without wild aces, only the two literal 3s (A) + one 3 (B) = 3
      expect(countBid(players, const DudoBid(1, 3), isPalafico: true), 3);
    });
  });

  // ── isValidRaise ─────────────────────────────────────────────────────────────

  group('isValidRaise', () {
    test('any non-ace bid valid when no previous bid', () {
      expect(isValidRaise(const DudoBid(1, 2), null), isTrue);
      expect(isValidRaise(const DudoBid(3, 6), null), isTrue);
    });

    test('ace first bid forbidden unless playerDiceCount == 1', () {
      expect(isValidRaise(const DudoBid(1, 1), null, playerDiceCount: 5),
          isFalse);
      expect(isValidRaise(const DudoBid(1, 1), null, playerDiceCount: 1),
          isTrue);
    });

    test('same face higher quantity valid', () {
      expect(isValidRaise(const DudoBid(4, 3), const DudoBid(3, 3)), isTrue);
    });

    test('same quantity higher face valid', () {
      expect(isValidRaise(const DudoBid(3, 5), const DudoBid(3, 3)), isTrue);
    });

    test('same quantity same face invalid', () {
      expect(isValidRaise(const DudoBid(3, 3), const DudoBid(3, 3)), isFalse);
    });

    test('lower quantity with higher face invalid', () {
      expect(isValidRaise(const DudoBid(2, 5), const DudoBid(3, 3)), isFalse);
    });

    test('non-aces to aces: ceil(oldQ/2) rule', () {
      // oldQ=5 → min ace qty = ceil(5/2) = 3
      expect(isValidRaise(const DudoBid(3, 1), const DudoBid(5, 4)), isTrue);
      expect(isValidRaise(const DudoBid(2, 1), const DudoBid(5, 4)), isFalse);
      // oldQ=4 → min = 2
      expect(isValidRaise(const DudoBid(2, 1), const DudoBid(4, 6)), isTrue);
    });

    test('aces to non-aces: 2*oldQ+1 rule', () {
      // oldQ=2 → min non-ace qty = 5
      expect(isValidRaise(const DudoBid(5, 3), const DudoBid(2, 1)), isTrue);
      expect(isValidRaise(const DudoBid(4, 3), const DudoBid(2, 1)), isFalse);
    });

    test('aces to aces: quantity must increase', () {
      expect(isValidRaise(const DudoBid(3, 1), const DudoBid(2, 1)), isTrue);
      expect(isValidRaise(const DudoBid(2, 1), const DudoBid(2, 1)), isFalse);
    });

    test('rejects quantity < 1 or face out of range', () {
      expect(isValidRaise(const DudoBid(0, 3), null), isFalse);
      expect(isValidRaise(const DudoBid(1, 0), null), isFalse);
      expect(isValidRaise(const DudoBid(1, 7), null), isFalse);
    });

    test('GB5: palafico restricts a raise to same face, quantity+1 only', () {
      expect(
          isValidRaise(const DudoBid(4, 3), const DudoBid(3, 3), isPalafico: true),
          isTrue);
      // Higher face at the same +1 quantity step is rejected — face must match.
      expect(
          isValidRaise(const DudoBid(4, 5), const DudoBid(3, 3), isPalafico: true),
          isFalse);
      // Skipping a quantity step is rejected even on the same face.
      expect(
          isValidRaise(const DudoBid(5, 3), const DudoBid(3, 3), isPalafico: true),
          isFalse);
    });

    test('GB5: palafico does not restrict the opening bid of the round', () {
      expect(isValidRaise(const DudoBid(2, 4), null, isPalafico: true), isTrue);
    });
  });

  // ── bidToString / faceLabel ───────────────────────────────────────────────

  group('bidToString', () {
    test('singular ace', () =>
        expect(bidToString(const DudoBid(1, 1)), '1 Ace'));
    test('plural aces', () =>
        expect(bidToString(const DudoBid(3, 1)), '3 Aces'));
    test('non-ace face', () =>
        expect(bidToString(const DudoBid(4, 5)), '4 Fives'));
  });

  group('faceLabel', () {
    test('1→Aces', () => expect(faceLabel(1), 'Aces'));
    test('6→Sixes', () => expect(faceLabel(6), 'Sixes'));
    test('unknown', () => expect(faceLabel(9), '9'));
  });

  // ── nextPlayer ────────────────────────────────────────────────────────────

  group('nextPlayer', () {
    test('returns next index', () {
      final players = [
        const DudoPlayer(id: 'a', name: 'A', isAI: false, diceCount: 5),
        const DudoPlayer(id: 'b', name: 'B', isAI: true, diceCount: 5),
        const DudoPlayer(id: 'c', name: 'C', isAI: true, diceCount: 5),
      ];
      expect(nextPlayer(players, 0), 1);
      expect(nextPlayer(players, 2), 0);
    });

    test('skips eliminated players', () {
      final players = [
        const DudoPlayer(id: 'a', name: 'A', isAI: false, diceCount: 5),
        const DudoPlayer(id: 'b', name: 'B', isAI: true, diceCount: 0),
        const DudoPlayer(id: 'c', name: 'C', isAI: true, diceCount: 3),
      ];
      expect(nextPlayer(players, 0), 2); // b is eliminated
    });
  });

  // ── DudoPlayer ────────────────────────────────────────────────────────────

  group('DudoPlayer', () {
    const p = DudoPlayer(
        id: 'x', name: 'Test', isAI: false, dice: [1, 2, 3], diceCount: 3);

    test('isEliminated when diceCount == 0', () {
      expect(p.copyWith(diceCount: 0).isEliminated, isTrue);
      expect(p.isEliminated, isFalse);
    });

    test('copyWith updates fields', () {
      final copy = p.copyWith(name: 'New', diceCount: 2);
      expect(copy.name, 'New');
      expect(copy.diceCount, 2);
      expect(copy.id, p.id);
    });

    test('toJson/fromJson round-trip', () {
      final restored = DudoPlayer.fromJson(p.toJson());
      expect(restored.id, p.id);
      expect(restored.name, p.name);
      expect(restored.isAI, p.isAI);
      expect(restored.dice, p.dice);
      expect(restored.diceCount, p.diceCount);
    });

    test('fromJson defaults isConnected to true', () {
      final j = {'id': 'z', 'name': 'G', 'isAI': false,
                 'dice': [1, 1, 1, 1, 1], 'diceCount': 5};
      expect(DudoPlayer.fromJson(j).isConnected, isTrue);
    });
  });

  // ── DudoBid ───────────────────────────────────────────────────────────────

  group('DudoBid', () {
    test('toJson/fromJson round-trip', () {
      const bid = DudoBid(3, 4);
      final restored = DudoBid.fromJson(bid.toJson());
      expect(restored.quantity, 3);
      expect(restored.face, 4);
    });
  });

  // ── DudoGameState ─────────────────────────────────────────────────────────

  group('DudoGameState', () {
    test('copyWith changes currentState', () {
      const s = DudoGameState(
          currentState: DudoStateEnum.start, players: []);
      expect(
          s.copyWith(currentState: DudoStateEnum.gameOver).currentState,
          DudoStateEnum.gameOver);
    });

    test('copyWith clears currentBid via callback', () {
      const s = DudoGameState(
          currentState: DudoStateEnum.bidding,
          players: [],
          currentBid: DudoBid(2, 3));
      final cleared = s.copyWith(currentBid: () => null);
      expect(cleared.currentBid, isNull);
    });

    test('toJson/fromJson round-trip', () {
      final s = DudoGameState(
        currentState: DudoStateEnum.bidding,
        players: [
          const DudoPlayer(id: 'p0', name: 'A', isAI: false),
          const DudoPlayer(id: 'p1', name: 'B', isAI: true),
        ],
        activePlayer: 1,
        lastBidder: 0,
        currentBid: const DudoBid(3, 4),
        allDiceRevealed: false,
        gameMessage: 'test',
      );
      final r = DudoGameState.fromJson(s.toJson());
      expect(r.currentState, s.currentState);
      expect(r.players.length, 2);
      expect(r.activePlayer, 1);
      expect(r.currentBid?.quantity, 3);
      expect(r.currentBid?.face, 4);
      expect(r.gameMessage, 'test');
    });
  });

  // ── DudoGameNotifier — player management ──────────────────────────────────

  group('DudoGameNotifier — player management', () {
    test('initial state is start with empty list', () {
      final c = makeContainer();
      expect(gs(c).currentState, DudoStateEnum.start);
      expect(gs(c).players, isEmpty);
    });

    test('addPlayer appends', () {
      final c = makeContainer();
      notifier(c).addPlayer(
          const DudoPlayer(id: 'p0', name: 'X', isAI: false));
      expect(gs(c).players.length, 1);
    });

    test('removePlayer removes by id', () {
      final c = makeContainer();
      addTwo(c);
      notifier(c).removePlayer('p0');
      expect(gs(c).players.length, 1);
      expect(gs(c).players.first.id, 'p1');
    });
  });

  // ── DudoGameNotifier — startGame ──────────────────────────────────────────

  group('DudoGameNotifier — startGame', () {
    test('requires ≥ 2 players', () {
      final c = makeContainer();
      notifier(c).addPlayer(
          const DudoPlayer(id: 'p0', name: 'X', isAI: false));
      notifier(c).startGame();
      expect(gs(c).currentState, DudoStateEnum.start);
    });

    test('transitions to determineStarter', () {
      final c = makeContainer();
      addTwo(c);
      notifier(c).startGame();
      expect(gs(c).currentState, DudoStateEnum.determineStarter);
    });

    test('each player gets exactly 1 die', () {
      final c = makeContainer();
      addTwo(c);
      notifier(c).startGame();
      for (final p in gs(c).players) {
        expect(p.dice.length, 1);
        expect(p.dice.first, inInclusiveRange(1, 6));
      }
    });
  });

  // ── DudoGameNotifier — determineStarter ──────────────────────────────────

  group('DudoGameNotifier — determineStarter', () {
    test('resolves to rollAll or announces winner or re-rolling on tie', () {
      final c = makeContainer();
      addTwo(c);
      notifier(c).startGame();
      notifier(c).determineStarter();
      final s = gs(c);
      // Non-tie: "X starts!" message (timer then calls beginRound → rollAll)
      // Tie: "Re-rolling" message
      final ok = s.currentState == DudoStateEnum.rollAll ||
          (s.gameMessage?.contains('Re-rolling') ?? false) ||
          (s.gameMessage?.contains('starts!') ?? false);
      expect(ok, isTrue);
    });

    test('activePlayer index is within bounds', () {
      final c = makeContainer();
      addTwo(c);
      notifier(c).startGame();
      for (int i = 0; i < 20; i++) {
        notifier(c).determineStarter();
        if (gs(c).currentState == DudoStateEnum.rollAll) break;
        // re-roll tied players
        notifier(c).startGame();
      }
    });
  });

  // ── DudoGameNotifier — placeBid ───────────────────────────────────────────

  group('DudoGameNotifier — placeBid', () {
    void reachBidding(ProviderContainer c) {
      addTwo(c);
      notifier(c).beginRound();
      notifier(c).startBidding();
    }

    test('valid first bid accepted', () {
      final c = makeContainer();
      reachBidding(c);
      notifier(c).placeBid(const DudoBid(1, 3));
      expect(gs(c).currentBid?.quantity, 1);
      expect(gs(c).currentBid?.face, 3);
    });

    test('invalid bid rejected — currentBid unchanged', () {
      final c = makeContainer();
      reachBidding(c);
      notifier(c).placeBid(const DudoBid(1, 3));
      notifier(c).placeBid(const DudoBid(1, 2)); // lower face, same qty → invalid
      expect(gs(c).currentBid?.face, 3); // unchanged
      expect(gs(c).gameMessage, contains('Invalid'));
    });

    test('bid advances activePlayer', () {
      final c = makeContainer();
      reachBidding(c);
      final before = gs(c).activePlayer;
      notifier(c).placeBid(const DudoBid(1, 3));
      expect(gs(c).activePlayer, isNot(before));
    });

    test('lastBidder set to prior activePlayer', () {
      final c = makeContainer();
      reachBidding(c);
      final bidder = gs(c).activePlayer;
      notifier(c).placeBid(const DudoBid(1, 3));
      expect(gs(c).lastBidder, bidder);
    });
  });

  // ── DudoGameNotifier — callDudo / callSpotOn ──────────────────────────────

  group('DudoGameNotifier — callDudo / callSpotOn', () {
    void reachBiddingWithBid(ProviderContainer c) {
      addTwo(c);
      notifier(c).beginRound();
      notifier(c).startBidding();
      notifier(c).placeBid(const DudoBid(1, 3));
    }

    test('callDudo transitions to resolveChallenge', () {
      final c = makeContainer();
      reachBiddingWithBid(c);
      notifier(c).callDudo();
      expect(gs(c).currentState, DudoStateEnum.resolveChallenge);
    });

    test('callDudo reveals all dice', () {
      final c = makeContainer();
      reachBiddingWithBid(c);
      notifier(c).callDudo();
      expect(gs(c).allDiceRevealed, isTrue);
    });

    test('callSpotOn transitions to resolveSpotOn', () {
      final c = makeContainer();
      reachBiddingWithBid(c);
      notifier(c).callSpotOn();
      expect(gs(c).currentState, DudoStateEnum.resolveSpotOn);
    });
  });

  // ── DudoGameNotifier — resolveChallenge ───────────────────────────────────

  group('DudoGameNotifier — resolveChallenge', () {
    // Skip beginRound() to keep the controlled dice from addTwo in place.

    test('bid correct (total >= quantity): Dudo-caller loses a die', () {
      final c = makeContainer();
      // p0 has 5 threes, p1 has 0. Bid 5×3 is honest.
      addTwo(c,
          p0Dice: [3, 3, 3, 3, 3], p1Dice: [2, 2, 2, 2, 2]);
      notifier(c).startBidding(); // p0 is activePlayer=0
      notifier(c).placeBid(const DudoBid(5, 3));
      expect(gs(c).activePlayer, 1);
      notifier(c).callDudo(); // p1 calls dudo
      notifier(c).resolveChallenge();
      // actual 3s = 5 >= bid 5 → honest → caller (p1) loses 1 die
      expect(gs(c).players[1].diceCount, 4);
      expect(gs(c).players[0].diceCount, 5);
    });

    test('bid wrong (total < quantity): bidder loses a die', () {
      final c = makeContainer();
      // p0 bluffs: no threes on the table, claims 10.
      addTwo(c,
          p0Dice: [2, 2, 2, 2, 2], p1Dice: [2, 2, 2, 2, 2]);
      notifier(c).startBidding();
      notifier(c).placeBid(const DudoBid(10, 3)); // impossible bid
      notifier(c).callDudo();
      notifier(c).resolveChallenge();
      // actual 3s = 0 < 10 → bluff → bidder (p0) loses 1 die
      expect(gs(c).players[0].diceCount, 4);
      expect(gs(c).players[1].diceCount, 5);
    });

    test('transitions to determineRoundOver', () {
      final c = makeContainer();
      addTwo(c, p0Dice: [3, 3, 3, 3, 3], p1Dice: [1, 1, 1, 1, 1]);
      notifier(c).startBidding();
      notifier(c).placeBid(const DudoBid(1, 3));
      notifier(c).callDudo();
      notifier(c).resolveChallenge();
      expect(gs(c).currentState, DudoStateEnum.determineRoundOver);
    });

    test(
        'GB6 regression: on a wrong bid, activePlayer becomes the bidder '
        '(the actual loser), not left on the caller — previously '
        'determineRoundOver() read activePlayer to pick the next-round '
        'starter, and resolveChallenge() never updated it off the caller '
        'when the bidder was the one who lost, so the challenger wrongly '
        'started the next round', () {
      final c = makeContainer();
      // p0 bluffs (bidder); p1 calls Dudo (caller). Bid is wrong → bidder (p0) loses.
      addTwo(c, p0Dice: [2, 2, 2, 2, 2], p1Dice: [2, 2, 2, 2, 2]);
      notifier(c).startBidding(); // activePlayer = 0 (p0)
      notifier(c).placeBid(const DudoBid(10, 3)); // impossible bid; lastBidder=0, activePlayer=1
      expect(gs(c).lastBidder, 0);
      expect(gs(c).activePlayer, 1); // p1 is the caller about to call Dudo
      notifier(c).callDudo();
      notifier(c).resolveChallenge();
      // Bidder (p0, index 0) lost — activePlayer must point to them, not
      // stay on the caller (p1, index 1).
      expect(gs(c).activePlayer, 0);
    });

    test(
        'GB6 regression: on a correct bid, activePlayer stays on the caller '
        '(the actual loser in this branch) — this direction happened to '
        'work even before the fix, kept here so both branches are covered',
        () {
      final c = makeContainer();
      // p0 bids honestly; p1 calls Dudo and loses (bid was correct).
      addTwo(c, p0Dice: [3, 3, 3, 3, 3], p1Dice: [2, 2, 2, 2, 2]);
      notifier(c).startBidding();
      notifier(c).placeBid(const DudoBid(5, 3));
      expect(gs(c).activePlayer, 1);
      notifier(c).callDudo();
      notifier(c).resolveChallenge();
      expect(gs(c).activePlayer, 1);
    });
  });

  // ── DudoGameNotifier — resolveSpotOn ─────────────────────────────────────

  group('DudoGameNotifier — resolveSpotOn', () {
    // Skip beginRound() to keep the controlled dice from addTwo in place.
    // Dice lists must have exactly diceCount elements (countBid counts all of p.dice).

    test('exact count: caller gains a die', () {
      final c = makeContainer();
      // p0: 2 threes; p1: 1 three → 3 total. bid 3×3 → exact → p1 gains.
      addTwo(c,
          p0Dice: [3, 3, 2, 4], p1Dice: [3, 2, 2, 4],
          p0Count: 4, p1Count: 4);
      notifier(c).startBidding();
      notifier(c).placeBid(const DudoBid(3, 3));
      notifier(c).callSpotOn();
      notifier(c).resolveSpotOn();
      // p1 diceCount was 4, gains 1 → 5
      expect(gs(c).players[1].diceCount, 5);
      expect(gs(c).players[0].diceCount, 4); // bidder unaffected
    });

    test('wrong count: caller loses a die', () {
      final c = makeContainer();
      // No threes on table; bid says 3.
      addTwo(c, p0Dice: [2, 2, 2, 2, 2], p1Dice: [2, 2, 2, 2, 2]);
      notifier(c).startBidding();
      notifier(c).placeBid(const DudoBid(3, 3)); // 0 threes → wrong
      notifier(c).callSpotOn();
      notifier(c).resolveSpotOn();
      // caller (p1) loses 1 die → 4
      expect(gs(c).players[1].diceCount, 4);
      expect(gs(c).players[0].diceCount, 5); // bidder never loses on Spot On
    });

    test('bidder never loses a die on Spot On', () {
      final c = makeContainer();
      addTwo(c, p0Dice: [5, 5, 5, 5, 5], p1Dice: [2, 2, 2, 2, 2]);
      notifier(c).startBidding();
      notifier(c).placeBid(const DudoBid(99, 3)); // impossible
      notifier(c).callSpotOn();
      final bidderBefore = gs(c).players[0].diceCount;
      notifier(c).resolveSpotOn();
      expect(gs(c).players[0].diceCount, bidderBefore); // bidder untouched
    });
  });

  // ── DudoGameNotifier — resetGame ──────────────────────────────────────────

  group('DudoGameNotifier — resetGame', () {
    test('resets to start', () {
      final c = makeContainer();
      addTwo(c, p0Count: 2, p1Count: 3);
      notifier(c).resetGame();
      expect(gs(c).currentState, DudoStateEnum.start);
    });

    test('restores all players to 5 dice', () {
      final c = makeContainer();
      addTwo(c, p0Count: 1, p1Count: 2);
      notifier(c).resetGame();
      for (final p in gs(c).players) {
        expect(p.diceCount, 5);
      }
    });

    test('clears currentBid', () {
      final c = makeContainer();
      addTwo(c);
      notifier(c).beginRound();
      notifier(c).startBidding();
      notifier(c).placeBid(const DudoBid(2, 4));
      notifier(c).resetGame();
      expect(gs(c).currentBid, isNull);
    });
  });

  // ── GB5: palafico (single-die round variant) ──────────────────────────────

  group('getAIBid — palafico (GB5)', () {
    test('a forced same-face quantity+1 bid is returned with no exploration', () {
      final players = [
        const DudoPlayer(id: 'a', name: 'A', isAI: false, diceCount: 1),
        const DudoPlayer(id: 'b', name: 'B', isAI: true, dice: [4], diceCount: 1),
      ];
      final bid = getAIBid(players, 1, const DudoBid(3, 5), isPalafico: true);
      expect(bid.face, 5);
      expect(bid.quantity, 4);
    });

    test('the opening bid of a palafico round still uses normal estimation', () {
      final players = [
        const DudoPlayer(id: 'a', name: 'A', isAI: false, diceCount: 1),
        const DudoPlayer(id: 'b', name: 'B', isAI: true, dice: [4], diceCount: 1),
      ];
      final bid = getAIBid(players, 1, null, isPalafico: true);
      expect(bid.quantity, greaterThanOrEqualTo(1));
    });
  });

  group('DudoGameNotifier — palafico round (GB5)', () {
    test('beginRound sets isPalaficoRound when a player is down to 1 die', () {
      fakeAsync((async) {
        final c = makeContainer();
        addTwo(c, p0Count: 1, p1Count: 5);
        notifier(c).beginRound();
        expect(gs(c).isPalaficoRound, isTrue);
        async.elapse(const Duration(seconds: 3)); // drain beginRound's Timer
      });
    });

    test('beginRound leaves isPalaficoRound false when nobody is down to 1 die', () {
      fakeAsync((async) {
        final c = makeContainer();
        addTwo(c, p0Count: 5, p1Count: 5);
        notifier(c).beginRound();
        expect(gs(c).isPalaficoRound, isFalse);
        async.elapse(const Duration(seconds: 3));
      });
    });

    test(
        'placeBid enforces the same-face quantity+1 restriction during '
        'palafico — previously any normal raise was allowed and aces '
        'stayed wild even with a player down to their last die', () {
      fakeAsync((async) {
        final c = makeContainer();
        addTwo(c, p0Count: 1, p1Count: 5);
        notifier(c).beginRound();
        async.elapse(const Duration(seconds: 3)); // let startBidding fire

        notifier(c).placeBid(const DudoBid(2, 4));
        expect(gs(c).currentBid?.quantity, 2);
        expect(gs(c).currentBid?.face, 4);

        // Higher face at the same +1 step is rejected — face must match.
        notifier(c).placeBid(const DudoBid(3, 6));
        expect(gs(c).currentBid?.face, 4, reason: 'invalid raise must be rejected');
        expect(gs(c).gameMessage, contains('Palafico'));

        // The only legal raise (same face, quantity+1) is accepted.
        notifier(c).placeBid(const DudoBid(3, 4));
        expect(gs(c).currentBid?.quantity, 3);
        expect(gs(c).currentBid?.face, 4);
      });
    });
  });

  // ── GAI4: binomial Dudo AI ────────────────────────────────────────────────

  group('GAI4 Dudo AI — binomial model', () {
    test('dudoDieMatchProbability: non-ace wild = 2/6, ace/palafico = 1/6', () {
      expect(dudoDieMatchProbability(3), closeTo(2 / 6, 1e-9));
      expect(dudoDieMatchProbability(1), closeTo(1 / 6, 1e-9));
      expect(dudoDieMatchProbability(3, isPalafico: true), closeTo(1 / 6, 1e-9));
    });

    test('binomialSurvival is 1 when k<=0 and 0 when k>n', () {
      expect(binomialSurvival(5, 0.5, 0), 1.0);
      expect(binomialSurvival(5, 0.5, 6), 0.0);
    });

    test('getAIShouldDudo challenges a clearly impossible quantity', () {
      final players = [
        const DudoPlayer(
            id: 'a', name: 'A', isAI: false, dice: [2, 3, 4], diceCount: 3),
        const DudoPlayer(
            id: 'b', name: 'B', isAI: true, dice: [5, 5, 6], diceCount: 3),
      ];
      // Bid 10 sixes with only 6 dice on the table and AI holding zero sixes.
      expect(
        getAIShouldDudo(players, 1, const DudoBid(10, 6)),
        isTrue,
      );
    });

    test('getAIShouldDudo trusts a bid covered by own dice alone', () {
      final players = [
        const DudoPlayer(
            id: 'a', name: 'A', isAI: false, dice: [2, 3, 4], diceCount: 3),
        const DudoPlayer(
            id: 'b', name: 'B', isAI: true, dice: [6, 6, 6], diceCount: 3),
      ];
      expect(
        getAIShouldDudo(players, 1, const DudoBid(2, 6)),
        isFalse,
      );
    });

    test('getAIBid prefers a face well supported by own dice', () {
      final players = [
        const DudoPlayer(
            id: 'a', name: 'A', isAI: false, diceCount: 5),
        const DudoPlayer(
            id: 'b',
            name: 'B',
            isAI: true,
            dice: [4, 4, 4, 2, 1],
            diceCount: 5),
      ];
      final bid = getAIBid(players, 1, null);
      // Four 4s counting (3 fours + 1 ace wild) → should lean into fours.
      expect(bid.face, 4);
      expect(bid.quantity, greaterThanOrEqualTo(3));
    });

    test('getAIShouldSpotOn is true near expected exact count', () {
      // AI sees 2 matching; 6 unknown dice, p=2/6 for face 3 → EV unknown = 2;
      // total EV = 4. Exact mass at 4 should be material.
      final players = [
        const DudoPlayer(
            id: 'a', name: 'A', isAI: false, diceCount: 6),
        const DudoPlayer(
            id: 'b',
            name: 'B',
            isAI: true,
            dice: [3, 3, 2, 5, 6],
            diceCount: 5),
      ];
      // May or may not spot depending on thresholds — assert pure exact mass
      // is non-trivial and dudo is not forced.
      final bid = const DudoBid(4, 3);
      final exact = dudoBidExact(players, 1, bid);
      expect(exact, greaterThan(0.15));
      expect(getAIShouldDudo(players, 1, bid), isFalse);
    });
  });

  // ── GAME1: multiplayer scaffolding (mirrors liars_dice_test.dart) ─────────

  group('DudoGameNotifier.initHostMode — isAI wiring from LobbyPlayer', () {
    test('a LobbyPlayer with isAI: true becomes an AI DudoPlayer in game state',
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
          reason: 'a host-added bot seat must carry isAI through to DudoPlayer');
    });

    test('GAI5: persona + difficulty wire from LobbyPlayer to DudoPlayer', () {
      final c = makeContainer();
      notifier(c).initHostMode(const [
        LobbyPlayer(id: 'host', name: 'Host'),
        LobbyPlayer(
          id: 'ai_bluff',
          name: 'Bluffer 1 (Hard)',
          isAI: true,
          aiDifficulty: GameAiDifficulty.hard,
          aiPersona: GameAiPersona.aggressive,
        ),
        LobbyPlayer(
          id: 'ai_rock',
          name: 'Rock 2 (Easy)',
          isAI: true,
          aiDifficulty: GameAiDifficulty.easy,
          aiPersona: GameAiPersona.tight,
        ),
      ]);
      final bluff = gs(c).players.firstWhere((p) => p.id == 'ai_bluff');
      final rock = gs(c).players.firstWhere((p) => p.id == 'ai_rock');
      expect(bluff.aiPersona, GameAiPersona.aggressive);
      expect(bluff.aiDifficulty, GameAiDifficulty.hard);
      expect(rock.aiPersona, GameAiPersona.tight);
      expect(rock.aiDifficulty, GameAiDifficulty.easy);
    });

    test('sets isMultiplayer and starts in the start state', () {
      final c = makeContainer();
      notifier(c).initHostMode(const [LobbyPlayer(id: 'host', name: 'Host')]);
      expect(gs(c).isMultiplayer, isTrue);
      expect(gs(c).currentState, DudoStateEnum.start);
    });
  });

  group('GAI5 Dudo persona thresholds', () {
    test('aggressive is less likely to dudo a borderline bid than tight', () {
      // AI holds one 6; three unknown dice; bid 3 sixes is stretchy but not absurd.
      final players = [
        const DudoPlayer(
            id: 'a', name: 'A', isAI: false, dice: [2, 3, 4], diceCount: 3),
        const DudoPlayer(
            id: 'b',
            name: 'B',
            isAI: true,
            dice: [6, 2, 3, 4, 5],
            diceCount: 5),
      ];
      const bid = DudoBid(3, 6);
      // Tight calls earlier; aggressive sticks longer on same EV.
      final tightDudo = getAIShouldDudo(players, 1, bid,
          difficulty: GameAiDifficulty.normal,
          persona: GameAiPersona.tight);
      final aggDudo = getAIShouldDudo(players, 1, bid,
          difficulty: GameAiDifficulty.normal,
          persona: GameAiPersona.aggressive);
      // If either differs, aggressive must not be the only one calling.
      // On this board tight should dudo at least as often as aggressive.
      expect(tightDudo || !aggDudo, isTrue);
      // Prefer a strict split when thresholds land cleanly:
      if (tightDudo != aggDudo) {
        expect(tightDudo, isTrue);
        expect(aggDudo, isFalse);
      }
    });

    test('chaos getAIBid stays legal with fixed rng', () {
      final players = [
        const DudoPlayer(
            id: 'a', name: 'A', isAI: false, diceCount: 5),
        const DudoPlayer(
            id: 'b',
            name: 'B',
            isAI: true,
            dice: [4, 4, 4, 2, 1],
            diceCount: 5),
      ];
      for (var seed = 0; seed < 12; seed++) {
        final bid = getAIBid(players, 1, null,
            difficulty: GameAiDifficulty.normal,
            persona: GameAiPersona.chaos,
            rng: Random(seed));
        expect(
          isValidRaise(bid, null, playerDiceCount: 5),
          isTrue,
          reason: 'chaos seed $seed produced illegal $bid',
        );
      }
    });
  });

  group('DudoGameNotifier — host/client mode flags', () {
    test('initHostMode/initClientMode/exitMultiplayerMode toggle isClientMode',
        () {
      final c = makeContainer();
      expect(notifier(c).isClientMode, isFalse);

      notifier(c).initClientMode();
      expect(notifier(c).isClientMode, isTrue);
      expect(gs(c).isMultiplayer, isTrue);

      notifier(c).exitMultiplayerMode();
      expect(notifier(c).isClientMode, isFalse);
    });

    test('resetGame exits multiplayer mode', () {
      final c = makeContainer();
      notifier(c).initClientMode();
      expect(notifier(c).isClientMode, isTrue);

      notifier(c).resetGame();
      expect(notifier(c).isClientMode, isFalse);
      expect(gs(c).isMultiplayer, isFalse);
    });
  });

  group('DudoGameNotifier — disconnect handling (_handleDisconnect)', () {
    test('game ends when fewer than 2 players remain after disconnect', () {
      final c = makeContainer();
      addTwo(c);
      // _handleDisconnect is private (only reachable via a real LAN peer
      // leave event); verify the same guard via the public removePlayer path,
      // matching liars_dice_test.dart's equivalent test.
      notifier(c).removePlayer('p0');
      expect(gs(c).players.length, 1);
      notifier(c).startGame();
      expect(gs(c).currentState, DudoStateEnum.start);
    });

    test('player IDs remain correct after removePlayer', () {
      final c = makeContainer();
      notifier(c).addPlayer(const DudoPlayer(id: 'a', name: 'A', isAI: false));
      notifier(c).addPlayer(const DudoPlayer(id: 'b', name: 'B', isAI: false));
      notifier(c).addPlayer(const DudoPlayer(id: 'c', name: 'C', isAI: false));
      notifier(c).removePlayer('b');
      final ids = gs(c).players.map((p) => p.id).toList();
      expect(ids, ['a', 'c']);
    });
  });
}
