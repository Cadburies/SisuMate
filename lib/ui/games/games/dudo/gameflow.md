# Dudo — Game Flow Documentation

**Variant**: Dudo (also Perudo / Cacho). Each player rolls their own set of dice under
a cup. Bids cover dice across ALL players' cups. Aces (1s) are wild for all non-ace bids.
Players lose dice (not counters) on losing a round. Last player with dice wins.

---

## Game Structure

- **Players**: 2–6 (mix of human and AI).
- **Starting dice**: 5 per player.
- **Aces are wild**: A die showing 1 counts toward any non-ace bid.
- **Elimination**: A player with 0 dice is out. Last player standing wins.

---

## Game States & Flow

### 1. Start (`DudoStateEnum.start`)

**Visual**: Player list + "Add AI Player" / "Add Human Player" / "Start Game" buttons.

**Logic**: `startGame()` requires ≥ 2 players. Rolls 1 die per player → `determineStarter`.
A 2-second timer calls `determineStarter()`.

---

### 2. Determine Starter (`DudoStateEnum.determineStarter`)

**Visual**: One die shown per player; highest value starts.

**Logic** (`determineStarter()`):
- Each player already has 1 die from `startGame()`.
- Highest single die → that player becomes `activePlayer`.
- Ties: only tied players re-roll; repeat until clear winner.

**Transition**: → `rollAll` (set `activePlayer = winner`).

---

### 3. Roll All (`DudoStateEnum.rollAll`)

**Description**: All non-eliminated players roll their full set of dice simultaneously.
Dice are hidden from opponents. Human player sees their own dice.

**Visual**: Human's dice shown; other players show `?` dice icons + die count only.

**Logic** (`beginRound()`):
- All non-eliminated players get `rollDice(player.diceCount)`.
- `currentBid` cleared to null.
- `allDiceRevealed = false`.
- A 2-second timer calls `startBidding()`.

**Transition**: → `bidding` (first `activePlayer` must bid; `currentBid == null`).

---

### 4. Bidding (`DudoStateEnum.bidding`)

**Description**: The `activePlayer` takes their turn. If `currentBid == null` they MUST
bid. If `currentBid != null` they can raise, call Dudo, or call Spot On.

**Visual** (human's turn):
- Current bid card at top (or "No bid yet — you go first!").
- Human's own dice shown.
- Quantity dropdown + Face dropdown + **Bid / Raise** button.
- **Dudo!** button (only if `currentBid != null`).
- **Spot On!** button (only if `currentBid != null`).

**Visual** (AI's turn): "Thinking…" message; 2-second timer fires AI action.

**Logic** (`placeBid(DudoBid bid)`):
- Validates `isValidRaise(bid, currentBid, playerDiceCount: player.diceCount)`.
- On valid: `currentBid = bid`, `lastBidder = activePlayer`,
  `activePlayer = nextPlayer(players, activePlayer)`.
- On invalid: updates `gameMessage` only.

**Logic** (`callDudo()`):
- `allDiceRevealed = true`, `currentState = resolveChallenge`.

**Logic** (`callSpotOn()`):
- `allDiceRevealed = true`, `currentState = resolveSpotOn`.

**AI automation** (screen timer):
- If `currentBid == null` → `getAIBid()` → `placeBid()`.
- Else if `getAIShouldSpotOn()` → `callSpotOn()`.
- Else if `getAIShouldDudo()` → `callDudo()`.
- Else → `getAIBid()` → `placeBid()`.

**Transition**: Same state (new `activePlayer`) until Dudo / Spot On.

---

### 5. Resolve Challenge (`DudoStateEnum.resolveChallenge`)

**Description**: Dudo was called. All dice are revealed. Count determines winner.

**Counting rule**:
```
total = Σ(player.dice where d == bid.face)
      + Σ(player.dice where d == 1, only if bid.face != 1)
```

**Resolution**:
- `total >= currentBid.quantity` → bid was valid → **caller (Dudo-caller) loses 1 die**
- `total < currentBid.quantity` → bid was wrong → **lastBidder loses 1 die**

**Visual**: All dice shown per player (revealed). Bid vs actual count. Result message.
Auto-advances (3-second timer) → `determineRoundOver`.

---

### 6. Resolve Spot On (`DudoStateEnum.resolveSpotOn`)

**Description**: Spot On was called. All dice revealed. Exact match check.

**Resolution**:
- `total == currentBid.quantity` → **exact!** → Spot On caller GAINS 1 die (max 5).
- `total != currentBid.quantity` → **wrong** → Spot On caller loses 1 die.
- `lastBidder` never loses a die on Spot On (regardless of outcome).

**Visual**: Same as resolveChallenge. 3-second timer → `determineRoundOver`.

---

### 7. Determine Round Over (`DudoStateEnum.determineRoundOver`)

**Logic** (`determineRoundOver()`):
1. Apply die change (already applied in resolve step).
2. Eliminate players with `diceCount <= 0`.
3. Count non-eliminated players:
   - `<= 1` → `gameOver`.
   - `>= 2` → set `activePlayer` to the player who LOST a die (or their clockwise
     neighbor if they were eliminated). → `rollAll`.

**Transition**: → `gameOver` or → `rollAll`.

---

### 8. Game Over (`DudoStateEnum.gameOver`)

**Visual**: "[Winner] wins!" message. "Play Again" + "Return to Games" buttons.

---

## Key Rules Summary

### Bid Validity (`isValidRaise`)

| Previous bid | New bid type | Rule |
|---|---|---|
| Non-aces (f1 ≠ 1) | Non-aces (f2 ≠ 1) | `q2 > q1` OR `(q2 == q1 AND f2 > f1)` |
| Non-aces | Aces (f2 = 1) | `q2 >= ceil(q1 / 2)` |
| Aces (f1 = 1) | Non-aces | `q2 >= 2 × q1 + 1` |
| Aces | Aces | `q2 > q1` |
| No previous bid | Any | Free; **cannot bid aces unless player has exactly 1 die** |

### Counting Dice

```dart
int countBid(players, bid) {
  return players.where((p) => !p.isEliminated)
    .expand((p) => p.dice)
    .where((d) => d == bid.face || (d == 1 && bid.face != 1))
    .length;
}
```

### After-Round Starter

The player who **lost a die** starts the next round. If that player was eliminated,
the next non-eliminated player clockwise starts.

---

## Implementation Notes

### State

```dart
final dudoGameProvider =
    NotifierProvider<DudoGameNotifier, DudoGameState>(DudoGameNotifier.new);
```

**`DudoGameState` fields**:

| Field | Type | Purpose |
|---|---|---|
| `currentState` | `DudoStateEnum` | Current phase |
| `players` | `List<DudoPlayer>` | All players |
| `activePlayer` | `int` | Whose turn it is |
| `lastBidder` | `int` | Who placed the current bid (challenged in Dudo) |
| `currentBid` | `DudoBid?` | The bid to beat; null at round start |
| `allDiceRevealed` | `bool` | True during resolve phases |
| `gameMessage` | `String?` | Status bar text |
| `isMultiplayer` | `bool` | Future LAN flag |

**`DudoPlayer` fields**:

| Field | Type | Purpose |
|---|---|---|
| `id` | `String` | Unique ID |
| `name` | `String` | Display name |
| `isAI` | `bool` | AI-controlled |
| `dice` | `List<int>` | Current dice values (length == diceCount) |
| `diceCount` | `int` | Number of dice (0 = eliminated) |
| `isConnected` | `bool` | LAN connection status (future) |

**`DudoBid` fields**: `quantity: int`, `face: int` (1 = aces, 2–6 = pips).

### File Paths

| What | Where |
|---|---|
| Game logic + models | `lib/ui/games/games/dudo/logic.dart` |
| Pure functions | `lib/ui/games/games/dudo/helpers.dart` |
| Screen / UI | `lib/ui/games/games/dudo/screen.dart` |
| Unit tests | `test/dudo_test.dart` |

---

## Known Gaps / Future Work

| Gap | Notes |
|---|---|
| No "palafico" / single-die round | Real Perudo (Cacho) rule sets commonly special-case the round(s) after a player is reduced to their last die: aces stop being wild and/or bids may only step up by exactly 1 in quantity for that round (variants differ on whether it applies to just that player's own bids or to the whole table). `isValidRaise`/`countBid` apply the same wild-ace and quantity-jump math regardless of any player's `diceCount`, so this nuance is entirely unimplemented — only the narrower "cannot open a round with an ace bid unless you personally hold exactly 1 die" restriction exists (`isValidRaise`, first-bid branch). Intentionally not fixed here per audit scope; log as a feature gap. |
