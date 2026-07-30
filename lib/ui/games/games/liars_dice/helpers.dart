import 'dart:math';
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
