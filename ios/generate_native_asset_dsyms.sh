#!/bin/sh
# Dart native-asset frameworks (objective_c.framework, …) are copied into the
# app without a dSYM. App Store Connect then fails upload with:
#   The archive did not include a dSYM for the objective_c.framework
# Run after Flutter's embed_and_thin so the binaries are already in place.
set -e
FWDIR="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
DSYMDIR="${DWARF_DSYM_FOLDER_PATH}"
[ -d "$FWDIR" ] || exit 0
[ -n "$DSYMDIR" ] || exit 0
mkdir -p "$DSYMDIR"
for fw in "$FWDIR"/*.framework; do
  [ -d "$fw" ] || continue
  name="$(basename "$fw" .framework)"
  bin="$fw/$name"
  [ -f "$bin" ] || continue
  dest="$DSYMDIR/${name}.framework.dSYM"
  [ -d "$dest" ] && continue
  dsymutil "$bin" -o "$dest"
done
