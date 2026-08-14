import '../models/models.dart';
import 'compliance_pack_service.dart';

/// #317 — offline shopping helper for a single list line (no network / no key).
///
/// Store-type hints, coarse local-name aliases, last place/price, and the
/// customs red-flag pack. Optional LLM enrichment lives in the UI dialog.
class ShoppingItemLocalGuide {
  ShoppingItemLocalGuide._();

  /// Human-readable offline report for [item].
  static String formatForItem(ShoppingItem item) {
    final buf = StringBuffer();
    buf.writeln('Offline shopping guide (no map / not live prices):');
    buf.writeln();

    // What / how many
    final qty = item.quantity < 1 ? 1 : item.quantity;
    final unit = (item.unit != null && item.unit!.trim().isNotEmpty)
        ? ' ${item.unit!.trim()}'
        : '';
    buf.writeln('• Item: ${item.name} ×$qty$unit');
    if (item.notes != null && item.notes!.trim().isNotEmpty) {
      buf.writeln('• Notes: ${item.notes!.trim()}');
    }
    if (item.lastPurchasePlace != null &&
        item.lastPurchasePlace!.trim().isNotEmpty) {
      buf.writeln('• Last bought at: ${item.lastPurchasePlace!.trim()}');
    }
    if (item.lastPurchasePrice != null) {
      buf.writeln(
        '• Last pack price on file: '
        '${item.lastPurchasePrice!.toStringAsFixed(2)} '
        '(×$qty ≈ ${(item.lineEstimate ?? item.lastPurchasePrice!).toStringAsFixed(2)})',
      );
    }

    buf.writeln();
    buf.writeln('Where to look (by list origin):');
    for (final line in storeHintsForOrigin(item.origin)) {
      buf.writeln('• $line');
    }

    final aliases = localNameHints(item.name);
    if (aliases.isNotEmpty) {
      buf.writeln();
      buf.writeln('Local name / brand hints (bundled, incomplete):');
      for (final a in aliases) {
        buf.writeln('• $a');
      }
    }

    buf.writeln();
    buf.writeln(
      CompliancePackService.formatHits(
        CompliancePackService.matchCustomsItem(item.name),
      ),
    );

    buf.writeln();
    buf.writeln(
      'Tip: this guide does not query live places. Use “Find nearest shop '
      '(online)” for a named store, expected price, and walking distance '
      'when online + an AI API key is set. “Improve with AI” can still '
      'suggest local product names and store types for a typed region.',
    );
    return buf.toString().trimRight();
  }

  /// Store-type suggestions from shopping [origin] (pantry/bar/spares/…).
  static List<String> storeHintsForOrigin(String origin) {
    switch (origin.toLowerCase().trim()) {
      case 'pantry':
      case 'galley':
      case 'food':
        return const [
          'Supermarket / hypermarket for staples',
          'Local market for produce (check customs/agri rules for fresh food)',
          'Bakery / butcher for specialty',
        ];
      case 'bar':
      case 'drinks':
      case 'beverage':
        return const [
          'Supermarket drinks aisle or liquor store',
          'Duty-free / bonded store when clearing in (keep receipts)',
          'Chandlery rarely stocks spirits — prefer town',
        ];
      case 'spares':
      case 'parts':
      case 'hardware':
        return const [
          'Chandlery / marine store for boat-specific parts',
          'Hardware / auto parts for fasteners, hose, electrics',
          'Electronics shop for batteries, USB, adapters',
        ];
      case 'safety':
        return const [
          'Chandlery for flares, PFDs, fire gear',
          'Confirm expiry dates before purchase',
        ];
      case 'medical':
      case 'pharmacy':
        return const [
          'Pharmacy / chemist for meds and first-aid restock',
          'Supermarket for basics (plasters, sunscreen)',
        ];
      default:
        return const [
          'Supermarket for consumables',
          'Chandlery / hardware for boat gear',
          'Ask locals for the nearest hypermarket vs chandlery split',
        ];
    }
  }

  /// Coarse multi-language grocery aliases for common items (bundled table).
  static List<String> localNameHints(String itemName) {
    final n = itemName.toLowerCase();
    final out = <String>[];

    void addIf(bool cond, String line) {
      if (cond) out.add(line);
    }

    addIf(
      n.contains('sugar'),
      'Sugar: şeker (TR), azúcar (ES), sucre (FR), Zucker (DE), 糖 (ZH)',
    );
    addIf(
      n.contains('flour') || n.contains('mealie') || n.contains('maize meal'),
      'Flour / meal: un (TR), harina (ES), farine (FR), Mehl (DE)',
    );
    addIf(
      n.contains('milk') && !n.contains('coconut'),
      'Milk: süt (TR), leche (ES), lait (FR), Milch (DE)',
    );
    addIf(
      n.contains('butter'),
      'Butter: tereyağı (TR), mantequilla (ES), beurre (FR), Butter (DE)',
    );
    addIf(
      n.contains('egg'),
      'Eggs: yumurta (TR), huevos (ES), œufs (FR), Eier (DE)',
    );
    addIf(
      n.contains('rice'),
      'Rice: pirinç (TR), arroz (ES), riz (FR), Reis (DE)',
    );
    addIf(
      n.contains('pasta') || n.contains('noodle') || n.contains('spaghetti'),
      'Pasta: makarna (TR), pasta (ES/IT), pâtes (FR), Nudeln (DE)',
    );
    addIf(
      n.contains('oil') &&
          (n.contains('olive') ||
              n.contains('cooking') ||
              n.contains('veg') ||
              n == 'oil' ||
              n.endsWith(' oil')),
      'Cooking oil: yağ (TR), aceite (ES), huile (FR), Öl (DE)',
    );
    addIf(
      n.contains('water') &&
          (n.contains('bottle') || n.contains('drink') || n.contains('spark')),
      'Bottled water: su (TR), agua (ES), eau (FR), Wasser (DE)',
    );
    addIf(
      n.contains('beer'),
      'Beer: bira (TR), cerveza (ES), bière (FR), Bier (DE) — local brands vary',
    );
    addIf(
      n.contains('wine'),
      'Wine: şarap (TR), vino (ES), vin (FR), Wein (DE)',
    );
    addIf(
      n.contains('coffee'),
      'Coffee: kahve (TR), café (ES/FR), Kaffee (DE)',
    );
    addIf(
      n.contains('tea') && !n.contains('teak'),
      'Tea: çay (TR), té (ES), thé (FR), Tee (DE)',
    );
    addIf(
      n.contains('diesel') || n.contains('fuel') || n.contains('petrol') || n.contains('gasoline'),
      'Fuel: marina fuel dock / gas station — not supermarket; check local names for diesel',
    );
    addIf(
      n.contains('propane') || n.contains('lpg') || n.contains('gas bottle') || n.contains('camping gaz'),
      'LPG: gas exchange cages / camping-gas stockists — never ferry empties casually',
    );
    addIf(
      n.contains('bolt') ||
          n.contains('screw') ||
          n.contains('hose') ||
          n.contains('hose clamp') ||
          n.contains('anode'),
      'Fasteners/hose/anodes: hardware + chandlery; bring the old part for matching',
    );

    return out;
  }
}
