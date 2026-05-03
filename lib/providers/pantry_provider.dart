import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_grocery_optimizer/models/grocery_item.dart';

/// Pantry items state provider
/// 
/// Manages the list of grocery items in the user's pantry
/// Uses StateNotifier for mutable state management
class PantryNotifier extends StateNotifier<List<GroceryItem>> {
  PantryNotifier() : super([]);

  /// Add a new item to the pantry
  void addItem(GroceryItem item) {
    state = [...state, item];
  }

  /// Remove an item from the pantry
  void removeItem(String itemId) {
    state = state.where((item) => item.id != itemId).toList();
  }

  /// Update an existing item
  void updateItem(GroceryItem updatedItem) {
    state = [
      for (final item in state)
        if (item.id == updatedItem.id) updatedItem else item,
    ];
  }

  /// Clear all items
  void clearAll() {
    state = [];
  }
}

/// Provider for pantry items
final pantryProvider = StateNotifierProvider<PantryNotifier, List<GroceryItem>>(
  (ref) => PantryNotifier(),
);

// Made with Bob
