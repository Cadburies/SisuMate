-- #214: wine + cocktail pairing suggestions on meals. Grape/style-level
-- wine text and a cocktail name, both free text. No new RLS needed —
-- recipes' existing boat-membership policies already cover new columns
-- on the same row.
alter table public.recipes add column "winePairing" text;
alter table public.recipes add column "cocktailPairing" text;
