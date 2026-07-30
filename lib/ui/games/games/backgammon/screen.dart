import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/lan/lan_providers.dart';
import '../../components/game_help_screen.dart';
import '../../components/game_rules_data.dart';
import 'logic.dart';

void _sendOrApply(WidgetRef ref, BackgammonNotifier notifier, String action,
    [Map<String, dynamic> data = const {}]) {
  if (notifier.isClientMode) {
    ref.read(gameLanServiceProvider).sendMove(action, data);
  } else {
    switch (action) {
      case 'roll':
        notifier.roll();
      case 'selectPoint':
        notifier.selectPoint(data['pointIdx'] as int);
      case 'bearOff':
        notifier.bearOff();
      case 'passTurn':
        notifier.passTurn();
      case 'offerDouble':
        notifier.offerDouble();
      case 'acceptDouble':
        notifier.acceptDouble();
      case 'declineDouble':
        notifier.declineDouble();
    }
  }
}

const _kOverlay = Color(0xBB000000);
const _kGameText = Colors.white;
const _kGameTextMuted = Color(0xFFb0bec5);
const _kHuman = Color(0xFFF5F5DC);  // cream/white
const _kAi = Color(0xFF1A1A1A);     // near-black
const _kPointDark = Color(0xFF8B4513);
const _kPointLight = Color(0xFF228B22);
const _kSelected = Color(0xFFFFD600);
const _kBarColor = Color(0xFF4E342E);

class BackgammonScreen extends ConsumerWidget {
  const BackgammonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gs = ref.watch(backgammonStateProvider);
    final notifier = ref.read(backgammonStateProvider.notifier);
    final amIHost = !notifier.isClientMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Image.asset('assets/games/games/backgammon/icon.jpg', height: 32,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.casino, size: 32, color: Colors.white)),
          const SizedBox(width: 8),
          const Flexible(
            child: Text('Backgammon',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ]),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'New game',
              onPressed: notifier.newGame),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            tooltip: 'How to play',
            onPressed: () => showGameHelp(context, backgammonHelp),
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
          child: gs.phase == BgPhase.gameOver
              ? _GameOver(gs: gs, amIHost: amIHost, onNew: notifier.newGame)
              : _GameLayout(gs: gs, notifier: notifier, amIHost: amIHost),
        ),
      ),
    );
  }
}

class _GameLayout extends StatelessWidget {
  final BackgammonState gs;
  final BackgammonNotifier notifier;
  final bool amIHost;
  const _GameLayout({required this.gs, required this.notifier, required this.amIHost});

  @override
  Widget build(BuildContext context) {
    final myTurn = gs.isHumanTurn == amIHost;
    // Broadcast messages are written from whichever role is acting — on the
    // other screen they'd read backwards (same class of bug caught live in
    // Yatzy/Checkers), so derive a perspective-correct message locally
    // instead of trusting gs.message verbatim in multiplayer.
    final displayMessage = gs.isMultiplayer
        ? (gs.phase == BgPhase.doubleOffered
            ? ((gs.doubleOfferedByHuman == amIHost)
                ? 'Double offered — waiting for opponent…'
                : 'Opponent offers double to ${gs.cubeValue * 2}. Accept or decline?')
            : (myTurn
                ? (gs.phase == BgPhase.rolling
                    ? 'Your turn — roll${gs.canOfferDouble ? ' or double' : ''}.'
                    : 'Your turn — select a piece (${gs.movesLeft.join(", ")} left).')
                : "Opponent's turn…"))
        : gs.message;
    return Column(children: [
      _ScoreBar(gs: gs, amIHost: amIHost),
      _MsgBar(displayMessage),
      const SizedBox(height: 4),
      Expanded(child: _Board(gs: gs, notifier: notifier, amIHost: amIHost)),
      const SizedBox(height: 4),
      _Controls(gs: gs, notifier: notifier, amIHost: amIHost),
    ]);
  }
}

class _ScoreBar extends StatelessWidget {
  final BackgammonState gs;
  final bool amIHost;
  const _ScoreBar({required this.gs, required this.amIHost});
  @override
  Widget build(BuildContext context) {
    final opponentWord = gs.isMultiplayer ? 'Opponent' : 'AI';
    final whiteLabel = amIHost ? 'You (white)' : '$opponentWord (white)';
    final blackLabel = amIHost ? '$opponentWord (black)' : 'You (black)';
    return Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
            color: _kOverlay, borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          _pip(whiteLabel, gs.humanBornOff, gs.humanBar, _kHuman),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // GB7 doubling cube display
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade800,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '×${gs.cubeValue}'
                    '${gs.cubeOwnerIsHuman == null ? '' : (gs.cubeOwnerIsHuman == amIHost ? ' you' : ' opp')}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
                if (gs.dice.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: gs.dice
                          .map((d) => Container(
                                width: 26,
                                height: 26,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4)),
                                child: Center(
                                    child: Text('$d',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14))),
                              ))
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
          _pip(blackLabel, gs.aiBornOff, gs.aiBar, _kAi),
        ]),
      );
  }

  Widget _pip(String label, int off, int bar, Color c) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: _kGameTextMuted, fontSize: 11)),
          Row(children: [
            Container(
                width: 12, height: 12,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                    color: c, shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24))),
            Text('Off:$off  Bar:$bar',
                style: const TextStyle(color: _kGameText, fontSize: 11)),
          ]),
        ],
      );
}

class _MsgBar extends StatelessWidget {
  final String msg;
  const _MsgBar(this.msg);

  // Fixed height = 3 lines of fontSize-12 text (≈14.4 px each) + 12 px vertical padding
  static const _height = 56.0;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        height: _height,
        decoration:
            BoxDecoration(color: _kOverlay, borderRadius: BorderRadius.circular(8)),
        child: Center(
          child: Text(msg,
              style: const TextStyle(color: _kGameText, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis),
        ),
      );
}

bool _canBearOff(BackgammonState gs, bool amIHost) {
  final from = gs.selectedPoint;
  if (from == null || from < 0) return false;
  for (final die in gs.movesLeft.toSet()) {
    final dests = amIHost ? validHumanMoves(gs, from, die) : validAiMoves(gs, from, die);
    if (dests.contains(-2)) return true;
  }
  return false;
}

bool _hasAnyMyMove(BackgammonState gs, bool amIHost) {
  for (final die in gs.movesLeft.toSet()) {
    final barCount = amIHost ? gs.humanBar : gs.aiBar;
    if (barCount > 0) {
      final dests = amIHost ? validHumanMoves(gs, -1, die) : validAiMoves(gs, -1, die);
      if (dests.isNotEmpty) return true;
    }
    for (int i = 0; i < 24; i++) {
      final owns = amIHost ? gs.board[i] > 0 : gs.board[i] < 0;
      if (owns) {
        final dests = amIHost ? validHumanMoves(gs, i, die) : validAiMoves(gs, i, die);
        if (dests.isNotEmpty) return true;
      }
    }
  }
  return false;
}

class _Controls extends ConsumerWidget {
  final BackgammonState gs;
  final BackgammonNotifier notifier;
  final bool amIHost;
  const _Controls({required this.gs, required this.notifier, required this.amIHost});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myTurn = gs.isHumanTurn == amIHost;
    final isMoving = gs.phase == BgPhase.moving && myTurn;
    final canBear = isMoving && _canBearOff(gs, amIHost);
    final noMoves = isMoving && !_hasAnyMyMove(gs, amIHost);

    // Who must answer a double: opposite of who offered.
    final iMustAnswerDouble = gs.phase == BgPhase.doubleOffered &&
        gs.doubleOfferedByHuman != null &&
        gs.doubleOfferedByHuman != amIHost;
    final iCanOffer = gs.phase == BgPhase.rolling &&
        myTurn &&
        gs.canOfferDouble;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          if (iMustAnswerDouble) ...[
            FilledButton.icon(
              onPressed: () => _sendOrApply(ref, notifier, 'acceptDouble'),
              icon: const Icon(Icons.check),
              label: Text('Accept ×${gs.cubeValue * 2}'),
            ),
            FilledButton.icon(
              onPressed: () => _sendOrApply(ref, notifier, 'declineDouble'),
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
              icon: const Icon(Icons.close),
              label: Text('Decline (lose ×${gs.cubeValue})'),
            ),
          ],
          if (gs.phase == BgPhase.rolling && myTurn)
            FilledButton.icon(
              onPressed: () => _sendOrApply(ref, notifier, 'roll'),
              icon: const Icon(Icons.casino),
              label: const Text('Roll Dice'),
            ),
          if (iCanOffer)
            OutlinedButton.icon(
              onPressed: () => _sendOrApply(ref, notifier, 'offerDouble'),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.amber)),
              icon: const Icon(Icons.casino_outlined, color: Colors.amber),
              label: Text('Double ×${gs.cubeValue * 2}',
                  style: const TextStyle(color: Colors.amber)),
            ),
          if (canBear)
            FilledButton.icon(
              onPressed: () => _sendOrApply(ref, notifier, 'bearOff'),
              icon: const Icon(Icons.home),
              label: const Text('Bear Off'),
            ),
          if (noMoves)
            FilledButton.icon(
              onPressed: () => _sendOrApply(ref, notifier, 'passTurn'),
              icon: const Icon(Icons.skip_next),
              label: const Text('Pass Turn'),
            ),
          if (isMoving)
            OutlinedButton(
              onPressed: () =>
                  _sendOrApply(ref, notifier, 'selectPoint', {'pointIdx': -1000}),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54)),
              child: const Text('Deselect', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}

// ── Board ─────────────────────────────────────────────────────────────────────

class _Board extends StatelessWidget {
  final BackgammonState gs;
  final BackgammonNotifier notifier;
  final bool amIHost;
  const _Board({required this.gs, required this.notifier, required this.amIHost});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, bc) {
      final w = bc.maxWidth - 32;
      final h = bc.maxHeight;
      final pointW = w / 13; // 12 points + bar in center
      return Center(
        child: Container(
          width: w,
          height: h,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF3E2723),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: Stack(children: [
            // Top row: points 13–18 (left) + bar + 19–24 (right) — AI's side
            _PointRow(
              gs: gs,
              notifier: notifier,
              amIHost: amIHost,
              pointIndices: [12,13,14,15,16,17,18,19,20,21,22,23],
              top: true,
              pointW: pointW,
              boardH: h,
            ),
            // Bottom row: points 12–7 (left) + bar + 6–1 (right) — Human's side
            _PointRow(
              gs: gs,
              notifier: notifier,
              amIHost: amIHost,
              pointIndices: [11,10,9,8,7,6,5,4,3,2,1,0],
              top: false,
              pointW: pointW,
              boardH: h,
            ),
            // Bar
            Positioned(
              left: pointW * 6,
              top: 0,
              child: Container(
                width: pointW,
                height: h,
                color: _kBarColor,
                child: _BarPieces(gs: gs, notifier: notifier, amIHost: amIHost),
              ),
            ),
          ]),
        ),
      );
    });
  }
}

class _BarPieces extends ConsumerWidget {
  final BackgammonState gs;
  final BackgammonNotifier notifier;
  final bool amIHost;
  const _BarPieces({required this.gs, required this.notifier, required this.amIHost});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Both bar groups are tappable — whichever one belongs to the local
    // viewer's role selects it (host=human/bottom, guest=AI/top); the
    // selection highlight only ever applies to the bar the tapper actually
    // owns (gs.selectedPoint==-1 is set regardless of whose turn it is, so
    // showing it on both would highlight the opponent's bar piece too).
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < gs.aiBar; i++)
          GestureDetector(
            onTap: () => _sendOrApply(ref, notifier, 'selectPoint', {'pointIdx': -1}),
            child: _Checker(
              color: _kAi,
              size: 18,
              selected: !amIHost && gs.selectedPoint == -1,
            ),
          ),
        const SizedBox(height: 4),
        for (int i = 0; i < gs.humanBar; i++)
          GestureDetector(
            onTap: () => _sendOrApply(ref, notifier, 'selectPoint', {'pointIdx': -1}),
            child: _Checker(
              color: _kHuman,
              size: 18,
              selected: amIHost && gs.selectedPoint == -1,
            ),
          ),
      ],
    );
  }
}

class _PointRow extends ConsumerWidget {
  final BackgammonState gs;
  final BackgammonNotifier notifier;
  final bool amIHost;
  final List<int> pointIndices; // 12 indices, index 6 = bar gap
  final bool top;
  final double pointW;
  final double boardH;

  const _PointRow({
    required this.gs,
    required this.notifier,
    required this.amIHost,
    required this.pointIndices,
    required this.top,
    required this.pointW,
    required this.boardH,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      top: top ? 0 : boardH / 2,
      left: 0,
      child: SizedBox(
        width: pointW * 13,
        height: boardH / 2,
        child: Row(
          children: List.generate(13, (col) {
            if (col == 6) return SizedBox(width: pointW); // bar gap
            final idx = col < 6 ? pointIndices[col] : pointIndices[col - 1];
            final isSelected = gs.selectedPoint == idx;
            final isValidDest = _isValidDest(idx);
            final pieces = gs.board[idx];
            final isLight = idx % 2 == 0;

            return GestureDetector(
              onTap: () =>
                  _sendOrApply(ref, notifier, 'selectPoint', {'pointIdx': idx}),
              child: SizedBox(
                width: pointW,
                child: Column(
                  mainAxisAlignment:
                      top ? MainAxisAlignment.start : MainAxisAlignment.end,
                  children: [
                    // Triangle — top row points DOWN (toward center), bottom points UP
                    SizedBox(
                      width: pointW,
                      height: boardH * 0.27,
                      child: CustomPaint(
                        painter: _TrianglePainter(
                          color: isLight ? _kPointLight : _kPointDark,
                          pointsDown: top,
                          highlight: isValidDest || isSelected,
                        ),
                      ),
                    ),
                    // Pieces
                    Expanded(
                      child: ClipRect(
                        child: _PieceStack(
                          count: pieces,
                          selected: isSelected,
                          top: top,
                          amIHost: amIHost,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // Only meaningful during the LOCAL viewer's own turn (myTurn) — the
  // destination-hint highlight is my own move options, computed against
  // whichever role I actually play (host=human, guest=AI), not hardcoded
  // human (same class of bug fixed in checkers/logic.dart's selectCell).
  bool _isValidDest(int idx) {
    final myTurn = gs.isHumanTurn == amIHost;
    if (gs.selectedPoint == null || gs.phase != BgPhase.moving || !myTurn) {
      return false;
    }
    final from = gs.selectedPoint!;
    for (final die in gs.movesLeft.toSet()) {
      final dests =
          amIHost ? validHumanMoves(gs, from, die) : validAiMoves(gs, from, die);
      if (dests.contains(idx)) return true;
    }
    return false;
  }
}

class _PieceStack extends StatelessWidget {
  final int count; // >0 human, <0 AI
  final bool selected;
  final bool top;
  final bool amIHost;
  const _PieceStack(
      {required this.count, required this.selected, required this.top, required this.amIHost});

  @override
  Widget build(BuildContext context) {
    final isHuman = count > 0;
    final abs = count.abs();
    if (abs == 0) return const SizedBox.shrink();
    final color = isHuman ? _kHuman : _kAi;
    // Only highlight the piece as "selected" for whichever role is actually
    // mine (host=human, guest=AI) — otherwise a guest's selection would
    // render on the host's own white pieces instead of their own black ones.
    final isMine = isHuman == amIHost;
    return Column(
      mainAxisAlignment: top ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: List.generate(
        abs.clamp(0, 5),
        (i) => _Checker(color: color, size: 18, selected: selected && isMine),
      ),
    );
  }
}

class _Checker extends StatelessWidget {
  final Color color;
  final double size;
  final bool selected;
  const _Checker({required this.color, required this.size, this.selected = false});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        margin: const EdgeInsets.symmetric(vertical: 1),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
              color: selected ? _kSelected : Colors.white38,
              width: selected ? 2 : 1),
        ),
      );
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  final bool pointsDown;
  final bool highlight;
  const _TrianglePainter(
      {required this.color, required this.pointsDown, required this.highlight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = highlight ? color.withValues(alpha: 0.7) : color
      ..style = PaintingStyle.fill;
    final path = Path();
    if (pointsDown) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
    } else {
      path.moveTo(size.width / 2, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) =>
      old.color != color || old.highlight != highlight;
}

class _GameOver extends StatelessWidget {
  final BackgammonState gs;
  final bool amIHost;
  final VoidCallback onNew;
  const _GameOver({required this.gs, required this.amIHost, required this.onNew});
  @override
  Widget build(BuildContext context) {
    // Who actually won is derivable straight from state (bornOff==15) rather
    // than needing a separate winner field — humanBornOff==15 means the
    // host's role won, regardless of which screen is looking at it. gs.message
    // is written from whichever role's move triggered game over, so it reads
    // backwards on the loser's screen in multiplayer (same class of bug as
    // Checkers' win overlay) — translate it through the viewer's own role.
    //
    // A disconnect (see _handleDisconnect in logic.dart) also sets
    // phase: gameOver without either side reaching 15 born off, since nobody
    // actually won — didHostWin would default to false, so the guest
    // (amIHost: false) would see didIWin: true and show a nonsensical
    // "You win!" on an ended-by-disconnect game (found live in cribbage).
    // Treat "neither side actually finished" as its own case.
    final hasWinner = gs.humanBornOff == 15 || gs.aiBornOff == 15;
    final didHostWin = gs.humanBornOff == 15;
    final didIWin = hasWinner && (amIHost ? didHostWin : !didHostWin);
    final opponentWord = gs.isMultiplayer ? 'Opponent' : 'AI';
    final message = !hasWinner
        ? gs.message
        : (gs.isMultiplayer
            ? (didIWin
                ? 'You win! All pieces borne off (×${gs.cubeValue}).'
                : '$opponentWord wins! All pieces borne off (×${gs.cubeValue}).')
            : gs.message);
    return Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
              color: _kOverlay, borderRadius: BorderRadius.circular(16)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.anchor, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            Text(message,
                style: const TextStyle(
                    color: _kGameText,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onNew,
              icon: const Icon(Icons.refresh),
              label: const Text('New Game'),
            ),
          ]),
        ),
      );
  }
}
