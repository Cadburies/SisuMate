import 'dart:async';

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

class BackgammonScreen extends ConsumerStatefulWidget {
  const BackgammonScreen({super.key});

  @override
  ConsumerState<BackgammonScreen> createState() => _BackgammonScreenState();
}

class _BackgammonScreenState extends ConsumerState<BackgammonScreen> {
  /// GAI6: solo practice coach — on-demand Hint button.
  bool _coachMode = false;
  /// GAI7: after each human turn, auto-show Hard-AI review for that roll.
  bool _practiceMode = false;
  StreamSubscription<CoachHint>? _practiceSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final n = ref.read(backgammonStateProvider.notifier);
      _practiceSub = n.practiceReviews.listen((hint) {
        if (!mounted || !_practiceMode) return;
        _showCoachSheet(
          context,
          hint,
          title: 'Practice review',
          subtitle:
              'What Hard AI would play for the roll you just finished — nothing moved.',
        );
      });
    });
  }

  @override
  void dispose() {
    _practiceSub?.cancel();
    super.dispose();
  }

  void _showCoachHint(BuildContext context, BackgammonNotifier notifier) {
    _showCoachSheet(
      context,
      notifier.coachHint(),
      title: 'Coach hint',
      subtitle: 'Suggestion only — nothing is moved for you.',
    );
  }

  void _showCoachSheet(
    BuildContext context,
    CoachHint hint, {
    required String title,
    required String subtitle,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    title.startsWith('Practice')
                        ? Icons.model_training
                        : Icons.lightbulb_outline,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
              ),
              const Divider(height: 20, color: Colors.white24),
              if (hint.hasPlay) ...[
                Text(
                  'Suggested play',
                  style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                        color: Colors.amber.shade200,
                      ),
                ),
                const SizedBox(height: 6),
                for (var i = 0; i < hint.steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${i + 1}. ${_formatStep(hint.steps[i])}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                const SizedBox(height: 12),
              ],
              Text(
                'Why',
                style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                      color: Colors.amber.shade200,
                    ),
              ),
              const SizedBox(height: 6),
              for (final r in hint.reasons)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('· ', style: TextStyle(color: Colors.white70)),
                      Expanded(
                        child: Text(r,
                            style: const TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatStep(AiPlayStep step) {
    final (from, to, die) = step;
    String lab(int i) {
      if (i == -1) return 'bar';
      if (i == -2) return 'off';
      return 'pt ${i + 1}';
    }

    return '${lab(from)} → ${lab(to)}  (die $die)';
  }

  @override
  Widget build(BuildContext context) {
    final gs = ref.watch(backgammonStateProvider);
    final notifier = ref.read(backgammonStateProvider.notifier);
    final amIHost = !notifier.isClientMode;
    // Coach is for solo / practice vs local AI — not multiplayer guest thrash.
    final coachAvailable = !gs.isMultiplayer || gs.isOpponentAI;

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
          if (coachAvailable) ...[
            IconButton(
              icon: Icon(
                _coachMode ? Icons.school : Icons.school_outlined,
                color: _coachMode ? Colors.amber : Colors.white,
              ),
              tooltip: _coachMode ? 'Coach on (tap Hint)' : 'Coach mode',
              onPressed: () => setState(() => _coachMode = !_coachMode),
            ),
            IconButton(
              icon: Icon(
                _practiceMode ? Icons.model_training : Icons.model_training_outlined,
                color: _practiceMode ? Colors.lightGreenAccent : Colors.white,
              ),
              tooltip: _practiceMode
                  ? 'Practice on (review after your turn)'
                  : 'Practice mode',
              onPressed: () {
                setState(() => _practiceMode = !_practiceMode);
                notifier.practiceMode = _practiceMode;
              },
            ),
          ],
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
              : _GameLayout(
                  gs: gs,
                  notifier: notifier,
                  amIHost: amIHost,
                  coachMode: _coachMode && coachAvailable,
                  onCoachHint: () => _showCoachHint(context, notifier),
                ),
        ),
      ),
    );
  }
}

class _GameLayout extends StatelessWidget {
  final BackgammonState gs;
  final BackgammonNotifier notifier;
  final bool amIHost;
  final bool coachMode;
  final VoidCallback? onCoachHint;
  const _GameLayout({
    required this.gs,
    required this.notifier,
    required this.amIHost,
    this.coachMode = false,
    this.onCoachHint,
  });

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
      _Controls(
        gs: gs,
        notifier: notifier,
        amIHost: amIHost,
        coachMode: coachMode,
        onCoachHint: onCoachHint,
      ),
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
                    child: _DiceRollDisplay(
                      dice: gs.dice,
                      movesLeft: gs.movesLeft,
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

/// Classic 1-6 die faces with pips (dots), not just numbers.
/// Dimmed faces mean that die value is fully spent for this turn.
class _DiceRollDisplay extends StatelessWidget {
  final List<int> dice;
  final List<int> movesLeft;
  const _DiceRollDisplay({required this.dice, required this.movesLeft});

  @override
  Widget build(BuildContext context) {
    // Count remaining uses per face so doubles can dim one at a time.
    final remaining = <int, int>{};
    for (final d in movesLeft) {
      remaining[d] = (remaining[d] ?? 0) + 1;
    }
    // For display we show each entry in [dice] once; for doubles both faces
    // stay lit while any moves of that value remain.
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < dice.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          _DieFace(
            value: dice[i].clamp(1, 6),
            size: 32,
            active: (remaining[dice[i]] ?? 0) > 0,
          ),
        ],
        if (movesLeft.isNotEmpty && movesLeft.length > dice.length) ...[
          const SizedBox(width: 6),
          Text(
            'x${movesLeft.length}',
            style: const TextStyle(
              color: _kGameTextMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _DieFace extends StatelessWidget {
  final int value; // 1-6
  final double size;
  final bool active;
  const _DieFace({
    required this.value,
    required this.size,
    this.active = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: active ? 1.0 : 0.35,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E7),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.black54, width: 1.2),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 3,
                    offset: const Offset(0.5, 1.5),
                  ),
                ]
              : null,
        ),
        child: CustomPaint(
          painter: _DiePipsPainter(value: value),
        ),
      ),
    );
  }
}

class _DiePipsPainter extends CustomPainter {
  final int value;
  const _DiePipsPainter({required this.value});

  // Pip centers as fractions of die size (classic layout).
  static List<Offset> _pipsFor(int v) {
    const tl = Offset(0.28, 0.28);
    const tr = Offset(0.72, 0.28);
    const ml = Offset(0.28, 0.50);
    const c = Offset(0.50, 0.50);
    const mr = Offset(0.72, 0.50);
    const bl = Offset(0.28, 0.72);
    const br = Offset(0.72, 0.72);
    return switch (v) {
      1 => const [c],
      2 => const [tl, br],
      3 => const [tl, c, br],
      4 => const [tl, tr, bl, br],
      5 => const [tl, tr, c, bl, br],
      6 => const [tl, tr, ml, mr, bl, br],
      _ => const [c],
    };
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;
    final r = size.shortestSide * 0.11;
    for (final p in _pipsFor(value.clamp(1, 6))) {
      canvas.drawCircle(
        Offset(p.dx * size.width, p.dy * size.height),
        r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DiePipsPainter old) => old.value != value;
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
  final bool coachMode;
  final VoidCallback? onCoachHint;
  const _Controls({
    required this.gs,
    required this.notifier,
    required this.amIHost,
    this.coachMode = false,
    this.onCoachHint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myTurn = gs.isHumanTurn == amIHost;
    final isMoving = gs.phase == BgPhase.moving && myTurn;
    final canBear = isMoving && _canBearOff(gs, amIHost);
    final noMoves = isMoving && !_hasAnyMyMove(gs, amIHost);
    final canHint = coachMode &&
        onCoachHint != null &&
        myTurn &&
        (gs.phase == BgPhase.moving || gs.phase == BgPhase.rolling);

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
          if (canHint)
            OutlinedButton.icon(
              onPressed: onCoachHint,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.amber),
              ),
              icon: const Icon(Icons.lightbulb_outline, color: Colors.amber),
              label: const Text('Hint', style: TextStyle(color: Colors.amber)),
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
            border: Border.all(color: const Color(0xFF5D4037), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(children: [
            // Mid-board hinge line (classic folded table feel).
            Positioned(
              left: 0,
              right: 0,
              top: h / 2 - 1,
              child: Container(height: 2, color: const Color(0xFF2A1A14)),
            ),
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
                decoration: BoxDecoration(
                  color: _kBarColor,
                  border: Border.symmetric(
                    vertical: BorderSide(
                      color: Colors.black.withValues(alpha: 0.25),
                    ),
                  ),
                ),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: _Checker(
                color: _kAi,
                size: 20,
                selected: !amIHost && gs.selectedPoint == -1,
              ),
            ),
          ),
        const SizedBox(height: 6),
        for (int i = 0; i < gs.humanBar; i++)
          GestureDetector(
            onTap: () => _sendOrApply(ref, notifier, 'selectPoint', {'pointIdx': -1}),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: _Checker(
                color: _kHuman,
                size: 20,
                selected: amIHost && gs.selectedPoint == -1,
              ),
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
    final halfH = boardH / 2;
    // Checker diameter scales with point width so stacks sit on the triangle.
    final checkerSize = (pointW * 0.82).clamp(14.0, 28.0);
    return Positioned(
      top: top ? 0 : halfH,
      left: 0,
      child: SizedBox(
        width: pointW * 13,
        height: halfH,
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
                height: halfH,
                // Triangle is the point surface; checkers are painted ON it
                // (stacked from the outer board edge toward the bar/center).
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _TrianglePainter(
                          color: isLight ? _kPointLight : _kPointDark,
                          pointsDown: top,
                          highlight: isValidDest || isSelected,
                        ),
                      ),
                    ),
                    Positioned(
                      top: top ? 3 : null,
                      bottom: top ? null : 3,
                      left: 0,
                      right: 0,
                      child: _PieceStack(
                        count: pieces,
                        selected: isSelected,
                        top: top,
                        amIHost: amIHost,
                        checkerSize: checkerSize,
                        maxStackHeight: halfH * 0.92,
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
  final double checkerSize;
  final double maxStackHeight;

  const _PieceStack({
    required this.count,
    required this.selected,
    required this.top,
    required this.amIHost,
    required this.checkerSize,
    required this.maxStackHeight,
  });

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

    // Overlap so a tall stack still sits on the point triangle.
    final step = (checkerSize * 0.62).clamp(8.0, checkerSize);
    final maxVisible = ((maxStackHeight - checkerSize) / step).floor() + 1;
    final visible = abs.clamp(1, maxVisible.clamp(1, 8));
    final overflow = abs - visible;

    // Stack from outer edge: top half grows downward, bottom half upward.
    return Center(
      child: SizedBox(
        height: checkerSize + (visible - 1) * step,
        width: checkerSize + 2,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < visible; i++)
              Positioned(
                top: top ? i * step : null,
                bottom: top ? null : i * step,
                left: 1,
                child: _Checker(
                  color: color,
                  size: checkerSize,
                  // Highlight the outer-most (base) checker when selected.
                  selected: selected && isMine && i == 0,
                ),
              ),
            if (overflow > 0)
              Positioned(
                top: top ? (visible - 1) * step + checkerSize * 0.15 : null,
                bottom:
                    top ? null : (visible - 1) * step + checkerSize * 0.15,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+$overflow',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: (checkerSize * 0.35).clamp(9.0, 12.0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
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
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Soft face so checkers read as sitting on the point wood.
          gradient: RadialGradient(
            center: const Alignment(-0.35, -0.4),
            radius: 0.95,
            colors: [
              Color.lerp(color, Colors.white, 0.22)!,
              color,
              Color.lerp(color, Colors.black, 0.18)!,
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
          border: Border.all(
              color: selected ? _kSelected : Colors.black38,
              width: selected ? 2.2 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 2.5,
              offset: const Offset(0.5, 1.2),
            ),
          ],
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
    final base = highlight ? Color.lerp(color, Colors.amber, 0.25)! : color;
    final path = Path();
    if (pointsDown) {
      // Base along the outer (top) edge; tip toward the board center.
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
    } else {
      // Base along the outer (bottom) edge; tip toward the board center.
      path.moveTo(size.width / 2, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    }
    path.close();

    final fill = Paint()
      ..shader = LinearGradient(
        begin: pointsDown ? Alignment.topCenter : Alignment.bottomCenter,
        end: pointsDown ? Alignment.bottomCenter : Alignment.topCenter,
        colors: [
          Color.lerp(base, Colors.white, 0.08)!,
          base,
          Color.lerp(base, Colors.black, 0.18)!,
        ],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fill);

    final edge = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(path, edge);

    if (highlight) {
      final glow = Paint()
        ..color = _kSelected.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawPath(path, glow);
    }
  }

  @override
  bool shouldRepaint(_TrianglePainter old) =>
      old.color != color ||
      old.highlight != highlight ||
      old.pointsDown != pointsDown;
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
