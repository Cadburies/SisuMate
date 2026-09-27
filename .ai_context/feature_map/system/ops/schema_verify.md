title: Live schema parity check
desc: Checks the live Supabase REST schema has every column and table the app syncs.
layer: ops
keywords: schema, supabase, migrations, verify, parity
kind: script
looks: -
reach: part of the full suite (skipped without credentials); scripts/verify_supabase_schema.sh --require to fail hard
needs: network=online
action: Probes each expected wire column; migrations are applied with the Supabase tools first.
expect: "verify_supabase_schema: ok".
uses: system/sync/remote_schema
script: -
source: scripts/verify_supabase_schema.sh
