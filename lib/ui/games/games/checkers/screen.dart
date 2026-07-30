import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/lan/lan_providers.dart';
import '../../components/game_help_screen.dart';
import '../../components/game_rules_data.dart';
import 'logic.dart';

void _sendOrApply(WidgetRef ref, CheckersNotifier notifier, int row, int col) {
  if (notifier.isClientMode) {
    ref.read(gameLanServiceProvider).sendMove('selectCell', {'row': row, 'col': col});
  } else {
    notifier.selectCell(row, col);
  }
}

const _kOverlay = Color(0xBB000000);
const _kGameText = Colors.white;

// Board colors
const _kDarkSquare = Color(0xFF8B4513);
const _kLightSquare = Color(0xFFFFDEAD);
const _kSelectedSquare = Color(0xFFFFD700);
const _kValidMoveHint = Color(0xFF66BB6A);

// Piece colors
const _kHumanPiece = Color(0xFFCC2200);
const _kHumanKingBorder = Color(0xFFFF6644);
const _kAiPiece = Color(0xFF212121);
const _kAiPieceBorder = Color(0xFF555555);

class CheckersScreen extends ConsumerStatefulWidget {
  const CheckersScreen({super.key});

  @override
  ConsumerState<CheckersScreen> createState() => _CheckersScreenState();
}

class _CheckersScreenState extends ConsumerState<CheckersScreen> {
  @override
  Widget build(BuildContext context) {
    final gs = ref.watch(checkersStateProvider);
    final notifier = ref.read(checkersStateProvider.notifier);
    final amIHost = !notifier.isClientMode;
    final myTurn = gs.isPlayerTurn == amIHost;
    // Broadcast messages are written from the host's own perspective — on
    // the guest's screen these would read backwards (same class of bug
    // caught live in Yatzy's turn-handoff text), so derive a perspective-
    // correct message locally instead of trusting `gs.message` verbatim.
    final displayMessage = gs.isMultiplayer && gs.phase != GamePhase.gameOver
        ? (myTurn
            ? (gs.mustContinueChain
                ? 'Jump again! Continue your chain.'
                : 'Your turn — tap a piece to select it.')
            : "Opponent's turn…")
        : gs.message;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(children: [
          Image.asset(
            'assets/games/games/checkers/icon.jpg',
            height: 36,
            errorBuilder: (_, _, _) =>
                const Icon(Icons.casino, size: 36, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Text(
            'Checkers',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'New game',
            onPressed: () => notifier.newGame(),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            tooltip: 'How to play',
            onPressed: () => showGameHelp(context, checkersHelp),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/games/common/longship_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _MessageBar(displayMessage),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = (constraints.maxWidth < constraints.maxHeight - 100
                                ? constraints.maxWidth
                                : constraints.maxHeight - 100)
                            .clamp(0.0, constraints.maxWidth);
                        return Center(
                          child: _CheckersBoard(
                            gs: gs,
                            size: size,
                            onTap: (r, c) => _sendOrApply(ref, notifier, r, c),
                          ),
                        );
                      },
                    ),
                  ),
                  _LegendBar(amIHost: amIHost, isMultiplayer: gs.isMultiplayer),
                ],
              ),
              if (gs.phase == GamePhase.gameOver)
                _GameOverOverlay(
                  winner: gs.winner,
                  message: gs.message,
                  amIHost: amIHost,
                  isMultiplayer: gs.isMultiplayer,
                  onRestart: () => notifier.newGame(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Message bar
// ──────────────────────────────────────────────

class _MessageBar extends StatelessWidget {
  final String msg;
  const _MessageBar(this.msg);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _kOverlay,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        msg,
        style: const TextStyle(color: _kGameText, fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Board
// ──────────────────────────────────────────────

class _CheckersBoard extends StatelessWidget {
  final CheckersState gs;
  final double size;
  final void Function(int row, int col) onTap;

  const _CheckersBoard({
    required this.gs,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cellSize = size / 8;

    // Build a set of valid destination squares for quick lookup
    final validDests = <(int, int)>{
      for (final m in gs.validMoves) (m.toRow, m.toCol),
    };

    return SizedBox(
      width: size,
      height: size,
      child: Column(
        children: List.generate(8, (row) {
          return Row(
            children: List.generate(8, (col) {
              final isDark = (row + col) % 2 == 1;
              final piece = gs.board[row][col];
              final isSelected =
                  gs.selectedRow == row && gs.selectedCol == col;
              final isValidDest = validDests.contains((row, col));

              return GestureDetector(
                onTap: isDark ? () => onTap(row, col) : null,
                child: _Square(
                  size: cellSize,
                  isDark: isDark,
                  piece: piece,
                  isSelected: isSelected,
                  isValidDest: isValidDest,
                ),
              );
            }),
          );
        }),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Single square
// ──────────────────────────────────────────────

class _Square extends StatelessWidget {
  final double size;
  final bool isDark;
  final int piece;
  final bool isSelected;
  final bool isValidDest;

  const _Square({
    required this.size,
    required this.isDark,
    required this.piece,
    required this.isSelected,
    required this.isValidDest,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    if (!isDark) {
      bgColor = _kLightSquare;
    } else if (isSelected) {
      bgColor = _kSelectedSquare;
    } else if (isValidDest) {
      bgColor = _kDarkSquare.withValues(alpha: 0.7);
    } else {
      bgColor = _kDarkSquare;
    }

    return Container(
      width: size,
      height: size,
      color: bgColor,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (!isDark) {
      return const SizedBox.shrink();
    }

    // Valid move hint dot (no piece on this square)
    if (isValidDest && piece == 0) {
      return Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: _kValidMoveHint.withValues(alpha: 0.85),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white54, width: 1),
          ),
        ),
      );
    }

    if (piece == 0) {
      return const SizedBox.shrink();
    }

    return _Piece(piece: piece, squareSize: size);
  }
}

// ──────────────────────────────────────────────
// Piece widget
// ──────────────────────────────────────────────

class _Piece extends StatelessWidget {
  final int piece;
  final double squareSize;

  const _Piece({required this.piece, required this.squareSize});

  @override
  Widget build(BuildContext context) {
    final isHuman = piece == 1 || piece == 3;
    final isKing = piece == 3 || piece == 4;
    final diameter = squareSize * 0.78;

    final Color fill = isHuman ? _kHumanPiece : _kAiPiece;
    final Color border = isHuman ? _kHumanKingBorder : _kAiPieceBorder;

    return Center(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fill,
          border: Border.all(color: border, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 4,
              offset: Offset(1, 2),
            ),
          ],
        ),
        child: isKing
            ? const Center(
                child: Icon(
                  Icons.star,
                  color: Color(0xFFFFD700),
                  size: 16,
                ),
              )
            : null,
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Legend bar
// ──────────────────────────────────────────────

class _LegendBar extends StatelessWidget {
  final bool amIHost;
  final bool isMultiplayer;
  const _LegendBar({required this.amIHost, required this.isMultiplayer});

  @override
  Widget build(BuildContext context) {
    // Host always plays red/human pieces, guest always plays black/"AI"
    // pieces — no board flip, so the guest is "You (Black)", not "You (Red)".
    final opponentWord = isMultiplayer ? 'Opponent' : 'AI';
    final redLabel = amIHost ? 'You (Red)' : '$opponentWord (Red)';
    final blackLabel = amIHost ? '$opponentWord (Black)' : 'You (Black)';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _kOverlay,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legendItem(color: _kHumanPiece, label: redLabel),
          _legendItem(color: _kAiPiece, label: blackLabel, borderColor: _kAiPieceBorder),
          Row(children: [
            const Icon(Icons.star, color: Color(0xFFFFD700), size: 14),
            const SizedBox(width: 4),
            const Text('= King', style: TextStyle(color: _kGameText, fontSize: 12)),
          ]),
        ],
      ),
    );
  }

  Widget _legendItem({
    required Color color,
    required String label,
    Color? borderColor,
  }) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: borderColor ?? color.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: _kGameText, fontSize: 12)),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Game over overlay
// ──────────────────────────────────────────────

class _GameOverOverlay extends StatelessWidget {
  final String? winner;
  final String message;
  final bool amIHost;
  final bool isMultiplayer;
  final VoidCallback onRestart;

  const _GameOverOverlay({
    required this.winner,
    required this.message,
    required this.amIHost,
    required this.isMultiplayer,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    // `winner` is absolute ('You' = host's side won, 'AI' = guest/"AI" side
    // won) regardless of which screen is looking at it — the guest must
    // translate it through its own role, or a host win would show "You Win!"
    // on the losing guest's screen too (same bug class as Yatzy's message).
    //
    // A disconnect (see _handleDisconnect in logic.dart) also sets
    // phase: gameOver but leaves winner null since nobody actually won —
    // (winner == 'You') == amIHost would then evaluate true for whichever
    // side happens to match, showing a nonsensical "You Win!" on an
    // ended-by-disconnect game (found live in cribbage). Treat a null
    // winner as its own case instead.
    final hasWinner = winner != null;
    final isPlayerWin = hasWinner && (winner == 'You') == amIHost;
    final opponentWord = isMultiplayer ? 'Opponent' : 'AI';
    final title =
        !hasWinner ? 'Game Ended' : (isPlayerWin ? 'You Win!' : '$opponentWord Wins!');
    final emoji = !hasWinner ? '🔌' : (isPlayerWin ? '🏆' : (isMultiplayer ? '🎮' : '🤖'));

    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPlayerWin
                  ? const Color(0xFFFFD700)
                  : const Color(0xFF555555),
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black87,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                !hasWinner
                    ? message
                    : (isPlayerWin ? 'Great game, Captain!' : 'Better luck next time.'),
                style: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRestart,
                icon: const Icon(Icons.refresh),
                label: const Text('Play Again'),
                style: FilledButton.styleFrom(
                  backgroundColor: isPlayerWin
                      ? const Color(0xFF8B4513)
                      : const Color(0xFF444444),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
