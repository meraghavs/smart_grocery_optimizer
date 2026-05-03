/// Model representing a grocery item in the pantry
///
/// This class contains all information about a grocery item including
/// its name, quantity, expiry date, and other relevant details.
class GroceryItem {
  final String id;
  final String userId;
  final String name;
  final String category;
  final int quantity;
  final String unit;
  final DateTime expiryDate;
  final DateTime purchaseDate;
  final double price;
  final String? imageUrl;
  final String? barcode;

  const GroceryItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.expiryDate,
    required this.purchaseDate,
    required this.price,
    this.imageUrl,
    this.barcode,
  });

  /// Creates a GroceryItem from JSON data
  factory GroceryItem.fromJson(Map<String, dynamic> json) {
    return GroceryItem(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      quantity: json['quantity'] as int,
      unit: json['unit'] as String,
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String?,
      barcode: json['barcode'] as String?,
    );
  }

  /// Converts the GroceryItem to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'expiryDate': expiryDate.toIso8601String(),
      'purchaseDate': purchaseDate.toIso8601String(),
      'price': price,
      'imageUrl': imageUrl,
      'barcode': barcode,
    };
  }

  /// Creates a copy of this GroceryItem with updated fields
  GroceryItem copyWith({
    String? id,
    String? userId,
    String? name,
    String? category,
    int? quantity,
    String? unit,
    DateTime? expiryDate,
    DateTime? purchaseDate,
    double? price,
    String? imageUrl,
    String? barcode,
  }) {
    return GroceryItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expiryDate: expiryDate ?? this.expiryDate,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      barcode: barcode ?? this.barcode,
    );
  }

  /// Checks if the item is expired
  bool get isExpired => DateTime.now().isAfter(expiryDate);

  /// Gets the number of days until expiry (negative if expired)
  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;

  @override
  String toString() {
    return 'GroceryItem(id: $id, name: $name, quantity: $quantity $unit, expiryDate: $expiryDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroceryItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Made with Bob
