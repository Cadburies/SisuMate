-- #258/#259: Boat.toJson() already pushes a `polar` array (manually-entered
-- polar table for weather routing / ETA). Local Drift has polar_json, but
-- public.boats never got the matching column — every boats upsert fails with
-- PGRST204 "Could not find the 'polar' column of 'boats' in the schema cache".
-- JSON list of {twaDeg, twsKt, boatSpeedKt} objects; empty list = no polar.
alter table public.boats
  add column if not exists "polar" jsonb not null default '[]'::jsonb;
