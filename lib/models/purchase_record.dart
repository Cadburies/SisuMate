part of 'models.dart';

// Nested data class, serialized as JSON inside the Drift bar/pantry
// `purchaseHistory` columns.
class PurchaseRecord {
  double? price;
  String currency = 'USD';
  String? place;
  DateTime? purchaseDate;
  String? priceUnit;
  String? notes;

  PurchaseRecord();

  factory PurchaseRecord.fromJson(Map<String, dynamic> json) {
    return PurchaseRecord()
      ..price = (json['price'] as num?)?.toDouble()
      ..currency = json['currency'] ?? 'USD'
      ..place = json['place']
      ..purchaseDate = json['purchaseDate'] != null
          ? DateTime.parse(json['purchaseDate'])
          : null
      ..priceUnit = json['priceUnit']
      ..notes = json['notes'];
  }

  Map<String, dynamic> toJson() => {
        'price': price,
        'currency': currency,
        'place': place,
        'purchaseDate': purchaseDate?.toIso8601String(),
        'priceUnit': priceUnit,
        'notes': notes,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseRecord &&
          runtimeType == other.runtimeType &&
          price == other.price &&
          currency == other.currency &&
          place == other.place &&
          purchaseDate == other.purchaseDate &&
          priceUnit == other.priceUnit &&
          notes == other.notes;

  @override
  int get hashCode =>
      Object.hashAll([price, currency, place, purchaseDate, priceUnit, notes]);

  @override
  String toString() => 'PurchaseRecord(price: $price, currency: $currency, '
      'place: $place, purchaseDate: $purchaseDate, priceUnit: $priceUnit, '
      'notes: $notes)';
}
