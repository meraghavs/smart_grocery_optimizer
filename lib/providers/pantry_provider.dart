import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_grocery_optimizer/models/grocery_item.dart';
import 'package:smart_grocery_optimizer/models/shopping_list.dart';
import 'package:smart_grocery_optimizer/models/item_source_list.dart';
import 'package:smart_grocery_optimizer/services/transfer_service.dart';

/// Pantry items state provider with Firestore persistence
/// 
/// Manages the list of grocery items in the user's pantry
/// Uses StateNotifier for mutable state management
/// Automatically syncs with Firestore for data persistence
class PantryNotifier extends StateNotifier<List<GroceryItem>> {
  final FirebaseFirestore _firestore;
  final String _userId;
  final TransferService _transferService;
  
  PantryNotifier(this._firestore, this._userId, this._transferService) : super([]) {
    loadItems();
  }

  /// Load items from Firestore
  Future<void> loadItems() async {
    try {
      print('DEBUG: Loading pantry items from Firestore');
      final snapshot = await _firestore
          .collection('pantry')
          .where('userId', isEqualTo: _userId)
          .get();
      
      print('DEBUG: Found ${snapshot.docs.length} pantry items');
      state = snapshot.docs
          .map((doc) => GroceryItem.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
      print('DEBUG: Pantry state updated with ${state.length} items');
    } catch (e) {
      print('Error loading pantry items: $e');
    }
  }

  /// Add a new item to the pantry
  void addItem(GroceryItem item) {
    // Update local state immediately for instant UI update
    state = [...state, item];
    
    // Save to Firestore in the background
    _firestore.collection('pantry').doc(item.id).set(item.toJson()).catchError((e) {
      print('Error adding pantry item to Firestore: $e');
    });
  }

  /// Remove an item from the pantry
  void removeItem(String itemId) {
    // Update local state immediately for instant UI update
    state = state.where((item) => item.id != itemId).toList();
    
    // Delete from Firestore in the background
    _firestore.collection('pantry').doc(itemId).delete().catchError((e) {
      print('Error removing pantry item from Firestore: $e');
    });
  }

  /// Update an existing item
  void updateItem(GroceryItem updatedItem) {
    // Update local state immediately for instant UI update
    state = [
      for (final item in state)
        if (item.id == updatedItem.id) updatedItem else item,
    ];
    
    // Update in Firestore in the background
    _firestore
        .collection('pantry')
        .doc(updatedItem.id)
        .update(updatedItem.toJson())
        .catchError((e) {
      print('Error updating pantry item in Firestore: $e');
    });
  }

  /// Clear all items
  Future<void> clearAll() async {
    try {
      // Delete all items from Firestore
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('pantry')
          .where('userId', isEqualTo: _userId)
          .get();
      
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      // Update local state
      state = [];
    } catch (e) {
      print('Error clearing pantry: $e');
    }
  }
  
  /// Move item to shopping list
  /// Returns the created ShoppingListItem for adding to shopping list provider
  Future<ShoppingListItem?> moveToShoppingList(String itemId) async {
    try {
      final item = state.firstWhere((item) => item.id == itemId);
      
      print('DEBUG: Moving item ${item.name} from pantry to shopping list');
      
      // Create shopping list item from pantry item
      final shoppingItem = ShoppingListItem(
        id: item.id,
        userId: item.userId,
        name: item.name,
        category: item.category,
        quantity: item.quantity.toDouble(),
        unit: item.unit,
        estimatedPrice: item.price,
        isPurchased: false,
        addedDate: DateTime.now(),
        notes: 'Moved from pantry',
        sourceList: ItemSourceList.shoppingList,
      );
      
      print('DEBUG: Created shopping item: ${shoppingItem.toJson()}');
      
      // Add to shopping_list collection in Firestore FIRST
      try {
        print('DEBUG: About to write to Firestore shopping_list collection...');
        await _firestore.collection('shopping_list').doc(itemId).set(shoppingItem.toJson());
        print('DEBUG: Successfully added to shopping_list collection in Firestore');
      } catch (firestoreError) {
        print('DEBUG: Firestore write error: $firestoreError');
        print('DEBUG: Error type: ${firestoreError.runtimeType}');
        rethrow;
      }
      
      // Then remove from pantry state
      state = state.where((i) => i.id != itemId).toList();
      print('DEBUG: Removed from pantry state');
      
      // Delete from pantry collection in Firestore
      await _firestore.collection('pantry').doc(itemId).delete();
      print('DEBUG: Deleted from pantry collection in Firestore');
      
      // Log transfer
      await _transferService.logTransfer(
        itemName: item.name,
        fromList: 'pantry',
        toList: 'shoppingList',
        userId: _userId,
      );
      print('DEBUG: Transfer logged');
      
      return shoppingItem;
    } catch (e, stackTrace) {
      print('ERROR moving item to shopping list: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }
  
  /// Reload items after transfer from shopping list
  Future<void> reloadAfterTransfer() async {
    print('DEBUG: Reloading pantry after transfer');
    await loadItems();
  }
}

/// Provider for transfer service
final transferServiceProvider = Provider<TransferService>(
  (ref) => TransferService(FirebaseFirestore.instance),
);

/// Provider for pantry items with Firestore persistence
final pantryProvider = StateNotifierProvider<PantryNotifier, List<GroceryItem>>(
  (ref) => PantryNotifier(
    FirebaseFirestore.instance,
    'user1', // TODO: Replace with actual user ID from auth
    ref.watch(transferServiceProvider),
  ),
);

// Made with Bob
