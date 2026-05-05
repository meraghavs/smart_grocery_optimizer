import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing item transfers between pantry and shopping list
/// 
/// Records transfer history in Firestore for tracking and analytics
class TransferService {
  final FirebaseFirestore _firestore;
  
  TransferService(this._firestore);
  
  /// Log a transfer from one list to another
  Future<void> logTransfer({
    required String itemName,
    required String fromList,
    required String toList,
    required String userId,
  }) async {
    try {
      await _firestore.collection('transfers').add({
        'itemName': itemName,
        'fromList': fromList,
        'toList': toList,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging transfer: $e');
    }
  }
  
  /// Get transfer history for a user
  Future<List<Map<String, dynamic>>> getTransferHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('transfers')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      
      return snapshot.docs.map((doc) => {
        ...doc.data(),
        'id': doc.id,
      }).toList();
    } catch (e) {
      print('Error getting transfer history: $e');
      return [];
    }
  }
}

// Made with Bob