import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget.dart';

/// Budget provider with Firestore persistence
/// Manages budget expenses with immediate UI updates and background sync
final budgetProvider = StateNotifierProvider<BudgetNotifier, List<Budget>>((ref) {
  return BudgetNotifier();
});

class BudgetNotifier extends StateNotifier<List<Budget>> {
  BudgetNotifier() : super([]) {
    _loadExpenses();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Load expenses from Firestore
  Future<void> _loadExpenses() async {
    try {
      final snapshot = await _firestore
          .collection('expenses')
          .orderBy('date', descending: true)
          .get();

      final expenses = snapshot.docs
          .map((doc) => Budget.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      state = expenses;
    } catch (e) {
      print('Error loading expenses from Firestore: $e');
    }
  }

  /// Add a new expense
  /// Updates state immediately for instant UI feedback, then saves to Firestore
  void addExpense(Budget expense) {
    // Update local state immediately for instant UI update
    state = [expense, ...state];

    // Save to Firestore in the background
    _firestore.collection('expenses').doc(expense.id).set(expense.toJson()).catchError((e) {
      print('Error adding expense to Firestore: $e');
    });
  }

  /// Remove an expense
  /// Updates state immediately for instant UI feedback, then removes from Firestore
  void removeExpense(String id) {
    // Update local state immediately for instant UI update
    state = state.where((expense) => expense.id != id).toList();

    // Remove from Firestore in the background
    _firestore.collection('expenses').doc(id).delete().catchError((e) {
      print('Error removing expense from Firestore: $e');
    });
  }

  /// Update an expense
  /// Updates state immediately for instant UI feedback, then updates Firestore
  void updateExpense(Budget updatedExpense) {
    // Update local state immediately for instant UI update
    state = state.map((expense) {
      return expense.id == updatedExpense.id ? updatedExpense : expense;
    }).toList();

    // Update Firestore in the background
    _firestore
        .collection('expenses')
        .doc(updatedExpense.id)
        .update(updatedExpense.toJson())
        .catchError((e) {
      print('Error updating expense in Firestore: $e');
    });
  }

  /// Clear all expenses
  void clearExpenses() {
    final expenseIds = state.map((e) => e.id).toList();
    
    // Update local state immediately
    state = [];

    // Delete from Firestore in the background
    for (final id in expenseIds) {
      _firestore.collection('expenses').doc(id).delete().catchError((e) {
        print('Error deleting expense $id from Firestore: $e');
      });
    }
  }

  /// Get total spending
  double get totalSpending {
    return state.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Get spending by category
  Map<String, double> get spendingByCategory {
    final Map<String, double> categorySpending = {};
    for (var expense in state) {
      categorySpending[expense.category] =
          (categorySpending[expense.category] ?? 0) + expense.amount;
    }
    return categorySpending;
  }

  /// Get expenses for a specific date range
  List<Budget> getExpensesInRange(DateTime start, DateTime end) {
    return state.where((expense) {
      return expense.date.isAfter(start.subtract(const Duration(days: 1))) &&
          expense.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  /// Get weekly spending by category
  Map<String, double> get weeklySpendingByCategory {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weeklyExpenses = getExpensesInRange(weekAgo, now);
    
    final Map<String, double> categorySpending = {};
    for (var expense in weeklyExpenses) {
      categorySpending[expense.category] =
          (categorySpending[expense.category] ?? 0) + expense.amount;
    }
    return categorySpending;
  }

  /// Refresh expenses from Firestore
  Future<void> refresh() async {
    await _loadExpenses();
  }
}

// Made with Bob
