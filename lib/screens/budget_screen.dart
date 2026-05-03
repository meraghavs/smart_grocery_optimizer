import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/budget.dart';
import '../providers/shopping_list_provider.dart';

/// Budget tracking screen with real-time shopping list integration
///
/// Features:
/// - Real shopping list cost estimation
/// - Weekly spending bar chart by category
/// - Budget alerts at 80% threshold
/// - Category breakdown
/// - Monthly spending summary
/// - Add expenses functionality
class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  // State variables
  bool _isLoading = false;
  double _monthlyBudget = 500.0; // Default budget
  double _currentSpending = 0.0;
  Map<String, double> _weeklySpendingByCategory = {};
  List<Budget> _recentExpenses = [];

  @override
  void initState() {
    super.initState();
    _loadBudgetData();
  }

  /// Loads budget data
  Future<void> _loadBudgetData() async {
    setState(() => _isLoading = true);

    try {

      // Initialize with existing expenses
      _currentSpending = _recentExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
      
      // Calculate category spending from expenses
      _weeklySpendingByCategory = {};
      for (var expense in _recentExpenses) {
        _weeklySpendingByCategory[expense.category] =
            (_weeklySpendingByCategory[expense.category] ?? 0) + expense.amount;
      }

      setState(() {
        _isLoading = false;
      });

      // Check budget alert is done in build method with actual data
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading budget data: $e')),
        );
      }
    }
  }

  /// Checks if user has reached 80% of budget and shows alert
  void _checkBudgetAlert(double estimatedShoppingListCost) {
    final projectedTotal = _currentSpending + estimatedShoppingListCost;
    final budgetPercentage = (projectedTotal / _monthlyBudget) * 100;

    if (budgetPercentage >= 80 && budgetPercentage < 100) {
      _showBudgetAlert(
        'Budget Warning',
        'You are at ${budgetPercentage.toStringAsFixed(1)}% of your monthly budget!',
        Colors.orange,
      );
    } else if (budgetPercentage >= 100) {
      _showBudgetAlert(
        'Budget Exceeded',
        'You have exceeded your monthly budget by \$${(projectedTotal - _monthlyBudget).toStringAsFixed(2)}!',
        Colors.red,
      );
    }
  }

  /// Shows budget alert dialog
  void _showBudgetAlert(String title, String message, Color color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: color),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showBudgetSettings();
            },
            child: const Text('Adjust Budget'),
          ),
        ],
      ),
    );
  }

  /// Shows budget settings dialog
  void _showBudgetSettings() {
    final controller = TextEditingController(text: _monthlyBudget.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Monthly Budget'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Monthly Budget',
            prefixText: '\$',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _monthlyBudget = double.tryParse(controller.text) ?? 500.0;
              });
              Navigator.pop(context);
              // Budget alert will be checked on next build
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get actual shopping list data
    final shoppingItems = ref.watch(shoppingListProvider);
    final estimatedShoppingListCost = shoppingItems.fold<double>(
      0,
      (sum, item) => sum + (item.estimatedPrice ?? 0),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showBudgetSettings,
            tooltip: 'Budget Settings',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBudgetData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBudgetData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBudgetSummaryCard(estimatedShoppingListCost),
                    const SizedBox(height: 16),
                    _buildShoppingListEstimateCard(shoppingItems, estimatedShoppingListCost),
                    const SizedBox(height: 16),
                    _buildWeeklySpendingChart(),
                    const SizedBox(height: 16),
                    _buildCategoryBreakdown(),
                    const SizedBox(height: 16),
                    _buildRecentExpenses(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExpense,
        child: const Icon(Icons.add),
        tooltip: 'Add Expense',
      ),
    );
  }

  /// Budget summary card with progress indicator
  Widget _buildBudgetSummaryCard(double estimatedShoppingListCost) {
    final projectedTotal = _currentSpending + estimatedShoppingListCost;
    final budgetPercentage = (projectedTotal / _monthlyBudget).clamp(0.0, 1.0);
    final remaining = _monthlyBudget - projectedTotal;

    Color progressColor;
    if (budgetPercentage >= 1.0) {
      progressColor = Colors.red;
    } else if (budgetPercentage >= 0.8) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.green;
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Monthly Budget',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${_monthlyBudget.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: budgetPercentage,
              backgroundColor: Colors.grey[300],
              color: progressColor,
              minHeight: 10,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBudgetStat(
                  'Spent',
                  '\$${_currentSpending.toStringAsFixed(2)}',
                  Colors.blue,
                ),
                _buildBudgetStat(
                  'Projected',
                  '\$${estimatedShoppingListCost.toStringAsFixed(2)}',
                  Colors.orange,
                ),
                _buildBudgetStat(
                  remaining >= 0 ? 'Remaining' : 'Over Budget',
                  '\$${remaining.abs().toStringAsFixed(2)}',
                  remaining >= 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${(budgetPercentage * 100).toStringAsFixed(1)}% of budget used',
              style: TextStyle(
                color: progressColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Shopping list estimate card with actual shopping list items
  Widget _buildShoppingListEstimateCard(dynamic shoppingItems, double total) {
    if (shoppingItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      child: ExpansionTile(
        leading: const Icon(Icons.shopping_cart, color: Colors.blue),
        title: const Text(
          'Shopping List Estimate',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Total: \$${total.toStringAsFixed(2)} (${shoppingItems.length} items)',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...shoppingItems.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.name} (${item.quantity} ${item.unit})',
                          style: TextStyle(
                            decoration: item.isPurchased
                                ? TextDecoration.lineThrough
                                : null,
                            color: item.isPurchased
                                ? Colors.grey[600]
                                : Colors.black,
                          ),
                        ),
                      ),
                      Text(
                        item.estimatedPrice != null
                            ? '\$${item.estimatedPrice!.toStringAsFixed(2)}'
                            : 'N/A',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: item.isPurchased
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ],
                  ),
                )),
                if (total > 0) ...[
                  const Divider(thickness: 2),
                  _buildPriceRow('Total', total, bold: true),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  /// Weekly spending bar chart by category
  Widget _buildWeeklySpendingChart() {
    if (_weeklySpendingByCategory.isEmpty) {
      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Weekly Spending by Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No expenses yet. Add an expense to see the chart.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Spending by Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _weeklySpendingByCategory.values.reduce((a, b) => a > b ? a : b) * 1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final category = _weeklySpendingByCategory.keys.elementAt(groupIndex);
                        return BarTooltipItem(
                          '$category\n\$${rod.toY.toStringAsFixed(2)}',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final categories = _weeklySpendingByCategory.keys.toList();
                          if (value.toInt() >= 0 && value.toInt() < categories.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                categories[value.toInt()],
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\$${value.toInt()}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _weeklySpendingByCategory.entries.map((entry) {
                    final index = _weeklySpendingByCategory.keys.toList().indexOf(entry.key);
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value,
                          color: _getCategoryColor(entry.key),
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'Groceries': Colors.blue,
      'Dairy': Colors.orange,
      'Meat': Colors.red,
      'Produce': Colors.green,
      'Bakery': Colors.purple,
    };
    return colors[category] ?? Colors.grey;
  }

  /// Category breakdown pie chart
  Widget _buildCategoryBreakdown() {
    if (_weeklySpendingByCategory.isEmpty) {
      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Category Breakdown',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No expenses yet. Add an expense to see category breakdown.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final total = _weeklySpendingByCategory.values.reduce((a, b) => a + b);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._weeklySpendingByCategory.entries.map((entry) {
              final percentage = (entry.value / total * 100);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(entry.key),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(entry.key),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '\$${entry.value.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Recent expenses list
  Widget _buildRecentExpenses() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Expenses',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_recentExpenses.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No expenses yet'),
                ),
              )
            else
              ..._recentExpenses.map((expense) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getCategoryColor(expense.category),
                  child: const Icon(Icons.shopping_bag, color: Colors.white),
                ),
                title: Text(expense.description),
                subtitle: Text(
                  '${expense.category} • ${_formatDate(expense.date)}',
                ),
                trailing: Text(
                  '\$${expense.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  void _addExpense() {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'Groceries';
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.add_circle, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
                      'Add Expense',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                    prefixText: '\$',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                    hintText: 'e.g., Weekly grocery shopping',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: [
                    'Groceries',
                    'Dairy',
                    'Meat',
                    'Produce',
                    'Bakery',
                    'Beverages',
                    'Snacks',
                    'Other'
                  ]
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Date'),
                  subtitle: Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey[400]!),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (amountController.text.isEmpty ||
                              descriptionController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill in all required fields'),
                              ),
                            );
                            return;
                          }

                          final amount = double.tryParse(amountController.text);
                          if (amount == null || amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a valid amount'),
                              ),
                            );
                            return;
                          }

                          // Create new expense
                          final expense = Budget(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            userId: 'user123', // TODO: Get from auth
                            amount: amount,
                            category: selectedCategory,
                            date: selectedDate,
                            description: descriptionController.text,
                            type: BudgetType.expense,
                          );

                          // Add to recent expenses and update spending
                          this.setState(() {
                            _recentExpenses.insert(0, expense);
                            _currentSpending += amount;
                            
                            // Update category spending
                            _weeklySpendingByCategory[selectedCategory] =
                                (_weeklySpendingByCategory[selectedCategory] ?? 0) + amount;
                          });

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Expense of \$${amount.toStringAsFixed(2)} added'),
                              backgroundColor: Colors.green,
                            ),
                          );

                          // Check budget alert after adding expense
                          final shoppingItems = ref.read(shoppingListProvider);
                          final estimatedCost = shoppingItems.fold<double>(
                            0,
                            (sum, item) => sum + (item.estimatedPrice ?? 0),
                          );
                          _checkBudgetAlert(estimatedCost);
                        },
                        child: const Text('Add Expense'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Made with Bob
