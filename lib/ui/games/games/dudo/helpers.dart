import 'dart:math';
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

/// AI: choose a bid. Estimates total = own matching dice + (others' dice / 6).
/// [isPalafico]: under the single-die round variant (GB5), a raise can only
/// be the same face at quantity+1, so there's no real choice to estimate —
/// the AI just plays that forced bid. The opening bid of the round is
/// unaffected and still uses the normal estimation.
DudoBid getAIBid(List<DudoPlayer> players, int aiIndex, DudoBid? lastBid,
    {bool isPalafico = false}) {
  if (isPalafico && lastBid != null) {
    return DudoBid(lastBid.quantity + 1, lastBid.face);
  }
  final ai = players[aiIndex];
  final int totalDice =
      players.fold(0, (s, p) => p.isEliminated ? s : s + p.diceCount);
  final int unknownDice = totalDice - ai.diceCount;

  int ownAces = ai.dice.where((d) => d == 1).length;

  // Try faces 2–6: estimate and take first valid conservative bid.
  for (int face = 2; face <= 6; face++) {
    final ownForFace = ai.dice.where((d) => d == face).length + ownAces;
    final estimated = (ownForFace + unknownDice ~/ 6).clamp(1, 99);
    final bid = DudoBid(estimated, face);
    if (isValidRaise(bid, lastBid, playerDiceCount: ai.diceCount)) return bid;
  }

  // Fallback: smallest valid raise scanning quantity then face.
  for (int q = 1; q <= totalDice + 2; q++) {
    for (int f = 2; f <= 6; f++) {
      final bid = DudoBid(q, f);
      if (isValidRaise(bid, lastBid, playerDiceCount: ai.diceCount)) return bid;
    }
  }

  if (lastBid == null) return const DudoBid(1, 2);
  return DudoBid(lastBid.quantity + 1,
      lastBid.face >= 6 ? 2 : lastBid.face + 1);
}

/// AI: should call Dudo? Challenge when estimated count < bid quantity.
bool getAIShouldDudo(List<DudoPlayer> players, int aiIndex, DudoBid bid,
    {bool isPalafico = false}) {
  final ai = players[aiIndex];
  int ownCount = 0;
  for (final d in ai.dice) {
    if (d == bid.face) { ownCount++; }
    else if (d == 1 && bid.face != 1 && !isPalafico) { ownCount++; }
  }
  final int othersDice = players
      .where((p) => p != ai && !p.isEliminated)
      .fold(0, (s, p) => s + p.diceCount);
  final estimated = ownCount + (othersDice / 6).ceil();
  return estimated < bid.quantity;
}

/// AI: should call Spot On? Only when estimated count exactly matches bid.
bool getAIShouldSpotOn(List<DudoPlayer> players, int aiIndex, DudoBid bid,
    {bool isPalafico = false}) {
  final ai = players[aiIndex];
  int ownCount = 0;
  for (final d in ai.dice) {
    if (d == bid.face) { ownCount++; }
    else if (d == 1 && bid.face != 1 && !isPalafico) { ownCount++; }
  }
  final int othersDice = players
      .where((p) => p != ai && !p.isEliminated)
      .fold(0, (s, p) => s + p.diceCount);
  final estimated = ownCount + (othersDice / 6).round();
  return estimated == bid.quantity;
}
