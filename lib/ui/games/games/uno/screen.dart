import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/lan/lan_providers.dart';
import '../../components/game_help_screen.dart';
import '../../components/game_rules_data.dart';
import 'logic.dart';

void _sendOrApply(WidgetRef ref, UnoNotifier notifier, String action,
    [Map<String, dynamic> data = const {}]) {
  if (notifier.isClientMode) {
    ref.read(gameLanServiceProvider).sendMove(action, data);
  } else {
    switch (action) {
      case 'selectCard':
        notifier.selectCard(data['index'] as int);
      case 'playSelected':
        notifier.playSelected();
      case 'chooseColor':
        notifier.chooseColor(UnoColor.values.byName(data['color'] as String));
      case 'drawCard':
        notifier.drawCard();
    }
  }
}

const _kOverlay = Color(0xBB000000);
const _kGameText = Colors.white;
const _kGameTextMuted = Color(0xFFb0bec5);

Color _unoColor(UnoColor c) => switch (c) {
      UnoColor.red => const Color(0xFFE53935),
      UnoColor.yellow => const Color(0xFFFDD835),
      UnoColor.green => const Color(0xFF43A047),
      UnoColor.blue => const Color(0xFF1E88E5),
      UnoColor.wild => const Color(0xFF6A1B9A),
    };

class UnoScreen extends ConsumerWidget {
  const UnoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gs = ref.watch(unoStateProvider);
    final notifier = ref.read(unoStateProvider.notifier);
    final amIHost = !notifier.isClientMode;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(children: [
          Image.asset('assets/games/games/uno/icon.jpg', height: 36,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.style, size: 36, color: Colors.white)),
          const SizedBox(width: 10),
          const Text('Uno',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            onPressed: () => showGameHelp(context, unoHelp),
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
          child: gs.phase == UnoPhase.gameOver
              ? _GameOverOverlay(gs: gs, amIHost: amIHost, onNewGame: notifier.newGame)
              : gs.phase == UnoPhase.choosingColor
                  ? (gs.isPlayerTurn == amIHost
                      ? _ColorPicker(notifier: notifier)
                      : const _WaitingForColorChoice())
                  : _GameTable(gs: gs, notifier: notifier, amIHost: amIHost),
        ),
      ),
    );
  }
}

// ── Color chooser ─────────────────────────────────────────────────────────────

class _WaitingForColorChoice extends StatelessWidget {
  const _WaitingForColorChoice();

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: _kOverlay, borderRadius: BorderRadius.circular(16)),
          child: const Text('Opponent is choosing a color…',
              style: TextStyle(color: _kGameText, fontSize: 16)),
        ),
      );
}

class _ColorPicker extends ConsumerWidget {
  final UnoNotifier notifier;
  const _ColorPicker({required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: _kOverlay, borderRadius: BorderRadius.circular(16)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Choose a color',
                style: TextStyle(
                    color: _kGameText,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                UnoColor.red,
                UnoColor.yellow,
                UnoColor.green,
                UnoColor.blue,
              ]
                  .map((c) => GestureDetector(
                        onTap: () => _sendOrApply(
                            ref, notifier, 'chooseColor', {'color': c.name}),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _unoColor(c),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ]),
        ),
      );
}

// ── Main game table ───────────────────────────────────────────────────────────

class _GameTable extends ConsumerWidget {
  final UnoState gs;
  final UnoNotifier notifier;
  final bool amIHost;
  const _GameTable({required this.gs, required this.notifier, required this.amIHost});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opponentWord = gs.isMultiplayer ? 'Opponent' : 'AI';
    final myHand = amIHost ? gs.playerHand : gs.aiHand;
    final oppHand = amIHost ? gs.aiHand : gs.playerHand;
    final myTurn = gs.isPlayerTurn == amIHost;
    // Broadcast messages are written from the acting role's perspective —
    // after a guest action the raw string often says "Opponent's turn" while
    // isPlayerTurn has already flipped to the host (found live 2026-07-30:
    // host saw "Red chosen. Opponent's turn." on their own turn). For
    // multiplayer always derive a local turn label from myTurn instead of
    // trusting the host-centric string on either side.
    final displayMessage = !gs.isMultiplayer
        ? gs.message
        : (myTurn ? 'Your turn! Play a card or draw.' : "Opponent's turn…");
    return Column(children: [
      // Opponent hand (face-down)
      _HandArea(
        label: '$opponentWord — ${oppHand.length} cards',
        cards: oppHand,
        faceDown: true,
        selectedIndex: null,
        onTap: null,
      ),
      const SizedBox(height: 8),
      // Center: discard + deck + color indicator
      _CenterRow(gs: gs, notifier: notifier, myTurn: myTurn),
      const SizedBox(height: 8),
      // Message
      _MsgBox(displayMessage),
      const SizedBox(height: 8),
      // My hand
      Expanded(
        child: _HandArea(
          label: 'You — ${myHand.length} cards',
          cards: myHand,
          faceDown: false,
          selectedIndex: myTurn ? gs.selectedCardIndex : null,
          onTap: myTurn
              ? (i) => _sendOrApply(ref, notifier, 'selectCard', {'index': i})
              : null,
          playable: myTurn,
          currentColor: gs.currentColor,
          currentValue: gs.currentValue,
        ),
      ),
      // Action row
      if (myTurn && gs.phase == UnoPhase.playing)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (gs.selectedCardIndex != null)
                FilledButton.icon(
                  onPressed: () => _sendOrApply(ref, notifier, 'playSelected'),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play Card'),
                  style: FilledButton.styleFrom(
                      backgroundColor: _unoColor(gs.currentColor)),
                ),
              if (gs.selectedCardIndex != null) const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _sendOrApply(ref, notifier, 'drawCard'),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Draw',
                    style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54)),
              ),
            ],
          ),
        ),
    ]);
  }
}

class _CenterRow extends ConsumerWidget {
  final UnoState gs;
  final UnoNotifier notifier;
  final bool myTurn;
  const _CenterRow({required this.gs, required this.notifier, required this.myTurn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topCard = gs.discardPile.isNotEmpty ? gs.discardPile.last : null;
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      // Deck
      GestureDetector(
        onTap: myTurn ? () => _sendOrApply(ref, notifier, 'drawCard') : null,
        child: Container(
          width: 60,
          height: 88,
          decoration: BoxDecoration(
            color: const Color(0xFF1A237E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white38),
          ),
          child: Center(
            child: Text('${gs.deck.length}',
                style: const TextStyle(color: Colors.white54, fontSize: 18)),
          ),
        ),
      ),
      const SizedBox(width: 24),
      // Current color indicator + discard
      Column(children: [
        Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: _unoColor(gs.currentColor),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
        if (topCard != null) _UnoCardWidget(card: topCard, size: 60),
      ]),
    ]);
  }
}

class _HandArea extends StatelessWidget {
  final String label;
  final List<UnoCard> cards;
  final bool faceDown;
  final int? selectedIndex;
  final void Function(int)? onTap;
  final bool playable;
  final UnoColor? currentColor;
  final UnoValue? currentValue;

  const _HandArea({
    required this.label,
    required this.cards,
    required this.faceDown,
    required this.selectedIndex,
    required this.onTap,
    this.playable = false,
    this.currentColor,
    this.currentValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(label,
            style: const TextStyle(color: _kGameTextMuted, fontSize: 12)),
      ),
      const SizedBox(height: 4),
      SizedBox(
        height: 100,
        child: cards.isEmpty
            ? const Center(
                child: Text('No cards',
                    style: TextStyle(color: _kGameTextMuted)))
            : ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: cards.length,
                itemBuilder: (context, i) {
                  final isSelected = selectedIndex == i;
                  final isPlayable = playable &&
                      currentColor != null &&
                      currentValue != null &&
                      cards[i].canPlayOn(currentColor!, currentValue!);
                  return GestureDetector(
                    onTap: onTap != null ? () => onTap!(i) : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      transform: isSelected
                          ? Matrix4.translationValues(0, -14, 0)
                          : Matrix4.identity(),
                      child: faceDown
                          ? _CardBack()
                          : _UnoCardWidget(
                              card: cards[i],
                              size: 60,
                              dimmed: playable && !isPlayable,
                              selected: isSelected,
                            ),
                    ),
                  );
                },
              ),
      ),
    ]);
  }
}

class _MsgBox extends StatelessWidget {
  final String msg;
  const _MsgBox(this.msg);
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: _kOverlay, borderRadius: BorderRadius.circular(8)),
        child: Text(msg,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _kGameText, fontSize: 13)),
      );
}

// ── Card widgets ──────────────────────────────────────────────────────────────

class _CardBack extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF1A237E),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white24),
        ),
      );
}

class _UnoCardWidget extends StatelessWidget {
  final UnoCard card;
  final double size;
  final bool dimmed;
  final bool selected;
  const _UnoCardWidget(
      {required this.card,
      required this.size,
      this.dimmed = false,
      this.selected = false});

  @override
  Widget build(BuildContext context) {
    final bg = _unoColor(card.color);
    final label = valueLabel[card.value]!;
    return Opacity(
      opacity: dimmed ? 0.4 : 1.0,
      child: Container(
        width: size * 0.73,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: selected ? Colors.yellow : Colors.white54,
              width: selected ? 2.5 : 1),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: Colors.yellow.withValues(alpha: 0.6),
                      blurRadius: 6)
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.22,
              fontWeight: FontWeight.bold,
              shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Game over ─────────────────────────────────────────────────────────────────

class _GameOverOverlay extends StatelessWidget {
  final UnoState gs;
  final bool amIHost;
  final VoidCallback onNewGame;
  const _GameOverOverlay({required this.gs, required this.amIHost, required this.onNewGame});

  @override
  Widget build(BuildContext context) {
    // gs.winner is absolute ('You' = host's role won, 'AI' = guest/AI role
    // won) regardless of which screen is looking at it — translate through
    // the viewer's own role, or a host win would show "You Win!" on the
    // losing guest's screen too (same bug class as checkers/backgammon/
    // cribbage's overlay).
    //
    // A disconnect (see _handleDisconnect/_handleHostDisconnect in
    // logic.dart) also sets phase: gameOver but leaves winner null since
    // nobody actually won — (winner == 'You') == amIHost would then evaluate
    // true for whichever side happens to match, showing a nonsensical
    // "You Win!" on an ended-by-disconnect game (found live in cribbage,
    // fixed proactively here). Treat a null winner as its own case.
    final hasWinner = gs.winner != null;
    final didIWin = hasWinner && (gs.winner == 'You') == amIHost;
    final opponentWord = gs.isMultiplayer ? 'Opponent' : 'AI';
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
            if (!hasWinner) ...[
              const SizedBox(height: 8),
              Text(gs.message,
                  style: const TextStyle(color: _kGameTextMuted, fontSize: 14),
                  textAlign: TextAlign.center),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onNewGame,
              icon: const Icon(Icons.refresh),
              label: const Text('Play Again'),
            ),
          ]),
        ),
      );
  }
}
