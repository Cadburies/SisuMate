import 'dart:math';
import '../../../../services/game_ai/game_ai_difficulty.dart';
import '../../../../services/game_ai/game_ai_persona.dart';
import 'logic.dart';

final _rng = Random();

DiceRank evaluateHand(List<int> dice) {
  Map<int, int> counts = {};
  for (int d in dice) {
    counts[d] = (counts[d] ?? 0) + 1;
  }

  List<int> sortedDice = [...dice]..sort();

  if (counts.values.any((c) => c == 5)) return DiceRank.fiveOfAKind;
  if (counts.values.any((c) => c == 4)) return DiceRank.fourOfAKind;
  if (counts.length == 2 && counts.values.contains(3)) return DiceRank.fullHouse;
  if (_isStraightHigh(sortedDice)) return DiceRank.straightHigh;
  if (_isStraightLow(sortedDice)) return DiceRank.straightLow;
  if (counts.values.any((c) => c == 3)) return DiceRank.threeOfAKind;
  if (counts.values.where((c) => c == 2).length == 2) return DiceRank.twoPair;
  if (counts.values.any((c) => c == 2)) return DiceRank.onePair;
  return DiceRank.highCard;
}

bool _isStraightHigh(List<int> dice) => dice.join() == '23456';
bool _isStraightLow(List<int> dice) => dice.join() == '12345';

int compareBids(Bid a, Bid b) {
  if (a.rank.index < b.rank.index) return 1;
  if (a.rank.index > b.rank.index) return -1;
  return a.face.compareTo(b.face);
}

bool isValidBid(Bid newBid, Bid? lastBid) {
  return lastBid == null || compareBids(newBid, lastBid) == 1;
}

List<int> rollDice() {
  return List.generate(5, (_) => _rng.nextInt(6) + 1);
}

List<int> rollDiceWithHolds(List<int> currentDice, List<bool> holds) {
  return List.generate(5, (i) => holds[i] ? currentDice[i] : _rng.nextInt(6) + 1);
}

/// Simple hold strategy for the AI's roll: keep whichever face forms the
/// largest group in [dice] (ties broken by the higher face value), reroll
/// the rest. Returns all-false (reroll everything) if no face appears more
/// than once. Deliberately simple — doesn't attempt straight completion —
/// matching a human's most obvious move (keep the pair/trips you already
/// have) rather than optimal play.
List<bool> bestHoldMask(List<int> dice) {
  final counts = <int, int>{};
  for (final d in dice) {
    counts[d] = (counts[d] ?? 0) + 1;
  }
  int bestFace = 0;
  int bestCount = 1;
  for (final entry in counts.entries) {
    if (entry.value > bestCount ||
        (entry.value == bestCount && entry.key > bestFace)) {
      bestFace = entry.key;
      bestCount = entry.value;
    }
  }
  if (bestCount < 2) return List.filled(5, false);
  return dice.map((d) => d == bestFace).toList();
}

String rankToString(DiceRank rank) {
  return switch (rank) {
    DiceRank.fiveOfAKind => 'Five of a Kind',
    DiceRank.fourOfAKind => 'Four of a Kind',
    DiceRank.fullHouse => 'Full House',
    DiceRank.straightHigh => 'Straight (2-6)',
    DiceRank.straightLow => 'Straight (1-5)',
    DiceRank.threeOfAKind => 'Three of a Kind',
    DiceRank.twoPair => 'Two Pair',
    DiceRank.onePair => 'One Pair',
    DiceRank.highCard => 'High Card',
  };
}

String faceToString(int face) {
  return switch (face) {
    1 => 'Aces',
    2 => 'Twos',
    3 => 'Threes',
    4 => 'Fours',
    5 => 'Fives',
    6 => 'Sixes',
    _ => '$face',
  };
}

// ── GAI4: prior / escalation Liar's Dice AI ──────────────────────────────────
//
// Each player holds private 5d6 "poker dice". Challenges reason about how
// rare a claimed rank is a priori, how far it sits above our visible hand,
// and how many escalations already happened in the bid history.

/// Approximate P(roll this rank) on 5 fair d6 (poker-dice combinatorics;
/// the two straight ranks split the usual combined straight mass).
const Map<DiceRank, double> liarDiceRankPrior = {
  DiceRank.fiveOfAKind: 6 / 7776,
  DiceRank.fourOfAKind: 150 / 7776,
  DiceRank.fullHouse: 300 / 7776,
  DiceRank.straightHigh: 120 / 7776,
  DiceRank.straightLow: 120 / 7776,
  DiceRank.threeOfAKind: 1200 / 7776,
  DiceRank.twoPair: 1800 / 7776,
  DiceRank.onePair: 3600 / 7776,
  DiceRank.highCard: 480 / 7776,
};

/// Pure AI bid: honest rank when it clears [lastBid]; otherwise the *least
/// rare* valid bluff rank (still min face within that rank — F7).
///
/// GAI1 [difficulty]: Easy may under-escalate; Hard bluffs with slightly
/// higher-face pressure when forced.
/// GAI5 [persona]: Aggressive presses higher faces/ranks; Tight stays honest;
/// Chaos samples near-best legal bids.
Bid computeLiarDiceAiBid(
  List<int> myDice,
  Bid? lastBid, {
  GameAiDifficulty difficulty = GameAiDifficulty.normal,
  GameAiPersona persona = GameAiPersona.balanced,
  Random? rng,
}) {
  final myRank = evaluateHand(myDice);
  final r = rng ?? _rng;

  // 1) Honest path: own rank first (min face), then minimal escalations.
  // Easy skill or chaos sometimes starts one rank worse (noisier play).
  // Tight never under-escalates deliberately.
  final underEscalate = persona != GameAiPersona.tight &&
      myRank.index < DiceRank.values.length - 1 &&
      ((difficulty == GameAiDifficulty.easy && r.nextInt(4) == 0) ||
          (persona == GameAiPersona.chaos && r.nextInt(3) == 0));
  final startRankIndex = underEscalate ? myRank.index + 1 : myRank.index;

  // Collect honest-path candidates for chaos / noise sampling.
  final honest = <Bid>[];
  for (var ri = startRankIndex; ri >= 0; ri--) {
    for (var face = 1; face <= 6; face++) {
      final bid = Bid(DiceRank.values[ri], face);
      if (!isValidBid(bid, lastBid)) continue;
      honest.add(bid);
      // Aggressive: prefer higher faces within the honest rank first.
      if (persona == GameAiPersona.aggressive) continue;
      // Tight/balanced: first legal (min face) wins.
      if (persona != GameAiPersona.chaos) return bid;
    }
    if (persona == GameAiPersona.aggressive && honest.isNotEmpty) {
      // Take the highest-face honest bid of this rank (press).
      return honest.last;
    }
  }
  if (honest.isNotEmpty) {
    if (persona.noiseChance > 0 && r.nextDouble() < persona.noiseChance) {
      return honest[r.nextInt(min(honest.length, 4))];
    }
    return honest.first;
  }

  // 2) Forced pure bluff past every better rank than our hand (lastBid very
  // high). Among remaining valid (rank, face) pairs, prefer higher prior
  // mass so the bluff is as "believable" as possible, then lowest face.
  final scored = <(Bid, double)>[];
  Bid? best;
  var bestScore = double.negativeInfinity;
  for (final rank in DiceRank.values) {
    final prior = liarDiceRankPrior[rank] ?? 0.01;
    for (var face = 1; face <= 6; face++) {
      final bid = Bid(rank, face);
      if (!isValidBid(bid, lastBid)) continue;
      // Higher prior better; lower face slightly preferred (hard: less face bias).
      // Aggressive: higher face rewarded (bluff pressure); tight: min face.
      final faceWeight = switch ((difficulty, persona)) {
        (_, GameAiPersona.aggressive) => -0.02, // prefer higher face
        (_, GameAiPersona.tight) => 0.02,
        (GameAiDifficulty.hard, _) => 0.002,
        _ => 0.01,
      };
      final score = prior * 1000.0 - face * faceWeight;
      scored.add((bid, score));
      if (score > bestScore) {
        bestScore = score;
        best = bid;
      }
    }
  }
  if (best != null &&
      scored.length > 1 &&
      persona.noiseChance > 0 &&
      r.nextDouble() < persona.noiseChance) {
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    final pool = scored.take(min(5, scored.length)).toList();
    return pool[r.nextInt(pool.length)].$1;
  }
  return best ?? const Bid(DiceRank.fiveOfAKind, 6);
}

/// Pure AI accept/challenge. [rng] injectable for tests.
///
/// Returns `true` to accept, `false` to challenge.
bool computeLiarDiceAiAccept({
  required Bid declared,
  required List<int> myDice,
  List<Bid> bidHistory = const [],
  Random? rng,
  GameAiDifficulty difficulty = GameAiDifficulty.normal,
  GameAiPersona persona = GameAiPersona.balanced,
}) {
  final random = rng ?? _rng;
  final myRank = evaluateHand(myDice);

  // rankDiff > 0 ⇒ declared is better (lower index) than our hand.
  final rankDiff = myRank.index - declared.rank.index;
  if (rankDiff <= 0) return true;

  final prior = liarDiceRankPrior[declared.rank] ?? 0.05;
  // Each prior raise in the history makes a high claim less trustworthy.
  final escalations = bidHistory.length.clamp(0, 6);
  final effectivePrior = prior * pow(0.72, escalations);

  // Tight challenges earlier (smaller gap); aggressive lets more slide.
  final hardRankDiff = (switch (difficulty) {
        GameAiDifficulty.easy => 4,
        GameAiDifficulty.normal => 3,
        GameAiDifficulty.hard => 2,
      } +
      switch (persona) {
        GameAiPersona.aggressive => 1,
        GameAiPersona.tight => -1,
        GameAiPersona.chaos => 0,
        GameAiPersona.balanced => 0,
      })
      .clamp(1, 5);

  // Hard challenges: far above us, or inherently rare (incl. after history).
  if (rankDiff >= hardRankDiff || prior < 0.02 || effectivePrior < 0.012) {
    return false;
  }

  // Small, common escalation → mostly trust; mid-range → flatter default.
  // History nudges challenge rate up slightly without breaking F7 rarity.
  final challengeBias = (switch (difficulty) {
        GameAiDifficulty.easy => -8, // accept more
        GameAiDifficulty.normal => 0,
        GameAiDifficulty.hard => 10, // challenge more
      } +
      // persona.challengeBias is ±0.1-ish; scale to percentage points.
      (persona.challengeBias * 100).round());
  if (rankDiff == 1 && prior > 0.1) {
    final challengePct = 15 + escalations * 3 + challengeBias;
    return random.nextInt(100) >= challengePct.clamp(8, 50);
  }
  // Chaos: extra coin-flip on mid-range accepts.
  if (persona == GameAiPersona.chaos && random.nextInt(5) == 0) {
    return random.nextBool();
  }
  final challengePct = 30 + escalations * 4 + challengeBias;
  return random.nextInt(100) >= challengePct.clamp(20, 65);
}
