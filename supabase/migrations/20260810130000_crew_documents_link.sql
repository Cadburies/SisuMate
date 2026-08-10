-- #324/#325/#326 — Crew: port-entry fields + dietary/allergen tags (kept
-- directly on crew_members, which syncs, rather than linked to
-- guest_profiles, which is local-only). Documents: optional link to the
-- crew member a passport/visa/certification belongs to.
alter table public.crew_members
  add column if not exists "dateOfBirth" timestamptz,
  add column if not exists "nationality" text,
  add column if not exists "passportNumber" text,
  add column if not exists "allergenRestrictions" jsonb default '[]'::jsonb,
  add column if not exists "dietaryRequirements" jsonb default '[]'::jsonb;

alter table public.documents
  add column if not exists "crewMemberSupabaseId" text;
