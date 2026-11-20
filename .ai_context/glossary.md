# Sisu Mate — domain glossary

Nautical and product language only. Product gates, sync eligibility, field lists, and the module inventory live in `access_tiers.md`, `data_models.md`, and `INDEX.md`; this file explains only terms those files do not.

- **Boat** — a vessel record; content is scoped to a boat once it is synced or joined.
- **Active boat** — the boat the app is editing and syncing.
- **Crew** — people attached to a boat. Membership belongs to the boat, not the device.
- **Crew share code** — short code the owner gives a crew member to join the boat. It is redeemed before any local write, so a bad code never half-enrolls.
- **Enrollment** — the local link between this device and a boat.
- **Restamp** — after joining, re-tag existing local content to the joined boat.
- **Polar** — expected boat speed for a true wind angle and speed, optionally split by sea state.
- **Polar sample** — one under-sail instrument snapshot used to learn the boat's polar; anonymized on the wire.
- **Sea state** — calm, moderate, or rough, estimated from instrument variance or phone motion. Not a calibrated buoy scale.
- **Anchor watch** — local-only anchor-drag alarm: a geofence circle plus an optional danger-zone ring.
- **Seat** — one player slot in a LAN game, human or AI.
- **AI seat** — a bot occupying a seat with a skill level and style.
- **Captain's Log** — dated log entries with sea state, crew, and notes.
- **Community** — shared templates and recipes from other boats.
