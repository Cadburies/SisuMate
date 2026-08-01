# 📜 Backgammon – Game Flow Documentation

This document describes the complete game flow for Backgammon in the SisuMate app. It covers all game states, UI interactions, rules, edge cases, and implementation details. It aligns with the Viking-themed aesthetic and single-player (human vs. AI) focus of the current implementation. The document is written so that an AI programmer could implement the game from scratch using it alone.

## Game Structure

- **Players**: 2 — Human (white) vs. AI (black).
- **Modes**: Single-player only (human vs. AI). Multiplayer is not yet implemented.
- **Rounds**: A single game. No round structure — the game ends when one player bears off all 15 pieces.
- **Focus**: One active player at a time. Human and AI alternate turns; the human always goes first.
- **Board**: 24 points, numbered 1–24. Represented internally as indices 0–23 (`board[i]` where `i+1` = point number).
  - **Human (white)**: moves from point 24 → point 1 (index 23 → 0). Home board: points 1–6 (indices 0–5).
  - **AI (black)**: moves from point 1 → point 24 (index 0 → 23). Home board: points 19–24 (indices 18–23).
  - `board[i] > 0`: human pieces on that point. `board[i] < 0`: AI pieces.
- **Bar**: Pieces hit by the opponent are placed on the bar (`humanBar` / `aiBar`). A player with pieces on the bar must re-enter before making any other move.
- **Bearing Off**: When all 15 of a player's pieces are in their home board (and none on the bar), that player may bear off pieces by rolling and removing them from the board. First player to bear off all 15 wins.
- **Dice**: Standard 6-sided dice. On doubles, the player gets 4 moves (not 2). Tracked as `movesLeft`.
- **UI Elements**:
  - **Board Display**: 24 points shown with piece stacks. Bar shown separately. Borne-off pieces counted.
  - **Game Message**: Displays instructions, roll results, and move prompts.
  - **Roll Button**: Visible only on the human's turn during the `rolling` phase.
  - **Point Selection**: Human taps a point (or bar icon) to select a piece, then taps destination.
- **Viking Theme**: Carved wooden board, rune-etched pieces (white for human, black for AI), Norse-styled dice, longship-deck background. Animations for rolling dice (runes spinning) and hitting blots (thunderclap).

---

## Game States & Flow

### 1. Start of Game

**Description**: Initialize the board with the standard backgammon setup and prepare for the human's first roll.

**Visual State**:

- Board displays the standard 15-vs-15 starting arrangement:
  - Human (white): 2 on point 24, 5 on point 13, 3 on point 8, 5 on point 6.
  - AI (black): 2 on point 1, 5 on point 12, 3 on point 17, 5 on point 19.
- Bar area: empty (0 pieces on bar for both sides).
- Borne-off trays: both empty (0/15).
- Game message: `'Tap "Roll" to start your turn.'`
- `phase` = `BgPhase.rolling`, `isHumanTurn` = `true`.

**Visible UI Elements**:

- "Roll" button (enabled — human's turn, rolling phase).
- Board with all 24 points drawn. Bar area visible but empty.
- Borne-off counters: both at 0.

**Available Actions**:

- Human taps "Roll" to roll their dice and begin the first turn.

**Logic**:

- `BackgammonNotifier.build()` returns the initial state using `_initialBoard()`.
- Initial board (index → piece count):
  - `board[23] = 2` (point 24, human)
  - `board[12] = 5` (point 13, human)
  - `board[7] = 3` (point 8, human)
  - `board[5] = 5` (point 6, human)
  - `board[0] = -2` (point 1, AI)
  - `board[11] = -5` (point 12, AI)
  - `board[16] = -3` (point 17, AI)
  - `board[18] = -5` (point 19, AI)
- All other fields start at zero. `dice = []`, `movesLeft = []`.

**Transition**: Human taps "Roll" → move to state 2 (Roll Dice).

---

### 2. Roll Dice

**Description**: The active player (human or AI) rolls two dice. On doubles, four moves are granted instead of two.

**Visual State**:

- **Human's Turn**:
  - Dice animation plays (2 dice spinning, 0.3–0.5 seconds).
  - Game message updates to: `'Rolled $d1, $d2. Select a piece to move.'`
  - Roll button disappears; board becomes interactive.
- **AI's Turn**:
  - AI roll triggered automatically with a 300 ms delay after the human's turn ends.
  - Game message: `'AI rolled $d1, $d2.'`
  - Board is non-interactive (no human input accepted during AI turn).

**Visible UI Elements**:

- **Human's Turn** (before tap): "Roll" button visible and enabled.
- **After roll**: "Roll" button hidden. Board points become tappable.
- **AI's Turn**: No buttons. Board non-interactive.

**Available Actions**:

- **Human**: Tap "Roll" button.
- **AI**: Automatic (no human action required).

**Logic**:

```dart
void roll() {
  if (state.phase != BgPhase.rolling) return;
  final d1 = _rng.nextInt(6) + 1;
  final d2 = _rng.nextInt(6) + 1;
  final dice = [d1, d2];
  final moves = d1 == d2 ? [d1, d1, d1, d1] : [d1, d2];
  // phase → BgPhase.moving
  if (!state.isHumanTurn) {
    Future.delayed(600ms, _aiMove);
  }
}
```

- Doubles: `movesLeft = [d, d, d, d]` (four uses of that die value).
- Non-doubles: `movesLeft = [d1, d2]`.
- `dice` stores the raw two dice values for display.
- `movesLeft` is consumed one entry at a time as moves are made.

**Transition**: After roll, `phase` → `BgPhase.moving`. Proceed to state 3 (Make Move).

---

### 3. Make Move (Human)

**Description**: The human selects a piece (from the board or from the bar) and taps a valid destination. Each die value must be used separately. All dice must be used if any legal move exists.

**Visual State**:

- Board is fully interactive.
- If `humanBar > 0`, the bar area is highlighted as the mandatory source.
- After tapping a piece: that point is highlighted (selected state), valid destination points are highlighted in a different color.
- Game message: `'Piece selected. Tap destination.'` or `'Bar selected. Choose destination.'`
- After each sub-move: `'Move again ($remaining left).'`
- After all moves consumed or no moves possible: transitions to AI's turn.

**Visible UI Elements**:

- Board points: tappable.
- Bar indicator: tappable when `humanBar > 0`.
- No "Roll" button (we are in `BgPhase.moving`).
- Selected point shown with highlight ring.
- Valid destinations shown with target indicators.

**Available Actions**:

- Tap an unselected human piece → select it (sets `selectedPoint`).
- Tap a valid destination → execute the move.
- Tap an invalid destination → deselect or re-select a different piece.
- If `humanBar > 0`, tapping any non-bar point as source is ignored until bar is cleared.

**Logic**:

`selectPoint(int pointIdx)` is the entry point. `pointIdx == -1` means the bar.

Step-by-step:

1. If no piece is selected yet:
   - If `humanBar > 0`, only `pointIdx == -1` (bar) is accepted as source. Any other tap is ignored.
   - Otherwise, the tapped point must have `board[pointIdx] > 0` (a human piece).
   - Sets `selectedPoint = pointIdx`.

2. If a piece is already selected (`selectedPoint != null`):
   - For each die value in `movesLeft`, call `validHumanMoves(state, from, die)`.
   - If the tapped `pointIdx` appears in any die's valid destinations, call `_executeHumanMove(from, dest, die)`.
   - If no die value makes the tap valid, try to re-select the tapped point as a new source (if it has a human piece), or deselect.

`validHumanMoves(BackgammonState s, int from, int die)`:

- Returns `[]` if `movesLeft` does not contain `die`.
- If `humanBar > 0` and `from != -1`: returns `[]` (must play from bar).
- **Bar re-entry** (`from == -1`): destination = `24 - die` (index). Blocked if `board[dest] <= -2` (AI has 2+ pieces there). Returns `[dest]` if valid.
- **Normal move**: `dest = from - die` (human moves toward index 0).
  - If `humanAllHome()` and `dest < 0`: returns `[-2]` (bear-off signal).
  - If `dest < 0`: returns `[]` (can't move, not yet in bearing-off phase).
  - If `board[dest] <= -2`: returns `[]` (blocked by AI prime).
  - Otherwise: returns `[dest]`.

`_executeHumanMove(int from, int to, int die)`:

1. Remove piece from source: if `from == -1` → `humanBar--`, else `board[from]--`.
2. If `to == -2`: bear off → `humanBornOff++`.
3. Otherwise:
   - If `board[to] == -1` (AI blot): hit it → `board[to] = 0`, `aiBar++`.
   - `board[to]++` (place human piece).
4. Remove `die` from `movesLeft`.
5. If `humanBornOff == 15`: game over (human wins). See state 6.
6. If `movesLeft.isEmpty` or no legal move remains (`!_humanHasMove(...)`):
   - Switch to AI turn: `isHumanTurn = false`, `phase = BgPhase.rolling`.
   - Auto-trigger `roll()` after 300 ms delay.
7. Otherwise: stay in `BgPhase.moving`, update message with remaining dice.

`_humanHasMove(BackgammonState s)`:
- Iterates all die values in `movesLeft.toSet()`.
- If `humanBar > 0`: checks `validHumanMoves(s, -1, die)` for each die.
- Otherwise: checks all points 0–23 where `board[i] > 0`.
- Returns `true` if any valid move exists.

**Bearing Off rules (human)**:

- Prerequisite: `humanAllHome()` — all 15 human pieces in indices 0–5 AND `humanBar == 0`.
- `humanAllHome()` checks `board[6..23]` for any `> 0` values and checks `humanBar == 0`.
- Valid bearing-off roll: die value equals the piece's point index+1 (exact match) OR die value is higher than the highest occupied home point (bear off the highest piece).
- In code: `dest = from - die`. If `dest == -1` (exact) and `humanAllHome()` → returns `[-2]` unconditionally. If `dest < -1` (overshoot), also checks `board[from+1..5]` for any occupied higher point — if one exists, the overshoot is rejected (`[]`) since that higher piece must be moved/borne off first.

**Transition**:

- All dice used (or no moves possible) → state 4 (AI's Turn — Roll Dice).
- `humanBornOff == 15` → state 6 (Game Over).

---

### 4. AI Turn — Roll & Move

**Description**: The AI automatically rolls, then greedily plays all its dice using a priority-scored move selection. AI moves execute with a short animation delay so the human can follow the action.

**Visual State**:

- Roll button is hidden (not human's turn).
- Board non-interactive.
- Game message: `'AI rolled $d1, $d2.'` then shows AI moves happening (piece animations on board).
- After all AI moves: `'Your turn. Tap Roll.'`

**Visible UI Elements**:

- Board with AI piece animations.
- No buttons.

**Available Actions**:

- None for the human during AI turn.

**Logic**:

`_aiMove()` is called after AI roll completes:

1. Copies board, `aiBar`, `aiBornOff`, `humanBar`, `movesLeft` into local mutable variables.
2. Greedy loop: while `movesLeft` is not empty and at least one move was made last iteration:
   - For each unique die value in `movesLeft.toSet()`:
     - Call `_bestAiMove(tempState, die)`.
     - If a move `(from, to)` is returned, apply it:
       - `from == -1`: `aiBar--`; else `board[from]++` (AI pieces are negative, so `++` removes one).
       - `to == -2`: `aiBornOff++`; else if `board[to] == 1` → hit human blot: `board[to] = 0`, `humanBar++`; then `board[to]--`.
       - Remove `die` from `movesLeft`.
       - Break inner loop and restart outer loop.

`validAiMoves(BackgammonState s, int from, int die)`:

- Returns `[]` if `movesLeft` does not contain `die`.
- If `aiBar > 0` and `from != -1`: returns `[]` (must enter from bar).
- **Bar re-entry** (`from == -1`): destination = `die - 1` (index, since AI enters at point die = index die-1). Blocked if `board[dest] >= 2`.
- **Normal move**: `dest = from + die` (AI moves toward index 23).
  - If `aiAllHome()` and `dest > 23`: `dest == 24` (exact) is always valid → `[-2]`. `dest > 24` (overshoot) additionally checks `board[18..from-1]` for an occupied lower/further-back point, rejecting the move (`[]`) if one exists — mirrors the human-side overshoot check (fixed 2026-07-15).
  - If `dest > 23` and not all home: returns `[]`.
  - If `board[dest] >= 2`: returns `[]` (blocked by human prime).
  - Otherwise: returns `[dest]`.

`_bestAiMove(BackgammonState s, int die)`:

- Builds list of all valid `(from, to)` tuples.
- Sorts by `_aiMoveScore`: bear off (10) > hit blot (8) > advance into home (5) > advance (to index value).
- Returns the highest-scoring move, or `null` if none.

`aiAllHome()` checks `board[0..17]` for any `< 0` values and `aiBar == 0`.

After all dice are consumed or no moves remain:

- If `aiBornOff == 15`: game over (AI wins). See state 6.
- Otherwise: switch to human turn. `isHumanTurn = true`, `phase = BgPhase.rolling`, message = `'Your turn. Tap Roll.'`

**Transition**:

- `aiBornOff == 15` → state 6 (Game Over).
- Otherwise → state 2 (Roll Dice) for the human.

---

### 5. Bearing Off

**Description**: When a player has all 15 pieces in their home board (and no pieces on the bar), they may bear off pieces using dice rolls. Bearing off is integrated into the normal move flow, not a separate phase.

**Visual State**:

- Board shows all human pieces clustered in points 1–6 (or AI pieces in 19–24).
- Borne-off tray for the bearing-off player shows increasing piece count.
- Game message: `'All pieces home — you can bear off!'` (displayed automatically when conditions are met).

**Visible UI Elements**:

- Same as state 3 (Make Move). Borne-off tray becomes prominent.
- Tapping the borne-off tray area (or a piece with no valid non-bearing destination) triggers bear-off.

**Available Actions**:

- Tap a piece, then tap the borne-off area (displayed as destination `to == -2`).

**Logic**:

- Exact match: if a piece is on point X and the die value equals X, it may be borne off exactly.
- Overshoot: a die larger than needed may only bear off from the highest occupied point — if a checker remains on any higher point, that overshoot is rejected and the higher checker must move/bear off first.
- In code: `dest = from - die`. `dest == -1` (exact) is always valid once `humanAllHome()`. `dest < -1` (overshoot) additionally checks `board[from+1..5]` for an occupied higher point, rejecting the move if one exists (fixed 2026-07-15 — history in `.ai_context/archive/changelog-full-through-2026-07-16.md`; previously any overshoot was accepted unconditionally).
- Bear-off advances `humanBornOff` or `aiBornOff` by 1.
- At 15 borne off: game over.

**Transition**: Integrated into states 3 and 4. When `humanBornOff == 15` or `aiBornOff == 15` → state 6 (Game Over).

---

### 6. Game Over

**Description**: One player has borne off all 15 pieces. Display the result and offer replay options.

**Visual State**:

- Board freezes in its final state.
- Game message: `'You win! All pieces borne off.'` (human wins) or `'AI wins! All pieces borne off.'` (AI wins).
- Victory overlay or animation (Viking-themed: northern lights or a longship sailing away for human win; storm clouds for AI win).
- Final borne-off counters: winner shows 15, loser shows their remaining count.

**Visible UI Elements**:

- "Play Again" button (resets via `newGame()`).
- "Return to Menu" button (navigates back to games list).
- No Roll button, no board interaction.

**Available Actions**:

- Tap "Play Again" → calls `notifier.newGame()`, returns to state 1 with a fresh board.
- Tap "Return to Menu" → navigate to the games hub screen.

**Logic**:

- `phase` = `BgPhase.gameOver`.
- Win is detected inside `_executeHumanMove` or `_aiMove` when `humanBornOff == 15` or `aiBornOff == 15`.
- `newGame()` calls `build()` which re-initializes the full state.
- No scoring beyond win/loss is tracked in the current implementation.

**Transition**: "Play Again" → state 1 (Start of Game).

---

## Key Game Rules Summary

### Board Layout

| Player | Direction | Home Board | Bar Re-entry Zone |
|--------|-----------|------------|-------------------|
| Human (white) | Point 24 → 1 (index 23 → 0) | Points 1–6 (indices 0–5) | Points 25-die (index 24-die) |
| AI (black) | Point 1 → 24 (index 0 → 23) | Points 19–24 (indices 18–23) | Point die (index die-1) |

### Initial Setup

| Point | Human pieces | AI pieces |
|-------|-------------|-----------|
| 24 (index 23) | 2 | — |
| 13 (index 12) | 5 | — |
| 8 (index 7) | 3 | — |
| 6 (index 5) | 5 | — |
| 1 (index 0) | — | 2 |
| 12 (index 11) | — | 5 |
| 17 (index 16) | — | 3 |
| 19 (index 18) | — | 5 |

### Movement Rules

- A point is **open** if it has 0 or 1 opponent pieces, or any number of your own.
- A point is **blocked** if the opponent has 2 or more pieces there. You cannot land on a blocked point. (Note: a "prime" formally refers to 6 consecutive blocked points forming a wall the opponent cannot cross — a single blocked point is not itself a prime; the term is used loosely elsewhere in this doc to mean "blocked by 2+ opponent pieces.")
- A **blot** is a single opponent piece on a point. Landing on a blot hits it: the blot goes to the bar, your piece takes the point.
- **Bar re-entry is mandatory**: if you have pieces on the bar, you must play from the bar first. You cannot move any board piece while you have pieces on the bar.
- **Doubles**: roll doubles → get 4 moves of that die value (e.g., rolling 3-3 gives four moves of 3).
- If a die roll produces no legal move (all destinations blocked), that die is forfeited. If neither die can be played, the turn is skipped.
- If only one of two dice can be played, the player must play whichever die results in a legal move. If both are playable but only one can actually be used, the player must use the higher die.

### Bearing Off Rules

- **Prerequisite**: All 15 of your pieces must be in your home board (no pieces on the bar or outside).
- **Exact match**: roll a die equal to a piece's point — remove that piece.
- **Overshoot**: no piece on the exact point → remove from the highest occupied home point that is lower than the die value.
- **Can't overshoot inward**: if there is a piece on a higher point than the die value, you must move it inward, not bear off.

### Win Condition

First player to bear off all 15 pieces wins. No gammon/backgammon distinction in the current implementation.

### Turn Order

1. Human rolls (state 2).
2. Human makes moves, one die at a time (state 3).
3. Turn passes to AI.
4. AI rolls and auto-moves (state 4).
5. Turn passes back to human.
6. Repeat until a player bears off all 15 (state 6).

---

## Enhancements & Edge Cases

### No Legal Move

- If after rolling there is no legal move for any die, the turn is automatically passed.
- Detected by `_humanHasMove()` returning `false` after consuming each die.
- In the human's case: if the first die produces no move and the second die also produces no move, the turn is passed silently with a message explaining this.
- For AI: the `_aiMove()` greedy loop naturally handles this — if `_bestAiMove()` returns `null` for all dice, the loop exits and the turn passes.

### Forced Die Choice

- Standard backgammon rule: if only one of two dice is playable, that die must be used.
- If both dice are playable but only one can be used (no further moves after the first), the higher-value die must be used.
- The current implementation does not yet enforce the "must use higher die" rule in ambiguous cases — this is a known limitation (see Implementation Notes).

### Hitting on the Bar

- A human piece hit by the AI (`board[to] == -1` for AI blot detection: `board[to] == 1`) goes to `humanBar`.
- A human piece cannot move while `humanBar > 0`. `selectPoint` ignores non-bar source taps.
- Bar re-entry: `dest = 24 - die`. If `board[dest] <= -2`, blocked. If `board[dest] == -1`, hit that AI blot in turn.

### Closed Board / Cannot Enter

- If the opponent has a prime (6 consecutive blocked points covering all entry points), a player on the bar cannot re-enter.
- The player's turn is skipped automatically (no valid bar entry moves).
- Message should inform the user: `'No entry available. Turn skipped.'`

### Bearing Off with Pieces on Higher Points

- While bearing off, if you roll a 6 but have no piece on point 6, and you also have a piece on point 5, you must move that piece (from 5 to 4-die = inward) not bear it off, unless there is no piece on any higher point than the die.
- Enforced in code (fixed 2026-07-15): an overshoot (`dest < -1` for human, `dest > 24` for AI) is rejected if a checker remains on a higher/further-back point; exact bear-off is always allowed. Both `validHumanMoves` and `validAiMoves` implement this identically.

### Doubles Exhaustion

- All 4 moves from doubles must be played if legal moves exist.
- Each `movesLeft.remove(die)` call removes one entry, leaving 3, 2, 1, 0 remaining.
- If only 3 of 4 are playable, the last is forfeited silently.

### AI Behavior Notes

- AI prioritizes: bear off (10 pts) > hit human blot (8 pts) > advance into home board (5 pts) > advance toward home (destination index value).
- AI does not look ahead beyond one move. It is a greedy heuristic, not a full minimax.
- Doubling cube (GB7): offer before roll when centered/owned; accept multiplies stake and flips ownership; decline ends game at current stake. AI accepts unless human is clearly ahead; may offer when ahead.

---

## Implementation Notes

### State Management Fields (`BackgammonState`)

| Field | Type | Description |
|-------|------|-------------|
| `board` | `List<int>` (24) | Piece counts per point. Positive = human, negative = AI. |
| `humanBar` | `int` | Human pieces on the bar. |
| `aiBar` | `int` | AI pieces on the bar. |
| `humanBornOff` | `int` | Human pieces borne off (win at 15). |
| `aiBornOff` | `int` | AI pieces borne off (win at 15). |
| `dice` | `List<int>` | The two dice values rolled this turn (display only). |
| `movesLeft` | `List<int>` | Die values remaining to be used this turn. |
| `isHumanTurn` | `bool` | `true` = human's turn, `false` = AI's turn. |
| `selectedPoint` | `int?` | `-1` = bar selected, `0–23` = board index, `null` = nothing selected. |
| `phase` | `BgPhase` | `rolling`, `moving`, or `gameOver`. |
| `message` | `String` | Current instruction/status string for the UI. |

### BgPhase Enum

```dart
enum BgPhase { rolling, moving, gameOver }
```

### Provider

```dart
final backgammonStateProvider =
    NotifierProvider<BackgammonNotifier, BackgammonState>(BackgammonNotifier.new);
```

### UI Logic Snippets

```dart
// Show Roll button only when it is the human's turn and we are in the rolling phase
bool shouldShowRollButton(BackgammonState s) {
  return s.isHumanTurn && s.phase == BgPhase.rolling;
}

// Board interactivity
bool isBoardInteractive(BackgammonState s) {
  return s.isHumanTurn && s.phase == BgPhase.moving;
}

// Highlight a point as selected
bool isSelected(BackgammonState s, int pointIdx) {
  return s.selectedPoint == pointIdx;
}

// Show bear-off area as a valid destination
bool canBearOff(BackgammonState s, int from) {
  for (final die in s.movesLeft.toSet()) {
    if (validHumanMoves(s, from, die).contains(-2)) return true;
  }
  return false;
}

// Determine if the bar needs interaction first
bool mustPlayFromBar(BackgammonState s) {
  return s.isHumanTurn && s.humanBar > 0;
}
```

### Encoding Convention

- `board[i]` positive value: number of human pieces on point `i+1`.
- `board[i]` negative value: absolute value is the number of AI pieces on point `i+1`.
- `board[i] == 0`: empty point.
- Human moves: subtract die from index (moves toward 0).
- AI moves: add die to index (moves toward 23).
- `to == -2` is the "bear off" sentinel used internally in `validHumanMoves` / `validAiMoves`.

### Folder Structure

- **Logic**: `lib/ui/games/games/backgammon/logic.dart` — all game state, rules, and AI.
- **Screen**: `lib/ui/games/games/backgammon/screen.dart` — board rendering and user interaction.
- **Assets**: `assets/games/backgammon/` — board images, piece sprites (white/black), dice faces (rune-etched).

### Testing Guidance

- **Unit tests** (`test/games/backgammon/`):
  - `validHumanMoves`: test bar re-entry, blocked points, bearing off exact and overshoot.
  - `validAiMoves`: test bar re-entry (AI direction), blocking.
  - `_humanHasMove`: test forced-no-move scenario (all destinations blocked).
  - `humanAllHome` / `aiAllHome`: boundary cases (piece on point 7, bar piece).
  - Win detection: `humanBornOff == 15` triggers `BgPhase.gameOver`.
  - Doubles: `movesLeft` has 4 entries after rolling doubles.
  - Hit blot: `aiBar` increments when AI piece is hit; `board[to]` resets to 0.
- **Integration tests**:
  - Full game: human forces win by bearing off all 15.
  - AI turn auto-triggers after human exhausts dice.
  - No-move pass: human gets a roll with no legal destination.

### Viking Theme Notes

- Use `SisuColors` from `lib/core/colors.dart` for board point colors (alternating dark/light in Norse palette: deep midnight blue and aged oak brown).
- Dice faces: runic numerals or pips on stone tablets.
- Piece sprites: white carved bone pieces (human), black obsidian pieces (AI). Both with subtle rune engravings.
- Hit animation: short thunderclap + piece flying to the bar area.
- Win screen: longship sailing off to Valhalla (human win) or dark fog rolling in (AI win).
- Background: weathered longship deck planks.

---

## Known Gaps / Future Work

| Gap | Notes |
|---|---|
| Doubling cube | Not implemented at all — no cube offer/accept/decline/redouble flow, and no stake multiplier tracking. Every game is played straight through for a single win/loss with no doubling. This is a full feature gap (not just an AI-strategy limitation), and is the kind of omission a real-world backgammon player would notice immediately. |
| Forced die-order / must-play-both-dice rule | `_humanHasMove` and `validHumanMoves`/`validAiMoves` check each die's legality independently. The engine does not check whether a different move order would allow *both* dice to be played, nor does it enforce "must play the higher die" when only one die can be used at a time. Already noted inline under "Forced Die Choice" above, but not enforced in code. |
| No gammon/backgammon scoring | A win always counts as a single point, regardless of whether the loser had borne off zero checkers (gammon) or still had a checker on the bar/in the winner's home board (backgammon) at game end. |
