import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/budget.dart';
import '../models/shopping_list.dart';
import '../services/price_api.dart';

/// Budget tracking screen with real-time price fetching and analytics
/// 
/// Features:
/// - Real-time shopping list cost estimation
/// - Weekly spending bar chart by category
/// - Budget alerts at 80% threshold
/// - Category breakdown
/// - Monthly spending summary
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  // Services
  late final PriceApiService _priceApi;
  
  // State variables
  bool _isLoading = false;
  double _monthlyBudget = 500.0; // Default budget
  double _currentSpending = 0.0;
  double _estimatedShoppingListCost = 0.0;
  Map<String, double> _weeklySpendingByCategory = {};
  List<Budget> _recentExpenses = [];
  Map<String, dynamic>? _priceEstimation;
  
  // Mock shopping list for demonstration
  final List<Map<String, dynamic>> _mockShoppingList = [
    {'name': 'Milk', 'quantity': 2},
    {'name': 'Bread', 'quantity': 1},
    {'name': 'Eggs', 'quantity': 1},
    {'name': 'Cheese', 'quantity': 1},
    {'name': 'Chicken', 'quantity': 2},
    {'name': 'Rice', 'quantity': 1},
    {'name': 'Tomatoes', 'quantity': 3},
    {'name': 'Apples', 'quantity': 2},
  ];

  @override
  void initState() {
    super.initState();
    _priceApi = PriceApiService(
      apiKey: 'demo_key',
      baseUrl: 'https://api.pricefeeds.com',
    );
    _loadBudgetData();
  }

  /// Loads budget data and fetches real-time prices
  Future<void> _loadBudgetData() async {
    setState(() => _isLoading = true);

    try {
      // Fetch real-time prices for shopping list
      final estimation = await _priceApi.estimateTotalCost(
        items: _mockShoppingList,
      );

      // Mock current spending data (replace with Firebase data)
      _currentSpending = 342.50;
      
      // Mock weekly spending by category
      _weeklySpendingByCategory = {
        'Groceries': 120.50,
        'Dairy': 45.30,
        'Meat': 89.20,
        'Produce': 52.80,
        'Bakery': 34.70,
      };

      // Mock recent expenses
      _recentExpenses = [
        Budget(
          id: '1',
          userId: 'user123',
          amount: 45.67,
          category: 'Groceries',
          date: DateTime.now().subtract(const Duration(days: 1)),
          description: 'Weekly shopping',
          type: BudgetType.expense,
        ),
        Budget(
          id: '2',
          userId: 'user123',
          amount: 23.45,
          category: 'Dairy',
          date: DateTime.now().subtract(const Duration(days: 3)),
          description: 'Milk and cheese',
          type: BudgetType.expense,
        ),
      ];

      setState(() {
        _priceEstimation = estimation;
        _estimatedShoppingListCost = estimation['total'] as double;
        _isLoading = false;
      });

      // Check budget alert
      _checkBudgetAlert();
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
  void _checkBudgetAlert() {
    final projectedTotal = _currentSpending + _estimatedShoppingListCost;
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
              _checkBudgetAlert();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    _buildBudgetSummaryCard(),
                    const SizedBox(height: 16),
                    _buildShoppingListEstimateCard(),
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
  Widget _buildBudgetSummaryCard() {
    final projectedTotal = _currentSpending + _estimatedShoppingListCost;
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
                  '\$${_estimatedShoppingListCost.toStringAsFixed(2)}',
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

  /// Shopping list estimate card with real-time prices
  Widget _buildShoppingListEstimateCard() {
    if (_priceEstimation == null) {
      return const SizedBox.shrink();
    }

    final items = _priceEstimation!['items'] as List<Map<String, dynamic>>;
    final subtotal = _priceEstimation!['subtotal'] as double;
    final tax = _priceEstimation!['tax'] as double;
    final total = _priceEstimation!['total'] as double;

    return Card(
      elevation: 4,
      child: ExpansionTile(
        leading: const Icon(Icons.shopping_cart, color: Colors.blue),
        title: const Text(
          'Shopping List Estimate',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Total: \$${total.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item['name']} (${item['quantity']}x)',
                          style: TextStyle(
                            color: item['estimated'] == true
                                ? Colors.grey[600]
                                : Colors.black,
                          ),
                        ),
                      ),
                      Text(
                        '\$${(item['total'] as double).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )),
                const Divider(),
                _buildPriceRow('Subtotal', subtotal),
                _buildPriceRow('Tax (8%)', tax),
                const Divider(thickness: 2),
                _buildPriceRow('Total', total, bold: true),
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
    // TODO: Implement add expense dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add expense feature coming soon')),
    );
  }
}

// Made with Bob
