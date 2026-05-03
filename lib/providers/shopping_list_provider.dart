import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_grocery_optimizer/models/shopping_list.dart';

/// Shopping list items state provider
/// 
/// Manages the list of items in the user's shopping list
/// Uses StateNotifier for mutable state management
class ShoppingListNotifier extends StateNotifier<List<ShoppingListItem>> {
  ShoppingListNotifier() : super([]);

  /// Add a new item to the shopping list
  void addItem(ShoppingListItem item) {
    state = [...state, item];
  }

  /// Remove an item from the shopping list
  void removeItem(String itemId) {
    state = state.where((item) => item.id != itemId).toList();
  }

  /// Toggle item purchased status
  void togglePurchased(String itemId) {
    state = [
      for (final item in state)
        if (item.id == itemId)
          ShoppingListItem(
            id: item.id,
            userId: item.userId,
            name: item.name,
            category: item.category,
            quantity: item.quantity,
            unit: item.unit,
            estimatedPrice: item.estimatedPrice,
            isPurchased: !item.isPurchased,
            addedDate: item.addedDate,
            notes: item.notes,
          )
        else
          item,
    ];
  }

  /// Update an existing item
  void updateItem(ShoppingListItem updatedItem) {
    state = [
      for (final item in state)
        if (item.id == updatedItem.id) updatedItem else item,
    ];
  }

  /// Clear all items
  void clearAll() {
    state = [];
  }

  /// Clear purchased items
  void clearPurchased() {
    state = state.where((item) => !item.isPurchased).toList();
  }
}

/// Provider for shopping list items
final shoppingListProvider =
    StateNotifierProvider<ShoppingListNotifier, List<ShoppingListItem>>(
  (ref) => ShoppingListNotifier(),
);

// Made with Bob
