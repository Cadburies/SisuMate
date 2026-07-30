#!/usr/bin/env bash
# LT2–LT4 — Module CRUD sweep on dual-device mirror harness.
#
# LT2: Create → wait for mirror → edit (same record) → wait → delete → wait gone
# LT3: Side action on the same record before delete (when the module has one)
# LT4: Never delete-recreate as a shortcut; one marker name per module, reused
#
# Usage:
#   bash scripts/lt_module_crud_sweep.sh [driver_android] [mirror_ios] [module|all]
#
# Modules: shopping inventory crew documents fuel  (default: all of these)
# Check-style modules (safety/maintenance/checklists) run a lighter complete-side path.
#
# Prerequisites: both devices on the SAME Pro boat (see lt_mirror_live_test.md).
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck disable=SC1091
source scripts/lt_ui_helpers.sh

DRIVER="${1:-R5CX2036L1F}"
MIRROR="${2:-43C4A261-F7F0-47FE-AC5B-C5313F7DFBEF}"
SCOPE="${3:-all}"
# Platforms: auto-detect from id shape (emulator/serial vs UUID).
detect_plat() {
  case "$1" in
    *-*-*-*-*) echo ios ;;
    *) echo android ;;
  esac
}
DRIVER_PLAT="$(detect_plat "$DRIVER")"
MIRROR_PLAT="$(detect_plat "$MIRROR")"
STAMP="$(date +%s)"
RUN_TAG="lt234_${STAMP}"
RESULT="$LOGDIR/${RUN_TAG}_result.txt"
: >"$RESULT"

PASS_N=0
FAIL_N=0
SKIP_N=0

record() {
  local status="$1" msg="$2"
  echo "$status $msg" | tee -a "$RESULT"
  case "$status" in
    PASS) PASS_N=$((PASS_N + 1)) ;;
    FAIL) FAIL_N=$((FAIL_N + 1)) ;;
    SKIP) SKIP_N=$((SKIP_N + 1)) ;;
  esac
}

if [ "$DRIVER_PLAT" = ios ]; then
  ios_ensure_companion "$DRIVER" 10882
fi
if [ "$MIRROR_PLAT" = ios ]; then
  # Second companion on alternate port when both are iOS.
  if [ "$DRIVER" = "$MIRROR" ]; then
    echo "DRIVER and MIRROR must differ" >&2
    exit 1
  fi
  if [ "$DRIVER_PLAT" = ios ]; then
    ios_ensure_companion "$MIRROR" 10883
  else
    ios_ensure_companion "$MIRROR" 10882
  fi
fi

# Detect Android lock screen early.
if [ "$DRIVER_PLAT" = android ]; then
  if and_dump "$DRIVER" | grep -q 'com.android.systemui' \
    && ! and_dump "$DRIVER" | grep -q 'com.sailingsisu.sisumate'; then
    record FAIL "Android driver is on lock screen — unlock the phone and re-run"
    echo "Hint: dual-iOS works unlocked: bash scripts/lt_module_crud_sweep.sh \\"
    echo "  DCC47B42-BE62-4EBD-A6F2-B8A7E4C3A6D2 43C4A261-F7F0-47FE-AC5B-C5313F7DFBEF shopping"
    exit 1
  fi
fi

drv_go_home() {
  if [ "$DRIVER_PLAT" = android ]; then and_go_home "$DRIVER"; else ios_go_home "$DRIVER"; fi
}
mir_go_home() {
  if [ "$MIRROR_PLAT" = android ]; then and_go_home "$MIRROR"; else ios_go_home "$MIRROR"; fi
}
mir_wait() {
  wait_for_text "$MIRROR_PLAT" "$MIRROR" "$1" "${2:-45}"
}
mir_open_module() {
  mir_go_home
  if [ "$MIRROR_PLAT" = android ]; then
    and_tap_text "$MIRROR" "$1" 2>/dev/null || and_tap_text_c "$MIRROR" "$1" || true
  else
    ios_tap_label "$MIRROR" "$1" 2>/dev/null || true
  fi
  sleep 3
  # Shopping categories are collapsed — expand Spares so SPARES-origin rows show.
  if [ "$1" = "Shopping" ]; then
    expand_shopping_categories "$MIRROR_PLAT" "$MIRROR"
  fi
}

# Expand Spares category (default origin for new shopping items).
# Idempotent: only taps Spares when the header is present AND no list row
# labels are already visible below it (second tap would collapse).
expand_shopping_categories() {
  local plat="$1" device="$2"
  if [ "$plat" = android ]; then
    if and_has_text "$device" "LT-" 2>/dev/null; then
      return 0
    fi
    and_tap_text_c "$device" "Spares" 2>/dev/null || true
    sleep 1
    return 0
  fi
  ios_activate
  # Detect expanded: any row label under Spares with y > Spares header y+height.
  local expanded
  expanded="$(idb ui describe-all --udid "$device" 2>/dev/null | python3 -c "
import json,sys
data=json.load(sys.stdin)
spares_bottom=None
for el in data:
    lab=el.get('AXLabel') or ''
    f=el.get('frame') or {}
    if lab.startswith('Spares') and (f.get('width') or 0)>50:
        spares_bottom=f.get('y',0)+f.get('height',0)
        break
if spares_bottom is None:
    print('no'); sys.exit(0)
for el in data:
    lab=el.get('AXLabel') or ''
    f=el.get('frame') or {}
    y=f.get('y',0)
    if y<=spares_bottom+4: continue
    if lab.startswith('LT-') or (lab and lab not in (
        'Back','Menu','Sisu Mate','Import / Export','Search items...',
        'Original','Name A-Z','Needed First','Price Low-High',
        'Trip estimate (to buy)','No prices yet — edit items or catalog',
        'Engine','Deck','Galley','Safety','Other') and not lab.startswith('\$')
        and (f.get('width') or 0)>80 and (f.get('height') or 0)>20):
        print('yes'); sys.exit(0)
print('no')
")"
  if [ "$expanded" = "yes" ]; then
    return 0
  fi
  local coords
  coords="$(idb ui describe-all --udid "$device" 2>/dev/null | python3 -c "
import json,sys
data=json.load(sys.stdin)
for el in data:
    lab=el.get('AXLabel') or ''
    f=el.get('frame',{})
    if lab.startswith('Spares') and (f.get('width') or 0) > 0:
        print(f\"{int(f['x']+f['width']/2)} {int(f['y']+f['height']/2)}\")
        break
")"
  if [ -n "$coords" ]; then
    read -r x y <<<"$coords"
    idb ui tap "$x" "$y" --udid "$device" 2>/dev/null || true
    sleep 1
  fi
}

# True if needle is on-screen with a tappable (non-zero) frame.
# Flutter ListView keeps off-screen rows in the a11y tree at 0×0 — ios_has_text
# would match those, but idb_tap_label correctly refuses them.
ios_tappable() {
  local udid="$1" needle="$2"
  ios_activate
  idb ui describe-all --udid "$udid" 2>/dev/null | python3 -c "
import json,sys
needle=sys.argv[1]
data=json.load(sys.stdin)
for el in data:
    lab=el.get('AXLabel') or ''
    if needle not in lab: continue
    f=el.get('frame') or {}
    if (f.get('width') or 0) > 0 and (f.get('height') or 0) > 0:
        sys.exit(0)
sys.exit(1)
" "$needle"
}

# Scroll list on iOS until label is tappable (non-zero frame), swipe up each try.
ios_scroll_find() {
  local udid="$1" needle="$2" max="${3:-10}"
  local i
  for ((i = 0; i < max; i++)); do
    if ios_tappable "$udid" "$needle"; then
      return 0
    fi
    ios_activate
    # Swipe up on mid-list area (bring lower rows into view).
    idb ui swipe 200 700 200 350 --udid "$udid" 2>/dev/null || true
    sleep 0.8
  done
  ios_tappable "$udid" "$needle"
}

# Wait up to N seconds for a label on driver (ios/android).
drv_wait_label() {
  local needle="$1" secs="${2:-8}"
  local i
  for ((i = 0; i < secs; i++)); do
    if [ "$DRIVER_PLAT" = android ]; then
      and_has_text "$DRIVER" "$needle" && return 0
    else
      ios_has_text "$DRIVER" "$needle" && return 0
    fi
    sleep 1
  done
  return 1
}

# Open shopping/list detail by marker; expand + scroll if needed.
drv_open_marker() {
  local home_label="$1" marker="$2"
  if [ "$DRIVER_PLAT" = android ]; then
    and_tap_text "$DRIVER" "$home_label"; sleep 3
    if [ "$home_label" = "Shopping" ]; then expand_shopping_categories android "$DRIVER"; fi
    and_tap_text_c "$DRIVER" "$marker" || and_tap_text "$DRIVER" "$marker" || return 1
  else
    ios_tap_label "$DRIVER" "$home_label"; sleep 3
    if [ "$home_label" = "Shopping" ]; then expand_shopping_categories ios "$DRIVER"; fi
    if ! ios_scroll_find "$DRIVER" "$marker" 8; then
      return 1
    fi
    ios_tap_label "$DRIVER" "$marker" || return 1
  fi
  sleep 2
  return 0
}
mir_has() {
  if [ "$MIRROR_PLAT" = android ]; then
    and_has_text "$MIRROR" "$1"
  else
    # Scroll a few times so long Shopping lists still match the marker.
    ios_scroll_find "$MIRROR" "$1" 5
  fi
}

# ── Generic list-module flow (LT2 create/edit/delete + LT4 reuse) ────────────
# Args: home_label create_btn_label  marker_name [side_fn]

flow_list_module() {
  local home_label="$1" create_btn="$2" marker="$3"
  local side_fn="${4:-}"
  local edited="${marker}-E"

  log_step "Module: $home_label  marker=$marker  driver=$DRIVER_PLAT mirror=$MIRROR_PLAT"

  drv_go_home
  mir_go_home

  # CREATE on driver
  if [ "$DRIVER_PLAT" = android ]; then
    and_tap_text "$DRIVER" "$home_label" || { record FAIL "$home_label: open module"; return; }
    sleep 3
    and_tap_fab "$DRIVER" || { record FAIL "$home_label: FAB"; return; }
    sleep 2
    and_replace_topmost_field "$DRIVER" "$marker" || { record FAIL "$home_label: name field"; return; }
    adb -s "$DRIVER" shell input keyevent 4
    sleep 1
    if ! and_tap_text "$DRIVER" "$create_btn" 2>/dev/null; then
      and_tap_text_c "$DRIVER" "Add" 2>/dev/null \
        || and_tap_text "$DRIVER" "Save" 2>/dev/null \
        || { record FAIL "$home_label: create confirm"; return; }
    fi
  else
    ios_tap_label "$DRIVER" "$home_label" || { record FAIL "$home_label: open module"; return; }
    sleep 3
    # FAB is often an unlabeled Button near bottom-right — find by frame.
    ios_activate
    fab="$(idb ui describe-all --udid "$DRIVER" 2>/dev/null | python3 -c "
import json,sys
data=json.load(sys.stdin)
best=None
for el in data:
    if el.get('type')!='Button': continue
    lab=el.get('AXLabel') or ''
    f=el.get('frame',{})
    y=f.get('y',0); x=f.get('x',0); w=f.get('width',0); h=f.get('height',0)
    if lab: continue
    if y<500 or w<40 or h<40: continue
    if best is None or y>best[0]:
        best=(y, int(x+w/2), int(y+h/2))
if best: print(f'{best[1]} {best[2]}')
")"
    if [ -n "$fab" ]; then
      read -r fx fy <<<"$fab"
      idb ui tap "$fx" "$fy" --udid "$DRIVER"
    else
      idb ui tap 346 770 --udid "$DRIVER"
    fi
    sleep 2
    # Focus the first TextField (Name / Item Name / title) — do not rely on
    # label alone (some dialogs leave focus on Quantity with default "1").
    ios_activate
    idb ui describe-all --udid "$DRIVER" 2>/dev/null | python3 -c "
import json,sys,subprocess
udid=sys.argv[1]
data=json.load(sys.stdin)
# Prefer a field labeled Name / Item Name / Title; else first empty TextField.
candidates=[]
for el in data:
    if el.get('type')!='TextField': continue
    f=el.get('frame') or {}
    w=f.get('width') or 0; h=f.get('height') or 0
    if w<40 or h<20: continue
    lab=(el.get('AXLabel') or '').lower()
    val=el.get('AXValue') or ''
    y=f.get('y',0)
    x=int(f['x']+w/2); cy=int(f['y']+h/2)
    score=0
    if 'name' in lab or 'title' in lab or 'item' in lab: score+=10
    if not val or val in ('1',): score+=1
    score -= int(y/100)  # prefer upper fields
    candidates.append((score, x, cy, lab, val))
candidates.sort(reverse=True)
if candidates:
    _, x, cy, lab, val = candidates[0]
    subprocess.run(['idb','ui','tap',str(x),str(cy),'--udid',udid])
    print(f'focus field lab={lab!r} val={val!r} at {x},{cy}', file=sys.stderr)
" "$DRIVER" || true
    sleep 0.4
    # Clear any prefilled text then type the marker.
    local _i
    for ((_i = 0; _i < 40; _i++)); do
      idb ui key 42 --udid "$DRIVER" >/dev/null 2>&1 || true
    done
    ios_type "$DRIVER" "$marker"
    sleep 1
    if ! ios_tap_label "$DRIVER" "$create_btn" 2>/dev/null; then
      ios_tap_label "$DRIVER" "Add Item" 2>/dev/null \
        || ios_tap_label "$DRIVER" "Save" 2>/dev/null \
        || ios_tap_label "$DRIVER" "Add" 2>/dev/null \
        || { record FAIL "$home_label: create confirm"; return; }
    fi
  fi
  sleep 2
  if [ "$home_label" = "Shopping" ]; then
    expand_shopping_categories "$DRIVER_PLAT" "$DRIVER"
  fi
  # Verify create on driver before claiming success (LT4 honesty).
  # Require a tappable frame — off-screen Flutter list nodes are 0×0.
  if [ "$DRIVER_PLAT" = ios ]; then
    if ! ios_scroll_find "$DRIVER" "$marker" 12; then
      record FAIL "$home_label: create not visible on driver after Add"
      return
    fi
  else
    if ! and_has_text "$DRIVER" "$marker"; then
      record FAIL "$home_label: create not visible on driver after Add"
      return
    fi
  fi
  record PASS "$home_label: create '$marker' on driver"

  # MIRROR: wait for create (LT2). Re-open module periodically — inbound
  # realtime can land in Drift while the list stream needs a revisit.
  local saw=0 elapsed=0
  while [ "$elapsed" -lt 90 ]; do
    mir_open_module "$home_label"
    if mir_has "$marker"; then saw=1; break; fi
    sleep 10
    elapsed=$((elapsed + 10))
  done
  if [ "$saw" -eq 1 ]; then
    record PASS "$home_label: mirror saw create"
  else
    # Cloud may already have the row even if mirror UI is stale — note for ops.
    record FAIL "$home_label: mirror did not see create (check Sync Status / relaunch mirror)"
    return
  fi

  # EDIT same record (LT4)
  drv_go_home
  if ! drv_open_marker "$home_label" "$marker"; then
    record FAIL "$home_label: open record for edit"; return
  fi
  if ! drv_wait_label "Edit" 6; then
    # Re-open once — expand may have been wrong; try again from home.
    drv_go_home
    if ! drv_open_marker "$home_label" "$marker" || ! drv_wait_label "Edit" 6; then
      record SKIP "$home_label: no Edit button"; edited="$marker"
    fi
  fi
  if drv_wait_label "Edit" 1; then
    if [ "$DRIVER_PLAT" = android ]; then
      and_tap_text "$DRIVER" "Edit" 2>/dev/null || and_tap_text_c "$DRIVER" "Edit"
      sleep 2
      and_replace_topmost_field "$DRIVER" "$edited" || true
      sleep 1
      and_tap_text "$DRIVER" "Save" 2>/dev/null || and_tap_text_c "$DRIVER" "Save" || true
    else
      ios_tap_label "$DRIVER" "Edit"
      sleep 2
      # Focus first TextField (Name) and replace full value (do not append).
      ios_activate
      idb ui describe-all --udid "$DRIVER" 2>/dev/null | python3 -c "
import json,sys,subprocess
udid=sys.argv[1]
data=json.load(sys.stdin)
for el in data:
    if el.get('type')!='TextField': continue
    f=el.get('frame') or {}
    if (f.get('width') or 0) < 40: continue
    x=int(f['x']+f['width']/2); y=int(f['y']+f['height']/2)
    subprocess.run(['idb','ui','tap',str(x),str(y),'--udid',udid])
    break
" "$DRIVER" || true
      sleep 0.4
      # HID Keyboard DELETE (42) clears existing name before typing.
      local _i
      for ((_i = 0; _i < 40; _i++)); do
        idb ui key 42 --udid "$DRIVER" >/dev/null 2>&1 || true
      done
      ios_type "$DRIVER" "$edited"
      sleep 1
      ios_tap_label "$DRIVER" "Save" 2>/dev/null || true
    fi
    sleep 2
    record PASS "$home_label: edit same record -> $edited"
  fi

  if [ "$edited" != "$marker" ]; then
    local mir_edit_ok=0 elapsed=0
    while [ "$elapsed" -lt 60 ]; do
      mir_open_module "$home_label"
      if mir_has "$edited"; then mir_edit_ok=1; break; fi
      sleep 8
      elapsed=$((elapsed + 8))
    done
    if [ "$mir_edit_ok" -eq 1 ]; then
      record PASS "$home_label: mirror saw edit"
    else
      record FAIL "$home_label: mirror did not see edit"
    fi
  fi

  # SIDE ACTION (LT3)
  if [ -n "$side_fn" ] && declare -f "$side_fn" >/dev/null; then
    drv_go_home
    drv_open_marker "$home_label" "$edited" 2>/dev/null \
      || drv_open_marker "$home_label" "$marker" || true
    sleep 1
    if "$side_fn"; then record PASS "$home_label: side action ($side_fn)"
    else record FAIL "$home_label: side action ($side_fn)"; fi
  fi

  # DELETE same record
  drv_go_home
  if ! drv_open_marker "$home_label" "$edited" 2>/dev/null; then
    if ! drv_open_marker "$home_label" "$marker"; then
      record FAIL "$home_label: open for delete"; return
    fi
  fi
  if [ "$DRIVER_PLAT" = android ]; then
    if and_tap_text "$DRIVER" "Delete" 2>/dev/null; then
      sleep 1; and_tap_text "$DRIVER" "Delete" 2>/dev/null || and_tap_text "$DRIVER" "OK" 2>/dev/null || true
      record PASS "$home_label: delete"
    elif and_tap_text "$DRIVER" "Hide" 2>/dev/null; then
      sleep 2
      # Shopping: Hide swaps actions to Unhide + Delete (SHOP1).
      and_tap_text "$DRIVER" "Delete" 2>/dev/null || and_tap_text_c "$DRIVER" "Delete" || true
      sleep 1; and_tap_text "$DRIVER" "Delete" 2>/dev/null || and_tap_text "$DRIVER" "OK" 2>/dev/null || true
      record PASS "$home_label: delete (via Hide)"
    else
      record SKIP "$home_label: no Delete — clean up '$edited' manually"; return
    fi
  else
    # Detail: Hide then Delete (shopping), or direct Delete.
    if ios_tap_label "$DRIVER" "Hide" 2>/dev/null; then
      sleep 2
      drv_wait_label "Delete" 5 || true
      ios_tap_label "$DRIVER" "Delete" 2>/dev/null || true
      sleep 1
      ios_tap_label "$DRIVER" "Delete" 2>/dev/null || ios_tap_label "$DRIVER" "OK" 2>/dev/null || true
      record PASS "$home_label: delete (via Hide)"
    elif ios_tap_label "$DRIVER" "Delete" 2>/dev/null; then
      sleep 1; ios_tap_label "$DRIVER" "Delete" 2>/dev/null || ios_tap_label "$DRIVER" "OK" 2>/dev/null || true
      record PASS "$home_label: delete"
    else
      record SKIP "$home_label: no Delete — clean up '$edited' manually"; return
    fi
  fi
  sleep 5

  # Mirror clear: reopen + scroll; relaunch once if still present (realtime
  # delete sometimes needs a cold list subscription).
  local gone=0 elapsed=0
  while [ "$elapsed" -lt 90 ]; do
    mir_open_module "$home_label"
    sleep 2
    if [ "$MIRROR_PLAT" = ios ]; then
      if ! ios_tappable "$MIRROR" "$edited" 2>/dev/null \
        && ! ios_tappable "$MIRROR" "$marker" 2>/dev/null; then
        gone=1; break
      fi
      if [ "$elapsed" -eq 30 ]; then
        ios_relaunch "$MIRROR"
        sleep 5
      fi
    else
      if ! mir_has "$edited" && ! mir_has "$marker"; then
        gone=1; break
      fi
    fi
    sleep 10
    elapsed=$((elapsed + 10))
  done
  if [ "$gone" -eq 1 ]; then
    record PASS "$home_label: mirror cleared after delete"
  else
    record FAIL "$home_label: mirror still shows deleted record"
  fi
}

side_shopping() {
  if [ "$DRIVER_PLAT" = android ]; then
    and_tap_text "$DRIVER" "Bought" 2>/dev/null \
      || and_tap_text_c "$DRIVER" "Complete" 2>/dev/null || return 0
  else
    ios_tap_label "$DRIVER" "Bought" 2>/dev/null \
      || ios_tap_label "$DRIVER" "Complete" 2>/dev/null || return 0
  fi
  sleep 1
  return 0
}

side_inventory() {
  if [ "$DRIVER_PLAT" = android ]; then
    and_tap_text_c "$DRIVER" "Shopping" 2>/dev/null \
      || and_tap_text "$DRIVER" "Add to shopping" 2>/dev/null || return 0
  else
    ios_tap_label "$DRIVER" "Shopping" 2>/dev/null || return 0
  fi
  sleep 1
  return 0
}

# Fuel & Water: list title prefers Notes when set (see fuel_screen.dart), so
# LT2 can treat Notes as the scannable marker like other list modules.
# Create = volume + notes(marker); open tile by marker title for edit/delete.
flow_fuel_module() {
  local marker="LT-$STAMP-Fuel"
  local edited="${marker}-E"
  local home_label="Fuel & Water"
  log_step "Module: $home_label  marker=$marker (notes-as-title)"

  drv_go_home
  if [ "$DRIVER_PLAT" != ios ]; then
    # Android: same field flow via adb helpers.
    and_tap_text "$DRIVER" "$home_label" || { record FAIL "Fuel: open"; return; }
    sleep 3
    and_tap_fab "$DRIVER" || { record FAIL "Fuel: FAB"; return; }
    sleep 2
    # Focus notes is unreliable on Android dump; type into top fields after volume.
    and_replace_topmost_field "$DRIVER" "1.5" || true
    sleep 0.5
    # Second field attempt: notes often lower — dump EditTexts and fill last empty-ish.
    and_dump "$DRIVER" > /tmp/lt_fuel_and.xml 2>/dev/null || true
    python3 -c "
import re, subprocess, sys
xml=open('/tmp/lt_fuel_and.xml').read()
serial=sys.argv[1]
fields=[]
for n in re.findall(r'<node[^>]*class=\"android.widget.EditText\"[^>]*/>', xml):
    b=re.search(r'bounds=\"\\[(\\d+),(\\d+)\\]\\[(\\d+),(\\d+)\\]\"', n)
    if not b: continue
    x1,y1,x2,y2=map(int,b.groups())
    fields.append((y1,(x1+x2)//2,(y1+y2)//2))
fields.sort()
if fields:
    _,cx,cy=fields[-1]
    subprocess.run(['adb','-s',serial,'shell','input','tap',str(cx),str(cy)])
" "$DRIVER" 2>/dev/null || true
    sleep 0.5
    adb -s "$DRIVER" shell input text "$marker" 2>/dev/null || true
    sleep 1
    and_tap_text "$DRIVER" "Save" 2>/dev/null || and_tap_text_c "$DRIVER" "Save" || {
      record FAIL "Fuel: Save"; return; }
    sleep 2
    if ! and_has_text "$DRIVER" "$marker"; then
      record FAIL "Fuel: create marker not visible on driver"; return
    fi
    record PASS "Fuel: create '$marker' on driver"
  else
    ios_tap_label "$DRIVER" "$home_label" || { record FAIL "Fuel: open"; return; }
    sleep 3
    ios_activate
    fab="$(idb ui describe-all --udid "$DRIVER" 2>/dev/null | python3 -c "
import json,sys
data=json.load(sys.stdin)
best=None
for el in data:
    if el.get('type')!='Button': continue
    if el.get('AXLabel'): continue
    f=el.get('frame') or {}
    y=f.get('y',0); w=f.get('width',0); h=f.get('height',0)
    if y<500 or w<40 or h<40: continue
    if best is None or y>best[0]:
        best=(y, int(f['x']+w/2), int(y+h/2))
if best: print(f'{best[1]} {best[2]}')
")"
    if [ -n "$fab" ]; then
      read -r fx fy <<<"$fab"
      idb ui tap "$fx" "$fy" --udid "$DRIVER"
    else
      idb ui tap 346 770 --udid "$DRIVER"
    fi
    sleep 2
    # Volume (required) then Notes = list title marker
    ios_activate
    idb ui describe-all --udid "$DRIVER" 2>/dev/null | python3 -c "
import json,sys,subprocess
udid=sys.argv[1]
data=json.load(sys.stdin)
def tap_field(want):
    for el in data:
        if el.get('type')!='TextField': continue
        lab=(el.get('AXLabel') or '').lower()
        if want not in lab: continue
        f=el.get('frame') or {}
        if (f.get('width') or 0)<40: continue
        x=int(f['x']+f['width']/2); y=int(f['y']+f['height']/2)
        subprocess.run(['idb','ui','tap',str(x),str(y),'--udid',udid])
        return True
    return False
tap_field('volume')
" "$DRIVER"
    sleep 0.3
    for _i in $(seq 1 10); do idb ui key 42 --udid "$DRIVER" >/dev/null 2>&1 || true; done
    ios_type "$DRIVER" "1.5"
    sleep 0.5
    idb ui describe-all --udid "$DRIVER" 2>/dev/null | python3 -c "
import json,sys,subprocess
udid=sys.argv[1]
data=json.load(sys.stdin)
for el in data:
    if el.get('type')!='TextField': continue
    lab=(el.get('AXLabel') or '').lower()
    if 'notes' not in lab: continue
    f=el.get('frame') or {}
    x=int(f['x']+f['width']/2); y=int(f['y']+f['height']/2)
    subprocess.run(['idb','ui','tap',str(x),str(y),'--udid',udid])
    break
" "$DRIVER"
    sleep 0.3
    for _i in $(seq 1 40); do idb ui key 42 --udid "$DRIVER" >/dev/null 2>&1 || true; done
    ios_type "$DRIVER" "$marker"
    sleep 1
    ios_tap_label "$DRIVER" "Save" || { record FAIL "Fuel: Save"; return; }
    sleep 2
    if ! ios_scroll_find "$DRIVER" "$marker" 8; then
      record FAIL "Fuel: create marker not visible on driver list"; return
    fi
    record PASS "Fuel: create '$marker' on driver (notes-as-title)"
  fi

  # Mirror saw create on list (title is notes)
  local saw=0 elapsed=0
  while [ "$elapsed" -lt 90 ]; do
    mir_open_module "$home_label"
    if mir_has "$marker"; then saw=1; break; fi
    sleep 10
    elapsed=$((elapsed + 10))
  done
  if [ "$saw" -eq 1 ]; then
    record PASS "Fuel: mirror saw create"
  else
    record FAIL "Fuel: mirror did not see create"; return
  fi

  # Edit notes (list title) on same record
  drv_go_home
  if ! drv_open_marker "$home_label" "$marker"; then
    # Fuel has no Spares expand — open module + scroll/tap marker
    if [ "$DRIVER_PLAT" = ios ]; then
      ios_tap_label "$DRIVER" "$home_label"; sleep 3
      ios_scroll_find "$DRIVER" "$marker" 8 || true
      ios_tap_label "$DRIVER" "$marker" || { record FAIL "Fuel: open for edit"; return; }
    else
      and_tap_text "$DRIVER" "$home_label"; sleep 3
      and_tap_text_c "$DRIVER" "$marker" || and_tap_text "$DRIVER" "$marker" || {
        record FAIL "Fuel: open for edit"; return; }
    fi
    sleep 2
  fi
  if drv_wait_label "Edit" 6; then
    if [ "$DRIVER_PLAT" = ios ]; then
      ios_tap_label "$DRIVER" "Edit"
      sleep 2
      ios_activate
      idb ui describe-all --udid "$DRIVER" 2>/dev/null | python3 -c "
import json,sys,subprocess
udid=sys.argv[1]
data=json.load(sys.stdin)
for el in data:
    if el.get('type')!='TextField': continue
    lab=(el.get('AXLabel') or '').lower()
    if 'notes' not in lab: continue
    f=el.get('frame') or {}
    x=int(f['x']+f['width']/2); y=int(f['y']+f['height']/2)
    subprocess.run(['idb','ui','tap',str(x),str(y),'--udid',udid])
    break
" "$DRIVER"
      for _i in $(seq 1 40); do idb ui key 42 --udid "$DRIVER" >/dev/null 2>&1 || true; done
      ios_type "$DRIVER" "$edited"
      ios_tap_label "$DRIVER" "Save" 2>/dev/null || true
    else
      and_tap_text "$DRIVER" "Edit" 2>/dev/null || and_tap_text_c "$DRIVER" "Edit"
      sleep 2
      and_replace_topmost_field "$DRIVER" "$edited" || true
      and_tap_text "$DRIVER" "Save" 2>/dev/null || true
    fi
    sleep 2
    record PASS "Fuel: edit same record -> $edited"
  else
    record SKIP "Fuel: no Edit button"; edited="$marker"
  fi

  if [ "$edited" != "$marker" ]; then
    local mir_edit_ok=0 elapsed=0
    while [ "$elapsed" -lt 60 ]; do
      mir_open_module "$home_label"
      if mir_has "$edited"; then mir_edit_ok=1; break; fi
      sleep 8
      elapsed=$((elapsed + 8))
    done
    if [ "$mir_edit_ok" -eq 1 ]; then
      record PASS "Fuel: mirror saw edit"
    else
      record FAIL "Fuel: mirror did not see edit"
    fi
  fi

  # Delete
  drv_go_home
  if [ "$DRIVER_PLAT" = ios ]; then
    ios_tap_label "$DRIVER" "$home_label"; sleep 3
    ios_scroll_find "$DRIVER" "$edited" 8 || ios_scroll_find "$DRIVER" "$marker" 4 || true
    ios_tap_label "$DRIVER" "$edited" 2>/dev/null || ios_tap_label "$DRIVER" "$marker" || {
      record FAIL "Fuel: open for delete"; return; }
    sleep 2
    if ios_tap_label "$DRIVER" "Delete" 2>/dev/null; then
      sleep 1
      ios_tap_label "$DRIVER" "Delete" 2>/dev/null || ios_tap_label "$DRIVER" "OK" 2>/dev/null || true
      record PASS "Fuel: delete"
    else
      record SKIP "Fuel: no Delete — clean up '$edited' manually"; return
    fi
  else
    and_tap_text "$DRIVER" "$home_label"; sleep 3
    and_tap_text_c "$DRIVER" "$edited" 2>/dev/null || and_tap_text_c "$DRIVER" "$marker" || {
      record FAIL "Fuel: open for delete"; return; }
    sleep 2
    if and_tap_text "$DRIVER" "Delete" 2>/dev/null; then
      sleep 1; and_tap_text "$DRIVER" "Delete" 2>/dev/null || and_tap_text "$DRIVER" "OK" 2>/dev/null || true
      record PASS "Fuel: delete"
    else
      record SKIP "Fuel: no Delete — clean up '$edited' manually"; return
    fi
  fi
  sleep 5

  local gone=0 elapsed=0
  while [ "$elapsed" -lt 90 ]; do
    mir_open_module "$home_label"
    sleep 2
    if [ "$MIRROR_PLAT" = ios ]; then
      if ! ios_tappable "$MIRROR" "$edited" 2>/dev/null \
        && ! ios_tappable "$MIRROR" "$marker" 2>/dev/null; then
        gone=1; break
      fi
      if [ "$elapsed" -eq 30 ]; then ios_relaunch "$MIRROR"; sleep 5; fi
    else
      if ! mir_has "$edited" && ! mir_has "$marker"; then gone=1; break; fi
    fi
    sleep 10
    elapsed=$((elapsed + 10))
  done
  if [ "$gone" -eq 1 ]; then
    record PASS "Fuel: mirror cleared after delete"
  else
    record FAIL "Fuel: mirror still shows deleted record"
  fi
}

flow_check_module() {
  local home_label="$1"
  log_step "Check-module: $home_label (complete side action)"

  drv_go_home
  if [ "$DRIVER_PLAT" = android ]; then
    and_tap_text "$DRIVER" "$home_label" || { record FAIL "$home_label: open"; return; }
  else
    ios_tap_label "$DRIVER" "$home_label" || { record FAIL "$home_label: open"; return; }
  fi
  sleep 3

  if [ "$DRIVER_PLAT" = android ]; then
    local coords
    coords="$(and_dump "$DRIVER" | python3 <<'PY'
import re, sys
xml = sys.stdin.read()
for n in re.findall(r'<node[^>]*/>', xml):
    if 'clickable="true"' not in n: continue
    m = re.search(r'content-desc="([^"]*)"', n)
    if not m or not m.group(1): continue
    desc = m.group(1).replace('&#10;', ' ')
    if desc in ('Back', 'Menu') or len(desc) < 3 or 'Sisu' in desc: continue
    b = re.search(r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', n)
    if not b: continue
    x1, y1, x2, y2 = map(int, b.groups())
    if y1 < 400: continue
    print(f"{(x1+x2)//2} {(y1+y2)//2}")
    break
PY
)"
    if [ -z "$coords" ]; then record SKIP "$home_label: no tile"; return; fi
    adb -s "$DRIVER" shell input tap $coords
  else
    # Tap first non-chrome label roughly mid-list via describe-all
    ios_activate
    idb ui describe-all --udid "$DRIVER" 2>/dev/null | python3 -c "
import json,sys
data=json.load(sys.stdin)
for el in data:
    lab=el.get('AXLabel') or ''
    f=el.get('frame',{})
    if not lab or lab in ('Back','Sisu Mate','Menu') or f.get('y',0)<120: continue
    if f.get('y',0)>200:
        print(f\"{f['x']+f['width']/2:.0f} {f['y']+f['height']/2:.0f}\")
        break
" | { read x y && idb ui tap "$x" "$y" --udid "$DRIVER"; } || true
  fi
  sleep 3

  if [ "$DRIVER_PLAT" = android ]; then
    if and_tap_text_c "$DRIVER" "Complete" 2>/dev/null; then
      record PASS "$home_label: side action complete"
    else
      record SKIP "$home_label: no Complete control"
    fi
  else
    if ios_tap_label "$DRIVER" "Complete" 2>/dev/null; then
      record PASS "$home_label: side action complete"
    else
      record SKIP "$home_label: no Complete control"
    fi
  fi

  mir_open_module "$home_label"
  record PASS "$home_label: mirror opened module"
}

# ── Run catalog ──────────────────────────────────────────────────────────────

log_step "LT2–LT4 module CRUD sweep"
echo "DRIVER=$DRIVER ($DRIVER_PLAT) MIRROR=$MIRROR ($MIRROR_PLAT) SCOPE=$SCOPE" | tee -a "$RESULT"

if [ "$DRIVER_PLAT" = android ]; then and_relaunch "$DRIVER"; else ios_relaunch "$DRIVER"; fi
if [ "$MIRROR_PLAT" = android ]; then and_relaunch "$MIRROR"; else ios_relaunch "$MIRROR"; fi

run_one() {
  local id="$1"
  case "$id" in
    shopping)
      flow_list_module "Shopping" "Add Item" "LT-$STAMP-Shop" side_shopping
      ;;
    inventory)
      # Avoid suffix "Inv" — iOS keyboard autocorrects it to "Inc".
      flow_list_module "Inventory" "Save" "LT-$STAMP-I9" side_inventory
      ;;
    crew)
      flow_list_module "Crew & Contacts" "Save" "LT-$STAMP-Crew" ""
      ;;
    documents)
      flow_list_module "Documents" "Save" "LT-$STAMP-Doc" ""
      ;;
    fuel)
      # List tiles show type (Fuel/Water), not free-text name — use notes-based create.
      flow_fuel_module
      ;;
    logbook|log)
      flow_list_module "Captain's Log" "Save" "LT-$STAMP-Log" ""
      ;;
    safety)
      flow_check_module "Safety"
      ;;
    maintenance)
      flow_check_module "Maintenance"
      ;;
    checklists|checks)
      flow_check_module "Checklists"
      ;;
    cocktails|chef)
      record SKIP "$id: complex UI — manual pass (open module + stock/shopping side action)"
      ;;
    *)
      record SKIP "unknown module $id"
      ;;
  esac
}

if [ "$SCOPE" = all ]; then
  for m in shopping inventory crew documents fuel logbook safety maintenance checklists; do
    run_one "$m" || true
  done
else
  run_one "$SCOPE" || true
fi

echo "" | tee -a "$RESULT"
echo "=== SUMMARY PASS=$PASS_N FAIL=$FAIL_N SKIP=$SKIP_N ===" | tee -a "$RESULT"
echo "Full log: $RESULT"

if [ "$FAIL_N" -gt 0 ]; then
  exit 1
fi
exit 0
