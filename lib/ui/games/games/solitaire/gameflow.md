# 📜 Solitaire (Klondike) – Consolidated Game Flow Documentation

This document describes the complete game flow for Klondike Solitaire in the SisuMate app, following the Viking-themed aesthetic established across SisuMate Games. It covers all game states, UI interactions, tap mechanics, and state management, giving developers a precise reference that matches the actual implementation in `lib/ui/games/games/solitaire/logic.dart`.

## Game Structure

- **Players**: 1 (single-player only — no AI opponent).
- **Modes**: Single-player puzzle **by design**. Not in GAME1 multiplayer scope (Klondike has no second player to host/join against).
- **Goal**: Move all 52 cards to the four foundation piles, sorted by suit from Ace to King.
- **Deck**: Standard 52-card deck, no jokers.
- **Layout**:
  - **Stock** (draw pile): Cards remaining after the initial deal, face-down. Tapping draws one card to the waste.
  - **Waste** (discard pile): Cards flipped from the stock. Only the top card is available for play. Tapping it toggles selection (tap again to deselect) — there is no automatic move to a foundation on tap; the player must select the card, then tap the destination foundation or tableau column.
  - **Foundations**: 4 piles (one per suit: ♣♦♥♠). Built up from Ace to King, same suit.
  - **Tableau**: 7 columns (piles 0–6). Columns alternate red-on-black descending rank. Pile 0 has 1 card (face-up); pile 1 has 1 face-down + 1 face-up; pile N has N face-down + 1 face-up.
- **Moves Counter**: Every tap that changes game state increments `moves` by 1.
- **Win Condition**: All four foundations contain 13 cards each (`foundations.every((f) => f.length == 13)`).
- **UI Elements**:
  - **Stock area**: Shows top of face-down pile (or empty placeholder). Tap to draw.
  - **Waste area**: Shows top face-up card. Tap to select; tapping the already-selected waste card again deselects it. No auto-move to foundation occurs on tap.
  - **Foundation areas**: 4 slots at top-right. Show top card of each suit pile.
  - **Tableau area**: 7 columns displayed vertically with overlapping cards. Face-down cards shown as card backs; face-up cards shown fully.
  - **Move counter**: Displayed in UI header.
  - **Selection highlight**: Selected card(s) are highlighted in gold/amber to indicate drag origin.
- **Viking Theme**: Fjord-blue card backs with Norse knotwork, stone-table tableau background, runic suit symbols replacing standard pip symbols. Victory triggers a longship sailing animation.

---

## Game States & Flow

### 1. Deal / New Game

**Description**: Shuffle the deck and lay out the initial Klondike tableau. This state occurs at app launch (from the Solitaire screen) and after "New Game" is tapped.

**Visual State**:

- **Tableau**: 7 columns spread out. Columns 0–6 have 1–7 cards respectively, with all but the top card of each column shown face-down (card backs). The top card of every column is face-up.
- **Stock**: Remaining 24 cards are in the stock pile (face-down). Displayed as a face-down stack.
- **Waste**: Empty.
- **Foundations**: All four empty.
- **Move Counter**: 0.
- Brief deal animation as cards slide into position.

**Visible UI Elements**:

- 7 tableau columns.
- Stock pile area.
- Waste pile area (empty initially).
- 4 foundation slots (empty).
- Move counter.
- "New Game" button (available at all times).

**Available Actions**:

- Tap stock to draw.
- Tap waste top card to select it.
- Tap tableau face-up card to select it.

**Logic** (`_deal()`):

- A 52-card deck (`List.generate(52, (i) => i)`) is shuffled.
- Tableau column `i` receives `i` face-down cards followed by 1 face-up card (total `i + 1` cards).
  - `faceDownCounts[i] = i` (the number of face-down cards at the bottom of pile `i`).
- Remaining cards (index 28 onward, 24 cards) go to `stock`.
- All foundations start empty; `waste` starts empty.
- `phase = SolitairePhase.playing`, `moves = 0`, `selection = null`.

**Note on card encoding**: In Solitaire, `rankOf(c) = c % 13` where **0 = Ace** and **12 = King** (different from the Poker encoding where 0 = 2). Foundation builds Ace (rank 0) through King (rank 12).

**Transition**: Deal completes → state 2 (Playing).

---

### 2. Playing (`SolitairePhase.playing`)

**Description**: The main gameplay loop. The player taps cards to select them and taps destination piles to move them. This state persists until the player wins.

**Visual State**:

- All 7 tableau columns visible with face-down and face-up cards.
- Stock and waste piles at the top.
- Foundations at the top-right.
- Selected card(s) highlighted (gold border or raised effect).
- Move counter incrementing.

**Visible UI Elements**:

- All tableau columns, stock, waste, foundations.
- Move counter.
- "New Game" button.

**Available Actions**:

All actions below are sub-states within the `playing` phase. Selection is stored in `state.selection`.

- **Tap Stock** → draw one card to waste (or recycle waste to stock if stock empty).
- **Tap Waste** → toggle selection of the top waste card (select it, or deselect if already selected). This does **not** auto-move it to a foundation — the player must then tap the destination foundation or tableau column.
- **Tap Foundation** → if a card is selected, attempt to move it to that foundation pile.
- **Tap Tableau card** → if a card is selected, attempt to move selection there; otherwise select the tapped card.
- **Tap empty Tableau column** → if a card is selected and is a King, move it to the empty column.

**Transition**: If `foundations.every((f) => f.length == 13)` after any move → state 3 (Won).

---

### 2a. Tap Stock (`tapStock()`)

**Description**: The player taps the stock pile to draw a card.

**Visual State**:

- Top card from stock transfers to waste (face-up) with a flip animation.
- If stock was empty: entire waste pile is flipped face-down back into stock. Waste becomes empty.

**Available Actions**:

- Tap stock again to draw the next card.
- Selection is cleared on stock tap.

**Logic**:

- If `stock.isEmpty` and `waste.isEmpty`: no-op (nothing to do).
- If `stock.isEmpty` and `waste` has cards: recycle — `stock = waste.reversed.toList()`, `waste = []`. Moves counter does NOT increment in this case.
- Otherwise: remove `stock.last` → append to `waste`. `moves += 1`. Any existing `selection` is cleared.

**Transition**: Stays in state 2 (Playing).

---

### 2b. Tap Waste (`tapWaste()`)

**Description**: The player taps the waste pile's top card. This is a pure selection toggle — it never moves the card by itself.

**Visual State**:

- Top waste card is highlighted as selected.
- If it was already selected, the highlight is removed (deselected).

**Available Actions**:

- First tap: card is selected (`selection = Selection(PileType.waste, 0, waste.length - 1)`).
- Tap again while selected: selection is cleared (toggle off).
- To actually move the card, the player must tap a foundation (`tapFoundation`) or tableau column (`tapTableau`/`tapEmptyTableau`) next — see 2c/2d/2e.

**Logic**:

- If `waste.isEmpty`: no-op.
- If `selection?.pile == PileType.waste`: clear selection, return (deselect).
- Otherwise: set `selection = Selection(PileType.waste, 0, waste.length - 1)`.
- `moves` is **not** incremented by this tap — no card actually moves yet.

**Transition**: Stays in state 2 (Playing).

---

### 2c. Tap Foundation (`tapFoundation(int i)`)

**Description**: The player taps a foundation pile while a card is selected.

**Visual State**:

- If move is valid: card slides to foundation. Selection clears.
- If invalid: selection remains unchanged (or clears to indicate failure).

**Available Actions**:

- Only possible when `selection != null`.

**Logic**:

- `tapFoundation(int i)`:
  - Reads selected card from waste or tableau (only the last card of a tableau pile can go to foundation — no multi-card moves to foundation).
  - Calls `_canPlaceOnFoundation(card, i)`: checks suit match and sequential rank.
  - If valid: calls `_moveToFoundation(card, sel, i)`.
    - Removes card from source (waste or tableau).
    - If removed from tableau: checks if the newly exposed top card was face-down and flips it (`faceDownCounts` decremented).
    - Adds card to `foundations[i]`.
    - `moves += 1`. `selection = null`.
    - Checks win condition: `phase = SolitairePhase.won` if all foundations complete.

**Transition**: Stays in state 2 (Playing) or transitions to state 3 (Won).

---

### 2d. Tap Tableau (`tapTableau(int pileIdx, int cardIdx)`)

**Description**: The player taps a card within a tableau column, either to select it or to move a previously selected card there.

**Visual State**:

- If a card is selected and the move is valid: card(s) slide from source to destination. Face-down card flips at source if newly exposed.
- If no selection and card is face-up: card (and all cards above it in the column) are selected and highlighted.
- If card is face-down: no action (face-down cards cannot be selected).

**Available Actions**:

- Tap to select any face-up card in any column.
- Tap destination column with selection active to move.
- Tap the same column/card a second time to deselect.

**Logic**:

- If `cardIdx < faceDownCounts[pileIdx]`: no-op (face-down card, cannot interact).
- If `selection != null`:
  - Determine `movingCards` from the selection source (waste = single card; tableau = sublist from `sel.cardIndex` to end).
  - Call `_canPlaceOnTableau(movingCards.first, pileIdx)`:
    - Empty pile: only Kings allowed (`rankOf(card) == 12`).
    - Non-empty pile: moving card must be opposite color (`isRed(card) != isRed(pile.last)`) AND one rank lower (`rankOf(card) == rankOf(pile.last) - 1`).
  - If valid: call `_moveToTableau(movingCards, sel, pileIdx)`.
    - Remove cards from source (waste.removeLast or tableau.removeRange).
    - Flip newly exposed face-down card at source if needed.
    - Append all moving cards to destination pile.
    - `moves += 1`. `selection = null`.
  - If invalid and same pile tapped: deselect.
- If `selection == null`:
  - Set `selection = Selection(PileType.tableau, pileIdx, cardIdx)` for the tapped face-up card.

**Transition**: Stays in state 2 (Playing).

---

### 2e. Tap Empty Tableau (`tapEmptyTableau(int pileIdx)`)

**Description**: The player taps an empty tableau column with a card (or stack) selected.

**Visual State**:

- If the selected card is a King: entire selected stack moves to the empty column.
- If not a King: no-op; selection remains.

**Logic**:

- Only Kings (`rankOf(movingCards.first) == 12`) may be placed on empty columns.
- Calls `_moveToTableau` with the empty pile index.
- `moves += 1`. `selection = null`.

**Transition**: Stays in state 2 (Playing).

---

### 3. Won (`SolitairePhase.won`)

**Description**: All 52 cards are on the four foundation piles (Ace through King per suit). The game is complete.

**Visual State**:

- All 4 foundations are full (13 cards each, showing Kings on top).
- Tableau is empty.
- Stock and waste are empty.
- **Viking Theme**: A longship sails across the screen; runestones rise from the sea in victory.
- **Game Message**: "Victory! You completed the game in N moves." (or similar).
- Final move count displayed prominently.

**Visible UI Elements**:

- Victory message and move count.
- **New Game** button.
- **Return to Menu** button.

**Available Actions**:

- **New Game**: Calls `newGame()` → `_deal()`. Fully resets all state.
- **Return to Menu**: Navigates to the app's game-selection screen.

**Logic**:

- Win check occurs inside `_moveToFoundation`: after adding a card, `foundations.every((f) => f.length == 13)` is evaluated. If true, `phase = SolitairePhase.won`.
- Also available as a method: `state.isWon()` returns `foundations.every((f) => f.length == 13)`.
- No further card interactions are possible in this phase.

**Transition**: "New Game" → state 1 (Deal). "Return to Menu" → exits game screen.

---

## Key Game Rules Summary

### Card Encoding (Solitaire)

```
card = 0..51
suit = card ~/ 13    // 0=♣, 1=♦, 2=♥, 3=♠
rank = card % 13     // 0=A, 1=2, 2=3, …, 11=Q, 12=K
isRed(c) = suit == 1 (♦) || suit == 2 (♥)
```

**Important**: Solitaire rank 0 = Ace, rank 12 = King. This is the **inverse** of the Poker encoding.

### Foundation Rules

- Each foundation is tied to one suit by index: `foundations[0]` = ♣, `[1]` = ♦, `[2]` = ♥, `[3]` = ♠.
- A card can be placed on foundation `i` if:
  - `suitOf(card) == i` (same suit), AND
  - Foundation is empty AND `rankOf(card) == 0` (Ace), OR
  - Foundation is non-empty AND `rankOf(card) == rankOf(foundations[i].last) + 1` (next rank up).

### Tableau Rules

- A card (or stack of face-up cards) can be placed on tableau pile `i` if:
  - Pile is empty AND `rankOf(card) == 12` (King only), OR
  - Pile is non-empty AND `isRed(card) != isRed(pile.last)` (alternating color) AND `rankOf(card) == rankOf(pile.last) - 1` (one rank lower).
- Multi-card moves: any contiguous face-up sequence from `cardIndex` to the bottom of the column is moved as a unit.

### Stock and Waste Rules

- Tap stock: flip top card to waste (1-card draw).
- If stock empty: recycle waste pile (reversed) back into stock. This does **not** count as a move.
- Only the **top card** of waste is playable.

### Face-Down Flipping

- When the top card of a tableau pile is removed (moved to foundation or another pile), the newly exposed card is automatically flipped face-up:
  - `faceDownCounts[pileIdx]` is decremented if it equals or exceeds the new pile length.

### Move Count

- `moves` increments by 1 for every: stock draw, waste-to-foundation auto-move, manual move to foundation, or move to tableau.
- Recycling the waste pile to stock does not increment moves.

---

## Enhancements & Edge Cases

### No Auto-Move to Foundation

- Tapping the waste (or a tableau card) never auto-sends it to a foundation — every foundation move requires the player to select the card, then explicitly tap the destination foundation. There is no one-tap "quick send" shortcut, even when the tapped card is the only legal foundation candidate.
- No auto-complete sweep is implemented in the current logic — the player must manually move each card once all face-down cards are flipped. (An auto-complete enhancement could be added by iterating safe moves until `isWon()`.)
- A `computeHint(state)` static helper (surfaced via the lightbulb icon / `hintModeProvider` in `screen.dart`) suggests the next legal move as text, but does not perform it — the player still must tap it out manually.

### Empty Tableau with No King

- If a tableau pile empties and the player has no King available in hand, waste, or a movable sequence, the column is temporarily stuck empty. No move is possible to that column until a King becomes available.

### Selection Cleared by Stock Tap

- Tapping the stock always clears the current `selection`. This is intentional — the player can't hold a selection while drawing.

### Multi-Card Moves

- In `tapTableau`, `movingCards = fromPile.sublist(sel.cardIndex)` — all face-up cards from the selected index to the end of the pile are moved together.
- The validity check uses only `movingCards.first` (the card that lands on the destination pile's current top card). The cards below it in the moving sequence are assumed to already form a valid alternating sequence.

### Face-Down Count Underflow

- `faceDownCounts[pileIdx]` is never allowed to go below 0 (clamped with `if (newFaceDown[sel.pileIndex] < 0) newFaceDown[sel.pileIndex] = 0`).

### Impossible Deals

- A random Klondike deal has approximately a 79–82% theoretical win rate. The current implementation makes no attempt to guarantee a winnable deal. A "new game" simply reshuffles.

### Selection on Same Pile

- Tapping a different face-up card within the same pile while a lower card in that pile is already selected: the selection updates to the new card index.
- Tapping the same card index on the already-selected pile: deselects (only if the attempted placement failed).

---

## Implementation Notes

### State Management

Global state is managed by `SolitaireNotifier extends Notifier<SolitaireState>` in `lib/ui/games/games/solitaire/logic.dart`.

**`SolitaireState` fields**:

| Field | Type | Description |
|-------|------|-------------|
| `stock` | `List<int>` | Face-down draw pile (top = last) |
| `waste` | `List<int>` | Face-up discard pile (top = last) |
| `foundations` | `List<List<int>>` | 4 suit piles (index = suit), each Ace→King |
| `tableaux` | `List<List<int>>` | 7 tableau columns (index 0–6) |
| `faceDownCounts` | `List<int>` | Number of face-down cards at bottom of each tableau |
| `selection` | `Selection?` | Currently selected pile/card, or null |
| `phase` | `SolitairePhase` | `playing` or `won` |
| `moves` | `int` | Total moves made this game |
| `message` | `String` | Short player-facing feedback string (e.g. "Foundation needs A♠ next.", "Moved 3 cards."), shown in the header message bar; overridden by the hint text when hint mode is on |

**`Selection` class**:

```dart
class Selection {
  final PileType pile;     // stock, waste, foundation, tableau
  final int pileIndex;     // foundation 0-3, tableau 0-6 (ignored for waste/stock)
  final int cardIndex;     // index within that pile's visible stack
}
```

**`SolitairePhase` enum values**:

| Value | Meaning |
|-------|---------|
| `playing` | Normal gameplay |
| `won` | All foundations complete |

**`PileType` enum values**: `stock`, `waste`, `foundation`, `tableau`.

**Provider**:

```dart
final solitaireProvider =
    NotifierProvider<SolitaireNotifier, SolitaireState>(SolitaireNotifier.new);
```

**Hint system**: `SolitaireNotifier.computeHint(SolitaireState s)` is a static method that inspects the current state (waste→foundation, waste→tableau, tableau→foundation, tableau→tableau, then stock/recycle) and returns a human-readable string describing one legal move, without mutating state. `screen.dart` toggles display of this text via the shared `hintModeProvider` (defined in `lib/core/di.dart`, not in this game's `logic.dart`) and a lightbulb `IconButton` in the app bar. This is advisory only — no move is performed automatically.

### UI Logic Snippets

```dart
// A card at (pileIdx, cardIdx) in tableau is face-up if:
bool isFaceUp(SolitaireState s, int pileIdx, int cardIdx) =>
    cardIdx >= s.faceDownCounts[pileIdx];

// A card is selected
bool isSelected(SolitaireState s, PileType pile, int pileIdx, int cardIdx) {
  final sel = s.selection;
  if (sel == null) return false;
  if (sel.pile != pile) return false;
  if (pile == PileType.tableau) {
    return sel.pileIndex == pileIdx && cardIdx >= sel.cardIndex;
  }
  return true; // waste: the single top card
}

// The waste top card (playable card)
int? wasteTop(SolitaireState s) =>
    s.waste.isEmpty ? null : s.waste.last;

// Foundation shows its top card (or empty)
int? foundationTop(SolitaireState s, int i) =>
    s.foundations[i].isEmpty ? null : s.foundations[i].last;

// Stock shows a face-down card if non-empty, or a recycle indicator if empty
bool stockHasCards(SolitaireState s) => s.stock.isNotEmpty;

// Win check
bool isWon(SolitaireState s) => s.phase == SolitairePhase.won;
```

### Folder Structure

- **Logic**: `lib/ui/games/games/solitaire/logic.dart` — all game logic, state, notifier.
- **Screen**: `lib/ui/games/games/solitaire/screen.dart` — UI widgets consuming `solitaireProvider`.
- **Assets**: `assets/games/solitaire/` — card back art (Norse knotwork), table background (stone/fjord-blue), suit symbols (runic).

### Testing Guidance

- **Unit tests** (`test/games/solitaire/`):
  - `_deal()`: verify tableau column i has i face-down + 1 face-up; stock has 24 cards; all 52 cards accounted for.
  - `_canPlaceOnFoundation`: Ace on empty; sequential same-suit; non-sequential fails; wrong suit fails.
  - `_canPlaceOnTableau`: King on empty; red-on-black alternating; black-on-red alternating; same-color fails; non-sequential fails.
  - `tapStock` recycling: waste reversed → stock; waste clears.
  - Face-down flip: after removing top card of tableau pile, next card flips face-up (faceDownCounts decremented).
  - Win detection: after placing 13th card of last foundation, `phase == SolitairePhase.won`.
  - Multi-card tableau move: sublist from selection index transfers correctly.
- **Integration tests**: Full game to win (seed a solvable deal and simulate moves).
- Aim for 90%+ coverage on move-validation logic.

### Viking Theme

- Use `SisuColors` from `lib/core/colors.dart` and `SisuMateTheme` from `lib/core/theme.dart`.
- Card back: Norse knotwork pattern in fjord blue — `assets/games/solitaire/card_back.png`.
- Background: carved stone table — `assets/games/solitaire/bg.png`.
- Victory: longship sailing animation across screen — `assets/games/solitaire/victory.gif`.
- Suit symbols replaced with runic equivalents where possible.
- Font: follow the NotoSansRunic pattern used across the app's Viking theme.

## Known Gaps / Future Work

| Gap | Notes |
|---|---|
| No one-tap "send to foundation" | Every foundation move requires an explicit two-step select-then-tap-foundation, even for a waste/tableau card that is the *only* legal foundation move available. Real-world Klondike players (and most digital implementations) expect a tap/double-tap shortcut here; this doc previously (incorrectly) described such a shortcut as implemented — it is not. Worth logging as a product enhancement, not a correctness bug. |
| No auto-complete sweep | Once all tableau cards are face-up, a human would expect the game to offer to auto-finish; not implemented (tracked in Next Steps below). |
| No redeal/pass limit or scoring | Stock recycling is unlimited and free (does not increment `moves`), matching casual/relaxed Klondike rules rather than "Vegas" scoring rules (which cap redeals and track a cash score). This is a deliberate variant choice, not a bug, but is worth confirming is the intended house rule. |
| No move back from foundation | Once a card is placed on a foundation it can never be selected or moved again (no foundation→tableau or foundation→waste path exists). Some real-world rule sets permit pulling a foundation card back into play; this implementation does not. |

## Next Steps

1. Implement drag-and-drop card movement in `screen.dart` (currently tap-to-select/tap-to-place).
2. Add auto-complete sweep: when all face-down cards are gone, automatically move safe cards to foundations until `isWon()`.
3. Add a move-hint system (highlight a valid move when the player is stuck). — Partially done: `computeHint()` + `hintModeProvider` already provide a text hint; only the visual highlight is outstanding.
4. Generate Viking-themed card-back asset in `assets/games/solitaire/` after user confirmation.
5. Write unit tests covering all move-validation functions in `test/games/solitaire/logic_test.dart`.
