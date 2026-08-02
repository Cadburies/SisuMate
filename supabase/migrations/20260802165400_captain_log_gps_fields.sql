-- #213: Captain's Log GPS button (SOG/COG from a single fix) + additional
-- useful fields. No new RLS needed — captain_logs' existing policies already
-- scope by boatSupabaseId membership; these are just new columns on the same
-- row.
alter table public.captain_logs add column "sogKt" double precision;
alter table public.captain_logs add column "cogDeg" double precision;
alter table public.captain_logs add column "barometricPressureHpa" double precision;
alter table public.captain_logs add column "seaState" text;
alter table public.captain_logs add column "watchCrew" jsonb;
alter table public.captain_logs add column "engineHours" double precision;
alter table public.captain_logs add column "fuelLevelPercent" double precision;
