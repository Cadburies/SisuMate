-- #211: replaces #203/#215's single llmApiKey/llmApiKeyProvider/
-- llmApiKeyShared scalar trio with one JSON-list column holding one entry
-- per provider ({provider, apiKey, shared}) — a boat can now store an
-- OpenAI, xAI, Anthropic, and Moonshot key at once and switch which is
-- active, instead of the last one entered overwriting whichever was there.
-- No install base (dev/sim only, per CLAUDE.md) — drop and replace rather
-- than write a data-preserving column migration. activeLlmProvider is a
-- per-device preference and deliberately never leaves the device, so it
-- has no column here at all.
alter table public.boats drop column if exists "llmApiKey";
alter table public.boats drop column if exists "llmApiKeyProvider";
alter table public.boats drop column if exists "llmApiKeyShared";
alter table public.boats add column "llmApiKeys" jsonb not null default '[]'::jsonb;
