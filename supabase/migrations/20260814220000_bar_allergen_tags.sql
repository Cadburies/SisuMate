-- #333 — bar catalog allergen tags (JSON list, same vocab as pantry).
alter table public.bar_ingredients
  add column if not exists "allergenTags" jsonb default '[]'::jsonb;
