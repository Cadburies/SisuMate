-- #319 — Inventory: optional link from a spare to the maintenance
-- checklist item that consumes it.
alter table public.inventory_items
  add column if not exists "linkedMaintenanceItemSupabaseId" text;
