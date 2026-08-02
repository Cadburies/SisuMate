-- #203: bring-your-own-key LLM support. User-entered, per-boat, synced like
-- any other boat field. No new RLS needed — boats_select (all boat members)
-- and boats_update (owner only) already cover read/write scoping correctly.
alter table public.boats add column "llmApiKey" text;
alter table public.boats add column "llmApiKeyProvider" text;
