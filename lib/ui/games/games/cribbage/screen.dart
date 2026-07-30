import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/lan/lan_providers.dart';
import '../../components/game_help_screen.dart';
import '../../components/game_rules_data.dart';
import 'logic.dart';

void _sendOrApply(WidgetRef ref, CribbageNotifier notifier, String action,
    [Map<String, dynamic> data = const {}]) {
  if (notifier.isClientMode) {
    ref.read(gameLanServiceProvider).sendMove(action, data);
  } else {
    switch (action) {
      case 'toggleDiscard':
        notifier.toggleDiscard(data['idx'] as int);
      case 'confirmDiscard':
        notifier.confirmDiscard();
      case 'playPegCard':
        notifier.playPegCard(data['handIdx'] as int);
      case 'sayGo':
        notifier.sayGo();
      case 'nextRound':
        notifier.nextRound();
    }
  }
}

// Guest's own hand uses separate action names (toggleAiDiscard/
// confirmAiDiscard) since the discard phase is simultaneous, not turn-based
// — see CribbageState's doc comment on aiFullHand.
void _sendOrApplyMine(WidgetRef ref, CribbageNotifier notifier, bool amIHost,
    String action, Map<String, dynamic> data) {
  final effectiveAction = amIHost
      ? action
      : (action == 'toggleDiscard' ? 'toggleAiDiscard' : 'confirmAiDiscard');
  if (notifier.isClientMode) {
    ref.read(gameLanServiceProvider).sendMove(effectiveAction, data);
  } else {
    switch (effectiveAction) {
      case 'toggleDiscard':
        notifier.toggleDiscard(data['idx'] as int);
      case 'confirmDiscard':
        notifier.confirmDiscard();
      case 'toggleAiDiscard':
        notifier.toggleAiDiscard(data['idx'] as int);
      case 'confirmAiDiscard':
        notifier.confirmAiDiscard();
    }
  }
}

const _kOverlay = Color(0xBB000000);
const _kGameText = Colors.white;
const _kGameTextMuted = Color(0xFFb0bec5);
const _kSelected = Color(0xFFFFD600);
const _kCardRed = Color(0xFFE53935);
const _kCardBlack = Colors.black87;

class CribbageScreen extends ConsumerWidget {
  const CribbageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gs = ref.watch(cribbageStateProvider);
    final notifier = ref.read(cribbageStateProvider.notifier);
    final amIHost = !notifier.isClientMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(children: [
          Image.asset('assets/games/games/cribbage/icon.jpg', height: 36,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.style, size: 36, color: Colors.white)),
          const SizedBox(width: 10),
          const Text('Cribbage',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'New game',
            onPressed: notifier.newGame,
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            tooltip: 'How to play',
            onPressed: () => showGameHelp(context, cribbageHelp),
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
          child: gs.phase == CribbagePhase.gameOver
              ? _GameOver(gs: gs, amIHost: amIHost, onNew: notifier.newGame)
              : _GameLayout(gs: gs, notifier: notifier, amIHost: amIHost),
        ),
      ),
    );
  }
}

// ── Main layout ───────────────────────────────────────────────────────────────

class _GameLayout extends StatelessWidget {
  final CribbageState gs;
  final CribbageNotifier notifier;
  final bool amIHost;
  const _GameLayout({required this.gs, required this.notifier, required this.amIHost});

  @override
  Widget build(BuildContext context) {
    // Broadcast messages are written from whichever role is acting — on the
    // other screen they'd read backwards (same class of bug caught live in
    // Yatzy/Checkers/Backgammon). Cribbage has too many distinct message
    // strings to translate individually, so derive a simple, always-correct
    // phase+turn message instead of trusting gs.message verbatim in
    // multiplayer (the host still sees the rich original text).
    final displayMessage = !gs.isMultiplayer
        ? gs.message
        : switch (gs.phase) {
            CribbagePhase.discarding => () {
                final myConfirmed =
                    amIHost ? gs.hostDiscardConfirmed : gs.guestDiscardConfirmed;
                final oppConfirmed =
                    amIHost ? gs.guestDiscardConfirmed : gs.hostDiscardConfirmed;
                if (myConfirmed && !oppConfirmed) {
                  return 'Waiting for opponent to discard…';
                }
                return 'Choose 2 cards for the crib.';
              }(),
            CribbagePhase.pegging =>
              gs.isPlayerPegging == amIHost ? 'Your turn to peg.' : "Opponent's turn to peg.",
            CribbagePhase.counting =>
              amIHost ? gs.message : 'Round complete — see scores above.',
            CribbagePhase.gameOver => gs.message,
          };
    return Column(children: [
      _ScoreBar(gs: gs, amIHost: amIHost),
      _MsgBar(displayMessage),
      const SizedBox(height: 6),
      Expanded(
        child: _PhaseContent(
          gs: gs,
          notifier: notifier,
          amIHost: amIHost,
          countingMessage: amIHost ? gs.message : 'Round complete — see scores above.',
        ),
      ),
    ]);
  }
}

class _ScoreBar extends StatelessWidget {
  final CribbageState gs;
  final bool amIHost;
  const _ScoreBar({required this.gs, required this.amIHost});

  @override
  Widget build(BuildContext context) {
    final opponentWord = gs.isMultiplayer ? 'Opponent' : 'AI';
    final myScore = amIHost ? gs.playerScore : gs.aiScore;
    final oppScore = amIHost ? gs.aiScore : gs.playerScore;
    final myIsDealer = amIHost ? gs.isPlayerDealer : !gs.isPlayerDealer;
    return Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
            color: _kOverlay, borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _score('You', myScore, myIsDealer),
          _pegIcon(gs),
          _score(opponentWord, oppScore, !myIsDealer),
        ]),
      );
  }

  Widget _score(String label, int score, bool isDealer) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label + (isDealer ? ' ◆' : ''),
              style: TextStyle(
                  color: isDealer ? Colors.amber : _kGameTextMuted,
                  fontSize: 11)),
          Text('$score / 121',
              style: const TextStyle(
                  color: _kGameText, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      );

  Widget _pegIcon(CribbageState gs) {
    if (gs.starter == null) return const SizedBox(width: 40);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('Starter', style: TextStyle(color: _kGameTextMuted, fontSize: 10)),
      _CardChip(gs.starter!),
    ]);
  }
}

class _MsgBar extends StatelessWidget {
  final String msg;
  const _MsgBar(this.msg);
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration:
            BoxDecoration(color: _kOverlay, borderRadius: BorderRadius.circular(8)),
        child: Text(msg,
            style: const TextStyle(color: _kGameText, fontSize: 12),
            textAlign: TextAlign.center),
      );
}

// ── Phase routing ─────────────────────────────────────────────────────────────

class _PhaseContent extends StatelessWidget {
  final CribbageState gs;
  final CribbageNotifier notifier;
  final bool amIHost;
  final String countingMessage;
  const _PhaseContent({
    required this.gs,
    required this.notifier,
    required this.amIHost,
    required this.countingMessage,
  });

  @override
  Widget build(BuildContext context) {
    return switch (gs.phase) {
      CribbagePhase.discarding =>
        _DiscardPhase(gs: gs, notifier: notifier, amIHost: amIHost),
      CribbagePhase.pegging =>
        _PeggingPhase(gs: gs, notifier: notifier, amIHost: amIHost),
      CribbagePhase.counting => _CountingPhase(
          gs: gs, notifier: notifier, amIHost: amIHost, message: countingMessage),
      CribbagePhase.gameOver => const SizedBox.shrink(),
    };
  }
}

// ── Discard phase ─────────────────────────────────────────────────────────────

class _DiscardPhase extends ConsumerWidget {
  final CribbageState gs;
  final CribbageNotifier notifier;
  final bool amIHost;
  const _DiscardPhase({required this.gs, required this.notifier, required this.amIHost});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myFullHand = amIHost ? gs.playerFullHand : gs.aiFullHand;
    final mySelected = amIHost ? gs.selectedDiscard : gs.selectedAiDiscard;
    final myConfirmed = amIHost ? gs.hostDiscardConfirmed : gs.guestDiscardConfirmed;

    if (myConfirmed) {
      return const Center(
        child: Text('Discard confirmed — waiting for opponent…',
            style: TextStyle(color: _kGameTextMuted, fontSize: 13)),
      );
    }

    return Column(children: [
      const Spacer(),
      const Text('Your Hand — select 2 to discard',
          style: TextStyle(color: _kGameTextMuted, fontSize: 12)),
      const SizedBox(height: 8),
      _CardRow(
        cards: myFullHand,
        selectedIndices: mySelected,
        onTap: (idx) =>
            _sendOrApplyMine(ref, notifier, amIHost, 'toggleDiscard', {'idx': idx}),
      ),
      const SizedBox(height: 24),
      FilledButton.icon(
        onPressed: mySelected.length == 2
            ? () => _sendOrApplyMine(ref, notifier, amIHost, 'confirmDiscard', {})
            : null,
        icon: const Icon(Icons.check),
        label: Text(mySelected.length == 2
            ? 'Confirm Discard'
            : 'Select ${2 - mySelected.length} more'),
      ),
      const Spacer(),
    ]);
  }
}

// ── Pegging phase ─────────────────────────────────────────────────────────────

class _PeggingPhase extends ConsumerWidget {
  final CribbageState gs;
  final CribbageNotifier notifier;
  final bool amIHost;
  const _PeggingPhase({required this.gs, required this.notifier, required this.amIHost});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opponentWord = gs.isMultiplayer ? 'Opponent' : 'AI';
    final myPegging = amIHost ? gs.playerPegging : gs.aiPegging;
    final oppPegging = amIHost ? gs.aiPegging : gs.playerPegging;
    final myTurn = gs.isPlayerPegging == amIHost;

    return Column(children: [
      // Peg table
      Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: _kOverlay, borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Table  ', style: TextStyle(color: _kGameTextMuted, fontSize: 11)),
            Text('Count: ${gs.pegCount}',
                style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 6),
          gs.pegTable.isEmpty
              ? const Text('No cards played yet',
                  style: TextStyle(color: _kGameTextMuted, fontSize: 12))
              : Wrap(
                  spacing: 4,
                  children: gs.pegTable.map((c) => _CardChip(c)).toList(),
                ),
        ]),
      ),
      const SizedBox(height: 12),
      // Opponent hand (face-down)
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: _kOverlay, borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Text('$opponentWord hand: ',
              style: const TextStyle(color: _kGameTextMuted, fontSize: 12)),
          ...List.generate(
            oppPegging.length,
            (_) => Container(
              width: 28, height: 40,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white24),
              ),
            ),
          ),
          if (oppPegging.isEmpty)
            const Text('Done pegging',
                style: TextStyle(color: _kGameTextMuted, fontSize: 12)),
        ]),
      ),
      const Spacer(),
      // My pegging hand
      if (myTurn) ...[
        Builder(builder: (context) {
          final canPlay = myPegging.any((c) => faceValue(c) + gs.pegCount <= 31);
          return Column(children: [
            Text(
              canPlay ? 'Your hand — tap to play' : 'No legal play',
              style: const TextStyle(color: _kGameTextMuted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            _CardRow(
              cards: myPegging,
              selectedIndices: const {},
              onTap: (idx) =>
                  _sendOrApply(ref, notifier, 'playPegCard', {'handIdx': idx}),
              dimUnplayable: true,
              pegCount: gs.pegCount,
            ),
            if (!canPlay) ...[
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _sendOrApply(ref, notifier, 'sayGo'),
                child: const Text('Go'),
              ),
            ],
          ]);
        }),
      ] else if (myPegging.isNotEmpty) ...[
        Text('Your hand (waiting for $opponentWord)',
            style: const TextStyle(color: _kGameTextMuted, fontSize: 12)),
        const SizedBox(height: 8),
        _CardRow(
          cards: myPegging,
          selectedIndices: const {},
          onTap: null,
        ),
      ] else
        const Text('You have pegged all cards',
            style: TextStyle(color: _kGameTextMuted, fontSize: 12)),
      const SizedBox(height: 16),
    ]);
  }
}

// ── Counting phase ────────────────────────────────────────────────────────────

class _CountingPhase extends ConsumerWidget {
  final CribbageState gs;
  final CribbageNotifier notifier;
  final bool amIHost;
  final String message;
  const _CountingPhase({
    required this.gs,
    required this.notifier,
    required this.amIHost,
    required this.message,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opponentWord = gs.isMultiplayer ? 'Opponent' : 'AI';
    final myHand = amIHost ? gs.playerHand : gs.aiHand;
    final oppHand = amIHost ? gs.aiHand : gs.playerHand;
    final cribIsMine = gs.isPlayerDealer == amIHost;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: _kOverlay, borderRadius: BorderRadius.circular(16)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Round Complete',
                style: TextStyle(
                    color: _kGameText,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (gs.starter != null)
              _HandDisplay('Starter', [gs.starter!]),
            const SizedBox(height: 12),
            _HandDisplay('Your Hand', myHand),
            const SizedBox(height: 8),
            _HandDisplay('$opponentWord Hand', oppHand),
            const SizedBox(height: 8),
            _HandDisplay("Crib (${cribIsMine ? 'Yours' : "$opponentWord's"})", gs.crib),
            const SizedBox(height: 16),
            Text(message,
                style: const TextStyle(color: Colors.amber, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _sendOrApply(ref, notifier, 'nextRound'),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next Round'),
            ),
          ]),
        ),
      ),
    );
  }
}

class _HandDisplay extends StatelessWidget {
  final String label;
  final List<int> cards;
  const _HandDisplay(this.label, this.cards);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(color: _kGameTextMuted, fontSize: 11)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            children: cards.map((c) => _CardChip(c)).toList(),
          ),
        ],
      );
}

// ── Card widgets ──────────────────────────────────────────────────────────────

class _CardRow extends StatelessWidget {
  final List<int> cards;
  final Set<int> selectedIndices;
  final void Function(int)? onTap;
  final bool dimUnplayable;
  final int pegCount;

  const _CardRow({
    required this.cards,
    required this.selectedIndices,
    required this.onTap,
    this.dimUnplayable = false,
    this.pegCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cards.length,
        itemBuilder: (context, i) {
          final isSelected = selectedIndices.contains(i);
          final unplayable = dimUnplayable && faceValue(cards[i]) + pegCount > 31;
          return GestureDetector(
            onTap: onTap != null && !unplayable ? () => onTap!(i) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              transform: isSelected
                  ? Matrix4.translationValues(0, -12, 0)
                  : Matrix4.identity(),
              child: Opacity(
                opacity: unplayable ? 0.35 : 1.0,
                child: _CardWidget(card: cards[i], selected: isSelected),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CardWidget extends StatelessWidget {
  final int card;
  final bool selected;
  const _CardWidget({required this.card, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final label = cardLabel(card);
    final textColor = isRed(card) ? _kCardRed : _kCardBlack;
    return Container(
      width: 52,
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: selected ? _kSelected : Colors.white38,
            width: selected ? 2.5 : 1),
        boxShadow: selected
            ? [BoxShadow(color: _kSelected.withValues(alpha: 0.5), blurRadius: 6)]
            : null,
      ),
      child: Center(
        child: Text(label,
            style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _CardChip extends StatelessWidget {
  final int card;
  const _CardChip(this.card);

  @override
  Widget build(BuildContext context) {
    final textColor = isRed(card) ? _kCardRed : _kCardBlack;
    return Container(
      width: 38,
      height: 28,
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white38),
      ),
      child: Center(
        child: Text(cardLabel(card),
            style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ── Game over ─────────────────────────────────────────────────────────────────

class _GameOver extends StatelessWidget {
  final CribbageState gs;
  final bool amIHost;
  final VoidCallback onNew;
  const _GameOver({required this.gs, required this.amIHost, required this.onNew});

  @override
  Widget build(BuildContext context) {
    // gs.winner is absolute ('You' = host's role won, 'AI' = guest/AI role
    // won) regardless of which screen is looking at it — translate through
    // the viewer's own role the same way as checkers/backgammon's overlay,
    // or a host win would show "You Win!" on the losing guest's screen too.
    //
    // A disconnect (see _handleDisconnect/_handleHostDisconnect in logic.dart)
    // also sets phase: gameOver but leaves winner null, since nobody actually
    // won — (gs.winner == 'You') == amIHost would then evaluate true for
    // whichever side happens to match that comparison, showing a nonsensical
    // "You Win!" on an ended-by-disconnect game (found live). Treat a null
    // winner as its own case rather than feeding it through the win/lose
    // framing at all.
    final hasWinner = gs.winner != null;
    final didIWin = hasWinner && (gs.winner == 'You') == amIHost;
    final opponentWord = gs.isMultiplayer ? 'Opponent' : 'AI';
    final myScore = amIHost ? gs.playerScore : gs.aiScore;
    final oppScore = amIHost ? gs.aiScore : gs.playerScore;
    return Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
              color: _kOverlay, borderRadius: BorderRadius.circular(16)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              !hasWinner
                  ? Icons.link_off
                  : (didIWin ? Icons.emoji_events : Icons.sentiment_dissatisfied),
              size: 64,
              color: !hasWinner
                  ? _kGameTextMuted
                  : (didIWin ? Colors.amber : Colors.redAccent),
            ),
            const SizedBox(height: 16),
            Text(
              !hasWinner ? 'Game Ended' : (didIWin ? 'You Win!' : '$opponentWord Wins!'),
              style: const TextStyle(
                  color: _kGameText,
                  fontSize: 26,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              !hasWinner ? gs.message : 'You: $myScore  –  $opponentWord: $oppScore',
              style: const TextStyle(color: _kGameTextMuted, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onNew,
              icon: const Icon(Icons.refresh),
              label: const Text('Play Again'),
            ),
          ]),
        ),
      );
  }
}
