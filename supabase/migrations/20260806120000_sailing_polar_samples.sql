-- #275: anonymized under-sail polar samples (performance metrics only).
-- No lat/lon track; crew can share measured TWA×TWS×boatSpeed for polar healing.
create table if not exists public.sailing_polar_samples (
  "supabaseId" text primary key,
  "boatSupabaseId" text not null references public.boats("supabaseId") on delete cascade,
  "observedAt" timestamptz not null default now(),
  "boatSpeedKt" double precision not null default 0,
  "speedSource" text not null default 'sog',
  "sogKt" double precision,
  "stwKt" double precision,
  "twaDeg" double precision not null default 0,
  "twsKt" double precision not null default 0,
  "isSynced" boolean default true,
  "lastModified" timestamptz default now()
);

create index if not exists sailing_polar_samples_boat_observed
  on public.sailing_polar_samples ("boatSupabaseId", "observedAt" desc);

alter table public.sailing_polar_samples enable row level security;

-- Wire ids are boat-prefixed (`guid::uuid`); match other boat-scoped tables.
create policy sisu_boat_scoped on public.sailing_polar_samples
  for all to authenticated
  using (split_part("supabaseId", '::', 1) in (select accessible_boat_ids()))
  with check (split_part("supabaseId", '::', 1) in (select accessible_boat_ids()));

alter publication supabase_realtime add table public.sailing_polar_samples;
