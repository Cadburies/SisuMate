import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/lan/game_lan_service.dart';
import '../../../../services/lan/lan_providers.dart';

final _rng = Random();

enum YatzyCategory {
  ones, twos, threes, fours, fives, sixes,
  threeOfAKind, fourOfAKind, fullHouse,
  smallStraight, largeStraight, yatzy, chance,
}

const categoryLabel = {
  YatzyCategory.ones: 'Ones',
  YatzyCategory.twos: 'Twos',
  YatzyCategory.threes: 'Threes',
  YatzyCategory.fours: 'Fours',
  YatzyCategory.fives: 'Fives',
  YatzyCategory.sixes: 'Sixes',
  YatzyCategory.threeOfAKind: '3 of a Kind',
  YatzyCategory.fourOfAKind: '4 of a Kind',
  YatzyCategory.fullHouse: 'Full House',
  YatzyCategory.smallStraight: 'Sm. Straight',
  YatzyCategory.largeStraight: 'Lg. Straight',
  YatzyCategory.yatzy: 'Yatzy!',
  YatzyCategory.chance: 'Chance',
};

final upperCats = [
  YatzyCategory.ones, YatzyCategory.twos, YatzyCategory.threes,
  YatzyCategory.fours, YatzyCategory.fives, YatzyCategory.sixes,
];

int scoreFor(YatzyCategory cat, List<int> dice) {
  final cnt = List.filled(7, 0);
  for (final d in dice) { cnt[d]++; }
  final sum = dice.fold(0, (a, b) => a + b);
  switch (cat) {
    case YatzyCategory.ones: return cnt[1];
    case YatzyCategory.twos: return cnt[2] * 2;
    case YatzyCategory.threes: return cnt[3] * 3;
    case YatzyCategory.fours: return cnt[4] * 4;
    case YatzyCategory.fives: return cnt[5] * 5;
    case YatzyCategory.sixes: return cnt[6] * 6;
    case YatzyCategory.threeOfAKind: return cnt.any((c) => c >= 3) ? sum : 0;
    case YatzyCategory.fourOfAKind: return cnt.any((c) => c >= 4) ? sum : 0;
    case YatzyCategory.fullHouse:
      return (cnt.any((c) => c == 3) && cnt.any((c) => c == 2)) ? 25 : 0;
    case YatzyCategory.smallStraight:
      final v = dice.toSet();
      return (v.containsAll({1,2,3,4}) || v.containsAll({2,3,4,5}) || v.containsAll({3,4,5,6})) ? 30 : 0;
    case YatzyCategory.largeStraight:
      final v = dice.toSet();
      return (v.containsAll({1,2,3,4,5}) || v.containsAll({2,3,4,5,6})) ? 40 : 0;
    case YatzyCategory.yatzy: return dice.toSet().length == 1 ? 50 : 0;
    case YatzyCategory.chance: return sum;
  }
}

class Scorecard {
  final Map<YatzyCategory, int?> scores;
  // Number of extra Yatzys rolled after the first (each worth a 100-point
  // bonus, only earned when the original Yatzy box scored 50 — see the
  // "joker" handling in scoreCategory/_aiTurn, GB1).
  final int yatzyBonusCount;
  const Scorecard(this.scores, {this.yatzyBonusCount = 0});
  factory Scorecard.empty() =>
      Scorecard({for (final c in YatzyCategory.values) c: null});
  Scorecard withScore(YatzyCategory c, int v, {bool addYatzyBonus = false}) =>
      Scorecard({...scores, c: v},
          yatzyBonusCount: yatzyBonusCount + (addYatzyBonus ? 1 : 0));

  Map<String, dynamic> toJson() => {
        'scores': {for (final e in scores.entries) e.key.name: e.value},
        'yatzyBonusCount': yatzyBonusCount,
      };

  factory Scorecard.fromJson(Map<String, dynamic> j) {
    final raw = (j['scores'] as Map).cast<String, dynamic>();
    return Scorecard(
      {for (final c in YatzyCategory.values) c: raw[c.name] as int?},
      yatzyBonusCount: j['yatzyBonusCount'] as int? ?? 0,
    );
  }

  int get upperSub =>
      upperCats.fold(0, (s, c) => s + (scores[c] ?? 0));
  int get bonus => (upperCats.every((c) => scores[c] != null) && upperSub >= 63) ? 50 : 0;
  int get total {
    int t = upperSub + bonus + yatzyBonusCount * 100;
    for (final c in YatzyCategory.values) {
      if (!upperCats.contains(c)) t += scores[c] ?? 0;
    }
    return t;
  }
  bool get isComplete => scores.values.every((v) => v != null);
}

/// GB1: the "joker" score for [cat] when the dice are a repeat Yatzy (a
/// 5-of-a-kind rolled after the Yatzy box is already filled with 50) — the
/// dice are wild, so lower-section categories score their maximum
/// regardless of whether the literal 5-of-a-kind pattern matches. Upper
/// section categories use ordinary scoring (a 5-of-a-kind of face X already
/// scores 5×X there, which is correct without any override).
int jokerScoreFor(YatzyCategory cat, List<int> dice) {
  final sum = dice.fold(0, (a, b) => a + b);
  switch (cat) {
    case YatzyCategory.threeOfAKind:
    case YatzyCategory.fourOfAKind:
    case YatzyCategory.chance:
      return sum;
    case YatzyCategory.fullHouse:
      return 25;
    case YatzyCategory.smallStraight:
      return 30;
    case YatzyCategory.largeStraight:
      return 40;
    default:
      return scoreFor(cat, dice);
  }
}

enum YatzyPhase { start, rolling, scoring, aiThinking, gameOver }

class YatzyState {
  final List<int> dice;
  final List<bool> holds;
  final int rollsLeft;
  final Scorecard playerCard;
  final Scorecard aiCard;
  final List<int> aiDice;
  final bool isPlayerTurn;
  final YatzyPhase phase;
  final String message;
  // GAME1: `playerCard`/`isPlayerTurn` are an ABSOLUTE host-vs-opponent model,
  // not "whoever is looking at this screen" — the host is always `playerCard`
  // (isPlayerTurn: true), the opponent is always `aiCard`, whether that
  // opponent is the local AI (solo, isOpponentAI: true) or a real remote
  // player (multiplayer, isOpponentAI: false). Each screen derives "is it MY
  // turn" from `notifier.isClientMode` — see `_isMyTurn` in screen.dart.
  final bool isMultiplayer;
  final bool isOpponentAI;

  const YatzyState({
    required this.dice,
    required this.holds,
    required this.rollsLeft,
    required this.playerCard,
    required this.aiCard,
    required this.aiDice,
    required this.isPlayerTurn,
    required this.phase,
    required this.message,
    this.isMultiplayer = false,
    this.isOpponentAI = true,
  });

  YatzyState copyWith({
    List<int>? dice,
    List<bool>? holds,
    int? rollsLeft,
    Scorecard? playerCard,
    Scorecard? aiCard,
    List<int>? aiDice,
    bool? isPlayerTurn,
    YatzyPhase? phase,
    String? message,
    bool? isMultiplayer,
    bool? isOpponentAI,
  }) =>
      YatzyState(
        dice: dice ?? this.dice,
        holds: holds ?? this.holds,
        rollsLeft: rollsLeft ?? this.rollsLeft,
        playerCard: playerCard ?? this.playerCard,
        aiCard: aiCard ?? this.aiCard,
        aiDice: aiDice ?? this.aiDice,
        isPlayerTurn: isPlayerTurn ?? this.isPlayerTurn,
        phase: phase ?? this.phase,
        message: message ?? this.message,
        isMultiplayer: isMultiplayer ?? this.isMultiplayer,
        isOpponentAI: isOpponentAI ?? this.isOpponentAI,
      );

  Map<String, dynamic> toJson() => {
        'dice': dice,
        'holds': holds,
        'rollsLeft': rollsLeft,
        'playerCard': playerCard.toJson(),
        'aiCard': aiCard.toJson(),
        'aiDice': aiDice,
        'isPlayerTurn': isPlayerTurn,
        'phase': phase.name,
        'message': message,
        'isMultiplayer': isMultiplayer,
        'isOpponentAI': isOpponentAI,
      };

  factory YatzyState.fromJson(Map<String, dynamic> j) => YatzyState(
        dice: (j['dice'] as List).cast<int>(),
        holds: (j['holds'] as List).cast<bool>(),
        rollsLeft: j['rollsLeft'] as int,
        playerCard: Scorecard.fromJson(j['playerCard'] as Map<String, dynamic>),
        aiCard: Scorecard.fromJson(j['aiCard'] as Map<String, dynamic>),
        aiDice: (j['aiDice'] as List).cast<int>(),
        isPlayerTurn: j['isPlayerTurn'] as bool,
        phase: YatzyPhase.values.byName(j['phase'] as String),
        message: j['message'] as String,
        isMultiplayer: j['isMultiplayer'] as bool? ?? false,
        isOpponentAI: j['isOpponentAI'] as bool? ?? true,
      );
}

class YatzyNotifier extends Notifier<YatzyState> {
  bool _isHostMode = false;
  bool _isClientMode = false;

  bool get isClientMode => _isClientMode;

  StreamSubscription<Map<String, dynamic>>? _remoteSub;
  StreamSubscription<({String peerId, String action, Map<String, dynamic> data})>?
      _moveSub;
  StreamSubscription<String>? _leaveSub;

  // Bumped on every initClientMode()/exitMultiplayerMode() call so an
  // in-flight reconnect retry loop from a previous session can tell it's
  // stale and stop touching state after the notifier has moved on.
  int _sessionGeneration = 0;

  @override
  YatzyState build() {
    ref.onDispose(() {
      _remoteSub?.cancel();
      _moveSub?.cancel();
      _leaveSub?.cancel();
    });
    return YatzyState(
      dice: const [1, 1, 1, 1, 1],
      holds: List.filled(5, false),
      rollsLeft: 3,
      playerCard: Scorecard.empty(),
      aiCard: Scorecard.empty(),
      aiDice: const [1, 1, 1, 1, 1],
      isPlayerTurn: true,
      phase: YatzyPhase.start,
      message: 'Tap Roll to start your turn!',
    );
  }

  // ── Multiplayer setup (mirrors dudo/logic.dart's DudoGameNotifier) ────────
  //
  // Yatzy is strictly 2-role (unlike Dudo/Liar's Dice's N-player roster): the
  // HOST is always `playerCard`/`isPlayerTurn: true`, the opponent is always
  // `aiCard` — whether that's the local AI (solo) or a real remote guest
  // (multiplayer). No player-id roster is needed since there are only ever
  // these two fixed roles.

  void initHostMode(List<LobbyPlayer> lobbyPlayers) {
    _isHostMode = true;
    _isClientMode = false;
    _sessionGeneration++;
    _remoteSub?.cancel();
    _moveSub?.cancel();
    _leaveSub?.cancel();

    final lan = ref.read(gameLanServiceProvider);
    _moveSub = lan.incomingMoves.listen(_applyRemoteMove);
    _leaveSub = lan.playerLeaves.listen(_handleDisconnect);

    final opponent = lobbyPlayers.length > 1 ? lobbyPlayers[1] : null;
    state = YatzyState(
      dice: const [1, 1, 1, 1, 1],
      holds: List.filled(5, false),
      rollsLeft: 3,
      playerCard: Scorecard.empty(),
      aiCard: Scorecard.empty(),
      aiDice: const [1, 1, 1, 1, 1],
      isPlayerTurn: true,
      phase: YatzyPhase.start,
      message: 'Game ready. Starting...',
      isMultiplayer: true,
      isOpponentAI: opponent?.isAI ?? true,
    );
    // Unlike Dudo/Liar's Dice, Yatzy has no determineStarter/startGame step
    // after initHostMode to naturally re-broadcast a couple of seconds later
    // — nothing would ever send this initial state, leaving the guest stuck
    // on its own "Waiting for host..." default forever. A broadcast fired
    // synchronously here would still race the guest's initClientMode()
    // subscription (only set up once the "gameStarted" signal reaches it, a
    // moment *after* this runs) — so delay briefly first, same margin the
    // other two games get for free from their own startGame() timers.
    Timer(const Duration(seconds: 1), _broadcastIfHost);
  }

  void initClientMode() {
    _isClientMode = true;
    _isHostMode = false;
    _moveSub?.cancel();
    _leaveSub?.cancel();
    final generation = ++_sessionGeneration;

    final lan = ref.read(gameLanServiceProvider);
    _remoteSub = lan.remoteStates.listen((json) {
      state = YatzyState.fromJson(json);
    });
    _leaveSub = lan.playerLeaves.listen((peerId) {
      if (peerId == 'host') _handleHostDisconnect(generation);
    });

    state = YatzyState(
      dice: const [1, 1, 1, 1, 1],
      holds: List.filled(5, false),
      rollsLeft: 3,
      playerCard: Scorecard.empty(),
      aiCard: Scorecard.empty(),
      aiDice: const [1, 1, 1, 1, 1],
      isPlayerTurn: true,
      phase: YatzyPhase.start,
      message: 'Waiting for host...',
      isMultiplayer: true,
      isOpponentAI: false,
    );
  }

  void exitMultiplayerMode() {
    _isHostMode = false;
    _isClientMode = false;
    _sessionGeneration++;
    _remoteSub?.cancel();
    _moveSub?.cancel();
    _leaveSub?.cancel();
  }

  /// Client-side: the connection to the host dropped. Surfaces a message and
  /// tries a few quick reconnects before giving up cleanly.
  Future<void> _handleHostDisconnect(int generation) async {
    if (generation != _sessionGeneration) return;
    state = state.copyWith(message: 'Connection lost. Reconnecting…');

    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      await Future.delayed(const Duration(seconds: 2));
      if (generation != _sessionGeneration) return;

      final reconnected = await ref.read(gameLanServiceProvider).reconnect();
      if (generation != _sessionGeneration) return;

      if (reconnected) {
        state = state.copyWith(message: 'Reconnected!');
        return;
      }
    }

    state = state.copyWith(
      phase: YatzyPhase.gameOver,
      message: 'Connection to host lost. Game ended.',
    );
  }

  // ── Host-side remote move handler ─────────────────────────────────────────

  void _applyRemoteMove(
      ({String peerId, String action, Map<String, dynamic> data}) move) {
    switch (move.action) {
      case 'roll':
        roll();
      case 'toggleHold':
        toggleHold(move.data['index'] as int);
      case 'scoreCategory':
        scoreCategory(YatzyCategory.values.byName(move.data['category'] as String));
    }
  }

  void _broadcastIfHost() {
    if (_isHostMode) {
      ref.read(gameLanServiceProvider).broadcastState(state.toJson());
    }
  }

  // ── Disconnect handling ───────────────────────────────────────────────────
  //
  // Yatzy has no player-id roster (fixed 2-role model) — any disconnect while
  // hosting can only be the one real guest, so it simply ends the game.
  void _handleDisconnect(String peerId) {
    state = state.copyWith(
      phase: YatzyPhase.gameOver,
      message: 'Opponent disconnected. Game ended.',
    );
    _broadcastIfHost();
  }

  // ── Game actions ──────────────────────────────────────────────────────────

  void toggleHold(int i) {
    if (state.phase != YatzyPhase.rolling && state.phase != YatzyPhase.scoring) return;
    if (state.rollsLeft == 3) return;
    final h = [...state.holds];
    h[i] = !h[i];
    state = state.copyWith(holds: h);
    _broadcastIfHost();
  }

  void roll() {
    if (state.rollsLeft == 0) return;
    if (state.phase == YatzyPhase.aiThinking || state.phase == YatzyPhase.gameOver) return;

    final d = [...state.dice];
    for (int i = 0; i < 5; i++) {
      if (!state.holds[i]) d[i] = _rng.nextInt(6) + 1;
    }
    final left = state.rollsLeft - 1;
    state = state.copyWith(
      dice: d,
      rollsLeft: left,
      phase: YatzyPhase.scoring,
      message: left == 0
          ? 'No rolls left — pick a category!'
          : left == 1
              ? 'One roll left. Hold keepers, then pick a category.'
              : 'Pick a category or hold dice and roll again.',
    );
    _broadcastIfHost();
  }

  void scoreCategory(YatzyCategory cat) {
    if (state.phase == YatzyPhase.start || state.phase == YatzyPhase.rolling) return;

    if (!state.isMultiplayer) {
      // Solo: unchanged — always the human ("player") scoring, then the
      // local AI plays its turn synchronously.
      if (!state.isPlayerTurn) return;
      if (state.playerCard.scores[cat] != null) return;

      // GB1: a second (or later) Yatzy earns a 100-point bonus and, when
      // scored into a lower-section category, jokers that category to its max.
      final isJoker = state.dice.toSet().length == 1 &&
          state.playerCard.scores[YatzyCategory.yatzy] == 50;
      final pts = isJoker ? jokerScoreFor(cat, state.dice) : scoreFor(cat, state.dice);
      final newCard = state.playerCard.withScore(cat, pts, addYatzyBonus: isJoker);
      if (newCard.isComplete && state.aiCard.isComplete) {
        state = state.copyWith(
          playerCard: newCard,
          phase: YatzyPhase.gameOver,
          message: _endMessage(newCard, state.aiCard),
        );
        return;
      }
      state = state.copyWith(
        playerCard: newCard,
        isPlayerTurn: false,
        phase: YatzyPhase.aiThinking,
        message: 'AI is rolling…',
      );
      Timer(const Duration(milliseconds: 700), _aiTurn);
      return;
    }

    // Multiplayer: the active absolute role scores (host → playerCard, guest
    // → aiCard), then the turn passes to the other real device.
    final activeIsHost = state.isPlayerTurn;
    final activeCard = activeIsHost ? state.playerCard : state.aiCard;
    if (activeCard.scores[cat] != null) return;

    final isJoker = state.dice.toSet().length == 1 &&
        activeCard.scores[YatzyCategory.yatzy] == 50;
    final pts = isJoker ? jokerScoreFor(cat, state.dice) : scoreFor(cat, state.dice);
    final newCard = activeCard.withScore(cat, pts, addYatzyBonus: isJoker);

    final newPlayerCard = activeIsHost ? newCard : state.playerCard;
    final newAiCard = activeIsHost ? state.aiCard : newCard;

    if (newPlayerCard.isComplete && newAiCard.isComplete) {
      state = state.copyWith(
        playerCard: newPlayerCard,
        aiCard: newAiCard,
        phase: YatzyPhase.gameOver,
        message: _endMessage(newPlayerCard, newAiCard),
      );
      _broadcastIfHost();
      return;
    }

    state = state.copyWith(
      playerCard: newPlayerCard,
      aiCard: newAiCard,
      isPlayerTurn: !activeIsHost,
      holds: List.filled(5, false),
      rollsLeft: 3,
      phase: YatzyPhase.start,
      // Neutral phrasing on purpose: this one string is broadcast verbatim
      // to both devices, so "Your turn!"/"Opponent's turn!" would read
      // backwards on whichever screen didn't just score (caught live —
      // the guest saw "Opponent's turn!" while the Roll button was already
      // enabled for them).
      message: 'Next turn!',
    );
    _broadcastIfHost();
  }

  void _aiTurn() {
    if (!mounted) return;
    // AI rolls up to 3 times with simple hold strategy
    var d = List.generate(5, (_) => _rng.nextInt(6) + 1);
    d = yatzyAiSmartReroll(d, _rng);
    d = yatzyAiSmartReroll(d, _rng);

    final isJoker = d.toSet().length == 1 && state.aiCard.scores[YatzyCategory.yatzy] == 50;
    final cat = yatzyAiBestCat(d, state.aiCard, isJoker: isJoker);
    final pts = isJoker ? jokerScoreFor(cat, d) : scoreFor(cat, d);
    final newAiCard = state.aiCard.withScore(cat, pts, addYatzyBonus: isJoker);

    if (state.playerCard.isComplete && newAiCard.isComplete) {
      state = state.copyWith(
        aiDice: d,
        aiCard: newAiCard,
        phase: YatzyPhase.gameOver,
        message: _endMessage(state.playerCard, newAiCard),
      );
      return;
    }
    state = state.copyWith(
      aiDice: d,
      aiCard: newAiCard,
      isPlayerTurn: true,
      holds: List.filled(5, false),
      rollsLeft: 3,
      phase: YatzyPhase.start,
      message: 'AI scored ${categoryLabel[cat]!}: $pts pts. Your turn!',
    );
  }

  bool get mounted => true; // Notifier is always alive while provider is alive

  String _endMessage(Scorecard p, Scorecard ai) {
    final ps = p.total;
    final as_ = ai.total;
    if (ps > as_) return 'You win! 🎉 $ps vs $as_';
    if (as_ > ps) return 'AI wins! $as_ vs $ps';
    return 'Tie! $ps each';
  }

  void newGame() {
    exitMultiplayerMode();
    state = build();
  }
}

/// TEST28: pure AI re-roll policy — same dice + same [rng] seed ⇒ same result.
List<int> yatzyAiSmartReroll(List<int> d, Random rng) {
  final cnt = List.filled(7, 0);
  for (final v in d) {
    cnt[v]++;
  }
  // Hold the most frequent face; reroll singles
  final best = cnt.skip(1).reduce((a, b) => a > b ? a : b);
  final bestFace = cnt.indexOf(best, 1);
  return d
      .map((v) => (cnt[v] >= 2 || v == bestFace) ? v : rng.nextInt(6) + 1)
      .toList();
}

/// TEST28: pure category pick — no RNG; same dice + card ⇒ same category.
YatzyCategory yatzyAiBestCat(List<int> d, Scorecard card,
    {bool isJoker = false}) {
  YatzyCategory? best;
  int bestPts = -1;
  for (final cat in YatzyCategory.values) {
    if (card.scores[cat] != null) continue;
    final pts = isJoker ? jokerScoreFor(cat, d) : scoreFor(cat, d);
    if (pts > bestPts) {
      bestPts = pts;
      best = cat;
    }
  }
  return best ?? YatzyCategory.values.firstWhere((c) => card.scores[c] == null);
}

final yatzyStateProvider =
    NotifierProvider<YatzyNotifier, YatzyState>(YatzyNotifier.new);
