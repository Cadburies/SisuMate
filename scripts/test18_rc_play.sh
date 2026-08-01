#!/usr/bin/env bash
# TEST18 live driver: plays a full Liar's Dice LAN round across 4 devices
# (iOS host + iOS client + 2 Android emulators + 2 AI seats), then kills one
# client mid-game and verifies LT7 same-seat rejoin end-to-end within the
# 15s grace window (kMidGameReconnectGrace).
#
# Precondition: scripts/liars_dice_4sim_setup.sh has just run successfully
# (host lobby shows "Start Game (6 players)"). Apps must already be installed
# on all 4 devices. Evidence screenshots land in /tmp/test18/.
#
# Usage: bash scripts/test18_rc_play.sh
set -uo pipefail
cd "$(dirname "$0")/.."

PKG="com.sailingsisu.sisumate"
IOS_HOST="DCC47B42-BE62-4EBD-A6F2-B8A7E4C3A6D2"   # iPhone 16  (IOS-Host)
IOS_CLIENT="AB064E47-9EBD-460E-9DA4-07E552360FB5" # iPhone 16e (IOS-2)
AND1="emulator-5554"                              # Android1
AND2="emulator-5556"                              # Android2
EVIDENCE="/tmp/test18"
mkdir -p "$EVIDENCE"
LOG="$EVIDENCE/run.log"
: > "$LOG"

log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG"; }

source .idb_venv/bin/activate

# ── label dumps ──────────────────────────────────────────────────────────────
ios_labels() { # $1 udid → newline-separated AXLabels with nonzero frames
  idb ui describe-all --udid "$1" 2>/dev/null | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for el in data:
    lab = el.get('AXLabel') or ''
    f = el.get('frame') or {}
    if lab and (f.get('width') or 0) > 0 and (f.get('height') or 0) > 0:
        print(lab)
"
}

and_labels() { # $1 serial → newline-separated text + content-desc attributes
  adb -s "$1" exec-out uiautomator dump /dev/tty 2>/dev/null \
    | grep -oE '(text|content-desc)="[^"]+"' | sed -E 's/^(text|content-desc)="(.*)"$/\2/' | grep -v '^$'
}

labels_of() { # $1 device-ref (ios:<udid> | and:<serial>)
  case "$1" in
    ios:*) ios_labels "${1#ios:}" ;;
    and:*) and_labels "${1#and:}" ;;
  esac
}

has_label() { # $1 device-ref, $2 needle (substring, fixed string)
  labels_of "$1" | grep -qF -- "$2"
}

# ── taps ─────────────────────────────────────────────────────────────────────
ios_tap() { bash scripts/idb_tap_label.sh "$1" "$2" >>"$LOG" 2>&1; }
and_tap() { bash scripts/adb_tap_text.sh "$@" >>"$LOG" 2>&1; }

tap_label() { # $1 device-ref, $2 label
  case "$1" in
    ios:*) ios_tap "${1#ios:}" "$2" ;;
    and:*) and_tap "${1#and:}" "$2" ;;
  esac
}

# Tap the discovered-game list entry on the joining view: exact "Liar's Dice",
# else a multi-line entry starting with the game name. Never the AppBar title
# ("Liar's Dice — Multiplayer" fails the exact match and is skipped).
tap_scan_entry() { # $1 udid
  local coords
  coords="$(idb ui describe-all --udid "$1" 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
hit = None
for el in data:
    lab = el.get('AXLabel') or ''
    f = el.get('frame') or {}
    if (f.get('width') or 0) <= 0 or (f.get('height') or 0) <= 0:
        continue
    if lab == \"Liar's Dice\" or lab.startswith(\"Liar's Dice\n\"):
        hit = (int(f['x'] + f['width']/2), int(f['y'] + f['height']/2))
        break
if hit is None:
    sys.exit(1)
print(f'{hit[0]} {hit[1]}')
")" || return 1
  read -r x y <<<"$coords"
  idb ui tap "$x" "$y" --udid "$1" >>"$LOG" 2>&1
}

# Poll for a label with timeout (keeps the rejoin path inside the 15s grace).
ios_wait_label() { # $1 udid, $2 needle, $3 timeout-s → 0 if seen
  local deadline=$((SECONDS + $3))
  while [ $SECONDS -lt $deadline ]; do
    if ios_labels "$1" | grep -qF -- "$2"; then return 0; fi
    sleep 0.4
  done
  return 1
}

# ── play-driving ─────────────────────────────────────────────────────────────
declare_with_device() { # $1 device-ref — full Roll → rank → face → Declare
  local d="$1"
  log "  $d: Roll Dice"
  tap_label "$d" "Roll Dice" || return 1
  sleep 2                      # human-ish think time before declaring
  tap_label "$d" "Select Rank" || return 1
  sleep 1
  tap_label "$d" "One Pair" || return 1
  sleep 1
  tap_label "$d" "Select Face" || return 1
  sleep 1
  tap_label "$d" "Sixes" || return 1
  sleep 1
  log "  $d: Declare (One Pair of Sixes)"
  tap_label "$d" "Declare" || return 1
}

# One poll pass over the given devices; drives whoever can act.
# ACTED=1 when this pass performed an action. DECLARE_SEEN=1 once any device
# shows declare/decide UI (used for round-cycle detection — AI-vs-AI cycles
# complete without any human tap, so Accept-taps can't be the round marker).
poll_drive_once() {
  ACTED=0
  local d labs
  for d in "$@"; do
    labs="$(labels_of "$d")"
    # Exact-line matches: "Accept" alone would also match the info card
    # "Android1 — Accept or Challenge?" shown on *every* device.
    if printf '%s\n' "$labs" | grep -qxF "Roll Dice"; then
      declare_with_device "$d" && ACTED=1
      sleep 2
    elif printf '%s\n' "$labs" | grep -qxF "Accept"; then
      log "  $d: Accept (exercises acceptReveal path)"
      tap_label "$d" "Accept" && ACTED=1
      sleep 4                  # acceptReveal shows for 3s on host
    fi
    if printf '%s\n' "$labs" | grep -qF "Select Rank" \
        || printf '%s\n' "$labs" | grep -qF "Accept or Challenge" \
        || printf '%s\n' "$labs" | grep -qF "to decide"; then
      DECLARE_SEEN=1
    fi
  done
}

# ── Phase 1: start the game ──────────────────────────────────────────────────
log "Phase 1: host taps Start Game"
if ! ios_labels "$IOS_HOST" | grep -qF "Start Game"; then
  log "FATAL: host lobby has no Start Game button — run liars_dice_4sim_setup.sh first"
  exit 1
fi
xcrun simctl io "$IOS_HOST" screenshot "$EVIDENCE/01_lobby_host.png" >/dev/null
ios_tap "$IOS_HOST" "Start Game" || { log "FATAL: Start Game tap failed"; exit 1; }
sleep 5                        # determineStarter auto-resolves after 2s
log "Phase 1 done — game started"

# ── Phase 2: one full round (roll → declare → accept/challenge → next roll) ──
log "Phase 2: driving one full round"
DECLARE_SEEN=0
ROUND_DONE=0
deadline=$((SECONDS + 180))
while [ $SECONDS -lt $deadline ]; do
  poll_drive_once "ios:$IOS_HOST" "ios:$IOS_CLIENT" "and:$AND1" "and:$AND2"
  if [ "$DECLARE_SEEN" = "1" ]; then
    # A declare/decide phase was seen; the next rollDice (fresh "Roll Dice"
    # button or "…to roll…" wait text) means a full cycle completed — this
    # also catches fully-autonomous AI-declarer/AI-opponent rounds.
    for d in "ios:$IOS_HOST" "ios:$IOS_CLIENT" "and:$AND1" "and:$AND2"; do
      if labels_of "$d" | grep -qxF "Roll Dice" || labels_of "$d" | grep -qF "to roll"; then
        ROUND_DONE=1
        break
      fi
    done
    [ "$ROUND_DONE" = "1" ] && break
  fi
  sleep 1
done
if [ "$ROUND_DONE" != "1" ]; then
  log "FATAL: full round did not complete within 180s"
  exit 1
fi
log "Phase 2 done — full round completed, next round underway"
xcrun simctl io "$IOS_HOST" screenshot "$EVIDENCE/02_after_round_host.png" >/dev/null

# iOS tap with scroll-retry (home grid's "Games" tile is below the fold).
# Taps only when the target is substantially visible — a sliver frame at the
# screen edge accepts the tap but iOS routes it to the home indicator.
ios_tap_scroll() { # $1 udid, $2 label
  local coords x y
  for _ in 1 2 3; do
    coords="$(idb ui describe-all --udid "$1" 2>/dev/null | python3 -c "
import json, sys
needle = sys.argv[1]
data = json.load(sys.stdin)
exact = None
sub = None
for el in data:
    lab = el.get('AXLabel') or ''
    f = el.get('frame') or {}
    w = f.get('width') or 0
    h = f.get('height') or 0
    if w < 44 or h < 44:
        continue
    c = (int(f['x'] + w/2), int(f['y'] + h/2))
    if lab == needle and exact is None:
        exact = c
    elif needle in lab and sub is None:
        sub = c
hit = exact or sub
if hit:
    print(f'{hit[0]} {hit[1]}')
" "$2")"
    if [ -n "$coords" ]; then
      read -r x y <<<"$coords"
      idb ui tap "$x" "$y" --udid "$1" >>"$LOG" 2>&1 && return 0
    fi
    idb ui swipe 196 700 196 250 --udid "$1" >/dev/null 2>&1 || true
    sleep 0.7
  done
  return 1
}

# In-game marker set: the game screen can be in rollDice (Scoreboard /
# Roll Dice / "Waiting for …"), acceptChallenge (Accept / Challenge! buttons),
# or reveal — "Scoreboard" alone is NOT always present.
ios_in_game() { # $1 udid → 0 if the game screen is up in any state
  local labs
  labs="$(ios_labels "$1")"
  printf '%s\n' "$labs" | grep -qxF "Scoreboard" && return 0
  printf '%s\n' "$labs" | grep -qxF "Accept" && return 0
  printf '%s\n' "$labs" | grep -qxF "Challenge!" && return 0
  printf '%s\n' "$labs" | grep -qxF "Roll Dice" && return 0
  printf '%s\n' "$labs" | grep -qF "Waiting for" && return 0
  printf '%s\n' "$labs" | grep -qF "Accept or Challenge" && return 0
  return 1
}

# ── Phase 3: kill iOS client mid-game → same-seat rejoin within grace ───────
log "Phase 3: killing IOS-2 mid-game, rejoining inside 15s grace"
KILL_AT=$SECONDS
xcrun simctl terminate "$IOS_CLIENT" "$PKG"
sleep 0.4
xcrun simctl launch "$IOS_CLIENT" "$PKG" >/dev/null

ok=1
# Each step: poll for the screen element, tap immediately when it appears.
ios_wait_label "$IOS_CLIENT" "Games" 8 || { log "  rejoin: no home screen"; ok=0; }
[ $ok = 1 ] && { ios_tap_scroll "$IOS_CLIENT" "Games" || ok=0; }
[ $ok = 1 ] && ios_wait_label "$IOS_CLIENT" "Multiplayer Mode" 3 || ok=0
[ $ok = 1 ] && { ios_tap "$IOS_CLIENT" "Multiplayer Mode" || ios_tap_scroll "$IOS_CLIENT" "Multiplayer Mode" || ok=0; }
[ $ok = 1 ] && ios_wait_label "$IOS_CLIENT" "Liar's Dice" 3 || ok=0
[ $ok = 1 ] && { ios_tap "$IOS_CLIENT" "Liar's Dice" || ios_tap_scroll "$IOS_CLIENT" "Liar's Dice" || ok=0; }
[ $ok = 1 ] && ios_wait_label "$IOS_CLIENT" "e.g. Frik" 3 || ok=0
[ $ok = 1 ] && { ios_tap "$IOS_CLIENT" "e.g. Frik" || ok=0; sleep 0.3; }
[ $ok = 1 ] && { idb ui text "IOS-2" --udid "$IOS_CLIENT" >>"$LOG" 2>&1 || ok=0; sleep 0.5; }
[ $ok = 1 ] && { ios_tap "$IOS_CLIENT" "Join a Game" || ok=0; }
JOIN_TAPPED_AT=$SECONDS
log "  join tapped at +$((JOIN_TAPPED_AT - KILL_AT))s (grace 15s)"
[ $ok = 1 ] && { tap_scan_entry "$IOS_CLIENT" || { sleep 1; tap_scan_entry "$IOS_CLIENT"; } || { sleep 1; tap_scan_entry "$IOS_CLIENT"; } || ok=0; }

REJOINED=0
if [ $ok = 1 ]; then
  for _ in $(seq 1 20); do
    if ios_in_game "$IOS_CLIENT"; then REJOINED=1; break; fi
    sleep 0.5
  done
fi
elapsed=$((SECONDS - KILL_AT))
log "  rejoin elapsed: ${elapsed}s (grace is 15s), in-game screen: $REJOINED"
if [ "$REJOINED" != "1" ]; then
  if ios_labels "$IOS_CLIENT" | grep -qF "Waiting for the host to start"; then
    log "  DIAG: client stuck on waitingForHost — host ignored the rejoin (grace likely expired)"
  fi
  log "FATAL: client did not land back in the game screen"
  xcrun simctl io "$IOS_CLIENT" screenshot "$EVIDENCE/03_rejoin_FAILED.png" >/dev/null
  exit 1
fi
if [ $elapsed -ge 15 ]; then
  log "WARN: rejoin completed but took ${elapsed}s — outside the nominal 15s grace"
fi
xcrun simctl io "$IOS_CLIENT" screenshot "$EVIDENCE/03_rejoined_client.png" >/dev/null
log "Phase 3 done — LT7 same-seat rejoin verified live"

# ── Phase 4: game continues with the rebound seat ───────────────────────────
log "Phase 4: driving ~75s more play with the rebound client"
end=$((SECONDS + 75))
while [ $SECONDS -lt $end ]; do
  poll_drive_once "ios:$IOS_HOST" "ios:$IOS_CLIENT" "and:$AND1" "and:$AND2"
  sleep 1
done

# Final assertions: rebound client still in-game; host still in-game; if the
# host is on a rollDice view, its scoreboard must list all 4 real players.
final_ok=1
ios_in_game "$IOS_CLIENT" || { log "FAIL: rebound client left the game screen"; final_ok=0; }
ios_in_game "$IOS_HOST" || { log "FAIL: host left the game screen"; final_ok=0; }
host_labels="$(ios_labels "$IOS_HOST")"
if printf '%s\n' "$host_labels" | grep -qxF "Scoreboard"; then
  for name in IOS-Host IOS-2 Android1 Android2; do
    printf '%s\n' "$host_labels" | grep -qF "$name" || { log "FAIL: host scoreboard missing $name"; final_ok=0; }
  done
else
  log "  (host not on a Scoreboard view — name check skipped, in-game confirmed)"
fi
xcrun simctl io "$IOS_HOST" screenshot "$EVIDENCE/04_final_host.png" >/dev/null
xcrun simctl io "$IOS_CLIENT" screenshot "$EVIDENCE/04_final_client.png" >/dev/null

if [ $final_ok != 1 ]; then
  log "FATAL: final assertions failed"
  exit 1
fi
log "TEST18 LIVE PASS: full round + mid-game same-seat rejoin + continued play"
exit 0
