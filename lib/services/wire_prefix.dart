/// WIRE-PREFIX: makes bundled item ids globally unique per boat *on the wire*
/// without touching local ids. Bundled seed ids are deterministic and identical
/// on every install (`dailyEngineId_check_oil`), but sync deletes-by-`supabaseId`
/// and realtime dedups-by-`id`, so two Pro accounts touching the same item would
/// collide onto one Supabase row. On outbound we prefix each id-ref field with
/// the boat GUID (`<guid>::<id>`); on inbound we strip it. `boatSupabaseId` (the
/// boat id itself) and the `boats` table are left untouched.
class WirePrefix {
  static const _sep = '::';

  /// Per-table id-ref fields to prefix. Tables absent here (notably `boats`,
  /// whose own `supabaseId` IS the GUID) are passed through unchanged.
  static const _fields = <String, List<String>>{
    'checklist_groups': ['supabaseId'],
    'checklist_items': ['supabaseId', 'groupSupabaseId'],
    'shopping_categories': ['supabaseId'],
    'shopping_items': ['supabaseId', 'categorySupabaseId'],
    'captain_logs': ['supabaseId'],
    'maintenance_tasks': ['supabaseId'],
    'documents': ['supabaseId'],
    'crew_members': ['supabaseId'],
    'inventory_items': ['supabaseId'],
    'fuel_logs': ['supabaseId'],
    'recipes': ['supabaseId'],
    'recipe_ingredients': ['supabaseId', 'recipeSupabaseId'],
    'bar_ingredients': ['supabaseId'],
    'pantry_ingredients': ['supabaseId'],
  };

  /// Outbound: prefix id-ref fields with [guid]. No-op if the table isn't
  /// scoped, the guid is empty, or a value is already prefixed (idempotent).
  static Map<String, dynamic> encode(
      String table, Map<String, dynamic> record, String guid) {
    final fields = _fields[table];
    if (fields == null || guid.isEmpty) return record;
    final m = Map<String, dynamic>.of(record);
    for (final f in fields) {
      final v = m[f];
      if (v is String && v.isNotEmpty && !v.contains(_sep)) {
        m[f] = '$guid$_sep$v';
      }
    }
    return m;
  }

  /// Inbound: strip the `<guid>::` prefix from id-ref fields.
  static Map<String, dynamic> decode(String table, Map<String, dynamic> record) {
    final fields = _fields[table];
    if (fields == null) return record;
    final m = Map<String, dynamic>.of(record);
    for (final f in fields) {
      final v = m[f];
      if (v is String) {
        final i = v.indexOf(_sep);
        if (i >= 0) m[f] = v.substring(i + _sep.length);
      }
    }
    return m;
  }

  /// Encode a bare record id (for delete-by-`supabaseId`). No-op for unscoped
  /// tables (e.g. `boats`) or an empty/already-prefixed id.
  static String encodeRecordId(String table, String id, String guid) {
    if (!_fields.containsKey(table) || guid.isEmpty || id.contains(_sep)) {
      return id;
    }
    return '$guid$_sep$id';
  }
}
