import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/lan/lan_providers.dart';
import '../../components/game_help_screen.dart';
import '../../components/game_rules_data.dart';
import 'logic.dart';

void _sendOrApply(WidgetRef ref, PokerNotifier notifier, String action,
    [Map<String, dynamic> data = const {}]) {
  if (notifier.isClientMode) {
    ref.read(gameLanServiceProvider).sendMove(action, data);
  } else {
    switch (action) {
      case 'bet':
        notifier.playerBet();
      case 'check':
        notifier.playerCheck();
      case 'call':
        notifier.playerCall();
      case 'fold':
        notifier.playerFold();
      case 'toggleDiscard':
        notifier.toggleDiscard(data['idx'] as int);
      case 'confirmDraw':
        notifier.confirmDraw();
      case 'toggleAiDiscard':
        notifier.toggleAiDiscard(data['idx'] as int);
      case 'confirmAiDraw':
        notifier.confirmAiDraw();
      case 'nextRound':
        notifier.nextRound();
    }
  }
}

/// Guest maps "my" draw actions onto the ai-role methods (same shape as cribbage).
void _sendOrApplyMine(
  WidgetRef ref,
  PokerNotifier notifier,
  bool amIHost,
  String action, [
  Map<String, dynamic> data = const {},
]) {
  final effective = amIHost
      ? action
      : switch (action) {
          'toggleDiscard' => 'toggleAiDiscard',
          'confirmDraw' => 'confirmAiDraw',
          _ => action,
        };
  _sendOrApply(ref, notifier, effective, data);
}

const _kOverlay = Color(0xBB000000);
const _kGameText = Colors.white;
const _kGameTextMuted = Color(0xFFb0bec5);
const _kSelected = Color(0xFFFFD600);
const _kCardRed = Color(0xFFD32F2F);
const _kCardBlack = Color(0xFF212121);

class PokerScreen extends ConsumerWidget {
  const PokerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gs = ref.watch(pokerStateProvider);
    final notifier = ref.read(pokerStateProvider.notifier);
    final amIHost = !notifier.isClientMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(children: [
          Image.asset('assets/games/games/poker/icon.jpg', height: 36,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.casino, size: 36, color: Colors.white)),
          const SizedBox(width: 10),
          const Text('5-Card Draw Poker',
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
            onPressed: () => showGameHelp(context, pokerHelp),
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
          child: gs.phase == PokerPhase.gameOver
              ? _GameOverOverlay(
                  gs: gs, amIHost: amIHost, onNewGame: notifier.newGame)
              : _GameContent(gs: gs, notifier: notifier, amIHost: amIHost),
        ),
      ),
    );
  }
}

class _GameContent extends ConsumerWidget {
  final PokerState gs;
  final PokerNotifier notifier;
  final bool amIHost;
  const _GameContent({
    required this.gs,
    required this.notifier,
    required this.amIHost,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opponentWord = gs.isMultiplayer ? 'Opponent' : 'AI';
    final myHand = amIHost ? gs.playerHand : gs.aiHand;
    final oppHand = amIHost ? gs.aiHand : gs.playerHand;
    final myChips = amIHost ? gs.playerChips : gs.aiChips;
    final oppChips = amIHost ? gs.aiChips : gs.playerChips;
    final mySelected = amIHost ? gs.selectedDiscard : gs.selectedAiDiscard;
    final myDrawConfirmed =
        amIHost ? gs.hostDrawConfirmed : gs.guestDrawConfirmed;
    final myTurn = gs.isPlayerTurn == amIHost;
    final revealHands = gs.phase == PokerPhase.showdown ||
        gs.phase == PokerPhase.roundOver;

    final displayMessage = _displayMessage(
      gs: gs,
      amIHost: amIHost,
      myTurn: myTurn,
      opponentWord: opponentWord,
      myDrawConfirmed: myDrawConfirmed,
    );

    return Column(children: [
      _ChipsBar(
        myChips: myChips,
        oppChips: oppChips,
        pot: gs.pot,
        opponentWord: opponentWord,
      ),
      const SizedBox(height: 8),
      // Opponent hand — face-down until showdown (hidden-hand design)
      _HandRow(
        label: '$opponentWord  (\$$oppChips)',
        hand: oppHand,
        faceDown: !revealHands,
        selectedDiscard: const {},
      ),
      const SizedBox(height: 8),
      _PotDisplay(pot: gs.pot),
      const SizedBox(height: 8),
      // My hand
      _HandRow(
        label: 'You  (\$$myChips)',
        hand: myHand,
        faceDown: false,
        selectedDiscard: mySelected,
        onCardTap: gs.phase == PokerPhase.draw && !myDrawConfirmed
            ? (i) => _sendOrApplyMine(
                ref, notifier, amIHost, 'toggleDiscard', {'idx': i})
            : null,
      ),
      const SizedBox(height: 8),
      _MessageBox(msg: displayMessage),
      const SizedBox(height: 8),
      _ActionButtons(
        gs: gs,
        notifier: notifier,
        amIHost: amIHost,
        myTurn: myTurn,
        myDrawConfirmed: myDrawConfirmed,
        mySelectedCount: mySelected.length,
      ),
      const SizedBox(height: 8),
    ]);
  }

  String _displayMessage({
    required PokerState gs,
    required bool amIHost,
    required bool myTurn,
    required String opponentWord,
    required bool myDrawConfirmed,
  }) {
    if (!gs.isMultiplayer || amIHost) return gs.message;

    // Guest: host-centric strings read backwards — use neutral/local copy.
    switch (gs.phase) {
      case PokerPhase.betting1:
      case PokerPhase.betting2:
        final myBet = amIHost ? gs.playerCurrentBet : gs.aiCurrentBet;
        final oppBet = amIHost ? gs.aiCurrentBet : gs.playerCurrentBet;
        if (!myTurn) return "Opponent's action…";
        if (oppBet > myBet) return 'Opponent bet. Call or fold?';
        return 'Your action — bet, check, or fold.';
      case PokerPhase.draw:
        if (myDrawConfirmed) return 'Waiting for opponent to discard…';
        return 'Select cards to discard.';
      case PokerPhase.showdown:
        return 'Showdown…';
      case PokerPhase.roundOver:
        final o = gs.outcome;
        if (o == null) return gs.message;
        if (o.startsWith('You win') || o == 'You win') {
          return 'You lose this round.';
        }
        if (o.startsWith('AI wins') ||
            o.startsWith('Opponent wins') ||
            o == 'AI wins') {
          return 'You win this round!';
        }
        if (o.startsWith('Tie')) return 'Tie! Split pot.';
        return o;
      case PokerPhase.gameOver:
        // Disconnect / chip-out — translate win/lose for guest.
        final o = gs.outcome;
        if (o == null) return gs.message; // disconnect: neutral message is fine
        if (o == 'You win' || o.startsWith('You win')) {
          return 'You\'re out of chips. Opponent wins.';
        }
        if (o == 'AI wins' || o.startsWith('AI') || o.startsWith('Opponent')) {
          return 'Opponent is out of chips. You win!';
        }
        return gs.message;
    }
  }
}

class _ChipsBar extends StatelessWidget {
  final int myChips;
  final int oppChips;
  final int pot;
  final String opponentWord;
  const _ChipsBar({
    required this.myChips,
    required this.oppChips,
    required this.pot,
    required this.opponentWord,
  });
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
            color: _kOverlay, borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('You: \$$myChips',
              style: const TextStyle(
                  color: _kGameText, fontWeight: FontWeight.bold)),
          Text('Pot: \$$pot',
              style: const TextStyle(
                  color: Colors.amber, fontWeight: FontWeight.bold)),
          Text('$opponentWord: \$$oppChips',
              style: const TextStyle(color: _kGameTextMuted)),
        ]),
      );
}

class _PotDisplay extends StatelessWidget {
  final int pot;
  const _PotDisplay({required this.pot});
  @override
  Widget build(BuildContext context) => Text(
        'POT: \$$pot',
        style: const TextStyle(
            color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold),
      );
}

class _HandRow extends StatelessWidget {
  final String label;
  final List<int> hand;
  final bool faceDown;
  final Set<int> selectedDiscard;
  final void Function(int)? onCardTap;
  const _HandRow({
    required this.label,
    required this.hand,
    required this.faceDown,
    required this.selectedDiscard,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label, style: const TextStyle(color: _kGameTextMuted, fontSize: 13)),
      const SizedBox(height: 4),
      if (hand.isEmpty)
        const SizedBox(height: 80)
      else
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(hand.length, (i) {
            final selected = selectedDiscard.contains(i);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: onCardTap != null ? () => onCardTap!(i) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  transform: selected
                      ? Matrix4.translationValues(0, -12, 0)
                      : Matrix4.identity(),
                  child: faceDown
                      ? _CardBack()
                      : _CardFace(card: hand[i], discarded: selected),
                ),
              ),
            );
          }),
        ),
      if (onCardTap != null)
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text('Tap cards to discard',
              style: TextStyle(color: _kGameTextMuted, fontSize: 11)),
        ),
    ]);
  }
}

class _CardBack extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 52,
        height: 76,
        decoration: BoxDecoration(
          color: const Color(0xFF1A237E),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white24),
        ),
        child: const Center(
          child: Text('🂠', style: TextStyle(fontSize: 24)),
        ),
      );
}

class _CardFace extends StatelessWidget {
  final int card;
  final bool discarded;
  const _CardFace({required this.card, this.discarded = false});

  @override
  Widget build(BuildContext context) {
    final red = isRed(card);
    final color = red ? _kCardRed : _kCardBlack;
    return Container(
      width: 52,
      height: 76,
      decoration: BoxDecoration(
        color: discarded ? Colors.grey.shade300 : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: discarded ? _kSelected : Colors.black26,
            width: discarded ? 2 : 1),
        boxShadow: [
          BoxShadow(
              color: discarded
                  ? _kSelected.withValues(alpha: 0.5)
                  : Colors.black38,
              blurRadius: 4)
        ],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 3, 0, 0),
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(cardLabel(card),
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    height: 1.1)),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(_suitSymbol(card),
                style: TextStyle(color: color, fontSize: 22)),
          ),
        ),
      ]),
    );
  }

  String _suitSymbol(int c) => const ['♣', '♦', '♥', '♠'][suitOf(c)];
}

class _MessageBox extends StatelessWidget {
  final String msg;
  const _MessageBox({required this.msg});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
            color: _kOverlay, borderRadius: BorderRadius.circular(10)),
        child: Text(msg,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _kGameText, fontSize: 14)),
      );
}

class _ActionButtons extends ConsumerWidget {
  final PokerState gs;
  final PokerNotifier notifier;
  final bool amIHost;
  final bool myTurn;
  final bool myDrawConfirmed;
  final int mySelectedCount;
  const _ActionButtons({
    required this.gs,
    required this.notifier,
    required this.amIHost,
    required this.myTurn,
    required this.myDrawConfirmed,
    required this.mySelectedCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (gs.phase) {
      case PokerPhase.betting1:
      case PokerPhase.betting2:
        if (!myTurn) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: Text("Opponent's action…",
                style: TextStyle(color: _kGameTextMuted)),
          );
        }
        final myBet = amIHost ? gs.playerCurrentBet : gs.aiCurrentBet;
        final oppBet = amIHost ? gs.aiCurrentBet : gs.playerCurrentBet;
        final canCall = oppBet > myBet;
        return _ButtonRow(buttons: [
          if (canCall)
            _Btn('Call', () => _sendOrApply(ref, notifier, 'call'),
                color: Colors.blue)
          else
            _Btn('Check', () => _sendOrApply(ref, notifier, 'check'),
                color: Colors.blue),
          if (!canCall)
            _Btn('Bet \$20', () => _sendOrApply(ref, notifier, 'bet'),
                color: Colors.green),
          _Btn('Fold', () => _sendOrApply(ref, notifier, 'fold'),
              color: Colors.red.shade700),
        ]);

      case PokerPhase.draw:
        if (myDrawConfirmed) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Waiting for opponent…',
                style: TextStyle(color: _kGameTextMuted)),
          );
        }
        return _ButtonRow(buttons: [
          _Btn(
            'Draw ($mySelectedCount discarded)',
            () => _sendOrApplyMine(ref, notifier, amIHost, 'confirmDraw'),
            color: Colors.green,
          ),
        ]);

      case PokerPhase.roundOver:
        return _ButtonRow(buttons: [
          _Btn('Next Round', () => _sendOrApply(ref, notifier, 'nextRound'),
              color: Colors.blue),
        ]);

      case PokerPhase.showdown:
        return const SizedBox.shrink();

      case PokerPhase.gameOver:
        return _ButtonRow(buttons: [
          _Btn('New Game', notifier.newGame, color: Colors.green),
        ]);
    }
  }
}

class _ButtonRow extends StatelessWidget {
  final List<Widget> buttons;
  const _ButtonRow({required this.buttons});
  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: buttons
            .expand((b) => [b, const SizedBox(width: 12)])
            .take(buttons.length * 2 - 1)
            .toList(),
      );
}

class _Btn extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color color;
  const _Btn(this.label, this.onPressed, {required this.color});
  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(backgroundColor: color),
        child: Text(label, style: const TextStyle(fontSize: 13)),
      );
}

class _GameOverOverlay extends StatelessWidget {
  final PokerState gs;
  final bool amIHost;
  final VoidCallback onNewGame;
  const _GameOverOverlay({
    required this.gs,
    required this.amIHost,
    required this.onNewGame,
  });
  @override
  Widget build(BuildContext context) {
    // Null outcome = disconnect / ended without a chip winner — do not
    // map through win/lose (same class of bug found live in cribbage).
    final o = gs.outcome;
    final hasWinner = o != null;
    final hostWon = hasWinner &&
        (o == 'You win' || o.startsWith('You win'));
    final didIWin = hasWinner && (hostWon == amIHost);
    final opponentWord = gs.isMultiplayer ? 'Opponent' : 'AI';
    final title = !hasWinner
        ? 'Game Ended'
        : (didIWin ? 'You Win!' : '$opponentWord Wins');

    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
            color: _kOverlay, borderRadius: BorderRadius.circular(16)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            hasWinner
                ? (didIWin ? Icons.emoji_events : Icons.casino)
                : Icons.link_off,
            size: 64,
            color: Colors.amber,
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  color: _kGameText,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            !hasWinner
                ? gs.message
                : (didIWin
                    ? 'Congratulations!'
                    : '$opponentWord took the last of your chips.'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: _kGameTextMuted),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onNewGame,
            icon: const Icon(Icons.refresh),
            label: const Text('New Game'),
          ),
        ]),
      ),
    );
  }
}
