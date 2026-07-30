# 📜 Poker (5-Card Draw) – Consolidated Game Flow Documentation

This document describes the complete game flow for 5-Card Draw Poker in the SisuMate app, following the Viking-themed aesthetic established across SisuMate Games. It covers all game states, UI interactions, button visibility, and state management, giving developers a precise reference that matches the actual implementation in `lib/ui/games/games/poker/logic.dart`.

## Game Structure

- **Players**: 2 — host role (`playerHand`/`playerChips`) vs opponent role (`aiHand`/`aiChips`).
- **Modes**: Single-player (human vs. AI) **and** LAN multiplayer (GAME1 absolute host/guest model, same as Uno/Yatzy/Checkers). Guest plays the opponent role; hidden-hand until showdown; simultaneous draw confirms; no AI auto-call against a real guest.
- **Rounds**: A game consists of consecutive rounds until one player runs out of chips.
- **Hands**: Each round is one 5-card draw hand consisting of up to four phases: first betting, draw, second betting, and showdown.
- **Focus**: Player vs. AI — both hold five cards; the player sees their own hand and the count of AI cards. AI hand is hidden until showdown.
- **Starting Chips**: Both player and AI begin each game with **500 chips**.
- **Ante**: Each round begins with an automatic ante of **10 chips** (or the minimum of both stacks), deducted before cards are dealt.
- **Bet Amount**: The fixed bet/call increment is **20 chips**.
- **Pot**: Grows as antes, bets, and calls are added. Awarded to the winner at showdown (or to the AI if the player folds). Split evenly on a tie.
- **UI Elements**:
  - **Player Hand Row**: Shows 5 face-up cards. Cards the player taps to discard are highlighted/toggled.
  - **AI Hand Row**: Shows 5 face-down cards (card backs) during play; revealed face-up at showdown.
  - **Chip Counters**: Player chips and AI chips displayed at all times.
  - **Pot Display**: Current pot value shown centrally.
  - **Game Message Bar**: Top row showing context-sensitive instructions (e.g., "Ante: $10 each. Bet, check, or fold?").
  - **Action Buttons**: Contextual — shown only when player input is required.
- **Viking Theme**: UI uses weathered wood card table backgrounds, runic card back art, and Norse-inspired typography. Chip icons styled as Viking silver coins (hack-silver). Victory displays northern-lights animation; defeat uses stormy-sea effect.

---

## Game States & Flow

### 1. Start of Game / New Game

**Description**: Initialize the game with fresh chip stacks and deal the first round.

**Visual State**:

- **Player Setup Screen** / immediate deal: No lobby screen is shown. The game begins immediately when the player navigates to the Poker screen or taps "New Game" from the game-over screen.
- Both chip counters reset to **500**.
- Cards are dealt face-down with a brief shuffle/deal animation before the player's cards flip face-up.
- Game message: "Ante: $10 each. Bet, check, or fold?"

**Visible UI Elements**:

- Player hand (5 face-up cards).
- AI hand (5 face-down cards, count only).
- Chip counters for player and AI.
- Pot display showing the initial pot (20 chips after ante).
- **Bet**, **Check**, and **Fold** action buttons (betting phase 1 active).

**Available Actions**:

- None before deal animation completes.
- After deal: **Bet**, **Check**, or **Fold** (first betting phase).

**Logic**:

- `PokerNotifier.build()` calls `_startRound(playerChips: 500, aiChips: 500)`.
- A 52-card deck is created (`List.generate(52, (i) => i)`) and shuffled.
- Cards 0–4 → `playerHand`; cards 5–9 → `aiHand`; remainder → `deck`.
- Ante (`_ante = 10`) is clamped to `min(playerChips, aiChips)` so neither goes negative.
- `phase` is set to `PokerPhase.betting1`.
- `selectedDiscard` starts as an empty `Set<int>`.

**Transition**: Deal completes → state 2 (Betting Phase 1).

---

### 2. Betting Phase 1 (`PokerPhase.betting1`)

**Description**: The first betting round occurs immediately after the deal, before the draw. Both players have seen their initial five cards. The player chooses to bet, check, or fold.

**Visual State**:

- **Player Hand**: 5 face-up cards, no discard toggles yet (toggling is only available in the Draw phase).
- **AI Hand**: 5 face-down cards.
- **Pot Display**: Current pot (post-ante).
- **Chip Counters**: Updated after ante.
- **Game Message**: "Ante: $10 each. Bet, check, or fold?" — or the AI's reaction message if the AI bet back after a player check.

**Visible UI Elements**:

- **Bet** button (enabled unless `playerChips == 0`).
- **Check** button (always enabled when it's the player's turn).
- **Fold** button (always enabled when it's the player's turn).
- **Call** button: appears only if the AI bets back after a player check (replaces Check button or appears alongside Fold).

**Available Actions**:

- **Bet**: Player bets `_betAmount` (20 chips). AI automatically calls. Advances to Draw phase.
- **Check**: Player checks (no additional bet).
  - If AI checks back (67% probability): advances to Draw phase.
  - If AI bets back (33% probability, `_rng.nextInt(3) == 0`): message updates to "AI bets $20. Call or fold?"; **Call** and **Fold** buttons appear.
- **Fold**: Player concedes. AI wins the entire pot. Round ends immediately.
- **Call** (conditional): Player calls AI's raise. Advances to Draw phase.

**Logic**:

- `playerBet()`:
  - Deducts `_betAmount.clamp(0, playerChips)` from player, same from AI (AI always calls).
  - Advances `phase` to `PokerPhase.draw`.
  - Message: "You bet $20. AI calls. Select cards to discard."
- `playerCheck()`:
  - AI bets back with 33% probability (`_rng.nextInt(3) == 0`).
  - If AI bets: updates `pot` and `aiCurrentBet`; player must Call or Fold.
  - If AI checks: advances `phase` to `PokerPhase.draw`.
  - Message: "Both check. Select cards to discard."
- `playerCall()`:
  - Deducts difference between `aiCurrentBet` and `playerCurrentBet` from `playerChips`.
  - Advances `phase` to `PokerPhase.draw`.
- `playerFold()`:
  - Sets `aiChips += pot`, `pot = 0`.
  - Advances `phase` to `PokerPhase.roundOver`.
  - `outcome = 'AI wins'`.
- Chips are clamped so neither player goes below 0.

**Transition**:

- Bet / Check / Call → state 3 (Draw Phase).
- Fold → state 5 (Round Over).

---

### 3. Draw Phase (`PokerPhase.draw`)

**Description**: Each player discards and draws replacement cards. The player selects which cards to discard; the AI discards automatically.

**Visual State**:

- **Player Hand**: 5 face-up cards. Tapping a card toggles its "discard" state (visually highlighted, e.g., raised or dimmed).
- **AI Hand**: Still 5 face-down cards (AI count may update after draw to show new count, e.g., "AI drew 2").
- **Pot Display**: Unchanged from end of betting 1.
- **Game Message**: "Select cards to discard." / "You drew N, AI drew N. Bet, check, or fold?"

**Visible UI Elements**:

- Player's 5 cards (each tappable to toggle discard selection).
- **Draw** (or "Confirm") button: enabled at all times (player may draw 0 cards by confirming with nothing selected).
- No Bet/Check/Fold buttons yet.

**Available Actions**:

- **Toggle card**: Tap any of the 5 player cards to select/deselect it for discard. Selected cards are highlighted.
- **Confirm Draw**: Tap "Draw" button to execute the discard/draw.

**Logic**:

- `toggleDiscard(int idx)`:
  - Only operates when `phase == PokerPhase.draw`.
  - Adds or removes `idx` from `selectedDiscard` (a `Set<int>`).
- `confirmDraw()`:
  - Replaces each discarded card index in `playerHand` with the next card from `deck`.
  - AI discard via `_aiDiscardIndices(aiHand)`:
    - If AI hand is One Pair or better: identifies the contributing ranks (`cnt[r] >= 2`) and discards all cards NOT in those ranks (up to 3 typically).
    - If AI hand has no pair: discards the two lowest-ranked cards (by `rankOf`), keeping the three highest.
  - Both hands are updated; `selectedDiscard` is cleared.
  - `phase` → `PokerPhase.betting2`.
  - Message: "You drew N, AI drew N. Bet, check, or fold?"

**Transition**: Confirm Draw → state 4 (Betting Phase 2).

---

### 4. Betting Phase 2 (`PokerPhase.betting2`)

**Description**: The second and final betting round, after the draw. Same mechanics as Betting Phase 1 but a successful showdown follows instead of a draw phase.

**Visual State**:

- **Player Hand**: 5 face-up cards (updated after draw).
- **AI Hand**: Still 5 face-down cards.
- **Pot Display**: Updated pot.
- **Game Message**: "You drew N, AI drew N. Bet, check, or fold?"

**Visible UI Elements**:

- **Bet** button.
- **Check** button.
- **Fold** button.
- **Call** button: appears if AI bets back after a player check.

**Available Actions**:

- Same as Betting Phase 1: **Bet**, **Check**, **Call** (conditional), **Fold**.

**Logic**:

- Identical to Betting Phase 1 mechanics except:
  - After resolution, `phase` advances to `PokerPhase.showdown` (not `PokerPhase.draw`).
  - `playerBet()`: message "You bet $20. AI calls. Showdown!"
  - `playerCheck()` with mutual check: message "Both check. Showdown!"
  - `playerFold()`: AI wins pot; `phase` → `PokerPhase.roundOver`.
- When `phase` becomes `PokerPhase.showdown`, `_showdown()` is called after a 400 ms delay.

**Transition**:

- Bet / Check / Call → state 5 (Showdown) after 400 ms delay.
- Fold → state 6 (Round Over).

---

### 5. Showdown (`PokerPhase.showdown`)

**Description**: Both hands are revealed and evaluated. The stronger hand wins the pot. On a tie the pot is split.

**Visual State**:

- **Player Hand**: 5 face-up cards.
- **AI Hand**: 5 face-up cards (AI hand is revealed for the first time).
- **Pot Display**: Shows final pot before distribution.
- **Game Message**: Result string, e.g., "You win! Full House beats Two Pair" or "AI wins with Straight Flush!"
- **Viking Theme**: Brief animation — crossed axes for a win, ship sinking for a loss.

**Visible UI Elements**:

- Both hands face-up.
- No Bet/Check/Fold buttons.
- "Next Round" button appears once `phase == PokerPhase.roundOver`.

**Available Actions**:

- None during the 400 ms resolution delay.
- After resolution: **Next Round** button.

**Logic** (`_showdown()`):

- `evaluateHand(playerHand)` → `HandResult pResult`.
- `evaluateHand(aiHand)` → `HandResult aResult`.
- Compare via `pResult.compareTo(aResult)`:
  - `> 0` (player wins): `playerChips += pot`; message "You win! [playerRank] beats [aiRank]".
  - `< 0` (AI wins): `aiChips += pot`; message "AI wins with [aiRank]!"
  - `== 0` (tie): `pot ~/ 2` → `playerChips`; remainder → `aiChips`; message "Tie! Split pot."
- `pot` resets to 0.
- `phase` → `PokerPhase.roundOver`.
- `outcome` field set to the result string.

**Transition**: Showdown resolves → state 6 (Round Over).

---

### 6. Round Over (`PokerPhase.roundOver`)

**Description**: The round has ended (by showdown or fold). Chip totals are updated. Player can start the next round or end the game.

**Visual State**:

- Both hands still visible (or folded state).
- Updated chip counters.
- **Game Message**: Result summary (from showdown or "You fold. AI wins $N.").
- "Next Round" button visible.

**Visible UI Elements**:

- **Next Round** button (navigates to state 1/2 of the next round).
- Chip totals.
- No card-action buttons.

**Available Actions**:

- **Next Round**: Calls `nextRound()` → `_startRound(playerChips, aiChips)`. Checks for game-over condition first.

**Logic** (`nextRound()`):

- Calls `_startRound(playerChips: state.playerChips, aiChips: state.aiChips)`.
- `_startRound` checks:
  - `playerChips <= 0` → `phase = PokerPhase.gameOver`, message "You're out of chips! AI wins."
  - `aiChips <= 0` → `phase = PokerPhase.gameOver`, message "AI is out of chips! You win!"
  - Otherwise → fresh deck, new ante, deal, `phase = PokerPhase.betting1`.

**Transition**:

- Chips remain → back to state 2 (Betting Phase 1) of a new round.
- A player is out of chips → state 7 (Game Over).

---

### 7. Game Over (`PokerPhase.gameOver`)

**Description**: One player has run out of chips. The game is finished.

**Visual State**:

- Chip counters showing final values (one player at 0).
- **Game Message**: "You're out of chips! AI wins." or "AI is out of chips! You win!"
- **Viking Theme**: Northern lights animation for victory; stormy seas for defeat.

**Visible UI Elements**:

- **Play Again** button (resets to `playerChips: 500, aiChips: 500`).
- **Return to Menu** button (navigates to the games list).

**Available Actions**:

- **Play Again**: Calls `newGame()` → `_startRound(playerChips: 500, aiChips: 500)`. Resets fully.
- **Return to Menu**: Navigates to the app's game-selection screen.

**Logic**:

- `newGame()` calls `_startRound(playerChips: 500, aiChips: 500)` directly.
- All state fields reset: new deck, new hands, pot = 0, `phase = PokerPhase.betting1`.

**Transition**: "Play Again" → state 1 (Start of Game). "Return to Menu" → exits game screen.

---

## Key Game Rules Summary

### Hand Rankings (Highest to Lowest)

| Rank | Name | Description | Tiebreaker |
|------|------|-------------|------------|
| 9 | Royal Flush | A-K-Q-J-10 of the same suit | None (unbeatable) |
| 8 | Straight Flush | Five consecutive ranks, same suit | Highest card |
| 7 | Four of a Kind | Four cards of the same rank | Quad rank, then kicker |
| 6 | Full House | Three of a kind + a pair | Trip rank, then pair rank |
| 5 | Flush | Five cards same suit, not consecutive | Cards ranked highest to lowest |
| 4 | Straight | Five consecutive ranks, mixed suits | Highest card (A-2-3-4-5 = low) |
| 3 | Three of a Kind | Three cards of the same rank | Trip rank, then kickers |
| 2 | Two Pair | Two different pairs | High pair, low pair, kicker |
| 1 | One Pair | One pair of matching rank | Pair rank, then kickers |
| 0 | High Card | No matching pattern | Cards ranked highest to lowest |

Note: Card ranks are `rank = card % 13` where 0 = 2, 12 = Ace (Ace is high). The A-2-3-4-5 "wheel" straight is detected as a special case in `evaluateHand`.

### Betting Rules

- **Ante**: Fixed at 10 chips per round (clamped to the smaller stack).
- **Bet / Call**: Fixed increment of 20 chips. There are no raises — only bet or call.
- **Check**: Pass without adding chips; AI may respond by betting.
- **Fold**: Forfeit the pot immediately; no showdown.
- **AI always calls** a player bet (simplification for AI play).
- **AI bets back** on a player check with 33% probability.

### Chip Management

- Both players start with 500 chips.
- A player whose `chips <= 0` at the start of `_startRound` triggers `PokerPhase.gameOver`.
- The pot is always transferred in full to the winner (split on tie: `pot ~/ 2` to player, remainder to AI).

### AI Draw Strategy (`_aiDiscardIndices`)

1. Evaluate the AI's hand with `evaluateHand`.
2. If the hand is **One Pair or better**: count rank frequencies; identify all ranks appearing 2+ times (`keepRanks`); discard all cards whose rank is not in `keepRanks`.
3. If **no pair**: sort all 5 card indices by rank ascending; discard the two lowest-ranked cards (indices 0 and 1 of the sorted list).

---

## Enhancements & Edge Cases

### Out-of-Cards Draw

- If `deck` runs out during a draw, the current implementation draws from whatever remains in the deck. The deck starts with 42 cards after the deal (`deck.sublist(10)` on a 52-card deck with 10 cards dealt), so running out is extremely unlikely but possible at low chip counts after many rounds (deck is never reshuffled mid-game because there is only one round per deck).

### Chip Clamping

- `amount = _betAmount.clamp(0, playerChips)` — if a player has fewer than 20 chips, the actual bet is reduced. If they have 0 chips, `playerBet()` silently falls through to `playerCheck()`.
- AI's call is `amount.clamp(0, state.aiChips)` — capped at what the player actually bet, not the nominal `_betAmount` (fixed 2026-07-16, GB3; previously AI always called the full nominal amount even when the player's real bet was smaller, over-matching a short-stacked all-in).
- `playerCall()`'s `diff` (the amount owed to match `aiCurrentBet`) is likewise clamped to `state.playerChips`, so a short-stacked player calls "all-in" for whatever they have left rather than the full difference. The mirror fix: `uncalled = needed - diff` is computed and returned to `aiChips` (deducted back out of `pot`), so AI's already-committed excess isn't left sitting in the pot uncontested when the player can't fully call it (GB3).

### Tie Pot Split

- On an exact tie, `pot ~/ 2` goes to the player; the remainder (pot - half) goes to AI. This means AI receives the extra chip if the pot is odd.

### Showdown Delay

- `_showdown()` is called via `Future.delayed(const Duration(milliseconds: 400), _showdown)`. The 400 ms pause allows UI animations to settle before updating state.

### AI Check/Bet Probability

- AI bets back on a player check with probability 1/3 (`_rng.nextInt(3) == 0`). This applies independently in both betting phases.
- There is no difficulty setting in the current implementation — the 1/3 probability is fixed.

### Fold During Betting Phase 2

- `playerFold()` can be called from either `betting1` or `betting2` — the logic is identical. The AI wins the entire pot regardless of phase.

---

## Known Gaps / Future Work

| Gap | Notes |
|---|---|
| No side pots (by design) | This is heads-up (2-player) only, so a single pot is always correct — side pots only become necessary with 3+ players and multiple simultaneous all-ins. Not a bug, just worth noting explicitly since side pots are the first thing to check in any poker implementation. |

---

## Implementation Notes

### State Management

Global state is managed by `PokerNotifier extends Notifier<PokerState>` in `lib/ui/games/games/poker/logic.dart`.

**`PokerState` fields**:

| Field | Type | Description |
|-------|------|-------------|
| `deck` | `List<int>` | Remaining draw cards (indices 0–51 encoding) |
| `playerHand` | `List<int>` | Player's 5 cards |
| `aiHand` | `List<int>` | AI's 5 cards |
| `selectedDiscard` | `Set<int>` | Indices in `playerHand` selected for discard |
| `playerChips` | `int` | Player's current chip count |
| `aiChips` | `int` | AI's current chip count |
| `pot` | `int` | Current pot value |
| `playerCurrentBet` | `int` | Player's cumulative bet this round |
| `aiCurrentBet` | `int` | AI's cumulative bet this round |
| `phase` | `PokerPhase` | Current game phase (enum) |
| `message` | `String` | UI instruction/result message |
| `outcome` | `String?` | Null until showdown; contains result string |

**`PokerPhase` enum values**:

| Value | Meaning |
|-------|---------|
| `betting1` | First betting round (pre-draw) |
| `draw` | Draw phase (card selection and replacement) |
| `betting2` | Second betting round (post-draw) |
| `showdown` | Hands being evaluated (400 ms delay) |
| `roundOver` | Round complete; awaiting "Next Round" |
| `gameOver` | One player out of chips |

**Card encoding**:

```dart
int suitOf(int c) => c ~/ 13;  // 0=♣, 1=♦, 2=♥, 3=♠
int rankOf(int c) => c % 13;    // 0=2, 1=3, …, 8=10, 9=J, 10=Q, 11=K, 12=A
bool isRed(int c) => suitOf(c) == 1 || suitOf(c) == 2;
```

**Provider**:

```dart
final pokerStateProvider =
    NotifierProvider<PokerNotifier, PokerState>(PokerNotifier.new);
```

### UI Logic Snippets

```dart
// Show betting buttons only during betting phases
bool shouldShowBetControls(PokerState s) =>
    s.phase == PokerPhase.betting1 || s.phase == PokerPhase.betting2;

// Show Call button only when AI has bet more than player
bool shouldShowCallButton(PokerState s) =>
    shouldShowBetControls(s) && s.aiCurrentBet > s.playerCurrentBet;

// Show draw controls only in draw phase
bool shouldShowDrawPhase(PokerState s) => s.phase == PokerPhase.draw;

// Show Next Round button
bool shouldShowNextRound(PokerState s) => s.phase == PokerPhase.roundOver;

// Show Play Again / Return to Menu
bool shouldShowGameOverButtons(PokerState s) => s.phase == PokerPhase.gameOver;

// AI hand is revealed only at showdown and beyond
bool shouldShowAiCards(PokerState s) =>
    s.phase == PokerPhase.showdown ||
    s.phase == PokerPhase.roundOver ||
    s.phase == PokerPhase.gameOver;

// A card is "selected for discard" during draw phase
bool isCardSelectedForDiscard(PokerState s, int idx) =>
    s.phase == PokerPhase.draw && s.selectedDiscard.contains(idx);
```

### Folder Structure

- **Logic**: `lib/ui/games/games/poker/logic.dart` — all game logic, state, notifier.
- **Screen**: `lib/ui/games/games/poker/screen.dart` — UI widgets consuming `pokerStateProvider`.
- **Assets**: `assets/games/poker/` — card back art (runic design), chip icons (hack-silver style), table background (weathered wood).

### Testing Guidance

- **Unit tests** (`test/poker_test.dart`):
  - `evaluateHand` for all 10 hand ranks including edge cases (wheel straight A-2-3-4-5, royal flush detection).
  - `_aiDiscardIndices` — verify it keeps pair cards and discards two lowest on no-pair.
  - `HandResult.compareTo` — same rank tiebreaking via tiebreakers list; a wheel must rank *below* any higher straight/straight-flush, not above it (GB4).
  - `_startRound` game-over detection when `playerChips <= 0` or `aiChips <= 0`.
  - Chip clamping when bet amount exceeds available chips; uncalled-bet return on both `playerBet()` and `playerCall()` when the player is short-stacked (GB3, via a `_SeededPokerNotifier` test helper for precise chip-count control).
- **Integration tests**: Full round cycle (deal → bet → draw → bet → showdown → next round).
- Aim for 90%+ coverage on `evaluateHand` and chip-management paths.

### Viking Theme

- Use `SisuColors` from `lib/core/colors.dart` and `SisuMateTheme` from `lib/core/theme.dart`.
- Card backs: rune-etched design in `assets/games/poker/card_back.png`.
- Chip icon: hack-silver coin in `assets/games/poker/chip.png`.
- Background: weathered longhouse wood in `assets/games/poker/bg.png`.
- Victory: northern-lights particle animation; defeat: stormy-sea overlay.
- Font: follow the NotoSansRunic pattern used across the app's Viking theme.

## Next Steps

1. Implement `PokerPhase.showdown` reveal animation (flip AI cards face-up) in `screen.dart`.
2. Add "Call" button conditional logic triggered by `aiCurrentBet > playerCurrentBet`.
3. Wire AI bet-back message state so the UI knows to show Call/Fold only (not Bet/Check).
4. Generate Viking-themed card-back asset in `assets/games/poker/` after user confirmation.
5. Write unit tests for all 10 `HandRank` values in `test/games/poker/logic_test.dart`.
