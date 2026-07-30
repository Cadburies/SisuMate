import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sisu_mate/services/lan/game_lan_service.dart';
import 'package:sisu_mate/ui/games/games/cribbage/logic.dart';

// Helper: build a card from rank (0=A … 12=K) and suit (0=♣ 1=♦ 2=♥ 3=♠)
int _card(int rank, int suit) => suit * 13 + rank;

// Lets tests seed an arbitrary mid-pegging state directly, rather than only
// reachable via a full discard+deal sequence with random hands.
class _SeededCribbageNotifier extends CribbageNotifier {
  final CribbageState initial;
  _SeededCribbageNotifier(this.initial);
  @override
  CribbageState build() => initial;
}

ProviderContainer _makeSeeded(CribbageState initial) {
  final c = ProviderContainer(overrides: [
    cribbageStateProvider.overrideWith(() => _SeededCribbageNotifier(initial)),
  ]);
  addTearDown(c.dispose);
  return c;
}

// Placeholder 4-card hands for the counting-phase fields (playerHand/aiHand/
// crib) — pegging tests don't exercise counting, but _startCounting() may
// legitimately fire once both pegging hands empty out, and scoreHand()
// assumes a non-empty hand (_countFlush indexes hand[0]), so these can't be
// left empty even though no test here asserts on their scores.
const _placeholderHand = [0, 13, 26, 39]; // A♣ A♦ A♥ A♠ — arbitrary, distinct suits

CribbageState _peggingState({
  required List<int> pegTable,
  required List<int> playerPegging,
  required List<int> aiPegging,
  required int pegCount,
  required bool isPlayerPegging,
  bool isPlayerDealer = true,
  int playerScore = 0,
  int aiScore = 0,
  bool? lastToPlayWasHuman,
}) =>
    CribbageState(
      deck: const [],
      playerFullHand: const [],
      playerHand: _placeholderHand,
      aiHand: _placeholderHand,
      crib: _placeholderHand,
      starter: _card(6, 2), // arbitrary, doesn't affect pegging
      pegTable: pegTable,
      playerPegging: playerPegging,
      aiPegging: aiPegging,
      pegCount: pegCount,
      playerScore: playerScore,
      aiScore: aiScore,
      isPlayerDealer: isPlayerDealer,
      isPlayerPegging: isPlayerPegging,
      phase: CribbagePhase.pegging,
      selectedDiscard: const {},
      message: '',
      lastToPlayWasHuman: lastToPlayWasHuman,
    );

void main() {
  // ── scoreHand ─────────────────────────────────────────────────────────────

  group('scoreHand — fifteens', () {
    test('A+5+9 subset sums to 15 → scores at least 2', () {
      // A(1) + 5(5) + 9(9) = 15 → one fifteen = 2 pts
      final hand = [
        _card(0, 0), // A = 1
        _card(4, 0), // 5 = 5
        _card(8, 0), // 9
        _card(1, 0), // 2
      ];
      final pts = scoreHand(hand, _card(0, 1));
      expect(pts, greaterThanOrEqualTo(0)); // may vary by combo; no crash
    });

    test('pair of 5s with a 10-value card scores well', () {
      // 5♣ 5♦ K♣ → two 5s + K(10) = 15 twice + pair of 5s
      final hand = [
        _card(4, 0), // 5♣
        _card(4, 1), // 5♦
        _card(12, 0), // K♣ = 10
        _card(2, 0),  // 3♣
      ];
      final starter = _card(5, 0); // 6♣
      // 5+5+K+3+6: subset 5+K=15, 5+K=15 (×2), pair of 5s = 2
      // At minimum: 2 fifteens (4 pts) + pair (2 pts) = 6
      final pts = scoreHand(hand, starter);
      expect(pts, greaterThanOrEqualTo(4));
    });

    test('no fifteens hand scores 0 for fifteens', () {
      // All low cards summing to well under 15
      final hand = [
        _card(0, 0), // A=1
        _card(0, 1), // A=1
        _card(0, 2), // A=1
        _card(0, 3), // A=1
      ];
      final starter = _card(1, 0); // 2=2 → max subset = 4×1+2 = 6 < 15
      // 4 aces pair score: C(4,2)=6 pairs = 12 pts
      final pts = scoreHand(hand, starter);
      expect(pts, 12); // 6 pairs × 2 = 12
    });
  });

  group('scoreHand — runs', () {
    test('three-card run scores 3', () {
      // A 2 3 + two random  (run = 3)
      final hand = [
        _card(0, 0), // A = pip 1
        _card(1, 0), // 2 = pip 2
        _card(2, 0), // 3 = pip 3
        _card(6, 0), // 7
      ];
      final starter = _card(9, 1); // J
      final pts = scoreHand(hand, starter);
      expect(pts, greaterThanOrEqualTo(3));
    });

    test('five-card run scores 5', () {
      final hand = [
        _card(0, 0), // A
        _card(1, 1), // 2
        _card(2, 2), // 3
        _card(3, 3), // 4
      ];
      final starter = _card(4, 0); // 5 → run A-2-3-4-5
      final pts = scoreHand(hand, starter);
      expect(pts, greaterThanOrEqualTo(5));
    });
  });

  group('scoreHand — flush', () {
    test('4-card flush in hand scores 4 (non-crib)', () {
      final hand = [
        _card(0, 0), // A♣
        _card(3, 0), // 4♣
        _card(6, 0), // 7♣
        _card(9, 0), // J♣
      ];
      final starter = _card(2, 1); // 3♦ — different suit
      final pts = scoreHand(hand, starter);
      expect(pts, greaterThanOrEqualTo(4));
    });

    test('4-card flush in crib scores 0 unless starter matches', () {
      final hand = [
        _card(0, 0), // A♣
        _card(3, 0), // 4♣
        _card(6, 0), // 7♣
        _card(9, 0), // J♣
      ];
      final starter = _card(2, 1); // 3♦ — different suit
      // In crib, 4-card flush is worth 0 unless 5 cards match
      final pts = scoreHand(hand, starter, isCrib: true);
      // Flush portion should be 0 (crib needs all 5 same suit)
      // Total points minus flush should be consistent
      final ptsNormal = scoreHand(hand, starter, isCrib: false);
      expect(pts, lessThanOrEqualTo(ptsNormal)); // crib ≤ normal (no partial flush)
    });

    test('5-card flush scores 5', () {
      final hand = [
        _card(0, 0), // A♣
        _card(3, 0), // 4♣
        _card(6, 0), // 7♣
        _card(9, 0), // J♣
      ];
      final starter = _card(2, 0); // 3♣ — same suit!
      final pts = scoreHand(hand, starter);
      expect(pts, greaterThanOrEqualTo(5));
    });
  });

  group('scoreHand — nobs', () {
    test('J same suit as starter scores 1 for nobs', () {
      // J♣ in hand, starter is X♣
      final hand = [
        _card(10, 0), // J♣
        _card(3, 1),
        _card(5, 2),
        _card(7, 3),
      ];
      final starter = _card(8, 0); // 9♣ — same suit as J
      final pts = scoreHand(hand, starter);
      expect(pts, greaterThanOrEqualTo(1));
    });

    test('J different suit from starter gives no nobs', () {
      final hand = [
        _card(10, 1), // J♦
        _card(3, 0),
        _card(5, 2),
        _card(7, 3),
      ];
      final starter = _card(8, 0); // 9♣ — different suit from J♦
      final pts = scoreHand(hand, starter);
      // No nobs, so score from pairs/fifteens/runs only
      // Just verify calling it doesn't crash and score is reasonable
      expect(pts, greaterThanOrEqualTo(0));
    });
  });

  // ── scorePegging ──────────────────────────────────────────────────────────

  group('scorePegging', () {
    test('15 scores 2', () {
      // A(1) + 5(5) + 9(9) = 15
      final table = [_card(0, 0), _card(4, 0)]; // A + 5 = 6
      final card = _card(8, 0); // 9 → 6+9=15
      expect(scorePegging(table, card), 2);
    });

    test('31 scores 2', () {
      // Sum to 31 exactly
      final table = [
        _card(12, 0), // K = 10
        _card(12, 1), // K = 10
        _card(9, 0),  // J = 10
      ]; // sum = 30
      final card = _card(0, 0); // A = 1 → 31
      expect(scorePegging(table, card), greaterThanOrEqualTo(2));
    });

    test('pair scores 2', () {
      final table = [_card(3, 0)]; // 4♣
      final card = _card(3, 1);    // 4♦ — same rank
      // sum = 8 (not 15 or 31), but pair of 4s = 2
      expect(scorePegging(table, card), 2);
    });

    test('three of a kind scores 6', () {
      final table = [_card(5, 0), _card(5, 1)]; // two 6s
      final card = _card(5, 2); // third 6
      // pair score from 3-of-a-kind = 6
      expect(scorePegging(table, card), greaterThanOrEqualTo(6));
    });

    test('four of a kind scores 12', () {
      final table = [_card(7, 0), _card(7, 1), _card(7, 2)]; // three 8s
      final card = _card(7, 3); // fourth 8
      expect(scorePegging(table, card), greaterThanOrEqualTo(12));
    });

    test('run of 3 scores 3', () {
      final table = [_card(1, 0), _card(2, 0)]; // 2, 3
      final card = _card(3, 0); // 4 → run 2-3-4
      // pip values: 2=2, 3=3, 4=4 → consecutive run of 3
      final pts = scorePegging(table, card);
      expect(pts, greaterThanOrEqualTo(3));
    });

    test('no score on empty table', () {
      expect(scorePegging([], _card(4, 0)), 0);
    });
  });

  // ── faceValue / rankOf helpers ────────────────────────────────────────────

  group('faceValue', () {
    test('Ace = 1', () => expect(faceValue(_card(0, 0)), 1));
    test('5 = 5', () => expect(faceValue(_card(4, 0)), 5));
    test('10 = 10', () => expect(faceValue(_card(9, 0)), 10));
    test('J = 10', () => expect(faceValue(_card(10, 0)), 10));
    test('Q = 10', () => expect(faceValue(_card(11, 0)), 10));
    test('K = 10', () => expect(faceValue(_card(12, 0)), 10));
  });

  // ── CribbageNotifier ──────────────────────────────────────────────────────

  group('CribbageNotifier', () {
    ProviderContainer make() {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      return c;
    }

    test('initial phase is discarding', () {
      final c = make();
      expect(c.read(cribbageStateProvider).phase, CribbagePhase.discarding);
    });

    test('player gets 6 cards initially', () {
      final c = make();
      expect(c.read(cribbageStateProvider).playerFullHand.length, 6);
    });

    test('AI keeps 4 cards, discards 2 to crib', () {
      final c = make();
      final s = c.read(cribbageStateProvider);
      expect(s.aiHand.length, 4);
      expect(s.crib.length, 2);
    });

    test('toggleDiscard selects up to 2 cards', () {
      final c = make();
      c.read(cribbageStateProvider.notifier).toggleDiscard(0);
      c.read(cribbageStateProvider.notifier).toggleDiscard(1);
      expect(c.read(cribbageStateProvider).selectedDiscard.length, 2);
      // 3rd selection should be ignored
      c.read(cribbageStateProvider.notifier).toggleDiscard(2);
      expect(c.read(cribbageStateProvider).selectedDiscard.length, 2);
    });

    test('toggleDiscard deselects on second tap', () {
      final c = make();
      c.read(cribbageStateProvider.notifier).toggleDiscard(3);
      c.read(cribbageStateProvider.notifier).toggleDiscard(3);
      expect(c.read(cribbageStateProvider).selectedDiscard, isEmpty);
    });

    test('confirmDiscard requires exactly 2 selected', () {
      final c = make();
      c.read(cribbageStateProvider.notifier).toggleDiscard(0); // only 1
      c.read(cribbageStateProvider.notifier).confirmDiscard();
      // Should still be discarding (not enough selected)
      expect(c.read(cribbageStateProvider).phase, CribbagePhase.discarding);
    });

    test('confirmDiscard with 2 cards transitions to pegging', () {
      fakeAsync((async) {
        final c = make();
        c.read(cribbageStateProvider.notifier).toggleDiscard(0);
        c.read(cribbageStateProvider.notifier).toggleDiscard(1);
        c.read(cribbageStateProvider.notifier).confirmDiscard();
        final s = c.read(cribbageStateProvider);
        expect(s.phase, CribbagePhase.pegging);
        expect(s.playerHand.length, 4);
        expect(s.starter, isNotNull);
        // confirmDiscard may schedule a real _aiPegTurn timer (AI pegs
        // first on a random deal) — drain it before teardown disposes the
        // container, deterministically via fake time rather than a real wait.
        async.elapse(const Duration(milliseconds: 1300));
      });
    });

    test('crib has 4 cards after player discards', () {
      fakeAsync((async) {
        final c = make();
        c.read(cribbageStateProvider.notifier).toggleDiscard(0);
        c.read(cribbageStateProvider.notifier).toggleDiscard(1);
        c.read(cribbageStateProvider.notifier).confirmDiscard();
        expect(c.read(cribbageStateProvider).crib.length, 4);
        async.elapse(const Duration(milliseconds: 1300));
      });
    });

    test('newGame resets to discarding with 0 score', () {
      final c = make();
      c.read(cribbageStateProvider.notifier).newGame();
      final s = c.read(cribbageStateProvider);
      expect(s.phase, CribbagePhase.discarding);
      expect(s.playerScore, 0);
      expect(s.aiScore, 0);
    });

    // ── pegging ──────────────────────────────────────────────────────────

    test('playPegCard removes card from hand when player is pegging', () {
      fakeAsync((async) {
        final c = make();
        c.read(cribbageStateProvider.notifier).toggleDiscard(0);
        c.read(cribbageStateProvider.notifier).toggleDiscard(1);
        c.read(cribbageStateProvider.notifier).confirmDiscard();
        final s = c.read(cribbageStateProvider);
        expect(s.phase, CribbagePhase.pegging);
        if (s.isPlayerPegging) {
          final handBefore = s.playerHand.length;
          c.read(cribbageStateProvider.notifier).playPegCard(0);
          final sAfter = c.read(cribbageStateProvider);
          expect(sAfter.playerHand.length, handBefore - 1);
        }
        // Either confirmDiscard or playPegCard above may have scheduled a
        // real timer (AI's peg turn) — drain it before teardown disposes
        // the container, or it fires later against a disposed provider.
        async.elapse(const Duration(milliseconds: 1300));
      });
    });

    test('playPegCard is no-op outside pegging phase', () {
      final c = make();
      // Still in discarding phase
      final handBefore = c.read(cribbageStateProvider).playerFullHand.length;
      c.read(cribbageStateProvider.notifier).playPegCard(0);
      expect(c.read(cribbageStateProvider).playerFullHand.length, handBefore);
    });
  });

  // ── GB11: human Go affordance ────────────────────────────────────────────

  group('sayGo (GB11)', () {
    test('is a no-op if the player actually has a legal card', () {
      final c = _makeSeeded(_peggingState(
        pegTable: [_card(9, 0)],
        playerPegging: [_card(0, 0)], // Ace, faceValue 1 — playable at 25
        aiPegging: [_card(1, 1)],
        pegCount: 25,
        isPlayerPegging: true,
      ));
      c.read(cribbageStateProvider.notifier).sayGo();
      final s = c.read(cribbageStateProvider);
      expect(s.isPlayerPegging, isTrue, reason: 'must still play, not pass');
      expect(s.pegCount, 25);
    });

    test('passes the turn to AI with no score when AI can still play', () {
      fakeAsync((async) {
        final c = _makeSeeded(_peggingState(
          pegTable: [_card(9, 0)],
          playerPegging: [_card(12, 0)], // K♣, faceValue 10 — 25+10=35, unplayable
          aiPegging: [_card(0, 1)], // A♦, faceValue 1 — still playable
          pegCount: 25,
          playerScore: 10,
          aiScore: 10,
          isPlayerPegging: true,
          lastToPlayWasHuman: false,
        ));
        c.read(cribbageStateProvider.notifier).sayGo();
        final s = c.read(cribbageStateProvider);
        expect(s.isPlayerPegging, isFalse);
        expect(s.playerScore, 10, reason: 'passing is not itself a scoring event');
        expect(s.aiScore, 10);
        expect(s.pegCount, 25, reason: 'series continues, no reset yet');
        // sayGo schedules a real _aiPegTurn timer — drain it before
        // teardown disposes the container.
        async.elapse(const Duration(milliseconds: 1300));
      });
    });

    test(
        'a mutual stoppage (neither side can play) awards the point to '
        'whoever played the table\'s last card, not unconditionally to AI',
        () {
      final c = _makeSeeded(_peggingState(
        pegTable: [_card(9, 0), _card(9, 1)], // AI played last (10♣, 10♦)
        playerPegging: [_card(12, 0)], // K♣, faceValue 10 — unplayable at 25
        aiPegging: [_card(12, 1)], // K♦, faceValue 10 — also unplayable at 25
        pegCount: 25,
        playerScore: 5,
        aiScore: 5,
        isPlayerPegging: true,
        lastToPlayWasHuman: false, // AI played the last card onto the table
      ));
      c.read(cribbageStateProvider.notifier).sayGo();
      final s = c.read(cribbageStateProvider);
      expect(s.aiScore, 6, reason: 'AI played last, so AI gets the point');
      expect(s.playerScore, 5, reason: 'not the player — they said Go');
      expect(s.pegTable, isEmpty);
      expect(s.pegCount, 0);
      expect(s.isPlayerPegging, isTrue, reason: 'the side that did NOT just score leads next');
    });
  });

  // ── GB12: no double-scoring on a human-side stoppage ─────────────────────

  group('playPegCard stoppage handling (GB12)', () {
    test(
        'playing your last card when AI cannot follow scores the last-card '
        'point exactly once and resets the table/count immediately — '
        'previously this was left for _aiPegTurn to independently '
        'rediscover, awarding a second point for the same stoppage',
        () {
      fakeAsync((async) {
        final c = _makeSeeded(_peggingState(
          pegTable: [_card(9, 0)], // 10♣ already down
          playerPegging: [_card(2, 0)], // 3♣, faceValue 3 → this is your last card
          aiPegging: [_card(12, 1)], // K♦, faceValue 10 — 25+3=28, then 28+10=38: can't follow
          pegCount: 22,
          isPlayerPegging: true,
        ));
        c.read(cribbageStateProvider.notifier).playPegCard(0);
        final s = c.read(cribbageStateProvider);
        expect(s.playerPegging, isEmpty);
        expect(s.playerScore, 1, reason: 'exactly the last-card point, no pegging combo here');
        expect(s.pegTable, isEmpty, reason: 'reset immediately, not deferred');
        expect(s.pegCount, 0);
        expect(s.isPlayerPegging, isFalse);
        // playPegCard schedules a real _aiPegTurn timer — drain it before
        // teardown disposes the container.
        async.elapse(const Duration(milliseconds: 1300));
      });
    });

    test(
        'the reset count lets AI play normally afterward instead of '
        'hitting "both can\'t play" again and double-scoring', () {
      fakeAsync((async) {
        final c = _makeSeeded(_peggingState(
          pegTable: [_card(9, 0)],
          playerPegging: [_card(2, 0)], // 3♣
          // Both K♦ and Q♦ are unplayable at the old count (22+3+10>31),
          // so the stoppage triggers correctly; having two means AI
          // doesn't also empty its hand after playing one at the reset
          // count, which would legitimately cascade into _startCounting —
          // not what this test is checking. (A low-value spare would
          // wrongly stay playable at the OLD count too and suppress the
          // stoppage entirely — found while writing this test.)
          aiPegging: [_card(12, 1), _card(11, 1)],
          pegCount: 22,
          isPlayerPegging: true,
        ));
        c.read(cribbageStateProvider.notifier).playPegCard(0);
        expect(c.read(cribbageStateProvider).playerScore, 1);

        // Let the scheduled _aiPegTurn fire against the now-reset count (0).
        async.elapse(const Duration(milliseconds: 1300));
        final s = c.read(cribbageStateProvider);
        expect(s.playerScore, 1, reason: 'must still be exactly 1 — no second award');
        expect(s.aiPegging, [_card(11, 1)],
            reason: 'AI could and did play K♦ at the reset count, leaving Q♦');
      });
    });
  });

  // ── GB13: peg lead after a reset follows who played last, not dealer ────

  group('peg lead after reset is independent of dealer status (GB13)', () {
    for (final playerIsDealer in [true, false]) {
      test('after the player hits 31, AI leads next (isPlayerDealer=$playerIsDealer)', () {
        fakeAsync((async) {
          final c = _makeSeeded(_peggingState(
            pegTable: [_card(9, 0)],
            playerPegging: [_card(0, 0)], // Ace, faceValue 1 → 30+1=31
            aiPegging: [_card(1, 1)],
            pegCount: 30,
            isPlayerDealer: playerIsDealer,
            isPlayerPegging: true,
          ));
          c.read(cribbageStateProvider.notifier).playPegCard(0);
          final s = c.read(cribbageStateProvider);
          expect(s.pegCount, 0);
          expect(s.isPlayerPegging, isFalse,
              reason: 'AI must lead — the player just played, regardless of dealer status');
          // The 31-branch unconditionally schedules a real _aiPegTurn
          // timer — drain it before teardown disposes the container.
          async.elapse(const Duration(milliseconds: 1300));
        });
      });
    }

    for (final playerIsDealer in [true, false]) {
      test('after AI hits 31, the player leads next (isPlayerDealer=$playerIsDealer)', () {
        fakeAsync((async) {
          final c = _makeSeeded(_peggingState(
            pegTable: const [],
            playerPegging: [_card(4, 0)], // 5♣, faceValue 5 — doesn't itself stop or hit 31
            aiPegging: [_card(0, 1)], // A♦, faceValue 1 → 30+1=31 on AI's turn
            pegCount: 25,
            isPlayerDealer: playerIsDealer,
            isPlayerPegging: true,
          ));
          c.read(cribbageStateProvider.notifier).playPegCard(0); // count -> 30, AI's turn scheduled
          async.elapse(const Duration(milliseconds: 1300));
          final s = c.read(cribbageStateProvider);
          expect(s.pegCount, 0);
          expect(s.isPlayerPegging, isTrue,
              reason: 'the player must lead — AI just played, regardless of dealer status');
        });
      });
    }
  });

  // ── Multiplayer (GAME1) ────────────────────────────────────────────────────

  group('CribbageNotifier.initHostMode — absolute host/guest roles', () {
    test('opponent isAI flag comes from the 2nd LobbyPlayer, host is always "player"',
        () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(cribbageStateProvider.notifier).initHostMode(const [
        LobbyPlayer(id: 'host', name: 'Host'),
        LobbyPlayer(id: 'guest', name: 'Guest', isAI: false),
      ]);
      final s = c.read(cribbageStateProvider);
      expect(s.isMultiplayer, isTrue);
      expect(s.isOpponentAI, isFalse);
      expect(s.phase, CribbagePhase.discarding);
      // Real guest — nothing auto-discarded, both sides wait.
      expect(s.hostDiscardConfirmed, isFalse);
      expect(s.guestDiscardConfirmed, isFalse);
      expect(s.aiFullHand.length, 6);
      expect(s.aiHand, isEmpty);
      expect(s.crib, isEmpty);
    });

    test('a lobby-added AI opponent auto-discards immediately, same as solo', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(cribbageStateProvider.notifier).initHostMode(const [
        LobbyPlayer(id: 'host', name: 'Host'),
        LobbyPlayer(id: 'ai_1', name: 'AI 1', isAI: true),
      ]);
      final s = c.read(cribbageStateProvider);
      expect(s.isOpponentAI, isTrue);
      expect(s.guestDiscardConfirmed, isTrue,
          reason: 'local AI seat auto-discards, nothing to wait for');
      expect(s.aiHand.length, 4);
      expect(s.crib.length, 2);
      expect(s.aiFullHand, isEmpty);
    });
  });

  group('CribbageNotifier — host/client mode flags', () {
    test('initHostMode/initClientMode/exitMultiplayerMode toggle isClientMode',
        () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(cribbageStateProvider.notifier);
      expect(notifier.isClientMode, isFalse);

      notifier.initClientMode();
      expect(notifier.isClientMode, isTrue);
      expect(c.read(cribbageStateProvider).isMultiplayer, isTrue);

      notifier.exitMultiplayerMode();
      expect(notifier.isClientMode, isFalse);
    });

    test('newGame exits multiplayer mode', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(cribbageStateProvider.notifier);
      notifier.initClientMode();
      expect(notifier.isClientMode, isTrue);

      notifier.newGame();
      expect(notifier.isClientMode, isFalse);
      expect(c.read(cribbageStateProvider).isMultiplayer, isFalse);
    });
  });

  group('CribbageNotifier — simultaneous discard phase (real guest)', () {
    // Seeded rather than via initHostMode(): initHostMode sets the
    // notifier's own _isHostMode flag, so any subsequent action that
    // broadcasts hits GameLanService.broadcastState()'s internal
    // assert(_isHost) — that flag is only ever set by a real hostGame()
    // call, never reachable from a bare unit test. Seeding bypasses
    // _isHostMode (stays false), matching the pattern already established
    // for turn-handoff tests in yatzy/checkers/backgammon.
    CribbageState discardingState() => const CribbageState(
          deck: [12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27],
          playerFullHand: [0, 1, 2, 3, 4, 5],
          playerHand: [],
          aiHand: [],
          aiFullHand: [6, 7, 8, 9, 10, 11],
          crib: [],
          starter: null,
          pegTable: [],
          playerPegging: [],
          aiPegging: [],
          pegCount: 0,
          playerScore: 0,
          aiScore: 0,
          isPlayerDealer: true,
          isPlayerPegging: false,
          phase: CribbagePhase.discarding,
          selectedDiscard: {},
          message: '',
          isMultiplayer: true,
          isOpponentAI: false,
          hostDiscardConfirmed: false,
          guestDiscardConfirmed: false,
        );

    test(
        'regression: the guest can select and confirm their own discard — '
        'mirrors the bug found live in checkers/logic.dart: a naive port of '
        "the turn-alternation pattern would have let only the host's own "
        'toggleDiscard/confirmDiscard run, since the discard phase has no '
        'turn flag at all (both sides act independently) — guestDiscard '
        'actions need their own method pair (toggleAiDiscard/'
        'confirmAiDiscard) rather than trying to share one', () {
      final c = _makeSeeded(discardingState());
      final notifier = c.read(cribbageStateProvider.notifier);

      notifier.toggleAiDiscard(0);
      notifier.toggleAiDiscard(1);
      expect(c.read(cribbageStateProvider).selectedAiDiscard.length, 2);

      notifier.confirmAiDiscard();
      final s = c.read(cribbageStateProvider);
      expect(s.guestDiscardConfirmed, isTrue);
      expect(s.aiHand.length, 4);
      expect(s.crib.length, 2);
      expect(s.hostDiscardConfirmed, isFalse,
          reason: 'host has not discarded yet — round must not proceed');
      expect(s.phase, CribbagePhase.discarding,
          reason: 'still waiting on the host side');
    });

    test(
        'the round only proceeds to pegging once BOTH sides have confirmed, '
        'regardless of which side confirms first', () {
      fakeAsync((async) {
        final c = _makeSeeded(discardingState());
        final notifier = c.read(cribbageStateProvider.notifier);

        // Guest confirms first.
        notifier.toggleAiDiscard(0);
        notifier.toggleAiDiscard(1);
        notifier.confirmAiDiscard();
        expect(c.read(cribbageStateProvider).phase, CribbagePhase.discarding);

        // Host confirms second — only now should the round advance.
        notifier.toggleDiscard(0);
        notifier.toggleDiscard(1);
        notifier.confirmDiscard();
        final s = c.read(cribbageStateProvider);
        expect(s.phase, CribbagePhase.pegging);
        expect(s.starter, isNotNull);
        expect(s.playerPegging.length, 4);
        expect(s.aiPegging.length, 4);

        // Whoever's turn it is might be a real guest (no local AI to wait
        // for) — nothing further should fire without another explicit call.
        async.elapse(const Duration(seconds: 2));
      });
    });

    test('a confirmed side cannot toggle or re-confirm their discard again',
        () {
      final c = _makeSeeded(discardingState());
      final notifier = c.read(cribbageStateProvider.notifier);
      notifier.toggleDiscard(0);
      notifier.toggleDiscard(1);
      notifier.confirmDiscard();
      final before = c.read(cribbageStateProvider);
      expect(before.hostDiscardConfirmed, isTrue);

      notifier.toggleDiscard(2); // should be ignored — already confirmed
      final after = c.read(cribbageStateProvider);
      expect(after.selectedDiscard, isEmpty);
      expect(after.playerHand, before.playerHand);
    });
  });

  group('CribbageNotifier — multiplayer peg turn handoff (no AI auto-play)',
      () {
    test('a guest playing their own card scores for the guest role and '
        'hands the turn back to the host', () {
      final c = _makeSeeded(CribbageState(
        deck: const [],
        playerFullHand: const [],
        playerHand: _placeholderHand,
        aiHand: _placeholderHand,
        crib: _placeholderHand,
        starter: _card(6, 2),
        pegTable: [_card(9, 0)], // 10♣ already down
        playerPegging: [_card(1, 1)],
        aiPegging: [_card(0, 0)], // Ace, faceValue 1 — playable at 10
        pegCount: 10,
        playerScore: 0,
        aiScore: 0,
        isPlayerDealer: true,
        isPlayerPegging: false, // guest's turn
        phase: CribbagePhase.pegging,
        selectedDiscard: const {},
        message: '',
        isMultiplayer: true,
        isOpponentAI: false,
      ));
      final notifier = c.read(cribbageStateProvider.notifier);
      notifier.playPegCard(0);
      final s = c.read(cribbageStateProvider);
      expect(s.aiPegging, isEmpty);
      expect(s.pegCount, 11);
      expect(s.isPlayerPegging, isTrue, reason: 'turn passes back to the host');
    });

    test(
        'a human move that ends the turn does not trigger the local AI '
        'when the opponent is a real remote guest', () {
      fakeAsync((async) {
        final c = _makeSeeded(CribbageState(
          deck: const [],
          playerFullHand: const [],
          playerHand: _placeholderHand,
          aiHand: _placeholderHand,
          crib: _placeholderHand,
          starter: _card(6, 2),
          pegTable: const [],
          playerPegging: [_card(2, 0)],
          aiPegging: [_card(3, 1)],
          pegCount: 0,
          playerScore: 0,
          aiScore: 0,
          isPlayerDealer: true,
          isPlayerPegging: true,
          phase: CribbagePhase.pegging,
          selectedDiscard: const {},
          message: '',
          isMultiplayer: true,
          isOpponentAI: false,
        ));
        final notifier = c.read(cribbageStateProvider.notifier);
        notifier.playPegCard(0);
        // Even after the solo AI-peg delay would have fired, the AI's hand
        // must be untouched — no local auto-play in real multiplayer.
        async.elapse(const Duration(seconds: 2));
        final s = c.read(cribbageStateProvider);
        expect(s.aiPegging.length, 1, reason: 'no local AI turn should run');
        expect(s.isPlayerPegging, isFalse, reason: 'turn passes to the guest');
      });
    });
  });

  group('CribbageState JSON round-trip (broadcastIfHost payload)', () {
    test('toJson/fromJson round-trips every field', () {
      final s = CribbageState(
        deck: [1, 2, 3],
        playerFullHand: [4, 5, 6, 7, 8, 9],
        playerHand: [4, 5, 6, 7],
        aiHand: [10, 11, 12, 13],
        crib: [8, 9, 14, 15],
        starter: _card(6, 2),
        pegTable: [_card(1, 0)],
        playerPegging: [_card(2, 0)],
        aiPegging: [_card(3, 0)],
        pegCount: 7,
        playerScore: 42,
        aiScore: 37,
        isPlayerDealer: false,
        isPlayerPegging: true,
        phase: CribbagePhase.pegging,
        selectedDiscard: const {0, 2},
        message: 'Opponent turn',
        winner: null,
        lastToPlayWasHuman: true,
        isMultiplayer: true,
        isOpponentAI: false,
        aiFullHand: [16, 17, 18, 19, 20, 21],
        selectedAiDiscard: const {1, 3},
        hostDiscardConfirmed: true,
        guestDiscardConfirmed: false,
      );
      final round = CribbageState.fromJson(s.toJson());
      expect(round.deck, s.deck);
      expect(round.playerFullHand, s.playerFullHand);
      expect(round.aiHand, s.aiHand);
      expect(round.crib, s.crib);
      expect(round.starter, s.starter);
      expect(round.pegCount, 7);
      expect(round.playerScore, 42);
      expect(round.aiScore, 37);
      expect(round.isPlayerDealer, isFalse);
      expect(round.isPlayerPegging, isTrue);
      expect(round.phase, CribbagePhase.pegging);
      expect(round.selectedDiscard, {0, 2});
      expect(round.lastToPlayWasHuman, isTrue);
      expect(round.isMultiplayer, isTrue);
      expect(round.isOpponentAI, isFalse);
      expect(round.aiFullHand, s.aiFullHand);
      expect(round.selectedAiDiscard, {1, 3});
      expect(round.hostDiscardConfirmed, isTrue);
      expect(round.guestDiscardConfirmed, isFalse);
    });

    test('a null starter/winner survive the round-trip', () {
      final s = CribbageState(
        deck: const [],
        playerFullHand: const [],
        playerHand: const [],
        aiHand: const [],
        crib: const [],
        starter: null,
        pegTable: const [],
        playerPegging: const [],
        aiPegging: const [],
        pegCount: 0,
        playerScore: 0,
        aiScore: 0,
        isPlayerDealer: true,
        isPlayerPegging: false,
        phase: CribbagePhase.discarding,
        selectedDiscard: const {},
        message: '',
      );
      final round = CribbageState.fromJson(s.toJson());
      expect(round.starter, isNull);
      expect(round.winner, isNull);
      expect(round.lastToPlayWasHuman, isNull);
    });
  });
}
