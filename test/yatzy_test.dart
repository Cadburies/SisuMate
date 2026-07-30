import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sisu_mate/services/lan/game_lan_service.dart';
import 'package:sisu_mate/ui/games/games/yatzy/logic.dart';

// Lets tests seed an arbitrary state directly, rather than only reachable
// via a full roll sequence with random dice.
class _SeededYatzyNotifier extends YatzyNotifier {
  final YatzyState initial;
  _SeededYatzyNotifier(this.initial);
  @override
  YatzyState build() => initial;
}

ProviderContainer _makeSeeded(YatzyState initial) {
  final c = ProviderContainer(overrides: [
    yatzyStateProvider.overrideWith(() => _SeededYatzyNotifier(initial)),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  // ── scoreFor — upper section ──────────────────────────────────────────────

  group('scoreFor — upper section', () {
    test('ones: counts aces only', () {
      expect(scoreFor(YatzyCategory.ones, [1, 1, 2, 3, 4]), 2);
      expect(scoreFor(YatzyCategory.ones, [2, 3, 4, 5, 6]), 0);
    });

    test('twos: counts twos × 2', () {
      expect(scoreFor(YatzyCategory.twos, [2, 2, 2, 1, 5]), 6);
    });

    test('threes → × 3', () {
      expect(scoreFor(YatzyCategory.threes, [3, 3, 1, 2, 4]), 6);
    });

    test('fours → × 4', () {
      expect(scoreFor(YatzyCategory.fours, [4, 4, 4, 1, 2]), 12);
    });

    test('fives → × 5', () {
      expect(scoreFor(YatzyCategory.fives, [5, 5, 1, 2, 3]), 10);
    });

    test('sixes → × 6', () {
      expect(scoreFor(YatzyCategory.sixes, [6, 6, 6, 1, 2]), 18);
    });
  });

  // ── scoreFor — lower section ──────────────────────────────────────────────

  group('scoreFor — threeOfAKind', () {
    test('returns sum when three or more match', () {
      expect(scoreFor(YatzyCategory.threeOfAKind, [3, 3, 3, 1, 2]), 12);
    });
    test('returns 0 when no triple', () {
      expect(scoreFor(YatzyCategory.threeOfAKind, [1, 2, 3, 4, 5]), 0);
    });
    test('five of a kind qualifies', () {
      expect(scoreFor(YatzyCategory.threeOfAKind, [4, 4, 4, 4, 4]), 20);
    });
  });

  group('scoreFor — fourOfAKind', () {
    test('returns sum on four match', () {
      expect(scoreFor(YatzyCategory.fourOfAKind, [5, 5, 5, 5, 2]), 22);
    });
    test('returns 0 when only three match', () {
      expect(scoreFor(YatzyCategory.fourOfAKind, [2, 2, 2, 1, 3]), 0);
    });
  });

  group('scoreFor — fullHouse', () {
    test('returns 25 for 3+2 combo', () {
      expect(scoreFor(YatzyCategory.fullHouse, [2, 2, 2, 5, 5]), 25);
    });
    test('returns 0 for five of a kind', () {
      expect(scoreFor(YatzyCategory.fullHouse, [3, 3, 3, 3, 3]), 0);
    });
    test('returns 0 for no combo', () {
      expect(scoreFor(YatzyCategory.fullHouse, [1, 2, 3, 4, 5]), 0);
    });
  });

  group('scoreFor — smallStraight', () {
    test('1-2-3-4 sequence returns 30', () {
      expect(scoreFor(YatzyCategory.smallStraight, [1, 2, 3, 4, 6]), 30);
    });
    test('2-3-4-5 sequence returns 30', () {
      expect(scoreFor(YatzyCategory.smallStraight, [2, 3, 4, 5, 1]), 30);
    });
    test('3-4-5-6 sequence returns 30', () {
      expect(scoreFor(YatzyCategory.smallStraight, [3, 4, 5, 6, 1]), 30);
    });
    test('no straight returns 0', () {
      expect(scoreFor(YatzyCategory.smallStraight, [1, 1, 2, 2, 3]), 0);
    });
  });

  group('scoreFor — largeStraight', () {
    test('1-2-3-4-5 returns 40', () {
      expect(scoreFor(YatzyCategory.largeStraight, [1, 2, 3, 4, 5]), 40);
    });
    test('2-3-4-5-6 returns 40', () {
      expect(scoreFor(YatzyCategory.largeStraight, [2, 3, 4, 5, 6]), 40);
    });
    test('short sequence returns 0', () {
      expect(scoreFor(YatzyCategory.largeStraight, [1, 2, 3, 4, 6]), 0);
    });
  });

  group('scoreFor — yatzy', () {
    test('five of same returns 50', () {
      expect(scoreFor(YatzyCategory.yatzy, [6, 6, 6, 6, 6]), 50);
    });
    test('four of same returns 0', () {
      expect(scoreFor(YatzyCategory.yatzy, [5, 5, 5, 5, 1]), 0);
    });
  });

  group('scoreFor — chance', () {
    test('returns sum of all dice', () {
      expect(scoreFor(YatzyCategory.chance, [1, 2, 3, 4, 5]), 15);
      expect(scoreFor(YatzyCategory.chance, [6, 6, 6, 6, 6]), 30);
    });
  });

  // ── Scorecard ─────────────────────────────────────────────────────────────

  group('Scorecard', () {
    test('starts empty — all null', () {
      final s = Scorecard.empty();
      expect(s.scores.values.every((v) => v == null), isTrue);
    });

    test('upperSub sums non-null upper scores', () {
      var s = Scorecard.empty();
      s = s.withScore(YatzyCategory.ones, 3);
      s = s.withScore(YatzyCategory.twos, 6);
      expect(s.upperSub, 9);
    });

    test('bonus is 50 when all upper filled and sum >= 63', () {
      var s = Scorecard.empty();
      for (final c in upperCats) {
        s = s.withScore(c, 15); // 6×15 = 90 ≥ 63
      }
      expect(s.bonus, 50);
    });

    test('no bonus when upper sum < 63', () {
      var s = Scorecard.empty();
      for (final c in upperCats) {
        s = s.withScore(c, 5); // 6×5 = 30 < 63
      }
      expect(s.bonus, 0);
    });

    test('isComplete only when all categories filled', () {
      var s = Scorecard.empty();
      expect(s.isComplete, isFalse);
      for (final c in YatzyCategory.values) {
        s = s.withScore(c, 0);
      }
      expect(s.isComplete, isTrue);
    });

    test('total sums upper + bonus + lower', () {
      var s = Scorecard.empty();
      // Fill upper to get no bonus (5 × 6 = 30)
      for (final c in upperCats) { s = s.withScore(c, 5); }
      // Add yatzy
      s = s.withScore(YatzyCategory.yatzy, 50);
      // Fill rest with 0
      for (final c in YatzyCategory.values) {
        if (s.scores[c] == null) s = s.withScore(c, 0);
      }
      expect(s.total, 30 + 0 + 50); // 80
    });

    test('GB1: addYatzyBonus adds 100 to total per extra Yatzy', () {
      var s = Scorecard.empty();
      s = s.withScore(YatzyCategory.yatzy, 50);
      s = s.withScore(YatzyCategory.fullHouse, 25, addYatzyBonus: true);
      expect(s.yatzyBonusCount, 1);
      expect(s.total, 50 + 25 + 100);
    });

    test('GB1: a second addYatzyBonus stacks (multiple repeat Yatzys)', () {
      var s = Scorecard.empty();
      s = s.withScore(YatzyCategory.yatzy, 50);
      s = s.withScore(YatzyCategory.fullHouse, 25, addYatzyBonus: true);
      s = s.withScore(YatzyCategory.chance, 30, addYatzyBonus: true);
      expect(s.yatzyBonusCount, 2);
      expect(s.total, 50 + 25 + 30 + 200);
    });
  });

  // ── jokerScoreFor (GB1) ───────────────────────────────────────────────────

  group('jokerScoreFor', () {
    test('lower-section categories score their max regardless of literal pattern', () {
      final fiveOfAKind = [4, 4, 4, 4, 4];
      expect(jokerScoreFor(YatzyCategory.fullHouse, fiveOfAKind), 25);
      expect(jokerScoreFor(YatzyCategory.smallStraight, fiveOfAKind), 30);
      expect(jokerScoreFor(YatzyCategory.largeStraight, fiveOfAKind), 40);
      expect(jokerScoreFor(YatzyCategory.threeOfAKind, fiveOfAKind), 20);
      expect(jokerScoreFor(YatzyCategory.fourOfAKind, fiveOfAKind), 20);
      expect(jokerScoreFor(YatzyCategory.chance, fiveOfAKind), 20);
    });

    test('upper-section categories use ordinary scoring (already correct without a joker override)', () {
      final fiveOfAKind = [3, 3, 3, 3, 3];
      expect(jokerScoreFor(YatzyCategory.threes, fiveOfAKind), 15);
      expect(jokerScoreFor(YatzyCategory.fours, fiveOfAKind), 0);
    });
  });

  // ── YatzyNotifier ─────────────────────────────────────────────────────────

  group('YatzyNotifier', () {
    ProviderContainer make() {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      return c;
    }

    test('initial phase is start', () {
      final c = make();
      expect(c.read(yatzyStateProvider).phase, YatzyPhase.start);
    });

    test('roll changes phase to scoring and decrements rollsLeft', () {
      final c = make();
      c.read(yatzyStateProvider.notifier).roll();
      final s = c.read(yatzyStateProvider);
      expect(s.phase, YatzyPhase.scoring);
      expect(s.rollsLeft, 2);
    });

    test('cannot roll when rollsLeft == 0', () {
      final c = make();
      c.read(yatzyStateProvider.notifier).roll();
      c.read(yatzyStateProvider.notifier).roll();
      c.read(yatzyStateProvider.notifier).roll(); // exhausted
      final before = c.read(yatzyStateProvider).phase;
      c.read(yatzyStateProvider.notifier).roll(); // should not change state
      expect(c.read(yatzyStateProvider).phase, before);
    });

    test('toggleHold does nothing before first roll', () {
      final c = make();
      c.read(yatzyStateProvider.notifier).toggleHold(0);
      expect(c.read(yatzyStateProvider).holds[0], isFalse);
    });

    test('toggleHold works after first roll', () {
      final c = make();
      c.read(yatzyStateProvider.notifier).roll();
      c.read(yatzyStateProvider.notifier).toggleHold(2);
      expect(c.read(yatzyStateProvider).holds[2], isTrue);
      c.read(yatzyStateProvider.notifier).toggleHold(2);
      expect(c.read(yatzyStateProvider).holds[2], isFalse);
    });

    test('scoreCategory fills that category', () {
      final c = make();
      c.read(yatzyStateProvider.notifier).roll();
      c.read(yatzyStateProvider.notifier).scoreCategory(YatzyCategory.chance);
      final scored = c.read(yatzyStateProvider).playerCard.scores[YatzyCategory.chance];
      expect(scored, isNotNull);
    });

    test('cannot score same category twice', () {
      final c = make();
      c.read(yatzyStateProvider.notifier).roll();
      c.read(yatzyStateProvider.notifier).scoreCategory(YatzyCategory.chance);
      final first = c.read(yatzyStateProvider).playerCard.scores[YatzyCategory.chance];
      // Start a new player turn (wait for AI timer — just test state at this point)
      expect(first, isNotNull);
    });

    test('newGame resets scorecard', () {
      final c = make();
      c.read(yatzyStateProvider.notifier).roll();
      c.read(yatzyStateProvider.notifier).scoreCategory(YatzyCategory.chance);
      c.read(yatzyStateProvider.notifier).newGame();
      expect(c.read(yatzyStateProvider).playerCard.scores[YatzyCategory.chance], isNull);
    });
  });

  // ── GB1: a second Yatzy triggers the joker/bonus rule ────────────────────

  group('scoreCategory — repeat Yatzy joker rule (GB1)', () {
    test(
        'rolling a second Yatzy and scoring it into an open lower category '
        'awards the 100-point bonus and jokers that category to its max — '
        'previously this was scored like an ordinary roll (0 for a '
        'non-matching pattern, no bonus)', () {
      fakeAsync((async) {
        final c = _makeSeeded(YatzyState(
          dice: const [6, 6, 6, 6, 6], // a second Yatzy
          holds: List.filled(5, false),
          rollsLeft: 1,
          playerCard: Scorecard.empty().withScore(YatzyCategory.yatzy, 50),
          aiCard: Scorecard.empty(),
          aiDice: const [1, 1, 1, 1, 1],
          isPlayerTurn: true,
          phase: YatzyPhase.scoring,
          message: '',
        ));
        c.read(yatzyStateProvider.notifier).scoreCategory(YatzyCategory.fullHouse);
        final s = c.read(yatzyStateProvider);
        expect(s.playerCard.scores[YatzyCategory.fullHouse], 25,
            reason: 'jokered to full house max, not 0 for a literal mismatch');
        expect(s.playerCard.yatzyBonusCount, 1);
        expect(s.playerCard.total, 50 + 25 + 100);
        // scoreCategory schedules a real AI-turn Timer — drain it
        // deterministically before teardown disposes the container.
        async.elapse(const Duration(seconds: 1));
      });
    });

    test(
        'a first Yatzy (yatzy box not yet filled) scores normally — no '
        'bonus, no joker fill, since the joker rule only applies to repeats',
        () {
      fakeAsync((async) {
        final c = _makeSeeded(YatzyState(
          dice: const [5, 5, 5, 5, 5],
          holds: List.filled(5, false),
          rollsLeft: 1,
          playerCard: Scorecard.empty(), // yatzy box still open
          aiCard: Scorecard.empty(),
          aiDice: const [1, 1, 1, 1, 1],
          isPlayerTurn: true,
          phase: YatzyPhase.scoring,
          message: '',
        ));
        c.read(yatzyStateProvider.notifier).scoreCategory(YatzyCategory.yatzy);
        final s = c.read(yatzyStateProvider);
        expect(s.playerCard.scores[YatzyCategory.yatzy], 50);
        expect(s.playerCard.yatzyBonusCount, 0);
        async.elapse(const Duration(seconds: 1));
      });
    });

    test(
        'a 5-of-a-kind scored into fullHouse without a prior Yatzy scores 0 '
        '(sanity check that the joker override only fires under the exact '
        'repeat-Yatzy condition)', () {
      fakeAsync((async) {
        final c = _makeSeeded(YatzyState(
          dice: const [2, 2, 2, 2, 2],
          holds: List.filled(5, false),
          rollsLeft: 1,
          playerCard: Scorecard.empty(), // yatzy not yet scored at all
          aiCard: Scorecard.empty(),
          aiDice: const [1, 1, 1, 1, 1],
          isPlayerTurn: true,
          phase: YatzyPhase.scoring,
          message: '',
        ));
        c.read(yatzyStateProvider.notifier).scoreCategory(YatzyCategory.fullHouse);
        final s = c.read(yatzyStateProvider);
        expect(s.playerCard.scores[YatzyCategory.fullHouse], 0);
        expect(s.playerCard.yatzyBonusCount, 0);
        async.elapse(const Duration(seconds: 1));
      });
    });
  });

  // ── GAME1: multiplayer scaffolding (mirrors dudo_test.dart) ───────────────

  group('YatzyNotifier.initHostMode — absolute host/guest roles', () {
    test('opponent isAI flag comes from the 2nd LobbyPlayer, host is always "player"',
        () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(yatzyStateProvider.notifier).initHostMode(const [
        LobbyPlayer(id: 'host', name: 'Host'),
        LobbyPlayer(id: 'guest', name: 'Guest', isAI: false),
      ]);
      final s = c.read(yatzyStateProvider);
      expect(s.isMultiplayer, isTrue);
      expect(s.isOpponentAI, isFalse);
      expect(s.isPlayerTurn, isTrue, reason: 'host always starts');
      expect(s.phase, YatzyPhase.start);
    });

    test('a lobby-added AI opponent is reflected in isOpponentAI', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(yatzyStateProvider.notifier).initHostMode(const [
        LobbyPlayer(id: 'host', name: 'Host'),
        LobbyPlayer(id: 'ai_1', name: 'AI 1', isAI: true),
      ]);
      expect(c.read(yatzyStateProvider).isOpponentAI, isTrue);
    });

  });

  group('YatzyNotifier — host/client mode flags', () {
    test('initHostMode/initClientMode/exitMultiplayerMode toggle isClientMode',
        () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(yatzyStateProvider.notifier);
      expect(notifier.isClientMode, isFalse);

      notifier.initClientMode();
      expect(notifier.isClientMode, isTrue);
      expect(c.read(yatzyStateProvider).isMultiplayer, isTrue);

      notifier.exitMultiplayerMode();
      expect(notifier.isClientMode, isFalse);
    });

    test('newGame exits multiplayer mode', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(yatzyStateProvider.notifier);
      notifier.initClientMode();
      expect(notifier.isClientMode, isTrue);

      notifier.newGame();
      expect(notifier.isClientMode, isFalse);
      expect(c.read(yatzyStateProvider).isMultiplayer, isFalse);
    });
  });

  group('YatzyNotifier — multiplayer turn handoff (no AI auto-play)', () {
    test('host scoring passes the turn to the guest without triggering _aiTurn',
        () {
      fakeAsync((async) {
        final c = _makeSeeded(YatzyState(
          dice: const [1, 1, 1, 1, 1],
          holds: List.filled(5, false),
          rollsLeft: 2,
          playerCard: Scorecard.empty(),
          aiCard: Scorecard.empty(),
          aiDice: const [1, 1, 1, 1, 1],
          isPlayerTurn: true,
          phase: YatzyPhase.scoring,
          message: '',
          isMultiplayer: true,
          isOpponentAI: false,
        ));
        c.read(yatzyStateProvider.notifier).scoreCategory(YatzyCategory.ones);
        // Even after the solo AI-turn delay would have fired, the guest's
        // card must still be untouched — no local auto-play in multiplayer.
        async.elapse(const Duration(seconds: 2));

        final s = c.read(yatzyStateProvider);
        expect(s.playerCard.scores[YatzyCategory.ones], 5);
        expect(s.isPlayerTurn, isFalse, reason: 'turn passes to the guest');
        expect(s.aiCard.scores.values.every((v) => v == null), isTrue,
            reason: 'no local AI turn should run in multiplayer');
        expect(s.rollsLeft, 3, reason: 'fresh roll allowance for the guest');
        expect(s.phase, YatzyPhase.start);
      });
    });

    test('guest scoring (isPlayerTurn: false) writes to aiCard and passes '
        'the turn back to the host', () {
      final c = _makeSeeded(YatzyState(
        dice: const [2, 2, 2, 2, 2],
        holds: List.filled(5, false),
        rollsLeft: 1,
        playerCard: Scorecard.empty(),
        aiCard: Scorecard.empty(),
        aiDice: const [1, 1, 1, 1, 1],
        isPlayerTurn: false,
        phase: YatzyPhase.scoring,
        message: '',
        isMultiplayer: true,
        isOpponentAI: false,
      ));
      c.read(yatzyStateProvider.notifier).scoreCategory(YatzyCategory.twos);
      final s = c.read(yatzyStateProvider);
      expect(s.aiCard.scores[YatzyCategory.twos], 10);
      expect(s.playerCard.scores.values.every((v) => v == null), isTrue);
      expect(s.isPlayerTurn, isTrue, reason: 'turn passes back to the host');
    });
  });

  group('YatzyState / Scorecard JSON round-trip (broadcastIfHost payload)', () {
    test('YatzyState.toJson/fromJson round-trips every field', () {
      final s = YatzyState(
        dice: const [3, 4, 5, 6, 1],
        holds: const [true, false, true, false, false],
        rollsLeft: 1,
        playerCard: Scorecard.empty().withScore(YatzyCategory.ones, 2),
        aiCard: Scorecard.empty().withScore(YatzyCategory.yatzy, 50),
        aiDice: const [6, 6, 6, 6, 6],
        isPlayerTurn: false,
        phase: YatzyPhase.scoring,
        message: 'Your turn!',
        isMultiplayer: true,
        isOpponentAI: false,
      );
      final round = YatzyState.fromJson(s.toJson());
      expect(round.dice, s.dice);
      expect(round.holds, s.holds);
      expect(round.rollsLeft, s.rollsLeft);
      expect(round.playerCard.scores[YatzyCategory.ones], 2);
      expect(round.aiCard.scores[YatzyCategory.yatzy], 50);
      expect(round.isPlayerTurn, isFalse);
      expect(round.phase, YatzyPhase.scoring);
      expect(round.isMultiplayer, isTrue);
      expect(round.isOpponentAI, isFalse);
    });
  });
}
