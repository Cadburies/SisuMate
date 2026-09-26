#!/usr/bin/env bash
# #394: regenerate the public GitHub wiki from .ai_context/feature_map/ (the single
# source) and push it to Cadburies/SisuMate.wiki.git. Run after any feature-map
# file is created or changed. Never hand-edit the wiki: this script replaces it.
#
#   scripts/publish_wiki.sh            # generate, sync, commit if changed, push
#   scripts/publish_wiki.sh --dry-run  # generate + show the diff, no push
set -euo pipefail
cd "$(dirname "$0")/.."
REPO_DIR="$(pwd)"
DRY=false
[ "${1:-}" = "--dry-run" ] && DRY=true
WIKI_URL="https://github.com/Cadburies/SisuMate.wiki.git"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

dart run tool/feature_map_wiki.dart "$WORK/pages"

if ! git clone -q "$WIKI_URL" "$WORK/wiki" 2>/dev/null; then
  if $DRY; then
    echo "wiki: repo not initialised yet; generated pages:"
    ls "$WORK/pages"
    exit 0
  fi
  echo "wiki: repo not initialised. Open https://github.com/Cadburies/SisuMate/wiki," >&2
  echo "      click 'Create the first page', save it, then rerun this script." >&2
  exit 2
fi

# Full replace so removed features disappear from the wiki too.
find "$WORK/wiki" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
cp -R "$WORK/pages/." "$WORK/wiki/"

SRC_SHA="$(git -C "$REPO_DIR" rev-parse --short HEAD)"
GIT_NAME="$(git -C "$REPO_DIR" config user.name)"
GIT_EMAIL="$(git -C "$REPO_DIR" config user.email)"
cd "$WORK/wiki"
git add -A
if git diff --cached --quiet; then
  echo "wiki: no changes"
  exit 0
fi
git diff --cached --stat
if $DRY; then
  echo "wiki: dry run, not pushed"
  exit 0
fi
git -c user.name="$GIT_NAME" -c user.email="$GIT_EMAIL" \
  commit -q -m "Regenerate from feature map @ $SRC_SHA"
git push -q origin HEAD
echo "wiki: published (feature map @ $SRC_SHA) → https://github.com/Cadburies/SisuMate/wiki"
