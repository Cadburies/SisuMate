import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/game_ai/game_ai_difficulty.dart';
import 'package:sisu_mate/services/game_ai/game_ai_persona.dart';
import 'package:sisu_mate/services/game_ai/game_ai_rng.dart';
import 'package:sisu_mate/ui/games/games/backgammon/logic.dart';
import 'package:sisu_mate/ui/games/games/checkers/logic.dart';
import 'package:sisu_mate/ui/games/games/cribbage/logic.dart';
import 'package:sisu_mate/ui/games/games/liars_dice/helpers.dart';
import 'package:sisu_mate/ui/games/games/poker/logic.dart';
import 'package:sisu_mate/ui/games/games/yatzy/logic.dart';

/// TEST28 — fixed seed/state → same AI move (repro).
///
/// Covers cold-game pure policies + shared RNG helper. Multiparty dice helpers
/// are included only via their already-injectable `rng` params (no lobby edits).
void main() {
  group('GameAiRng (TEST28)', () {
    test('same seed yields identical integer sequences', () {
      final a = GameAiRng.sampleInts(GameAiRng.seeded(42), 20, 100);
      final b = GameAiRng.sampleInts(GameAiRng.seeded(42), 20, 100);
      expect(a, b);
    });

    test('different seeds diverge', () {
      final a = GameAiRng.sampleInts(GameAiRng.seeded(1), 10, 50);
      final b = GameAiRng.sampleInts(GameAiRng.seeded(2), 10, 50);
      expect(a, isNot(b));
    });
  });

  group('Checkers AI tie-break (TEST28)', () {
    List<List<int>> emptyBoard() =>
        List.generate(8, (_) => List.filled(8, 0));

    test('same seed + same board ⇒ same AI board twice', () {
      final board = emptyBoard();
      // Simple open mid-game: AI pieces can move; multiple legal lines.
      board[5][2] = 2;
      board[5][4] = 2;
      board[2][1] = 1;
      board[2][3] = 1;

      const seed = 99;
      final first =
          debugSelectAiBoard(board, rng: GameAiRng.seeded(seed));
      final second =
          debugSelectAiBoard(board, rng: GameAiRng.seeded(seed));
      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(first, second);
    });

    test('different seeds can pick different tied outcomes', () {
      final board = emptyBoard();
      board[5][2] = 2;
      board[5][4] = 2;
      board[2][1] = 1;
      board[2][3] = 1;

      // Not always different (single best move possible) — only assert that
      // each seed is self-consistent (repro property).
      for (final seed in [0, 1, 2, 7, 13]) {
        final a = debugSelectAiBoard(board, rng: GameAiRng.seeded(seed));
        final b = debugSelectAiBoard(board, rng: GameAiRng.seeded(seed));
        expect(a, b, reason: 'seed $seed');
      }
    });
  });

  group('Poker AI discard (TEST28 pure, no RNG)', () {
    test('same hand ⇒ same discard indices twice', () {
      // Pair of aces + junk (ranks: A=12, 2=0, 3=1, 4=2) — suits vary.
      final hand = [12, 25, 0, 1, 2]; // A♣ A♦ 2♣ 3♣ 4♣
      expect(pokerAiDiscardIndices(hand), pokerAiDiscardIndices(hand));
      // Keep the pair; discard three kickers.
      expect(pokerAiDiscardIndices(hand), hasLength(3));
    });

    test('high-card hand discards two lowest ranks', () {
      // 2,3,5,8,K different suits — no pair.
      final hand = [0, 14, 3, 20, 11];
      final d = pokerAiDiscardIndices(hand);
      expect(d, hasLength(2));
      expect(pokerAiDiscardIndices(hand), d);
    });
  });

  group('Cribbage AI keep (TEST28 pure, no RNG)', () {
    test('same 6-card hand ⇒ same 4-card keep twice', () {
      final hand = [0, 1, 2, 3, 4, 5];
      final a = cribbageAiSelectKeep(hand);
      final b = cribbageAiSelectKeep(hand);
      expect(a, b);
      expect(a, hasLength(4));
    });
  });

  group('Yatzy AI (TEST28)', () {
    test('smart reroll is deterministic under a fixed seed', () {
      final dice = [1, 1, 3, 5, 6];
      final a = yatzyAiSmartReroll(dice, GameAiRng.seeded(7));
      final b = yatzyAiSmartReroll(dice, GameAiRng.seeded(7));
      expect(a, b);
      // Held pair of ones stays.
      expect(a[0], 1);
      expect(a[1], 1);
    });

    test('best category is pure (no RNG)', () {
      final card = Scorecard.empty();
      final dice = [6, 6, 6, 6, 6];
      expect(
        yatzyAiBestCat(dice, card),
        yatzyAiBestCat(dice, card),
      );
      expect(yatzyAiBestCat(dice, card), YatzyCategory.yatzy);
    });
  });

  group('Backgammon AI bestPlay (TEST28 seeded)', () {
    BackgammonState empty({
      List<int>? board,
      List<int> movesLeft = const [3],
    }) {
      return BackgammonState(
        board: board ?? List.filled(24, 0),
        humanBar: 0,
        aiBar: 0,
        humanBornOff: 0,
        aiBornOff: 0,
        dice: movesLeft,
        movesLeft: movesLeft,
        isHumanTurn: false,
        selectedPoint: null,
        phase: BgPhase.moving,
        message: '',
      );
    }

    test('easy bestPlay same seed ⇒ same steps', () {
      final board = List.filled(24, 0);
      board[0] = -2;
      board[3] = 1;
      final s = empty(board: board, movesLeft: const [3]);
      final a = BackgammonAi.bestPlay(
        s,
        difficulty: GameAiDifficulty.easy,
        rng: GameAiRng.seeded(11),
      );
      final b = BackgammonAi.bestPlay(
        s,
        difficulty: GameAiDifficulty.easy,
        rng: GameAiRng.seeded(11),
      );
      expect(a, b);
      expect(a, isNotEmpty);
    });

    test('shouldOfferDouble is reproducible under a fixed seed', () {
      final board = List.filled(24, 0);
      // Strong AI race lead so offer is considered.
      for (var i = 18; i < 24; i++) {
        board[i] = -2;
      }
      for (var i = 0; i < 6; i++) {
        board[i] = 2;
      }
      final s = BackgammonState(
        board: board,
        humanBar: 0,
        aiBar: 0,
        humanBornOff: 0,
        aiBornOff: 0,
        dice: const [],
        movesLeft: const [],
        isHumanTurn: false,
        selectedPoint: null,
        phase: BgPhase.rolling, // canOfferDouble requires rolling
        message: '',
        cubeValue: 1,
        cubeOwnerIsHuman: null,
      );
      final offerA = BackgammonAi.shouldOfferDouble(
        s,
        GameAiRng.seeded(3),
        difficulty: GameAiDifficulty.normal,
      );
      final offerB = BackgammonAi.shouldOfferDouble(
        s,
        GameAiRng.seeded(3),
        difficulty: GameAiDifficulty.normal,
      );
      expect(offerA, offerB);
    });
  });

  group('Liar\'s Dice pure AI (TEST28 seeded; no lobby edits)', () {
    test('computeLiarDiceAiBid same seed ⇒ same bid', () {
      final dice = [2, 2, 3, 4, 5];
      final a = computeLiarDiceAiBid(
        dice,
        null,
        persona: GameAiPersona.chaos,
        rng: GameAiRng.seeded(5),
      );
      final b = computeLiarDiceAiBid(
        dice,
        null,
        persona: GameAiPersona.chaos,
        rng: GameAiRng.seeded(5),
      );
      expect(a.rank, b.rank);
      expect(a.face, b.face);
    });
  });
}
