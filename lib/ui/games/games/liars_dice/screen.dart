import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/lan/lan_providers.dart';
import '../../components/game_help_screen.dart';
import '../../components/game_rules_data.dart';
import 'logic.dart';
import 'helpers.dart';

// ── Game overlay style ────────────────────────────────────────────────────────
// All in-game containers use a dark translucent overlay so white text is always
// legible against the Viking background image.

const _kOverlay = Color(0xBB000000);      // black 73 % opacity
const _kOverlayLight = Color(0x88000000); // black 53 % — for subtle chips
const _kGameText = Colors.white;
const _kGameTextSecondary = Color(0xFFb0bec5); // light blue-grey

BoxDecoration _gameCard({double radius = 10}) => BoxDecoration(
      color: _kOverlay,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white24),
    );

TextStyle _gameTitle(BuildContext context) =>
    Theme.of(context).textTheme.titleMedium!.copyWith(color: _kGameText);

TextStyle _gameBody(BuildContext context) =>
    Theme.of(context).textTheme.bodyLarge!.copyWith(color: _kGameText);

TextStyle _gameBodySmall(BuildContext context) =>
    Theme.of(context).textTheme.bodyMedium!.copyWith(color: _kGameTextSecondary);

// ── Per-device identity helpers ───────────────────────────────────────────────

bool _isDeclarerMe(GameState gs, String? localPlayerId) {
  if (gs.players.isEmpty || gs.currentTurn >= gs.players.length) return false;
  final declarer = gs.players[gs.currentTurn];
  if (declarer.isAI) return false;
  if (localPlayerId != null) return declarer.id == localPlayerId;
  final humans = gs.players.where((p) => !p.isAI);
  return humans.isNotEmpty && declarer.id == humans.first.id;
}

bool _isOpponentMe(GameState gs, String? localPlayerId) {
  if (gs.players.isEmpty || gs.oppositionPlayer >= gs.players.length) {
    return false;
  }
  final opponent = gs.players[gs.oppositionPlayer];
  if (opponent.isAI) return false;
  if (localPlayerId != null) return opponent.id == localPlayerId;
  final humans = gs.players.where((p) => !p.isAI);
  return humans.isNotEmpty && opponent.id == humans.first.id;
}

void _sendOrApply(
  WidgetRef ref,
  GameStateNotifier notifier,
  String action,
  Map<String, dynamic> data,
) {
  if (notifier.isClientMode) {
    ref.read(gameLanServiceProvider).sendMove(action, data);
  } else {
    switch (action) {
      case 'finalizeRoll':
        notifier.finalizeRoll((data['dice'] as List).cast<int>());
      case 'declareBid':
        notifier.declareBid(Bid.fromJson(data));
      case 'acceptChallenge':
        notifier.acceptChallenge(data['accept'] as bool);
      case 'resolveChallenge':
        notifier.resolveChallenge();
    }
  }
}

// ── Dice widgets ──────────────────────────────────────────────────────────────

class DiceWidget extends StatelessWidget {
  final int? value;
  final bool isHeld;
  final VoidCallback? onTap;

  const DiceWidget({super.key, this.value, this.isHeld = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isHeld
              ? const Color(0xFF006666).withValues(alpha: 0.7)
              : const Color(0xFF1a1a2e).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isHeld ? const Color(0xFF00cccc) : Colors.white38,
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black54, offset: Offset(2, 2), blurRadius: 4),
          ],
        ),
        child: Center(
          child: Text(
            value != null ? value.toString() : '?',
            style: const TextStyle(
              color: _kGameText,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
            ),
          ),
        ),
      ),
    );
  }
}

class DiceRow extends StatelessWidget {
  final List<int?> diceValues;
  final List<bool> holds;
  final Function(int)? onDiceTap;

  const DiceRow({
    super.key,
    required this.diceValues,
    this.holds = const [],
    this.onDiceTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final isHeld =
            holds.isNotEmpty && holds[index] && diceValues[index] != null;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: DiceWidget(
            value: diceValues[index],
            isHeld: isHeld,
            onTap: onDiceTap != null ? () => onDiceTap!(index) : null,
          ),
        );
      }),
    );
  }
}

// ── Main screen ───────────────────────────────────────────────────────────────

class LiarsDiceScreen extends ConsumerWidget {
  const LiarsDiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/games/games/liars_dice/icon.jpg',
              height: 36,
              errorBuilder: (context, error, stack) =>
                  const Icon(Icons.casino, size: 36),
            ),
            const SizedBox(width: 12),
            const Text("Liar's Dice"),
          ],
        ),
        backgroundColor: const Color(0xCC000000),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Reset game',
            onPressed: () => ref.read(gameStateProvider.notifier).resetGame(),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            tooltip: 'How to play',
            onPressed: () => showGameHelp(context, liarsDiceHelp),
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (gameState.gameMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: _gameCard(radius: 8),
                    child: Text(
                      gameState.gameMessage!,
                      style: _gameBody(context),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 12),
                Expanded(child: _buildStateUI(context, ref, gameState)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStateUI(
      BuildContext context, WidgetRef ref, GameState gameState) {
    final notifier = ref.read(gameStateProvider.notifier);
    switch (gameState.currentState) {
      case GameStateEnum.start:
        return _StartStateUI(notifier: notifier, gameState: gameState);
      case GameStateEnum.determineStarter:
        return _DetermineStarterUI(gameState: gameState);
      case GameStateEnum.rollDice:
      case GameStateEnum.declareHand:
        return const _GameplayUI();
      case GameStateEnum.acceptChallenge:
        return const _AcceptChallengeUI();
      case GameStateEnum.acceptReveal:
        return const _AcceptRevealUI();
      case GameStateEnum.resolveChallenge:
        return const _ResolveChallengeUI();
      case GameStateEnum.determineGameOver:
        return _DetermineGameOverUI(notifier: notifier, gameState: gameState);
      case GameStateEnum.gameOver:
        return _GameOverUI(notifier: notifier, gameState: gameState);
    }
  }
}

// ── Start ─────────────────────────────────────────────────────────────────────

class _StartStateUI extends ConsumerWidget {
  final GameStateNotifier notifier;
  final GameState gameState;

  const _StartStateUI({required this.notifier, required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: _gameCard(),
          child: Text('Add Players (2–10)',
              style: _gameTitle(context), textAlign: TextAlign.center),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            children: gameState.players.map((player) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 3),
                decoration: _gameCard(),
                child: ListTile(
                  title: Text(player.name,
                      style: const TextStyle(color: _kGameText)),
                  subtitle: Text(player.isAI ? 'AI' : 'Human',
                      style: const TextStyle(color: _kGameTextSecondary)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: _kGameText),
                    onPressed: () => notifier.removePlayer(player.id),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () {
            final id = 'ai_${gameState.players.length}';
            notifier.addPlayer(Player(
              id: id,
              name: 'AI ${gameState.players.length + 1}',
              isAI: true,
            ));
          },
          icon: const Icon(Icons.smart_toy_outlined),
          label: const Text('Add AI Player'),
        ),
        const SizedBox(height: 8),
        FilledButton.tonal(
          onPressed: () {
            notifier.addPlayer(
                const Player(id: 'human', name: 'You', isAI: false));
          },
          child: const Text('Add Human Player'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed:
              gameState.players.length >= 2 ? () => notifier.startGame() : null,
          child: const Text('Start Game'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Determine starter ─────────────────────────────────────────────────────────

class _DetermineStarterUI extends StatelessWidget {
  final GameState gameState;
  const _DetermineStarterUI({required this.gameState});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: gameState.players.map((player) {
        final isRerolling = gameState.rerollingPlayerIds.contains(player.id);
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: _gameCard().copyWith(
            border: Border.all(
              color: isRerolling ? Colors.amber : Colors.white24,
              width: isRerolling ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(player.name, style: _gameTitle(context)),
              if (isRerolling) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.amber),
                    ),
                    const SizedBox(width: 6),
                    Text('Tied — re-rolling…',
                        style: _gameBodySmall(context)
                            .copyWith(color: Colors.amber)),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              _ShakingDice(
                key: ValueKey('${player.id}_${isRerolling}_'
                    '${player.dice.join(',')}'),
                shake: isRerolling,
                child: DiceRow(diceValues: player.dice.cast<int?>()),
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Wraps a dice row with a brief shake so tied players re-rolling for the
/// starter spot read as visibly "in motion", not just a silent number swap.
class _ShakingDice extends StatefulWidget {
  final bool shake;
  final Widget child;
  const _ShakingDice({super.key, required this.shake, required this.child});

  @override
  State<_ShakingDice> createState() => _ShakingDiceState();
}

class _ShakingDiceState extends State<_ShakingDice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.shake) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.shake) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final dx = (_controller.value - 0.5) * 10;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

// ── Gameplay (rollDice + declareHand) ─────────────────────────────────────────

// ConsumerStatefulWidget: _rollScheduled / _declareScheduled prevent the AI
// timer from being re-registered on every rebuild within the same phase.
class _GameplayUI extends ConsumerStatefulWidget {
  const _GameplayUI();

  @override
  ConsumerState<_GameplayUI> createState() => _GameplayUIState();
}

class _GameplayUIState extends ConsumerState<_GameplayUI> {
  bool _rollScheduled = false;
  bool _declareScheduled = false;

  @override
  void initState() {
    super.initState();
    // ref.listen only fires on transitions, not on initial mount.
    // If _GameplayUI mounts while already in rollDice (e.g. after challenge
    // resolution), reset local dice providers so the Roll button appears.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final gs = ref.read(gameStateProvider);
      if (gs.currentState == GameStateEnum.rollDice) {
        ref.read(hasRolledProvider.notifier).set(false);
        ref.read(diceHoldsProvider.notifier).set(List.filled(5, false));
        final inherited = gs.players[gs.currentTurn].dice;
        ref.read(myDiceProvider.notifier).set(inherited);
        ref.read(selectedRankProvider.notifier).set(null);
        ref.read(selectedFaceProvider.notifier).set(null);
        setState(() {
          _rollScheduled = false;
          _declareScheduled = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final myDice = ref.watch(myDiceProvider);
    final holds = ref.watch(diceHoldsProvider);
    final hasRolled = ref.watch(hasRolledProvider);
    final selectedRank = ref.watch(selectedRankProvider);
    final selectedFace = ref.watch(selectedFaceProvider);
    final localPlayerId = ref.watch(localPlayerIdProvider);
    final notifier = ref.read(gameStateProvider.notifier);

    final declarerIsMe = _isDeclarerMe(gameState, localPlayerId);
    final currentPlayer = gameState.players[gameState.currentTurn];

    // Reset local dice state and schedule flags when a new roll phase begins.
    ref.listen<GameState>(gameStateProvider, (prev, next) {
      if (next.currentState == GameStateEnum.rollDice &&
          (prev?.currentState != GameStateEnum.rollDice ||
              prev?.currentTurn != next.currentTurn)) {
        ref.read(hasRolledProvider.notifier).set(false);
        ref.read(diceHoldsProvider.notifier).set(List.filled(5, false));
        // One-box: seed from the shared dice passed by the previous declarer.
        final inherited = next.players[next.currentTurn].dice;
        ref.read(myDiceProvider.notifier).set(inherited);
        ref.read(selectedRankProvider.notifier).set(null);
        ref.read(selectedFaceProvider.notifier).set(null);
        setState(() {
          _rollScheduled = false;
          _declareScheduled = false;
        });
      }
    });

    // AI auto-roll — one timer per roll phase. Gated on currentPlayer.isAI,
    // not just !declarerIsMe: a real remote peer's turn also has
    // declarerIsMe == false on the host's own screen, and without this check
    // the host would auto-roll/auto-declare on that human's behalf after 2s.
    if (!notifier.isClientMode &&
        !declarerIsMe &&
        currentPlayer.isAI &&
        !_rollScheduled &&
        gameState.currentState == GameStateEnum.rollDice) {
      _rollScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Timer(const Duration(seconds: 2), () {
          if (!mounted) return;
          // Hold the best group in the inherited/current dice (one-box) and
          // only reroll the rest — a blind full reroll here would silently
          // discard a good hand every time a bot inherits one via accept.
          final inheritedDice = currentPlayer.dice;
          final holdMask = bestHoldMask(inheritedDice);
          final rolledDice = rollDiceWithHolds(inheritedDice, holdMask);
          ref.read(myDiceProvider.notifier).set(rolledDice);
          ref.read(hasRolledProvider.notifier).set(true);
          Timer(const Duration(seconds: 1), () {
            if (!mounted) return;
            notifier.finalizeRoll(rolledDice);
          });
        });
      });
    }

    // AI auto-declare — one timer per declare phase. Same isAI gate as above.
    if (!notifier.isClientMode &&
        !declarerIsMe &&
        currentPlayer.isAI &&
        !_declareScheduled &&
        gameState.currentState == GameStateEnum.declareHand) {
      _declareScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Timer(const Duration(seconds: 2), () {
          if (!mounted) return;
          notifier.declareBid(notifier.getAIBid());
        });
      });
    }

    // One-box: show the inherited (or rolled) dice to the human declarer at all
    // times — they need to see what they received before deciding what to hold.
    // The opponent still sees ? because !declarerIsMe.
    final List<int?> displayDice = declarerIsMe
        ? myDice.cast<int?>()
        : List.filled(5, null);

    final bool waitingForRemote = gameState.isMultiplayer && !declarerIsMe;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Status label
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: _gameCard(),
            child: Text(
              waitingForRemote
                  ? (gameState.currentState == GameStateEnum.rollDice
                      ? 'Waiting for ${currentPlayer.name} to roll…'
                      : 'Waiting for ${currentPlayer.name} to declare…')
                  : (gameState.currentState == GameStateEnum.rollDice
                      ? 'Roll your dice'
                      : 'Declare your hand'),
              style: _gameTitle(context),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),

          // Top row: last declared hand
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: _kOverlayLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text('Declared hand', style: _gameBodySmall(context)),
                const SizedBox(height: 6),
                DiceRow(
                  diceValues: gameState.lastDeclaredBid != null
                      ? List.filled(5, gameState.lastDeclaredBid!.face)
                      : List.filled(5, null),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Bottom row: declarer's dice (others see ?)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: _kOverlayLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  declarerIsMe ? 'Your dice' : "${currentPlayer.name}'s dice",
                  style: _gameBodySmall(context),
                ),
                const SizedBox(height: 6),
                DiceRow(
                  diceValues: displayDice,
                  holds: holds,
                  onDiceTap: declarerIsMe &&
                          !hasRolled &&
                          gameState.currentState == GameStateEnum.rollDice
                      ? (index) {
                          final newHolds = [...holds];
                          newHolds[index] = !holds[index];
                          ref
                              .read(diceHoldsProvider.notifier)
                              .set(newHolds);
                        }
                      : null,
                ),
                if (declarerIsMe && !hasRolled)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('Tap to hold a die before rolling',
                        style: _gameBodySmall(context)),
                  ),
              ],
            ),
          ),

          // Declare dropdowns
          if (declarerIsMe &&
              ((hasRolled &&
                      gameState.currentState == GameStateEnum.rollDice) ||
                  gameState.currentState == GameStateEnum.declareHand)) ...[
            const SizedBox(height: 10),
            Container(
              decoration: _gameCard(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<DiceRank>(
                  value: selectedRank,
                  isExpanded: true,
                  hint: Text('Select Rank',
                      style: TextStyle(color: _kGameTextSecondary)),
                  dropdownColor: const Color(0xFF1a1a2e),
                  style: const TextStyle(color: _kGameText),
                  iconEnabledColor: _kGameText,
                  onChanged: (v) =>
                      ref.read(selectedRankProvider.notifier).set(v),
                  items: DiceRank.values
                      .map((rank) => DropdownMenuItem(
                            value: rank,
                            child: Text(rankToString(rank)),
                          ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: _gameCard(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: selectedFace,
                  isExpanded: true,
                  hint: Text('Select Face',
                      style: TextStyle(color: _kGameTextSecondary)),
                  dropdownColor: const Color(0xFF1a1a2e),
                  style: const TextStyle(color: _kGameText),
                  iconEnabledColor: _kGameText,
                  onChanged: (v) =>
                      ref.read(selectedFaceProvider.notifier).set(v),
                  items: List.generate(6, (i) => i + 1)
                      .map((face) => DropdownMenuItem(
                            value: face,
                            child: Text(faceToString(face)),
                          ))
                      .toList(),
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Roll button
          if (declarerIsMe &&
              gameState.currentState == GameStateEnum.rollDice &&
              !hasRolled)
            FilledButton.icon(
              onPressed: () {
                final newDice = rollDiceWithHolds(myDice, holds);
                ref.read(myDiceProvider.notifier).set(newDice);
                ref.read(hasRolledProvider.notifier).set(true);
                if (notifier.isClientMode) {
                  _sendOrApply(
                      ref, notifier, 'finalizeRoll', {'dice': newDice});
                }
              },
              icon: const Icon(Icons.casino_outlined),
              label: const Text('Roll Dice'),
            ),

          // Declare button
          if (declarerIsMe &&
              ((hasRolled &&
                      gameState.currentState == GameStateEnum.rollDice) ||
                  gameState.currentState == GameStateEnum.declareHand))
            Builder(builder: (ctx) {
              final rank = selectedRank;
              final face = selectedFace;
              final valid = rank != null &&
                  face != null &&
                  isValidBid(Bid(rank, face), gameState.lastDeclaredBid);
              return FilledButton(
                onPressed: valid
                    ? () {
                        final bid = Bid(rank, face);
                        if (!notifier.isClientMode) {
                          notifier.finalizeRoll(myDice);
                        }
                        _sendOrApply(
                            ref, notifier, 'declareBid', bid.toJson());
                        ref.read(selectedRankProvider.notifier).set(null);
                        ref.read(selectedFaceProvider.notifier).set(null);
                      }
                    : null,
                child: const Text('Declare'),
              );
            }),

          const SizedBox(height: 12),

          // Scoreboard
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: _gameCard(),
            child: Column(
              children: [
                Text('Scoreboard', style: _gameBodySmall(context)),
                const SizedBox(height: 4),
                ...gameState.players.map((p) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(p.name, style: _gameBody(context)),
                          Text('${p.counters} counters',
                              style: _gameBodySmall(context)),
                        ],
                      ),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const _RankingCard(),
        ],
      ),
    );
  }
}

// ── Accept / Challenge ────────────────────────────────────────────────────────

class _AcceptChallengeUI extends ConsumerStatefulWidget {
  const _AcceptChallengeUI();

  @override
  ConsumerState<_AcceptChallengeUI> createState() => _AcceptChallengeUIState();
}

class _AcceptChallengeUIState extends ConsumerState<_AcceptChallengeUI> {
  bool _scheduled = false;

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final opponent = gameState.players[gameState.oppositionPlayer];
    final localPlayerId = ref.watch(localPlayerIdProvider);
    final isMyTurn = _isOpponentMe(gameState, localPlayerId);
    final notifier = ref.read(gameStateProvider.notifier);

    if (opponent.isAI && !notifier.isClientMode && !_scheduled) {
      _scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Timer(const Duration(seconds: 2), () {
          if (!mounted) return;
          _sendOrApply(ref, notifier, 'acceptChallenge',
              {'accept': notifier.getAIAccept()});
        });
      });
    }

    final bool waitingForRemote =
        gameState.isMultiplayer && !isMyTurn && !opponent.isAI;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: _gameCard(),
          child: Column(
            children: [
              Text(
                waitingForRemote
                    ? 'Waiting for ${opponent.name} to decide…'
                    : '${opponent.name} — Accept or Challenge?',
                style: _gameTitle(context),
                textAlign: TextAlign.center,
              ),
              if (gameState.lastDeclaredBid != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${rankToString(gameState.lastDeclaredBid!.rank)}'
                  ' of ${faceToString(gameState.lastDeclaredBid!.face)}',
                  style: _gameBody(context),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (isMyTurn)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FilledButton.tonal(
                onPressed: () => _sendOrApply(
                    ref, notifier, 'acceptChallenge', {'accept': true}),
                child: const Text('Accept'),
              ),
              FilledButton(
                onPressed: () => _sendOrApply(
                    ref, notifier, 'acceptChallenge', {'accept': false}),
                child: const Text('Challenge!'),
              ),
            ],
          ),
      ],
    );
  }
}

// ── Accept reveal ─────────────────────────────────────────────────────────────

// Brief dice reveal shown to all players after an opponent accepts the bid.
// No counter is deducted — this is purely informational.
class _AcceptRevealUI extends ConsumerStatefulWidget {
  const _AcceptRevealUI();

  @override
  ConsumerState<_AcceptRevealUI> createState() => _AcceptRevealUIState();
}

class _AcceptRevealUIState extends ConsumerState<_AcceptRevealUI> {
  bool _scheduled = false;

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final declarer = gameState.players[gameState.currentTurn];
    final notifier = ref.read(gameStateProvider.notifier);

    if (!notifier.isClientMode && !_scheduled) {
      _scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Timer(const Duration(seconds: 3), () {
          if (!mounted) return;
          notifier.advanceFromAcceptReveal();
        });
      });
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: _gameCard(),
          child: Column(
            children: [
              Text(
                '${gameState.players[gameState.oppositionPlayer].name} accepted!',
                style: _gameTitle(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                "${declarer.name}'s actual hand",
                style: _gameBodySmall(context),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (gameState.lastDeclaredBid != null) ...[
          Text('Declared', style: _gameBodySmall(context)),
          const SizedBox(height: 6),
          DiceRow(
              diceValues: List.filled(5, gameState.lastDeclaredBid!.face)),
          const SizedBox(height: 12),
        ],
        Text('Actual', style: _gameBodySmall(context)),
        const SizedBox(height: 6),
        DiceRow(diceValues: declarer.dice.cast<int?>()),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF006666).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF00cccc), width: 1),
          ),
          child: Text('Next round starting…', style: _gameBody(context)),
        ),
      ],
    );
  }
}

// ── Resolve challenge ─────────────────────────────────────────────────────────

class _ResolveChallengeUI extends ConsumerStatefulWidget {
  const _ResolveChallengeUI();

  @override
  ConsumerState<_ResolveChallengeUI> createState() =>
      _ResolveChallengeUIState();
}

class _ResolveChallengeUIState extends ConsumerState<_ResolveChallengeUI> {
  bool _scheduled = false;

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final declarer = gameState.players[gameState.currentTurn];
    final notifier = ref.read(gameStateProvider.notifier);

    if (!notifier.isClientMode && !_scheduled) {
      _scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Timer(const Duration(seconds: 3), () {
          if (!mounted) return;
          _sendOrApply(ref, notifier, 'resolveChallenge', {});
        });
      });
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: _gameCard(),
          child: Text(
            "Challenging ${declarer.name}!",
            style: _gameTitle(context),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        if (gameState.lastDeclaredBid != null) ...[
          Text('Declared', style: _gameBodySmall(context)),
          const SizedBox(height: 6),
          DiceRow(
              diceValues: List.filled(5, gameState.lastDeclaredBid!.face)),
          const SizedBox(height: 12),
        ],
        Text('Actual', style: _gameBodySmall(context)),
        const SizedBox(height: 6),
        DiceRow(diceValues: declarer.dice.cast<int?>()),
      ],
    );
  }
}

// ── Determine game over ───────────────────────────────────────────────────────

class _DetermineGameOverUI extends ConsumerWidget {
  final GameStateNotifier notifier;
  final GameState gameState;

  const _DetermineGameOverUI(
      {required this.notifier, required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!notifier.isClientMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.determineGameOver();
      });
    }
    return const Center(child: CircularProgressIndicator());
  }
}

// ── Ranking card ──────────────────────────────────────────────────────────────

class _MiniDie extends StatelessWidget {
  final int value;
  const _MiniDie({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      margin: const EdgeInsets.only(left: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white38, width: 1),
      ),
      child: Center(
        child: Text(
          value.toString(),
          style: const TextStyle(
            color: _kGameText,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// Example dice shown next to each hand rank. Order mirrors DiceRank enum (best → worst).
const _kRankExamples = [
  [3, 3, 3, 3, 3], // fiveOfAKind
  [2, 2, 2, 2, 5], // fourOfAKind
  [5, 5, 5, 2, 2], // fullHouse
  [2, 3, 4, 5, 6], // straightHigh
  [1, 2, 3, 4, 5], // straightLow
  [4, 4, 4, 1, 2], // threeOfAKind
  [3, 3, 6, 6, 1], // twoPair
  [5, 5, 2, 4, 6], // onePair
  [1, 3, 4, 5, 6], // highCard
];

class _RankingCard extends StatelessWidget {
  const _RankingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: _gameCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hand Rankings (highest → lowest)',
              style: _gameBodySmall(context)),
          const SizedBox(height: 8),
          ...List.generate(DiceRank.values.length, (i) {
            final rank = DiceRank.values[i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Text('${i + 1}.',
                        style: _gameBodySmall(context),
                        textAlign: TextAlign.right),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(rankToString(rank),
                        style: const TextStyle(
                            color: _kGameText, fontSize: 13)),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _kRankExamples[i]
                        .map((d) => _MiniDie(value: d))
                        .toList(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Game over ─────────────────────────────────────────────────────────────────

class _GameOverUI extends ConsumerWidget {
  final GameStateNotifier notifier;
  final GameState gameState;

  const _GameOverUI({required this.notifier, required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _gameCard(),
          child: Text(
            gameState.gameMessage ?? 'Game Over',
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  color: _kGameText,
                  shadows: const [
                    Shadow(color: Colors.black87, blurRadius: 8)
                  ],
                ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () {
            ref.read(gameLanServiceProvider).endSession();
            notifier.resetGame();
          },
          icon: const Icon(Icons.replay),
          label: const Text('Play Again'),
        ),
        const SizedBox(height: 8),
        FilledButton.tonal(
          onPressed: () {
            ref.read(gameLanServiceProvider).endSession();
            Navigator.of(context).pop();
          },
          child: const Text('Return to Games'),
        ),
      ],
    );
  }
}
