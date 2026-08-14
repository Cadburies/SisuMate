-- #327 — split catalog purchase SKU from on-hand stock (pantry + bar).
-- Guest preferred drinks are local-only (guest_profiles is not synced).

alter table public.pantry_ingredients
  add column if not exists "purchaseSizeBase" double precision;
alter table public.pantry_ingredients
  add column if not exists "purchaseBaseUnit" text;
alter table public.pantry_ingredients
  add column if not exists "purchaseNoun" text;
alter table public.pantry_ingredients
  add column if not exists "unitsPerPurchase" integer default 1;
alter table public.pantry_ingredients
  add column if not exists "innerSizeBase" double precision;

alter table public.bar_ingredients
  add column if not exists "purchaseSizeBase" double precision;
alter table public.bar_ingredients
  add column if not exists "purchaseBaseUnit" text;
alter table public.bar_ingredients
  add column if not exists "purchaseNoun" text;
alter table public.bar_ingredients
  add column if not exists "unitsPerPurchase" integer default 1;
alter table public.bar_ingredients
  add column if not exists "innerSizeBase" double precision;
alter table public.bar_ingredients
  add column if not exists "onHandBase" double precision;
alter table public.bar_ingredients
  add column if not exists "onHandUnit" text;
