# 📜 Uno – Consolidated Game Flow Documentation

This document describes the complete game flow for Uno in the SisuMate app, following the Viking-themed aesthetic established across SisuMate Games. It covers all game states, UI interactions, card effects, and state management, giving developers a precise reference that matches the actual implementation in `lib/ui/games/games/uno/logic.dart`.

## Game Structure

- **Players**: 2 — one human and one AI opponent (single-player only).
- **Modes**: Single-player (human vs. AI).
- **Goal**: Be the first player to empty their hand.
- **Deck**: 108 cards total.
  - 4 colors (Red, Yellow, Green, Blue):
    - 1 × Zero card per color = 4 cards.
    - 2 × each of 1–9, Skip, Reverse, Draw Two per color = 4 × 19 = 76 cards.
  - Wild cards (no color): 4 × Wild + 4 × Wild Draw Four = 8 cards.
  - Total: 4 + 76 + 8 = **108 cards**.
- **Initial Deal**: Each player receives **7 cards**. One non-Wild card is turned face-up to start the discard pile.
- **Turn Order**: Player always goes first. In 2-player Uno, Reverse acts as Skip (AI is skipped; player plays again).
- **UI Elements**:
  - **Player Hand Row**: Shows all player cards face-up (horizontally scrollable if hand is large). Selected card is highlighted.
  - **AI Hand Row**: Shows N face-down cards (card backs). Count visible.
  - **Discard Pile**: Top card shown prominently in the center.
  - **Deck Area**: Face-down draw pile. Tap to draw.
  - **Color Indicator**: When current color differs from the top discard card's color (after a Wild), a colored indicator shows the active color.
  - **Game Message Bar**: Context-sensitive instructions (e.g., "Your turn! Play a card or draw.").
  - **Color Picker**: Appears when the player plays a Wild card; shows 4 color buttons.
- **Viking Theme**: Rune-marked cards replacing standard Uno graphics. Deep sea blue and storm grey backgrounds. Skip = crossed axes icon; Reverse = oroboros rune; Draw Two = twin spear icon; Wild = Odin's eye symbol; Wild Draw Four = Mjolnir icon. Victory plays the "Skål!" horn sound.

---

## Game States & Flow

### 1. Start of Game / New Game

**Description**: Shuffle and deal cards. Place the first non-Wild card on the discard pile. Player always takes the first turn.

**Visual State**:

- Player hand: 7 face-up cards dealt with a brief animation.
- AI hand: 7 face-down cards.
- Discard pile: 1 face-up start card (non-Wild).
- Draw pile: remaining 94 cards (108 - 14 dealt - 1 start card).
- **Game Message**: "Your turn! Play a card or draw."

**Visible UI Elements**:

- Player's 7 cards.
- AI's card count (7 face-down backs).
- Discard pile top card.
- Draw pile (tappable).
- "New Game" button.

**Available Actions**:

- Tap a player card to select it.
- Tap the draw pile to draw.

**Logic** (`_dealGame()`):

- `_buildDeck()` constructs and shuffles the 108-card deck:
  - For each of 4 colors: add one Zero, then two copies of values 1–9, Skip, Reverse, Draw Two.
  - Add 4 × Wild and 4 × Wild Draw Four (all with `UnoColor.wild`).
  - Deck is shuffled with `_rng`.
- Player hand: `deck.sublist(0, 7)`.
- AI hand: `deck.sublist(7, 14)`.
- Remaining deck starts at index 14.
- Find first non-Wild card for discard pile: `deck.indexWhere((c) => !c.isWild)`. If not found (extremely rare), index 0 is used.
- `currentColor = startCard.color`, `currentValue = startCard.value`.
- `isPlayerTurn = true`, `phase = UnoPhase.playing`.
- `selectedCardIndex = null`.

**Transition**: Deal completes → state 2 (Player Turn).

---

### 2. Player Turn (`isPlayerTurn == true`, `phase == UnoPhase.playing`)

**Description**: The human player selects and plays a card, or draws from the deck.

**Visual State**:

- **Player Hand**: All 7+ cards visible and tappable.
- **AI Hand**: N face-down cards.
- **Discard Pile**: Top card shown. Current active color indicator visible if color differs from top card (post-Wild).
- **Game Message**: "Your turn! Play a card or draw." (or a specific prompt after drawing).

**Visible UI Elements**:

- Player hand cards (each tappable).
- Selected card highlighted (if `selectedCardIndex != null`).
- Draw pile (tappable).
- **Play** button: appears when `selectedCardIndex != null` (player has a valid card selected).
- "New Game" button.

**Available Actions**:

- **Select a card**: Tap a card in hand to attempt selection.
- **Play selected card**: Tap the "Play" button (or the selected card again) to play it.
- **Draw**: Tap the draw pile to draw one card.

**Transition**:

- Valid card selected and played → state 3 (Apply Card Effect) or state 4 (Choose Color) if Wild.
- Draw card → state 2b (After Draw).

---

### 2a. Select Card (`selectCard(int index)`)

**Description**: The player taps a card in their hand.

**Logic**:

- Only operates when `isPlayerTurn == true` and `phase == UnoPhase.playing`.
- Checks `card.canPlayOn(currentColor, currentValue)`:
  - Wild cards: always playable.
  - Non-wild: playable if `card.color == currentColor` OR `card.value == currentValue`.
- If **not playable**: `selectedCardIndex = null`; message "That card can't be played. Draw or pick another."
- If **playable**: `selectedCardIndex = index`. Card is highlighted in the UI.

**Transition**: Stays in state 2.

---

### 2b. After Draw (`drawCard()`)

**Description**: The player taps the draw pile.

**Logic**:

- Only operates when `isPlayerTurn == true` and `phase == UnoPhase.playing`.
- If deck is empty: reshuffle waste pile (all discard cards except the top) back into deck.
- Remove top card from deck; add to `playerHand`.
- If the drawn card **can be played** (`drawn.canPlayOn(currentColor, currentValue)`):
  - `selectedCardIndex = newHand.length - 1` (auto-select the drawn card).
  - Message: "Drew [card] — tap to play it or pass."
  - Player can now play the drawn card or ignore it (playing is still a manual action).
- If the drawn card **cannot be played**:
  - `isPlayerTurn = false`.
  - After 700 ms delay: AI takes its turn.
  - Message: "Drew [card]. AI's turn."

**Transition**:

- Drawn card playable → stays in state 2 with card selected.
- Drawn card not playable → state 3 (AI Turn) after 700 ms.

---

### 3. Apply Player Card Effect (`playSelected()` → `_applyPlayerCard()`)

**Description**: The player confirms playing the selected card. Effects are applied based on card value.

**Visual State**:

- Card moves from player hand to discard pile with animation.
- AI hand count updates if Draw Two was played.
- AI's turn indicator activates (or player gets another turn for Skip/Reverse/Draw Two).

**Logic** (`playSelected()`):

- Called when player taps "Play" with a valid `selectedCardIndex`.
- Removes card from `playerHand`.
- **Win check**: if `newHand.isEmpty`:
  - `phase = UnoPhase.gameOver`, `winner = 'You'`, message "UNO! You win! 🎉". Stop.
- If card is Wild (`card.isWild`):
  - Set `phase = UnoPhase.choosingColor`, message "Choose a color!". → state 4 (Choose Color).
- Otherwise: call `_applyPlayerCard(card, newHand)`.

**`_applyPlayerCard` switch by `card.value`**:

| Card Value | Effect | AI Gets Skipped? |
|------------|--------|-----------------|
| `skip` | AI's turn is skipped | Yes |
| `reverse` | In 2-player: acts as Skip | Yes |
| `drawTwo` | AI draws 2 cards from deck; AI's turn skipped | Yes |
| Any number (0–9) | Normal play | No |

- If AI is **not** skipped: `isPlayerTurn = false`; after 700 ms → AI takes turn.
- If AI is **skipped**: `isPlayerTurn = false`; after 700 ms → `isPlayerTurn = true`, message "Your turn!".
- `currentColor = card.color`, `currentValue = card.value`.
- Message varies: "AI is skipped!", "Reversed! (AI skipped in 2-player)", "AI draws 2 and is skipped!", or "AI's turn." / "UNO! AI's turn." (if player hand is 1 card).

**Transition**:

- Wild → state 4 (Choose Color).
- Skip / Reverse / Draw Two → state 2 (Player Turn) after 700 ms.
- Normal card → state 5 (AI Turn) after 700 ms.
- Player hand empty → state 7 (Game Over).

---

### 4. Choose Color (`phase == UnoPhase.choosingColor`)

**Description**: The player has just played a Wild or Wild Draw Four and must choose the active color.

**Visual State**:

- Color picker overlay appears with 4 color buttons: Red, Yellow, Green, Blue.
- Discard pile shows the Wild card.
- Game message: "Choose a color!"

**Visible UI Elements**:

- **Red**, **Yellow**, **Green**, **Blue** color-choice buttons.
- No other action buttons while in this phase.

**Available Actions**:

- Tap one of the 4 color buttons.

**Logic** (`chooseColor(UnoColor color)`):

- Only operates when `phase == UnoPhase.choosingColor`.
- Determines if the last played card was Wild Draw Four:
  - `isWildDraw4 = discardPile.last.value == UnoValue.wildDrawFour`.
- If `isWildDraw4`:
  - AI draws 4 cards from deck (with deck-recycling if needed).
  - `aiGetsSkipped = true`.
- Sets `currentColor = color`, `phase = UnoPhase.playing`.
- `isPlayerTurn = false`.
- If AI skipped: after 700 ms → `isPlayerTurn = true`, message "Your turn!".
- If AI not skipped (plain Wild): after 700 ms → AI takes turn.
- Message: "AI draws 4! [color] chosen." or "[color] chosen. AI's turn."

**Transition**:

- Wild Draw Four → state 2 (Player Turn) after 700 ms (AI draws 4 and is skipped).
- Plain Wild → state 5 (AI Turn) after 700 ms.

---

### 5. AI Turn (`isPlayerTurn == false`, `phase == UnoPhase.playing`)

**Description**: The AI automatically plays a card or draws. No player input accepted during this phase.

**Visual State**:

- Player hand is greyed out / non-interactive.
- AI card count may change (decreases when AI plays, increases if AI draws).
- Discard pile updates with AI's played card.
- Game message shows what AI did.

**Visible UI Elements**:

- Player hand cards (not tappable).
- Updated AI card count.
- Updated discard pile.
- No action buttons for the player.

**Available Actions**: None (AI acts automatically after a 700 ms delay).

**Logic** (`_aiTurn()`):

- No-op if `phase == UnoPhase.gameOver` or `isPlayerTurn == true`.
- Find all playable cards: `aiHand.where((c) => c.canPlayOn(currentColor, currentValue))`.
- **If no playable card**:
  - AI draws one card from deck (recycling if needed).
  - `isPlayerTurn = true`, message "AI drew a card. Your turn!"
  - Return (AI does not play the drawn card).
- **Card selection priority** (sort order):
  1. Non-Wild action cards first (Skip, Reverse, Draw Two).
  2. Non-Wild number cards next.
  3. Wild cards last (AI conserves Wilds).
  - The sort uses: wild last (`a.isWild && !b.isWild → +1`), then action first (`a.isAction && !b.isAction → -1`).
- AI plays `playable.first` after sorting.
- AI removes card from `aiHand`.
- **Win check**: if `aiHand.isEmpty` after removing card:
  - `phase = UnoPhase.gameOver`, `winner = 'AI'`, message "AI plays [card]. UNO! AI wins!". Stop.
- **Wild color selection**: if card is Wild, AI counts color frequencies in remaining hand. Picks the most frequent non-wild color. If all remaining are Wild, picks a random color.
- **Apply action effects** (switch on `card.value`):
  - `skip` / `reverse`: player gets skipped. After 800 ms: AI takes another turn.
  - `drawTwo`: player draws 2 cards and is skipped. AI takes another turn after 700 ms.
  - `wildDrawFour`: player draws 4 cards and is skipped (fixed 2026-07-16, GB2 — previously `isPlayerTurn` was left `true` here, letting the player act immediately instead of losing their turn). AI picks best color, `isPlayerTurn = false`, AI takes another turn after 700 ms — mirrors `drawTwo` exactly.
  - All other values: `isPlayerTurn = !playerGetsSkipped`.
- Message: "AI plays [card]." or "AI plays [card] — UNO!" if AI has 1 card remaining.

**Transition**:

- AI draws (no playable card) → state 2 (Player Turn).
- AI plays Skip/Reverse → AI takes another turn after 800 ms (state 5 again).
- AI plays Draw Two → AI takes another turn after 700 ms (state 5 again).
- AI plays Wild Draw Four → AI takes another turn after 700 ms (state 5 again) — player draws 4 and is skipped, same shape as Draw Two.
- AI plays normal card → state 2 (Player Turn).
- AI hand empty → state 7 (Game Over).

---

### 6. Deck Recycle (sub-process, occurs within any draw action)

**Description**: When the draw deck is empty and a card must be drawn, the discard pile (minus the top card) is shuffled and becomes the new deck.

**Visual State**:

- Brief shuffle animation on the draw pile.
- Discard pile resets to showing only the top card.

**Logic** (inline within `drawCard`, `_aiTurn`, `_applyPlayerCard`, `chooseColor`):

```dart
if (deck.isEmpty) {
  deck = discard.sublist(0, discard.length - 1)..shuffle(_rng);
  discard = [discard.last];
}
```

- The current top of discard (the card that defines `currentColor` and `currentValue`) is preserved.
- All other discard cards are shuffled into a fresh draw deck.

**Transition**: Continues the current draw operation.

---

### 7. Game Over (`phase == UnoPhase.gameOver`)

**Description**: One player has played their last card. The game ends.

**Visual State**:

- The winning player's hand is empty.
- **Game Message**: "UNO! You win! 🎉" or "AI plays [card]. UNO! AI wins!"
- **Viking Theme**: Winner receives Skål! horn animation. Loser sees the Helm of Awe (Ægishjálmr) symbol fade in.

**Visible UI Elements**:

- Victory/defeat message.
- `winner` field: `'You'` or `'AI'`.
- **New Game** button.
- **Return to Menu** button.

**Available Actions**:

- **New Game**: Calls `newGame()` → `_dealGame()`. Full reset.
- **Return to Menu**: Navigates to game-selection screen.

**Logic**:

- Game over is detected immediately when a player's hand becomes empty after playing a card (before any action effects are applied — the win is instant on playing the last card).
- `phase = UnoPhase.gameOver`, `winner` set, final message set.
- No further turns occur.

**Transition**: "New Game" → state 1. "Return to Menu" → exits game screen.

---

## Key Game Rules Summary

### Deck Composition (108 cards)

| Card Type | Count | Details |
|-----------|-------|---------|
| Zero (0) | 4 | One per color |
| 1–9 (per color) | 72 | Two of each number, four colors |
| Skip | 8 | Two per color |
| Reverse | 8 | Two per color |
| Draw Two (+2) | 8 | Two per color |
| Wild | 4 | No color |
| Wild Draw Four (+4) | 4 | No color |
| **Total** | **108** | |

### Playability Rule

A card can be played if:
- It is Wild (always playable), OR
- Its color matches `currentColor`, OR
- Its value matches `currentValue`.

```dart
bool canPlayOn(UnoColor topColor, UnoValue topValue) {
  if (isWild) return true;
  if (color == topColor) return true;
  if (value == topValue) return true;
  return false;
}
```

### Action Card Effects (2-Player Rules)

| Card | Effect on opponent | Notes |
|------|--------------------|-------|
| Skip | Opponent loses their turn | Opponent draws nothing |
| Reverse | In 2-player: acts as Skip | Opponent loses their turn |
| Draw Two (+2) | Opponent draws 2 cards AND loses their turn | Applied immediately |
| Wild | Played by current player; they choose the new active color | No card draw |
| Wild Draw Four (+4) | Opponent draws 4 cards AND loses their turn; player chooses color | |

### Deck Recycling

- When the draw pile is empty, the discard pile (all cards except the current top card) is shuffled and becomes the new draw pile.

### Win Condition

- The first player to empty their hand wins immediately upon playing their last card.
- There is no point scoring in the current implementation — wins are binary (win or lose).

### UNO Declaration

- When a player's hand drops to 1 card after playing, the message shows "UNO!" as a notification. There is no penalty mechanic for failing to call UNO in the current implementation.

---

## Enhancements & Edge Cases

### 2-Player Reverse = Skip

- In standard Uno with more players, Reverse changes direction. With 2 players, reversing direction means the same player goes again, which is equivalent to Skip. The implementation hardcodes this: `case UnoValue.reverse: aiGetsSkipped = true` (from player) and `case UnoValue.reverse: playerGetsSkipped = true` (from AI).

### AI Skip Chain

- When AI plays Skip or Reverse, the implementation triggers another `_aiTurn` call after 800 ms. This means the AI immediately takes a second turn rather than returning control to the player.

### AI Draw Two Chaining

- When AI plays Draw Two, player draws 2 cards, then `_aiTurn` is called after 700 ms. The AI gets an immediate follow-up turn.

### Wild Draw Four Symmetry

- When the **player** plays Wild Draw Four: `chooseColor()` is called; in `chooseColor`, if `isWildDraw4`, AI draws 4 and is skipped.
- When the **AI** plays Wild Draw Four: player draws 4 from within `_aiTurn`; `isPlayerTurn = false` and AI takes another turn after 700 ms — symmetric with the player-played case (fixed 2026-07-16, GB2; previously `isPlayerTurn = true` let the player act immediately instead of losing their turn, same shape as the `drawTwo` case right above it in the same switch).

### Empty Hand on Wild

- The win check in `playSelected()` occurs **before** the Wild color-picker is shown. If the player's last card is a Wild, the game ends immediately without showing the color picker (correct behavior — no more cards to play).

### Drawn Card Auto-Selection

- When `drawCard()` results in a playable card being drawn, `selectedCardIndex` is automatically set to the new card's index. The player still must manually press "Play" — it does not auto-play.

### AI Conserves Wilds

- AI's card-selection sort places Wild cards last. The AI only plays a Wild if it is the only playable card.

### AI Color Strategy

- AI picks the most frequent non-Wild color in its remaining hand. If all remaining cards are Wilds: picks a random color from 0–3 (`_rng.nextInt(4)`).

### No Action-Card Stacking (Official Rule, By Design)

- This implementation does **not** allow stacking: if a Draw Two or Wild Draw Four is played, the targeted player (AI or human) immediately draws the penalty cards and loses their turn — they get no opportunity to play a matching Draw Two/Wild Draw Four of their own in response to pass the penalty along, even if one is in their hand. The draw + skip happens synchronously as part of applying the card, before the target's turn ever begins. This matches the official Uno rules (stacking is a common house-rule variant, not the base ruleset) and is an intentional design decision, not an oversight.

### Deck Shortage During Action Effects

- Within `_applyPlayerCard` for Draw Two, deck recycling is performed inline:
  ```dart
  if (deck.isEmpty) { deck = discard.sublist(0, discard.length - 1)..shuffle(_rng); discard = [discard.last]; }
  ```
  This can be called twice within the same Draw Two loop (once per card drawn).

---

## Implementation Notes

### State Management

Global state is managed by `UnoNotifier extends Notifier<UnoState>` in `lib/ui/games/games/uno/logic.dart`.

**`UnoState` fields**:

| Field | Type | Description |
|-------|------|-------------|
| `deck` | `List<UnoCard>` | Remaining draw pile |
| `playerHand` | `List<UnoCard>` | Player's current cards |
| `aiHand` | `List<UnoCard>` | AI's current cards |
| `discardPile` | `List<UnoCard>` | Played cards (top = last = current) |
| `currentColor` | `UnoColor` | Active color (may differ from top discard after Wild) |
| `currentValue` | `UnoValue` | Active value (top discard) |
| `isPlayerTurn` | `bool` | True when player should act |
| `phase` | `UnoPhase` | `playing`, `choosingColor`, or `gameOver` |
| `message` | `String` | UI instruction/result message |
| `winner` | `String?` | `'You'`, `'AI'`, or null during play |
| `selectedCardIndex` | `int?` | Index of player's selected card, or null |

**`UnoPhase` enum values**:

| Value | Meaning |
|-------|---------|
| `playing` | Normal turn in progress |
| `choosingColor` | Player played a Wild; awaiting color choice |
| `gameOver` | A player has won |

**`UnoColor` enum**: `red`, `yellow`, `green`, `blue`, `wild`.

**`UnoValue` enum**: `zero` through `nine`, `skip`, `reverse`, `drawTwo`, `wild`, `wildDrawFour`.

**`UnoCard` class**:

```dart
class UnoCard {
  final UnoColor color;
  final UnoValue value;
  bool get isWild => color == UnoColor.wild;
  bool get isAction => value == UnoValue.skip || value == UnoValue.reverse ||
      value == UnoValue.drawTwo || value == UnoValue.wild ||
      value == UnoValue.wildDrawFour;
  bool canPlayOn(UnoColor topColor, UnoValue topValue) { … }
}
```

**Provider**:

```dart
final unoStateProvider = NotifierProvider<UnoNotifier, UnoState>(UnoNotifier.new);
```

### UI Logic Snippets

```dart
// Player can interact with their hand
bool isPlayerInputEnabled(UnoState s) =>
    s.isPlayerTurn && s.phase == UnoPhase.playing;

// Show Play button only when a card is selected
bool shouldShowPlayButton(UnoState s) =>
    s.isPlayerTurn && s.selectedCardIndex != null;

// Show color picker
bool shouldShowColorPicker(UnoState s) =>
    s.phase == UnoPhase.choosingColor;

// Show game-over screen
bool isGameOver(UnoState s) => s.phase == UnoPhase.gameOver;

// A card is selected
bool isCardSelected(UnoState s, int idx) =>
    s.selectedCardIndex == idx;

// Card can be played (for visual greying-out)
bool isCardPlayable(UnoState s, int idx) =>
    s.playerHand[idx].canPlayOn(s.currentColor, s.currentValue);

// Active color indicator (show when top card is Wild and color was chosen)
bool showColorIndicator(UnoState s) =>
    s.discardPile.isNotEmpty && s.discardPile.last.isWild;
```

### Folder Structure

- **Logic**: `lib/ui/games/games/uno/logic.dart` — all game logic, state, notifier.
- **Screen**: `lib/ui/games/games/uno/screen.dart` — UI widgets consuming `unoStateProvider`.
- **Assets**: `assets/games/uno/` — runic card faces, Viking-themed Skip/Reverse/Draw Two icons, background.

### Testing Guidance

- **Unit tests** (`test/games/uno/`):
  - `_buildDeck()`: verify exactly 108 cards; correct counts per type.
  - `canPlayOn`: Wild always true; color match; value match; neither match = false.
  - `_dealGame()`: 7 player cards, 7 AI cards, 1 start card (non-Wild), remainder in deck.
  - `_applyPlayerCard` for Skip: AI gets skipped, player gets another turn.
  - `_applyPlayerCard` for Reverse: same as Skip in 2-player.
  - `_applyPlayerCard` for Draw Two: AI hand grows by 2.
  - `chooseColor` for Wild Draw Four: AI hand grows by 4.
  - `_aiTurn` card priority: prefers action over numbers, wild last.
  - `_aiTurn` color selection: picks most frequent color.
  - Win detection: playing last card sets `phase = UnoPhase.gameOver`.
  - Deck recycle: playing cards empties deck → discard shuffled into deck.
- **Integration tests**: Full game to win (seed deterministic rng and verify win path).
- Aim for 90%+ coverage on card-effect application and win detection.

### Viking Theme

- Use `SisuColors` from `lib/core/colors.dart` and `SisuMateTheme` from `lib/core/theme.dart`.
- Card backgrounds: deep sea blue with rune borders.
- Skip icon: crossed axes — `assets/games/uno/skip.png`.
- Reverse icon: Ouroboros rune — `assets/games/uno/reverse.png`.
- Draw Two icon: twin spears — `assets/games/uno/draw_two.png`.
- Wild icon: Odin's eye (Valknut) — `assets/games/uno/wild.png`.
- Wild Draw Four icon: Mjolnir — `assets/games/uno/wild_draw_four.png`.
- Victory: Skål! horn sound + runestone rise animation.
- Font: follow the NotoSansRunic pattern used across the app's Viking theme.

## Known Gaps / Future Work

| Gap | Notes |
|---|---|
| No UNO-call penalty | When a player's hand drops to 1 card, "UNO!" is only shown as a notification message. There is no requirement to declare it and no catch-penalty (official rule: an opponent who catches you failing to call UNO before your next turn starts can force you to draw 2 cards). |
| No Wild Draw Four challenge | Official Uno lets the target of a Wild Draw Four challenge it, forcing the player who played it to reveal their hand; if they had a matching-color card they could have played instead, they draw 4 themselves rather than the target. Neither `chooseColor()` nor `_aiTurn()`'s `wildDrawFour` branch implement this — Wild Draw Four is always unconditionally playable and never challenged. |

## Next Steps

1. Add visual UNO alert animation when a player reaches 1 card.
2. Generate Viking-themed card assets in `assets/games/uno/` after user confirmation.
3. Write unit tests in `test/uno_test.dart` covering all action card effects.
