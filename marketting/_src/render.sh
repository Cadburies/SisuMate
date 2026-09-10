#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GROK="$ROOT/grok"
HTML="file://$GROK/_src/listing.html"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
SHOT() {
  local w="$1" h="$2" out="$3" url="$4"
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars \
    --force-device-scale-factor=1 \
    --window-size="${w},${h}" \
    --virtual-time-budget=12000 \
    --screenshot="$out" \
    "$url" >/dev/null 2>&1
  python3 - "$out" "$w" "$h" <<'PY'
import sys
from PIL import Image
path, w, h = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
im = Image.open(path).convert('RGB')
if im.size != (w, h):
    canvas = Image.new('RGB', (w, h), (13, 13, 13))
    src = im.resize((w, h), Image.Resampling.LANCZOS) if im.size[0] != w else im
    canvas.paste(src.crop((0, 0, w, min(h, src.size[1]))))
    canvas.save(path, 'PNG')
else:
    im.save(path, 'PNG')
print('wrote', path, Image.open(path).size)
PY
}

SHOT 1024 500 "$GROK/feature-graphic.png" "${HTML}?k=feature"

SCREENS="home checklists shopping weather chef games cocktails anchor"
i=1
for s in $SCREENS; do
  n=$(printf '%02d' "$i")
  SHOT 1080 1920 "$GROK/screenshots/${n}-${s}.png" "${HTML}?k=shot&s=${s}"
  SHOT 1320 2868 "$GROK/screenshots-iphone-69/${n}-${s}.png" "${HTML}?k=ios&s=${s}"
  i=$((i+1))
done
