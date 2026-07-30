# Liar's Dice — Live 4-Sim Multiplayer Test Setup

Fast path to a ready-to-play 4-device Liar's Dice game (2 iOS Simulators +
2 Android emulators, host + 2 AI bots = 6 players). Read this before manually
tapping through sims again — it's already been done once the hard way (see
changelog 2026-07-13); don't repeat that.

---

## One command to get to "ready"

```bash
bash scripts/liars_dice_4sim_setup.sh
```

This force-stops and relaunches the app on all 4 devices (clean slate — no
zombie host sessions from a prior run), then drives: host lobby + 2 AI bots →
3 real clients join. Ends with the host on "Start Game (6 players)". Then:

```bash
bash scripts/idb_tap_label.sh DCC47B42-BE62-4EBD-A6F2-B8A7E4C3A6D2 "Start Game"
```

**Built from validated manual steps (2026-07-13)** — every individual step
(toggle, host, add AI, join, cross-platform discovery) was proven live,
step-by-step, in the session that wrote this file, including a full played
round. The script chains those exact steps; still worth a screenshot spot
check of the host after running before trusting it blindly in a new session,
since it hasn't been run as one unattended script end-to-end.

---

## Device IDs (this machine)

| Role | Platform | ID |
|---|---|---|
| Host | iOS Sim — iPhone 16 | `DCC47B42-BE62-4EBD-A6F2-B8A7E4C3A6D2` |
| Client | iOS Sim — iPhone 16e | `AB064E47-9EBD-460E-9DA4-07E552360FB5` |
| Client | Android emulator (`sync_arm_a`) | `emulator-5554` |
| Client | Android emulator (`sync_arm_b`) | `emulator-5556` |

`xcrun simctl list devices` / `adb devices` to re-discover if these change.
Boot a shutdown sim with `xcrun simctl boot <udid>`; boot a second Android AVD
with `flutter emulators --launch sync_arm_b` (NOT `sync_arm_a` again — that's
already `emulator-5554`, and two instances of the *same* AVD name conflict:
`Running multiple emulators with the same AVD is an experimental feature`).

---

## One-time environment setup (already done on this machine 2026-07-13)

Android automation uses `adb` (already present). iOS automation needs `idb`
(Facebook's iOS automation CLI) — `xcrun simctl` alone cannot inject taps:

```bash
brew tap facebook/fb
brew trust facebook/fb            # this Homebrew install requires explicit tap trust
brew install idb-companion
brew trust --formula dart-lang/dart/dart   # only if you hit an unrelated "untrusted tap" warning for dart-lang/dart

python3 -m venv .idb_venv
.idb_venv/bin/pip install fb-idb
```

Start a companion per iOS simulator (each needs its own port — the default
10882 only serves one target at a time):

```bash
idb_companion --udid <udid1> > /tmp/idb1.log 2>&1 &
idb_companion --udid <udid2> --grpc-port 10883 --debug-port 10884 > /tmp/idb2.log 2>&1 &
source .idb_venv/bin/activate
idb connect localhost 10882
idb connect localhost 10883
```

`scripts/liars_dice_4sim_setup.sh` does this automatically (checks if already
running via `pgrep` first).

---

## Why label-based taps, not raw coordinates

Every hardcoded pixel/point coordinate in this session was wrong at least
once, for a different reason each time:

- **iOS points vs pixels**: `idb ui tap` takes **logical points** (e.g. 393×852
  for iPhone 16), not the raw pixel dimensions a screenshot reports
  (1179×2556, a 3x scale). Converting by hand from a screenshot crop is
  fragile and got the wrong *row* entirely at one point.
- **A button's on-screen position isn't where a screenshot makes it look**:
  the "Add AI Player" button's true position (found via `idb ui
  describe-all`'s accessibility frame: `y:682` in points) was nowhere near a
  screenshot-based visual estimate (`y:516`). Always prefer accessibility
  introspection over eyeballing a screenshot crop.
- **Fixed-position elements outside a scrolling list don't move** when the
  list above them grows — don't recompute their position after every list
  change; only the scrollable content shifts.

**The fix, used throughout `scripts/idb_tap_label.sh` /
`scripts/adb_tap_text.sh`**: query the live accessibility tree
(`idb ui describe-all` / `uiautomator dump`) and tap the *center of the
matched element's reported frame/bounds*, never a hand-guessed coordinate.
This is robust to screen size, layout changes, and scroll position.

---

## Troubleshooting

**Multiple "Liar's Dice" entries in "Available games", not sure which is
real**: this happens when a previous host session wasn't torn down cleanly
(navigating back from the hosting lobby doesn't yet call
`GameLanService.endSession()` — a known gap, see `gameflow.md`'s Live
Multiplayer Test Plan and the "Lobby lifecycle" follow-up in
`outstanding.md`). The zombie keeps broadcasting via mDNS indefinitely.
**Fix**: force-stop and relaunch the app on whichever device was hosting
before — killing the process closes its WebSocket server and stops the
broadcast. `liars_dice_4sim_setup.sh` does this for all 4 devices up front
specifically to avoid this ambiguity.

**A discovered entry's address is `10.0.2.x` and joining it fails with
`SocketException: ... No route to host`**: that's an Android emulator's
**isolated NAT interface** (SLIRP), which an iOS Simulator (sharing the host
Mac's real network) cannot reach. Not an app bug — this machine's Android
emulators apparently ALSO bridge to the host's real LAN IP (they showed up as
`192.168.0.151`, the Mac's address, in every successful join) so real
cross-platform discovery does work; just avoid tapping the `10.0.2.x` entry.

**iOS keyboard-dismiss + button tap race**: after `idb ui text`, the on-screen
keyboard is still up. Tapping a button whose position you read from a
*pre-keyboard-dismiss* screenshot can land on the wrong element once the
keyboard closes and the layout reflows. Always dismiss the keyboard first
(iOS: tap elsewhere or the return key; Android: `input keyevent 111`) and
re-read the layout before tapping the next button.

**`adb_tap_text.sh`/label search matches the wrong element when two elements
share a substring**: e.g. matching `"Liar's Dice"` hits the AppBar title
("Liar's Dice — Multiplayer", earlier in the dump) before the actual list
row ("Liar's Dice", the discovered-game entry) — `grep`'s `head -1` takes
whichever comes first in the accessibility tree, not necessarily the
clickable one you meant. Use a more specific/unique substring (e.g. the
port number, or `-c` on distinguishing text) when two elements could match.

**A toggle switch tapped via its label doesn't always register — verify
`checked=`/state before proceeding, don't assume the tap landed**: navigating
to a fresh screen can reset toggle state, and tapping immediately after
without confirming the new state can silently continue in the wrong mode
(e.g. landing on the solo-mode "Add Players" screen instead of the
multiplayer lobby because the toggle was actually still off). Re-check state
via `uiautomator dump`/`describe-all` after any toggle tap before continuing
a multi-step script blind.

**Riverpod `ref.read()` inside `State.dispose()` throws `Bad state: Using
"ref" ... unsafe` — and Flutter's widget-tree finalization swallows it
silently**: a `get` accessor pattern (`Foo get _thing => ref.read(...)`) used
from `dispose()` fails with no visible crash and no error on screen — the
UI navigates away looking completely normal, while the cleanup call inside
that getter's caller never actually executes. This makes "it looked fine"
verification (a screenshot after the action) actively misleading. Cache the
provider value in a field instead (`late final Foo _thing =
ref.read(...);`, resolved once on first access, long before dispose runs),
and verify cleanup claims against OS-level ground truth — `lsof -nP
-iTCP:<port>` for a server socket, not just a screenshot of the UI — plus
`flutter run`'s live console (not `simctl launch`, which has no attached
console) to actually see `EXCEPTION CAUGHT BY WIDGETS LIBRARY` if it's there.

**`xcrun simctl launch`/`am start` crashes the app instantly ("Runner quit
unexpectedly" / disappears in <1s)**: this was `GADApplicationIdentifier`
missing from `ios/Runner/Info.plist` — a real, now-fixed critical bug (see
`risks.md` Platform-Specific Divergences, changelog 2026-07-13). If it
recurs, check that key is still present before assuming it's an automation
issue.

---

## Manual fallback (if the script breaks)

1. Force-stop + relaunch the app on all 4 devices first — always start clean.
2. Host: Games tile → Multiplayer Mode toggle → Liar's Dice tile → name field
   → type name → Host Game → Add AI Player ×2.
3. Each client: Games tile → Multiplayer Mode toggle → Liar's Dice tile →
   name field → type name → **dismiss keyboard** → Join a Game → tap the one
   `Liar's Dice` entry in the list (there's only one after a clean restart).
4. Host taps Start Game once the lobby shows all expected players.

Use `idb ui describe-all --udid <udid>` (iOS) or `adb -s <serial> exec-out
uiautomator dump /dev/tty` (Android) at any point to see exactly what's on
screen and its real coordinates, rather than guessing from a screenshot.
