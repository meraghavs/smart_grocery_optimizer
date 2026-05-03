import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_grocery_optimizer/models/shopping_list.dart';

/// Shopping list items state provider with Firestore persistence
/// 
/// Manages the list of items in the user's shopping list
/// Uses StateNotifier for mutable state management
/// Automatically syncs with Firestore for data persistence
class ShoppingListNotifier extends StateNotifier<List<ShoppingListItem>> {
  final FirebaseFirestore _firestore;
  final String _userId;
  
  ShoppingListNotifier(this._firestore, this._userId) : super([]) {
    _loadItems();
  }

  /// Load items from Firestore
  Future<void> _loadItems() async {
    try {
      final snapshot = await _firestore
          .collection('shopping_list')
          .where('userId', isEqualTo: _userId)
          .get();
      
      state = snapshot.docs
          .map((doc) => ShoppingListItem.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error loading shopping list items: $e');
    }
  }

  /// Add a new item to the shopping list
  void addItem(ShoppingListItem item) {
    // Update local state immediately for instant UI update
    state = [...state, item];
    
    // Save to Firestore in the background
    _firestore.collection('shopping_list').doc(item.id).set(item.toJson()).catchError((e) {
      print('Error adding shopping list item to Firestore: $e');
    });
  }

  /// Remove an item from the shopping list
  void removeItem(String itemId) {
    // Update local state immediately for instant UI update
    state = state.where((item) => item.id != itemId).toList();
    
    // Delete from Firestore in the background
    _firestore.collection('shopping_list').doc(itemId).delete().catchError((e) {
      print('Error removing shopping list item from Firestore: $e');
    });
  }

  /// Toggle item purchased status
  void togglePurchased(String itemId) {
    final item = state.firstWhere((item) => item.id == itemId);
    final updatedItem = ShoppingListItem(
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
    );
    
    // Update local state immediately for instant UI update
    state = [
      for (final item in state)
        if (item.id == itemId) updatedItem else item,
    ];
    
    // Update in Firestore in the background
    _firestore
        .collection('shopping_list')
        .doc(itemId)
        .update({'isPurchased': updatedItem.isPurchased})
        .catchError((e) {
      print('Error toggling purchased status in Firestore: $e');
    });
  }

  /// Update an existing item
  void updateItem(ShoppingListItem updatedItem) {
    // Update local state immediately for instant UI update
    state = [
      for (final item in state)
        if (item.id == updatedItem.id) updatedItem else item,
    ];
    
    // Update in Firestore in the background
    _firestore
        .collection('shopping_list')
        .doc(updatedItem.id)
        .update(updatedItem.toJson())
        .catchError((e) {
      print('Error updating shopping list item in Firestore: $e');
    });
  }

  /// Clear all items
  Future<void> clearAll() async {
    try {
      // Delete all items from Firestore
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('shopping_list')
          .where('userId', isEqualTo: _userId)
          .get();
      
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      // Update local state
      state = [];
    } catch (e) {
      print('Error clearing shopping list: $e');
    }
  }

  /// Clear purchased items
  Future<void> clearPurchased() async {
    try {
      // Delete purchased items from Firestore
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('shopping_list')
          .where('userId', isEqualTo: _userId)
          .where('isPurchased', isEqualTo: true)
          .get();
      
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      // Update local state
      state = state.where((item) => !item.isPurchased).toList();
    } catch (e) {
      print('Error clearing purchased items: $e');
    }
  }
}

/// Provider for shopping list items with Firestore persistence
final shoppingListProvider =
    StateNotifierProvider<ShoppingListNotifier, List<ShoppingListItem>>(
  (ref) => ShoppingListNotifier(
    FirebaseFirestore.instance,
    'user1', // TODO: Replace with actual user ID from auth
  ),
);

// Made with Bob
