import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sisu_mate/ui/games/games/poker/logic.dart';

// Card encoding: 0-51. suit = c ~/ 13 (0=♣ 1=♦ 2=♥ 3=♠), rank = c % 13 (0=2 … 12=A)
int _card(int rank, int suit) => suit * 13 + rank;

// Lets tests seed an arbitrary betting state directly, rather than only
// reachable via a random deal with the default 500-chip starting stacks.
class _SeededPokerNotifier extends PokerNotifier {
  final PokerState initial;
  _SeededPokerNotifier(this.initial);
  @override
  PokerState build() => initial;
}

ProviderContainer _makeSeeded(PokerState initial) {
  final c = ProviderContainer(overrides: [
    pokerStateProvider.overrideWith(() => _SeededPokerNotifier(initial)),
  ]);
  addTearDown(c.dispose);
  return c;
}

PokerState _bettingState({
  required int playerChips,
  required int aiChips,
  required int pot,
  int playerCurrentBet = 0,
  int aiCurrentBet = 0,
  PokerPhase phase = PokerPhase.betting1,
  bool isPlayerTurn = true,
  bool isMultiplayer = false,
  bool isOpponentAI = true,
}) =>
    PokerState(
      deck: List.generate(20, (i) => i + 20), // arbitrary, unused by betting logic
      playerHand: [_card(0, 0), _card(1, 0), _card(2, 0), _card(3, 1), _card(4, 1)],
      aiHand: [_card(5, 0), _card(6, 0), _card(7, 0), _card(8, 1), _card(9, 1)],
      selectedDiscard: const {},
      playerChips: playerChips,
      aiChips: aiChips,
      pot: pot,
      playerCurrentBet: playerCurrentBet,
      aiCurrentBet: aiCurrentBet,
      phase: phase,
      message: '',
      isPlayerTurn: isPlayerTurn,
      isMultiplayer: isMultiplayer,
      isOpponentAI: isOpponentAI,
    );

void main() {
  // ── Hand evaluation ───────────────────────────────────────────────────────

  group('evaluateHand', () {
    test('high card', () {
      // 2♣ 4♣ 6♣ 8♦ 10♥ — no pairs, no straight, no flush
      final hand = [
        _card(0, 0), _card(2, 0), _card(4, 0), _card(6, 1), _card(8, 2),
      ];
      expect(evaluateHand(hand).rank, HandRank.highCard);
    });

    test('one pair', () {
      final hand = [
        _card(0, 0), _card(0, 1), _card(2, 0), _card(4, 1), _card(6, 2),
      ];
      expect(evaluateHand(hand).rank, HandRank.onePair);
    });

    test('two pair', () {
      final hand = [
        _card(0, 0), _card(0, 1), _card(2, 0), _card(2, 1), _card(6, 2),
      ];
      expect(evaluateHand(hand).rank, HandRank.twoPair);
    });

    test('three of a kind', () {
      final hand = [
        _card(5, 0), _card(5, 1), _card(5, 2), _card(1, 0), _card(3, 1),
      ];
      expect(evaluateHand(hand).rank, HandRank.threeOfAKind);
    });

    test('straight', () {
      // 2♣ 3♦ 4♥ 5♠ 6♣ — ranks 0,1,2,3,4
      final hand = [
        _card(0, 0), _card(1, 1), _card(2, 2), _card(3, 3), _card(4, 0),
      ];
      expect(evaluateHand(hand).rank, HandRank.straight);
    });

    test('flush', () {
      // All clubs, non-sequential ranks
      final hand = [
        _card(0, 0), _card(2, 0), _card(5, 0), _card(8, 0), _card(11, 0),
      ];
      expect(evaluateHand(hand).rank, HandRank.flush);
    });

    test('full house', () {
      final hand = [
        _card(3, 0), _card(3, 1), _card(3, 2), _card(7, 0), _card(7, 1),
      ];
      expect(evaluateHand(hand).rank, HandRank.fullHouse);
    });

    test('four of a kind', () {
      final hand = [
        _card(9, 0), _card(9, 1), _card(9, 2), _card(9, 3), _card(4, 0),
      ];
      expect(evaluateHand(hand).rank, HandRank.fourOfAKind);
    });

    test('straight flush', () {
      // 2♣ 3♣ 4♣ 5♣ 6♣
      final hand = [
        _card(0, 0), _card(1, 0), _card(2, 0), _card(3, 0), _card(4, 0),
      ];
      expect(evaluateHand(hand).rank, HandRank.straightFlush);
    });

    test('royal flush', () {
      // 10♣ J♣ Q♣ K♣ A♣ — ranks 8,9,10,11,12
      final hand = [
        _card(8, 0), _card(9, 0), _card(10, 0), _card(11, 0), _card(12, 0),
      ];
      expect(evaluateHand(hand).rank, HandRank.royalFlush);
    });

    test('wheel straight A-2-3-4-5', () {
      // Ace(rank=12), 2(rank=0), 3(rank=1), 4(rank=2), 5(rank=3) — mixed suits
      final hand = [
        _card(12, 0), _card(0, 1), _card(1, 2), _card(2, 3), _card(3, 0),
      ];
      expect(evaluateHand(hand).rank, HandRank.straight);
    });
  });

  // ── HandResult comparison ─────────────────────────────────────────────────

  group('HandResult.compareTo', () {
    test('higher rank wins', () {
      final flush = evaluateHand([
        _card(0, 0), _card(2, 0), _card(5, 0), _card(8, 0), _card(11, 0),
      ]);
      final pair = evaluateHand([
        _card(0, 0), _card(0, 1), _card(2, 0), _card(4, 1), _card(6, 2),
      ]);
      expect(flush.compareTo(pair), greaterThan(0));
    });

    test('same rank: higher tiebreaker wins', () {
      // Pair of Aces (rank=12) vs Pair of 2s (rank=0)
      final pairAces = evaluateHand([
        _card(12, 0), _card(12, 1), _card(3, 0), _card(5, 1), _card(7, 2),
      ]);
      final pairTwos = evaluateHand([
        _card(0, 0), _card(0, 1), _card(3, 0), _card(5, 1), _card(7, 2),
      ]);
      expect(pairAces.compareTo(pairTwos), greaterThan(0));
    });

    test('identical hands compare as 0', () {
      final h1 = evaluateHand([
        _card(0, 0), _card(0, 1), _card(2, 0), _card(4, 1), _card(6, 2),
      ]);
      final h2 = evaluateHand([
        _card(0, 2), _card(0, 3), _card(2, 1), _card(4, 2), _card(6, 3),
      ]);
      expect(h1.compareTo(h2), 0);
    });

    test(
        'GB4: a wheel (A-2-3-4-5) ranks below a 6-high straight, not above '
        'it — the Ace plays low in a wheel, so it must be the *lowest* '
        'straight, not compare as Ace-high', () {
      final wheel = evaluateHand([
        _card(12, 0), _card(0, 1), _card(1, 2), _card(2, 3), _card(3, 0),
      ]); // A,2,3,4,5 mixed suits
      final sixHigh = evaluateHand([
        _card(1, 0), _card(2, 1), _card(3, 2), _card(4, 3), _card(5, 0),
      ]); // 3,4,5,6,7 mixed suits
      expect(wheel.rank, HandRank.straight);
      expect(sixHigh.rank, HandRank.straight);
      expect(wheel.compareTo(sixHigh), lessThan(0),
          reason: 'a wheel must lose to any higher straight');
      expect(sixHigh.compareTo(wheel), greaterThan(0));
    });

    test(
        'GB4: a steel wheel (A-2-3-4-5 same suit) also ranks below a '
        'higher straight flush, not above it', () {
      final steelWheel = evaluateHand([
        _card(12, 0), _card(0, 0), _card(1, 0), _card(2, 0), _card(3, 0),
      ]); // A,2,3,4,5 all ♣
      final higherStraightFlush = evaluateHand([
        _card(1, 1), _card(2, 1), _card(3, 1), _card(4, 1), _card(5, 1),
      ]); // 3,4,5,6,7 all ♦
      expect(steelWheel.rank, HandRank.straightFlush);
      expect(higherStraightFlush.rank, HandRank.straightFlush);
      expect(steelWheel.compareTo(higherStraightFlush), lessThan(0));
    });
  });

  // ── PokerNotifier ─────────────────────────────────────────────────────────

  group('PokerNotifier', () {
    ProviderContainer make() {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      return c;
    }

    test('initial state: 500 chips each, betting1 phase', () {
      final c = make();
      final s = c.read(pokerStateProvider);
      expect(s.phase, PokerPhase.betting1);
      // Each player starts with 500 minus the ante (10)
      expect(s.playerChips, 490);
      expect(s.aiChips, 490);
      expect(s.pot, 20); // 2 × ante
    });

    test('each player dealt 5 cards', () {
      final c = make();
      final s = c.read(pokerStateProvider);
      expect(s.playerHand.length, 5);
      expect(s.aiHand.length, 5);
    });

    test('no duplicates in dealt cards', () {
      final c = make();
      final s = c.read(pokerStateProvider);
      final dealt = {...s.playerHand, ...s.aiHand};
      expect(dealt.length, 10); // all unique
    });

    test('playerFold transitions to roundOver and awards pot to AI', () {
      final c = make();
      final before = c.read(pokerStateProvider).aiChips;
      final pot = c.read(pokerStateProvider).pot;
      c.read(pokerStateProvider.notifier).playerFold();
      final s = c.read(pokerStateProvider);
      expect(s.phase, PokerPhase.roundOver);
      expect(s.aiChips, before + pot);
      expect(s.outcome, 'AI wins');
    });

    test('toggleDiscard only works in draw phase', () {
      final c = make();
      c.read(pokerStateProvider.notifier).toggleDiscard(0);
      expect(c.read(pokerStateProvider).selectedDiscard, isEmpty);
    });

    test('playerBet in betting1 moves to draw', () {
      final c = make();
      c.read(pokerStateProvider.notifier).playerBet();
      expect(c.read(pokerStateProvider).phase, PokerPhase.draw);
    });

    test('confirmDraw replaces selected cards', () {
      final c = make();
      c.read(pokerStateProvider.notifier).playerBet(); // → draw
      final handBefore = [...c.read(pokerStateProvider).playerHand];
      c.read(pokerStateProvider.notifier).toggleDiscard(0);
      c.read(pokerStateProvider.notifier).toggleDiscard(1);
      c.read(pokerStateProvider.notifier).confirmDraw();
      final handAfter = c.read(pokerStateProvider).playerHand;
      // Cards at index 0 and 1 should have changed
      expect(handAfter[0] != handBefore[0] || handAfter[1] != handBefore[1], isTrue);
    });

    test('nextRound starts a new round', () {
      final c = make();
      c.read(pokerStateProvider.notifier).playerFold();
      c.read(pokerStateProvider.notifier).nextRound();
      expect(c.read(pokerStateProvider).phase, PokerPhase.betting1);
    });

    test('playerCheck transitions out of betting1', () {
      final c = make();
      c.read(pokerStateProvider.notifier).playerCheck();
      final s = c.read(pokerStateProvider);
      // Either AI checked (→ draw) or AI bet back (→ stays in betting1)
      expect(
        s.phase == PokerPhase.draw || s.phase == PokerPhase.betting1,
        isTrue,
      );
    });

    test('newGame resets chips to 500 each and deals fresh', () {
      final c = make();
      c.read(pokerStateProvider.notifier).playerFold();
      c.read(pokerStateProvider.notifier).newGame();
      final s = c.read(pokerStateProvider);
      expect(s.playerChips + s.pot + (500 - s.aiChips - s.pot), 500);
      expect(s.phase, PokerPhase.betting1);
    });
  });

  // ── GB3: uncalled-bet return (heads-up equivalent of a side pot) ─────────

  group('uncalled-bet return (GB3)', () {
    test(
        'playerBet: a short-stacked all-in bet cannot be over-matched by '
        'AI — previously AI always called the full nominal bet amount '
        'regardless of what you actually had to bet', () {
      final c = _makeSeeded(_bettingState(
        playerChips: 5, // less than the $20 nominal bet — an effective all-in
        aiChips: 500,
        pot: 100,
      ));
      c.read(pokerStateProvider.notifier).playerBet();
      final s = c.read(pokerStateProvider);
      expect(s.playerChips, 0, reason: 'bet your entire short stack');
      expect(s.aiChips, 495, reason: 'AI must only match the 5 you bet, not 20');
      expect(s.pot, 110, reason: '100 + your 5 + AI\'s matching 5');
    });

    test('playerBet: AI still calls the full amount when you can afford it',
        () {
      final c = _makeSeeded(_bettingState(
        playerChips: 100,
        aiChips: 500,
        pot: 100,
      ));
      c.read(pokerStateProvider.notifier).playerBet();
      final s = c.read(pokerStateProvider);
      expect(s.playerChips, 80);
      expect(s.aiChips, 480);
      expect(s.pot, 140);
    });

    test(
        'playerCall: when you cannot fully match AI\'s bet, the uncalled '
        'portion is returned to AI\'s stack rather than left in the pot '
        'uncontested', () {
      final c = _makeSeeded(_bettingState(
        playerChips: 5, // can only call 5 of the 20 owed
        aiChips: 500,
        pot: 100, // already includes AI's full bet contribution
        playerCurrentBet: 10,
        aiCurrentBet: 30, // 20 more than you — that's what's owed
      ));
      c.read(pokerStateProvider.notifier).playerCall();
      final s = c.read(pokerStateProvider);
      expect(s.playerChips, 0, reason: 'called all-in for your short stack');
      expect(s.aiChips, 515, reason: '500 + the 15 AI over-bet that you couldn\'t call');
      expect(s.pot, 90, reason: '100 + your 5 - the 15 returned to AI');
      expect(s.playerCurrentBet, 15);
    });

    test('playerCall: a full call moves no chips back to AI', () {
      final c = _makeSeeded(_bettingState(
        playerChips: 100,
        aiChips: 500,
        pot: 100,
        playerCurrentBet: 10,
        aiCurrentBet: 30,
      ));
      c.read(pokerStateProvider.notifier).playerCall();
      final s = c.read(pokerStateProvider);
      expect(s.playerChips, 80);
      expect(s.aiChips, 500, reason: 'unchanged — nothing to return on a full call');
      expect(s.pot, 120);
    });
  });

  // ── GAME1 multiplayer ─────────────────────────────────────────────────────

  group('PokerNotifier — multiplayer (absolute host/guest)', () {
    test('JSON round-trip preserves multiplayer fields and hands', () {
      final original = PokerState(
        deck: [10, 11, 12],
        playerHand: [_card(12, 0), _card(11, 0), _card(10, 0), _card(9, 0), _card(8, 0)],
        aiHand: [_card(0, 1), _card(1, 1), _card(2, 1), _card(3, 1), _card(4, 1)],
        selectedDiscard: {1, 3},
        selectedAiDiscard: {0},
        playerChips: 400,
        aiChips: 450,
        pot: 50,
        playerCurrentBet: 30,
        aiCurrentBet: 20,
        phase: PokerPhase.draw,
        message: 'Select cards',
        isPlayerTurn: false,
        isMultiplayer: true,
        isOpponentAI: false,
        hostDrawConfirmed: true,
        guestDrawConfirmed: false,
      );
      final restored = PokerState.fromJson(original.toJson());
      expect(restored.deck, original.deck);
      expect(restored.playerHand, original.playerHand);
      expect(restored.aiHand, original.aiHand);
      expect(restored.selectedDiscard, original.selectedDiscard);
      expect(restored.selectedAiDiscard, original.selectedAiDiscard);
      expect(restored.playerChips, 400);
      expect(restored.aiChips, 450);
      expect(restored.pot, 50);
      expect(restored.phase, PokerPhase.draw);
      expect(restored.isPlayerTurn, isFalse);
      expect(restored.isMultiplayer, isTrue);
      expect(restored.isOpponentAI, isFalse);
      expect(restored.hostDrawConfirmed, isTrue);
      expect(restored.guestDrawConfirmed, isFalse);
    });

    test(
        'regression: guest can bet on their turn — role-aware via isPlayerTurn, '
        'not hardcoded player-only chips', () {
      final c = _makeSeeded(_bettingState(
        playerChips: 200,
        aiChips: 200,
        pot: 20,
        playerCurrentBet: 10,
        aiCurrentBet: 10,
        isPlayerTurn: false, // guest's action
        isMultiplayer: true,
        isOpponentAI: false,
      ));
      c.read(pokerStateProvider.notifier).playerBet();
      final s = c.read(pokerStateProvider);
      expect(s.aiChips, 180, reason: 'guest (ai role) pays the bet');
      expect(s.playerChips, 200, reason: 'host stack untouched until call');
      expect(s.pot, 40);
      expect(s.aiCurrentBet, 30);
      expect(s.isPlayerTurn, isTrue, reason: 'hand off to host for call/fold');
      expect(s.phase, PokerPhase.betting1,
          reason: 'must wait for host response — no auto-call');
    });

    test(
        'host bet does not auto-call a real guest — waits for call/fold', () {
      final c = _makeSeeded(_bettingState(
        playerChips: 200,
        aiChips: 200,
        pot: 20,
        playerCurrentBet: 10,
        aiCurrentBet: 10,
        isMultiplayer: true,
        isOpponentAI: false,
      ));
      c.read(pokerStateProvider.notifier).playerBet();
      final s = c.read(pokerStateProvider);
      expect(s.playerChips, 180);
      expect(s.aiChips, 200, reason: 'guest has not called yet');
      expect(s.pot, 40);
      expect(s.isPlayerTurn, isFalse);
      expect(s.phase, PokerPhase.betting1);
    });

    test('guest call after host bet advances to draw', () {
      final c = _makeSeeded(_bettingState(
        playerChips: 180,
        aiChips: 200,
        pot: 40,
        playerCurrentBet: 30,
        aiCurrentBet: 10,
        isPlayerTurn: false, // guest to call
        isMultiplayer: true,
        isOpponentAI: false,
      ));
      c.read(pokerStateProvider.notifier).playerCall();
      final s = c.read(pokerStateProvider);
      expect(s.phase, PokerPhase.draw);
      expect(s.aiChips, 180);
      expect(s.pot, 60);
      expect(s.aiCurrentBet, 30);
    });

    test('guest fold after host bet awards pot to host', () {
      final c = _makeSeeded(_bettingState(
        playerChips: 180,
        aiChips: 200,
        pot: 40,
        playerCurrentBet: 30,
        aiCurrentBet: 10,
        isPlayerTurn: false,
        isMultiplayer: true,
        isOpponentAI: false,
      ));
      c.read(pokerStateProvider.notifier).playerFold();
      final s = c.read(pokerStateProvider);
      expect(s.phase, PokerPhase.roundOver);
      expect(s.playerChips, 220);
      expect(s.pot, 0);
      expect(s.outcome, 'You win');
    });

    test('simultaneous draw: both must confirm before betting2', () {
      final c = _makeSeeded(PokerState(
        deck: List.generate(20, (i) => i + 20),
        playerHand: [_card(0, 0), _card(1, 0), _card(2, 0), _card(3, 1), _card(4, 1)],
        aiHand: [_card(5, 0), _card(6, 0), _card(7, 0), _card(8, 1), _card(9, 1)],
        selectedDiscard: {0},
        selectedAiDiscard: {1, 2},
        playerChips: 200,
        aiChips: 200,
        pot: 40,
        playerCurrentBet: 20,
        aiCurrentBet: 20,
        phase: PokerPhase.draw,
        message: '',
        isMultiplayer: true,
        isOpponentAI: false,
      ));
      final n = c.read(pokerStateProvider.notifier);
      n.confirmDraw();
      expect(c.read(pokerStateProvider).phase, PokerPhase.draw);
      expect(c.read(pokerStateProvider).hostDrawConfirmed, isTrue);
      n.confirmAiDraw();
      final s = c.read(pokerStateProvider);
      expect(s.phase, PokerPhase.betting2);
      expect(s.hostDrawConfirmed, isFalse);
      expect(s.guestDrawConfirmed, isFalse);
    });

    test('initClientMode sets isClientMode; exit and newGame clear it', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = c.read(pokerStateProvider.notifier);
      expect(n.isClientMode, isFalse);
      n.initClientMode();
      expect(n.isClientMode, isTrue);
      expect(c.read(pokerStateProvider).message, 'Waiting for host...');
      n.exitMultiplayerMode();
      expect(n.isClientMode, isFalse);
      n.initClientMode();
      n.newGame();
      expect(n.isClientMode, isFalse);
      expect(c.read(pokerStateProvider).isMultiplayer, isFalse);
    });

    test('no AI auto-play after host check when opponent is real guest', () {
      final c = _makeSeeded(_bettingState(
        playerChips: 200,
        aiChips: 200,
        pot: 20,
        playerCurrentBet: 10,
        aiCurrentBet: 10,
        isMultiplayer: true,
        isOpponentAI: false,
      ));
      c.read(pokerStateProvider.notifier).playerCheck();
      final s = c.read(pokerStateProvider);
      expect(s.phase, PokerPhase.betting1, reason: 'waiting on guest');
      expect(s.isPlayerTurn, isFalse);
      expect(s.aiChips, 200, reason: 'guest has not bet or checked yet');
      expect(s.pot, 20);
    });
  });
}
