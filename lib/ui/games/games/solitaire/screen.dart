import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di.dart';
import '../../components/game_help_screen.dart';
import '../../components/game_rules_data.dart';
import 'logic.dart';

const _kOverlay = Color(0xBB000000);
const _kGameText = Colors.white;
const _kCardBack = Color(0xFF1A237E);
const _kFoundationEmpty = Color(0x44FFFFFF);
const _kSelectedBorder = Color(0xFFFFD600);

class SolitaireScreen extends ConsumerWidget {
  const SolitaireScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gs = ref.watch(solitaireProvider);
    final notifier = ref.read(solitaireProvider.notifier);
    final hintOn = ref.watch(hintModeProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(children: [
          Image.asset('assets/games/games/solitaire/icon.jpg', height: 36,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.style, size: 36, color: Colors.white)),
          const SizedBox(width: 10),
          const Text('Solitaire',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ]),
        actions: [
          IconButton(
            icon: Icon(
              Icons.lightbulb_outline,
              color: hintOn ? Colors.amber : Colors.white,
            ),
            tooltip: hintOn ? 'Hide hints' : 'Show hint',
            onPressed: () => ref.read(hintModeProvider.notifier).toggle(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Center(
              child: Text('${gs.moves}mv',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'New game',
            onPressed: notifier.newGame,
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            tooltip: 'How to play',
            onPressed: () => showGameHelp(context, solitaireHelp),
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
          child: gs.phase == SolitairePhase.won
              ? _WonOverlay(onNewGame: notifier.newGame)
              : _GameBoard(gs: gs, notifier: notifier, hintOn: hintOn),
        ),
      ),
    );
  }
}

class _WonOverlay extends StatelessWidget {
  final VoidCallback onNewGame;
  const _WonOverlay({required this.onNewGame});
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration:
              BoxDecoration(color: _kOverlay, borderRadius: BorderRadius.circular(16)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            const Text('You Win!',
                style: TextStyle(
                    color: _kGameText, fontSize: 28, fontWeight: FontWeight.bold)),
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

class _GameBoard extends StatelessWidget {
  final SolitaireState gs;
  final SolitaireNotifier notifier;
  final bool hintOn;
  const _GameBoard({required this.gs, required this.notifier, required this.hintOn});

  @override
  Widget build(BuildContext context) {
    final displayMsg = hintOn
        ? SolitaireNotifier.computeHint(gs)
        : gs.message.isNotEmpty
            ? gs.message
            : null;

    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final cardW = (w - 8 * 4) / 7;
      final cardH = cardW * 1.4;
      return Column(children: [
        // Top row: stock, waste, gap, 4 foundations
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(children: [
            _StockPile(gs: gs, notifier: notifier, w: cardW, h: cardH),
            const SizedBox(width: 4),
            _WastePile(gs: gs, notifier: notifier, w: cardW, h: cardH),
            const Spacer(),
            for (int i = 0; i < 4; i++) ...[
              _FoundationPile(
                  gs: gs, notifier: notifier, index: i, w: cardW, h: cardH),
              if (i < 3) const SizedBox(width: 4),
            ],
          ]),
        ),
        // Message / hint bar — fixed 3-line height so the tableau never jumps
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          height: 56,
          decoration:
              BoxDecoration(color: _kOverlay, borderRadius: BorderRadius.circular(8)),
          child: Center(
            child: Text(displayMsg ?? '',
                style: const TextStyle(color: _kGameText, fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
          ),
        ),
        // Tableau — scrollable so tall piles don't overflow
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(7, (i) {
                  return SizedBox(
                    width: cardW,
                    child: Padding(
                      padding: EdgeInsets.only(right: i < 6 ? 4 : 0),
                      child: _TableauPile(
                          gs: gs,
                          notifier: notifier,
                          index: i,
                          cardW: cardW - (i < 6 ? 4 : 0),
                          cardH: cardH),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ]);
    });
  }
}

class _StockPile extends StatelessWidget {
  final SolitaireState gs;
  final SolitaireNotifier notifier;
  final double w, h;
  const _StockPile(
      {required this.gs, required this.notifier, required this.w, required this.h});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: notifier.tapStock,
        child: _CardSlot(
          w: w, h: h,
          child: gs.stock.isEmpty
              ? Center(
                  child: Icon(Icons.refresh, color: Colors.white38, size: w * 0.5))
              : Container(
                  decoration: BoxDecoration(
                    color: _kCardBack,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Center(
                    child: Text('${gs.stock.length}',
                        style:
                            TextStyle(color: Colors.white54, fontSize: w * 0.25))),
                ),
        ),
      );
}

class _WastePile extends StatelessWidget {
  final SolitaireState gs;
  final SolitaireNotifier notifier;
  final double w, h;
  const _WastePile(
      {required this.gs, required this.notifier, required this.w, required this.h});
  @override
  Widget build(BuildContext context) {
    if (gs.waste.isEmpty) return _CardSlot(w: w, h: h, child: const SizedBox());
    final topCard = gs.waste.last;
    final isSel = gs.selection?.pile == PileType.waste;
    return GestureDetector(
      onTap: notifier.tapWaste,
      onDoubleTap: () => notifier.autoSendToFoundation(PileType.waste, 0),
      child: _CardFace(card: topCard, w: w, h: h, selected: isSel),
    );
  }
}

class _FoundationPile extends StatelessWidget {
  final SolitaireState gs;
  final SolitaireNotifier notifier;
  final int index;
  final double w, h;
  const _FoundationPile(
      {required this.gs,
      required this.notifier,
      required this.index,
      required this.w,
      required this.h});
  @override
  Widget build(BuildContext context) {
    final pile = gs.foundations[index];
    return GestureDetector(
      onTap: () => notifier.tapFoundation(index),
      child: pile.isEmpty
          ? _CardSlot(
              w: w,
              h: h,
              child: Center(
                child: Text(_suitSymbols[index],
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: w * 0.45,
                        fontWeight: FontWeight.bold)),
              ))
          : _CardFace(card: pile.last, w: w, h: h),
    );
  }

  static const _suitSymbols = ['♣', '♦', '♥', '♠'];
}

class _TableauPile extends StatelessWidget {
  final SolitaireState gs;
  final SolitaireNotifier notifier;
  final int index;
  final double cardW, cardH;
  const _TableauPile(
      {required this.gs,
      required this.notifier,
      required this.index,
      required this.cardW,
      required this.cardH});

  @override
  Widget build(BuildContext context) {
    final pile = gs.tableaux[index];
    final faceDown = gs.faceDownCounts[index];
    if (pile.isEmpty) {
      return GestureDetector(
        onTap: () => notifier.tapEmptyTableau(index),
        child: _CardSlot(w: cardW, h: cardH, child: const SizedBox()),
      );
    }
    const faceDownOffset = 12.0;
    const faceUpOffset = 22.0;
    double totalHeight = cardH;
    for (int i = 1; i < pile.length; i++) {
      totalHeight += i < faceDown ? faceDownOffset : faceUpOffset;
    }

    return SizedBox(
      width: cardW,
      height: totalHeight,
      child: Stack(
        children: List.generate(pile.length, (i) {
          double top = 0;
          for (int j = 0; j < i; j++) {
            top += j < faceDown ? faceDownOffset : faceUpOffset;
          }
          final isFaceDown = i < faceDown;
          final sel = gs.selection;
          final isSelected = sel != null &&
              sel.pile == PileType.tableau &&
              sel.pileIndex == index &&
              i >= sel.cardIndex;

          final isTopCard = i == pile.length - 1;
          return Positioned(
            top: top,
            child: GestureDetector(
              onTap: () => notifier.tapTableau(index, i),
              onDoubleTap: isTopCard
                  ? () => notifier.autoSendToFoundation(PileType.tableau, index)
                  : null,
              child: isFaceDown
                  ? _CardBack(w: cardW, h: cardH)
                  : _CardFace(
                      card: pile[i], w: cardW, h: cardH, selected: isSelected),
            ),
          );
        }),
      ),
    );
  }
}

// ── Reusable card widgets ─────────────────────────────────────────────────────

class _CardSlot extends StatelessWidget {
  final double w, h;
  final Widget child;
  const _CardSlot({required this.w, required this.h, required this.child});
  @override
  Widget build(BuildContext context) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: _kFoundationEmpty,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white24),
        ),
        child: child,
      );
}

class _CardBack extends StatelessWidget {
  final double w, h;
  const _CardBack({required this.w, required this.h});
  @override
  Widget build(BuildContext context) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: _kCardBack,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white24),
        ),
      );
}

class _CardFace extends StatelessWidget {
  final int card;
  final double w, h;
  final bool selected;
  const _CardFace(
      {required this.card,
      required this.w,
      required this.h,
      this.selected = false});

  @override
  Widget build(BuildContext context) {
    final red = isRed(card);
    final color = red ? Colors.red : const Color(0xFF212121);
    final label = cardLabel(card);
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: selected ? _kSelectedBorder : Colors.black26, width: selected ? 2 : 1),
        boxShadow: selected
            ? [BoxShadow(color: _kSelectedBorder.withValues(alpha: 0.6), blurRadius: 6)]
            : [const BoxShadow(color: Colors.black26, blurRadius: 2)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: w * 0.22,
                    fontWeight: FontWeight.bold,
                    height: 1)),
          ],
        ),
      ),
    );
  }
}
