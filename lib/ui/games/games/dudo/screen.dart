import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/lan/lan_providers.dart';
import '../../components/game_help_screen.dart';
import '../../components/game_rules_data.dart';
import 'logic.dart';
import 'helpers.dart';

// ── Shared style constants ────────────────────────────────────────────────────
// Dark overlays ensure all text is legible against the Viking longship background.

const _kOverlay = Color(0xBB000000);
const _kOverlayLight = Color(0x88000000);
const _kGameText = Colors.white;
const _kGameTextSecondary = Color(0xFFb0bec5);
const _kAccentTeal = Color(0xFF006666);
const _kAccentTealLight = Color(0xFF00cccc);

BoxDecoration _card({double radius = 10}) => BoxDecoration(
      color: _kOverlay,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white24),
    );

TextStyle _title(BuildContext context) =>
    Theme.of(context).textTheme.titleMedium!.copyWith(color: _kGameText);

TextStyle _body(BuildContext context) =>
    Theme.of(context).textTheme.bodyLarge!.copyWith(color: _kGameText);

TextStyle _bodySmall(BuildContext context) =>
    Theme.of(context).textTheme.bodyMedium!.copyWith(color: _kGameTextSecondary);

// ── Per-device identity + action dispatch (mirrors liars_dice/screen.dart) ────

/// Index of the local player's seat. Prefers the real peer identity
/// (`localPlayerIdProvider`, set once a game is joined via the multiplayer
/// lobby); falls back to "first human" for solo/local-AI play where no real
/// peer id exists.
int _myIndex(DudoGameState gs, String? localPlayerId) {
  if (localPlayerId != null) {
    final idx = gs.players.indexWhere((p) => p.id == localPlayerId);
    if (idx != -1) return idx;
  }
  return _humanIndex(gs);
}

void _sendOrApply(
  WidgetRef ref,
  DudoGameNotifier notifier,
  String action,
  Map<String, dynamic> data,
) {
  if (notifier.isClientMode) {
    ref.read(gameLanServiceProvider).sendMove(action, data);
  } else {
    switch (action) {
      case 'placeBid':
        notifier.placeBid(DudoBid.fromJson(data));
      case 'callDudo':
        notifier.callDudo();
      case 'callSpotOn':
        notifier.callSpotOn();
    }
  }
}

// ── Main screen ───────────────────────────────────────────────────────────────

class DudoScreen extends ConsumerWidget {
  const DudoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gs = ref.watch(dudoGameProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/games/games/dudo/icon.jpg',
              height: 36,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.casino, size: 36, color: _kGameText),
            ),
            const SizedBox(width: 12),
            const Text('Dudo', style: TextStyle(color: _kGameText)),
          ],
        ),
        backgroundColor: const Color(0xCC000000),
        foregroundColor: _kGameText,
        iconTheme: const IconThemeData(color: _kGameText),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _kGameText),
            tooltip: 'Reset game',
            onPressed: () => ref.read(dudoGameProvider.notifier).resetGame(),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: _kGameText),
            tooltip: 'How to play',
            onPressed: () => showGameHelp(context, dudoHelp),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/games/common/longship_background.png'),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (gs.isPalaficoRound)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade900.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Palafico! Aces aren\'t wild — raises must match the face, +1 quantity.',
                      style: _body(context).copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (gs.gameMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: _card(radius: 8),
                    child: Text(
                      gs.gameMessage!,
                      style: _body(context),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 12),
                Expanded(child: _buildStateUI(context, ref, gs)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStateUI(
      BuildContext context, WidgetRef ref, DudoGameState gs) {
    final notifier = ref.read(dudoGameProvider.notifier);
    switch (gs.currentState) {
      case DudoStateEnum.start:
        return _StartUI(notifier: notifier, gs: gs);
      case DudoStateEnum.determineStarter:
        return _DetermineStarterUI(gs: gs);
      case DudoStateEnum.rollAll:
        return _RollAllUI(gs: gs);
      case DudoStateEnum.bidding:
        return const _BiddingUI();
      case DudoStateEnum.resolveChallenge:
      case DudoStateEnum.resolveSpotOn:
        return const _ResolveUI();
      case DudoStateEnum.determineRoundOver:
        return _DetermineRoundOverUI(notifier: notifier);
      case DudoStateEnum.gameOver:
        return _GameOverUI(notifier: notifier, gs: gs);
    }
  }
}

// ── Start ─────────────────────────────────────────────────────────────────────

class _StartUI extends ConsumerWidget {
  final DudoGameNotifier notifier;
  final DudoGameState gs;
  const _StartUI({required this.notifier, required this.gs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: _card(),
          child: Text('Add Players (2–6)',
              style: _title(context), textAlign: TextAlign.center),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            children: gs.players.map((p) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 3),
                decoration: _card(),
                child: ListTile(
                  title: Text(p.name,
                      style: const TextStyle(color: _kGameText)),
                  subtitle: Text(p.isAI ? 'AI' : 'Human',
                      style: const TextStyle(color: _kGameTextSecondary)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: _kGameText),
                    onPressed: () => notifier.removePlayer(p.id),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => notifier.addPlayer(DudoPlayer(
            id: 'ai_${gs.players.length}',
            name: 'AI ${gs.players.length + 1}',
            isAI: true,
          )),
          icon: const Icon(Icons.smart_toy_outlined),
          label: const Text('Add AI Player'),
        ),
        const SizedBox(height: 8),
        FilledButton.tonal(
          onPressed: () => notifier.addPlayer(const DudoPlayer(
            id: 'human', name: 'You', isAI: false,
          )),
          child: const Text('Add Human Player'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: gs.players.length >= 2 ? notifier.startGame : null,
          child: const Text('Start Game'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Determine starter ─────────────────────────────────────────────────────────

class _DetermineStarterUI extends StatelessWidget {
  final DudoGameState gs;
  const _DetermineStarterUI({required this.gs});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: gs.players.map((p) {
        final die = p.dice.isNotEmpty ? p.dice.first : null;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: _card(),
          child: Row(
            children: [
              Expanded(
                  child: Text(p.name, style: _title(context))),
              _DiePip(value: die),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Roll All ──────────────────────────────────────────────────────────────────

class _RollAllUI extends ConsumerWidget {
  final DudoGameState gs;
  const _RollAllUI({required this.gs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myIndex = _myIndex(gs, ref.watch(localPlayerIdProvider));
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: _card(),
            child: Text('Dice rolled — round begins!',
                style: _title(context), textAlign: TextAlign.center),
          ),
          const SizedBox(height: 12),
          ...gs.players.asMap().entries.map((e) {
            final i = e.key;
            final p = e.value;
            if (p.isEliminated) return const SizedBox.shrink();
            final showDice = i == myIndex;
            return _PlayerDiceCard(
              player: p,
              showDice: showDice,
              isActive: false,
            );
          }),
        ],
      ),
    );
  }
}

// ── Bidding ───────────────────────────────────────────────────────────────────

class _BiddingUI extends ConsumerStatefulWidget {
  const _BiddingUI();

  @override
  ConsumerState<_BiddingUI> createState() => _BiddingUIState();
}

class _BiddingUIState extends ConsumerState<_BiddingUI> {
  bool _aiScheduled = false;
  int _selectedQty = 1;
  int _selectedFace = 2;

  @override
  Widget build(BuildContext context) {
    final gs = ref.watch(dudoGameProvider);
    final notifier = ref.read(dudoGameProvider.notifier);
    final localPlayerId = ref.watch(localPlayerIdProvider);
    final myIndex = _myIndex(gs, localPlayerId);
    final isMyTurn = gs.activePlayer == myIndex;
    final currentPlayer = gs.players[gs.activePlayer];

    // AI auto-action — host-only (a client just mirrors broadcast state), and
    // gated on the active seat actually being an AI: `!isMyTurn` alone would
    // also match a real remote human's turn once a second real player exists.
    if (!notifier.isClientMode &&
        !isMyTurn &&
        currentPlayer.isAI &&
        !_aiScheduled) {
      _aiScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Timer(const Duration(seconds: 2), () {
          if (!mounted) return;
          if (gs.currentBid != null && notifier.shouldAISpotOn()) {
            notifier.callSpotOn();
          } else if (gs.currentBid != null && notifier.shouldAIDudo()) {
            notifier.callDudo();
          } else {
            notifier.placeBid(notifier.computeAIBid());
          }
          if (mounted) setState(() => _aiScheduled = false);
        });
      });
    }

    // Reset flag when turn changes back to the local player.
    ref.listen<DudoGameState>(dudoGameProvider, (prev, next) {
      if (next.activePlayer == myIndex && prev?.activePlayer != myIndex) {
        setState(() => _aiScheduled = false);
      }
    });

    final bool waitingForRemote =
        gs.isMultiplayer && !isMyTurn && !currentPlayer.isAI;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Current bid
          _CurrentBidCard(gs: gs, context: context),
          const SizedBox(height: 10),

          // Player list
          ...gs.players.asMap().entries.map((e) {
            final i = e.key;
            final p = e.value;
            if (p.isEliminated) return const SizedBox.shrink();
            return _PlayerDiceCard(
              player: p,
              showDice: i == myIndex || gs.allDiceRevealed,
              isActive: i == gs.activePlayer,
            );
          }),

          if (waitingForRemote) ...[
            const SizedBox(height: 12),
            Text('Waiting for ${currentPlayer.name}…',
                style: _bodySmall(context), textAlign: TextAlign.center),
          ],

          // Human action area
          if (isMyTurn) ...[
            const SizedBox(height: 12),
            _BidControls(
              gs: gs,
              selectedQty: _selectedQty,
              selectedFace: _selectedFace,
              onQtyChanged: (v) => setState(() => _selectedQty = v),
              onFaceChanged: (v) => setState(() => _selectedFace = v),
              onBid: () => _sendOrApply(ref, notifier, 'placeBid',
                  DudoBid(_selectedQty, _selectedFace).toJson()),
              onDudo: gs.currentBid != null
                  ? () => _sendOrApply(ref, notifier, 'callDudo', const {})
                  : null,
              onSpotOn: gs.currentBid != null
                  ? () => _sendOrApply(ref, notifier, 'callSpotOn', const {})
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Resolve ───────────────────────────────────────────────────────────────────

class _ResolveUI extends ConsumerStatefulWidget {
  const _ResolveUI();

  @override
  ConsumerState<_ResolveUI> createState() => _ResolveUIState();
}

class _ResolveUIState extends ConsumerState<_ResolveUI> {
  bool _scheduled = false;

  @override
  Widget build(BuildContext context) {
    final gs = ref.watch(dudoGameProvider);
    final notifier = ref.read(dudoGameProvider.notifier);

    if (!notifier.isClientMode && !_scheduled) {
      _scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Timer(const Duration(seconds: 1), () {
          if (!mounted) return;
          if (gs.currentState == DudoStateEnum.resolveChallenge) {
            notifier.resolveChallenge();
          } else if (gs.currentState == DudoStateEnum.resolveSpotOn) {
            notifier.resolveSpotOn();
          }
        });
      });
    }

    final bid = gs.currentBid;
    final actual =
        bid != null ? countBid(gs.players, bid, isPalafico: gs.isPalaficoRound) : 0;

    return SingleChildScrollView(
      child: Column(
        children: [
          if (bid != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: _card(),
              child: Column(
                children: [
                  Text('Bid: ${bidToString(bid)}',
                      style: _title(context), textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text('Actual count: $actual × ${bid.face}s',
                      style: _body(context), textAlign: TextAlign.center),
                ],
              ),
            ),
          const SizedBox(height: 12),
          ...gs.players.map((p) {
            if (p.isEliminated) return const SizedBox.shrink();
            return _PlayerDiceCard(
                player: p, showDice: true, isActive: false);
          }),
        ],
      ),
    );
  }
}

// ── Determine round over ──────────────────────────────────────────────────────

class _DetermineRoundOverUI extends ConsumerWidget {
  final DudoGameNotifier notifier;
  const _DetermineRoundOverUI({required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!notifier.isClientMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.determineRoundOver();
      });
    }
    return const Center(child: CircularProgressIndicator());
  }
}

// ── Game over ─────────────────────────────────────────────────────────────────

class _GameOverUI extends ConsumerWidget {
  final DudoGameNotifier notifier;
  final DudoGameState gs;
  const _GameOverUI({required this.notifier, required this.gs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _card(),
          child: Text(
            gs.gameMessage ?? 'Game Over',
            style: Theme.of(context)
                .textTheme
                .headlineMedium!
                .copyWith(color: _kGameText),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: notifier.resetGame,
          icon: const Icon(Icons.replay),
          label: const Text('Play Again'),
        ),
        const SizedBox(height: 8),
        FilledButton.tonal(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Return to Games'),
        ),
      ],
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _CurrentBidCard extends StatelessWidget {
  final DudoGameState gs;
  final BuildContext context;
  const _CurrentBidCard({required this.gs, required this.context});

  @override
  Widget build(BuildContext _) {
    final bid = gs.currentBid;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _kOverlayLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Text('Current bid', style: _bodySmall(context)),
          const SizedBox(height: 4),
          Text(
            bid != null ? bidToString(bid) : '— no bid yet —',
            style: bid != null
                ? _title(context).copyWith(fontSize: 22)
                : _bodySmall(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PlayerDiceCard extends StatelessWidget {
  final DudoPlayer player;
  final bool showDice;
  final bool isActive;

  const _PlayerDiceCard({
    required this.player,
    required this.showDice,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive
            ? _kAccentTeal.withValues(alpha: 0.5)
            : _kOverlayLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? _kAccentTealLight : Colors.white24,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.name,
                    style: TextStyle(
                      color: _kGameText,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                    )),
                Text(
                  '${player.diceCount} ${player.diceCount == 1 ? 'die' : 'dice'}',
                  style: const TextStyle(
                      color: _kGameTextSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Row(
            children: showDice
                ? player.dice
                    .map((d) => _DiePip(value: d))
                    .toList()
                : List.generate(
                    player.diceCount,
                    (_) => const _DiePip(value: null),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DiePip extends StatelessWidget {
  final int? value;
  const _DiePip({this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: value == 1
            ? _kAccentTeal.withValues(alpha: 0.7)
            : const Color(0xFF1a1a2e).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: value == 1 ? _kAccentTealLight : Colors.white38,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          value != null ? '$value' : '?',
          style: TextStyle(
            color: _kGameText,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            shadows: value == 1
                ? null
                : const [Shadow(color: Colors.black87, blurRadius: 4)],
          ),
        ),
      ),
    );
  }
}

class _BidControls extends StatelessWidget {
  final DudoGameState gs;
  final int selectedQty;
  final int selectedFace;
  final ValueChanged<int> onQtyChanged;
  final ValueChanged<int> onFaceChanged;
  final VoidCallback onBid;
  final VoidCallback? onDudo;
  final VoidCallback? onSpotOn;

  const _BidControls({
    required this.gs,
    required this.selectedQty,
    required this.selectedFace,
    required this.onQtyChanged,
    required this.onFaceChanged,
    required this.onBid,
    this.onDudo,
    this.onSpotOn,
  });

  @override
  Widget build(BuildContext context) {
    final activeDice = gs.players
        .where((p) => !p.isEliminated)
        .fold(0, (s, p) => s + p.diceCount);
    final activePlayerDiceCount =
        gs.players[gs.activePlayer].diceCount;

    final bid = DudoBid(selectedQty, selectedFace);
    final isValid = isValidRaise(bid, gs.currentBid,
        playerDiceCount: activePlayerDiceCount, isPalafico: gs.isPalaficoRound);

    return Column(
      children: [
        // Quantity + face row
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _kOverlay,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedQty,
                    dropdownColor: const Color(0xFF1a1a2e),
                    style: const TextStyle(color: _kGameText),
                    iconEnabledColor: _kGameText,
                    isExpanded: true,
                    onChanged: (v) => onQtyChanged(v!),
                    items: List.generate(activeDice + 2, (i) => i + 1)
                        .map((q) => DropdownMenuItem(
                              value: q,
                              child: Text('$q'),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: _kOverlay,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedFace,
                    dropdownColor: const Color(0xFF1a1a2e),
                    style: const TextStyle(color: _kGameText),
                    iconEnabledColor: _kGameText,
                    isExpanded: true,
                    onChanged: (v) => onFaceChanged(v!),
                    items: [
                      if (activePlayerDiceCount == 1)
                        const DropdownMenuItem(value: 1, child: Text('Aces')),
                      ...List.generate(5, (i) => i + 2).map(
                        (f) => DropdownMenuItem(
                          value: f,
                          child: Text(faceLabel(f)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FilledButton(
              onPressed: isValid ? onBid : null,
              child: Text(gs.currentBid == null ? 'Bid' : 'Raise'),
            ),
            if (onDudo != null)
              FilledButton.tonal(
                onPressed: onDudo,
                child: const Text('Dudo!'),
              ),
            if (onSpotOn != null)
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kGameText,
                  side: const BorderSide(color: Colors.white38),
                ),
                onPressed: onSpotOn,
                child: const Text('Spot On'),
              ),
          ],
        ),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Returns the index of the first non-AI player, or 0 if all are AI.
int _humanIndex(DudoGameState gs) {
  for (int i = 0; i < gs.players.length; i++) {
    if (!gs.players[i].isAI) return i;
  }
  return 0;
}
