-- #320 — Inventory: JSON log of quantity changes (timestamp + old/new).
alter table public.inventory_items
  add column if not exists "quantityHistory" jsonb default '[]'::jsonb;
