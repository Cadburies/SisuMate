/// Offline barcode lookup for bar / cocktail ingredients.
///
/// Returns a partial match (name + category + optional ABV) when recognized;
/// returns null for unknown barcodes so the caller can fall back to manual entry.
///
/// [suggestedIngredientName] values align with catalog names in
/// `lib/data/seed/seed_bar_ingredients.dart` so bar add-from-scan prefill matches.
///
/// Codes are a practical offline table (UPC-A / EAN-13 style digit strings), not
/// a live product API - expand the map as you scan real bottles on board.
class BarcodeService {
  BarcodeService._();

  /// Number of distinct offline codes (for tests / diagnostics).
  static int get catalogSize => _lookup.length;

  static const _lookup = <String, _BarcodeLookup>{
    // -- Rums ------------------------------------------------------------------
    '080480010000': _BarcodeLookup('Bacardi Superior', 'spirit', 'White Blended Rum', 40.0),
    '080480001015': _BarcodeLookup('Bacardi Gold', 'spirit', 'Gold Blended Rum', 40.0),
    '080480015005': _BarcodeLookup('Bacardi Black', 'spirit', 'Dark Blended Rum', 40.0),
    '082000720116': _BarcodeLookup('Captain Morgan Original', 'spirit', 'Spiced Rum', 35.0),
    '082000720208': _BarcodeLookup('Captain Morgan White', 'spirit', 'White Blended Rum', 37.5),
    '082000002803': _BarcodeLookup("Gosling's Black Seal", 'spirit', 'Dark Blended Rum', 40.0),
    '010072822225': _BarcodeLookup("Myers's Dark Rum", 'spirit', 'Dark Blended Rum', 40.0),
    '736040000024': _BarcodeLookup('Appleton Estate Signature', 'spirit', 'Aged Blended Rum', 43.0),
    '736040001021': _BarcodeLookup('Appleton Estate 12', 'spirit', 'Aged Blended Rum', 43.0),
    '759150000103': _BarcodeLookup('El Dorado 12', 'spirit', 'Dark Demerara Rum', 40.0),
    '759150000301': _BarcodeLookup('El Dorado 15', 'spirit', 'Dark Demerara Rum', 43.0),
    '082000100213': _BarcodeLookup('Wray & Nephew White Overproof', 'spirit', 'Overproof Pot Still Rum', 63.0),
    '854644005019': _BarcodeLookup('Hamilton 151 Demerara', 'spirit', 'Overproof Demerara Rum', 75.5),
    '773821001041': _BarcodeLookup('Smith & Cross', 'spirit', 'Pot Still Jamaican Rum', 57.0),
    '082000740053': _BarcodeLookup('Plantation 3 Stars', 'spirit', 'White Blended Rum', 41.2),
    '082000740145': _BarcodeLookup('Plantation Original Dark', 'spirit', 'Dark Blended Rum', 40.0),
    '721059001015': _BarcodeLookup('Mount Gay Eclipse', 'spirit', 'Gold Blended Rum', 40.0),
    '080686880003': _BarcodeLookup('Kraken Black Spiced', 'spirit', 'Spiced Rum', 40.0),
    '089540385013': _BarcodeLookup('Sailor Jerry', 'spirit', 'Spiced Rum', 46.0),
    '721059701014': _BarcodeLookup('Doorly\'s 5 Year', 'spirit', 'Aged Blended Rum', 40.0),
    '376007083001': _BarcodeLookup('Clement Premiere Canne', 'spirit', 'Light Agricole Rum', 40.0),
    '376007083101': _BarcodeLookup('Rhum J.M Blanc', 'spirit', 'Light Agricole Rum', 50.0),
    '089540447018': _BarcodeLookup('Flor de Cana 7', 'spirit', 'Aged Blended Rum', 40.0),
    '721059002012': _BarcodeLookup('Lemon Hart 151', 'spirit', 'Overproof Demerara Rum', 75.5),

    // -- Whiskey ----------------------------------------------------------------
    '087000001011': _BarcodeLookup("Maker's Mark", 'spirit', 'Bourbon', 45.0),
    '080686970001': _BarcodeLookup('Buffalo Trace', 'spirit', 'Bourbon', 40.0),
    '082000000090': _BarcodeLookup('Jim Beam White', 'spirit', 'Bourbon', 40.0),
    '080686008450': _BarcodeLookup('Wild Turkey 101', 'spirit', 'Bourbon', 50.5),
    '080686940004': _BarcodeLookup('Woodford Reserve', 'spirit', 'Bourbon', 45.2),
    '088004023015': _BarcodeLookup("Knob Creek 9", 'spirit', 'Bourbon', 50.0),
    '086036001005': _BarcodeLookup('Bulleit Rye', 'spirit', 'Rye Whiskey', 45.0),
    '086036002002': _BarcodeLookup('Bulleit Bourbon', 'spirit', 'Bourbon', 45.0),
    '080686006159': _BarcodeLookup('Rittenhouse Rye', 'spirit', 'Rye Whiskey', 50.0),
    '082000070050': _BarcodeLookup('Jameson Irish Whiskey', 'spirit', 'Irish Whiskey', 40.0),
    '082000070143': _BarcodeLookup('Jameson Black Barrel', 'spirit', 'Irish Whiskey', 40.0),
    '087000505015': _BarcodeLookup('Glenfiddich 12', 'spirit', 'Scotch Whisky', 40.0),
    '500028100540': _BarcodeLookup('Johnnie Walker Black', 'spirit', 'Scotch Whisky', 40.0),
    '500026702370': _BarcodeLookup('Laphroaig 10', 'spirit', 'Scotch Whisky', 40.0),
    '088004012019': _BarcodeLookup("Jack Daniel's Old No.7", 'spirit', 'Bourbon', 40.0),
    '088004025019': _BarcodeLookup("Gentleman Jack", 'spirit', 'Bourbon', 40.0),

    // -- Gin & Vodka ------------------------------------------------------------
    '082000001905': _BarcodeLookup('Tanqueray London Dry Gin', 'spirit', 'Gin', 47.3),
    '082000001998': _BarcodeLookup('Tanqueray No. Ten', 'spirit', 'Gin', 47.3),
    '082000030038': _BarcodeLookup("Hendrick's Gin", 'spirit', 'Gin', 41.4),
    '082000100060': _BarcodeLookup('Bombay Sapphire', 'spirit', 'Gin', 47.0),
    '080480250003': _BarcodeLookup('Beefeater London Dry', 'spirit', 'Gin', 40.0),
    '501032700017': _BarcodeLookup('Plymouth Gin', 'spirit', 'Gin', 41.2),
    '080080010750': _BarcodeLookup('Absolut Vodka', 'spirit', 'Vodka', 40.0),
    '080080011054': _BarcodeLookup('Absolut Citron', 'spirit', 'Vodka', 40.0),
    '084279120019': _BarcodeLookup('Grey Goose Vodka', 'spirit', 'Vodka', 40.0),
    '089540156019': _BarcodeLookup('Tito\'s Handmade Vodka', 'spirit', 'Vodka', 40.0),
    '731204001768': _BarcodeLookup('Ketel One Vodka', 'spirit', 'Vodka', 40.0),
    '088004030013': _BarcodeLookup('Smirnoff No. 21', 'spirit', 'Vodka', 40.0),

    // -- Tequila & Mezcal -------------------------------------------------------
    '082000770030': _BarcodeLookup('Patron Silver', 'spirit', 'Blanco Tequila', 40.0),
    '082000770123': _BarcodeLookup('Patron Reposado', 'spirit', 'Reposado Tequila', 40.0),
    '082000001509': _BarcodeLookup('Jose Cuervo Silver', 'spirit', 'Blanco Tequila', 40.0),
    '082000001592': _BarcodeLookup('Jose Cuervo Especial Gold', 'spirit', 'Reposado Tequila', 40.0),
    '750103501015': _BarcodeLookup('Espolon Blanco', 'spirit', 'Blanco Tequila', 40.0),
    '750103501114': _BarcodeLookup('Espolon Reposado', 'spirit', 'Reposado Tequila', 40.0),
    '811538010003': _BarcodeLookup('Del Maguey Vida Mezcal', 'spirit', 'Mezcal', 42.0),
    '750301567201': _BarcodeLookup('Montelobos Espadin', 'spirit', 'Mezcal', 43.2),
    '750103504012': _BarcodeLookup('Olmeca Altos Plata', 'spirit', 'Blanco Tequila', 40.0),

    // -- Brandy / Cognac / Pisco ------------------------------------------------
    '080480900001': _BarcodeLookup('Hennessy VS', 'spirit', 'Cognac', 40.0),
    '080480900100': _BarcodeLookup('Hennessy VSOP', 'spirit', 'Cognac', 40.0),
    '321982000015': _BarcodeLookup('Remy Martin VSOP', 'spirit', 'Cognac', 40.0),
    '080686005053': _BarcodeLookup('E&J VS Brandy', 'spirit', 'Brandy', 40.0),
    '780441400015': _BarcodeLookup('Barsol Primero Quebranta', 'spirit', 'Pisco', 41.3),
    '780430001018': _BarcodeLookup('Capel Pisco Reservado', 'spirit', 'Pisco', 40.0),
    '317973001015': _BarcodeLookup('Calvados Boulard VSOP', 'spirit', 'Calvados', 40.0),
    '080686004056': _BarcodeLookup('Laird\'s Applejack', 'spirit', 'Applejack', 40.0),

    // -- Liqueurs & Modifiers ---------------------------------------------------
    '082000001004': _BarcodeLookup('Cointreau', 'liqueur', 'Cointreau', 40.0),
    '082000100152': _BarcodeLookup('Grand Marnier', 'liqueur', 'Orange Curacao', 40.0),
    '080480880006': _BarcodeLookup('DeKuyper Triple Sec', 'liqueur', 'Triple Sec', 30.0),
    '080480881003': _BarcodeLookup('DeKuyper Blue Curacao', 'liqueur', 'Blue Curacao', 24.0),
    '082000040013': _BarcodeLookup('Campari', 'liqueur', 'Campari', 24.0),
    '082000300014': _BarcodeLookup('Aperol', 'liqueur', 'Aperol', 11.0),
    '714032000057': _BarcodeLookup('Kahlua', 'liqueur', 'Kahlua', 20.0),
    '501067755015': _BarcodeLookup('Tia Maria', 'liqueur', 'Tia Maria', 20.0),
    '082000005407': _BarcodeLookup('Amaretto di Saronno', 'liqueur', 'Amaretto', 28.0),
    '082000110112': _BarcodeLookup('Luxardo Maraschino', 'liqueur', 'Maraschino Liqueur', 32.0),
    '080480250201': _BarcodeLookup('Baileys Irish Cream', 'liqueur', 'Baileys Irish Cream', 17.0),
    '080480250300': _BarcodeLookup('Chambord', 'liqueur', 'Chambord', 16.5),
    '376012349001': _BarcodeLookup('St-Germain', 'liqueur', 'St-Germain Elderflower', 20.0),
    '080480250409': _BarcodeLookup('Midori Melon', 'liqueur', 'Midori', 20.0),
    '080480250508': _BarcodeLookup('Peach Schnapps', 'liqueur', 'Peach Schnapps', 15.0),
    '317973112018': _BarcodeLookup('Benedictine DOM', 'liqueur', 'Benedictine', 40.0),
    '301299302015': _BarcodeLookup('Green Chartreuse', 'liqueur', 'Chartreuse', 55.0),
    '301299303012': _BarcodeLookup('Yellow Chartreuse', 'liqueur', 'Chartreuse', 40.0),
    '800334001018': _BarcodeLookup('Fernet-Branca', 'liqueur', 'Fernet-Branca', 39.0),
    '080480250607': _BarcodeLookup('Galliano L\'Autentico', 'liqueur', 'Galliano', 42.3),
    '080480250706': _BarcodeLookup('Drambuie', 'liqueur', 'Drambuie', 40.0),
    '080480250805': _BarcodeLookup('Pama Pomegranate', 'liqueur', 'Pomegranate Liqueur', 17.0),
    '080480250904': _BarcodeLookup('Ancho Reyes', 'liqueur', 'Ancho Reyes Chile Liqueur', 40.0),
    '080480251000': _BarcodeLookup('Creme de Cacao Dark', 'liqueur', 'Creme de Cacao', 25.0),
    '080480251109': _BarcodeLookup('Creme de Cacao White', 'liqueur', 'White Creme de Cacao', 25.0),
    '080480251208': _BarcodeLookup('Creme de Cassis', 'liqueur', 'Creme de Cassis', 15.0),
    '080480251307': _BarcodeLookup('Creme de Violette', 'liqueur', 'Creme de Violette', 20.0),
    '080480251406': _BarcodeLookup('Green Creme de Menthe', 'liqueur', 'Green Creme de Menthe', 24.0),
    '080480251505': _BarcodeLookup('White Creme de Menthe', 'liqueur', 'White Creme de Menthe', 24.0),
    '080480251604': _BarcodeLookup('Absinthe Pernod', 'liqueur', 'Absinthe', 68.0),
    '080480251703': _BarcodeLookup('Velvet Falernum', 'liqueur', 'Velvet Falernum', 11.0),
    '080480251802': _BarcodeLookup('St. Elizabeth Allspice Dram', 'liqueur', 'Allspice Dram', 22.5),
    '080480251901': _BarcodeLookup('Amaro Nonino', 'liqueur', 'Amaro Nonino', 35.0),
    '600122415018': _BarcodeLookup('Amarula', 'liqueur', 'Amarula', 17.0),
    '080480252007': _BarcodeLookup('Apricot Liqueur', 'liqueur', 'Apricot Liqueur', 24.0),

    // -- Vermouth & fortified wine ----------------------------------------------
    '080480300001': _BarcodeLookup('Martini & Rossi Rosso', 'wine', 'Sweet Vermouth', 15.0),
    '080480300100': _BarcodeLookup('Martini & Rossi Extra Dry', 'wine', 'Dry Vermouth', 18.0),
    '800334009014': _BarcodeLookup('Cinzano Rosso', 'wine', 'Sweet Vermouth', 15.0),
    '800334010010': _BarcodeLookup('Cinzano Extra Dry', 'wine', 'Dry Vermouth', 18.0),
    '080480300209': _BarcodeLookup('Dolin Rouge', 'wine', 'Sweet Vermouth', 16.0),
    '080480300308': _BarcodeLookup('Dolin Dry', 'wine', 'Dry Vermouth', 17.5),
    '080480300407': _BarcodeLookup('Carpano Antica Formula', 'wine', 'Sweet Vermouth', 16.5),
    '080480300506': _BarcodeLookup('Noilly Prat Original Dry', 'wine', 'Dry Vermouth', 18.0),
    '080480300605': _BarcodeLookup('La Marca Prosecco', 'wine', 'Prosecco', 11.0),
    '080480300704': _BarcodeLookup('Freixenet Cordon Negro', 'wine', 'Prosecco', 11.5),
    '080480300803': _BarcodeLookup('Tio Pepe Fino', 'wine', 'Dry Sherry', 15.0),
    '080480300902': _BarcodeLookup('Lustau Amontillado', 'wine', 'Dry Sherry', 18.5),

    // -- Syrups -----------------------------------------------------------------
    '070847811015': _BarcodeLookup('Monin Orgeat', 'syrup', 'Orgeat', null),
    '070847812012': _BarcodeLookup('Monin Pure Cane', 'syrup', 'Simple Syrup', null),
    '070847813019': _BarcodeLookup('Monin Grenadine', 'syrup', 'Grenadine', null),
    '070847814016': _BarcodeLookup('Monin Passion Fruit', 'syrup', 'Passion Fruit Syrup', null),
    '070847815013': _BarcodeLookup('Monin Pineapple', 'syrup', 'Pineapple Syrup', null),
    '070847816010': _BarcodeLookup('Monin Cinnamon', 'syrup', 'Cinnamon Syrup', null),
    '070847817017': _BarcodeLookup('Monin Honey', 'syrup', 'Honey Syrup', null),
    '073138100015': _BarcodeLookup('Torani Puremade Simple', 'syrup', 'Simple Syrup', null),
    '073138101012': _BarcodeLookup('Torani Orgeat', 'syrup', 'Orgeat', null),
    '073138102019': _BarcodeLookup('Torani Grenadine', 'syrup', 'Grenadine', null),
    '073138103016': _BarcodeLookup('Small Hand Foods Orgeat', 'syrup', 'Orgeat', null),
    '073138104013': _BarcodeLookup('Liber & Co. Demerara', 'syrup', 'Demerara Syrup', null),
    '073138105010': _BarcodeLookup('Liber & Co. Passion Fruit', 'syrup', 'Passion Fruit Syrup', null),
    '073138106017': _BarcodeLookup('BG Reynolds Falernum', 'syrup', 'Falernum Syrup', null),
    '073138107014': _BarcodeLookup("Coco Lopez Cream of Coconut", 'syrup', 'Cream of Coconut', null),
    '073138108011': _BarcodeLookup('Goya Coconut Cream', 'syrup', 'Coconut Cream', null),

    // -- Juices (shelf bottles - "fresh" is the catalog name) -------------------
    '041800001015': _BarcodeLookup('ReaLemon Juice', 'juice', 'Fresh Lemon Juice', null),
    '041800002012': _BarcodeLookup('ReaLime Juice', 'juice', 'Fresh Lime Juice', null),
    '048500001019': _BarcodeLookup('Tropicana Orange Juice', 'juice', 'Orange Juice', null),
    '048500002016': _BarcodeLookup('Dole Pineapple Juice', 'juice', 'Pineapple Juice', null),
    '048500003013': _BarcodeLookup('Ocean Spray Cranberry', 'juice', 'Cranberry Juice', null),
    '048500004010': _BarcodeLookup('Ocean Spray Grapefruit', 'juice', 'Grapefruit Juice', null),
    '048500005017': _BarcodeLookup('Goya Passion Fruit', 'juice', 'Passion Fruit Juice', null),
    '048500006014': _BarcodeLookup('Goya Mango Nectar', 'juice', 'Mango Juice', null),
    '048500007011': _BarcodeLookup('Goya Papaya Nectar', 'juice', 'Papaya Juice', null),

    // -- Mixers -----------------------------------------------------------------
    '049000028911': _BarcodeLookup('Coca-Cola Classic', 'mixer', 'Cola (Coke)', null),
    '049000050011': _BarcodeLookup('Diet Coke', 'mixer', 'Cola (Coke)', null),
    '078000001015': _BarcodeLookup('Canada Dry Ginger Ale', 'mixer', 'Ginger Ale', null),
    '078000002012': _BarcodeLookup('Canada Dry Club Soda', 'mixer', 'Soda Water', null),
    '078000003019': _BarcodeLookup('Canada Dry Tonic', 'mixer', 'Tonic Water', null),
    '078000004016': _BarcodeLookup('Schweppes Ginger Ale', 'mixer', 'Ginger Ale', null),
    '078000005013': _BarcodeLookup('Schweppes Tonic', 'mixer', 'Tonic Water', null),
    '078000006010': _BarcodeLookup('Fever-Tree Ginger Beer', 'mixer', 'Ginger Beer', null),
    '078000007017': _BarcodeLookup('Fever-Tree Tonic', 'mixer', 'Tonic Water', null),
    '078000008014': _BarcodeLookup('Reed\'s Extra Ginger Beer', 'mixer', 'Ginger Beer', null),
    '078000009011': _BarcodeLookup('Vita Coco Coconut Water', 'mixer', 'Coconut Water', null),
    '078000010017': _BarcodeLookup('San Pellegrino Sparkling', 'mixer', 'Soda Water', null),

    // -- Bitters ----------------------------------------------------------------
    '036872010016': _BarcodeLookup('Angostura Aromatic Bitters', 'bitters', 'Angostura Bitters', 44.7),
    '082000200017': _BarcodeLookup("Peychaud's Bitters", 'bitters', "Peychaud's Bitters", 35.0),
    '082000700033': _BarcodeLookup("Regan's Orange Bitters", 'bitters', 'Orange Bitters', 45.0),
    '082000700132': _BarcodeLookup('Fee Brothers Orange Bitters', 'bitters', 'Orange Bitters', 28.0),
    '082000700231': _BarcodeLookup('Bittermens Elemakule Tiki', 'bitters', 'Angostura Bitters', 44.0),
  };

  /// Look up a barcode and return a match, or null if not recognized.
  ///
  /// Accepts UPC-A (12), EAN-13 (13, often `0` + UPC), and strings with spaces
  /// or hyphens. Digits-only after trim.
  static BarcodeMatch? lookup(String barcode) {
    final digits = _digitsOnly(barcode);
    if (digits.isEmpty) return null;

    for (final key in _candidateKeys(digits)) {
      final entry = _lookup[key];
      if (entry != null) {
        return BarcodeMatch(
          bottleName: entry.bottleName,
          suggestedIngredientName: entry.suggestedName,
          category: entry.category,
          abv: entry.abv,
        );
      }
    }
    return null;
  }

  static String _digitsOnly(String raw) =>
      raw.trim().replaceAll(RegExp(r'[^0-9]'), '');

  /// Generate lookup key variants for common retail barcode encodings.
  static Iterable<String> _candidateKeys(String digits) sync* {
    yield digits;
    // EAN-13 with leading 0 <-> UPC-A
    if (digits.length == 13 && digits.startsWith('0')) {
      yield digits.substring(1);
    }
    if (digits.length == 12) {
      yield '0$digits';
    }
    // Some scanners drop a check digit or pad; try stripping one leading zero.
    if (digits.length > 8 && digits.startsWith('0')) {
      yield digits.replaceFirst(RegExp(r'^0+'), '');
    }
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

  const _BarcodeLookup(
    this.bottleName,
    this.category,
    this.suggestedName, [
    this.abv,
  ]);
}
