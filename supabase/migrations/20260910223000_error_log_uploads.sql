-- #341: tester/release-build crash logs uploaded from Settings.
-- RLS: a user can only insert/select their own rows. Agents pull via
-- service role / dashboard, not from the app.

create table if not exists public.error_log_uploads (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  payload jsonb not null
);

alter table public.error_log_uploads enable row level security;

drop policy if exists error_log_uploads_own on public.error_log_uploads;
create policy error_log_uploads_own
  on public.error_log_uploads
  for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

grant select, insert on public.error_log_uploads to authenticated;
