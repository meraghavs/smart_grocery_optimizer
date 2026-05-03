/// Model representing a shopping list
/// 
/// Contains a collection of items to purchase and metadata
/// about the shopping trip.
class ShoppingList {
  final String id;
  final String name;
  final List<ShoppingItem> items;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isCompleted;
  final double? estimatedTotal;
  final String? storeLocation;

  const ShoppingList({
    required this.id,
    required this.name,
    required this.items,
    required this.createdAt,
    this.completedAt,
    this.isCompleted = false,
    this.estimatedTotal,
    this.storeLocation,
  });

  /// Creates a ShoppingList from JSON data
  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id'] as String,
      name: json['name'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => ShoppingItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
      estimatedTotal: json['estimatedTotal'] != null
          ? (json['estimatedTotal'] as num).toDouble()
          : null,
      storeLocation: json['storeLocation'] as String?,
    );
  }

  /// Converts the ShoppingList to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'items': items.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isCompleted': isCompleted,
      'estimatedTotal': estimatedTotal,
      'storeLocation': storeLocation,
    };
  }

  /// Creates a copy of this ShoppingList with updated fields
  ShoppingList copyWith({
    String? id,
    String? name,
    List<ShoppingItem>? items,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? isCompleted,
    double? estimatedTotal,
    String? storeLocation,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      estimatedTotal: estimatedTotal ?? this.estimatedTotal,
      storeLocation: storeLocation ?? this.storeLocation,
    );
  }

  /// Gets the number of checked items
  int get checkedItemsCount => items.where((item) => item.isChecked).length;

  /// Gets the total number of items
  int get totalItemsCount => items.length;

  /// Calculates the actual total based on item prices
  double get actualTotal {
    return items.fold(0.0, (sum, item) {
      final price = item.price ?? 0.0;
      return sum + (price * item.quantity);
    });
  }

  /// Checks if all items are checked
  bool get allItemsChecked => items.isNotEmpty && checkedItemsCount == totalItemsCount;

  @override
  String toString() {
    return 'ShoppingList(id: $id, name: $name, items: ${items.length}, completed: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShoppingList && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Model representing an individual item in a shopping list
class ShoppingItem {
  final String id;
  final String name;
  final int quantity;
  final String unit;
  final bool isChecked;
  final double? price;
  final String? category;
  final String? notes;

  const ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    this.isChecked = false,
    this.price,
    this.category,
    this.notes,
  });

  /// Creates a ShoppingItem from JSON data
  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      unit: json['unit'] as String,
      isChecked: json['isChecked'] as bool? ?? false,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      category: json['category'] as String?,
      notes: json['notes'] as String?,
    );
  }

  /// Converts the ShoppingItem to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'isChecked': isChecked,
      'price': price,
      'category': category,
      'notes': notes,
    };
  }

  /// Creates a copy of this ShoppingItem with updated fields
  ShoppingItem copyWith({
    String? id,
    String? name,
    int? quantity,
    String? unit,
    bool? isChecked,
    double? price,
    String? category,
    String? notes,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      isChecked: isChecked ?? this.isChecked,
      price: price ?? this.price,
      category: category ?? this.category,
      notes: notes ?? this.notes,
    );
  }

  /// Gets the total price for this item (price * quantity)
  double get totalPrice => (price ?? 0.0) * quantity;

  @override
  String toString() {
    return 'ShoppingItem(id: $id, name: $name, quantity: $quantity $unit, checked: $isChecked)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShoppingItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
/// Model representing an individual shopping list item with purchase tracking
class ShoppingListItem {
  final String id;
  final String userId;
  final String name;
  final String category;
  final double quantity;
  final String unit;
  final double? estimatedPrice;
  final bool isPurchased;
  final DateTime addedDate;
  final String? notes;

  const ShoppingListItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    this.estimatedPrice,
    this.isPurchased = false,
    required this.addedDate,
    this.notes,
  });

  /// Creates a ShoppingListItem from JSON data
  factory ShoppingListItem.fromJson(Map<String, dynamic> json) {
    return ShoppingListItem(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      estimatedPrice: json['estimatedPrice'] != null
          ? (json['estimatedPrice'] as num).toDouble()
          : null,
      isPurchased: json['isPurchased'] as bool? ?? false,
      addedDate: DateTime.parse(json['addedDate'] as String),
      notes: json['notes'] as String?,
    );
  }

  /// Converts the ShoppingListItem to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'estimatedPrice': estimatedPrice,
      'isPurchased': isPurchased,
      'addedDate': addedDate.toIso8601String(),
      'notes': notes,
    };
  }

  /// Creates a copy of this ShoppingListItem with updated fields
  ShoppingListItem copyWith({
    String? id,
    String? userId,
    String? name,
    String? category,
    double? quantity,
    String? unit,
    double? estimatedPrice,
    bool? isPurchased,
    DateTime? addedDate,
    String? notes,
  }) {
    return ShoppingListItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      isPurchased: isPurchased ?? this.isPurchased,
      addedDate: addedDate ?? this.addedDate,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'ShoppingListItem(id: $id, name: $name, quantity: $quantity $unit, purchased: $isPurchased)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShoppingListItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}


// Made with Bob
