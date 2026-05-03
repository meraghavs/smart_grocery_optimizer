import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_grocery_optimizer/models/grocery_item.dart';

/// Pantry items state provider with Firestore persistence
/// 
/// Manages the list of grocery items in the user's pantry
/// Uses StateNotifier for mutable state management
/// Automatically syncs with Firestore for data persistence
class PantryNotifier extends StateNotifier<List<GroceryItem>> {
  final FirebaseFirestore _firestore;
  final String _userId;
  
  PantryNotifier(this._firestore, this._userId) : super([]) {
    _loadItems();
  }

  /// Load items from Firestore
  Future<void> _loadItems() async {
    try {
      final snapshot = await _firestore
          .collection('pantry')
          .where('userId', isEqualTo: _userId)
          .get();
      
      state = snapshot.docs
          .map((doc) => GroceryItem.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
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
}

/// Provider for pantry items with Firestore persistence
final pantryProvider = StateNotifierProvider<PantryNotifier, List<GroceryItem>>(
  (ref) => PantryNotifier(
    FirebaseFirestore.instance,
    'user1', // TODO: Replace with actual user ID from auth
  ),
);

// Made with Bob
