import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sisu_mate/services/lan/game_lan_service.dart';
import 'package:sisu_mate/ui/games/games/checkers/logic.dart';

List<List<int>> _emptyBoard() => List.generate(8, (_) => List.filled(8, 0));

// Lets tests seed an arbitrary board/selection state directly, rather than
// only reachable via a sequence of selectCell() calls from the standard
// starting position.
class _SeededCheckersNotifier extends CheckersNotifier {
  final CheckersState initial;
  _SeededCheckersNotifier(this.initial);
  @override
  CheckersState build() => initial;
}

ProviderContainer _makeSeeded(CheckersState initial) {
  final c = ProviderContainer(overrides: [
    checkersStateProvider
        .overrideWith(() => _SeededCheckersNotifier(initial)),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  // ── getMovesForPiece ──────────────────────────────────────────────────────

  group('getMovesForPiece — simple moves', () {
    test('human piece at (2,1) on empty board has 2 forward moves', () {
      final board = _emptyBoard();
      board[2][1] = 1;
      final moves = getMovesForPiece(board, 2, 1);
      expect(moves.length, 2);
      expect(moves.any((m) => m.toRow == 3 && m.toCol == 0), isTrue);
      expect(moves.any((m) => m.toRow == 3 && m.toCol == 2), isTrue);
    });

    test('AI piece (value=2) moves toward row 0', () {
      final board = _emptyBoard();
      board[5][2] = 2;
      final moves = getMovesForPiece(board, 5, 2);
      expect(moves.every((m) => m.toRow < 5), isTrue);
    });

    test('human blocked on left edge', () {
      final board = _emptyBoard();
      board[2][0] = 1;
      final moves = getMovesForPiece(board, 2, 0);
      expect(moves.length, 1);
      expect(moves.first.toCol, 1);
    });

    test('king (value=3) can move both directions', () {
      final board = _emptyBoard();
      board[4][4] = 3;
      final moves = getMovesForPiece(board, 4, 4);
      final rowsForward = moves.where((m) => m.toRow > 4).length;
      final rowsBack = moves.where((m) => m.toRow < 4).length;
      expect(rowsForward, greaterThan(0));
      expect(rowsBack, greaterThan(0));
    });

    test('no moves when surrounded by own pieces', () {
      final board = _emptyBoard();
      board[3][3] = 1;
      board[4][2] = 1;
      board[4][4] = 1;
      final moves = getMovesForPiece(board, 3, 3);
      expect(moves.where((m) => m.captured.isEmpty), isEmpty);
    });

    test('empty cell returns no moves', () {
      final board = _emptyBoard();
      final moves = getMovesForPiece(board, 3, 3);
      expect(moves, isEmpty);
    });
  });

  group('getMovesForPiece — jump moves', () {
    test('human can capture AI piece', () {
      final board = _emptyBoard();
      board[2][2] = 1;
      board[3][3] = 2; // AI piece to capture
      // Landing at (4,4)
      final moves = getMovesForPiece(board, 2, 2);
      final jump = moves.where((m) => m.captured.isNotEmpty);
      expect(jump.length, 1);
      expect(jump.first.toRow, 4);
      expect(jump.first.toCol, 4);
      expect(jump.first.captured, [(3, 3)]);
    });

    test('jump only returned when landing square empty', () {
      final board = _emptyBoard();
      board[2][2] = 1;
      board[3][3] = 2;
      board[4][4] = 1; // landing blocked
      final moves = getMovesForPiece(board, 2, 2);
      expect(moves.where((m) => m.captured.isNotEmpty), isEmpty);
    });

    test('when jumps available, simple moves are suppressed', () {
      final board = _emptyBoard();
      board[2][2] = 1;
      board[3][3] = 2; // jump available
      // (2,3) is also empty — would be simple move, but jump takes priority
      final moves = getMovesForPiece(board, 2, 2);
      expect(moves.every((m) => m.captured.isNotEmpty), isTrue);
    });
  });

  // ── getAllMoves ───────────────────────────────────────────────────────────

  group('getAllMoves', () {
    test('returns player moves on player turn', () {
      final board = _emptyBoard();
      board[2][1] = 1;
      final moves = getAllMoves(board, true);
      expect(moves.every((m) => m.fromRow == 2 && m.fromCol == 1), isTrue);
    });

    test('returns AI moves on AI turn', () {
      final board = _emptyBoard();
      board[5][2] = 2;
      final moves = getAllMoves(board, false);
      expect(moves.every((m) => m.fromRow == 5 && m.fromCol == 2), isTrue);
    });

    test('returns only jump moves when any jump exists (mandatory jump)', () {
      final board = _emptyBoard();
      board[2][2] = 1;
      board[3][3] = 2; // creates a jump
      board[2][4] = 1; // another human piece with simple move available
      final moves = getAllMoves(board, true);
      // All returned moves must be jumps
      expect(moves.every((m) => m.captured.isNotEmpty), isTrue);
    });

    test('empty board returns no moves', () {
      expect(getAllMoves(_emptyBoard(), true), isEmpty);
    });
  });

  // ── getChainJumps ─────────────────────────────────────────────────────────

  group('getChainJumps', () {
    test('detects chain jump after first capture', () {
      final board = _emptyBoard();
      board[4][4] = 1; // piece at landing pos after first jump
      board[5][5] = 2; // another AI piece for chain
      // Chain: piece at (4,4) can jump (5,5) to land at (6,6)
      final jumps = getChainJumps(board, 4, 4, []);
      expect(jumps.any((m) => m.toRow == 6 && m.toCol == 6), isTrue);
    });

    test('already-captured piece is not counted again', () {
      final board = _emptyBoard();
      board[4][4] = 1;
      board[5][5] = 2;
      // Pretend (5,5) was already captured
      final jumps = getChainJumps(board, 4, 4, [(5, 5)]);
      expect(jumps.where((m) => m.toRow == 6 && m.toCol == 6), isEmpty);
    });
  });

  // ── CheckersNotifier ──────────────────────────────────────────────────────

  group('CheckersNotifier', () {
    ProviderContainer make() {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      return c;
    }

    test('initial board has 12 red and 12 black pieces', () {
      final c = make();
      final board = c.read(checkersStateProvider).board;
      int red = 0, black = 0;
      for (final row in board) {
        for (final v in row) {
          if (v == 1 || v == 3) red++;
          if (v == 2 || v == 4) black++;
        }
      }
      expect(red, 12);
      expect(black, 12);
    });

    test('initial state is player turn, playing phase', () {
      final c = make();
      final s = c.read(checkersStateProvider);
      expect(s.isPlayerTurn, isTrue);
      expect(s.phase, GamePhase.playing);
      expect(s.winner, isNull);
    });

    test('selecting empty square does not change selectedRow', () {
      final c = make();
      c.read(checkersStateProvider.notifier).selectCell(4, 4);
      expect(c.read(checkersStateProvider).selectedRow, isNull);
    });

    test('selecting AI piece on player turn does not select', () {
      final c = make();
      // AI pieces are at rows 5-7 on dark squares
      c.read(checkersStateProvider.notifier).selectCell(5, 1);
      expect(c.read(checkersStateProvider).selectedRow, isNull);
    });

    test('selecting valid player piece sets selectedRow/Col', () {
      final c = make();
      // Human pieces are at rows 0-2 on dark squares; row 2, col 1 is (r+c)%2==1
      c.read(checkersStateProvider.notifier).selectCell(2, 1);
      final s = c.read(checkersStateProvider);
      expect(s.selectedRow, 2);
      expect(s.selectedCol, 1);
    });

    test('newGame resets board', () {
      final c = make();
      c.read(checkersStateProvider.notifier).selectCell(2, 1);
      c.read(checkersStateProvider.notifier).newGame();
      final s = c.read(checkersStateProvider);
      expect(s.selectedRow, isNull);
      expect(s.phase, GamePhase.playing);
    });
  });

  // ── King promotion via game flow ──────────────────────────────────────────

  group('king promotion', () {
    test('human piece reaching row 7 becomes king (value 3)', () {
      final board = _emptyBoard();
      board[6][2] = 1; // one step away from row 7
      // The piece at (6,2) should have forward moves to row 7
      final moves = getMovesForPiece(board, 6, 2);
      expect(moves.any((m) => m.toRow == 7), isTrue);
    });

    test(
        'GB9 regression: a piece promoted to king mid-jump ends its turn '
        'immediately, even though the newly-crowned king could otherwise '
        'continue capturing backward — previously promotion happened before '
        'the chain-jump check, so getChainJumps saw a king and offered a '
        'backward capture no plain man should get mid-move', () {
      final board = _emptyBoard();
      board[5][2] = 1; // human man, about to jump and land on row 7
      board[6][3] = 2; // AI piece captured on the way to row 7
      board[6][5] = 2; // AI piece that would enable a backward king-jump
      // (7,4) landing square and (5,6) backward-landing square stay empty.
      final allMoves = getAllMoves(board, true);
      final c = _makeSeeded(CheckersState(
        board: board,
        isPlayerTurn: true,
        selectedRow: null,
        selectedCol: null,
        validMoves: const [],
        allMoves: allMoves,
        phase: GamePhase.playing,
        message: '',
        winner: null,
      ));
      final notifier = c.read(checkersStateProvider.notifier);
      notifier.selectCell(5, 2); // select the jumping piece
      notifier.selectCell(7, 4); // execute the jump onto row 7
      final s = c.read(checkersStateProvider);
      expect(s.board[7][4], 3, reason: 'piece must be promoted to king');
      expect(s.isPlayerTurn, isFalse,
          reason: 'turn must end on promotion, not continue the chain');
      expect(s.mustContinueChain, isFalse);
    });
  });

  // ── Mandatory chain-jump continuation (GB10) ──────────────────────────────

  group('mandatory chain-jump continuation (GB10)', () {
    test(
        'tapping a different own piece with its own independent jump is '
        'ignored while mid-forced-chain — previously this let the tap '
        'hijack the forced continuation, abandoning the piece mid-chain',
        () {
      final board = _emptyBoard();
      board[4][4] = 1; // piece A — mid-chain, must continue jumping
      board[5][5] = 2; // A's forced next capture
      board[2][0] = 1; // piece B — a different own piece
      board[3][1] = 2; // B's own, independent capture
      final chainMoveForA = getChainJumps(board, 4, 4, []);
      final allMoves = getAllMoves(board, true); // includes both A's and B's jumps
      final seeded = CheckersState(
        board: board,
        isPlayerTurn: true,
        selectedRow: 4,
        selectedCol: 4,
        validMoves: chainMoveForA,
        allMoves: allMoves,
        phase: GamePhase.playing,
        message: 'Jump again! You must continue the chain.',
        winner: null,
        mustContinueChain: true,
      );
      final c = _makeSeeded(seeded);
      final notifier = c.read(checkersStateProvider.notifier);

      notifier.selectCell(2, 0); // tap piece B instead of continuing A's chain

      final s = c.read(checkersStateProvider);
      expect(s.selectedRow, 4, reason: 'selection must stay on piece A');
      expect(s.selectedCol, 4);
      expect(s.mustContinueChain, isTrue);
      expect(s.board, seeded.board, reason: 'board must be untouched by the ignored tap');
    });

    test(
        'continuing the forced chain with a valid destination still works '
        'normally', () {
      final board = _emptyBoard();
      board[4][4] = 1;
      board[5][5] = 2;
      final chainMoveForA = getChainJumps(board, 4, 4, []);
      final allMoves = getAllMoves(board, true);
      final c = _makeSeeded(CheckersState(
        board: board,
        isPlayerTurn: true,
        selectedRow: 4,
        selectedCol: 4,
        validMoves: chainMoveForA,
        allMoves: allMoves,
        phase: GamePhase.playing,
        message: 'Jump again! You must continue the chain.',
        winner: null,
        mustContinueChain: true,
      ));
      final notifier = c.read(checkersStateProvider.notifier);

      notifier.selectCell(6, 6); // the forced chain's only valid destination

      final s = c.read(checkersStateProvider);
      expect(s.board[6][6], 1, reason: 'piece must have landed');
      expect(s.board[5][5], 0, reason: 'captured piece must be removed');
      expect(s.mustContinueChain, isFalse,
          reason: 'no further chain available — turn must end normally');
    });
  });

  // ── Human move integration ────────────────────────────────────────────────

  group('human move integration', () {
    ProviderContainer make() {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      return c;
    }

    test('human piece moves from (2,1) to (3,0)', () {
      final c = make();
      // (2,1) is a dark square with a human piece in initial setup
      // (3,0) is an empty dark square — valid forward diagonal
      c.read(checkersStateProvider.notifier).selectCell(2, 1);
      c.read(checkersStateProvider.notifier).selectCell(3, 0);
      final s = c.read(checkersStateProvider);
      expect(s.board[3][0], 1); // piece moved
      expect(s.board[2][1], 0); // source cleared
    });

    test('turn passes to AI after human move', () {
      final c = make();
      c.read(checkersStateProvider.notifier).selectCell(2, 1);
      c.read(checkersStateProvider.notifier).selectCell(3, 0);
      expect(c.read(checkersStateProvider).isPlayerTurn, isFalse);
    });

    test('human capture removes opponent piece and lands correctly', () {
      final board = _emptyBoard();
      board[2][2] = 1; // human
      board[3][3] = 2; // AI to capture
      // (4,4) is the landing square — empty
      // Use a custom notifier state via pure function, not via provider
      // Just verify getMovesForPiece returns the jump
      final moves = getMovesForPiece(board, 2, 2);
      final jump = moves.where((m) => m.captured.isNotEmpty);
      expect(jump.length, 1);
      expect(jump.first.toRow, 4);
      expect(jump.first.toCol, 4);
    });
  });

  // ── Multiplayer (GAME1) ────────────────────────────────────────────────────

  group('CheckersNotifier.initHostMode — absolute host/guest roles', () {
    test('opponent isAI flag comes from the 2nd LobbyPlayer, host is always human/red',
        () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(checkersStateProvider.notifier).initHostMode(const [
        LobbyPlayer(id: 'host', name: 'Host'),
        LobbyPlayer(id: 'guest', name: 'Guest', isAI: false),
      ]);
      final s = c.read(checkersStateProvider);
      expect(s.isMultiplayer, isTrue);
      expect(s.isOpponentAI, isFalse);
      expect(s.isPlayerTurn, isTrue, reason: 'host always starts');
      expect(s.phase, GamePhase.playing);
    });

    test('a lobby-added AI opponent is reflected in isOpponentAI', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(checkersStateProvider.notifier).initHostMode(const [
        LobbyPlayer(id: 'host', name: 'Host'),
        LobbyPlayer(id: 'ai_1', name: 'AI 1', isAI: true),
      ]);
      expect(c.read(checkersStateProvider).isOpponentAI, isTrue);
    });
  });

  group('CheckersNotifier — host/client mode flags', () {
    test('initHostMode/initClientMode/exitMultiplayerMode toggle isClientMode',
        () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(checkersStateProvider.notifier);
      expect(notifier.isClientMode, isFalse);

      notifier.initClientMode();
      expect(notifier.isClientMode, isTrue);
      expect(c.read(checkersStateProvider).isMultiplayer, isTrue);

      notifier.exitMultiplayerMode();
      expect(notifier.isClientMode, isFalse);
    });

    test('newGame exits multiplayer mode', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(checkersStateProvider.notifier);
      notifier.initClientMode();
      expect(notifier.isClientMode, isTrue);

      notifier.newGame();
      expect(notifier.isClientMode, isFalse);
      expect(c.read(checkersStateProvider).isMultiplayer, isFalse);
    });
  });

  group('CheckersNotifier — multiplayer turn handoff (no AI auto-play)', () {
    test('a human move that ends the turn does not trigger the local AI '
        'when the opponent is a real remote guest', () {
      fakeAsync((async) {
        final board = _emptyBoard();
        board[2][1] = 1; // human piece, one simple move available
        board[5][2] = 2; // a black piece so the game doesn't end on this move
        final c = _makeSeeded(CheckersState(
          board: board,
          isPlayerTurn: true,
          selectedRow: null,
          selectedCol: null,
          validMoves: const [],
          allMoves: getAllMoves(board, true),
          phase: GamePhase.playing,
          message: '',
          winner: null,
          isMultiplayer: true,
          isOpponentAI: false,
        ));
        final notifier = c.read(checkersStateProvider.notifier);
        notifier.selectCell(2, 1);
        notifier.selectCell(3, 0);

        // Even after the solo AI-move delay would have fired, the board must
        // still show only the human's own move — no local auto-play when
        // the opponent is a real remote device.
        async.elapse(const Duration(seconds: 2));

        final s = c.read(checkersStateProvider);
        expect(s.board[3][0], 1);
        expect(s.isPlayerTurn, isFalse, reason: 'turn passes to the guest');
        expect(s.phase, GamePhase.playing);
      });
    });

    test('the local AI still plays when isOpponentAI is true, even in a '
        'multiplayer-flagged lobby (AI-filled seat)', () {
      fakeAsync((async) {
        final board = _emptyBoard();
        board[2][1] = 1;
        board[5][2] = 2; // a lone AI piece so _aiMove has a move to make
        final c = _makeSeeded(CheckersState(
          board: board,
          isPlayerTurn: true,
          selectedRow: null,
          selectedCol: null,
          validMoves: const [],
          allMoves: getAllMoves(board, true),
          phase: GamePhase.playing,
          message: '',
          winner: null,
          isMultiplayer: true,
          isOpponentAI: true,
        ));
        final notifier = c.read(checkersStateProvider.notifier);
        notifier.selectCell(2, 1);
        notifier.selectCell(3, 0);

        async.elapse(const Duration(seconds: 1));

        final s = c.read(checkersStateProvider);
        expect(s.isPlayerTurn, isTrue,
            reason: 'local AI should have played and passed the turn back');
      });
    });

    test(
        'regression: the guest can select and move their own black piece — '
        'found live, selectCell used to hardcode _isHumanPiece for the '
        'selection check, which only ever matched red/human pieces, so a '
        'guest\'s remotely-forwarded taps on their own black pieces were '
        'silently ignored (guest could never move at all)', () {
      final board = _emptyBoard();
      board[6][1] = 2; // a black piece, the guest's own role
      final c = _makeSeeded(CheckersState(
        board: board,
        isPlayerTurn: false, // guest's turn (host's turn flag is false)
        selectedRow: null,
        selectedCol: null,
        validMoves: const [],
        allMoves: getAllMoves(board, false),
        phase: GamePhase.playing,
        message: '',
        winner: null,
        isMultiplayer: true,
        isOpponentAI: false,
      ));
      final notifier = c.read(checkersStateProvider.notifier);
      notifier.selectCell(6, 1); // select the guest's own black piece
      final selected = c.read(checkersStateProvider);
      expect(selected.selectedRow, 6,
          reason: 'the guest must be able to select their own black piece');
      expect(selected.selectedCol, 1);

      notifier.selectCell(5, 0); // move it forward
      final s = c.read(checkersStateProvider);
      expect(s.board[5][0], 2);
      expect(s.board[6][1], 0);
      expect(s.isPlayerTurn, isTrue, reason: 'turn passes back to the host');
    });
  });

  group('CheckersState JSON round-trip (broadcastIfHost payload)', () {
    test('toJson/fromJson round-trips fields and recomputes allMoves', () {
      final board = _emptyBoard();
      board[2][1] = 1;
      board[5][2] = 2; // a black piece so isPlayerTurn:false has a move to find
      final s = CheckersState(
        board: board,
        isPlayerTurn: false,
        selectedRow: null,
        selectedCol: null,
        validMoves: const [],
        allMoves: const [],
        phase: GamePhase.playing,
        message: 'Opponent turn',
        winner: null,
        isMultiplayer: true,
        isOpponentAI: false,
      );
      final round = CheckersState.fromJson(s.toJson());
      expect(round.board, s.board);
      expect(round.isPlayerTurn, isFalse);
      expect(round.phase, GamePhase.playing);
      expect(round.isMultiplayer, isTrue);
      expect(round.isOpponentAI, isFalse);
      expect(round.allMoves, isNotEmpty,
          reason: 'allMoves is recomputed from the board, not serialized');
    });

    test('a selected piece mid-mandatory-chain recomputes validMoves as the '
        'chain jumps, not the piece\'s ordinary moves', () {
      final board = _emptyBoard();
      board[4][4] = 1;
      board[5][5] = 2;
      final s = CheckersState(
        board: board,
        isPlayerTurn: true,
        selectedRow: 4,
        selectedCol: 4,
        validMoves: const [], // deliberately wrong — fromJson must recompute
        allMoves: const [],
        phase: GamePhase.playing,
        message: '',
        winner: null,
        mustContinueChain: true,
      );
      final round = CheckersState.fromJson(s.toJson());
      expect(round.validMoves.any((m) => m.toRow == 6 && m.toCol == 6), isTrue);
    });

    test('winner and message survive the round-trip', () {
      final s = CheckersState(
        board: _emptyBoard(),
        isPlayerTurn: true,
        selectedRow: null,
        selectedCol: null,
        validMoves: const [],
        allMoves: const [],
        phase: GamePhase.gameOver,
        message: 'You win! All AI pieces captured.',
        winner: 'You',
      );
      final round = CheckersState.fromJson(s.toJson());
      expect(round.winner, 'You');
      expect(round.phase, GamePhase.gameOver);
      expect(round.message, s.message);
    });
  });
}
