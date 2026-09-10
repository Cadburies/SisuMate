-- Self-service account deletion (issue #338). Lets a signed-in user
-- permanently delete their own Supabase account + owned boat data via
-- Settings > Delete My Account. Scoped to auth.uid() only — no params, so
-- it can never target another user. Distinct from the admin-only
-- admin_purge_boat (which purges abandoned boat content but never touches
-- auth.users) — this is the user-initiated, self-scoped equivalent.

create or replace function public.delete_own_account()
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  uid uuid := auth.uid();
  t text;
  n bigint;
  boats_deleted bigint := 0;
  content_rows_deleted bigint := 0;
  owned_boat record;
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;

  -- Purge every boat this user owns (same content sweep as admin_purge_boat)
  -- so crew on those boats don't keep syncing against an orphaned owner.
  for owned_boat in select "supabaseId" from public.boats where "ownerId" = uid loop
    foreach t in array array[
      'checklist_groups','checklist_items','shopping_categories','shopping_items',
      'captain_logs','maintenance_tasks','documents','crew_members',
      'inventory_items','fuel_logs','recipes','recipe_ingredients',
      'bar_ingredients','pantry_ingredients'
    ] loop
      execute format('delete from public.%I where "supabaseId" like $1', t)
        using owned_boat."supabaseId" || '::%';
      get diagnostics n = row_count;
      content_rows_deleted := content_rows_deleted + n;
    end loop;
    delete from public.boat_members where "boatSupabaseId" = owned_boat."supabaseId";
    delete from public.boats where "supabaseId" = owned_boat."supabaseId";
    boats_deleted := boats_deleted + 1;
  end loop;

  -- Drop this user's crew membership on boats owned by someone else — the
  -- boat and its data are untouched for the owner and other crew.
  delete from public.boat_members where "memberId" = uid;

  -- Drop rows that FK-reference auth.users before the account itself.
  delete from public.app_admins where "id" = uid;
  delete from public.profiles where "id" = uid;

  delete from auth.users where id = uid;

  return jsonb_build_object(
    'boatsDeleted', boats_deleted,
    'contentRowsDeleted', content_rows_deleted
  );
end;
$function$;

revoke all on function public.delete_own_account() from public;
grant execute on function public.delete_own_account() to authenticated;
