-- #321 — moderation: let any authenticated user flag a community template
-- for human review. Insert-only from the client; no read/update/delete
-- policy needed yet (a human reviews via the Supabase dashboard/SQL for
-- now — no in-app moderation queue at this stage).
create table if not exists public.community_template_reports (
  id bigint generated always as identity primary key,
  template_id uuid references public.community_templates(id),
  reporter_id text not null,
  reason text not null,
  note text,
  created_at timestamptz not null default now()
);

alter table public.community_template_reports enable row level security;

drop policy if exists "Authenticated users can report templates"
  on public.community_template_reports;
create policy "Authenticated users can report templates"
  on public.community_template_reports
  for insert
  to authenticated
  with check (true);
