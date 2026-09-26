# 📜 Checkers – Game Flow Documentation

This document describes the complete game flow for Checkers (Draughts) in the SisuMate app. It covers all game states, UI interactions, rules, edge cases, and implementation details. It aligns with the Viking-themed aesthetic and single-player (human vs. AI) focus of the current implementation. The document is written so that an AI programmer could implement the game from scratch using it alone.

## Game Structure

- **Players**: 2 — Human (red) vs. AI (black).
- **Modes**: Human vs. AI, or local Wi-Fi multiplayer via the Games lobby (`GameCatalog.multiplayerReady` in `lib/core/app_router.dart` is the source of truth).
- **Rounds**: A single continuous game. No round structure.
- **Focus**: Alternating turns. Human always moves first.
- **Board**: 8×8 grid. Only dark squares are used (where `(row + col) % 2 == 1`). Rows 0–7, columns 0–7.
  - **Human (red)**: starts at rows 0–2. Moves toward row 7 (increasing row index).
  - **AI (black)**: starts at rows 5–7. Moves toward row 0 (decreasing row index).
- **Piece values** (internal board integers):
  - `0` = empty
  - `1` = human regular piece (red)
  - `2` = AI regular piece (black)
  - `3` = human king (red king)
  - `4` = AI king (black king)
- **Promotion (King)**: A regular piece reaching the opponent's back row is promoted to king.
  - Human piece reaching row 7 → becomes `3` (red king).
  - AI piece reaching row 0 → becomes `4` (black king).
  - Kings move in all 4 diagonal directions (forward and backward).
- **Win Conditions**:
  - A player wins if the opponent has no pieces remaining on the board.
  - A player wins if the opponent has no legal moves (all pieces are blocked).
- **UI Elements**:
  - **Board Display**: 8×8 grid with piece icons.
  - **Game Message**: Instructions, AI status, win/loss announcement.
  - **Piece Selection**: Human taps a red piece to select it; valid destinations are highlighted.
- **Viking Theme**: Carved wooden board (dark/light squares in Norse palette), rune-etched pieces, Viking warrior icons for kings.

---

## Game States & Flow

### 1. Start of Game

**Description**: Initialize the board, compute all valid first moves, and wait for the human to select a piece.

**Visual State**:

- Board: human (red) pieces on rows 0–2 dark squares; AI (black) pieces on rows 5–7 dark squares. Rows 3–4 empty.
- No piece selected. No destinations highlighted.
- Game message: `'Your turn — tap a red piece to select it.'`
- `phase` = `GamePhase.playing`, `isPlayerTurn` = `true`.
- `allMoves` is pre-computed for the human's opening position.

**Visible UI Elements**:

- 8×8 board with all pieces in starting positions.
- No buttons (the entire game is tap-driven).

**Available Actions**:

- Human taps a red piece.

**Logic**:

`CheckersNotifier.build()` calls `_buildInitialBoard()` and `getAllMoves(board, true)`.

`_buildInitialBoard()`:
```dart
for (int r = 0; r < 3; r++) {
  for (int c = 0; c < 8; c++) {
    if ((r + c) % 2 == 1) board[r][c] = 1; // human red
  }
}
for (int r = 5; r < 8; r++) {
  for (int c = 0; c < 8; c++) {
    if ((r + c) % 2 == 1) board[r][c] = 2; // AI black
  }
}
```

Each player starts with 12 pieces (3 rows × 4 dark squares per row).

`getAllMoves(board, isPlayerTurn)` scans all pieces belonging to the active player and returns all valid moves. If any jump moves exist, only jump moves are returned (mandatory jump rule — see Key Rules). `allMoves` is the full set of currently available moves for the active player.

**Transition**: Human taps a red piece → state 2 (Select Piece).

---

### 2. Select Piece (Human)

**Description**: Human taps a piece to select it. The valid destinations for that piece are computed and highlighted.

**Visual State**:

- The tapped piece is visually highlighted (selected state: e.g., glow ring or raised appearance).
- Valid destination squares are highlighted (e.g., green tint or rune-circle marker).
- Game message: `'Your turn — tap a red piece to select it.'` (unchanged until a valid piece is selected).
- `selectedRow` and `selectedCol` are set.
- `validMoves` contains the list of `CheckersMove` objects reachable from the selected piece.

**Visible UI Elements**:

- Board fully visible.
- Selected piece highlighted.
- Valid destinations highlighted.

**Available Actions**:

- Tap a highlighted destination → execute the move (state 3).
- Tap a different red piece → re-select (state 2 restarts with new piece).
- Tap an empty or black square → deselect (return to unselected state).

**Logic**:

`selectCell(int row, int col)` is called on every board tap.

1. If `phase == GamePhase.gameOver` or `!isPlayerTurn`: return immediately.
2. If a piece is already selected (`selectedRow != null`):
   - Check if `(row, col)` is a valid destination in `validMoves`. If yes → `_executeMove`.
   - If the player taps a different red piece, re-select it (step 3 below).
3. If tapping a human piece (`_isHumanPiece(board[row][col])`):
   - **Mandatory jump check**: if `allMoves.first.captured.isNotEmpty` (jump moves exist), only allow selecting pieces that have jump moves in `allMoves`. A piece with no jump move during a mandatory jump turn cannot be selected.
   - Compute `pieceMoves`:
     - If mandatory jump: filter `allMoves` for moves starting at `(row, col)`.
     - Otherwise: call `getMovesForPiece(board, row, col)`.
   - If `pieceMoves.isEmpty`: deselect (clear `selectedRow`, `selectedCol`, `validMoves`).
   - Otherwise: set `selectedRow = row`, `selectedCol = col`, `validMoves = pieceMoves`.
4. Tap on empty or AI square with no piece already selected: deselect.

**Transition**: Valid destination tapped → state 3 (Execute Move).

---

### 3. Execute Move (Human)

**Description**: Apply a human move — move the piece, remove any captured pieces, check for king promotion, check for chain jump, then either require chain jump continuation or pass to AI.

**Visual State**:

- Moving piece animation: piece slides from source to destination.
- Captured piece(s) removed from board (disappear animation).
- If king promotion: piece visually upgrades (crown/rune added).
- If chain jump required: piece stays selected at new position, new valid destinations highlighted.
- Game message during chain: `'Jump again! You must continue the chain.'`
- After full move: `'AI is thinking...'`

**Visible UI Elements**:

- Board updated.
- If chain jump: new piece position highlighted, chain destinations highlighted.
- If turn ends: no selection visible; AI "thinking" indicator.

**Available Actions**:

- **Chain jump in progress**: tap the next highlighted destination.
- **Turn ended**: nothing (AI moves automatically).

**Logic**:

`_executeMove(CheckersMove move)` applies one move step:

1. Copy the board: `_copyBoard(state.board)`.
2. Remove captured pieces: for each `(cr, cc)` in `move.captured` → `board[cr][cc] = 0`.
3. Move the piece: `board[move.fromRow][move.fromCol] = 0`, `board[move.toRow][move.toCol] = piece`.
4. **King promotion**: `justPromoted = piece == 1 && move.toRow == 7` (piece was a plain man, not already a king). If true, `board[move.toRow][move.toCol] = 3`.
5. **Chain jump check**: if `!justPromoted && move.captured.isNotEmpty` — a piece crowned this move skips the chain check entirely and its turn ends immediately, per standard rules:
   - Call `getChainJumps(board, move.toRow, move.toCol, [])`.
   - If chain jumps exist: update state with new board, `selectedRow/Col` = new position, `validMoves = chainJumps`, `mustContinueChain = true`. Message: `'Jump again! You must continue the chain.'`. Return — do not pass to AI.
6. **Switch to AI turn**: compute `aiMoves = getAllMoves(board, false)`. `mustContinueChain` is explicitly reset to `false` here.
7. **Win check**: if `aiMoves.isEmpty` or `!_hasAnyPieces(board, false)` → game over, human wins (`mustContinueChain = false`).
8. Otherwise: update state to AI's turn. Schedule `_aiMove()` after 600 ms.

`getMovesForPiece(board, row, col, {alreadyCaptured, jumpsOnly})`:

- Gets the piece at `(row, col)`.
- Determines movement directions from `_forwardDirs(piece)`:
  - Regular human piece (1): `[1]` (rows increase).
  - Regular AI piece (2): `[-1]` (rows decrease).
  - King (3 or 4): `[-1, 1]` (both directions).
- Column directions are always `[-1, 1]`.

**Jump move detection** (checked first, for every direction pair `(dr, dc)`):

- Middle square: `(row+dr, col+dc)`.
- Landing square: `(row+dr*2, col+dc*2)`.
- Valid if: landing is in bounds, middle is an opponent piece, landing is empty, middle not already in `alreadyCaptured`.
- Returns a `CheckersMove` with `captured = [...alreadyCaptured, (midR, midC)]`.

**Simple move detection** (only if no jump moves and not `jumpsOnly`):

- Target: `(row+dr, col+dc)` — must be in bounds and empty.
- Returns `CheckersMove` with empty `captured`.

**Chain jump** (`getChainJumps`): same logic as jump detection in `getMovesForPiece`, but called recursively after a jump is executed. Note: `alreadyCaptured` is passed as `[]` (fresh) in the current implementation — a piece can only be captured once because it is physically removed from the board before chain detection.

**Win detection** (`_hasAnyPieces`): scans the board for any piece of the given side. Win also triggered if `getAllMoves` returns empty (no legal moves, even if pieces exist).

**Transition**:

- Chain jump available → stay in state 3 with new position.
- Turn complete, AI has moves → state 4 (AI Move).
- Turn complete, AI has no moves or no pieces → state 5 (Game Over).

---

### 4. AI Move

**Description**: The AI automatically selects and executes the best available move, handling chain jumps, king promotion, and turn-end. Runs after a 600 ms delay for visual pacing.

**Visual State**:

- Board non-interactive.
- Game message: `'AI is thinking...'`
- AI piece moves with animation (same as human animation).
- Captured human pieces disappear.
- After AI turn: `'Your turn — tap a red piece to select it.'`

**Visible UI Elements**:

- Board with AI move animations.
- No interactive elements.

**Available Actions**:

- None for human.

**Logic**:

`_aiMove()` is called via `Timer(600ms, _aiMove)`.

1. If `state.phase == GamePhase.gameOver` or `!_isMounted`: return.
2. Get `moves = state.allMoves`. If empty → AI has no moves → human wins (game over).
3. Call `_pickAiMove(moves)` to choose the best move.
4. Apply the move (same steps as `_executeMove` for human):
   - Copy board.
   - Remove captured pieces.
   - Move piece.
   - **King promotion**: if `_isAiPiece(piece) && move.toRow == 0` → `board[move.toRow][move.toCol] = 4`.
5. **Chain jump check**: call `getChainJumps(board, move.toRow, move.toCol, [])`.
   - If chain jumps exist: call `_applyAiChain(board, _pickAiMove(chainJumps))`.
6. Otherwise: call `_finishAiMove(board)`.

`_applyAiChain(board, move)`: recursively applies chain jumps for AI.

- Apply the chain move (remove captured, move piece, check promotion).
- Call `getChainJumps` again. If more exist, recurse. Otherwise call `_finishAiMove`.

`_finishAiMove(board)`:

- Compute `playerMoves = getAllMoves(board, true)`.
- If `playerMoves.isEmpty` or `!_hasAnyPieces(board, true)` → AI wins (game over).
- Otherwise: update state to human's turn with new `allMoves = playerMoves`.

`_pickAiMove(List<CheckersMove> moves)` priority:

1. Multi-captures (chains of 2+): preferred first.
2. Single captures.
3. King moves (non-capture).
4. Random regular move.

Ties within each tier are broken randomly using `_rng.nextInt`.

**Transition**:

- After AI move, no player moves → state 5 (Game Over, AI wins).
- After AI move, player has moves → state 2 (Select Piece).

---

### 5. Game Over

**Description**: One player has won. Display the result and offer replay.

**Visual State**:

- Board shows final state (frozen).
- Game message: `'You win! All AI pieces captured.'` / `'You win! AI has no moves left.'` / `'AI wins! You have no moves left.'`
- `phase` = `GamePhase.gameOver`.
- `winner` = `'You'` or `'AI'`.
- Viking-themed victory/defeat overlay.

**Visible UI Elements**:

- "Play Again" button → calls `newGame()`.
- "Return to Menu" button → navigates to games hub.
- Board visible but non-interactive.

**Available Actions**:

- Tap "Play Again" → `newGame()` → state 1.
- Tap "Return to Menu" → navigate out.

**Logic**:

- Game over is triggered by:
  1. Opponent has no pieces left (`!_hasAnyPieces(board, false/true)`).
  2. Opponent has no legal moves (`getAllMoves(board, false/true).isEmpty`).
- `winner` is set to `'You'` (human wins) or `'AI'` (AI wins).
- `newGame()` calls `build()` which re-initializes fully.

**Transition**: "Play Again" → state 1.

---

## Key Game Rules Summary

### Piece Types and Movement

| Value | Piece | Belongs To | Moves Toward | Moves Diagonally |
|-------|-------|-----------|-------------|-----------------|
| 1 | Regular | Human (red) | Row 7 (↓) | Forward only |
| 2 | Regular | AI (black) | Row 0 (↑) | Forward only |
| 3 | King | Human (red) | Both | All 4 diagonals |
| 4 | King | AI (black) | Both | All 4 diagonals |

### Movement Rules

- Pieces move diagonally on dark squares only (`(row + col) % 2 == 1`).
- Regular pieces move forward only (one direction).
- Kings move diagonally in all 4 directions.
- A simple move lands on any adjacent empty diagonal square.
- A jump move leaps over one adjacent opponent piece to an empty square behind it. The jumped piece is captured and removed.
- **Variant note**: this implementation is American/English-style ("standard") checkers, not International/Russian draughts. Kings move and capture only **one square at a time** in each diagonal direction — they do not "fly" multiple empty squares along a diagonal the way International/Russian draughts kings do. Both simple moves and jumps land exactly 1 or 2 squares away respectively, for kings and regular pieces alike; the only difference for kings is that backward directions are also allowed.

### Mandatory Jump Rule

- If one or more jump moves are available for the active player, they **must** make a jump. Simple moves are forbidden.
- Implemented in `getAllMoves`: if any jump moves exist, only jump moves are returned. Simple moves are excluded.
- If multiple pieces can jump, the player may choose which piece to jump with (not forced to use a specific one in the current implementation).
- However, once a piece is selected, if that piece can jump, it must — the player cannot switch to a non-jumping piece if jumping pieces exist.

### Chain Jumps (Multi-Capture)

- After completing a jump, if the landing square allows another jump, the player **must** continue jumping with the same piece.
- The turn does not end until no further jumps are possible.
- A piece cannot jump over the same opponent piece twice in one turn (enforced by `alreadyCaptured`, though in the current code `alreadyCaptured` is passed as `[]` for chain detection — safe because the captured piece is physically removed before chain check).
- King promotion during a chain: if the piece reaches the back row mid-chain (row 7 for human), it is promoted (board value set to `3`/`4`) and **the turn ends immediately** — `_executeMove` skips the chain-jump check entirely on the move that promoted the piece (`justPromoted` guard), matching standard rules: a piece crowned mid-jump may not make any further capture that turn, even one available to it as a king (e.g. backward).

### King Promotion

- Human regular piece (value 1) lands on row 7 → becomes king (value 3).
- AI regular piece (value 2) lands on row 0 → becomes king (value 4).
- Kings can move and jump in all 4 diagonal directions.
- `_isKing(v)` returns true for values 3 and 4.
- `_forwardDirs(piece)` returns `[-1, 1]` for kings.

### Win Conditions

1. Opponent has no pieces remaining on the board.
2. Opponent has no legal moves (all pieces blocked, even if pieces exist).

### Turn Structure

1. Compute all valid moves for the active player (`getAllMoves`).
2. If jump moves exist, only jumps are valid.
3. Player selects a piece and destination.
4. Move is executed; captured pieces removed.
5. Check for chain jump. If available, force continuation.
6. After all jumps complete: check king promotion.
7. Check win conditions for opponent.
8. Pass turn to opponent.

---

## Enhancements & Edge Cases

### Mandatory Jump Enforcement

- When `allMoves.first.captured.isNotEmpty`, only pieces with jumps in `allMoves` can be selected.
- In `selectCell`, the `mustJump` flag is derived from `state.allMoves.isNotEmpty && state.allMoves.first.captured.isNotEmpty`.
- A piece with no jump available during a mandatory-jump turn: `pieceMoves` will be empty → deselect (piece is unselectable).
- **Mid-forced-chain-jump** (`state.mustContinueChain == true`, set by `_executeMove` when a chain continuation is forced): `selectCell` ignores any tap that isn't one of the current piece's own `validMoves` destinations, before ever reaching the piece-selection logic. This prevents a different own piece's independent jump from hijacking the forced continuation — the piece mid-chain must be the one to keep jumping.

### Chain Jump During King Promotion

- If a piece reaches row 7 (for human) during a jump and earns promotion, its turn ends immediately — `_executeMove`'s `justPromoted` guard skips the chain-jump check on that move, so `getChainJumps` is never called with the newly-crowned king. Matches standard American/English draughts rules: reaching the king row ends the turn immediately, even if a further capture would be available to it as a king.

### AI No Moves (Loss by Blockade)

- If after the human's move `aiMoves.isEmpty` (from `getAllMoves(board, false)`), this triggers a human win even if AI pieces still exist (they are all blocked).
- Message: `'You win! All AI pieces captured.'` (reuses this message for blockade too; ideally this should say "AI has no moves left" — currently both win conditions show the capture message in code).

### Deselection

- Tapping an empty square or an AI piece with nothing currently selected: `selectedRow/Col` set to null, `validMoves` cleared.
- This allows the human to deselect and re-pick without penalty.

### AI Chain Recursion

- `_applyAiChain` recurses until `getChainJumps` returns empty.
- Each recursive call applies one jump step synchronously (no animation delays between chain steps for AI).
- This means a multi-jump AI sequence appears instantaneous (all jumps applied before the state update is emitted).

### Board Boundaries

- All move calculations include bounds checks: `if (landR < 0 || landR >= 8 || landC < 0 || landC >= 8) continue`.

### Re-selection During Active Selection

- Human has piece A selected. Taps piece B (also human). Piece B is re-selected as the new active piece, replacing piece A's selection. This is handled in `selectCell`: if the tapped square is not a valid destination but is a human piece, re-select logic fires before the deselect path.

---

## Known Gaps / Future Work

None currently tracked. (King-promotion-ends-turn and mandatory-chain-continuation-cannot-be-bypassed were both fixed 2026-07-15 — see `justPromoted` in `_executeMove` and `mustContinueChain` in `CheckersState`/`selectCell`.)

---

## Implementation Notes

### State Management Fields (`CheckersState`)

| Field | Type | Description |
|-------|------|-------------|
| `board` | `List<List<int>>` (8×8) | Board grid. 0=empty, 1=human, 2=AI, 3=human king, 4=AI king. |
| `isPlayerTurn` | `bool` | `true` = human's turn. |
| `selectedRow` | `int?` | Row of currently selected piece. |
| `selectedCol` | `int?` | Column of currently selected piece. |
| `validMoves` | `List<CheckersMove>` | Valid destinations for selected piece. |
| `allMoves` | `List<CheckersMove>` | All valid moves for the active player this turn. |
| `phase` | `GamePhase` | `playing` or `gameOver`. |
| `message` | `String` | UI instruction/status string. |
| `winner` | `String?` | `'You'`, `'AI'`, or `null`. |
| `mustContinueChain` | `bool` | `true` only while the selected piece is mid-forced-chain-jump (set by `_executeMove`, reset to `false` at both of its turn-ending branches). Guards `selectCell` against a different piece's independent jump hijacking the forced continuation. |

### CheckersMove Class

```dart
class CheckersMove {
  final int fromRow;
  final int fromCol;
  final int toRow;
  final int toCol;
  final List<(int, int)> captured; // list of (row, col) of captured pieces
}
```

### GamePhase Enum

```dart
enum GamePhase { playing, gameOver }
```

### Provider

```dart
final checkersStateProvider =
    NotifierProvider<CheckersNotifier, CheckersState>(CheckersNotifier.new);
```

### Helper Functions (top-level)

```dart
bool _isHumanPiece(int v) => v == 1 || v == 3;
bool _isAiPiece(int v) => v == 2 || v == 4;
bool _isKing(int v) => v == 3 || v == 4;

List<int> _forwardDirs(int piece) {
  if (_isKing(piece)) return [-1, 1];
  if (_isHumanPiece(piece)) return [1];  // human moves ↓
  return [-1];                            // AI moves ↑
}
```

### UI Logic Snippets

```dart
// Determine if a cell should show as selected
bool isCellSelected(CheckersState s, int row, int col) {
  return s.selectedRow == row && s.selectedCol == col;
}

// Determine if a cell is a valid destination for the selected piece
bool isCellValidDest(CheckersState s, int row, int col) {
  return s.validMoves.any((m) => m.toRow == row && m.toCol == col);
}

// Determine if a piece is selectable (respects mandatory jump)
bool isPieceSelectable(CheckersState s, int row, int col) {
  if (!s.isPlayerTurn || s.phase == GamePhase.gameOver) return false;
  if (!_isHumanPiece(s.board[row][col])) return false;
  final mustJump = s.allMoves.isNotEmpty && s.allMoves.first.captured.isNotEmpty;
  if (mustJump) {
    return s.allMoves.any((m) => m.fromRow == row && m.fromCol == col);
  }
  return true;
}

// Show AI thinking indicator
bool showAiThinking(CheckersState s) {
  return !s.isPlayerTurn && s.phase == GamePhase.playing;
}
```

### Folder Structure

- **Logic**: `lib/ui/games/games/checkers/logic.dart`
- **Screen**: `lib/ui/games/games/checkers/screen.dart`
- **Assets**: `assets/games/checkers/` — board image, red/black piece sprites, king crown overlays.

### Testing Guidance

- **Unit tests** (`test/games/checkers/`):
  - `getMovesForPiece`: regular move, blocked square, jump move, no moves.
  - `getAllMoves`: mandatory jump — verify only jumps returned when jumps available.
  - `getChainJumps`: verify chain detection after first jump.
  - King promotion: human piece at row 6 jumps to row 7 → value becomes 3.
  - Win detection: board with 1 AI piece, human jumps it → game over.
  - AI blockade: arrange board so AI has pieces but no moves → human wins.
  - `_pickAiMove`: multi-capture preferred over single capture over simple move.
  - `copyWith` sentinel: `selectedRow: null` vs. unset (confirm null propagates correctly via `_sentinel`).
- **Integration tests**:
  - Full game: human captures all AI pieces.
  - Chain jump: human performs 3-jump chain in one turn.
  - AI chain: AI performs multi-capture automatically.
  - Re-selection: tap piece A, then tap piece B → piece B becomes selected.

### Viking Theme Notes

- Board: alternating dark (aged oak) and light (pale birch) squares with slight wear texture. Only dark squares are used for gameplay.
- Regular pieces: round carved wood coins — red (bloodwood grain) for human, black (ebony grain) for AI.
- King pieces: same piece with a rune-carved crown overlay or a golden rune etched on top.
- Selection highlight: faint golden glow ring (like a torch being held to the piece).
- Valid destinations: glowing amber footprint runes on the target squares.
- Capture animation: captured piece "shattered" with a brief flash or crumble effect.
- Chain jump: each successive capture plays a short Norse horn stab sound.
- Win overlay: crossed axes (victory) or broken shield (defeat) with runic text.
- Background: carved stone hall floor or Viking game table surface.
