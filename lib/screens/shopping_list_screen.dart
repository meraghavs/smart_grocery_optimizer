import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_grocery_optimizer/models/shopping_list.dart';
import 'package:smart_grocery_optimizer/providers/shopping_list_provider.dart';

/// Shopping list management screen
/// 
/// Features:
/// - Create and manage shopping lists
/// - AI-powered suggestions
/// - Check off items
/// - Price estimation
/// - Share lists

class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingItems = ref.watch(shoppingListProvider);
    final purchasedItems = shoppingItems.where((item) => item.isPurchased).toList();
    final pendingItems = shoppingItems.where((item) => !item.isPurchased).toList();
    final totalEstimated = shoppingItems.fold<double>(
      0,
      (sum, item) => sum + (item.estimatedPrice ?? 0),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        actions: [
          if (purchasedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear purchased items',
              onPressed: () {
                ref.read(shoppingListProvider.notifier).clearPurchased();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Purchased items cleared')),
                );
              },
            ),
        ],
      ),
      body: shoppingItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Shopping list is empty',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add items',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                if (totalEstimated > 0)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Estimated Total:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${totalEstimated.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: shoppingItems.length,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context, index) {
                      final item = shoppingItems[index];
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: ListTile(
                          leading: Checkbox(
                            value: item.isPurchased,
                            onChanged: (value) {
                              ref.read(shoppingListProvider.notifier).togglePurchased(item.id);
                            },
                          ),
                          title: Text(
                            item.name,
                            style: TextStyle(
                              decoration: item.isPurchased
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: Text(
                            '${item.quantity} ${item.unit}${item.estimatedPrice != null ? ' • \$${item.estimatedPrice!.toStringAsFixed(2)}' : ''}',
                            style: TextStyle(
                              decoration: item.isPurchased
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              ref.read(shoppingListProvider.notifier).removeItem(item.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${item.name} removed')),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final priceController = TextEditingController();
    final notesController = TextEditingController();
    String selectedUnit = 'pcs';
    String selectedCategory = 'Other';

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
                const Text(
                  'Add Shopping Item',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.shopping_bag),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedUnit,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(),
                        ),
                        items: ['pcs', 'kg', 'g', 'L', 'ml', 'lb', 'oz']
                            .map((unit) => DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedUnit = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: [
                    'Dairy',
                    'Meat',
                    'Vegetables',
                    'Fruits',
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
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Estimated Price (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 2,
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
                          if (nameController.text.isEmpty ||
                              quantityController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill in all required fields'),
                              ),
                            );
                            return;
                          }

                          final item = ShoppingListItem(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            userId: 'user1', // TODO: Get from auth
                            name: nameController.text,
                            category: selectedCategory,
                            quantity: double.tryParse(quantityController.text) ?? 1,
                            unit: selectedUnit,
                            estimatedPrice: priceController.text.isNotEmpty
                                ? double.tryParse(priceController.text)
                                : null,
                            isPurchased: false,
                            addedDate: DateTime.now(),
                            notes: notesController.text.isNotEmpty
                                ? notesController.text
                                : null,
                          );

                          ref.read(shoppingListProvider.notifier).addItem(item);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${item.name} added to shopping list')),
                          );
                        },
                        child: const Text('Add Item'),
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
