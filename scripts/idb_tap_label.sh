#!/usr/bin/env bash
# Taps the center of the first iOS accessibility element whose label contains
# the given substring. Avoids hand-computed pixel/point coordinates, which
# drift across screen sizes and layout changes (see liars_dice/live_test_setup.md).
set -euo pipefail
UDID="${1:?usage: idb_tap_label.sh <udid> <label-substring>}"
LABEL="${2:?usage: idb_tap_label.sh <udid> <label-substring>}"
VENV="$(dirname "$0")/../.idb_venv"
source "$VENV/bin/activate"

# Prefer exact label match, then substring. Integer coords only (idb rejects floats).
# Skip zero-size frames (Flutter ListView keeps off-screen a11y nodes at 0x0).
coords="$(idb ui describe-all --udid "$UDID" | python3 -c "
import json, sys
label_needle = sys.argv[1]
data = json.load(sys.stdin)
exact = None
sub = None
for el in data:
    label = el.get('AXLabel') or ''
    f = el.get('frame') or {}
    w = f.get('width') or 0
    h = f.get('height') or 0
    if w <= 0 or h <= 0:
        continue
    x = int(f['x'] + w / 2)
    y = int(f['y'] + h / 2)
    if label == label_needle and exact is None:
        exact = (x, y)
    elif label_needle in label and sub is None:
        sub = (x, y)
hit = exact or sub
if not hit:
    print('NOTFOUND', file=sys.stderr)
    sys.exit(1)
print(f'{hit[0]} {hit[1]}')
" "$LABEL")" || exit 1
read -r x y <<<"$coords"
idb ui tap "$x" "$y" --udid "$UDID"
