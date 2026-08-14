import '../models/models.dart';

/// #298 — local min-qty reorder suggestions from inventory → shopping lines.
///
/// No schema change: default threshold is 1 (quantity &lt; 1 or ≤ [defaultMinQty]).
/// Optional note tags: `min:2` or `min=2` override per item.
class InventoryReorderLine {
  final InventoryItem item;
  final double minQty;
  final double shortfall;

  const InventoryReorderLine({
    required this.item,
    required this.minQty,
    required this.shortfall,
  });

  String get suggestedName => item.name;

  double get suggestedQty => shortfall > 0 ? shortfall : minQty;
}

class InventoryReorderService {
  InventoryReorderService._();

  /// Default: suggest reorder when quantity is at or below this.
  static const double defaultMinQty = 1;

  /// Parse `min:N` / `min=N` from notes; else [defaultMinQty].
  static double minQtyFor(InventoryItem item, {double fallback = defaultMinQty}) {
    final notes = item.notes?.toLowerCase() ?? '';
    final m = RegExp(r'\bmin\s*[:=]\s*(\d+(?:\.\d+)?)').firstMatch(notes);
    if (m != null) {
      return double.tryParse(m.group(1)!) ?? fallback;
    }
    return fallback;
  }

  /// Items at or below min qty (positive shortfall to restock to min).
  static List<InventoryReorderLine> lowStock(
    Iterable<InventoryItem> items, {
    double defaultMin = defaultMinQty,
  }) {
    final out = <InventoryReorderLine>[];
    for (final item in items) {
      final min = minQtyFor(item, fallback: defaultMin);
      if (item.quantity <= min) {
        final short = (min - item.quantity).clamp(0.0, double.infinity);
        // Always restock at least 1 unit when at/below min.
        out.add(InventoryReorderLine(
          item: item,
          minQty: min,
          shortfall: short <= 0 ? 1.0 : short,
        ));
      }
    }
    out.sort((a, b) => a.item.name.toLowerCase().compareTo(b.item.name.toLowerCase()));
    return out;
  }

  /// Distinct location labels for filter UI (non-empty, sorted).
  /// Case-insensitive dedupe; keeps first-seen casing.
  static List<String> locationTree(Iterable<InventoryItem> items) {
    final byKey = <String, String>{};
    for (final i in items) {
      final loc = i.location?.trim();
      if (loc == null || loc.isEmpty) continue;
      byKey.putIfAbsent(loc.toLowerCase(), () => loc);
    }
    final list = byKey.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  /// Filter by location (case-insensitive exact match on trimmed location).
  static List<InventoryItem> filterByLocation(
    Iterable<InventoryItem> items,
    String? location,
  ) {
    if (location == null || location.trim().isEmpty) {
      return items.toList();
    }
    final key = location.trim().toLowerCase();
    return items
        .where((i) => (i.location ?? '').trim().toLowerCase() == key)
        .toList();
  }

  /// #318 — the item already on hand with this exact barcode, if any (for
  /// the add-item scan flow's "you already have this, open it instead?"
  /// prompt). Null/empty barcodes never match — an empty scan result or an
  /// item with no barcode set shouldn't collide with anything.
  static InventoryItem? findByBarcode(
    Iterable<InventoryItem> items,
    String? barcode,
  ) {
    if (barcode == null || barcode.isEmpty) return null;
    for (final i in items) {
      if (i.barcode == barcode) return i;
    }
    return null;
  }

  /// #319 — inventory rows linked to this maintenance checklist item.
  /// Empty/null ids never match (an unlinked spare is not "used by" anything).
  static List<InventoryItem> linkedTo(
    Iterable<InventoryItem> items,
    String? checklistItemSupabaseId,
  ) {
    if (checklistItemSupabaseId == null || checklistItemSupabaseId.isEmpty) {
      return const [];
    }
    return items
        .where((i) => i.linkedMaintenanceItemSupabaseId == checklistItemSupabaseId)
        .toList();
  }

  /// "Engine Room — Replace impeller" (group prefix optional).
  static String maintenanceItemLabel(
    ChecklistItem item, {
    String Function(String groupSupabaseId)? groupTitleOf,
  }) {
    final title = item.title.isNotEmpty ? item.title : item.name;
    final group = groupTitleOf?.call(item.groupSupabaseId);
    if (group != null && group.isNotEmpty) return '$group — $title';
    return title;
  }

  /// Display label for the maintenance task an inventory item is used by.
  /// [groupTitleOf] prefixes the item title with its group when provided.
  /// Returns null when the item is unlinked.
  static String? usedByLabel(
    InventoryItem item,
    Iterable<ChecklistItem> maintenanceItems, {
    String Function(String groupSupabaseId)? groupTitleOf,
  }) {
    final id = item.linkedMaintenanceItemSupabaseId;
    if (id == null || id.isEmpty) return null;
    for (final c in maintenanceItems) {
      if (c.supabaseId != id) continue;
      return maintenanceItemLabel(c, groupTitleOf: groupTitleOf);
    }
    return 'Linked task missing';
  }

  /// "Spare impeller: 3 pcs on hand, min 1" — used on the maintenance
  /// item detail and the decrement prompt.
  static String spareOnHandLabel(InventoryItem item) {
    final qty = item.quantity == item.quantity.roundToDouble()
        ? item.quantity.toInt().toString()
        : item.quantity.toString();
    final unit = (item.unit != null && item.unit!.isNotEmpty) ? ' ${item.unit}' : '';
    final min = minQtyFor(item);
    final minStr = min == min.roundToDouble() ? min.toInt().toString() : min.toString();
    return '${item.name}: $qty$unit on hand, min $minStr';
  }
}
