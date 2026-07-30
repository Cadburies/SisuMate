import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/lan/lan_providers.dart';
import '../../components/game_help_screen.dart';
import '../../components/game_rules_data.dart';
import 'logic.dart';

const _kOverlay = Color(0xBB000000);
const _kGameText = Colors.white;
const _kGameTextMuted = Color(0xFFb0bec5);
const _kHeld = Color(0xFF2e8b57);
const _kAvail = Color(0xFF1565C0);

// ── Per-device identity + action dispatch (mirrors dudo/screen.dart) ─────────
//
// Yatzy's state is absolute (host = playerCard/isPlayerTurn:true, opponent =
// aiCard), not "whoever is looking at this screen" — so each device must
// derive "is it MY turn" / "which card is mine" from whether it's the client
// (guest) or not (host, or solo where there's no client at all).
bool _isMyTurn(YatzyState gs, bool amIHost) =>
    amIHost ? gs.isPlayerTurn : !gs.isPlayerTurn;

void _sendOrApply(
  WidgetRef ref,
  YatzyNotifier notifier,
  String action,
  Map<String, dynamic> data,
) {
  if (notifier.isClientMode) {
    ref.read(gameLanServiceProvider).sendMove(action, data);
  } else {
    switch (action) {
      case 'roll':
        notifier.roll();
      case 'toggleHold':
        notifier.toggleHold(data['index'] as int);
      case 'scoreCategory':
        notifier.scoreCategory(YatzyCategory.values.byName(data['category'] as String));
    }
  }
}

class YatzyScreen extends ConsumerWidget {
  const YatzyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gs = ref.watch(yatzyStateProvider);
    final notifier = ref.read(yatzyStateProvider.notifier);
    final amIHost = !notifier.isClientMode;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(children: [
          Image.asset('assets/games/games/yatzy/icon.jpg', height: 36,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.casino, size: 36, color: Colors.white)),
          const SizedBox(width: 10),
          const Text('Yatzy',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'New game',
            onPressed: () => ref.read(yatzyStateProvider.notifier).newGame(),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            tooltip: 'How to play',
            onPressed: () => showGameHelp(context, yatzyHelp),
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
          child: Column(
            children: [
              _MessageBar(gs.message),
              _DiceArea(gs, amIHost: amIHost),
              Expanded(child: _Scorecard(gs, amIHost: amIHost)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBar extends StatelessWidget {
  final String msg;
  const _MessageBar(this.msg);
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration:
            BoxDecoration(color: _kOverlay, borderRadius: BorderRadius.circular(8)),
        child: Text(msg,
            style: const TextStyle(color: _kGameText),
            textAlign: TextAlign.center),
      );
}

class _DiceArea extends ConsumerWidget {
  final YatzyState gs;
  final bool amIHost;
  const _DiceArea(this.gs, {required this.amIHost});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(yatzyStateProvider.notifier);
    final myTurn = _isMyTurn(gs, amIHost);
    final canHold =
        myTurn && gs.phase == YatzyPhase.scoring && gs.rollsLeft > 0;
    final canRoll = myTurn &&
        gs.rollsLeft > 0 &&
        (gs.phase == YatzyPhase.start || gs.phase == YatzyPhase.scoring) &&
        gs.phase != YatzyPhase.aiThinking &&
        gs.phase != YatzyPhase.gameOver;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration:
          BoxDecoration(color: _kOverlay, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (i) {
              final held = gs.holds[i];
              return GestureDetector(
                onTap: canHold
                    ? () => _sendOrApply(
                        ref, notifier, 'toggleHold', {'index': i})
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: held
                        ? _kHeld.withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: held ? _kHeld : Colors.white54, width: 2),
                  ),
                  child: Center(
                    child: Text('${gs.dice[i]}',
                        style: const TextStyle(
                            color: _kGameText,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(canHold ? 'Tap dice to hold' : '',
                  style:
                      const TextStyle(color: _kGameTextMuted, fontSize: 12)),
              Text('Rolls left: ${gs.rollsLeft}',
                  style:
                      const TextStyle(color: _kGameTextMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canRoll
                  ? () => _sendOrApply(ref, notifier, 'roll', const {})
                  : null,
              icon: const Icon(Icons.casino),
              label: Text(gs.rollsLeft == 3 ? 'Roll Dice' : 'Roll Again'),
            ),
          ),
          if (gs.phase == YatzyPhase.aiThinking)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

class _Scorecard extends ConsumerWidget {
  final YatzyState gs;
  final bool amIHost;
  const _Scorecard(this.gs, {required this.amIHost});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(yatzyStateProvider.notifier);
    final myTurn = _isMyTurn(gs, amIHost);
    final canScore = myTurn && gs.phase == YatzyPhase.scoring && gs.rollsLeft < 3;
    final myCard = amIHost ? gs.playerCard : gs.aiCard;
    final oppCard = amIHost ? gs.aiCard : gs.playerCard;
    final oppLabel = gs.isMultiplayer ? 'Opp.' : 'AI';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      decoration:
          BoxDecoration(color: _kOverlay, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              const Expanded(
                  child: Text('Category',
                      style: TextStyle(
                          color: _kGameTextMuted,
                          fontWeight: FontWeight.bold))),
              SizedBox(
                  width: 64,
                  child: Text('You',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: _kGameText,
                          fontWeight: FontWeight.bold))),
              SizedBox(
                  width: 64,
                  child: Text(oppLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: _kGameTextMuted,
                          fontWeight: FontWeight.bold))),
            ]),
          ),
          const Divider(color: Colors.white24, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 8),
              children: [
                _sectionHeader('Upper Section'),
                for (final cat in upperCats)
                  _ScoreRow(
                      cat: cat,
                      gs: gs,
                      myCard: myCard,
                      oppCard: oppCard,
                      canScore: canScore,
                      notifier: notifier),
                _bonusRow(myCard, oppCard),
                _sectionHeader('Lower Section'),
                for (final cat in YatzyCategory.values)
                  if (!upperCats.contains(cat))
                    _ScoreRow(
                        cat: cat,
                        gs: gs,
                        myCard: myCard,
                        oppCard: oppCard,
                        canScore: canScore,
                        notifier: notifier),
                _totalRow(myCard, oppCard),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
        child: Text(title,
            style: const TextStyle(
                color: Color(0xFF80CBC4),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
      );

  Widget _bonusRow(Scorecard myCard, Scorecard oppCard) {
    final pSub = myCard.upperSub;
    final pBonus = myCard.bonus;
    final aSub = oppCard.upperSub;
    final aBonus = oppCard.bonus;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.white.withValues(alpha: 0.05),
      child: Row(children: [
        const Expanded(
            child: Text('Bonus (≥63 → +50)',
                style: TextStyle(color: Color(0xFFFFD54F), fontSize: 12))),
        SizedBox(
            width: 64,
            child: Text(pBonus > 0 ? '+50' : '$pSub/63',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: pBonus > 0 ? Colors.greenAccent : _kGameTextMuted,
                    fontSize: 12))),
        SizedBox(
            width: 64,
            child: Text(aBonus > 0 ? '+50' : '$aSub/63',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: aBonus > 0 ? Colors.greenAccent : _kGameTextMuted,
                    fontSize: 12))),
      ]),
    );
  }

  Widget _totalRow(Scorecard myCard, Scorecard oppCard) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: Colors.white.withValues(alpha: 0.08),
        child: Row(children: [
          const Expanded(
              child: Text('TOTAL',
                  style: TextStyle(
                      color: _kGameText,
                      fontWeight: FontWeight.bold,
                      fontSize: 14))),
          SizedBox(
              width: 64,
              child: Text('${myCard.total}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14))),
          SizedBox(
              width: 64,
              child: Text('${oppCard.total}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: _kGameTextMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 14))),
        ]),
      );
}

class _ScoreRow extends StatelessWidget {
  final YatzyCategory cat;
  final YatzyState gs;
  final Scorecard myCard;
  final Scorecard oppCard;
  final bool canScore;
  final YatzyNotifier notifier;
  const _ScoreRow(
      {required this.cat,
      required this.gs,
      required this.myCard,
      required this.oppCard,
      required this.canScore,
      required this.notifier});

  @override
  Widget build(BuildContext context) {
    final playerScore = myCard.scores[cat];
    final aiScore = oppCard.scores[cat];
    final potential =
        (canScore && playerScore == null) ? scoreFor(cat, gs.dice) : null;
    final isAvail = canScore && playerScore == null;

    return Consumer(builder: (context, ref, _) => InkWell(
      onTap: isAvail
          ? () => _sendOrApply(
              ref, notifier, 'scoreCategory', {'category': cat.name})
          : null,
      child: Container(
        color: isAvail ? _kAvail.withValues(alpha: 0.25) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(children: [
          Expanded(
              child: Text(categoryLabel[cat]!,
                  style: TextStyle(
                      color: isAvail ? Colors.white : _kGameTextMuted,
                      fontSize: 13))),
          SizedBox(
            width: 64,
            child: Text(
              playerScore != null
                  ? '$playerScore'
                  : potential != null
                      ? '+$potential'
                      : '—',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: playerScore != null
                    ? _kGameText
                    : (potential != null && potential > 0)
                        ? Colors.greenAccent
                        : _kGameTextMuted,
                fontWeight: playerScore != null ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(aiScore != null ? '$aiScore' : '—',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: aiScore != null ? _kGameText : _kGameTextMuted,
                    fontWeight:
                        aiScore != null ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13)),
          ),
        ]),
      ),
    ));
  }
}
