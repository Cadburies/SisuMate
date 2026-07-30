/// Offline barcode lookup for common bar spirits.
/// Returns a partial match (name + category + optional ABV) when recognized;
/// returns null for unknown barcodes so the caller can fall back to manual entry.
class BarcodeService {
  BarcodeService._();

  static const _lookup = <String, _BarcodeLookup>{
    // ── Rums ──────────────────────────────────────────────────────────────────
    '080480010000': _BarcodeLookup('Bacardí Superior', 'spirit', 'White Blended Rum', 40.0),
    '082000720116': _BarcodeLookup('Captain Morgan Original', 'spirit', 'Spiced Rum', 35.0),
    '082000002803': _BarcodeLookup('Gosling\'s Black Seal', 'spirit', 'Dark Blended Rum', 40.0),
    '010072822225': _BarcodeLookup('Myers\'s Dark Rum', 'spirit', 'Dark Blended Rum', 40.0),
    '736040000024': _BarcodeLookup('Appleton Estate Signature', 'spirit', 'Aged Blended Rum', 43.0),
    '759150000103': _BarcodeLookup('El Dorado 12', 'spirit', 'Dark Demerara Rum', 40.0),
    '082000100213': _BarcodeLookup('Wray & Nephew White Overproof', 'spirit', 'Overproof Pot Still Rum', 63.0),
    '854644005019': _BarcodeLookup('Hamilton 151 Demerara', 'spirit', 'Overproof Demerara Rum', 75.5),
    '773821001041': _BarcodeLookup('Smith & Cross', 'spirit', 'Pot Still Jamaican Rum', 57.0),
    '082000740053': _BarcodeLookup('Plantation 3 Stars', 'spirit', 'White Blended Rum', 41.2),

    // ── Whiskey ────────────────────────────────────────────────────────────────
    '087000001011': _BarcodeLookup('Maker\'s Mark', 'spirit', 'Bourbon', 45.0),
    '080686970001': _BarcodeLookup('Buffalo Trace', 'spirit', 'Bourbon', 40.0),
    '082000000090': _BarcodeLookup('Jim Beam White', 'spirit', 'Bourbon', 40.0),
    '086036001005': _BarcodeLookup('Bulleit Rye', 'spirit', 'Rye Whiskey', 45.0),
    '082000070050': _BarcodeLookup('Jameson Irish Whiskey', 'spirit', 'Irish Whiskey', 40.0),
    '087000505015': _BarcodeLookup('Glenfiddich 12', 'spirit', 'Scotch Whisky', 40.0),

    // ── Gin & Vodka ────────────────────────────────────────────────────────────
    '082000001905': _BarcodeLookup('Tanqueray London Dry Gin', 'spirit', 'Gin', 47.3),
    '082000030038': _BarcodeLookup('Hendrick\'s Gin', 'spirit', 'Gin', 41.4),
    '082000100060': _BarcodeLookup('Bombay Sapphire', 'spirit', 'Gin', 47.0),
    '080080010750': _BarcodeLookup('Absolut Vodka', 'spirit', 'Vodka', 40.0),
    '084279120019': _BarcodeLookup('Grey Goose Vodka', 'spirit', 'Vodka', 40.0),

    // ── Tequila & Mezcal ───────────────────────────────────────────────────────
    '082000770030': _BarcodeLookup('Patrón Silver', 'spirit', 'Blanco Tequila', 40.0),
    '082000001509': _BarcodeLookup('Jose Cuervo Silver', 'spirit', 'Blanco Tequila', 40.0),
    '811538010003': _BarcodeLookup('Del Maguey Vida Mezcal', 'spirit', 'Mezcal', 42.0),

    // ── Liqueurs & Modifiers ───────────────────────────────────────────────────
    '082000001004': _BarcodeLookup('Cointreau', 'liqueur', 'Cointreau', 40.0),
    '082000100152': _BarcodeLookup('Grand Marnier', 'liqueur', 'Orange Curaçao', 40.0),
    '082000040013': _BarcodeLookup('Campari', 'liqueur', 'Campari', 24.0),
    '082000300014': _BarcodeLookup('Aperol', 'liqueur', 'Aperol', 11.0),
    '714032000057': _BarcodeLookup('Kahlúa', 'liqueur', 'Kahlúa', 20.0),
    '082000005407': _BarcodeLookup('Amaretto di Saronno', 'liqueur', 'Amaretto', 28.0),
    '082000110112': _BarcodeLookup('Luxardo Maraschino', 'liqueur', 'Maraschino Liqueur', 32.0),

    // ── Bitters ────────────────────────────────────────────────────────────────
    '036872010016': _BarcodeLookup('Angostura Aromatic Bitters', 'bitters', 'Angostura Bitters', 44.7),
    '082000200017': _BarcodeLookup('Peychaud\'s Bitters', 'bitters', 'Peychaud\'s Bitters', 35.0),
    '082000700033': _BarcodeLookup('Regan\'s Orange Bitters', 'bitters', 'Orange Bitters', 45.0),
  };

  /// Look up a barcode and return a match, or null if not recognized.
  static BarcodeMatch? lookup(String barcode) {
    final entry = _lookup[barcode.trim()];
    if (entry == null) return null;
    return BarcodeMatch(
      bottleName: entry.bottleName,
      suggestedIngredientName: entry.suggestedName,
      category: entry.category,
      abv: entry.abv,
    );
  }
}

class BarcodeMatch {
  final String bottleName;
  final String suggestedIngredientName;
  final String category;
  final double? abv;

  const BarcodeMatch({
    required this.bottleName,
    required this.suggestedIngredientName,
    required this.category,
    this.abv,
  });
}

class _BarcodeLookup {
  final String bottleName;
  final String category;
  final String suggestedName;
  final double? abv;

  const _BarcodeLookup(this.bottleName, this.category, this.suggestedName, [this.abv]);
}
