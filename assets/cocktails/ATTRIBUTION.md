# Cocktail image attribution

## Size
All images are resized to max **720×480** JPEG (quality ~72) to match the cocktail
detail hero (`width: full`, `height: 200` logical) while keeping the APK small.

## Sources
- **Glassware defaults** (`_default*.jpg`): generated offline silhouettes (no third-party copyright).
- **Named photos** (when present): Wikimedia Commons, resized for bundling.
  See `manifest.json` for File titles, licenses, and artists for any Commons-sourced files.

Wikimedia bulk download is rate-limited; re-run a slow fetch later to add more named photos.
Named files currently may include: navy_grog, bloody_mary, espresso_martini, paloma, paper_plane, sidecar.
