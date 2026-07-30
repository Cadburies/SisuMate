import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sisu_mate/services/lan/game_lan_service.dart';
import 'package:sisu_mate/ui/games/games/backgammon/logic.dart';

// Lets tests seed an arbitrary state directly, rather than only reachable
// via roll() with random dice.
class _SeededBackgammonNotifier extends BackgammonNotifier {
  final BackgammonState initial;
  _SeededBackgammonNotifier(this.initial);
  @override
  BackgammonState build() => initial;
}

ProviderContainer _makeSeeded(BackgammonState initial) {
  final c = ProviderContainer(overrides: [
    backgammonStateProvider.overrideWith(() => _SeededBackgammonNotifier(initial)),
  ]);
  addTearDown(c.dispose);
  return c;
}

BackgammonState _empty({
  List<int>? board,
  int humanBar = 0,
  int aiBar = 0,
  int humanBornOff = 0,
  int aiBornOff = 0,
  List<int> movesLeft = const [3],
  bool isHumanTurn = true,
  BgPhase phase = BgPhase.moving,
}) =>
    BackgammonState(
      board: board ?? List.filled(24, 0),
      humanBar: humanBar,
      aiBar: aiBar,
      humanBornOff: humanBornOff,
      aiBornOff: aiBornOff,
      dice: movesLeft,
      movesLeft: movesLeft,
      isHumanTurn: isHumanTurn,
      selectedPoint: null,
      phase: phase,
      message: '',
    );

void main() {
  // ── GB7 doubling cube ─────────────────────────────────────────────────────

  group('doubling cube (GB7)', () {
    test('canOfferDouble when cube centered and phase rolling', () {
      final s = _empty(phase: BgPhase.rolling, movesLeft: const []);
      expect(s.canOfferDouble, isTrue);
      expect(s.cubeValue, 1);
      expect(s.cubeOwnerIsHuman, isNull);
    });

    test('offerDouble moves to doubleOffered; accept doubles stake', () {
      final c = _makeSeeded(_empty(phase: BgPhase.rolling, movesLeft: const []));
      final n = c.read(backgammonStateProvider.notifier);
      n.offerDouble();
      expect(c.read(backgammonStateProvider).phase, BgPhase.doubleOffered);
      expect(c.read(backgammonStateProvider).doubleOfferedByHuman, isTrue);
      n.acceptDouble();
      final s = c.read(backgammonStateProvider);
      expect(s.cubeValue, 2);
      expect(s.cubeOwnerIsHuman, isFalse); // acceptor (AI role) owns cube
      expect(s.phase, BgPhase.rolling);
    });

    test('declineDouble ends game for the offerer at current stake', () {
      final c = _makeSeeded(_empty(phase: BgPhase.rolling, movesLeft: const []));
      final n = c.read(backgammonStateProvider.notifier);
      n.offerDouble();
      n.declineDouble();
      final s = c.read(backgammonStateProvider);
      expect(s.phase, BgPhase.gameOver);
      expect(s.humanBornOff, 15); // offerer marked winner for overlay
      expect(s.cubeValue, 1);
    });

    test('only cube owner may redouble after accept', () {
      final c = _makeSeeded(_empty(phase: BgPhase.rolling, movesLeft: const []));
      final n = c.read(backgammonStateProvider.notifier);
      n.offerDouble();
      n.acceptDouble();
      // After accept, human no longer owns cube — cannot offer on human turn.
      final s = c.read(backgammonStateProvider);
      expect(s.isHumanTurn, isTrue);
      expect(s.canOfferDouble, isFalse);
    });
  });

  // ── BackgammonState helpers ───────────────────────────────────────────────

  group('BackgammonState.humanAllHome', () {
    test('true when all human pieces in indices 0–5 and no bar', () {
      final board = List.filled(24, 0);
      board[0] = 5;
      board[3] = 10;
      final s = _empty(board: board, humanBar: 0);
      expect(s.humanAllHome(), isTrue);
    });

    test('false when human pieces outside home board', () {
      final board = List.filled(24, 0);
      board[6] = 1;
      final s = _empty(board: board);
      expect(s.humanAllHome(), isFalse);
    });

    test('false when human on bar', () {
      final board = List.filled(24, 0);
      board[0] = 15;
      final s = _empty(board: board, humanBar: 1);
      expect(s.humanAllHome(), isFalse);
    });
  });

  group('BackgammonState.aiAllHome', () {
    test('true when all AI pieces in indices 18–23 and no bar', () {
      final board = List.filled(24, 0);
      board[18] = -15;
      final s = _empty(board: board, aiBar: 0);
      expect(s.aiAllHome(), isTrue);
    });

    test('false when AI piece outside home board', () {
      final board = List.filled(24, 0);
      board[17] = -1;
      final s = _empty(board: board);
      expect(s.aiAllHome(), isFalse);
    });
  });

  // ── validHumanMoves ───────────────────────────────────────────────────────

  group('validHumanMoves', () {
    test('normal move: from index 10 with die 3 → index 7', () {
      final board = List.filled(24, 0);
      board[10] = 1;
      final s = _empty(board: board, movesLeft: [3]);
      expect(validHumanMoves(s, 10, 3), [7]);
    });

    test('returns [] if die not in movesLeft', () {
      final board = List.filled(24, 0);
      board[10] = 1;
      final s = _empty(board: board, movesLeft: [4]);
      expect(validHumanMoves(s, 10, 3), []);
    });

    test('blocked by 2+ AI pieces at destination', () {
      final board = List.filled(24, 0);
      board[10] = 1;
      board[7] = -2; // blocked
      final s = _empty(board: board, movesLeft: [3]);
      expect(validHumanMoves(s, 10, 3), []);
    });

    test('can hit AI blot (single piece)', () {
      final board = List.filled(24, 0);
      board[10] = 1;
      board[7] = -1; // blot — can be hit
      final s = _empty(board: board, movesLeft: [3]);
      expect(validHumanMoves(s, 10, 3), [7]);
    });

    test('must enter from bar when humanBar > 0', () {
      final board = List.filled(24, 0);
      board[10] = 1;
      final s = _empty(board: board, humanBar: 1, movesLeft: [3]);
      // from != -1 should return [] since bar must be cleared first
      expect(validHumanMoves(s, 10, 3), []);
    });

    test('enters from bar onto point 25-die = index 24-die', () {
      final board = List.filled(24, 0);
      final s = _empty(board: board, humanBar: 1, movesLeft: [3]);
      // entering from bar with die 3 → dest = 24-3 = 21
      expect(validHumanMoves(s, -1, 3), [21]);
    });

    test('entering from bar blocked by 2 AI pieces', () {
      final board = List.filled(24, 0);
      board[21] = -2; // blocked re-entry
      final s = _empty(board: board, humanBar: 1, movesLeft: [3]);
      expect(validHumanMoves(s, -1, 3), []);
    });

    test('bearing off returns [-2] when all home and dest < 0', () {
      final board = List.filled(24, 0);
      board[2] = 1; // in home board
      final s = _empty(board: board, humanBar: 0, movesLeft: [5]);
      // dest = 2-5 = -3 < 0, all home → bear off
      expect(validHumanMoves(s, 2, 5), [-2]);
    });

    test('cannot bear off when not all home', () {
      final board = List.filled(24, 0);
      board[2] = 1;
      board[8] = 1; // not all home
      final s = _empty(board: board, movesLeft: [5]);
      expect(validHumanMoves(s, 2, 5), []);
    });

    test(
        'GB8 regression: overshoot bear-off from a low point is rejected '
        'while a checker remains on a higher point — previously any die '
        'that overshot (dest < -1) was accepted unconditionally, letting a '
        'checker on point 3 bear off with a 6 while a checker still sat on '
        'point 6, which real backgammon forbids', () {
      final board = List.filled(24, 0);
      board[2] = 1; // point 3
      board[5] = 1; // point 6 — higher point, must move/bear off first
      final s = _empty(board: board, movesLeft: [6]);
      // dest = 2-6 = -4 (overshoot) with a checker still on point 6 (index 5)
      expect(validHumanMoves(s, 2, 6), []);
    });

    test(
        'GB8: overshoot bear-off from the highest occupied point is still '
        'allowed — a checker on a LOWER point must not block it', () {
      final board = List.filled(24, 0);
      board[0] = 1; // point 1 — lower than the moving checker, irrelevant
      board[2] = 1; // point 3 — the highest occupied point, this one moves
      final s = _empty(board: board, movesLeft: [5]);
      // dest = 2-5 = -3 (overshoot); no checker on points 4/5/6 → still valid
      expect(validHumanMoves(s, 2, 5), [-2]);
    });

    test('GB8: exact bear-off (dest == -1) is always allowed regardless of '
        'other checkers', () {
      final board = List.filled(24, 0);
      board[2] = 1; // point 3 — exact bear-off die is 3
      board[5] = 1; // point 6 — higher point, but this move is exact, not overshoot
      final s = _empty(board: board, movesLeft: [3]);
      expect(validHumanMoves(s, 2, 3), [-2]);
    });
  });

  // ── validAiMoves ─────────────────────────────────────────────────────────

  group('validAiMoves', () {
    test('normal AI move: from index 5 with die 3 → index 8', () {
      final board = List.filled(24, 0);
      board[5] = -1;
      final s = _empty(board: board, isHumanTurn: false, movesLeft: [3]);
      expect(validAiMoves(s, 5, 3), [8]);
    });

    test('AI blocked by 2+ human pieces', () {
      final board = List.filled(24, 0);
      board[5] = -1;
      board[8] = 2; // 2 human pieces — blocked
      final s = _empty(board: board, isHumanTurn: false, movesLeft: [3]);
      expect(validAiMoves(s, 5, 3), []);
    });

    test('AI can hit human blot', () {
      final board = List.filled(24, 0);
      board[5] = -1;
      board[8] = 1; // human blot
      final s = _empty(board: board, isHumanTurn: false, movesLeft: [3]);
      expect(validAiMoves(s, 5, 3), [8]);
    });

    test('AI enters from bar: point die → index die-1', () {
      final board = List.filled(24, 0);
      final s = _empty(board: board, aiBar: 1, isHumanTurn: false, movesLeft: [4]);
      // die=4 → dest = 4-1 = 3
      expect(validAiMoves(s, -1, 4), [3]);
    });

    test('AI bears off when all home and dest > 23', () {
      final board = List.filled(24, 0);
      board[22] = -1;
      final s = _empty(board: board, aiBar: 0, isHumanTurn: false, movesLeft: [5]);
      // dest = 22+5 = 27 > 23, all AI home → bear off
      expect(validAiMoves(s, 22, 5), [-2]);
    });

    test(
        'GB8 regression (AI side): overshoot bear-off is rejected while a '
        'checker remains further back — mirrors the human-side fix', () {
      final board = List.filled(24, 0);
      board[19] = -1; // point 20 for AI (index 19) — further back (needs a 5 exactly)
      board[20] = -1; // point 21 for AI (index 20) — the one attempting to move (needs a 4 exactly)
      final s = _empty(board: board, isHumanTurn: false, movesLeft: [6]);
      // dest = 20+6 = 26 (overshoot) while index 19 still has a checker
      // further back — must be rejected.
      expect(validAiMoves(s, 20, 6), []);
    });

    test(
        'GB8: AI exact bear-off is still allowed despite a checker further '
        'back — only overshoot is restricted', () {
      final board = List.filled(24, 0);
      board[19] = -1; // further back
      board[20] = -1; // the one attempting to move
      final s = _empty(board: board, isHumanTurn: false, movesLeft: [4]);
      // dest = 20+4 = 24 (exact) — always allowed regardless of other checkers.
      expect(validAiMoves(s, 20, 4), [-2]);
    });

    test(
        'GB8: AI overshoot bear-off from the furthest-back occupied point '
        'is still allowed — a checker closer to home does not block it', () {
      final board = List.filled(24, 0);
      board[23] = -1; // point 24 for AI — closer to home, irrelevant
      board[21] = -1; // point 22 for AI — the furthest-back, this one moves
      final s = _empty(board: board, isHumanTurn: false, movesLeft: [5]);
      // dest = 21+5 = 26 (overshoot); no checker further back (index < 21) → valid
      expect(validAiMoves(s, 21, 5), [-2]);
    });
  });

  // ── BackgammonNotifier — initial state ────────────────────────────────────

  group('BackgammonNotifier', () {
    ProviderContainer make() {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      return c;
    }

    test('initial board has correct piece counts', () {
      final c = make();
      final s = c.read(backgammonStateProvider);
      // Human (white) total = 2 + 5 + 3 + 5 = 15
      final humanTotal =
          s.board.where((v) => v > 0).fold(0, (a, b) => a + b);
      expect(humanTotal, 15);
      // AI (black) total = -2 - 5 - 3 - 5 = -15
      final aiTotal =
          s.board.where((v) => v < 0).fold(0, (a, b) => a + b);
      expect(aiTotal, -15);
    });

    test('initial phase is rolling, human turn', () {
      final c = make();
      final s = c.read(backgammonStateProvider);
      expect(s.phase, BgPhase.rolling);
      expect(s.isHumanTurn, isTrue);
      expect(s.movesLeft, isEmpty);
    });

    test('roll sets phase to moving and populates movesLeft', () {
      final c = make();
      c.read(backgammonStateProvider.notifier).roll();
      final s = c.read(backgammonStateProvider);
      expect(s.phase, BgPhase.moving);
      expect(s.movesLeft, isNotEmpty);
      for (final d in s.movesLeft) {
        expect(d, inInclusiveRange(1, 6));
      }
    });

    test('roll gives 2 or 4 moves (4 only on doubles)', () {
      final c = make();
      c.read(backgammonStateProvider.notifier).roll();
      final s = c.read(backgammonStateProvider);
      if (s.dice[0] == s.dice[1]) {
        expect(s.movesLeft.length, 4);
      } else {
        expect(s.movesLeft.length, 2);
      }
    });

    test('newGame resets state', () {
      final c = make();
      c.read(backgammonStateProvider.notifier).roll();
      c.read(backgammonStateProvider.notifier).newGame();
      final s = c.read(backgammonStateProvider);
      expect(s.phase, BgPhase.rolling);
      expect(s.humanBornOff, 0);
      expect(s.aiBornOff, 0);
    });

    test('selectPoint does nothing during rolling phase', () {
      final c = make();
      final before = c.read(backgammonStateProvider).selectedPoint;
      c.read(backgammonStateProvider.notifier).selectPoint(5);
      expect(c.read(backgammonStateProvider).selectedPoint, before);
    });

    // ── passTurn ──────────────────────────────────────────────────────────

    test('passTurn clears movesLeft, sets isHumanTurn false, phase to rolling', () {
      final c = make();
      c.read(backgammonStateProvider.notifier).roll(); // → moving
      c.read(backgammonStateProvider.notifier).passTurn();
      final s = c.read(backgammonStateProvider);
      expect(s.movesLeft, isEmpty);
      expect(s.isHumanTurn, isFalse);
      expect(s.phase, BgPhase.rolling);
    });

    test('passTurn is no-op during rolling phase', () {
      final c = make();
      expect(c.read(backgammonStateProvider).phase, BgPhase.rolling);
      c.read(backgammonStateProvider.notifier).passTurn();
      final s = c.read(backgammonStateProvider);
      expect(s.phase, BgPhase.rolling);
      expect(s.isHumanTurn, isTrue);
    });

    // ── bearOff ───────────────────────────────────────────────────────────

    test('bearOff is no-op when no point is selected', () {
      final c = make();
      c.read(backgammonStateProvider.notifier).roll(); // → moving
      final before = c.read(backgammonStateProvider).humanBornOff;
      c.read(backgammonStateProvider.notifier).bearOff();
      expect(c.read(backgammonStateProvider).humanBornOff, before);
    });

    test('bearOff is no-op during rolling phase', () {
      final c = make();
      c.read(backgammonStateProvider.notifier).bearOff();
      expect(c.read(backgammonStateProvider).phase, BgPhase.rolling);
    });
  });

  // ── Multiplayer (GAME1) ────────────────────────────────────────────────────

  group('BackgammonNotifier.initHostMode — absolute host/guest roles', () {
    test('opponent isAI flag comes from the 2nd LobbyPlayer, host is always human/white',
        () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(backgammonStateProvider.notifier).initHostMode(const [
        LobbyPlayer(id: 'host', name: 'Host'),
        LobbyPlayer(id: 'guest', name: 'Guest', isAI: false),
      ]);
      final s = c.read(backgammonStateProvider);
      expect(s.isMultiplayer, isTrue);
      expect(s.isOpponentAI, isFalse);
      expect(s.isHumanTurn, isTrue, reason: 'host always starts');
      expect(s.phase, BgPhase.rolling);
    });

    test('a lobby-added AI opponent is reflected in isOpponentAI', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(backgammonStateProvider.notifier).initHostMode(const [
        LobbyPlayer(id: 'host', name: 'Host'),
        LobbyPlayer(id: 'ai_1', name: 'AI 1', isAI: true),
      ]);
      expect(c.read(backgammonStateProvider).isOpponentAI, isTrue);
    });
  });

  group('BackgammonNotifier — host/client mode flags', () {
    test('initHostMode/initClientMode/exitMultiplayerMode toggle isClientMode',
        () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(backgammonStateProvider.notifier);
      expect(notifier.isClientMode, isFalse);

      notifier.initClientMode();
      expect(notifier.isClientMode, isTrue);
      expect(c.read(backgammonStateProvider).isMultiplayer, isTrue);

      notifier.exitMultiplayerMode();
      expect(notifier.isClientMode, isFalse);
    });

    test('newGame exits multiplayer mode', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(backgammonStateProvider.notifier);
      notifier.initClientMode();
      expect(notifier.isClientMode, isTrue);

      notifier.newGame();
      expect(notifier.isClientMode, isFalse);
      expect(c.read(backgammonStateProvider).isMultiplayer, isFalse);
    });
  });

  group('BackgammonNotifier — multiplayer turn handoff (no AI auto-play)', () {
    test(
        'regression: the guest can select and move their own AI-role (black) '
        'pieces — mirrors the bug found live in checkers/logic.dart: '
        'selectPoint/bearOff/passTurn originally hardcoded "the human", so a '
        "guest's remotely-forwarded taps on their own black pieces would "
        'have been silently ignored (guest could never move at all)', () {
      final board = List.filled(24, 0);
      board[5] = -1; // a lone AI/black piece, the guest's own role
      final c = _makeSeeded(BackgammonState(
        board: board,
        humanBar: 0,
        aiBar: 0,
        humanBornOff: 0,
        aiBornOff: 0,
        dice: const [3],
        movesLeft: const [3],
        isHumanTurn: false, // guest's turn (host's turn flag is false)
        selectedPoint: null,
        phase: BgPhase.moving,
        message: '',
        isMultiplayer: true,
        isOpponentAI: false,
      ));
      final notifier = c.read(backgammonStateProvider.notifier);
      notifier.selectPoint(5); // select the guest's own black piece
      final selected = c.read(backgammonStateProvider);
      expect(selected.selectedPoint, 5,
          reason: 'the guest must be able to select their own black piece');

      notifier.selectPoint(8); // move it (index 5 + die 3 = index 8)
      final s = c.read(backgammonStateProvider);
      expect(s.board[8], -1);
      expect(s.board[5], 0);
      expect(s.isHumanTurn, isTrue, reason: 'turn passes back to the host');
    });

    test('a human move that ends the turn does not trigger the local AI '
        'when the opponent is a real remote guest', () {
      fakeAsync((async) {
        final board = List.filled(24, 0);
        board[10] = 1; // human piece, one simple move available
        board[5] = -1; // a black piece so the game doesn't end on this move
        final c = _makeSeeded(BackgammonState(
          board: board,
          humanBar: 0,
          aiBar: 0,
          humanBornOff: 0,
          aiBornOff: 0,
          dice: const [3],
          movesLeft: const [3],
          isHumanTurn: true,
          selectedPoint: null,
          phase: BgPhase.moving,
          message: '',
          isMultiplayer: true,
          isOpponentAI: false,
        ));
        final notifier = c.read(backgammonStateProvider.notifier);
        notifier.selectPoint(10);
        notifier.selectPoint(7); // 10 - 3 = 7

        // Even after the solo AI-move delay would have fired, the board must
        // still show only the human's own move — no local auto-play when
        // the opponent is a real remote device.
        async.elapse(const Duration(seconds: 2));

        final s = c.read(backgammonStateProvider);
        expect(s.board[7], 1);
        expect(s.isHumanTurn, isFalse, reason: 'turn passes to the guest');
      });
    });
  });

  group('BackgammonState JSON round-trip (broadcastIfHost payload)', () {
    test('toJson/fromJson round-trips every field', () {
      final s = BackgammonState(
        board: List.generate(24, (i) => i == 3 ? 2 : (i == 20 ? -3 : 0)),
        humanBar: 1,
        aiBar: 2,
        humanBornOff: 3,
        aiBornOff: 4,
        dice: const [5, 6],
        movesLeft: const [5],
        isHumanTurn: false,
        selectedPoint: 10,
        phase: BgPhase.moving,
        message: 'Opponent turn',
        isMultiplayer: true,
        isOpponentAI: false,
      );
      final round = BackgammonState.fromJson(s.toJson());
      expect(round.board, s.board);
      expect(round.humanBar, 1);
      expect(round.aiBar, 2);
      expect(round.humanBornOff, 3);
      expect(round.aiBornOff, 4);
      expect(round.dice, s.dice);
      expect(round.movesLeft, s.movesLeft);
      expect(round.isHumanTurn, isFalse);
      expect(round.selectedPoint, 10);
      expect(round.phase, BgPhase.moving);
      expect(round.isMultiplayer, isTrue);
      expect(round.isOpponentAI, isFalse);
    });

    test('a null selectedPoint survives the round-trip', () {
      final s = BackgammonState(
        board: List.filled(24, 0),
        humanBar: 0, aiBar: 0, humanBornOff: 0, aiBornOff: 0,
        dice: const [], movesLeft: const [], isHumanTurn: true,
        selectedPoint: null, phase: BgPhase.rolling, message: '',
      );
      final round = BackgammonState.fromJson(s.toJson());
      expect(round.selectedPoint, isNull);
    });
  });
}
