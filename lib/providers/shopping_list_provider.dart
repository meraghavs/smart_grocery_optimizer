import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_grocery_optimizer/models/shopping_list.dart';
import 'package:smart_grocery_optimizer/models/grocery_item.dart';
import 'package:smart_grocery_optimizer/models/item_source_list.dart';
import 'package:smart_grocery_optimizer/services/transfer_service.dart';

/// Shopping list items state provider with Firestore persistence
/// 
/// Manages the list of items in the user's shopping list
/// Uses StateNotifier for mutable state management
/// Automatically syncs with Firestore for data persistence
class ShoppingListNotifier extends StateNotifier<List<ShoppingListItem>> {
  final FirebaseFirestore _firestore;
  final String _userId;
  final TransferService _transferService;
  
  ShoppingListNotifier(this._firestore, this._userId, this._transferService) : super([]) {
    loadItems();
  }

  /// Load items from Firestore
  Future<void> loadItems() async {
    try {
      print('DEBUG: Loading shopping list items from Firestore');
      final snapshot = await _firestore
          .collection('shopping_list')
          .where('userId', isEqualTo: _userId)
          .get();
      
      print('DEBUG: Found ${snapshot.docs.length} shopping list items');
      state = snapshot.docs
          .map((doc) => ShoppingListItem.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
      print('DEBUG: Shopping list state updated with ${state.length} items');
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
  
  /// Move item to pantry
  /// Returns the created GroceryItem for adding to pantry provider
  Future<GroceryItem?> moveToPantry(String itemId) async {
    try {
      final item = state.firstWhere((item) => item.id == itemId);
      
      print('DEBUG: Moving item ${item.name} from shopping list to pantry');
      
      // Create pantry item from shopping list item
      final pantryItem = GroceryItem(
        id: item.id,
        userId: item.userId,
        name: item.name,
        category: item.category,
        quantity: item.quantity.toInt(),
        unit: item.unit,
        expiryDate: DateTime.now().add(const Duration(days: 7)), // Default 7 days
        purchaseDate: DateTime.now(),
        price: item.estimatedPrice ?? 0,
        sourceList: ItemSourceList.pantry,
      );
      
      print('DEBUG: Created pantry item: ${pantryItem.toJson()}');
      
      // Add to pantry collection in Firestore FIRST
      try {
        print('DEBUG: About to write to Firestore pantry collection...');
        await _firestore.collection('pantry').doc(itemId).set(pantryItem.toJson());
        print('DEBUG: Successfully added to pantry collection in Firestore');
      } catch (firestoreError) {
        print('DEBUG: Firestore write error: $firestoreError');
        print('DEBUG: Error type: ${firestoreError.runtimeType}');
        rethrow;
      }
      
      // Then remove from shopping list state
      state = state.where((i) => i.id != itemId).toList();
      print('DEBUG: Removed from shopping list state');
      
      // Delete from shopping_list collection in Firestore
      await _firestore.collection('shopping_list').doc(itemId).delete();
      print('DEBUG: Deleted from shopping_list collection in Firestore');
      
      // Log transfer
      await _transferService.logTransfer(
        itemName: item.name,
        fromList: 'shoppingList',
        toList: 'pantry',
        userId: _userId,
      );
      print('DEBUG: Transfer logged');
      
      return pantryItem;
    } catch (e, stackTrace) {
      print('ERROR moving item to pantry: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }
  
  /// Reload items after transfer from pantry
  Future<void> reloadAfterTransfer() async {
    print('DEBUG: Reloading shopping list after transfer');
    await loadItems();
  }
}

/// Provider for transfer service
final transferServiceProvider = Provider<TransferService>(
  (ref) => TransferService(FirebaseFirestore.instance),
);

/// Provider for shopping list items with Firestore persistence
final shoppingListProvider =
    StateNotifierProvider<ShoppingListNotifier, List<ShoppingListItem>>(
  (ref) => ShoppingListNotifier(
    FirebaseFirestore.instance,
    'user1', // TODO: Replace with actual user ID from auth
    ref.watch(transferServiceProvider),
  ),
);

// Made with Bob
