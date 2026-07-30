# Liar's Dice — Game Flow & Multiplayer Architecture

Developer specification.  Read this before touching `logic.dart` or `screen.dart`.

---

## Game Modes

| Mode | Description |
|---|---|
| **Single-player** | One human + 1–9 AI players on one device |
| **Multiplayer host** | Host device; runs game logic; pushes state to clients |
| **Multiplayer client** | Guest device; renders received state; sends moves to host |

The host-authoritative model means **all game logic runs on the host**.  Clients
send action messages; the host applies them, mutates state, then broadcasts the
new state to everyone.  A client never calls `notifier.*` directly — it calls
`gameLanService.sendMove(action, data)` instead.

---

## State Machine

States are defined in `GameStateEnum` (`logic.dart`):

```
start
  │  addPlayer() / removePlayer()  (host/SP only)
  ▼
determineStarter          — all players roll once; highest hand goes first
  │  determineStarter()   (host/SP only; auto-fired after 2 s)
  │  If tied: re-rolls only the tied players and repeats until one winner
  ▼
rollDice                  ← start of every round
  │  [human] Roll button → finalizeRoll(dice)
  │  [AI]    auto-fired after 2 s                  (host/SP only)
  ▼
declareHand
  │  [human] Declare button → declareBid(bid)
  │  [AI]    auto-fired after 2 s (hand-aware bid)  (host/SP only)
  ▼
acceptChallenge
  │  [human] Accept / Challenge button → acceptChallenge(bool)
  │  [AI]    auto-fired after 2 s (dice-aware decision)  (host/SP only)
  │
  ├─ accept=true  → acceptReveal (3 s dice reveal for all players, no counter lost)
  │                    │  advanceFromAcceptReveal()   (host/SP only; auto-fired after 3 s)
  │                    └─ rollDice (next declarer = opposition player)
  │
  └─ accept=false → resolveChallenge
                       │  resolveChallenge()        (host/SP only; auto-fired after 3 s)
                       ▼
                   determineGameOver
                       │  determineGameOver()        (host/SP only; auto-fired immediately)
                       │
                       ├─ someone at 0 counters → gameOver
                       └─ game continues          → rollDice (same currentTurn = round winner)
```

---

## Per-Device View Rules

Every non-host device receives the full `GameState` from the host but must
render a **restricted view** to prevent cheating.

| Device | What they see |
|---|---|
| Declarer (`player.id == localPlayerId`) | Their own dice (bottom row) |
| Everyone else | `?` dice in the bottom row |
| All devices | The declared hand in the top row (or empty before first declare) |

`localPlayerId` is read from `localPlayerIdProvider` (`logic.dart`):
- `null` in single-player mode
- `'host'` on the host device (set in `lobby_screen.dart` after `_host()`)
- `peer_N` (e.g. `'peer_1'`) on client devices (set inside the `gameStarted` listener using `gameLanService.myAssignedId`)

Helper functions used by `screen.dart`:

```dart
bool _isDeclarerMe(GameState gs, String? localPlayerId)
bool _isOpponentMe(GameState gs, String? localPlayerId)
```

Both fall back to "first non-AI player is you" when `localPlayerId` is null
(single-player mode).

---

## Action Routing

All user-initiated actions go through `_sendOrApply()` in `screen.dart`:

```
host / single-player  →  call notifier method directly
client                →  gameLanService.sendMove(action, data)
```

The host receives client moves via `GameLanService.incomingMoves` and applies
them in `GameStateNotifier._applyRemoteMove()`.  After every mutation the host
calls `_broadcastIfHost()` which sends the full state JSON to all clients via
`GameLanService.broadcastState()`.

Supported action keys (sent as strings over the wire):

| Action | Payload fields | Who can send |
|---|---|---|
| `finalizeRoll` | `dice: List<int>` | Declarer (client or host) |
| `declareBid` | `rank: String, face: int` | Declarer (client or host) |
| `acceptChallenge` | `accept: bool` | Opposition player (client or host) |
| `resolveChallenge` | _(none)_ | Host only (auto-fired) |

---

## Multiplayer Setup Sequence

### Host path

1. `GameLobbyScreen._host()` — calls `GameLanService.hostGame(gameName, hostPlayerName)`
2. mDNS service broadcast starts; WebSocket server binds to OS-assigned port
3. `localPlayerIdProvider` is set to `'host'`
4. Joining clients appear in `GameLanService.playerJoins` stream → lobby list updates
5. Host may tap **Add AI Player** any number of times (added 2026-07-13) —
   `GameLanService.addLocalPlayer(LobbyPlayer(..., isAI: true))` appends a
   host-local seat (no network connection) and re-broadcasts the lobby list so
   already-connected clients see it too; **Remove** (trash icon) undoes it
   before start via `removeLocalPlayer`
6. Host taps **Start Game** → `notifier.initHostMode(lobbyPlayers)` seeds players from
   lobby (`Player.isAI` now comes from `LobbyPlayer.isAI`, not hardcoded false),
   then `notifier.startGame()` + `lan.startGame()` fires
7. `GameLobbyScreen` navigates to `LiarsDiceScreen`

### Client path

1. `GameLobbyScreen._scan()` — calls `GameLanService.scanForGames()` (bonsoir discovery)
2. Player taps a discovered game → `_connect(service)` → `lan.joinGame(service, name)`
3. Host receives `join` message and replies with a `welcome` message: `{ yourId: 'peer_N' }`
4. Client stores `_myAssignedId = 'peer_N'` in `GameLanService`
5. When host taps Start, client receives `start` message → `gameStarted` stream fires
6. Inside the `gameStarted` listener: `localPlayerIdProvider` ← `lan.myAssignedId`
7. `notifier.initClientMode()` subscribes `remoteStates`; client navigates to `LiarsDiceScreen`

---

## Auto-Advance Rules (host / single-player only)

All timed auto-advances and AI actions are **gated on `!notifier.isClientMode`**.
A client device must never auto-fire any state transition — only the host
drives time-based progression.

**The `rollDice`/`declareHand` auto-timers are additionally gated on
`currentPlayer.isAI`** (fixed 2026-07-13) — without this, the host's own screen
can't tell "not my turn because it's an AI bot" from "not my turn because it's
a real remote peer", and would auto-roll/auto-declare on a real human client's
behalf after 2 seconds. `acceptChallenge`'s auto-timer already had this gate
(`opponent.isAI` in `_AcceptChallengeUIState`) — the roll/declare timers were
the only two missing it. This was never caught because no changelog entry
shows an actual multi-device LAN game (2+ real connected peers) was ever
live-tested before 2026-07-13 — see "Live Multiplayer Test Plan" below.

| State | Who advances | Trigger |
|---|---|---|
| `determineStarter` | host/SP | `Timer(2 s)` after `startGame()` |
| `rollDice` (AI) | host/SP | `Timer(2 s)` after entering state |
| `declareHand` (AI) | host/SP | `Timer(2 s)` after entering state |
| `acceptChallenge` (AI) | host/SP | `Timer(2 s)` after entering state |
| `resolveChallenge` | host/SP | `Timer(2 s)` in `_ResolveChallengeUI` |
| `determineGameOver` | host/SP | `addPostFrameCallback` immediately |

---

## Local UI State Reset

Between rounds the following providers are reset/reseeded so stale local UI
state doesn't leak into the next turn. This happens in a `ref.listen` inside
`_GameplayUI` whenever the state enters `rollDice` with a different `currentTurn`
(and mirrored in `initState`'s `addPostFrameCallback` for the case where the
widget mounts while already in `rollDice`, e.g. right after challenge resolution):

| Provider | Reset value |
|---|---|
| `hasRolledProvider` | `false` |
| `diceHoldsProvider` | `[false, false, false, false, false]` |
| `myDiceProvider` | **seeded from `next.players[next.currentTurn].dice`** (the One-box inherited/shared dice — NOT a fixed `[1,1,1,1,1]`) |
| `selectedRankProvider` | `null` |
| `selectedFaceProvider` | `null` |

---

## Key Files

| File | Role |
|---|---|
| `logic.dart` | `GameStateNotifier`, all game enums, models, providers, `localPlayerIdProvider` |
| `helpers.dart` | Pure functions: `evaluateHand`, `compareBids`, `isValidBid`, `rollDice`, `rollDiceWithHolds`, `bestHoldMask`, `rankToString`, `faceToString` |
| `screen.dart` | All game UI; top-level `_isDeclarerMe`, `_isOpponentMe`, `_sendOrApply` helpers |
| `../../../services/lan/game_lan_service.dart` | Game protocol: lobby, welcome handshake, state broadcast, move routing |
| `../../../services/lan/lan_engine.dart` | Transport: mDNS (bonsoir 6.x) + WebSocket (dart:io) |
| `../../../services/lan/lan_providers.dart` | Riverpod providers for LAN services (imported by screens, NOT by di.dart) |
| `../../lobby/lobby_screen.dart` | Pre-game lobby: host/join, mDNS scan, player list, start signal |

---

## LAN Transport Summary

- **mDNS library**: `bonsoir ^6.1.0` — sealed-class event API; always pattern-match event
  subtypes, never use `.type` strings
- **Transport**: `dart:io` WebSocket — no external packages needed
- **Service type**: `_sisumate._tcp`
- **Port**: OS-assigned (`InternetAddress.anyIPv4, 0`) — port is embedded in the mDNS
  service record and read via `BonsoirService.port` after resolution

---

## AI Strategy

**Rolling (`bestHoldMask`, added 2026-07-13):** before rolling, the AI holds
whichever face forms the largest group in its current/inherited dice (ties
broken by the higher face value) and only rerolls the rest — e.g. inheriting
`[4,3,5,5,6]` via one-box holds the pair of 5s, rerolling the other 3. Simple
heuristic, doesn't attempt straight completion. Previously the AI did a
**blind full reroll every time** (`rollDice()`, discarding any inherited
hand entirely) — found live during the 2026-07-13 multiplayer test, verified
fixed by both new unit tests (`bestHoldMask` group in `liars_dice_test.dart`)
and a live solo-mode session where the AI truthfully declared "Four of a
Kind" immediately after its first roll (a challenge against it failed,
confirming the claim was genuine — implausible from a blind full reroll,
consistent with holding a strong partial hand from the initial roll).

**Bidding (`getAIBid`):** evaluates the AI's actual hand (`evaluateHand(dice)`), then tries to bid that rank at the *minimum* valid face (1 → 6, fixed 2026-07-04 per F7 — previously searched high-to-low and always overbid to the maximum face). If the honest hand can't beat the last bid, it escalates to the next better rank. Only as a last resort does it find the minimum valid bluff above the last bid.

**Accepting (`getAIAccept`):** compares the AI's own dice rank against the declared rank, weighted by the declared rank's absolute rarity (added 2026-07-04, F7) — a claim that's inherently a long shot (< 2% of honest rolls) is challenged even if the AI's own hand doesn't directly contradict it. If the declared hand is 3+ rank levels better than the AI's own, it challenges. If the declared rank is equal or weaker, it accepts. In the middle ground it accepts 70-85% of the time depending on how plausible the claim is.

---

## Known Gaps / Future Work

| Gap | Notes |
|---|---|
| Reconnection is limited, not absent | Client-side: 3 retries, 2s apart, then the session ends cleanly (`_handleHostDisconnect`). Host-side: a disconnected player is dropped, game continues if ≥2 remain (`_handleDisconnect`). No resume-into-an-existing-game after the retry window lapses. |
| AI across multiple players | `getAIBid` / `getAIAccept` use the single current player's dice; a smarter AI could account for how many dice total are on the table |
| Tie re-roll display | Tied players' dice are re-rolled in place; no animated "re-rolling" indication for each tied player |

---

## Live Multiplayer Test Plan (2026-07-13)

> Context: no changelog entry shows an actual multi-device LAN game (2+ real
> connected peers) was ever live-tested before this plan — every prior
> verification was either unit tests or single-device AI-vs-AI play. This is
> the first real end-to-end test of the networking this game was built on.

### Pre-existing defects fixed as part of "finishing" this game (2026-07-13)

1. **Critical — host hijacked real remote peers' turns.** `_GameplayUIState`'s
   roll/declare auto-timers gated only on `!declarerIsMe`, which is also true
   whenever it's a **real remote human's** turn (not just an AI's). Fixed by
   adding `currentPlayer.isAI` to both conditions, matching the pattern
   `_AcceptChallengeUIState` already had. Without this fix, any real client
   taking longer than 2s to roll/declare would have their turn overwritten by
   a random host-generated move.
2. **Feature gap — no way to add an AI seat to a multiplayer lobby.**
   `initHostMode` hardcoded every lobby player to `isAI: false`, and the lobby
   UI had no AI-adding control (unlike solo mode's `_StartStateUI`). Fixed:
   `LobbyPlayer` gained an `isAI` field (default false, wire-compatible);
   `GameLanService.addLocalPlayer()`/`removeLocalPlayer()` let the host add/
   remove host-local bot seats (no network connection, re-broadcasts the
   lobby list so connected clients see them too); `GameLobbyScreen`'s
   `_HostingView` got an **Add AI Player** button + a delete icon on AI rows;
   `initHostMode` now reads `lp.isAI` instead of hardcoding `false`.
3. Self-healed this doc: the "Local UI State Reset" table claimed
   `myDiceProvider` resets to `[1,1,1,1,1]` every round — the actual code
   (One-box rule) seeds it from the inherited/shared dice. The "Reconnection"
   gap row claimed no reconnect logic exists at all — `_handleHostDisconnect`
   (client-side, 3 retries) and `_handleDisconnect` (host-side) have existed
   since the 2026-07-04 F6 fix; both rows now describe the real behavior.

### Known environmental risk — verify before the full mixed test

Android emulators' default networking (SLIRP/user-mode NAT) historically does
**not** support mDNS multicast between emulator instances, or between an
emulator and the host's real network (which iOS Simulators share directly,
since they are not NAT'd). This has never been tested on this machine for
this app. **Step 0 below exists specifically to find out before committing to
the full 4-device topology** — if Android-to-Android or Android-to-iOS
discovery fails, that's an emulator/tooling limitation to route around
(e.g. fewer Android instances, or flag it and proceed iOS-heavy), not an app
bug, and should be logged as such rather than as an LT6 failure.

### Test topology (per user decision, 2026-07-13)

- **4 real connected LAN peers**, split evenly across platforms: 2 iOS
  Simulators + 2 Android emulators — this is the actual LT6 stress test
  (turn-order/lobby flow across many concurrent connections, not just 2).
- **Plus AI bot seats added on top** by the host (via the new Add AI Player
  button) so the game also exercises AI turns interleaved with real remote
  peers in the same session — this is what Bug #1 above would have broken.
- **Human seats are agent-driven**, not a live human tester: taps are issued
  via `adb`/`simctl` with human-like pacing (multi-second think time before
  declaring/accepting) specifically to stress the 2-second auto-timer window
  Bug #1 was hiding behind — an instant-tap test would not have caught it.
- Total players: 4 real devices + 2 AI bots = 6.

### Device roles & order

| Step | Device | Role | Notes |
|---|---|---|---|
| 1 | iOS Simulator #1 | Host | Adds 2 AI bot seats immediately, before any client joins (tests that a joining client receives the AI seats via the re-broadcast lobby list, not just at game-start) |
| 2 | Android emulator #1 | Client (join 1st) | |
| 3 | iOS Simulator #2 | Client (join 2nd) | |
| 4 | Android emulator #2 | Client (join 3rd) | |
| 5 | iOS Simulator #1 (host) | Start Game once all 4 real devices + 2 AI bots are listed | |

Join order deliberately alternates platform (iOS host → Android → iOS →
Android) so platform mix is exercised throughout setup; actual turn order
within the game is dice-luck-determined by `determineStarter`, not join order
— that's expected and matches the real game rules, not something to control.

### Play-through checklist (log any divergence per outstanding.md Rule 3)

- [x] Step 0: 2-device connectivity smoke test — confirmed cross-platform
      (iOS↔Android) discovery/join works on this machine; the one NAT-isolated
      `10.0.2.x` address correctly failed to connect (emulator networking
      fact, not an app bug)
- [x] Lobby: all 4 real devices + 2 AI seats visible on every device's lobby
      view before Start (6 total: IOS-Host, AI 1, AI 2, Android1, Android2, IOS-2)
- [x] `determineStarter` — Android1 won on the first roll (no tie this run;
      the tie/re-roll path already has deterministic unit test coverage in
      `test/liars_dice_test.dart`, not re-verified live here)
- [x] A full `rollDice → declareHand → acceptChallenge` cycle where the
      opposition player is a real remote peer, with a deliberately slow
      (6+ second) response — **direct regression test for Bug #1, passed**:
      host correctly showed "Waiting for Android1 to roll…"/"…to declare…"
      throughout, never auto-played
- [ ] The same cycle with an AI bot as the opposition player (not exercised
      this run — Android1 declared and Android2, a real peer, challenged
      before an AI bot's turn came up in the two-player-focused bid/challenge
      cycle; AI turns are exercised continuously in solo mode's existing test
      coverage, just not re-confirmed in this specific multi-peer session)
- [ ] `acceptChallenge(accept: true)` → `acceptReveal` → One-box inheritance
      (this run's declare was **challenged**, not accepted — the accept path
      already has deterministic unit coverage; not re-verified live here)
- [x] A challenge (`accept: false`) → `resolveChallenge` → `determineGameOver`
      continuing — Android2 challenged an honest declare, challenge correctly
      **failed** (declared ≤ actual), Android2 lost a counter (10→9), and the
      next round correctly started with Android2 as declarer (challenger
      always starts next round) with freshly-rolled dice
- [ ] Game reaching `gameOver` naturally (not run to completion — one full
      round was enough to validate the fixes; not needed to prove the same
      state machine keeps working every additional round)
- [ ] A mid-game disconnect via killing a client app (not exercised this
      run — the session ended by intentionally killing the *host* instead,
      while validating the lobby-lifecycle fix, which incidentally confirmed
      the existing client-side `_handleHostDisconnect` path: both remaining
      clients correctly showed "Connection to host lost. Game ended.")

### Lobby lifecycle fix (found during this test, 2026-07-13)

Canceling a hosted lobby (or backing out before Start) didn't tear down the
WebSocket server + mDNS broadcast — a cancelled host kept showing up,
unreachable, in every future scan ("zombie" host). Fixed: `GameLobbyScreen`
now calls `_lan.endSession()` in `dispose()` whenever the lobby is left
without starting (guarded by a `_gameStarted` flag so a *successful* start
doesn't tear down the connection it just made), plus explicit Cancel buttons
on every lobby sub-view. **The first fix attempt silently failed** — caching
lesson worth repeating: `GameLanService get _lan => ref.read(...)` (a getter,
re-reading every access) throws `Bad state: Using "ref" ... unsafe` when
called from `dispose()`, and Flutter's widget-tree-finalization swallows that
exception, so it *looked* fixed (clean navigation, no crash) while never
actually running. Caught only by checking OS-level ground truth (`lsof -nP
-iTCP:<port>` still showed the server bound) rather than trusting a
screenshot. Real fix: `late final GameLanService _lan = ref.read(...)` —
resolved once, safe to reuse in `dispose()`. See changelog for the full story.

**Not implemented** (scoped as `LT7` in outstanding.md, not attempted here):
mid-game reconnect into your *same* seat. A peer that disconnects mid-game
and reconnects gets a brand-new `peer_N` id with no path back into
`GameState.players` — needs a deliberate name/token-matching design that
crosses the generic-transport/game-specific-state boundary, not a quick patch.

### After the test

`outstanding.md` LT6 marked done for Liar's Dice; `LT7` added for the
mid-game-reconnect gap. `changelog.md` has the full narrative including the
first-fix-attempt correction. Reusable setup for next time:
`scripts/liars_dice_4sim_setup.sh` + `live_test_setup.md` (same directory).
