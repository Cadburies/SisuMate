# 📜 Cribbage – Game Flow Documentation

This document describes the complete game flow for Cribbage in the SisuMate app. It covers all game states, UI interactions, scoring rules, edge cases, and implementation details. It aligns with the Viking-themed aesthetic and single-player (human vs. AI) focus of the current implementation. The document is written so that an AI programmer could implement the game from scratch using it alone.

## Game Structure

- **Players**: 2 — Human vs. AI.
- **Modes**: Human vs. AI, or local Wi-Fi multiplayer via the Games lobby (`GameCatalog.multiplayerReady` in `lib/core/app_router.dart` is the source of truth).
- **Rounds**: Multiple rounds until a player reaches 121 points. Dealer alternates each round (human deals first).
- **Win Condition**: First player to reach **121 points** wins. Can win at any scoring moment (pegging, nibs, or hand counting).
- **Deck**: Standard 52-card deck. Card encoding: `card = suit * 13 + rank`. Suit 0=♣ 1=♦ 2=♥ 3=♠. Rank 0=A, 1=2, … 12=K.
- **Face Values**: Ace=1, 2–10=face value, J/Q/K=10 (used for 15s and peg count). `faceValue(c) = min(rankOf(c)+1, 10)`.
- **Pip Values**: Ace=1, 2=2, … King=13 (used for run detection). `pipValue(c) = rankOf(c)+1`.
- **Phases per Round**:
  1. Discarding — each player selects 2 cards for the crib.
  2. Pegging — alternating play, scoring points on the pegging table.
  3. Counting — hands and crib are scored.
- **Crib**: The 4-card discard pile (2 from each player). Always belongs to the dealer. Scored after hands.
- **Starter (Cut card)**: One card cut from the remaining deck after discarding. Used in hand and crib scoring.
- **Nibs (Heels)**: If the starter card is a Jack, the dealer scores 2 points immediately.
- **UI Elements**:
  - **Player Hand**: Human's 4 kept cards (after discarding), displayed face-up.
  - **AI Hand**: 4 kept cards, typically shown face-down during pegging (revealed at counting).
  - **Crib Indicator**: Shows who owns the crib (dealer).
  - **Peg Table**: Cards currently played in the pegging round; peg count displayed.
  - **Score Display**: Running scores for both players (out of 121).
  - **Discard Selection**: During discarding, human's full 6-card hand shown; toggleable cards.
  - **Game Message**: Instructions, scores awarded, win/loss announcements.
- **Viking Theme**: Cards rendered with Norse border art, wooden card-back design, rune numerals for scores, mead hall background with the crib depicted as a carved chest.

---

## Game States & Flow

### 1. Start of Game / Start of Round (Deal)

**Description**: A new round begins. The deck is shuffled and 6 cards each are dealt to both players. The AI immediately discards 2 cards to the crib. The human is shown their 6 cards and asked to choose 2 to discard.

**Visual State**:

- Human's hand shows 6 cards, face-up.
- AI's cards hidden (face-down).
- Crib area shows 2 face-down cards (AI's discards already placed).
- Starter card position: empty (not yet cut).
- Score display: current running scores visible.
- Dealer indicator: shows who is dealing this round.
- Game message (human deals): `'You deal. Choose 2 cards for your crib.'`
- Game message (AI deals): `'AI deals. Choose 2 cards for the crib.'`
- `phase` = `CribbagePhase.discarding`.

**Visible UI Elements**:

- 6 human cards displayed with tap-to-toggle selection.
- "Confirm Discard" button: disabled until exactly 2 cards are selected.
- Crib chest icon showing owner (dealer).
- Score trackers for both players.

**Available Actions**:

- Human taps a card to toggle it as a discard selection (`toggleDiscard(idx)`).
- Can select up to 2 cards (attempts to select a 3rd are ignored).
- Tap a selected card again to deselect it.
- Tap "Confirm Discard" when exactly 2 are selected (`confirmDiscard()`).

**Logic**:

`_dealRound({playerScore, aiScore, playerDealer})`:

1. Shuffle a fresh 52-card deck: `List.generate(52, (i) => i)..shuffle(_rng)`.
2. Deal `playerFullHand = deck[0..5]` (6 cards) and `aiFullHand = deck[6..11]`.
3. AI auto-discards: `_aiSelectDiscard(aiFullHand, playerDealer)` returns 4 cards to keep. The other 2 go to `crib`.
4. `playerHand = []` (empty until human confirms discard).
5. `isPlayerPegging = !playerDealer` (non-dealer pegs first).
6. `phase = CribbagePhase.discarding`.

`_aiSelectDiscard(List<int> hand, bool playerDealer)`:
- Tries all 15 combinations of keeping 4 out of 6 (C(6,4)).
- For each keep combination, evaluates `scoreHand(keep, dummyStarter)` using the first available card not in `hand` as a rough starter estimate.
- Returns the 4-card keep combination with the highest estimated score.
- The 2 non-kept cards become AI's crib contribution.

`toggleDiscard(int idx)`:
- Toggles `idx` in `selectedDiscard` (a `Set<int>`).
- If already selected: removes it.
- If not selected and `selectedDiscard.length < 2`: adds it.
- If not selected and already 2 selected: ignored (silently — no error).

**Transition**: Human taps "Confirm Discard" with 2 cards selected → `confirmDiscard()` → state 2 (Cut Starter).

---

### 2. Cut Starter (Confirm Discard)

**Description**: The human confirms their 2 discards, the starter card is cut from the remaining deck, and nibs is checked. Pegging begins.

**Visual State**:

- Human's 4 kept cards shown face-up in the hand area.
- Crib now contains all 4 discards (2 human + 2 AI), shown face-down.
- Starter card revealed face-up in the starter position.
- If nibs: brief animation/message noting the 2 bonus points for the dealer.
- Game message: `'Starter: [card].[nibs message] [non-dealer]'s turn to peg.'`
- `phase` = `CribbagePhase.pegging`.

**Visible UI Elements**:

- Human's 4 kept cards in hand (face-up, tappable during pegging if it is the human's turn).
- Starter card displayed.
- Peg table (empty at start).
- Peg count: `0`.
- "Confirm Discard" button: hidden (we've moved past discarding).

**Available Actions**:

- Depends on who pegs first:
  - If non-dealer pegs first and human is non-dealer: human can tap a card to play it.
  - If AI pegs first: human waits (AI auto-pegs after 600 ms).

**Logic**:

`confirmDiscard()`:

1. Guard: `phase != discarding` or `selectedDiscard.length != 2` → return.
2. Identify kept cards: `kept = [for (i in 0..5) if (i not in selectedDiscard) hand[i]]`.
3. Identify discarded cards: `discard = selectedDiscard.map((i) => hand[i])`.
4. `newCrib = [...state.crib (AI's 2), ...discard (human's 2)]` → 4-card crib.
5. Cut starter: `starterCard = deckCopy.removeAt(_rng.nextInt(deckCopy.length))`.
6. **Nibs check**: if `rankOf(starterCard) == 10` (it's a Jack):
   - Dealer gets 2 points immediately.
   - Check win condition: if dealer now has ≥ 121 → game over with nibs.
7. Set `playerPegging = [...kept]`, `aiPegging = [...state.aiHand]`.
8. `phase = CribbagePhase.pegging`.
9. If AI pegs first (`!state.isPlayerPegging`): schedule `_aiPegTurn()` after 600 ms.

**Transition**: → state 3 (Pegging).

---

### 3. Pegging

**Description**: Players alternate playing cards from their pegging hands onto the peg table. Cards are played one at a time. Running total (peg count) must not exceed 31. Scoring opportunities arise from 15s, 31s, pairs, trips, quads, and runs. A player who cannot play says "Go". After a Go or 31, the count resets and play resumes. Pegging ends when both players have no cards remaining.

**Visual State**:

- **Human's peg turn**:
  - Human's remaining pegging cards shown face-up (tappable).
  - Cards that would exceed 31 shown grayed out / non-tappable.
  - Peg table shows all cards played so far in this peg sequence.
  - Peg count shown prominently (running total).
  - Game message: `'Count: [n]. Your peg turn.'`
- **AI's peg turn**:
  - Human's cards non-interactive.
  - Game message: `'AI plays [card]. [score info]. Count: [n]. Your peg turn.'` (updated after AI plays).
- **Go situation** (AI cannot play):
  - Message: `'AI says Go! Your turn. Count: [pegCount].'`
  - Human continues playing alone.
- **Go situation** (human cannot play):
  - The card row shows "No legal play" instead of "Your hand — tap to play", and a **Go** button appears below it. Tapping it calls `sayGo()`.

**Visible UI Elements**:

- Peg table (played cards in sequence).
- Peg count display.
- Human's remaining pegging cards (tappable on human's turn, face-up).
- AI's remaining pegging cards (face-down count indicator).
- Score displays (updated after each scoring play).
- **Go** button — shown only when it's the human's peg turn and no held card fits under 31.

**Available Actions**:

- **Human's turn**: tap a valid card (one whose face value + peg count ≤ 31), or tap **Go** if none fit.
- **AI's turn**: automatic.

**Logic**:

`playPegCard(int handIdx)` — called when human taps a card:

1. Guard: `!state.isPlayerPegging` or `phase != pegging` → return.
2. Get `card = state.playerPegging[handIdx]`.
3. If `faceValue(card) + pegCount > 31` → return (invalid, card cannot be played).
4. Score the play: `pts = scorePegging(state.pegTable, card)`.
5. Update: `pScore += pts`, `newTable = [...pegTable, card]`, remove card from `playerPegging`, `newCount = pegCount + faceValue(card)`.
6. **Win check**: if `pScore >= 121` → game over (human wins during pegging).
7. **31 check**: if `newCount == 31` → human scores 2 extra points; reset `pegTable = []`, `pegCount = 0`; **AI leads the next series** (`isPlayerPegging = false` — the human just played, so the other side goes next, regardless of dealer status); schedule `_aiPegTurn()` after 600 ms.
8. **Stoppage check**: if AI cannot play at `newCount` (`!aiPegging.any((c) => faceValue(c) + newCount <= 31)`) *and* the human's `newPegging` is now empty, this is a stoppage: `pScore += 1` (last card point), and — unlike the pre-2026-07-15 behavior — `pegTable`/`pegCount` reset **immediately** here rather than being left for `_aiPegTurn()` to rediscover (which used to award a second, duplicate point for the same event).
9. Set `isPlayerPegging = false`. If both `newPegging.isEmpty` and `aiPegging.isEmpty` → schedule `_startCounting()` after 400 ms; otherwise schedule `_aiPegTurn()` after 600 ms.

`sayGo()` — called when the human taps the **Go** button:

1. Guard: `!state.isPlayerPegging` or `phase != pegging` → return.
2. Guard: if the human actually has a playable card, return (must play, not pass).
3. If AI can still play at the current count: pass the turn (`isPlayerPegging = false`, no score change, count unchanged), schedule `_aiPegTurn()` after 600 ms.
4. Otherwise (neither side can play): call `_resolveGoStoppage()`.

`_aiPegTurn()` — AI's automatic peg:

1. Guard: `state.isPlayerPegging` or `phase != pegging` → return.
2. Find playable cards: `aiPegging` where `faceValue(c) + pegCount <= 31`.
3. **If no playable cards**:
   - If human has playable cards: set `isPlayerPegging = true`, message: `'AI says Go!'`. Return.
   - If neither can play: call `_resolveGoStoppage()`.
4. Otherwise: sort playable cards by `scorePegging` descending, then by `faceValue` descending (play highest-scoring, then highest face value as tiebreak).
5. Play the top card: compute `pts = scorePegging(pegTable, card)`, `aScore += pts`.
6. **Win check**: if `aScore >= 121` → game over (AI wins during pegging).
7. **31 check**: `newCount == 31` → AI scores 2; reset peg table and count; **the human leads the next series** (`isPlayerPegging = true` — AI just played, regardless of dealer status).
8. **Stoppage check**: if human cannot play at `newCount` and AI's `newAiPegging` is now empty, reset `pegTable`/`pegCount` immediately (same fix as step 8 of `playPegCard` above) and `aScore += 1`.
9. Set `isPlayerPegging = true`, update state. If both pegging hands empty: schedule `_startCounting()` after 400 ms.

`_resolveGoStoppage()` — shared by both `_aiPegTurn()`'s and `sayGo()`'s "neither side can play" branches:

1. Read `state.lastToPlayWasHuman` (set every time either side successfully adds a card to `pegTable`, i.e. not on a plain "Go" pass) to determine who played the table's last card — **not** inferred from which function is calling this, since that inference is unreliable (the human-side "both can't play" case can be reached after either side played last).
2. Award +1 to whichever side played last.
3. Win-check both scores (≥121) before proceeding, since this is now a genuine scoring path for either side.
4. Reset `pegTable = []`, `pegCount = 0`; the side that did **not** just score leads next.
5. If both pegging hands are empty: schedule `_startCounting()` after 400 ms. Otherwise, if AI leads next, schedule `_aiPegTurn()` after 600 ms.

`scorePegging(List<int> table, int card)`:

The full scoring function for a single played card. Evaluates the sequence `[...table, card]`:

1. **Fifteen**: if `sum(faceValues of all played cards) == 15` → +2.
2. **Thirty-one**: if `sum == 31` → +2.
3. **Pairs/Trips/Quads**: count consecutive matching ranks at the end of the played sequence:
   - Look backward from the just-played card: how many consecutive cards share the same rank?
   - Pair (2 of same rank at end) → +2.
   - Three of a kind (3 at end) → +6.
   - Four of a kind (4 at end) → +12.
4. **Runs**: check if the last N cards (working from largest N down to 3) form a consecutive sequence of pip values (no duplicates). First qualifying run scores N points. Example: [5, 6, 7] played → +3 on the 7.

**Transition**: Both pegging hands empty → `_startCounting()` → state 4 (Counting).

---

### 4. Counting (Hand Scoring)

**Description**: After pegging ends, hands are scored in order: non-dealer's hand first, then dealer's hand, then dealer's crib. Scoring uses the 4-card hand plus the starter card (5 cards total for evaluation). Results are applied immediately and win condition is checked after each.

**Visual State**:

- Peg table clears.
- Both hands revealed face-up.
- Crib revealed face-up.
- Starter card visible.
- Game message: scores announced (e.g., `'AI hand: 8. Your hand+crib: 12. You: 45 – AI: 38. Next round.'`)
- `phase` = `CribbagePhase.counting`.

**Visible UI Elements**:

- Both 4-card hands displayed face-up.
- Crib's 4 cards displayed.
- Starter card displayed.
- Running scores.
- "Next Round" button.

**Available Actions**:

- Human taps "Next Round" to deal the next round (`nextRound()`).

**Logic**:

`_startCounting()`:

1. Guard: `phase != pegging` → return.
2. Identify non-dealer hand and dealer hand:
   - `isPlayerDealer == true`: non-dealer = AI hand, dealer = player hand.
   - `isPlayerDealer == false`: non-dealer = player hand, dealer = AI hand.
3. Score all three:
   - `nonDealerPts = scoreHand(nonDealerHand, starter)`.
   - `dealerPts = scoreHand(dealerHand, starter)`.
   - `cribPts = scoreHand(crib, starter, isCrib: true)`.
4. Apply scores (non-dealer first, then dealer + crib):
   - If player is dealer: `aScore += nonDealerPts`; `pScore += dealerPts + cribPts`.
   - If AI is dealer: `pScore += nonDealerPts`; `aScore += dealerPts + cribPts`.
5. Win check:
   - `pScore >= 121`: player wins.
   - `aScore >= 121`: AI wins.
6. Otherwise: `phase = CribbagePhase.counting`. Show summary message.

`nextRound()`:

- Guard: `phase != counting` → return.
- Call `_dealRound(playerScore: pScore, aiScore: aScore, playerDealer: !isPlayerDealer)`.
- Dealer alternates each round.

`scoreHand(List<int> hand, int starter, {bool isCrib = false})`:

Evaluates a 4-card hand + starter (5 cards total = `all = [...hand, starter]`):

```
score = _countFifteens(all)
      + _countPairs(all)
      + _countRuns(all)
      + _countFlush(hand, starter, isCrib)
      + _countNobs(hand, starter)
```

**Transition**: "Next Round" → state 1 (new round deal). If win detected during counting → state 5 (Game Over).

---

### 5. Game Over

**Description**: A player has reached or exceeded 121 points. The game ends immediately at the point of scoring.

**Visual State**:

- `phase` = `CribbagePhase.gameOver`.
- `winner` = `'You'` or `'AI'`.
- Message examples:
  - `'You win with nibs!'` (starter Jack awarded 121 to dealer).
  - `'You win with [score] points!'` (pegging win).
  - `'AI wins with [score] points!'`
  - `'You win! [summary]. Final: You [p] – AI [a]'` (counting win).
- Viking-themed win/loss screen (northern lights, runic text, mead horns raised).

**Visible UI Elements**:

- "Play Again" button → `newGame()`.
- "Return to Menu" button → navigate to games hub.
- Final score display.

**Available Actions**:

- "Play Again" → `newGame()` → state 1 (fresh game, human deals first).
- "Return to Menu" → navigate out.

**Logic**:

- Win is checked at multiple points:
  - After nibs: `if (pScore >= 121 || aScore >= 121)` immediately in `confirmDiscard`.
  - During pegging: after every `playPegCard` / `_aiPegTurn` score update.
  - During counting: after `_startCounting` applies scores.
- `newGame()` calls `build()` → `_dealRound(playerScore: 0, aiScore: 0, playerDealer: true)`.

**Transition**: "Play Again" → state 1.

---

## Key Game Rules Summary

### Card Values

| Cards | Face Value (15s/peg count) | Pip Value (run detection) |
|-------|---------------------------|--------------------------|
| Ace | 1 | 1 |
| 2–10 | Face value (2–10) | Pip value (2–10) |
| Jack | 10 | 11 |
| Queen | 10 | 12 |
| King | 10 | 13 |

### Pegging Scoring (per card played)

| Combination | Points | Notes |
|------------|--------|-------|
| Count reaches 15 | 2 | Sum of all face values on peg table equals 15 |
| Count reaches 31 | 2 | Sum equals 31; table resets after |
| Pair | 2 | Last 2 played cards share a rank |
| Three of a kind | 6 | Last 3 played cards share a rank |
| Four of a kind | 12 | Last 4 played cards share a rank |
| Run of 3 | 3 | Last 3 played (any order played, but consecutive pips) |
| Run of 4 | 4 | Last 4 form a run |
| Run of 5 | 5 | Last 5 form a run |
| Last card (Go/end) | 1 | Playing the last card before count would bust; or last card of all pegging |

**31 rule**: Playing a card that brings the count to exactly 31 scores 2 points and resets the table. The 2 points for 31 are scored via `scorePegging` (count == 31 check).

**Go rule**: If a player cannot play any card without exceeding 31, they say "Go". The opponent continues playing as long as they can. The last player to play before neither can continue scores 1 point (last card). Then the count resets to 0 and play resumes.

### Hand Scoring (`scoreHand`)

All five combinations are evaluated across the 5-card set (4 hand cards + starter):

#### 1. Fifteens (+2 per combination)

Every distinct subset of cards whose face values sum to 15 scores 2 points.

```
_countFifteens(cards):
  for each non-empty subset (bitmask 1 to 2^n - 1):
    if sum(faceValues) == 15: score += 2
```

Examples:
- 7 + 8 = 15 → 2 pts.
- 5 + 5 + 5 = 15 → 2 pts (one 15).
- 5 + Q + A = 5+10+1 = 16 (not 15, no score).
- A hand with three 5s and a 10: subsets `{5,10}` (×3) + `{5,5,5}` = 4 fifteens = 8 pts.
- Maximum possible: 16 pts (four 5s and a Jack is a legendary hand scoring many 15s).

#### 2. Pairs (+2 per pair)

Every distinct pair of cards with the same rank scores 2 points.

```
_countPairs(cards):
  for all i < j: if rankOf(i) == rankOf(j): score += 2
```

| Combination | Points | Reason |
|------------|--------|--------|
| One pair | 2 | C(2,2) = 1 pair |
| Three of a kind | 6 | C(3,2) = 3 pairs |
| Four of a kind | 12 | C(4,2) = 6 pairs |
| Two separate pairs | 4 | 2 × 2 = 4 pts |

Note: Jack in hand that matches starter suit (Nobs) does NOT count as a pair with the starter Jack — nobs is a separate score.

#### 3. Runs (+1 per card in run)

The longest run of 3 or more consecutive pip values among the 5 cards.

```
_countRuns(cards):
  sort pip values
  find longest consecutive sequence of length >= 3
  score += length of that sequence
```

Rules for runs:
- Cards need not be played in order — pip values are sorted.
- A "double run" (pair + run): `[3, 4, 4, 5]` → two runs of 3 = 6 pts (the pair multiplies the run). Note: the current implementation's `_countRuns` uses a simplified first-match approach and may not fully account for double/triple runs with multiplicity. An enhanced version iterates all subsequences.
- Examples:
  - `[A, 2, 3, 7, K]` → run of 3 (A-2-3) = 3 pts.
  - `[5, 6, 7, 8, 9]` → run of 5 = 5 pts.
  - `[3, 4, 5, 5, 6]` → two runs of 4 (3-4-5-6 with each 5) = 8 pts. *(Note: simplified code may return 4 pts — this is a known limitation.)*

#### 4. Flush (+4 or +5)

All 4 hand cards share the same suit:

- 4-card flush (hand only, not including starter): **+4 pts**.
- 5-card flush (hand + starter all same suit): **+5 pts**.
- Crib flush: only scores if all 5 cards (4 crib + starter) are the same suit (**+5 pts**). A 4-card crib flush does NOT score.

```
_countFlush(hand, starter, isCrib):
  suit = suitOf(hand[0])
  if all hand cards same suit:
    if starter same suit: return 5
    if !isCrib: return 4
  return 0
```

#### 5. Nobs (+1)

If the hand contains a Jack of the same suit as the starter card: **+1 pt**.

```
_countNobs(hand, starter):
  for c in hand:
    if rankOf(c) == 10 (Jack) and suitOf(c) == suitOf(starter): return 1
  return 0
```

Note: Only the Jack in the hand scores nobs, not the starter itself.

#### Nibs (Heels) (+2, immediate)

If the **starter card** is a Jack, the **dealer** scores 2 points immediately when the card is cut, before pegging begins. This is evaluated in `confirmDiscard()` using `rankOf(starterCard) == 10`.

### Perfect Hand

The maximum hand score is 29: `[5♠, 5♥, 5♦, J♣]` with starter `5♣` (Jack is nobs, four 5s give maximum 15-combos and a four-of-a-kind). This is extremely rare but theoretically possible.

### Scoring Order (per round)

1. **Nibs** (if starter is Jack → dealer gets 2 pts). Checked in `confirmDiscard`.
2. **Pegging** (during play, both players alternately).
3. **Non-dealer's hand** (counted first — opponent of dealer gets to "count out" first, which can end the game before the dealer's advantageous crib is counted).
4. **Dealer's hand**.
5. **Dealer's crib**.

This order matters because a player can win the game during any scoring step.

### Win Condition

- First player to reach or exceed **121 points** wins.
- Win can occur at any scoring moment: nibs, a single pegging card, or during hand/crib counting.
- The check `>= 121` is applied immediately after every point gain.
- Target is 121 (not 120) because the final scoring hole is hole 121.

---

## Enhancements & Edge Cases

### Nibs at Game End

- If the dealer cuts a Jack starter and nibs pushes their score to ≥ 121, they win immediately, before pegging begins.
- The message `'You win with nibs!'` is shown; phase set to `CribbagePhase.gameOver`.
- Implemented in `confirmDiscard()` with an early-return check.

### Pegging Win Mid-Sequence

- If a player reaches 121 during pegging (e.g., playing a card that scores 2 for a pair), the game ends immediately.
- The `playPegCard` and `_aiPegTurn` methods both check `>= 121` after adding points, before any further state changes.

### Non-Dealer Counting Out First

- `_startCounting` always scores the non-dealer's hand first.
- If the non-dealer wins during counting (e.g., scores enough to hit 121 on their hand), the game ends before the dealer scores their crib.
- This is the standard cribbage rule and is implemented in the scoring order within `_startCounting`.

### Go Sequence (Complex Case)

Scenario: Human plays, AI says Go, human plays again (one or more cards), neither can play.

1. AI finds no playable cards → says Go (`isPlayerPegging = true`).
2. Human plays remaining cards (all scoring opportunities apply each play).
3. If human reaches a card that would bust 31 with remaining cards, either their own play empties their hand while AI can't follow (handled inline in `playPegCard`, step 8 above) or they tap **Go** (`sayGo()`) if a card remains but none fit. Either way, exactly one +1 last-card point is awarded, to whoever played last (tracked via `lastToPlayWasHuman`), via `_resolveGoStoppage()`.
4. Count resets to 0. `pegTable = []`. The side that did **not** just play leads the new series — correct regardless of dealer status (fixed 2026-07-15; previously hardcoded to `!isPlayerDealer`, which could even leave the same player leading twice in a row).
5. If both hands are now empty → `_startCounting()`.

### 31 Reset vs. Last Card

- **31**: Playing the card that makes the count exactly 31 → +2 points. Table resets. Does NOT also score +1 for last card.
- **Last card**: If the count does not reach 31 but neither player can play, the last person to play scores +1 (not +2). This is separate from and mutually exclusive with the 31 bonus.

### Flush in Crib

- A 4-card flush in the crib does NOT score. Only a 5-card flush (all 4 crib cards + starter same suit) scores in the crib.
- This is enforced via `isCrib` parameter in `_countFlush`.

### Nobs vs. Nibs Terminology

- **Nobs**: Jack in the hand that matches the starter's suit → +1 during hand counting.
- **Nibs (Heels)**: Starter card itself is a Jack → dealer gets +2 immediately upon cut.

### Multiple Fifteens

- Each distinct combination (subset) that sums to 15 scores independently.
- With a hand like `[5, 5, 5, J, starter=5]`: subsets `{5,J}` appear 4 times (one for each 5 paired with J=10), plus `{5,5,5}` (four choose 3 = 4 times), and potentially `{5,5,5,5}` if sum allows. Total can be very high.
- The bitmask enumeration in `_countFifteens` correctly counts every non-empty subset.

### AI Discard Strategy

- `_aiSelectDiscard` uses a greedy approach: test all C(6,2) = 15 possible discard pairs (equivalently all C(6,4) = 15 keep combinations).
- Evaluation: `scoreHand(keep, dummyStarter)` using one dummy starter (first available non-hand card). This is a rough estimate that does not account for crib value or expected starter distributions.
- Limitation: AI does not consider crib ownership when discarding — it always optimizes its kept hand, regardless of whether the crib belongs to it or the opponent. A stronger AI would keep lower cards in its hand when the crib belongs to the opponent.

### Pegging Run Detection

`scorePegging` for runs checks the last N cards in the peg table (working from largest N downward):

```dart
for (int len = played.length; len >= 3; len--) {
  final tail = played.sublist(played.length - len).map(pipValue).toList()..sort();
  // Check all consecutive AND no duplicates (toSet().length == len)
  if (tail.toSet().length == len && isRun) { score += len; break; }
}
```

Example: peg table `[3♠, 5♦, 4♥]`. After playing 4: tail sorted = [3,4,5] → run of 3 → +3.

Example with non-run middle: `[2♠, 7♦, 4♥, 5♣, 6♦]`. After playing 6: tail of 4 sorted = [4,5,6,7] → run of 4 → +4.

---

## Known Gaps / Future Work

None currently tracked for pegging Go/scoring/lead. (Human "Go" not triggerable, double-scored Go/last-card points, and the dealer-hardcoded post-reset peg lead were all fixed 2026-07-15 — see `sayGo()`, `_resolveGoStoppage()`, and `CribbageState.lastToPlayWasHuman` in `logic.dart`.)

## Implementation Notes

### State Management Fields (`CribbageState`)

| Field | Type | Description |
|-------|------|-------------|
| `deck` | `List<int>` | Remaining cards after dealing. |
| `playerFullHand` | `List<int>` | All 6 cards dealt to the human (before discard). |
| `playerHand` | `List<int>` | The 4 cards the human kept. Empty until discard confirmed. |
| `aiHand` | `List<int>` | The 4 cards the AI kept. |
| `crib` | `List<int>` | 4 discarded cards (2 AI + 2 human). Dealer owns it. |
| `starter` | `int?` | The cut card. `null` until discard is confirmed. |
| `pegTable` | `List<int>` | Cards played in the current pegging sequence. Resets on 31 or Go. |
| `playerPegging` | `List<int>` | Human's remaining pegging cards. |
| `aiPegging` | `List<int>` | AI's remaining pegging cards. |
| `pegCount` | `int` | Running sum of face values on `pegTable`. Resets on 31/Go. |
| `playerScore` | `int` | Human's running total (target: 121). |
| `aiScore` | `int` | AI's running total (target: 121). |
| `isPlayerDealer` | `bool` | `true` = human is dealer this round. |
| `isPlayerPegging` | `bool` | `true` = human's peg turn. |
| `phase` | `CribbagePhase` | `discarding`, `pegging`, `counting`, or `gameOver`. |
| `selectedDiscard` | `Set<int>` | Indices (0–5) of cards in `playerFullHand` toggled for discard. |
| `message` | `String` | UI instruction/status string. |
| `winner` | `String?` | `'You'`, `'AI'`, or `null`. |
| `lastToPlayWasHuman` | `bool?` | Who most recently added a card to `pegTable` (not a Go pass, which adds nothing). Drives Go/last-card point attribution and post-reset peg lead in `_resolveGoStoppage()` — added 2026-07-15 (GB12/GB13 fix). |

### CribbagePhase Enum

```dart
enum CribbagePhase { discarding, pegging, counting, gameOver }
```

### Provider

```dart
final cribbageStateProvider =
    NotifierProvider<CribbageNotifier, CribbageState>(CribbageNotifier.new);
```

### Top-Level Card Helpers

```dart
int suitOf(int c) => c ~/ 13;         // 0=♣ 1=♦ 2=♥ 3=♠
int rankOf(int c) => c % 13;          // 0=A 1=2 … 12=K
int faceValue(int c) => min(rankOf(c) + 1, 10);  // A=1, J/Q/K=10
int pipValue(int c) => rankOf(c) + 1; // A=1 … K=13
String cardLabel(int c) => '${_rankLabels[rankOf(c)]}${_suitSymbols[suitOf(c)]}';
bool isRed(int c) => suitOf(c) == 1 || suitOf(c) == 2; // ♦ or ♥
```

### UI Logic Snippets

```dart
// Discard phase: show confirm button only when exactly 2 selected
bool canConfirmDiscard(CribbageState s) {
  return s.phase == CribbagePhase.discarding && s.selectedDiscard.length == 2;
}

// Is this card in the discard selection?
bool isSelectedForDiscard(CribbageState s, int handIdx) {
  return s.selectedDiscard.contains(handIdx);
}

// Pegging: can the human tap this card?
bool canPlayPegCard(CribbageState s, int handIdx) {
  if (!s.isPlayerPegging || s.phase != CribbagePhase.pegging) return false;
  final card = s.playerPegging[handIdx];
  return faceValue(card) + s.pegCount <= 31;
}

// Counting phase: show "Next Round" button
bool showNextRoundButton(CribbageState s) {
  return s.phase == CribbagePhase.counting;
}

// Game over
bool isGameOver(CribbageState s) => s.phase == CribbagePhase.gameOver;
```

### Folder Structure

- **Logic**: `lib/ui/games/games/cribbage/logic.dart`
- **Screen**: `lib/ui/games/games/cribbage/screen.dart`
- **Assets**: `assets/games/cribbage/` — card sprites (Norse-bordered), card back, crib chest, peg board image, score peg markers.

### Testing Guidance

- **Unit tests** (`test/cribbage_test.dart`):
  - `_countFifteens`: test `[5,5,5,J,5]` (starter=5) → should yield 8 fifteens = 16 pts.
  - `_countPairs`: three of a kind = 6, four of a kind = 12, two pairs = 4.
  - `_countRuns`: run of 5 = 5 pts; run of 3 with no duplicates; double run of 3 ([3,4,4,5]) = 6 (note known simplification in current code).
  - `_countFlush`: 4 hand cards same suit, starter different → 4 pts (non-crib); starter same → 5 pts; crib with only 4 matching → 0 pts.
  - `_countNobs`: Jack in hand matching starter suit → 1 pt; Jack not matching → 0.
  - `scorePegging`: 15 = 2 pts; pair = 2; trip = 6; quad = 12; run of 3 = 3; run + 15 = 5; 31 = 2.
  - `scoreHand`: known hand `[5♠, J♣, 5♥, 5♦]` with starter `5♣` → 29 pts.
  - Nibs: `confirmDiscard` with Jack starter, player is dealer → pScore += 2; check game over if pScore >= 121.
  - Pegging win: player reaches 121 mid-peg → gameOver triggered, not counting phase.
  - Non-dealer counts first: if player is dealer, AI (non-dealer) hand scored before player hand+crib.
  - Go sequence: AI says Go, human plays last card, count < 31 → human gets +1 last card.
  - 31: playing to exactly 31 → +2 for 31 (not also +1 for last card).
  - Dealer alternates: after each round, `isPlayerDealer` flips.
  - `_aiSelectDiscard`: verify it returns a 4-card list, all in original 6.
  - `sayGo()` (GB11): no-op with a legal card in hand; passes to AI with no score when AI can still play; a mutual stoppage scores whoever played the table's last card (via `lastToPlayWasHuman`), not unconditionally AI.
  - Stoppage handling (GB12): playing your last card when AI can't follow scores the last-card point exactly once, with the table/count reset immediately rather than left for `_aiPegTurn()` to rediscover and double-award.
  - Peg lead after reset (GB13): parameterized over both `isPlayerDealer` values to prove the post-31/Go lead follows who played last, not dealer status.
  - Tests exercising `playPegCard`/`sayGo()`/`confirmDiscard` schedule real internal timers (AI's peg turn, the counting transition) — use `package:fake_async`'s `fakeAsync()`/`async.elapse()` to drain them deterministically rather than a real `await Future.delayed(...)`, which is racy across a sequential test file (a slow-draining test's dangling timer can fire during a later, unrelated test).
- **Integration tests**:
  - Full round from deal through counting, scores accumulate correctly.
  - Multiple rounds: dealer alternates, scores persist across rounds.
  - Win by counting: player hand pushes score to 121 during counting.

### Viking Theme Notes

- Cards: full standard deck with Norse-border art. Face cards (J/Q/K) depict Norse figures (e.g., Queen = Skadi, King = Odin, Jack = Loki). Suits styled as Norse symbols: ♣=raven, ♦=axe, ♥=helm, ♠=ship.
- Card backs: dark wood grain with golden rune border.
- Crib: represented as a carved wooden chest in the center of the table. Belongs to the dealer (shows their clan symbol).
- Peg board: traditional cribbage peg board styled as a longship's oar rack with carved notches. Two tracks (one per player) with pegs advancing. Track length: 121 holes.
- Score animation: pegs advance along the board with a click/clack sound.
- Nibs: brief fanfare (Norse horn blast) and golden glow on the starter card.
- Win screen: raising of a mead horn (human win) or the longship sinking into the fog (AI win). Runic inscription of final score.
- Background: mead hall table with candle light, soft amber tones consistent with `SisuColors` palette from `lib/core/colors.dart`.
