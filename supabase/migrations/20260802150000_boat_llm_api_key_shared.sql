-- #215: bring-your-own-key LLM support becomes local-only by default.
-- llmApiKeyShared is the explicit owner opt-in that lets llmApiKey/
-- llmApiKeyProvider (added in #203) actually sync — the app now sends
-- those two columns as null whenever this is false, so no code change is
-- needed here beyond adding the new flag column itself. boats_update RLS
-- (owner-only write) already covers who can flip it.
alter table public.boats add column "llmApiKeyShared" boolean not null default false;
