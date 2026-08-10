-- #318 — Inventory: barcode field for quickly re-finding an item on restock.
alter table public.inventory_items
  add column if not exists "barcode" text;
