import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/lan/game_lan_service.dart';
import '../../../../services/lan/lan_providers.dart';

final _rng = Random();

enum GamePhase { playing, gameOver }

class CheckersMove {
  final int fromRow;
  final int fromCol;
  final int toRow;
  final int toCol;
  final List<(int, int)> captured;

  const CheckersMove({
    required this.fromRow,
    required this.fromCol,
    required this.toRow,
    required this.toCol,
    this.captured = const [],
  });
}

class CheckersState {
  final List<List<int>> board;
  final bool isPlayerTurn;
  final int? selectedRow;
  final int? selectedCol;
  final List<CheckersMove> validMoves;
  final List<CheckersMove> allMoves;
  final GamePhase phase;
  final String message;
  final String? winner;
  // GB10: true while the selected piece is mid-forced-chain-jump — the only
  // legal action is continuing that exact piece's jump; taps elsewhere
  // (including a different own piece with its own independent jump) must be
  // ignored rather than letting them hijack the forced continuation.
  final bool mustContinueChain;
  // GAME1: absolute host/guest model, same shape as yatzy/logic.dart — the
  // host is always the human/red side (isPlayerTurn: true means host's turn),
  // the opponent is always the black/"AI" side (values 2/4), whether that's
  // the local AI (solo, isOpponentAI: true) or a real remote guest
  // (multiplayer, isOpponentAI: false). No board flip for the guest — same
  // absolute orientation on both screens (see screen.dart for perspective
  // handling of labels/messages).
  final bool isMultiplayer;
  final bool isOpponentAI;

  const CheckersState({
    required this.board,
    required this.isPlayerTurn,
    required this.selectedRow,
    required this.selectedCol,
    required this.validMoves,
    required this.allMoves,
    required this.phase,
    required this.message,
    required this.winner,
    this.mustContinueChain = false,
    this.isMultiplayer = false,
    this.isOpponentAI = true,
  });

  CheckersState copyWith({
    List<List<int>>? board,
    bool? isPlayerTurn,
    Object? selectedRow = _sentinel,
    Object? selectedCol = _sentinel,
    List<CheckersMove>? validMoves,
    List<CheckersMove>? allMoves,
    GamePhase? phase,
    String? message,
    Object? winner = _sentinel,
    bool? mustContinueChain,
    bool? isMultiplayer,
    bool? isOpponentAI,
  }) {
    return CheckersState(
      board: board ?? this.board,
      isPlayerTurn: isPlayerTurn ?? this.isPlayerTurn,
      selectedRow: selectedRow == _sentinel ? this.selectedRow : selectedRow as int?,
      selectedCol: selectedCol == _sentinel ? this.selectedCol : selectedCol as int?,
      validMoves: validMoves ?? this.validMoves,
      allMoves: allMoves ?? this.allMoves,
      phase: phase ?? this.phase,
      message: message ?? this.message,
      winner: winner == _sentinel ? this.winner : winner as String?,
      mustContinueChain: mustContinueChain ?? this.mustContinueChain,
      isMultiplayer: isMultiplayer ?? this.isMultiplayer,
      isOpponentAI: isOpponentAI ?? this.isOpponentAI,
    );
  }

  Map<String, dynamic> toJson() => {
        'board': board,
        'isPlayerTurn': isPlayerTurn,
        'selectedRow': selectedRow,
        'selectedCol': selectedCol,
        'phase': phase.name,
        'message': message,
        'winner': winner,
        'mustContinueChain': mustContinueChain,
        'isMultiplayer': isMultiplayer,
        'isOpponentAI': isOpponentAI,
      };

  // Move lists aren't serialized (CheckersMove.captured is a tuple list, not
  // trivially JSON-safe) — they're pure functions of the rest of the state,
  // so recompute them here instead of shipping them over the wire.
  factory CheckersState.fromJson(Map<String, dynamic> j) {
    final board = (j['board'] as List)
        .map((row) => (row as List).cast<int>())
        .toList();
    final isPlayerTurn = j['isPlayerTurn'] as bool;
    final selectedRow = j['selectedRow'] as int?;
    final selectedCol = j['selectedCol'] as int?;
    final mustContinueChain = j['mustContinueChain'] as bool? ?? false;
    final allMoves = getAllMoves(board, isPlayerTurn);

    var validMoves = <CheckersMove>[];
    if (selectedRow != null && selectedCol != null) {
      if (mustContinueChain) {
        validMoves = getChainJumps(board, selectedRow, selectedCol, const []);
      } else {
        final mustJump = allMoves.isNotEmpty && allMoves.first.captured.isNotEmpty;
        validMoves = mustJump
            ? allMoves
                .where((m) => m.fromRow == selectedRow && m.fromCol == selectedCol)
                .toList()
            : getMovesForPiece(board, selectedRow, selectedCol);
      }
    }

    return CheckersState(
      board: board,
      isPlayerTurn: isPlayerTurn,
      selectedRow: selectedRow,
      selectedCol: selectedCol,
      validMoves: validMoves,
      allMoves: allMoves,
      phase: GamePhase.values.byName(j['phase'] as String),
      message: j['message'] as String,
      winner: j['winner'] as String?,
      mustContinueChain: mustContinueChain,
      isMultiplayer: j['isMultiplayer'] as bool? ?? false,
      isOpponentAI: j['isOpponentAI'] as bool? ?? true,
    );
  }
}

// ── GAI2: minimax + alpha-beta search ───────────────────────────────────
//
// A "full turn" is the unit of search, not a single board step: a mandatory
// chain jump keeps the same side to move and isn't a real choice point for
// the opponent, so each node explores every complete forced-capture
// sequence (or, absent captures, every simple move) as one branch rather
// than treating each jump hop as its own ply.

class _TurnOutcome {
  final CheckersMove firstMove;
  final List<List<int>> board;
  const _TurnOutcome(this.firstMove, this.board);
}

/// Applies one move/jump step in place; returns true if it just promoted
/// (which — per GB9 — ends the turn even mid-chain).
bool _applyStep(List<List<int>> board, CheckersMove move) {
  final piece = board[move.fromRow][move.fromCol];
  for (final (cr, cc) in move.captured) {
    board[cr][cc] = 0;
  }
  board[move.fromRow][move.fromCol] = 0;
  board[move.toRow][move.toCol] = piece;
  final justPromoted =
      (piece == 1 && move.toRow == 7) || (piece == 2 && move.toRow == 0);
  if (justPromoted) {
    board[move.toRow][move.toCol] = _isHumanPiece(piece) ? 3 : 4;
  }
  return justPromoted;
}

List<_TurnOutcome> _fullTurnOutcomes(List<List<int>> board, bool isHumanTurn) {
  final firstMoves = getAllMoves(board, isHumanTurn);
  if (firstMoves.isEmpty) {
    return const [];
  }

  final outcomes = <_TurnOutcome>[];
  if (firstMoves.first.captured.isEmpty) {
    for (final m in firstMoves) {
      final b = _copyBoard(board);
      _applyStep(b, m);
      outcomes.add(_TurnOutcome(m, b));
    }
    return outcomes;
  }

  void extendChain(
      List<List<int>> b, CheckersMove firstMove, int row, int col) {
    final chainJumps = getChainJumps(b, row, col, const []);
    if (chainJumps.isEmpty) {
      outcomes.add(_TurnOutcome(firstMove, b));
      return;
    }
    for (final cj in chainJumps) {
      final b2 = _copyBoard(b);
      final promoted = _applyStep(b2, cj);
      if (promoted) {
        outcomes.add(_TurnOutcome(firstMove, b2));
      } else {
        extendChain(b2, firstMove, cj.toRow, cj.toCol);
      }
    }
  }

  for (final m in firstMoves) {
    final b = _copyBoard(board);
    final promoted = _applyStep(b, m);
    if (promoted) {
      outcomes.add(_TurnOutcome(m, b));
    } else {
      extendChain(b, m, m.toRow, m.toCol);
    }
  }
  return outcomes;
}

/// Material + advancement, positive favors the AI (black).
double _evaluateBoard(List<List<int>> board) {
  double score = 0;
  for (int r = 0; r < 8; r++) {
    for (int c = 0; c < 8; c++) {
      final p = board[r][c];
      if (p == 0) continue;
      final isKing = _isKing(p);
      final sign = _isAiPiece(p) ? 1.0 : -1.0;
      score += sign * (isKing ? 1.5 : 1.0);
      if (!isKing) {
        score += sign * (_isAiPiece(p) ? (7 - r) : r) * 0.02;
      }
    }
  }
  return score;
}

const int _aiSearchDepth = 6;
const double _winScore = 1000.0;

double _minimaxValue(
  List<List<int>> board,
  bool isHumanTurn,
  int depth,
  double alpha,
  double beta,
) {
  final outcomes = _fullTurnOutcomes(board, isHumanTurn);
  if (outcomes.isEmpty) {
    // Side to move is stuck — loses.
    return isHumanTurn ? _winScore : -_winScore;
  }
  if (depth == 0) {
    return _evaluateBoard(board);
  }

  if (isHumanTurn) {
    var best = double.infinity;
    for (final o in outcomes) {
      final value = _minimaxValue(o.board, false, depth - 1, alpha, beta);
      if (value < best) best = value;
      if (best < beta) beta = best;
      if (beta <= alpha) break;
    }
    return best;
  }

  var best = -double.infinity;
  for (final o in outcomes) {
    final value = _minimaxValue(o.board, true, depth - 1, alpha, beta);
    if (value > best) best = value;
    if (best > alpha) alpha = best;
    if (beta <= alpha) break;
  }
  return best;
}

/// Root search: picks the AI's best full turn, breaking ties randomly
/// across equally-good options so play isn't fully deterministic.
///
/// TEST28: pass [rng] (e.g. [Random] with a fixed seed) so two runs with the
/// same board + seed pick the same tied outcome.
_TurnOutcome? _selectAiTurn(List<List<int>> board, {Random? rng}) {
  final r = rng ?? _rng;
  final outcomes = _fullTurnOutcomes(board, false);
  if (outcomes.isEmpty) {
    return null;
  }

  var alpha = -double.infinity;
  const beta = double.infinity;
  var bestValue = -double.infinity;
  final best = <_TurnOutcome>[];

  for (final o in outcomes) {
    final value =
        _minimaxValue(o.board, true, _aiSearchDepth - 1, alpha, beta);
    if (value > bestValue + 1e-9) {
      bestValue = value;
      best
        ..clear()
        ..add(o);
    } else if (value >= bestValue - 1e-9) {
      best.add(o);
    }
    if (value > alpha) alpha = value;
  }

  return best[r.nextInt(best.length)];
}

/// TEST28: board after AI's chosen turn (null if no moves). Same seed → same board.
@visibleForTesting
List<List<int>>? debugSelectAiBoard(List<List<int>> board, {Random? rng}) {
  final o = _selectAiTurn(board, rng: rng);
  if (o == null) return null;
  // Deep copy so tests don't mutate shared lists.
  return o.board.map((row) => List<int>.from(row)).toList();
}

// Sentinel to distinguish null from "not provided" in copyWith
const Object _sentinel = Object();

List<List<int>> _buildInitialBoard() {
  final board = List.generate(8, (_) => List.filled(8, 0));
  // Human (red = 1) starts at rows 0, 1, 2 on dark squares
  for (int r = 0; r < 3; r++) {
    for (int c = 0; c < 8; c++) {
      if ((r + c) % 2 == 1) {
        board[r][c] = 1;
      }
    }
  }
  // AI (black = 2) starts at rows 5, 6, 7 on dark squares
  for (int r = 5; r < 8; r++) {
    for (int c = 0; c < 8; c++) {
      if ((r + c) % 2 == 1) {
        board[r][c] = 2;
      }
    }
  }
  return board;
}

bool _isHumanPiece(int v) => v == 1 || v == 3;
bool _isAiPiece(int v) => v == 2 || v == 4;
bool _isKing(int v) => v == 3 || v == 4;

List<int> _forwardDirs(int piece) {
  // Human moves toward row 7 (increasing), AI moves toward row 0 (decreasing)
  if (_isKing(piece)) {
    return [-1, 1];
  }
  if (_isHumanPiece(piece)) {
    return [1];
  }
  return [-1];
}

List<CheckersMove> getMovesForPiece(
  List<List<int>> board,
  int row,
  int col, {
  List<(int, int)> alreadyCaptured = const [],
  bool jumpsOnly = false,
}) {
  final piece = board[row][col];
  if (piece == 0) {
    return [];
  }

  final moves = <CheckersMove>[];
  final rowDirs = _forwardDirs(piece);
  const colDirs = [-1, 1];

  // Jump moves
  for (final dr in rowDirs) {
    for (final dc in colDirs) {
      final midR = row + dr;
      final midC = col + dc;
      final landR = row + dr * 2;
      final landC = col + dc * 2;

      if (landR < 0 || landR >= 8 || landC < 0 || landC >= 8) {
        continue;
      }

      final midPiece = board[midR][midC];
      final landPiece = board[landR][landC];

      final isOpponent = _isHumanPiece(piece)
          ? _isAiPiece(midPiece)
          : _isHumanPiece(midPiece);

      final alreadyInPath =
          alreadyCaptured.contains((midR, midC));

      if (isOpponent && !alreadyInPath && landPiece == 0) {
        moves.add(CheckersMove(
          fromRow: row,
          fromCol: col,
          toRow: landR,
          toCol: landC,
          captured: [...alreadyCaptured, (midR, midC)],
        ));
      }
    }
  }

  if (jumpsOnly || moves.isNotEmpty) {
    return moves;
  }

  // Simple moves (only if no jumps)
  for (final dr in rowDirs) {
    for (final dc in colDirs) {
      final toR = row + dr;
      final toC = col + dc;

      if (toR < 0 || toR >= 8 || toC < 0 || toC >= 8) {
        continue;
      }

      if (board[toR][toC] == 0) {
        moves.add(CheckersMove(
          fromRow: row,
          fromCol: col,
          toRow: toR,
          toCol: toC,
        ));
      }
    }
  }

  return moves;
}

List<CheckersMove> getAllMoves(List<List<int>> board, bool isPlayerTurn) {
  final allMoves = <CheckersMove>[];
  final jumpMoves = <CheckersMove>[];

  for (int r = 0; r < 8; r++) {
    for (int c = 0; c < 8; c++) {
      final piece = board[r][c];
      if (piece == 0) {
        continue;
      }
      final isPlayerPiece = _isHumanPiece(piece);
      if (isPlayerPiece != isPlayerTurn) {
        continue;
      }
      final pieceMoves = getMovesForPiece(board, r, c);
      for (final m in pieceMoves) {
        if (m.captured.isNotEmpty) {
          jumpMoves.add(m);
        } else {
          allMoves.add(m);
        }
      }
    }
  }

  if (jumpMoves.isNotEmpty) {
    return jumpMoves;
  }
  return allMoves;
}

List<CheckersMove> getChainJumps(
  List<List<int>> board,
  int row,
  int col,
  List<(int, int)> alreadyCaptured,
) {
  final piece = board[row][col];
  if (piece == 0) {
    return [];
  }

  final rowDirs = _forwardDirs(piece);
  const colDirs = [-1, 1];
  final jumps = <CheckersMove>[];

  for (final dr in rowDirs) {
    for (final dc in colDirs) {
      final midR = row + dr;
      final midC = col + dc;
      final landR = row + dr * 2;
      final landC = col + dc * 2;

      if (landR < 0 || landR >= 8 || landC < 0 || landC >= 8) {
        continue;
      }

      final midPiece = board[midR][midC];
      final landPiece = board[landR][landC];

      final isOpponent = _isHumanPiece(piece)
          ? _isAiPiece(midPiece)
          : _isHumanPiece(midPiece);

      final alreadyInPath = alreadyCaptured.contains((midR, midC));

      if (isOpponent && !alreadyInPath && landPiece == 0) {
        jumps.add(CheckersMove(
          fromRow: row,
          fromCol: col,
          toRow: landR,
          toCol: landC,
          captured: [...alreadyCaptured, (midR, midC)],
        ));
      }
    }
  }

  return jumps;
}

List<List<int>> _copyBoard(List<List<int>> board) {
  return [for (final row in board) [...row]];
}

bool _hasAnyPieces(List<List<int>> board, bool forPlayer) {
  for (int r = 0; r < 8; r++) {
    for (int c = 0; c < 8; c++) {
      final p = board[r][c];
      if (forPlayer && _isHumanPiece(p)) {
        return true;
      }
      if (!forPlayer && _isAiPiece(p)) {
        return true;
      }
    }
  }
  return false;
}

class CheckersNotifier extends Notifier<CheckersState> {
  bool _isHostMode = false;
  bool _isClientMode = false;

  bool get isClientMode => _isClientMode;

  StreamSubscription<Map<String, dynamic>>? _remoteSub;
  StreamSubscription<({String peerId, String action, Map<String, dynamic> data})>?
      _moveSub;
  StreamSubscription<String>? _leaveSub;

  // Bumped on every initClientMode()/exitMultiplayerMode() call so an
  // in-flight reconnect retry loop from a previous session can tell it's
  // stale and stop touching state after the notifier has moved on.
  int _sessionGeneration = 0;

  @override
  CheckersState build() {
    ref.onDispose(() {
      _remoteSub?.cancel();
      _moveSub?.cancel();
      _leaveSub?.cancel();
    });
    final board = _buildInitialBoard();
    final moves = getAllMoves(board, true);
    return CheckersState(
      board: board,
      isPlayerTurn: true,
      selectedRow: null,
      selectedCol: null,
      validMoves: const [],
      allMoves: moves,
      phase: GamePhase.playing,
      message: 'Your turn — tap a red piece to select it.',
      winner: null,
    );
  }

  // ── Multiplayer setup (mirrors yatzy/logic.dart's absolute host/guest
  // model — Checkers is strictly 2-role, no player-id roster needed) ────────

  void initHostMode(List<LobbyPlayer> lobbyPlayers) {
    _isHostMode = true;
    _isClientMode = false;
    _sessionGeneration++;
    _remoteSub?.cancel();
    _moveSub?.cancel();
    _leaveSub?.cancel();

    final lan = ref.read(gameLanServiceProvider);
    _moveSub = lan.incomingMoves.listen(_applyRemoteMove);
    _leaveSub = lan.playerLeaves.listen(_handleDisconnect);

    final opponent = lobbyPlayers.length > 1 ? lobbyPlayers[1] : null;
    final board = _buildInitialBoard();
    state = CheckersState(
      board: board,
      isPlayerTurn: true,
      selectedRow: null,
      selectedCol: null,
      validMoves: const [],
      allMoves: getAllMoves(board, true),
      phase: GamePhase.playing,
      message: 'Game ready. Starting...',
      winner: null,
      isMultiplayer: true,
      isOpponentAI: opponent?.isAI ?? true,
    );
    // Checkers has no separate startGame()/determineStarter() step to
    // naturally re-broadcast a couple of seconds later (same gap found live
    // in Yatzy) — delay briefly so the guest's initClientMode() subscription
    // has attached before this fires, instead of it being stuck on its own
    // "Waiting for host..." default forever.
    Timer(const Duration(seconds: 1), _broadcastIfHost);
  }

  void initClientMode() {
    _isClientMode = true;
    _isHostMode = false;
    _moveSub?.cancel();
    _leaveSub?.cancel();
    final generation = ++_sessionGeneration;

    final lan = ref.read(gameLanServiceProvider);
    _remoteSub = lan.remoteStates.listen((json) {
      state = CheckersState.fromJson(json);
    });
    _leaveSub = lan.playerLeaves.listen((peerId) {
      if (peerId == 'host') _handleHostDisconnect(generation);
    });

    final board = _buildInitialBoard();
    state = CheckersState(
      board: board,
      isPlayerTurn: true,
      selectedRow: null,
      selectedCol: null,
      validMoves: const [],
      allMoves: getAllMoves(board, true),
      phase: GamePhase.playing,
      message: 'Waiting for host...',
      winner: null,
      isMultiplayer: true,
      isOpponentAI: false,
    );
  }

  void exitMultiplayerMode() {
    _isHostMode = false;
    _isClientMode = false;
    _sessionGeneration++;
    _remoteSub?.cancel();
    _moveSub?.cancel();
    _leaveSub?.cancel();
  }

  /// Client-side: the connection to the host dropped. Surfaces a message and
  /// tries a few quick reconnects before giving up cleanly.
  Future<void> _handleHostDisconnect(int generation) async {
    if (generation != _sessionGeneration) return;
    state = state.copyWith(message: 'Connection lost. Reconnecting…');

    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      await Future.delayed(const Duration(seconds: 2));
      if (generation != _sessionGeneration) return;

      final reconnected = await ref.read(gameLanServiceProvider).reconnect();
      if (generation != _sessionGeneration) return;

      if (reconnected) {
        state = state.copyWith(message: 'Reconnected!');
        return;
      }
    }

    state = state.copyWith(
      phase: GamePhase.gameOver,
      message: 'Connection to host lost. Game ended.',
    );
  }

  // ── Host-side remote move handler ─────────────────────────────────────────

  void _applyRemoteMove(
      ({String peerId, String action, Map<String, dynamic> data}) move) {
    if (move.action == 'selectCell') {
      selectCell(move.data['row'] as int, move.data['col'] as int);
    }
  }

  void _broadcastIfHost() {
    if (_isHostMode) {
      ref.read(gameLanServiceProvider).broadcastState(state.toJson());
    }
  }

  // ── Disconnect handling ───────────────────────────────────────────────────
  //
  // Checkers has no player-id roster (fixed 2-role model) — any disconnect
  // while hosting can only be the one real guest, so it simply ends the game.
  void _handleDisconnect(String peerId) {
    state = state.copyWith(
      phase: GamePhase.gameOver,
      message: 'Opponent disconnected. Game ended.',
    );
    _broadcastIfHost();
  }

  void selectCell(int row, int col) {
    if (state.phase == GamePhase.gameOver) {
      return;
    }

    final board = state.board;
    final piece = board[row][col];

    // If a piece is already selected, check if this is a valid destination
    if (state.selectedRow != null && state.selectedCol != null) {
      final dest = state.validMoves.where(
        (m) => m.toRow == row && m.toCol == col,
      );
      if (dest.isNotEmpty) {
        _executeMove(dest.first);
        return;
      }
    }

    // Mid-forced-chain-jump: the selected piece must keep jumping. Ignore
    // any tap that isn't one of its own jump destinations (handled above)
    // rather than falling through to piece-selection below, which would
    // otherwise let a different own piece's independent jump hijack the
    // forced continuation (GB10).
    if (state.mustContinueChain) {
      return;
    }

    // Select a piece if it belongs to whichever role is currently active.
    // In solo mode `isPlayerTurn` is only ever true when this runs (the AI's
    // turn never calls selectCell), so this always meant "human/red" there.
    // In multiplayer, the guest's own taps are forwarded here too via
    // _applyRemoteMove while isPlayerTurn is false (the host's turn flag,
    // not "whoever tapped") — hardcoding _isHumanPiece would make the
    // guest's black pieces permanently unselectable. Match the active
    // role's color instead of assuming red.
    final isActivePiece =
        state.isPlayerTurn ? _isHumanPiece(piece) : _isAiPiece(piece);
    if (isActivePiece) {
      // Only allow selecting pieces that have valid moves
      // If there are mandatory jumps, only allow pieces that can jump
      final mustJump = state.allMoves.isNotEmpty &&
          state.allMoves.first.captured.isNotEmpty;

      List<CheckersMove> pieceMoves;
      if (mustJump) {
        pieceMoves = state.allMoves
            .where((m) => m.fromRow == row && m.fromCol == col)
            .toList();
      } else {
        pieceMoves = getMovesForPiece(board, row, col);
      }

      if (pieceMoves.isEmpty) {
        // Deselect
        state = state.copyWith(
          selectedRow: null,
          selectedCol: null,
          validMoves: const [],
        );
        _broadcastIfHost();
        return;
      }

      state = state.copyWith(
        selectedRow: row,
        selectedCol: col,
        validMoves: pieceMoves,
      );
      _broadcastIfHost();
      return;
    }

    // Tapping an empty or opponent square deselects
    state = state.copyWith(
      selectedRow: null,
      selectedCol: null,
      validMoves: const [],
    );
    _broadcastIfHost();
  }

  void _executeMove(CheckersMove move) {
    // Captured before any mutation: in solo mode this is always true (the
    // AI's turn never reaches selectCell/_executeMove), but in multiplayer
    // the guest's forwarded moves run through here too while isPlayerTurn is
    // false — the rest of this method must act on behalf of whichever role
    // actually moved, not assume "human just moved, switch to AI" (GAME1
    // regression: hardcoding that assumption made the guest's moves always
    // hand the turn to the wrong side and check the wrong side for a win).
    final activeIsHumanRole = state.isPlayerTurn;
    final board = _copyBoard(state.board);
    final piece = board[move.fromRow][move.fromCol];

    // Remove captured pieces
    for (final (cr, cc) in move.captured) {
      board[cr][cc] = 0;
    }

    // Move the piece
    board[move.fromRow][move.fromCol] = 0;
    board[move.toRow][move.toCol] = piece;

    // King promotion — a piece crowned on this move ends its turn
    // immediately, even mid-chain-jump: standard rules forbid a newly-kinged
    // piece from continuing to capture (backward or otherwise) in the same
    // turn (GB9). Only a piece that was already a king before this move may
    // continue the chain.
    final justPromoted = piece == 1 && move.toRow == 7;
    if (justPromoted) {
      board[move.toRow][move.toCol] = 3;
    }

    // Check for chain jump (skipped when this move just promoted the piece)
    if (!justPromoted && move.captured.isNotEmpty) {
      final chainJumps = getChainJumps(
        board,
        move.toRow,
        move.toCol,
        [], // fresh captured list for chain
      );

      if (chainJumps.isNotEmpty) {
        // Mandatory chain jump — keep the active role's turn, same piece
        // selected (still that role's move regardless of which side it is).
        final allMoves = getAllMoves(board, activeIsHumanRole);
        state = state.copyWith(
          board: board,
          selectedRow: move.toRow,
          selectedCol: move.toCol,
          validMoves: chainJumps,
          allMoves: allMoves,
          mustContinueChain: true,
          message: 'Jump again! You must continue the chain.',
        );
        _broadcastIfHost();
        return;
      }
    }

    // Hand the turn to the other role.
    final nextIsHumanRole = !activeIsHumanRole;
    final nextMoves = getAllMoves(board, nextIsHumanRole);

    // Check win condition — does the other role have moves/pieces left?
    if (nextMoves.isEmpty || !_hasAnyPieces(board, nextIsHumanRole)) {
      state = state.copyWith(
        board: board,
        isPlayerTurn: nextIsHumanRole,
        selectedRow: null,
        selectedCol: null,
        validMoves: const [],
        allMoves: const [],
        phase: GamePhase.gameOver,
        message: activeIsHumanRole
            ? 'You win! All AI pieces captured.'
            : 'AI wins! You have no moves left.',
        winner: activeIsHumanRole ? 'You' : 'AI',
        mustContinueChain: false,
      );
      _broadcastIfHost();
      return;
    }

    state = state.copyWith(
      board: board,
      isPlayerTurn: nextIsHumanRole,
      selectedRow: null,
      selectedCol: null,
      validMoves: const [],
      allMoves: nextMoves,
      mustContinueChain: false,
      message: nextIsHumanRole
          ? 'Your turn — tap a red piece to select it.'
          : 'AI is thinking...',
    );
    _broadcastIfHost();

    // A remote human opponent plays its own turn via its own device's taps —
    // only fire the local AI when there's no such opponent to wait for
    // (solo, or a multiplayer seat deliberately filled with a local AI).
    if (!nextIsHumanRole && (!state.isMultiplayer || state.isOpponentAI)) {
      Timer(const Duration(milliseconds: 600), _aiMove);
    }
  }

  /// Test-only synchronous entry point — production code only reaches
  /// _aiMove via the Timer in _executeMove, which unit tests can't await
  /// without going through a full human-move sequence first.
  @visibleForTesting
  void debugRunAiMove() => _aiMove();

  void _aiMove() {
    if (!_isMounted) {
      return;
    }
    if (state.phase == GamePhase.gameOver) {
      return;
    }

    // GAI2: minimax/alpha-beta over full turns (see _selectAiTurn) picks the
    // whole forced-chain sequence at once, rather than re-picking greedily
    // at each jump hop.
    final outcome = _selectAiTurn(state.board);
    if (outcome == null) {
      // AI has no moves — player wins
      state = state.copyWith(
        isPlayerTurn: true,
        selectedRow: null,
        selectedCol: null,
        validMoves: const [],
        allMoves: const [],
        phase: GamePhase.gameOver,
        message: 'You win! AI has no moves left.',
        winner: 'You',
      );
      _broadcastIfHost();
      return;
    }

    _finishAiMove(outcome.board);
  }

  void _finishAiMove(List<List<int>> board) {
    final playerMoves = getAllMoves(board, true);

    if (playerMoves.isEmpty || !_hasAnyPieces(board, true)) {
      state = state.copyWith(
        board: board,
        isPlayerTurn: true,
        selectedRow: null,
        selectedCol: null,
        validMoves: const [],
        allMoves: const [],
        phase: GamePhase.gameOver,
        message: 'AI wins! You have no moves left.',
        winner: 'AI',
      );
      _broadcastIfHost();
      return;
    }

    state = state.copyWith(
      board: board,
      isPlayerTurn: true,
      selectedRow: null,
      selectedCol: null,
      validMoves: const [],
      allMoves: playerMoves,
      message: 'Your turn — tap a red piece to select it.',
    );
    _broadcastIfHost();
  }

  // Notifier is alive as long as the provider is alive
  bool get _isMounted => true;

  void newGame() {
    exitMultiplayerMode();
    state = build();
  }
}

final checkersStateProvider =
    NotifierProvider<CheckersNotifier, CheckersState>(CheckersNotifier.new);
