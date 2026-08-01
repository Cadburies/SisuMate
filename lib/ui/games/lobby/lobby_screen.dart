import 'dart:async';
import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_router.dart';
import '../../../core/colors.dart';
import '../../../services/game_ai/game_ai_difficulty.dart';
import '../../../services/game_ai/game_ai_persona.dart';
import '../../../services/lan/game_lan_service.dart';
import '../../../services/lan/lan_providers.dart';
import '../games/liars_dice/logic.dart' as liars_dice;
import '../games/dudo/logic.dart' as dudo;
import '../games/yatzy/logic.dart' as yatzy;
import '../games/checkers/logic.dart' as checkers;
import '../games/backgammon/logic.dart' as backgammon;
import '../games/cribbage/logic.dart' as cribbage;
import '../games/uno/logic.dart' as uno;
import '../games/poker/logic.dart' as poker;

/// Pre-game lobby used by every multiplayer game.
///
/// [gameId]   — catalog id (e.g. `liars_dice`) for named play route.
/// [gameName] — shown to discovering players (e.g. "Liar's Dice").
///
/// Host flow:  enter name → Host Game → wait for players → Start Game.
/// Client flow: enter name → Join a Game → pick from list → wait for host.
class GameLobbyScreen extends ConsumerStatefulWidget {
  final String gameId;
  final String gameName;

  const GameLobbyScreen({
    super.key,
    required this.gameId,
    required this.gameName,
  });

  @override
  ConsumerState<GameLobbyScreen> createState() => _GameLobbyScreenState();
}

class _GameLobbyScreenState extends ConsumerState<GameLobbyScreen> {
  // ── view state ─────────────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  _LobbyView _view = _LobbyView.pickRole;
  bool _busy = false;
  String? _error;

  // ── live data ──────────────────────────────────────────────────────────────
  final List<LobbyPlayer> _lobbyPlayers = [];
  int _aiCounter = 0;
  /// GAI1: difficulty applied to the next AI seat added.
  GameAiDifficulty _nextAiDifficulty = GameAiDifficulty.normal;
  /// GAI5: play style applied to the next AI seat added.
  GameAiPersona _nextAiPersona = GameAiPersona.balanced;
  final List<BonsoirService> _discovered = [];
  StreamSubscription<LobbyPlayer>? _joinSub;
  StreamSubscription<String>? _leaveSub;
  StreamSubscription<List<BonsoirService>>? _discoverySub;
  StreamSubscription<void>? _startSub;

  // Set right before navigating to the game screen (host starting, or a
  // client's gameStarted listener firing). Guards the dispose()-time cleanup
  // below so a successful start doesn't tear down the connection it just
  // established — only leaving the lobby *without* starting should.
  bool _gameStarted = false;

  // Cached rather than read fresh via a `ref.read()` getter: `ref` is unsafe
  // to use inside State.dispose() (Riverpod throws "Using ref when a widget
  // is about to or has been unmounted is unsafe") — this was silently
  // swallowing the endSession() cleanup call below, leaving the host's
  // WebSocket server + mDNS broadcast running forever after Cancel/back.
  late final GameLanService _lan = ref.read(gameLanServiceProvider);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _joinSub?.cancel();
    _leaveSub?.cancel();
    _discoverySub?.cancel();
    _startSub?.cancel();
    // Leaving the lobby without starting (back button, Cancel, or the
    // screen being popped for any other reason) must tear down the host's
    // WebSocket server + mDNS broadcast (or the client's connection)
    // immediately — otherwise a cancelled host keeps broadcasting forever
    // and shows up as an unreachable "zombie" entry in every future scan.
    if (!_gameStarted) {
      _lan.endSession();
    }
    super.dispose();
  }

  // ── host ───────────────────────────────────────────────────────────────────

  Future<void> _host() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter your player name first.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _lan.hostGame(gameName: widget.gameName, hostPlayerName: name);
      ref.read(localPlayerIdProvider.notifier).set('host');

      _lobbyPlayers
        ..clear()
        ..addAll(_lan.lobbyPlayers);

      _joinSub = _lan.playerJoins.listen((p) {
        if (mounted) setState(() => _lobbyPlayers.add(p));
      });
      _leaveSub = _lan.playerLeaves.listen((id) {
        if (mounted) {
          setState(() => _lobbyPlayers.removeWhere((p) => p.id == id));
        }
      });

      setState(() {
        _view = _LobbyView.hosting;
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _error = 'Could not start host: $e';
      });
    }
  }

  void _addAiPlayer() {
    _aiCounter++;
    // GAI5: persona seat name + difficulty, e.g. "Bluffer 2 (Hard)".
    final player = LobbyPlayer(
      id: 'ai_$_aiCounter',
      name:
          '${_nextAiPersona.seatName} $_aiCounter (${_nextAiDifficulty.label})',
      isAI: true,
      aiDifficulty: _nextAiDifficulty,
      aiPersona: _nextAiPersona,
    );
    _lan.addLocalPlayer(player);
    setState(() => _lobbyPlayers.add(player));
  }

  void _cycleNextAiDifficulty() {
    setState(() => _nextAiDifficulty = _nextAiDifficulty.next);
  }

  void _cycleNextAiPersona() {
    setState(() => _nextAiPersona = _nextAiPersona.next);
  }

  void _removeAiPlayer(String id) {
    _lan.removeLocalPlayer(id);
    setState(() => _lobbyPlayers.removeWhere((p) => p.id == id));
  }

  void _startGame() {
    switch (widget.gameId) {
      case 'liars_dice':
        final notifier = ref.read(liars_dice.gameStateProvider.notifier);
        notifier.initHostMode(_lobbyPlayers);
        notifier.startGame();
      case 'dudo':
        final notifier = ref.read(dudo.dudoGameProvider.notifier);
        notifier.initHostMode(_lobbyPlayers);
        notifier.startGame();
      case 'yatzy':
        // Yatzy is strictly 2-role with no starter-determination roll — the
        // host is always first, ready to play as soon as the lobby hands off.
        ref.read(yatzy.yatzyStateProvider.notifier).initHostMode(_lobbyPlayers);
      case 'checkers':
        // Same strictly-2-role shape as Yatzy — no starter roll either.
        ref.read(checkers.checkersStateProvider.notifier).initHostMode(_lobbyPlayers);
      case 'backgammon':
        ref.read(backgammon.backgammonStateProvider.notifier).initHostMode(_lobbyPlayers);
      case 'cribbage':
        ref.read(cribbage.cribbageStateProvider.notifier).initHostMode(_lobbyPlayers);
      case 'uno':
        ref.read(uno.unoStateProvider.notifier).initHostMode(_lobbyPlayers);
      case 'poker':
        ref.read(poker.pokerStateProvider.notifier).initHostMode(_lobbyPlayers);
    }
    _lan.startGame();

    _gameStarted = true;
    context.pushReplacement(AppRoutes.playGame(widget.gameId));
  }

  // ── client ─────────────────────────────────────────────────────────────────

  Future<void> _scan() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter your player name first.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _discovered.clear();
      _view = _LobbyView.joining;
    });

    try {
      await _lan.scanForGames();
      _discoverySub = _lan.discoveredGames.listen((services) {
        if (mounted) {
          setState(() {
            _discovered
              ..clear()
              ..addAll(services);
          });
        }
      });
      setState(() => _busy = false);
    } catch (e) {
      setState(() {
        _busy = false;
        _error = 'Discovery failed: $e';
        _view = _LobbyView.pickRole;
      });
    }
  }

  Future<void> _connect(BonsoirService service) async {
    final name = _nameCtrl.text.trim();
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _lan.joinGame(service: service, playerName: name);
      // myAssignedId arrives asynchronously via the welcome message.
      // Set localPlayerIdProvider just before entering the game screen so
      // the correct peer id is always available (welcome arrives well before
      // the host manually taps Start Game).
      _startSub = _lan.gameStarted.listen((_) {
        if (!mounted) return;
        final myId = _lan.myAssignedId ?? name;
        ref.read(localPlayerIdProvider.notifier).set(myId);
        switch (widget.gameId) {
          case 'liars_dice':
            ref.read(liars_dice.gameStateProvider.notifier).initClientMode();
          case 'dudo':
            ref.read(dudo.dudoGameProvider.notifier).initClientMode();
          case 'yatzy':
            ref.read(yatzy.yatzyStateProvider.notifier).initClientMode();
          case 'checkers':
            ref.read(checkers.checkersStateProvider.notifier).initClientMode();
          case 'backgammon':
            ref.read(backgammon.backgammonStateProvider.notifier).initClientMode();
          case 'cribbage':
            ref.read(cribbage.cribbageStateProvider.notifier).initClientMode();
          case 'uno':
            ref.read(uno.unoStateProvider.notifier).initClientMode();
          case 'poker':
            ref.read(poker.pokerStateProvider.notifier).initClientMode();
        }
        _gameStarted = true;
        context.pushReplacement(AppRoutes.playGame(widget.gameId));
      });

      setState(() {
        _view = _LobbyView.waitingForHost;
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _error = 'Could not connect: $e';
      });
    }
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: SisuColors.getAppBackground(isDark),
      appBar: AppBar(
        title: Text('${widget.gameName} — Multiplayer'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return switch (_view) {
      _LobbyView.pickRole => _PickRoleView(
          nameCtrl: _nameCtrl,
          error: _error,
          busy: _busy,
          onHost: _host,
          onJoin: _scan,
        ),
      _LobbyView.hosting => _HostingView(
          players: _lobbyPlayers,
          onStart: _lobbyPlayers.length >= 2 ? _startGame : null,
          onAddAi: _addAiPlayer,
          nextAiDifficulty: _nextAiDifficulty,
          onCycleAiDifficulty: _cycleNextAiDifficulty,
          nextAiPersona: _nextAiPersona,
          onCycleAiPersona: _cycleNextAiPersona,
          onRemoveAi: _removeAiPlayer,
        ),
      _LobbyView.joining => _JoiningView(
          services: _discovered,
          busy: _busy,
          error: _error,
          onConnect: _connect,
        ),
      _LobbyView.waitingForHost => const _WaitingView(),
    };
  }
}

enum _LobbyView { pickRole, hosting, joining, waitingForHost }

// ── Sub-views ─────────────────────────────────────────────────────────────────

class _PickRoleView extends StatelessWidget {
  final TextEditingController nameCtrl;
  final String? error;
  final bool busy;
  final VoidCallback onHost;
  final VoidCallback onJoin;

  const _PickRoleView({
    required this.nameCtrl,
    required this.error,
    required this.busy,
    required this.onHost,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Your name',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            hintText: 'e.g. Frik',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: busy ? null : onHost,
          icon: const Icon(Icons.wifi_tethering),
          label: const Text('Host Game'),
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: busy ? null : onJoin,
          icon: const Icon(Icons.search),
          label: const Text('Join a Game'),
        ),
        if (busy) ...[
          const SizedBox(height: 24),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }
}

class _HostingView extends StatelessWidget {
  final List<LobbyPlayer> players;
  final VoidCallback? onStart;
  final VoidCallback onAddAi;
  final void Function(String id) onRemoveAi;
  final GameAiDifficulty nextAiDifficulty;
  final VoidCallback onCycleAiDifficulty;
  final GameAiPersona nextAiPersona;
  final VoidCallback onCycleAiPersona;

  const _HostingView({
    required this.players,
    required this.onStart,
    required this.onAddAi,
    required this.onRemoveAi,
    required this.nextAiDifficulty,
    required this.onCycleAiDifficulty,
    required this.nextAiPersona,
    required this.onCycleAiPersona,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Lobby — waiting for players',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Other players open the app, tap Multiplayer, then Join a Game. '
          'You can also add AI players below.',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Expanded(
          child: players.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (_, i) {
                    final p = players[i];
                    return ListTile(
                      leading: Icon(
                          p.isAI ? Icons.smart_toy_outlined : Icons.person),
                      title: Text(p.name),
                      subtitle: Text(p.id == 'host'
                          ? 'Host'
                          : (p.isAI
                              ? 'AI · ${p.aiPersona.label} · ${p.aiDifficulty.label}'
                              : 'Player')),
                      trailing: p.isAI
                          ? IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => onRemoveAi(p.id),
                            )
                          : null,
                    );
                  },
                ),
        ),
        const SizedBox(height: 8),
        // GAI1 difficulty + GAI5 persona chips for the next seat.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: Text('Skill: ${nextAiDifficulty.label}'),
              selected: true,
              onSelected: (_) => onCycleAiDifficulty(),
              avatar: const Icon(Icons.tune, size: 16),
            ),
            FilterChip(
              label: Text('Style: ${nextAiPersona.label}'),
              selected: true,
              onSelected: (_) => onCycleAiPersona(),
              avatar: const Icon(Icons.psychology_outlined, size: 16),
            ),
            FilledButton.tonalIcon(
              onPressed: onAddAi,
              icon: const Icon(Icons.smart_toy_outlined),
              label: const Text('Add AI'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: onStart,
          child: Text(onStart == null
              ? 'Need at least 2 players'
              : 'Start Game (${players.length} players)'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel Hosting'),
        ),
      ],
    );
  }
}

class _JoiningView extends StatelessWidget {
  final List<BonsoirService> services;
  final bool busy;
  final String? error;
  final void Function(BonsoirService) onConnect;

  const _JoiningView({
    required this.services,
    required this.busy,
    required this.error,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Available games',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(width: 12),
            if (busy) const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (error != null)
          Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        const SizedBox(height: 8),
        Expanded(
          child: services.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_find, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        'Searching for games on your WiFi...',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: services.length,
                  itemBuilder: (_, i) {
                    final svc = services[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.sports_esports),
                        title: Text(svc.name),
                        subtitle: Text('${svc.host}:${svc.port}'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => onConnect(svc),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _WaitingView extends StatelessWidget {
  const _WaitingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          const Text('Connected! Waiting for the host to start the game...'),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
