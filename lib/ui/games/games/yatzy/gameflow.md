# 📜 Yatzy – Consolidated Game Flow Documentation

This document describes the complete game flow for Yatzy in the SisuMate app, following the Viking-themed aesthetic established across SisuMate Games. It covers all game states, UI interactions, dice mechanics, scoring categories, and state management, giving developers a precise reference that matches the actual implementation in `lib/ui/games/games/yatzy/logic.dart`.

## Game Structure

- **Players**: 2 — one human and one AI opponent (single-player only).
- **Modes**: Single-player (human vs. AI).
- **Goal**: Score the most points across all 13 categories. Each player fills in all 13 categories over 13 turns each.
- **Dice**: 5 standard six-sided dice (values 1–6).
- **Rolls per Turn**: Up to 3 rolls. The player may hold (lock) any dice between rolls.
- **Scoring Categories**: 13 categories split into Upper and Lower sections.
- **Upper Section Bonus**: If the sum of the six upper-section scores (Ones through Sixes) reaches 63 or more, a **50-point bonus** is awarded. (Note: The standard Yatzy bonus is 35 pts; this implementation awards **50 pts** when `upperSub >= 63`.)
- **Winner**: Player with the highest total score after all 13 categories are filled by both players.
- **UI Elements**:
  - **Dice Row**: Shows 5 dice with current values. Held dice are visually locked (highlighted in gold/amber). Dice are tappable to toggle hold.
  - **Roll Button**: Large button to roll unheld dice. Disabled after 3 rolls or before the first roll of a new turn.
  - **Scorecard**: Displayed as a table showing all 13 categories with: category name, player's current score (or potential score for unfilled categories), AI's current score.
  - **Potential Score Hints**: While the player has rolled this turn, unfilled categories show the potential score they would earn if selected now.
  - **Game Message Bar**: Context-sensitive instructions (e.g., "Tap Roll to start your turn!").
  - **Roll Counter**: Displays how many rolls remain this turn (0–3).
  - **Turn Indicator**: Shows whether it is the player's turn or AI's turn.
- **Viking Theme**: Rune-etched dice (Norse runes replacing pip dots). Carved stone scorecard. Thor's hammer animation for Yatzy. AI opponent is "The Jarl" — a weathered Viking chieftain portrait. Victory animates crossed axes; defeat shows a broken shield.

---

## Game States & Flow

### 1. Start of Game / New Turn Setup (`YatzyPhase.start`)

**Description**: Beginning of the player's turn. Dice are reset (holds cleared, rolls refilled to 3). No dice have been rolled yet this turn.

**Visual State**:

- **Dice Row**: Shows last roll values (or `[1,1,1,1,1]` at game start) but all holds are cleared.
- **Roll Button**: Enabled.
- **Scorecard**: Shows each category with the player's current scored value (or empty dash for unfilled).
- **Game Message**: "Tap Roll to start your turn!" (or "AI scored [category]: N pts. Your turn!" after AI's turn).
- **Roll Counter**: "Rolls left: 3".

**Visible UI Elements**:

- 5 dice (not tappable for holds yet — `toggleHold` requires `rollsLeft < 3`).
- **Roll** button (enabled).
- Scorecard (category rows not selectable yet — scoring requires `phase == YatzyPhase.scoring`).

**Available Actions**:

- **Roll**: Tap the Roll button to roll all 5 dice and begin the turn.

**Logic**:

- Initial state (from `build()`):
  - `dice = [1,1,1,1,1]`, `holds = [false×5]`, `rollsLeft = 3`.
  - `playerCard = Scorecard.empty()`, `aiCard = Scorecard.empty()`.
  - `aiDice = [1,1,1,1,1]`, `isPlayerTurn = true`.
  - `phase = YatzyPhase.start`, `message = 'Tap Roll to start your turn!'`.
- After AI's turn completes, `phase` returns to `YatzyPhase.start` with `rollsLeft = 3` and `holds` cleared.

**Transition**: Tap Roll → state 2 (Rolling / Scoring).

---

### 2. Rolling & Scoring (`YatzyPhase.rolling` / `YatzyPhase.scoring`)

**Description**: The player has rolled at least once. They may hold dice, roll again (up to 3 times total), and then select a scoring category. These two phases are used interchangeably after the first roll.

**Note**: In the implementation, `YatzyPhase.rolling` is listed in the enum but the `roll()` method transitions immediately to `YatzyPhase.scoring` after the first roll. `toggleHold` accepts both `rolling` and `scoring`. In practice, the phase is `scoring` after the very first roll.

**Visual State**:

- **Dice Row**: Shows current dice values. Held dice are highlighted. Un-held dice are available to re-roll.
- **Roll Button**: Enabled if `rollsLeft > 0`; disabled (greyed out) if `rollsLeft == 0`.
- **Scorecard**: Each unfilled category shows the potential score the player would earn based on current dice.
- **Roll Counter**: "Rolls left: N" (N = 2, 1, or 0).
- **Game Message**:
  - After roll 1 (rollsLeft = 2): "Pick a category or hold dice and roll again."
  - After roll 2 (rollsLeft = 1): "One roll left. Hold keepers, then pick a category."
  - After roll 3 (rollsLeft = 0): "No rolls left — pick a category!"

**Visible UI Elements**:

- 5 dice (tappable to toggle hold when `rollsLeft < 3`).
- **Roll** button (enabled if `rollsLeft > 0`).
- Scorecard with potential scores on unfilled categories (tappable).

**Available Actions**:

- **Toggle Hold** on any die (when `rollsLeft > 0` and `rollsLeft < 3`).
- **Roll** again (up to 3 times total per turn).
- **Score Category**: Tap any unfilled scorecard category to lock in the score and end the turn.

**Logic** (`roll()`):

- Guards: `!isPlayerTurn`, `rollsLeft == 0`, `phase == aiThinking`, `phase == gameOver` all abort.
- For each die `i`: if `!holds[i]` → `d[i] = _rng.nextInt(6) + 1`.
- `rollsLeft -= 1`.
- `phase = YatzyPhase.scoring`.
- Message set based on remaining rolls (see above).

**Logic** (`toggleHold(int i)`):

- Guards: `phase` must be `rolling` or `scoring`; `rollsLeft` must be `< 3` (cannot hold before the first roll of the turn).
- Toggles `holds[i]` between true and false.

**Transition**: Score category tap → state 3 (Score Category).

---

### 3. Score Category (`scoreCategory(YatzyCategory cat)`)

**Description**: The player selects an unfilled scoring category. Their score is recorded, and control passes to the AI.

**Visual State**:

- Scorecard updates: the selected category now shows the player's final score.
- Brief score-reveal animation on the row.
- **Game Message**: Transitions to "AI is rolling…" as AI begins its turn.

**Logic** (`scoreCategory(YatzyCategory cat)`):

- Guards: `!isPlayerTurn`, `playerCard.scores[cat] != null` (already scored), `phase == start` or `phase == rolling` — all abort.
- `pts = scoreFor(cat, state.dice)` — evaluates the current dice against the selected category.
- `newCard = playerCard.withScore(cat, pts)`.
- **Game-over check**: if `newCard.isComplete && aiCard.isComplete`:
  - `phase = YatzyPhase.gameOver`, message = `_endMessage(newCard, aiCard)`. Stop.
- Otherwise:
  - `playerCard = newCard`, `isPlayerTurn = false`, `phase = YatzyPhase.aiThinking`.
  - Message: "AI is rolling…".
  - `Timer(700ms, _aiTurn)`.

**Transition**: AI card complete + player card complete → state 6 (Game Over). Otherwise → state 4 (AI Turn).

---

### 4. AI Turn (`YatzyPhase.aiThinking`)

**Description**: The AI automatically takes its turn — rolling 3 times (with a simplified hold strategy) and scoring the best available category.

**Visual State**:

- Turn indicator shows AI's turn.
- `aiDice` updates to show the AI's final dice values (visible to the player as a replay/reveal).
- AI's scorecard column updates with its scored category.
- **Game Message**: "AI scored [category]: N pts. Your turn!" after completion.

**Visible UI Elements**:

- Updated `aiDice` display.
- AI scorecard column updated.
- Player dice row and Roll button remain inactive.

**Available Actions**: None (AI acts automatically).

**Logic** (`_aiTurn()`):

- Guard: `if (!mounted) return` (Notifier alive check).
- Simulate 3 rolls with smart rerolling:
  ```dart
  var d = List.generate(5, (_) => _rng.nextInt(6) + 1);  // Roll 1
  d = _aiSmartReroll(d);  // Roll 2
  d = _aiSmartReroll(d);  // Roll 3
  ```
- `_aiSmartReroll(d)`:
  - Count frequency of each face value (`cnt[v]++`).
  - Find the most frequent face value (`bestFace`).
  - For each die: if the die appears 2+ times OR equals `bestFace`, keep it; otherwise reroll.
  - This strategy holds any value that has a pair or better, rerolling singletons.
- `cat = _aiBestCat(d, aiCard)`:
  - Iterates all 13 categories; picks the one with the highest `scoreFor(cat, d)`.
  - Tiebreaker: first found (iteration order of `YatzyCategory.values`).
  - If no category yields > 0: picks the first unfilled category (sacrifice a 0).
- `pts = scoreFor(cat, d)`.
- `newAiCard = aiCard.withScore(cat, pts)`.
- **Game-over check**: if `playerCard.isComplete && newAiCard.isComplete`:
  - `phase = YatzyPhase.gameOver`, message = `_endMessage(playerCard, newAiCard)`. Stop.
- Otherwise:
  - `aiDice = d`, `aiCard = newAiCard`, `isPlayerTurn = true`.
  - `holds = [false×5]`, `rollsLeft = 3`.
  - `phase = YatzyPhase.start`.
  - Message: "AI scored [category]: N pts. Your turn!"

**Transition**: Both cards complete → state 6 (Game Over). Otherwise → state 1 (Start of Turn) for player.

---

### 5. Scoring Calculation (sub-process)

**Description**: `scoreFor(YatzyCategory cat, List<int> dice)` is the pure function that evaluates dice against any category. It is used for both scoring and for displaying potential scores in the UI.

**Logic** (`scoreFor`):

| Category | Formula |
|----------|---------|
| Ones | `cnt[1]` (count of 1s × 1) |
| Twos | `cnt[2] × 2` |
| Threes | `cnt[3] × 3` |
| Fours | `cnt[4] × 4` |
| Fives | `cnt[5] × 5` |
| Sixes | `cnt[6] × 6` |
| Three of a Kind | Sum of all dice if any value appears ≥ 3 times; else 0 |
| Four of a Kind | Sum of all dice if any value appears ≥ 4 times; else 0 |
| Full House | **25 points** if exactly one value appears 3 times AND another appears exactly 2 times; else 0 |
| Small Straight | **30 points** if dice contain {1,2,3,4} OR {2,3,4,5} OR {3,4,5,6}; else 0 |
| Large Straight | **40 points** if dice contain {1,2,3,4,5} OR {2,3,4,5,6}; else 0 |
| Yatzy | **50 points** if all 5 dice show the same value; else 0 |
| Chance | Sum of all dice (always > 0) |

**Transition**: Returns score immediately; used inline.

---

### 6. Game Over (`YatzyPhase.gameOver`)

**Description**: Both players have filled all 13 categories. Final scores are compared and a winner is declared.

**Visual State**:

- Full scorecard displayed showing all 13 categories for both player and AI.
- Upper section subtotals, bonus (if applicable), and grand totals shown.
- **Game Message**: "You win! 🎉 N vs N" or "AI wins! N vs N" or "Tie! N each".
- **Viking Theme**: Crossed-axes animation for a win; broken shield for a loss; Valknut symbol for a tie.

**Visible UI Elements**:

- Complete scorecard with both columns filled.
- Upper bonus row (shows 50 if bonus earned, 0 if not).
- Total row for both players.
- **New Game** button.
- **Return to Menu** button.

**Available Actions**:

- **New Game**: Calls `newGame()` → `build()`. Resets all state to initial values.
- **Return to Menu**: Navigates to game-selection screen.

**Logic** (`_endMessage(Scorecard p, Scorecard ai)`):

- `ps = p.total` (upper sub + bonus + lower section sum).
- `as_ = ai.total`.
- `ps > as_` → "You win! 🎉 $ps vs $as_".
- `as_ > ps` → "AI wins! $as_ vs $ps".
- Equal → "Tie! $ps each".

**`Scorecard.total`**:

```dart
int get total {
  int t = upperSub + bonus;
  for (final c in YatzyCategory.values) {
    if (!upperCats.contains(c)) t += scores[c] ?? 0;
  }
  return t;
}
```

**Transition**: "New Game" → state 1. "Return to Menu" → exits game screen.

---

## Key Game Rules Summary

### Scoring Categories

#### Upper Section

| Category | Scoring Rule | Max Score | Bonus Target |
|----------|-------------|-----------|-------------|
| Ones | Count of 1s (each worth 1) | 5 | ≥3 |
| Twos | Count of 2s × 2 | 10 | ≥3 |
| Threes | Count of 3s × 3 | 15 | ≥3 |
| Fours | Count of 4s × 4 | 20 | ≥3 |
| Fives | Count of 5s × 5 | 25 | ≥3 |
| Sixes | Count of 6s × 6 | 30 | ≥3 |
| **Upper Total** | Sum of above | **105** | |
| **Upper Bonus** | +50 if Upper Total ≥ 63 | **50** | |

Note: Three of each number (1+1+1 = 3, 2+2+2 = 6, … 6+6+6 = 18) gives exactly 63.

#### Lower Section

| Category | Scoring Rule | Score |
|----------|-------------|-------|
| Three of a Kind | Sum of ALL 5 dice if ≥3 match | Variable (max 30) |
| Four of a Kind | Sum of ALL 5 dice if ≥4 match | Variable (max 30) |
| Full House | Exactly 3 of one + 2 of another | **25** |
| Small Straight | 4 consecutive values in dice | **30** |
| Large Straight | 5 consecutive values in dice | **40** |
| Yatzy | All 5 dice identical | **50** |
| Chance | Sum of ALL 5 dice (no conditions) | Variable (max 30) |

#### Maximum Possible Score

- Upper section max: 105 + 50 bonus = 155.
- Lower section max: 30 + 30 + 25 + 30 + 40 + 50 + 30 = 235.
- Grand max: 155 + 235 = **390**.

### Roll Rules

- 3 rolls maximum per turn.
- Before the first roll: no holds may be set (`toggleHold` guard: `rollsLeft == 3` → abort).
- After rolling (rolls 1 or 2): any dice may be held or unheld freely.
- After the third roll: must score a category (`rollsLeft == 0`).
- A player **must** score a category each turn, even if all scores are 0 for all remaining categories (forced sacrifice).

### Turn Flow

1. Player is at `YatzyPhase.start`.
2. Player rolls (up to 3 times), toggling holds between rolls.
3. Player selects a scoring category → `scoreFor(cat, dice)` records score.
4. AI takes its turn automatically (3 rolls + best-category selection).
5. Repeat until both scorecards are complete.

---

## Enhancements & Edge Cases

### Forced Zero Scoring

- A player must score a category every turn. If no remaining category yields points with the current dice, the player must "sacrifice" a category by scoring 0. The UI should still allow tapping any unfilled category (potential score shown as 0).

### Upper Bonus Calculation

- `bonus` is only calculated after all 6 upper categories are filled (`upperCats.every((c) => scores[c] != null)`). If any upper category remains unfilled, `bonus == 0`.
- The bonus threshold is **63** points, awarding **50 points** (not the more common 35-point rule — this is the actual implementation).

### `isComplete` Check

- `Scorecard.isComplete` is `scores.values.every((v) => v != null)`.
- Game over is triggered when **both** player and AI scorecards are complete simultaneously (checked at the end of the AI turn) or when the player scores the last category AND AI is already complete.

### AI Reroll Count

- The AI always performs exactly 2 smart rerolls (`_aiSmartReroll` called twice) after the initial random roll, regardless of what dice it holds. This simulates 3 rolls with holds but does not track a "rollsLeft" for the AI.

### AI Category Tie-Breaking

- `_aiBestCat` iterates `YatzyCategory.values` in enum declaration order and picks the first category that yields the maximum score. No tie-breaking by strategic value (e.g., it does not prefer to save Yatzy slot).

### Chance as Safety Net

- "Chance" always scores (sum of dice > 0 guaranteed), making it a reliable sacrifice category. Strategic players save it for a bad roll. AI uses the same greedy best-score logic and may score Chance early.

### Phase Guard in `toggleHold`

- `toggleHold` accepts `phase == YatzyPhase.rolling` OR `phase == YatzyPhase.scoring`. In practice, `roll()` always sets `phase = YatzyPhase.scoring`, so `rolling` may never be reached in normal flow. The guard is defensive.

### Scorecard Immutability

- `Scorecard` is immutable. `withScore(cat, pts)` returns a new `Scorecard` with the updated score map via `{...scores, c: v}`.

---

## Implementation Notes

### State Management

Global state is managed by `YatzyNotifier extends Notifier<YatzyState>` in `lib/ui/games/games/yatzy/logic.dart`.

**`YatzyState` fields**:

| Field | Type | Description |
|-------|------|-------------|
| `dice` | `List<int>` | Player's current 5 dice values (1–6) |
| `holds` | `List<bool>` | Which dice are held (true = locked) |
| `rollsLeft` | `int` | Remaining rolls this turn (0–3) |
| `playerCard` | `Scorecard` | Player's scorecard (all 13 categories) |
| `aiCard` | `Scorecard` | AI's scorecard |
| `aiDice` | `List<int>` | AI's last-turn dice (for display) |
| `isPlayerTurn` | `bool` | True when player should act |
| `phase` | `YatzyPhase` | Current game phase (enum) |
| `message` | `String` | UI instruction/result message |

**`YatzyPhase` enum values**:

| Value | Meaning |
|-------|---------|
| `start` | Player's turn start; awaiting first roll |
| `rolling` | (Defined but not used in post-roll transitions) |
| `scoring` | Player has rolled; may hold, re-roll, or score |
| `aiThinking` | AI is taking its turn |
| `gameOver` | Both scorecards complete |

**`Scorecard` class**:

```dart
class Scorecard {
  final Map<YatzyCategory, int?> scores;  // null = unfilled
  int get upperSub => upperCats.fold(0, (s, c) => s + (scores[c] ?? 0));
  int get bonus => (upperCats.every((c) => scores[c] != null) && upperSub >= 63) ? 50 : 0;
  int get total { … }  // upperSub + bonus + lower section sum
  bool get isComplete => scores.values.every((v) => v != null);
}
```

**`YatzyCategory` enum** (13 values, in order):
`ones`, `twos`, `threes`, `fours`, `fives`, `sixes`,
`threeOfAKind`, `fourOfAKind`, `fullHouse`,
`smallStraight`, `largeStraight`, `yatzy`, `chance`.

**`upperCats` list**: `[ones, twos, threes, fours, fives, sixes]`.

**Provider**:

```dart
final yatzyStateProvider =
    NotifierProvider<YatzyNotifier, YatzyState>(YatzyNotifier.new);
```

### UI Logic Snippets

```dart
// Roll button is enabled when player can roll
bool canRoll(YatzyState s) =>
    s.isPlayerTurn &&
    s.rollsLeft > 0 &&
    s.phase != YatzyPhase.aiThinking &&
    s.phase != YatzyPhase.gameOver;

// Player can toggle a die's hold
bool canToggleHold(YatzyState s) =>
    (s.phase == YatzyPhase.rolling || s.phase == YatzyPhase.scoring) &&
    s.rollsLeft < 3;

// A die is held
bool isDieHeld(YatzyState s, int i) => s.holds[i];

// A category is available to score (unfilled + player has rolled)
bool canScoreCategory(YatzyState s, YatzyCategory cat) =>
    s.isPlayerTurn &&
    s.phase == YatzyPhase.scoring &&
    s.playerCard.scores[cat] == null;

// Potential score for unfilled category (shown as hint in scorecard)
int potentialScore(YatzyState s, YatzyCategory cat) =>
    s.playerCard.scores[cat] == null
        ? scoreFor(cat, s.dice)
        : s.playerCard.scores[cat]!;

// Upper bonus progress (show progress toward 63)
String upperBonusProgress(YatzyState s) {
  final sub = s.playerCard.upperSub;
  return sub >= 63 ? '+50 Bonus!' : '$sub / 63';
}

// Game over check
bool isGameOver(YatzyState s) => s.phase == YatzyPhase.gameOver;
```

### Folder Structure

- **Logic**: `lib/ui/games/games/yatzy/logic.dart` — all game logic, state, notifier, scorecard, scoring function.
- **Screen**: `lib/ui/games/games/yatzy/screen.dart` — UI widgets consuming `yatzyStateProvider`.
- **Assets**: `assets/games/yatzy/` — rune-etched dice, carved stone scorecard background, AI opponent portrait (The Jarl).

### Testing Guidance

- **Unit tests** (`test/games/yatzy/`):
  - `scoreFor` for all 13 categories with representative and edge-case dice:
    - Ones: `[1,1,2,3,4]` → 2; `[2,3,4,5,6]` → 0.
    - Three of a Kind: `[3,3,3,2,1]` → 12; `[1,2,3,4,5]` → 0.
    - Full House: `[2,2,3,3,3]` → 25; `[2,2,2,3,3]` → 25; `[1,2,3,4,5]` → 0.
    - Small Straight: `[1,2,3,4,6]` → 30; `[1,2,3,5,6]` → 0.
    - Large Straight: `[1,2,3,4,5]` → 40; `[2,3,4,5,6]` → 40; `[1,2,3,4,6]` → 0.
    - Yatzy: `[6,6,6,6,6]` → 50; `[6,6,6,6,5]` → 0.
    - Chance: `[1,2,3,4,5]` → 15; `[6,6,6,6,6]` → 30.
  - `Scorecard.bonus`: only awarded when all 6 upper categories scored AND sum ≥ 63.
  - `Scorecard.total`: correct summation of all sections.
  - `Scorecard.isComplete`: true only when all 13 values non-null.
  - `toggleHold` guard: cannot hold before first roll of turn.
  - `roll()` guard: `rollsLeft == 0` → no-op.
  - `scoreCategory` guard: already-scored category → no-op.
  - `_aiSmartReroll`: holding pairs and rerolling singletons.
  - `_aiBestCat`: picks highest-scoring category.
  - `_endMessage`: all three outcomes (win, lose, tie).
- **Integration tests**: Full 13-turn game for both players; verify final scores and winner detection.
- Aim for 90%+ coverage on `scoreFor` and `Scorecard` methods.

### Viking Theme

- Use `SisuColors` from `lib/core/colors.dart` and `SisuMateTheme` from `lib/core/theme.dart`.
- Dice: rune-etched stone dice — `assets/games/yatzy/die_N.png` (N = 1–6, each showing the corresponding rune).
- Scorecard background: carved stone tablet — `assets/games/yatzy/scorecard_bg.png`.
- AI opponent portrait: "The Jarl" — `assets/games/yatzy/jarl.png`.
- Yatzy animation: Thor's hammer strike — `assets/games/yatzy/yatzy.gif`.
- Victory: crossed axes animation; defeat: broken shield fade.
- Font: follow the NotoSansRunic pattern used across the app's Viking theme.

## Known Gaps / Future Work

| Gap | Notes |
|---|---|
| Yatzy bonus / joker rule | Classic Yatzy/Yahtzee rule, not implemented: once a player has scored a genuine Yatzy (the `yatzy` category holds 50, not 0), rolling a **second** (or later) Yatzy traditionally earns a flat bonus (commonly +100) on top of normal scoring, and the roll may be used as a "joker" to fill *any* other open category at full value (with the matching upper-section box required first if it is still open). `scoreFor`/`scoreCategory`/`_aiTurn` treat a repeat Yatzy exactly like any other roll — it is simply scored into whichever open category the player/AI picks, with no extra bonus and no joker flexibility. This silently removes one of the signature "big moment" mechanics of the real game. Logging this in `outstanding.md` as a candidate enhancement, not fixing in `logic.dart` here (doc-accuracy pass only). |
| 13 categories vs. 15-category "Scandinavian Yatzy" | This implementation uses the 13-category American Yahtzee category set (no "One Pair" / "Two Pairs" boxes found in the traditional Nordic 15-category Yatzy scorecard). Documented here for awareness only — this is a scope/variant choice, not a bug, and changing it would be a much larger rework than a doc fix. |

---

## Next Steps

1. Implement the scorecard UI with potential-score hints on unfilled categories in `screen.dart`.
2. Add upper-section bonus progress bar showing current `upperSub / 63`.
3. Add die-roll animation (spinning die stopping at the rolled value).
4. Display AI's dice after its turn so the player can see what AI rolled.
5. Generate Viking-themed rune dice assets in `assets/games/yatzy/` after user confirmation.
6. Write unit tests for all `scoreFor` cases in `test/games/yatzy/logic_test.dart`.
