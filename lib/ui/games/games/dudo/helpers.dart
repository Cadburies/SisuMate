import 'dart:math';
import '../../../../services/game_ai/game_ai_difficulty.dart';
import '../../../../services/game_ai/game_ai_persona.dart';
import 'logic.dart';

final _rng = Random();

List<int> rollDice(int count) =>
    List.generate(count, (_) => _rng.nextInt(6) + 1);

/// Count dice across all non-eliminated players matching the bid.
/// Aces (face=1) are wild for any non-ace bid — unless [isPalafico], the
/// single-die round variant where aces stop being wild (GB5).
int countBid(List<DudoPlayer> players, DudoBid bid, {bool isPalafico = false}) {
  int total = 0;
  for (final p in players) {
    if (p.isEliminated) continue;
    for (final d in p.dice) {
      if (d == bid.face) {
        total++;
      } else if (d == 1 && bid.face != 1 && !isPalafico) {
        total++;
      }
    }
  }
  return total;
}

/// Returns true when [newBid] is a legal raise over [lastBid].
/// [playerDiceCount] is the bidding player's current die count (first-bid ace rule).
/// [isPalafico]: real Perudo rule — once any player is down to their last
/// die, that round's raises are restricted to the same face, quantity+1
/// only (GB5). The opening bid of the round is unrestricted either way.
bool isValidRaise(DudoBid newBid, DudoBid? lastBid,
    {int playerDiceCount = 5, bool isPalafico = false}) {
  if (newBid.face < 1 || newBid.face > 6 || newBid.quantity < 1) return false;
  if (lastBid == null) {
    // First bid of round: aces forbidden unless player has exactly 1 die.
    if (newBid.face == 1 && playerDiceCount > 1) return false;
    return true;
  }
  if (isPalafico) {
    return newBid.face == lastBid.face && newBid.quantity == lastBid.quantity + 1;
  }
  final isNewAces = newBid.face == 1;
  final isOldAces = lastBid.face == 1;
  if (!isOldAces && !isNewAces) {
    return newBid.quantity > lastBid.quantity ||
        (newBid.quantity == lastBid.quantity && newBid.face > lastBid.face);
  }
  if (!isOldAces && isNewAces) {
    // Non-aces → aces: quantity >= ceil(oldQuantity / 2)
    return newBid.quantity >= (lastBid.quantity + 1) ~/ 2;
  }
  if (isOldAces && !isNewAces) {
    // Aces → non-aces: quantity >= 2 × oldQuantity + 1
    return newBid.quantity >= 2 * lastBid.quantity + 1;
  }
  // Aces → aces: must increase quantity
  return newBid.quantity > lastBid.quantity;
}

String bidToString(DudoBid bid) {
  final q = bid.quantity;
  final faceStr = bid.face == 1 ? (q == 1 ? 'Ace' : 'Aces') : faceLabel(bid.face);
  return '$q $faceStr';
}

String faceLabel(int face) => switch (face) {
      1 => 'Aces',
      2 => 'Twos',
      3 => 'Threes',
      4 => 'Fours',
      5 => 'Fives',
      6 => 'Sixes',
      _ => '$face',
    };

/// Next non-eliminated player index after [from].
int nextPlayer(List<DudoPlayer> players, int from) {
  final n = players.length;
  for (int i = 1; i < n; i++) {
    final idx = (from + i) % n;
    if (!players[idx].isEliminated) return idx;
  }
  return from;
}

// ── GAI4: binomial / Bayesian Dudo AI ────────────────────────────────────────
//
// Unknown dice are modelled as i.i.d. Bernoulli trials that match the bid face
// with p = 1/6 (aces or palafico) or p = 2/6 (normal non-ace: face or wild ace).
// Challenge / spot-on / bid choices use survival and exact binomial mass rather
// than the old integer "others/6" heuristic.

/// P(a single unknown die counts toward [face]).
double dudoDieMatchProbability(int face, {bool isPalafico = false}) {
  if (face < 1 || face > 6) return 0;
  if (isPalafico || face == 1) return 1.0 / 6.0;
  return 2.0 / 6.0;
}

/// Own dice that count toward [face] (aces wild unless palafico / ace bid).
int countOwnMatching(List<int> dice, int face, {bool isPalafico = false}) {
  var n = 0;
  for (final d in dice) {
    if (d == face) {
      n++;
    } else if (d == 1 && face != 1 && !isPalafico) {
      n++;
    }
  }
  return n;
}

int _unknownDiceCount(List<DudoPlayer> players, int aiIndex) {
  final aiId = players[aiIndex].id;
  return players
      .where((p) => !p.isEliminated && p.id != aiId)
      .fold(0, (s, p) => s + p.diceCount);
}

/// C(n, k) via multiplicative formula (double; fine for n ≤ ~40 table dice).
double binomialCoefficient(int n, int k) {
  if (k < 0 || k > n) return 0;
  if (k == 0 || k == n) return 1;
  final kk = k > n - k ? n - k : k;
  var c = 1.0;
  for (var i = 0; i < kk; i++) {
    c *= (n - i);
    c /= (i + 1);
  }
  return c;
}

double binomialPmf(int n, int k, double p) {
  if (k < 0 || k > n) return 0;
  if (p <= 0) return k == 0 ? 1.0 : 0.0;
  if (p >= 1) return k == n ? 1.0 : 0.0;
  return binomialCoefficient(n, k) * pow(p, k) * pow(1 - p, n - k);
}

/// P(X ≥ k) for X ~ Binomial(n, p).
double binomialSurvival(int n, double p, int k) {
  if (k <= 0) return 1.0;
  if (k > n) return 0.0;
  var s = 0.0;
  for (var i = k; i <= n; i++) {
    s += binomialPmf(n, i, p);
  }
  return s.clamp(0.0, 1.0);
}

/// P(table total matching dice ≥ [quantity] | own dice + unknowns).
double dudoBidSurvival(
  List<DudoPlayer> players,
  int aiIndex,
  DudoBid bid, {
  bool isPalafico = false,
}) {
  final ai = players[aiIndex];
  final own = countOwnMatching(ai.dice, bid.face, isPalafico: isPalafico);
  final unknown = _unknownDiceCount(players, aiIndex);
  final needFromUnknown = bid.quantity - own;
  final p = dudoDieMatchProbability(bid.face, isPalafico: isPalafico);
  return binomialSurvival(unknown, p, needFromUnknown);
}

/// P(table total == [quantity]).
double dudoBidExact(
  List<DudoPlayer> players,
  int aiIndex,
  DudoBid bid, {
  bool isPalafico = false,
}) {
  final ai = players[aiIndex];
  final own = countOwnMatching(ai.dice, bid.face, isPalafico: isPalafico);
  final unknown = _unknownDiceCount(players, aiIndex);
  final need = bid.quantity - own;
  final p = dudoDieMatchProbability(bid.face, isPalafico: isPalafico);
  return binomialPmf(unknown, need, p);
}

/// AI: choose a bid. Uses expected matching dice and survival mass; prefers
/// faces well-supported by own dice. Soft bluff only when own support is strong.
///
/// [isPalafico]: under the single-die round variant (GB5), a raise can only
/// be the same face at quantity+1 — forced bid, no search.
///
/// GAI1 [difficulty] = skill; GAI5 [persona] = risk style (orthogonal).
DudoBid getAIBid(List<DudoPlayer> players, int aiIndex, DudoBid? lastBid,
    {bool isPalafico = false,
    GameAiDifficulty difficulty = GameAiDifficulty.normal,
    GameAiPersona persona = GameAiPersona.balanced,
    Random? rng}) {
  if (isPalafico && lastBid != null) {
    return DudoBid(lastBid.quantity + 1, lastBid.face);
  }
  final r = rng ?? _rng;
  final ai = players[aiIndex];
  final int totalDice =
      players.fold(0, (s, p) => p.isEliminated ? s : s + p.diceCount);
  final unknown = _unknownDiceCount(players, aiIndex);

  // GAI1 skill + GAI5 style.
  final bluffBonus = (switch (difficulty) {
        GameAiDifficulty.easy => 0.0,
        GameAiDifficulty.normal => 1.0,
        GameAiDifficulty.hard => 1.6,
      }) +
      persona.bluffBoost;
  final longShotPenalty = (switch (difficulty) {
        GameAiDifficulty.easy => 0.15,
        GameAiDifficulty.normal => 0.35,
        GameAiDifficulty.hard => 0.55,
      }) *
      persona.longShotMul;

  DudoBid? best;
  var bestScore = double.negativeInfinity;
  final scored = <(DudoBid, double)>[];

  for (var face = 1; face <= 6; face++) {
    final p = dudoDieMatchProbability(face, isPalafico: isPalafico);
    final own = countOwnMatching(ai.dice, face, isPalafico: isPalafico);
    final expectedUnknown = unknown * p;
    final expectedTotal = own + expectedUnknown;

    // Candidate quantities: conservative EV, EV rounded, light bluff (+1).
    final candidates = <int>{
      1,
      expectedTotal.floor().clamp(1, totalDice + 2),
      expectedTotal.round().clamp(1, totalDice + 2),
      expectedTotal.ceil().clamp(1, totalDice + 2),
      if (own >= 2) (own + expectedUnknown.floor()).clamp(1, totalDice + 2),
      if (own >= 3 ||
          difficulty == GameAiDifficulty.hard ||
          persona == GameAiPersona.aggressive)
        (expectedTotal.floor() + 1).clamp(1, totalDice + 2),
      // Aggressive / chaos sometimes float a wilder +2 over EV.
      if (persona == GameAiPersona.aggressive || persona == GameAiPersona.chaos)
        (expectedTotal.floor() + 2).clamp(1, totalDice + 2),
    };

    for (final q in candidates) {
      final bid = DudoBid(q, face);
      if (!isValidRaise(bid, lastBid, playerDiceCount: ai.diceCount,
          isPalafico: isPalafico)) {
        continue;
      }
      final survival = binomialSurvival(unknown, p, q - own);
      // Prefer well-supported bids; reward own concentration; penalize long shots.
      final score = survival * 10.0 +
          own * 1.4 +
          (face == 1 ? -0.3 : 0) +
          (q > expectedTotal ? bluffBonus.clamp(0.0, 4.0) * 0.4 : 0) -
          (q - expectedTotal).abs() * longShotPenalty;
      scored.add((bid, score));
      if (score > bestScore) {
        bestScore = score;
        best = bid;
      }
    }
  }

  if (best != null) {
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    // Easy skill OR chaotic persona: occasionally pick near-best.
    final noisy = (difficulty == GameAiDifficulty.easy && r.nextInt(3) == 0) ||
        (persona.noiseChance > 0 && r.nextDouble() < persona.noiseChance);
    if (noisy && scored.length > 1) {
      final poolSize = persona == GameAiPersona.chaos
          ? min(6, scored.length)
          : min(4, scored.length);
      final pool = scored.take(poolSize).toList();
      return pool[r.nextInt(pool.length)].$1;
    }
    return best;
  }

  // Fallback: smallest valid raise scanning quantity then face.
  for (int q = 1; q <= totalDice + 2; q++) {
    for (int f = 1; f <= 6; f++) {
      final bid = DudoBid(q, f);
      if (isValidRaise(bid, lastBid,
          playerDiceCount: ai.diceCount, isPalafico: isPalafico)) {
        return bid;
      }
    }
  }

  if (lastBid == null) return const DudoBid(1, 2);
  return DudoBid(lastBid.quantity + 1,
      lastBid.face >= 6 ? 2 : lastBid.face + 1);
}

/// AI: call Dudo when P(table ≥ bid) is uncomfortably low.
bool getAIShouldDudo(List<DudoPlayer> players, int aiIndex, DudoBid bid,
    {bool isPalafico = false,
    GameAiDifficulty difficulty = GameAiDifficulty.normal,
    GameAiPersona persona = GameAiPersona.balanced}) {
  final survival = dudoBidSurvival(players, aiIndex, bid, isPalafico: isPalafico);
  final ai = players[aiIndex];
  final own = countOwnMatching(ai.dice, bid.face, isPalafico: isPalafico);
  final unknown = _unknownDiceCount(players, aiIndex);
  final p = dudoDieMatchProbability(bid.face, isPalafico: isPalafico);
  final expected = own + unknown * p;

  // Persona challengeBias: positive → call earlier (tight); negative → stick longer.
  final survivalFloor = (switch (difficulty) {
        GameAiDifficulty.easy => 0.28,
        GameAiDifficulty.normal => 0.40,
        GameAiDifficulty.hard => 0.48,
      } +
      persona.challengeBias)
      .clamp(0.12, 0.70);
  final overEv = switch (difficulty) {
    GameAiDifficulty.easy => 2.4,
    GameAiDifficulty.normal => 1.75,
    GameAiDifficulty.hard => 1.25,
  } *
      (persona == GameAiPersona.aggressive
          ? 1.25
          : persona == GameAiPersona.tight
              ? 0.8
              : 1.0);
  final overEvSurv = (switch (difficulty) {
        GameAiDifficulty.easy => 0.45,
        GameAiDifficulty.normal => 0.55,
        GameAiDifficulty.hard => 0.62,
      } +
      persona.challengeBias)
      .clamp(0.25, 0.80);

  if (survival < survivalFloor) return true;
  if (bid.quantity >= expected + overEv && survival < overEvSurv) return true;
  return false;
}

/// AI: Spot On when the exact count is a plausible mode (not a long shot).
bool getAIShouldSpotOn(List<DudoPlayer> players, int aiIndex, DudoBid bid,
    {bool isPalafico = false,
    GameAiDifficulty difficulty = GameAiDifficulty.normal,
    GameAiPersona persona = GameAiPersona.balanced}) {
  // Never spot-on when Dudo is clearly correct.
  if (getAIShouldDudo(players, aiIndex, bid,
      isPalafico: isPalafico, difficulty: difficulty, persona: persona)) {
    return false;
  }
  final exact = dudoBidExact(players, aiIndex, bid, isPalafico: isPalafico);
  final survival = dudoBidSurvival(players, aiIndex, bid, isPalafico: isPalafico);
  // Aggressive spots more often; tight almost never gambles on spot-on.
  final exactMin = (switch (difficulty) {
        GameAiDifficulty.easy => 0.28,
        GameAiDifficulty.normal => 0.20,
        GameAiDifficulty.hard => 0.16,
      } +
      switch (persona) {
        GameAiPersona.aggressive => -0.04,
        GameAiPersona.tight => 0.08,
        GameAiPersona.chaos => -0.02,
        GameAiPersona.balanced => 0.0,
      })
      .clamp(0.08, 0.45);
  // Exact mass high and survival not screaming "too high" or "too low".
  return exact >= exactMin && survival >= 0.35 && survival <= 0.75;
}
