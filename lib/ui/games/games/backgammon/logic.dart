import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/game_ai/game_ai_difficulty.dart';
import '../../../../services/lan/game_lan_service.dart';
import '../../../../services/lan/lan_providers.dart';

final _rng = Random();

// Board: indices 0–23 = points 1–24.
// Human (white) moves point 24→1, i.e. index 23→0. Home board: indices 0–5.
// AI (black) moves point 1→24, i.e. index 0→23. Home board: indices 18–23.
// board[i] > 0 : human pieces on point i+1
// board[i] < 0 : AI pieces on point i+1

List<int> _initialBoard() {
  final b = List.filled(24, 0);
  // Human (white)
  b[23] = 2;   // point 24
  b[12] = 5;   // point 13
  b[7] = 3;    // point 8
  b[5] = 5;    // point 6
  // AI (black)
  b[0] = -2;   // point 1
  b[11] = -5;  // point 12
  b[16] = -3;  // point 17
  b[18] = -5;  // point 19
  return b;
}

enum BgPhase { rolling, moving, gameOver, doubleOffered }

class BackgammonState {
  final List<int> board;       // 24 points
  final int humanBar;
  final int aiBar;
  final int humanBornOff;
  final int aiBornOff;
  final List<int> dice;        // current roll (may have duplicates for doubles)
  final List<int> movesLeft;   // remaining die values to use this turn
  final bool isHumanTurn;
  final int? selectedPoint;    // -1 = bar, 0–23 = point index, null = none
  final BgPhase phase;
  final String message;
  // GAME1: absolute host/guest model, same shape as checkers/yatzy — the
  // host is always the human/white role (isHumanTurn: true means host's
  // turn), the opponent is always the AI/black role, whether that's the
  // local AI (solo, isOpponentAI: true) or a real remote guest (multiplayer,
  // isOpponentAI: false).
  final bool isMultiplayer;
  final bool isOpponentAI;
  // GB7 doubling cube — stake multiplies on accept; owner may redouble.
  final int cubeValue; // 1,2,4,8,16,32,64
  final bool? cubeOwnerIsHuman; // null = centered (either may double)
  final bool? doubleOfferedByHuman; // set while phase == doubleOffered

  const BackgammonState({
    required this.board,
    required this.humanBar,
    required this.aiBar,
    required this.humanBornOff,
    required this.aiBornOff,
    required this.dice,
    required this.movesLeft,
    required this.isHumanTurn,
    required this.selectedPoint,
    required this.phase,
    required this.message,
    this.isMultiplayer = false,
    this.isOpponentAI = true,
    this.cubeValue = 1,
    this.cubeOwnerIsHuman,
    this.doubleOfferedByHuman,
  });

  /// Whether the role whose turn it is may offer a double (before rolling).
  bool get canOfferDouble {
    if (phase != BgPhase.rolling) return false;
    if (cubeValue >= 64) return false;
    // Centered: either player. Owned: only the owner may redouble.
    if (cubeOwnerIsHuman == null) return true;
    return cubeOwnerIsHuman == isHumanTurn;
  }

  BackgammonState copyWith({
    List<int>? board,
    int? humanBar,
    int? aiBar,
    int? humanBornOff,
    int? aiBornOff,
    List<int>? dice,
    List<int>? movesLeft,
    bool? isHumanTurn,
    int? Function()? selectedPoint,
    BgPhase? phase,
    String? message,
    bool? isMultiplayer,
    bool? isOpponentAI,
    int? cubeValue,
    bool? Function()? cubeOwnerIsHuman,
    bool? Function()? doubleOfferedByHuman,
  }) =>
      BackgammonState(
        board: board ?? this.board,
        humanBar: humanBar ?? this.humanBar,
        aiBar: aiBar ?? this.aiBar,
        humanBornOff: humanBornOff ?? this.humanBornOff,
        aiBornOff: aiBornOff ?? this.aiBornOff,
        dice: dice ?? this.dice,
        movesLeft: movesLeft ?? this.movesLeft,
        isHumanTurn: isHumanTurn ?? this.isHumanTurn,
        selectedPoint: selectedPoint != null ? selectedPoint() : this.selectedPoint,
        phase: phase ?? this.phase,
        message: message ?? this.message,
        isMultiplayer: isMultiplayer ?? this.isMultiplayer,
        isOpponentAI: isOpponentAI ?? this.isOpponentAI,
        cubeValue: cubeValue ?? this.cubeValue,
        cubeOwnerIsHuman: cubeOwnerIsHuman != null
            ? cubeOwnerIsHuman()
            : this.cubeOwnerIsHuman,
        doubleOfferedByHuman: doubleOfferedByHuman != null
            ? doubleOfferedByHuman()
            : this.doubleOfferedByHuman,
      );

  Map<String, dynamic> toJson() => {
        'board': board,
        'humanBar': humanBar,
        'aiBar': aiBar,
        'humanBornOff': humanBornOff,
        'aiBornOff': aiBornOff,
        'dice': dice,
        'movesLeft': movesLeft,
        'isHumanTurn': isHumanTurn,
        'selectedPoint': selectedPoint,
        'phase': phase.name,
        'message': message,
        'isMultiplayer': isMultiplayer,
        'isOpponentAI': isOpponentAI,
        'cubeValue': cubeValue,
        'cubeOwnerIsHuman': cubeOwnerIsHuman,
        'doubleOfferedByHuman': doubleOfferedByHuman,
      };

  factory BackgammonState.fromJson(Map<String, dynamic> j) => BackgammonState(
        board: (j['board'] as List).cast<int>(),
        humanBar: j['humanBar'] as int,
        aiBar: j['aiBar'] as int,
        humanBornOff: j['humanBornOff'] as int,
        aiBornOff: j['aiBornOff'] as int,
        dice: (j['dice'] as List).cast<int>(),
        movesLeft: (j['movesLeft'] as List).cast<int>(),
        isHumanTurn: j['isHumanTurn'] as bool,
        selectedPoint: j['selectedPoint'] as int?,
        phase: BgPhase.values.byName(j['phase'] as String),
        message: j['message'] as String,
        isMultiplayer: j['isMultiplayer'] as bool? ?? false,
        isOpponentAI: j['isOpponentAI'] as bool? ?? true,
        cubeValue: j['cubeValue'] as int? ?? 1,
        cubeOwnerIsHuman: j['cubeOwnerIsHuman'] as bool?,
        doubleOfferedByHuman: j['doubleOfferedByHuman'] as bool?,
      );

  bool humanAllHome() {
    for (int i = 6; i < 24; i++) {
      if (board[i] > 0) return false;
    }
    return humanBar == 0;
  }

  bool aiAllHome() {
    for (int i = 0; i < 18; i++) {
      if (board[i] < 0) return false;
    }
    return aiBar == 0;
  }
}

// ── Move validation helpers ───────────────────────────────────────────────────

/// Returns list of valid destination indices for human moving from [from].
/// [from] == -1 means coming off the bar.
List<int> validHumanMoves(BackgammonState s, int from, int die) {
  if (s.movesLeft.isEmpty || !s.movesLeft.contains(die)) return [];
  final board = s.board;

  if (s.humanBar > 0 && from != -1) return []; // must enter from bar first

  if (from == -1) {
    // Entering from bar: land on point (25 - die) = index (24 - die)
    final dest = 24 - die;
    if (dest < 0 || dest > 23) return [];
    if (board[dest] <= -2) return []; // blocked by AI
    return [dest];
  }

  final dest = from - die;
  if (s.humanAllHome() && dest < 0) {
    // Exact bear-off (dest == -1) is always allowed. An overshoot
    // (dest < -1, i.e. die > exact needed) is only allowed when no checker
    // remains on a higher point — otherwise that checker must move/bear off
    // first (GB8: this used to accept any overshoot unconditionally).
    if (dest < -1) {
      for (int i = from + 1; i <= 5; i++) {
        if (board[i] > 0) return [];
      }
    }
    return [-2]; // -2 = bear off
  }
  if (dest < 0) return [];
  if (board[dest] <= -2) return []; // blocked
  return [dest];
}

List<int> validAiMoves(BackgammonState s, int from, int die) {
  if (s.movesLeft.isEmpty || !s.movesLeft.contains(die)) return [];
  final board = s.board;

  if (s.aiBar > 0 && from != -1) return [];

  if (from == -1) {
    final dest = die - 1; // entering: point die = index die-1
    if (dest < 0 || dest > 23) return [];
    if (board[dest] >= 2) return [];
    return [dest];
  }

  final dest = from + die;
  if (s.aiAllHome() && dest > 23) {
    // Exact bear-off (dest == 24) is always allowed. An overshoot
    // (dest > 24) is only allowed when no checker remains further back
    // (lower index within the home board) — mirrors the human check above.
    if (dest > 24) {
      for (int i = 18; i < from; i++) {
        if (board[i] < 0) return [];
      }
    }
    return [-2]; // bear off
  }
  if (dest > 23) return [];
  if (board[dest] >= 2) return [];
  return [dest];
}

// ── GAI3: full-turn AI (beam search + position eval) ─────────────────────────
//
// Old bot scored each die greedily (hit > bear-off > home). This searches
// complete plays for the current roll and scores the resulting position with
// pip race, bar pressure, blot risk, and home structure.

/// One ply in an AI play: (from, to, die). from/to use the same conventions
/// as [validAiMoves] (from == -1 bar, to == -2 bear off).
typedef AiPlayStep = (int from, int to, int die);

/// Pure AI helpers — unit-tested without the notifier.
class BackgammonAi {
  /// Beam width per ply for [GameAiDifficulty.normal] (doubles expand a lot).
  static const int beamWidthNormal = 14;
  static const int beamWidthHard = 28;
  static const int beamWidthEasy = 4;

  /// Higher = better for AI (black).
  static double evaluate(BackgammonState s) {
    if (s.aiBornOff >= 15) return 1e6;
    if (s.humanBornOff >= 15) return -1e6;

    var score = 0.0;

    // Pip race (lower AI pips / higher human pips is good for AI).
    score += (humanPipCount(s) - aiPipCount(s)) * 1.15;

    // Race finish.
    score += (s.aiBornOff - s.humanBornOff) * 42.0;

    // Bar pressure.
    score += s.humanBar * 28.0;
    score -= s.aiBar * 32.0;

    // Structure / contact.
    var aiBlots = 0;
    var humanBlots = 0;
    var aiPoints = 0;
    var humanPoints = 0;
    var aiHomeCheckers = 0;
    var humanHomeCheckers = 0;
    var longestAiPrime = 0;
    var run = 0;

    for (var i = 0; i < 24; i++) {
      final v = s.board[i];
      if (v <= -2) {
        aiPoints++;
        run++;
        if (run > longestAiPrime) longestAiPrime = run;
      } else {
        run = 0;
      }
      if (v >= 2) humanPoints++;
      if (v == -1) aiBlots++;
      if (v == 1) humanBlots++;
      if (i >= 18 && v < 0) aiHomeCheckers += -v;
      if (i <= 5 && v > 0) humanHomeCheckers += v;
    }

    // Exposed singles are liabilities; opponent blots are opportunities.
    score -= aiBlots * 18.0;
    score += humanBlots * 10.0;

    // Made points and primes (blockade value).
    score += aiPoints * 3.5;
    score -= humanPoints * 3.0;
    if (longestAiPrime >= 4) score += (longestAiPrime - 3) * 12.0;

    // Home-board concentration (bearing readiness / containment).
    score += aiHomeCheckers * 2.5;
    score -= humanHomeCheckers * 1.5;

    // Anchors in opponent's home (indices 0–5 for AI) are strong.
    for (var i = 0; i < 6; i++) {
      if (s.board[i] <= -2) score += 14.0;
      if (s.board[i] == -1) score += 4.0; // advanced builder, still blot risk above
    }

    return score;
  }

  static int aiPipCount(BackgammonState s) {
    var pips = s.aiBar * 25;
    for (var i = 0; i < 24; i++) {
      if (s.board[i] < 0) pips += -s.board[i] * (24 - i);
    }
    return pips;
  }

  static int humanPipCount(BackgammonState s) {
    var pips = s.humanBar * 25;
    for (var i = 0; i < 24; i++) {
      if (s.board[i] > 0) pips += s.board[i] * (i + 1);
    }
    return pips;
  }

  /// Legal (from, to) pairs for [die] given AI to move.
  static List<(int from, int to)> legalMoves(BackgammonState s, int die) {
    final out = <(int, int)>[];
    if (s.aiBar > 0) {
      for (final dest in validAiMoves(s, -1, die)) {
        out.add((-1, dest));
      }
      return out;
    }
    for (var i = 0; i < 24; i++) {
      if (s.board[i] >= 0) continue;
      for (final dest in validAiMoves(s, i, die)) {
        out.add((i, dest));
      }
    }
    return out;
  }

  /// Apply one AI checker move; removes [die] from [movesLeft].
  static BackgammonState applyMove(
    BackgammonState s,
    int from,
    int to,
    int die,
  ) {
    final board = List<int>.from(s.board);
    var aiBar = s.aiBar;
    var humanBar = s.humanBar;
    var aiBornOff = s.aiBornOff;

    if (from == -1) {
      aiBar--;
    } else {
      board[from]++;
    }
    if (to == -2) {
      aiBornOff++;
    } else {
      if (board[to] == 1) {
        board[to] = 0;
        humanBar++;
      }
      board[to]--;
    }

    final movesLeft = List<int>.from(s.movesLeft)..remove(die);
    return s.copyWith(
      board: board,
      aiBar: aiBar,
      humanBar: humanBar,
      aiBornOff: aiBornOff,
      movesLeft: movesLeft,
      selectedPoint: () => null,
      isHumanTurn: false,
      phase: BgPhase.moving,
    );
  }

  static int beamWidthFor(GameAiDifficulty d) => switch (d) {
        GameAiDifficulty.easy => beamWidthEasy,
        GameAiDifficulty.normal => beamWidthNormal,
        GameAiDifficulty.hard => beamWidthHard,
      };

  /// Best full play for the current [movesLeft] roll. Empty if no legal move.
  ///
  /// GAI1: [difficulty] widens/narrows the beam; Easy sometimes picks a
  /// random legal full play instead of the top eval line.
  static List<AiPlayStep> bestPlay(
    BackgammonState s, {
    GameAiDifficulty difficulty = GameAiDifficulty.normal,
    Random? rng,
  }) {
    if (s.movesLeft.isEmpty) return const [];
    final r = rng ?? Random();
    final width = beamWidthFor(difficulty);

    // Beam: each entry is (state after partial play, steps so far).
    var beam = <(BackgammonState, List<AiPlayStep>)>[(s, <AiPlayStep>[])];
    final stepsRemaining = s.movesLeft.length;

    for (var depth = 0; depth < stepsRemaining; depth++) {
      final next = <(BackgammonState, List<AiPlayStep>)>[];
      for (final (cur, path) in beam) {
        if (cur.movesLeft.isEmpty) {
          next.add((cur, path));
          continue;
        }
        final uniqueDice = cur.movesLeft.toSet();
        var expanded = false;
        for (final die in uniqueDice) {
          final moves = legalMoves(cur, die);
          for (final m in moves) {
            expanded = true;
            final ns = applyMove(cur, m.$1, m.$2, die);
            next.add((ns, [...path, (m.$1, m.$2, die)]));
          }
        }
        if (!expanded) {
          // Stuck with unused dice — keep partial play.
          next.add((cur, path));
        }
      }
      if (next.isEmpty) break;
      next.sort((a, b) => evaluate(b.$1).compareTo(evaluate(a.$1)));
      beam = next.length <= width ? next : next.sublist(0, width);
    }

    if (beam.isEmpty) return const [];
    beam.sort((a, b) => evaluate(b.$1).compareTo(evaluate(a.$1)));

    // Easy: ~40% of the time pick a random beam candidate (noise).
    if (difficulty == GameAiDifficulty.easy && beam.length > 1 && r.nextInt(5) < 2) {
      return beam[r.nextInt(beam.length)].$2;
    }
    // Hard: always top. Normal: top (beam already narrower than hard).
    return beam.first.$2;
  }

  /// Whether AI should accept an offered double (crude equity on eval).
  static bool shouldAcceptDouble(
    BackgammonState s, {
    GameAiDifficulty difficulty = GameAiDifficulty.normal,
  }) {
    final e = evaluate(s);
    // Easy holds more often (accept worse positions); hard is pickier.
    final floor = switch (difficulty) {
      GameAiDifficulty.easy => -80.0,
      GameAiDifficulty.normal => -40.0,
      GameAiDifficulty.hard => -20.0,
    };
    return e > floor;
  }

  /// Whether AI should offer a double before rolling.
  static bool shouldOfferDouble(
    BackgammonState s,
    Random rng, {
    GameAiDifficulty difficulty = GameAiDifficulty.normal,
  }) {
    if (!s.canOfferDouble) return false;
    final e = evaluate(s);
    final minLead = switch (difficulty) {
      GameAiDifficulty.easy => 90.0,
      GameAiDifficulty.normal => 55.0,
      GameAiDifficulty.hard => 40.0,
    };
    if (e < minLead) return false;
    // Stronger lead → more likely to cube (hard cubes more aggressively).
    if (e >= 120) {
      return rng.nextInt(difficulty == GameAiDifficulty.hard ? 2 : 3) == 0;
    }
    return rng.nextInt(difficulty == GameAiDifficulty.easy ? 8 : 5) == 0;
  }

  // ── GAI6: coach / hint mode (human to move; does not apply the play) ─────

  /// Higher = better for human (white). Negation of black-centric [evaluate].
  static double evaluateForHuman(BackgammonState s) => -evaluate(s);

  /// Legal (from, to) for [die] with human (white) to move.
  static List<(int from, int to)> legalHumanMoves(BackgammonState s, int die) {
    final out = <(int, int)>[];
    if (s.humanBar > 0) {
      for (final dest in validHumanMoves(s, -1, die)) {
        out.add((-1, dest));
      }
      return out;
    }
    for (var i = 0; i < 24; i++) {
      if (s.board[i] <= 0) continue;
      for (final dest in validHumanMoves(s, i, die)) {
        out.add((i, dest));
      }
    }
    return out;
  }

  /// Apply one human checker move; removes [die] from [movesLeft].
  static BackgammonState applyHumanMove(
    BackgammonState s,
    int from,
    int to,
    int die,
  ) {
    final board = List<int>.from(s.board);
    var humanBar = s.humanBar;
    var aiBar = s.aiBar;
    var humanBornOff = s.humanBornOff;

    if (from == -1) {
      humanBar--;
    } else {
      board[from]--;
    }
    if (to == -2) {
      humanBornOff++;
    } else {
      if (board[to] == -1) {
        board[to] = 0;
        aiBar++;
      }
      board[to]++;
    }

    final movesLeft = List<int>.from(s.movesLeft)..remove(die);
    return s.copyWith(
      board: board,
      humanBar: humanBar,
      aiBar: aiBar,
      humanBornOff: humanBornOff,
      movesLeft: movesLeft,
      selectedPoint: () => null,
      isHumanTurn: true,
      phase: BgPhase.moving,
    );
  }

  /// Best full human play for current [movesLeft] (Hard beam by default).
  static List<AiPlayStep> bestHumanPlay(
    BackgammonState s, {
    GameAiDifficulty difficulty = GameAiDifficulty.hard,
  }) {
    if (s.movesLeft.isEmpty) return const [];
    final width = beamWidthFor(difficulty);

    var beam = <(BackgammonState, List<AiPlayStep>)>[(s, <AiPlayStep>[])];
    final stepsRemaining = s.movesLeft.length;

    for (var depth = 0; depth < stepsRemaining; depth++) {
      final next = <(BackgammonState, List<AiPlayStep>)>[];
      for (final (cur, path) in beam) {
        if (cur.movesLeft.isEmpty) {
          next.add((cur, path));
          continue;
        }
        final uniqueDice = cur.movesLeft.toSet();
        var expanded = false;
        for (final die in uniqueDice) {
          final moves = legalHumanMoves(cur, die);
          for (final m in moves) {
            expanded = true;
            final ns = applyHumanMove(cur, m.$1, m.$2, die);
            next.add((ns, [...path, (m.$1, m.$2, die)]));
          }
        }
        if (!expanded) next.add((cur, path));
      }
      if (next.isEmpty) break;
      // Best for human = highest evaluateForHuman = lowest AI evaluate.
      next.sort(
          (a, b) => evaluateForHuman(b.$1).compareTo(evaluateForHuman(a.$1)));
      beam = next.length <= width ? next : next.sublist(0, width);
    }

    if (beam.isEmpty) return const [];
    beam.sort(
        (a, b) => evaluateForHuman(b.$1).compareTo(evaluateForHuman(a.$1)));
    return beam.first.$2;
  }

  /// GAI6: suggested full play + plain-language reasons. Does **not** mutate
  /// game state — safe for solo coach UI.
  static CoachHint coachHint(
    BackgammonState s, {
    GameAiDifficulty difficulty = GameAiDifficulty.hard,
  }) {
    if (s.phase == BgPhase.gameOver) {
      return const CoachHint(
        steps: [],
        reasons: ['Game over — start a new game to practice.'],
        scoreDelta: 0,
      );
    }
    if (!s.isHumanTurn) {
      return const CoachHint(
        steps: [],
        reasons: ["Not your turn — coach only advises on your move."],
        scoreDelta: 0,
      );
    }
    if (s.phase == BgPhase.rolling) {
      return const CoachHint(
        steps: [],
        reasons: ['Roll the dice first, then ask for a hint.'],
        scoreDelta: 0,
      );
    }
    if (s.phase != BgPhase.moving || s.movesLeft.isEmpty) {
      return const CoachHint(
        steps: [],
        reasons: ['No dice left to play — pass or wait for the next roll.'],
        scoreDelta: 0,
      );
    }

    final before = evaluateForHuman(s);
    final play = bestHumanPlay(s, difficulty: difficulty);
    if (play.isEmpty) {
      return const CoachHint(
        steps: [],
        reasons: ['No legal play with this roll — pass the turn.'],
        scoreDelta: 0,
      );
    }

    var cur = s;
    final stepNotes = <String>[];
    for (final step in play) {
      final prev = cur;
      cur = applyHumanMove(cur, step.$1, step.$2, step.$3);
      stepNotes.add(_describeHumanStep(prev, step));
    }
    final after = evaluateForHuman(cur);
    final delta = after - before;
    final reasons = <String>[
      ...stepNotes,
      ..._positionReasons(s, cur),
      if (delta > 5)
        'Overall: improves your standing (eval +${delta.toStringAsFixed(0)}).'
      else if (delta < -5)
        'Overall: damage control — least-bad line (eval ${delta.toStringAsFixed(0)}).'
      else
        'Overall: roughly even position after this play.',
    ];

    return CoachHint(steps: play, reasons: reasons, scoreDelta: delta);
  }

  static String _pointLabel(int idx) {
    if (idx == -1) return 'bar';
    if (idx == -2) return 'off';
    return 'point ${idx + 1}';
  }

  static String _describeHumanStep(BackgammonState before, AiPlayStep step) {
    final (from, to, die) = step;
    final parts = <String>[
      '${_pointLabel(from)} → ${_pointLabel(to)} (die $die)',
    ];
    if (to != -2 && to >= 0 && before.board[to] == -1) {
      parts.add('hits blot');
    }
    if (to == -2) parts.add('bears off');
    if (from == -1) parts.add('enters from bar');
    if (to >= 0 && to <= 5 && from > 5) parts.add('into home');
    return parts.join(' — ');
  }

  static List<String> _positionReasons(
      BackgammonState before, BackgammonState after) {
    final out = <String>[];
    final pipGain = humanPipCount(before) - humanPipCount(after);
    if (pipGain > 0) out.add('Closes $pipGain pip(s) in the race.');
    if (after.aiBar > before.aiBar) {
      out.add('Puts ${after.aiBar - before.aiBar} opponent checker(s) on the bar.');
    }
    if (after.humanBar < before.humanBar) {
      out.add('Clears your bar.');
    }
    if (after.humanBornOff > before.humanBornOff) {
      out.add(
          'Bears off ${after.humanBornOff - before.humanBornOff} checker(s).');
    }

    int blots(BackgammonState s, {required bool human}) {
      var n = 0;
      for (var i = 0; i < 24; i++) {
        if (human && s.board[i] == 1) n++;
        if (!human && s.board[i] == -1) n++;
      }
      return n;
    }

    final blotDelta = blots(after, human: true) - blots(before, human: true);
    if (blotDelta < 0) out.add('Reduces your exposed blots.');
    if (blotDelta > 0) out.add('Leaves a blot — watch for return hits.');

    int madePoints(BackgammonState s, {required bool human}) {
      var n = 0;
      for (var i = 0; i < 24; i++) {
        if (human && s.board[i] >= 2) n++;
        if (!human && s.board[i] <= -2) n++;
      }
      return n;
    }

    final pointDelta =
        madePoints(after, human: true) - madePoints(before, human: true);
    if (pointDelta > 0) out.add('Makes a new point (safer structure).');

    return out;
  }
}

/// GAI6: coach suggestion for the human side (never auto-applied).
class CoachHint {
  /// Ordered plies `(from, to, die)` using human move conventions.
  final List<AiPlayStep> steps;
  /// Plain-language why lines for the sheet UI.
  final List<String> reasons;
  /// Change in [BackgammonAi.evaluateForHuman] after the full play.
  final double scoreDelta;

  const CoachHint({
    required this.steps,
    required this.reasons,
    required this.scoreDelta,
  });

  bool get hasPlay => steps.isNotEmpty;
}

class BackgammonNotifier extends Notifier<BackgammonState> {
  bool _isHostMode = false;
  bool _isClientMode = false;
  GameAiDifficulty _aiDifficulty = GameAiDifficulty.normal;

  /// GAI7: after each human turn, emit Hard-AI review for the roll position.
  bool practiceMode = false;
  BackgammonState? _practiceTurnStart;
  final _practiceReviewCtrl = StreamController<CoachHint>.broadcast();

  bool get isClientMode => _isClientMode;
  GameAiDifficulty get aiDifficulty => _aiDifficulty;

  /// Fires when [practiceMode] is on and the human finishes a turn (or wins).
  Stream<CoachHint> get practiceReviews => _practiceReviewCtrl.stream;

  StreamSubscription<Map<String, dynamic>>? _remoteSub;
  StreamSubscription<({String peerId, String action, Map<String, dynamic> data})>?
      _moveSub;
  StreamSubscription<String>? _leaveSub;

  // Bumped on every initClientMode()/exitMultiplayerMode() call so an
  // in-flight reconnect retry loop from a previous session can tell it's
  // stale and stop touching state after the notifier has moved on.
  int _sessionGeneration = 0;

  @override
  BackgammonState build() {
    ref.onDispose(() {
      _remoteSub?.cancel();
      _moveSub?.cancel();
      _leaveSub?.cancel();
      _practiceReviewCtrl.close();
    });
    return BackgammonState(
      board: _initialBoard(),
      humanBar: 0,
      aiBar: 0,
      humanBornOff: 0,
      aiBornOff: 0,
      dice: [],
      movesLeft: [],
      isHumanTurn: true,
      selectedPoint: null,
      phase: BgPhase.rolling,
      message: 'Tap "Roll" to start your turn.',
    );
  }

  // ── Multiplayer setup (mirrors checkers/logic.dart's absolute host/guest
  // model — Backgammon is strictly 2-role, no player-id roster needed) ──────

  void initHostMode(List<LobbyPlayer> lobbyPlayers) {
    _isHostMode = true;
    _isClientMode = false;
    _aiDifficulty = maxAiDifficulty(lobbyPlayers);
    _sessionGeneration++;
    _remoteSub?.cancel();
    _moveSub?.cancel();
    _leaveSub?.cancel();

    final lan = ref.read(gameLanServiceProvider);
    _moveSub = lan.incomingMoves.listen(_applyRemoteMove);
    _leaveSub = lan.playerLeaves.listen(_handleDisconnect);

    final opponent = lobbyPlayers.length > 1 ? lobbyPlayers[1] : null;
    state = BackgammonState(
      board: _initialBoard(),
      humanBar: 0,
      aiBar: 0,
      humanBornOff: 0,
      aiBornOff: 0,
      dice: [],
      movesLeft: [],
      isHumanTurn: true,
      selectedPoint: null,
      phase: BgPhase.rolling,
      message: 'Game ready. Starting...',
      isMultiplayer: true,
      isOpponentAI: opponent?.isAI ?? true,
    );
    // No startGame()/determineStarter() step to naturally re-broadcast a
    // couple of seconds later (same gap found live in Yatzy/Checkers) — delay
    // briefly so the guest's initClientMode() subscription has attached
    // before this fires, instead of it being stuck on its own default forever.
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
      state = BackgammonState.fromJson(json);
    });
    _leaveSub = lan.playerLeaves.listen((peerId) {
      if (peerId == 'host') _handleHostDisconnect(generation);
    });

    state = BackgammonState(
      board: _initialBoard(),
      humanBar: 0,
      aiBar: 0,
      humanBornOff: 0,
      aiBornOff: 0,
      dice: [],
      movesLeft: [],
      isHumanTurn: true,
      selectedPoint: null,
      phase: BgPhase.rolling,
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
      phase: BgPhase.gameOver,
      message: 'Connection to host lost. Game ended.',
    );
  }

  // ── Host-side remote move handler ─────────────────────────────────────────

  void _applyRemoteMove(
      ({String peerId, String action, Map<String, dynamic> data}) move) {
    switch (move.action) {
      case 'roll':
        roll();
      case 'selectPoint':
        selectPoint(move.data['pointIdx'] as int);
      case 'bearOff':
        bearOff();
      case 'passTurn':
        passTurn();
      case 'offerDouble':
        offerDouble();
      case 'acceptDouble':
        acceptDouble();
      case 'declineDouble':
        declineDouble();
    }
  }

  void _broadcastIfHost() {
    if (_isHostMode) {
      ref.read(gameLanServiceProvider).broadcastState(state.toJson());
    }
  }

  // ── Disconnect handling ───────────────────────────────────────────────────
  //
  // Backgammon has no player-id roster (fixed 2-role model) — any disconnect
  // while hosting can only be the one real guest, so it simply ends the game.
  void _handleDisconnect(String peerId) {
    state = state.copyWith(
      phase: BgPhase.gameOver,
      message: 'Opponent disconnected. Game ended.',
    );
    _broadcastIfHost();
  }

  // ── Game actions ────────────────────────────────────────────────────────────
  //
  // All of these act on behalf of whichever role's turn it currently is
  // (state.isHumanTurn), not hardcoded "the human" — in solo mode those are
  // always the same thing (the AI's turn never reaches these methods, it
  // goes through _aiMove instead), but in multiplayer the guest's actions are
  // forwarded here too via _applyRemoteMove while isHumanTurn is false. This
  // mirrors the fix found live in checkers/logic.dart's selectCell/
  // _executeMove — same bug class, same shape (single shared entry point
  // serving both roles), applied here proactively before shipping.

  // ── GB7 doubling cube ─────────────────────────────────────────────────────

  void offerDouble() {
    if (!state.canOfferDouble) return;
    final isHumanRole = state.isHumanTurn;
    state = state.copyWith(
      phase: BgPhase.doubleOffered,
      doubleOfferedByHuman: () => isHumanRole,
      message: isHumanRole
          ? 'Double offered (${state.cubeValue}→${state.cubeValue * 2}). Waiting…'
          : 'Opponent offers double to ${state.cubeValue * 2}. Accept or decline?',
    );
    _broadcastIfHost();

    // Local AI responds when a human offered against AI.
    final aiMustRespond = isHumanRole &&
        (!state.isMultiplayer || state.isOpponentAI);
    if (aiMustRespond) {
      Future.delayed(const Duration(milliseconds: 700), _aiRespondToDouble);
    }
  }

  void acceptDouble() {
    if (state.phase != BgPhase.doubleOffered) return;
    final offeredByHuman = state.doubleOfferedByHuman ?? true;
    // Acceptor becomes owner and may redouble later.
    final newOwnerIsHuman = !offeredByHuman;
    final newValue = (state.cubeValue * 2).clamp(1, 64);
    state = state.copyWith(
      cubeValue: newValue,
      cubeOwnerIsHuman: () => newOwnerIsHuman,
      doubleOfferedByHuman: () => null,
      phase: BgPhase.rolling,
      // Offerer's turn continues — they still need to roll.
      isHumanTurn: offeredByHuman,
      message: 'Double accepted — cube is $newValue. Roll dice.',
    );
    _broadcastIfHost();

    final isLocalAiTurn =
        !state.isHumanTurn && (!state.isMultiplayer || state.isOpponentAI);
    if (isLocalAiTurn) {
      Future.delayed(const Duration(milliseconds: 400), roll);
    }
  }

  void declineDouble() {
    if (state.phase != BgPhase.doubleOffered) return;
    final offeredByHuman = state.doubleOfferedByHuman ?? true;
    final stake = state.cubeValue;
    state = state.copyWith(
      phase: BgPhase.gameOver,
      doubleOfferedByHuman: () => null,
      // Mark winner via born-off for overlay: set offerer to 15.
      humanBornOff: offeredByHuman ? 15 : state.humanBornOff,
      aiBornOff: offeredByHuman ? state.aiBornOff : 15,
      message: offeredByHuman
          ? 'Opponent declined the double. You win ($stake pt)!'
          : 'You declined. Opponent wins ($stake pt).',
    );
    _broadcastIfHost();
  }

  void _aiRespondToDouble() {
    if (state.phase != BgPhase.doubleOffered) return;
    if (BackgammonAi.shouldAcceptDouble(state, difficulty: _aiDifficulty)) {
      acceptDouble();
    } else {
      declineDouble();
    }
  }

  void _maybeAiOfferDouble() {
    if (!state.canOfferDouble) return;
    if (state.isHumanTurn) return;
    if (state.isMultiplayer && !state.isOpponentAI) return;
    if (BackgammonAi.shouldOfferDouble(state, _rng, difficulty: _aiDifficulty)) {
      offerDouble();
    }
  }

  void roll() {
    if (state.phase != BgPhase.rolling) return;
    // Solo AI may offer a double before rolling.
    if (!state.isHumanTurn &&
        (!state.isMultiplayer || state.isOpponentAI) &&
        state.canOfferDouble) {
      _maybeAiOfferDouble();
      if (state.phase == BgPhase.doubleOffered) return;
    }

    final d1 = _rng.nextInt(6) + 1;
    final d2 = _rng.nextInt(6) + 1;
    final dice = [d1, d2];
    final moves = d1 == d2 ? [d1, d1, d1, d1] : [d1, d2];
    final isHumanRole = state.isHumanTurn;
    state = state.copyWith(
      dice: dice,
      movesLeft: moves,
      phase: BgPhase.moving,
      message: isHumanRole
          ? 'Rolled $d1, $d2. Select a piece to move.'
          : 'AI rolled $d1, $d2.',
    );
    _broadcastIfHost();
    if (isHumanRole) _capturePracticeTurnStart();

    // A remote human opponent plays its own turn via its own device's taps —
    // only fire the local AI when there's no such opponent to wait for
    // (solo, or a multiplayer seat deliberately filled with a local AI).
    final isLocalAiTurn =
        !isHumanRole && (!state.isMultiplayer || state.isOpponentAI);
    if (isLocalAiTurn) {
      Future.delayed(const Duration(milliseconds: 600), _aiMove);
      return;
    }

    // Whoever's turn it actually is (host or a real guest) — if they have no
    // valid move at all for this roll, auto-pass after a short beat.
    if (!_hasAnyMove(state, isHumanRole)) {
      state = state.copyWith(
        message: isHumanRole
            ? 'No valid moves for this roll — passing.'
            : 'Opponent has no valid moves — passing.',
      );
      _broadcastIfHost();
      Future.delayed(const Duration(milliseconds: 1200), () {
        state = state.copyWith(
          movesLeft: [],
          selectedPoint: () => null,
          isHumanTurn: !isHumanRole,
          phase: BgPhase.rolling,
          message: isHumanRole ? "Opponent's turn." : 'Your turn. Tap Roll.',
        );
        _broadcastIfHost();
        _emitPracticeReviewIfNeeded(humanTurnEnded: isHumanRole);
        final nextIsLocalAi = !state.isHumanTurn &&
            (!state.isMultiplayer || state.isOpponentAI);
        if (nextIsLocalAi) {
          Future.delayed(const Duration(milliseconds: 300), roll);
        }
      });
    }
  }

  void bearOff() {
    if (state.phase != BgPhase.moving) return;
    final isHumanRole = state.isHumanTurn;
    final from = state.selectedPoint;
    if (from == null || from < 0) return;
    for (final die in [...state.movesLeft]) {
      final dests = isHumanRole
          ? validHumanMoves(state, from, die)
          : validAiMoves(state, from, die);
      if (dests.contains(-2)) {
        _executeMove(from, -2, die, isHumanRole);
        return;
      }
    }
  }

  void passTurn() {
    if (state.phase != BgPhase.moving) return;
    final wasHumanTurn = state.isHumanTurn;
    state = state.copyWith(
      movesLeft: [],
      selectedPoint: () => null,
      isHumanTurn: !wasHumanTurn,
      phase: BgPhase.rolling,
      message: wasHumanTurn ? "Opponent's turn." : 'Your turn. Tap Roll.',
    );
    _broadcastIfHost();
    _emitPracticeReviewIfNeeded(humanTurnEnded: wasHumanTurn);
    final nextIsLocalAi =
        !state.isHumanTurn && (!state.isMultiplayer || state.isOpponentAI);
    if (nextIsLocalAi) {
      Future.delayed(const Duration(milliseconds: 300), roll);
    }
  }

  void selectPoint(int pointIdx) {
    // pointIdx: -1 = bar, 0–23 = board index
    if (state.phase != BgPhase.moving) return;
    final isHumanRole = state.isHumanTurn;
    final board = state.board;
    final hasSelected = state.selectedPoint != null;
    final barCount = isHumanRole ? state.humanBar : state.aiBar;

    if (!hasSelected) {
      // Selecting a source
      if (barCount > 0) {
        if (pointIdx == -1) {
          state = state.copyWith(
              selectedPoint: () => -1, message: 'Bar selected. Choose destination.');
          _broadcastIfHost();
        }
        return;
      }
      final owns = isHumanRole ? board[pointIdx] > 0 : board[pointIdx] < 0;
      if (pointIdx < 0 || pointIdx > 23 || !owns) return;
      state = state.copyWith(
          selectedPoint: () => pointIdx, message: 'Piece selected. Tap destination.');
      _broadcastIfHost();
      return;
    }

    final from = state.selectedPoint!;
    // Try each remaining die
    for (final die in [...state.movesLeft]) {
      final dests = isHumanRole
          ? validHumanMoves(state, from, die)
          : validAiMoves(state, from, die);
      if (dests.contains(pointIdx) || (pointIdx == -1 && dests.contains(-2))) {
        _executeMove(from, pointIdx == -1 ? -2 : pointIdx, die, isHumanRole);
        return;
      }
    }
    // Tapped invalid dest — try reselect
    final ownsTapped = pointIdx >= 0 &&
        pointIdx <= 23 &&
        (isHumanRole ? board[pointIdx] > 0 : board[pointIdx] < 0);
    if (ownsTapped) {
      state = state.copyWith(selectedPoint: () => pointIdx);
    } else {
      state = state.copyWith(selectedPoint: () => null, message: 'Invalid move. Select a piece.');
    }
    _broadcastIfHost();
  }

  void _executeMove(int from, int to, int die, bool isHumanRole) {
    final board = [...state.board];
    int humanBar = state.humanBar;
    int aiBar = state.aiBar;
    int humanBornOff = state.humanBornOff;
    int aiBornOff = state.aiBornOff;

    if (isHumanRole) {
      // Remove from source
      if (from == -1) {
        humanBar--;
      } else {
        board[from]--;
      }
      if (to == -2) {
        humanBornOff++;
      } else {
        // Hit check
        if (board[to] == -1) {
          board[to] = 0;
          aiBar++;
        }
        board[to]++;
      }
    } else {
      if (from == -1) {
        aiBar--;
      } else {
        board[from]++;
      }
      if (to == -2) {
        aiBornOff++;
      } else {
        if (board[to] == 1) {
          board[to] = 0;
          humanBar++;
        }
        board[to]--;
      }
    }

    final newMovesLeft = [...state.movesLeft];
    newMovesLeft.remove(die);

    if (isHumanRole && humanBornOff == 15) {
      final stake = state.cubeValue;
      state = state.copyWith(
        board: board, humanBar: humanBar, humanBornOff: humanBornOff,
        aiBar: aiBar, aiBornOff: aiBornOff, movesLeft: newMovesLeft,
        selectedPoint: () => null,
        phase: BgPhase.gameOver,
        message: 'You win! All pieces borne off ($stake pt).',
      );
      _broadcastIfHost();
      _emitPracticeReviewIfNeeded(humanTurnEnded: true);
      return;
    }
    if (!isHumanRole && aiBornOff == 15) {
      final stake = state.cubeValue;
      state = state.copyWith(
        board: board, humanBar: humanBar, humanBornOff: humanBornOff,
        aiBar: aiBar, aiBornOff: aiBornOff, movesLeft: newMovesLeft,
        selectedPoint: () => null,
        phase: BgPhase.gameOver,
        message: 'AI wins! All pieces borne off ($stake pt).',
      );
      _broadcastIfHost();
      return;
    }

    final stillHasMove = newMovesLeft.isNotEmpty &&
        _hasAnyMove(
          state.copyWith(
              board: board, humanBar: humanBar, aiBar: aiBar, movesLeft: newMovesLeft),
          isHumanRole,
        );

    if (!stillHasMove) {
      state = state.copyWith(
        board: board, humanBar: humanBar, humanBornOff: humanBornOff,
        aiBar: aiBar, aiBornOff: aiBornOff, movesLeft: [],
        selectedPoint: () => null,
        isHumanTurn: !isHumanRole,
        phase: BgPhase.rolling,
        message: isHumanRole ? "Opponent's turn." : 'Your turn. Tap Roll.',
      );
      _broadcastIfHost();
      _emitPracticeReviewIfNeeded(humanTurnEnded: isHumanRole);
      final nextIsLocalAi = !state.isHumanTurn &&
          (!state.isMultiplayer || state.isOpponentAI);
      if (nextIsLocalAi) {
        Future.delayed(const Duration(milliseconds: 300), roll);
      }
      return;
    }

    state = state.copyWith(
      board: board, humanBar: humanBar, humanBornOff: humanBornOff,
      aiBar: aiBar, aiBornOff: aiBornOff, movesLeft: newMovesLeft,
      selectedPoint: () => null,
      message: 'Move again (${newMovesLeft.join(", ")} left).',
    );
    _broadcastIfHost();
  }

  bool _hasAnyMove(BackgammonState s, bool isHumanRole) {
    for (final die in s.movesLeft.toSet()) {
      final barCount = isHumanRole ? s.humanBar : s.aiBar;
      if (barCount > 0) {
        final dests =
            isHumanRole ? validHumanMoves(s, -1, die) : validAiMoves(s, -1, die);
        if (dests.isNotEmpty) return true;
      } else {
        for (int i = 0; i < 24; i++) {
          final owns = isHumanRole ? s.board[i] > 0 : s.board[i] < 0;
          if (owns) {
            final dests = isHumanRole
                ? validHumanMoves(s, i, die)
                : validAiMoves(s, i, die);
            if (dests.isNotEmpty) return true;
          }
        }
      }
    }
    return false;
  }

  void _aiMove() {
    if (state.isHumanTurn || state.phase == BgPhase.gameOver) return;
    final s = state;
    // GAI3 beam search; GAI1 difficulty scales beam / noise.
    final play = BackgammonAi.bestPlay(
      s,
      difficulty: _aiDifficulty,
      rng: _rng,
    );
    var cur = s;
    for (final step in play) {
      cur = BackgammonAi.applyMove(cur, step.$1, step.$2, step.$3);
    }

    if (cur.aiBornOff >= 15) {
      final stake = state.cubeValue;
      state = state.copyWith(
        board: cur.board,
        aiBar: cur.aiBar,
        aiBornOff: cur.aiBornOff,
        humanBar: cur.humanBar,
        humanBornOff: cur.humanBornOff,
        movesLeft: [],
        selectedPoint: () => null,
        phase: BgPhase.gameOver,
        message: 'AI wins! All pieces borne off ($stake pt).',
      );
      _broadcastIfHost();
      return;
    }

    state = state.copyWith(
      board: cur.board,
      aiBar: cur.aiBar,
      aiBornOff: cur.aiBornOff,
      humanBar: cur.humanBar,
      humanBornOff: cur.humanBornOff,
      movesLeft: [],
      selectedPoint: () => null,
      isHumanTurn: true,
      phase: BgPhase.rolling,
      message: 'Your turn. Tap Roll.',
    );
    _broadcastIfHost();
  }

  void newGame() {
    exitMultiplayerMode();
    state = build();
  }

  /// GAI6: coach suggestion for the current position (does not change state).
  CoachHint coachHint({
    GameAiDifficulty difficulty = GameAiDifficulty.hard,
  }) =>
      BackgammonAi.coachHint(state, difficulty: difficulty);

  /// Snapshot after a human roll for GAI7 end-of-turn review.
  void _capturePracticeTurnStart() {
    if (!practiceMode) {
      _practiceTurnStart = null;
      return;
    }
    if (!state.isHumanTurn || state.phase != BgPhase.moving) return;
    // Deep-enough copy for coach eval (lists duplicated in copyWith defaults
    // would alias — rebuild from toJson/fromJson for isolation).
    _practiceTurnStart = BackgammonState.fromJson(state.toJson());
  }

  /// GAI7: compute Hard-AI suggestion for the captured roll and emit to UI.
  void _emitPracticeReviewIfNeeded({required bool humanTurnEnded}) {
    if (!practiceMode || !humanTurnEnded) return;
    final snap = _practiceTurnStart;
    _practiceTurnStart = null;
    if (snap == null) return;
    if (_practiceReviewCtrl.isClosed) return;
    final hint = BackgammonAi.coachHint(
      snap,
      difficulty: GameAiDifficulty.hard,
    );
    _practiceReviewCtrl.add(hint);
  }
}

final backgammonStateProvider =
    NotifierProvider<BackgammonNotifier, BackgammonState>(BackgammonNotifier.new);
