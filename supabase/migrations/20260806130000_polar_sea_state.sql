-- #276: sea-state on anonymized polar samples + multi-polar map on boats.
alter table public.sailing_polar_samples
  add column if not exists "seaState" text not null default 'unknown';

alter table public.boats
  add column if not exists "polarBySeaState" jsonb not null default '{}'::jsonb;
