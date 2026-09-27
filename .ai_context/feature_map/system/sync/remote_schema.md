title: Cloud schema and access rules
desc: The Supabase tables, columns and row-level security the app syncs with; migrations live in the repo and are applied with the Supabase tools, then verified.
layer: sync
keywords: supabase, schema, rls, row level security, migrations, cloud
kind: service
looks: -
reach: every sync call; checked live by the full suite when credentials are present
needs: network=online
action: RLS keeps each boat's rows visible only to its owner and crew.
expect: The live RLS smoke and schema parity checks pass.
uses: -
script: test/live_supabase_rls_test.dart
source: lib/services/supabase_remote.dart (LiveSupabaseRemote); scripts/verify_supabase_schema.sh
