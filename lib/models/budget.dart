/// Model representing a budget entry or expense
/// 
/// Tracks financial transactions related to grocery shopping
/// and helps users manage their grocery budget.
class Budget {
  final String id;
  final String userId;
  final double amount;
  final String category;
  final DateTime date;
  final String description;
  final BudgetType type;
  final String? receiptImageUrl;
  final List<String>? itemIds; // References to GroceryItem IDs

  const Budget({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.date,
    required this.description,
    required this.type,
    this.receiptImageUrl,
    this.itemIds,
  });

  /// Creates a Budget from JSON data
  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String,
      type: BudgetType.values.firstWhere(
        (e) => e.toString() == 'BudgetType.${json['type']}',
        orElse: () => BudgetType.expense,
      ),
      receiptImageUrl: json['receiptImageUrl'] as String?,
      itemIds: json['itemIds'] != null
          ? (json['itemIds'] as List<dynamic>).map((e) => e as String).toList()
          : null,
    );
  }

  /// Converts the Budget to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'description': description,
      'type': type.toString().split('.').last,
      'receiptImageUrl': receiptImageUrl,
      'itemIds': itemIds,
    };
  }

  /// Creates a copy of this Budget with updated fields
  Budget copyWith({
    String? id,
    String? userId,
    double? amount,
    String? category,
    DateTime? date,
    String? description,
    BudgetType? type,
    String? receiptImageUrl,
    List<String>? itemIds,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      description: description ?? this.description,
      type: type ?? this.type,
      receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl,
      itemIds: itemIds ?? this.itemIds,
    );
  }

  /// Checks if this is an expense
  bool get isExpense => type == BudgetType.expense;

  /// Checks if this is income/budget allocation
  bool get isIncome => type == BudgetType.income;

  /// Gets the signed amount (negative for expenses, positive for income)
  double get signedAmount => isExpense ? -amount : amount;

  @override
  String toString() {
    return 'Budget(id: $id, amount: \$${amount.toStringAsFixed(2)}, type: $type, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Budget && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Enum representing the type of budget entry
enum BudgetType {
  /// Money spent on groceries
  expense,
  
  /// Budget allocation or refund
  income,
}

/// Extension to get display names for BudgetType
extension BudgetTypeExtension on BudgetType {
  String get displayName {
    switch (this) {
      case BudgetType.expense:
        return 'Expense';
      case BudgetType.income:
        return 'Income';
    }
  }
}

// Made with Bob
