# Cocktail image attribution

## Size
All images are resized to max **720×480** JPEG (quality ~72) — **3:2**. The
detail hero and grid cards must keep that aspect (`CocktailArt`); a short
full-bleed `BoxFit.cover` on iPad crops through the glass.

## Sources
- **Glassware defaults** (`_default*.jpg`): generated offline silhouettes (no third-party copyright).
- **Named photos** (when present): Wikimedia Commons, resized for bundling.
  See `manifest.json` for File titles, licenses, and artists for any Commons-sourced files.

Wikimedia bulk download is rate-limited; re-run a slow fetch later to add more named photos.
Named files currently may include: navy_grog, bloody_mary, espresso_martini, paloma, paper_plane, sidecar.

Licence summary for the whole repo (Apache 2.0 vs. these photos): see `NOTICE` at the repo root.
