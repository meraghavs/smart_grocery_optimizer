import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_grocery_optimizer/models/shopping_list.dart';
import 'package:smart_grocery_optimizer/providers/shopping_list_provider.dart';
import 'package:smart_grocery_optimizer/providers/pantry_provider.dart';
import 'package:smart_grocery_optimizer/screens/scanner_screen.dart';

/// Shopping list management screen
/// 
/// Features:
/// - Create and manage shopping lists
/// - AI-powered suggestions
/// - Check off items
/// - Price estimation
/// - Share lists
/// - Camera scanning for quick item addition

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  @override
  Widget build(BuildContext context) {
    final shoppingItems = ref.watch(shoppingListProvider);
    final purchasedItems = shoppingItems.where((item) => item.isPurchased).toList();
    final totalEstimated = shoppingItems.fold<double>(
      0,
      (sum, item) => sum + (item.estimatedPrice ?? 0),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            tooltip: 'Scan items',
            onPressed: _openScanner,
          ),
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
                    'Tap + to add items or camera to scan',
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
                      
                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.startToEnd,
                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          color: Colors.green,
                          child: const Row(
                            children: [
                              Icon(Icons.kitchen, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Move to Pantry',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        onDismissed: (direction) async {
                          await _moveToPantry(item);
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          child: InkWell(
                            onLongPress: () => _showContextMenu(context, item),
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
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showEditItemDialog(item),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      ref.read(shoppingListProvider.notifier).removeItem(item.id);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('${item.name} removed')),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Move item to pantry with undo option
  Future<bool> _moveToPantry(ShoppingListItem item) async {
    final pantryItem = await ref.read(shoppingListProvider.notifier).moveToPantry(item.id);
    
    if (pantryItem != null && mounted) {
      // Wait a moment for Firestore to propagate
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Reload pantry to show the new item
      await ref.read(pantryProvider.notifier).reloadAfterTransfer();
      
      // Show snackbar with undo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} moved to Pantry'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Undo',
            textColor: Colors.white,
            onPressed: () async {
              // Undo: move back to shopping list
              final shoppingItem = await ref.read(pantryProvider.notifier).moveToShoppingList(item.id);
              if (shoppingItem != null) {
                await Future.delayed(const Duration(milliseconds: 500));
                await ref.read(shoppingListProvider.notifier).reloadAfterTransfer();
              }
            },
          ),
        ),
        );
      }
      return true;
    }
    return false;
  }

  /// Show context menu for item actions
  void _showContextMenu(BuildContext context, ShoppingListItem item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.kitchen, color: Colors.green),
              title: const Text('Move to Pantry'),
              onTap: () {
                Navigator.pop(context);
                _moveToPantry(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart, color: Colors.grey),
              title: const Text('Move to Shopping List'),
              enabled: false,
              subtitle: const Text('Already in shopping list'),
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit Item'),
              onTap: () {
                Navigator.pop(context);
                _showEditItemDialog(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Item'),
              onTap: () {
                Navigator.pop(context);
                ref.read(shoppingListProvider.notifier).removeItem(item.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item.name} removed')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Open scanner screen to scan items with camera
  Future<void> _openScanner() async {
    try {
      final scannedItems = await Navigator.push<List<String>>(
        context,
        MaterialPageRoute(
          builder: (context) => const ScannerScreen(),
        ),
      );

      if (scannedItems != null && scannedItems.isNotEmpty && mounted) {
        _showAddScannedItemsDialog(scannedItems);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open scanner: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show dialog to add scanned items to shopping list
  void _showAddScannedItemsDialog(List<String> scannedItems) {
    String selectedUnit = 'pcs';
    String selectedCategory = 'Other';
    final quantityController = TextEditingController(text: '1');

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
                    const Icon(Icons.camera_alt, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text(
                      'Add Scanned Items',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${scannedItems.length} item(s) detected',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Set default quantity and category for all items:',
                  style: TextStyle(fontWeight: FontWeight.w500),
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
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Items to add:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: scannedItems.length,
                    itemBuilder: (context, index) => Card(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.shopping_basket, size: 20),
                        title: Text(
                          scannedItems[index],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
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
                          final quantity =
                              double.tryParse(quantityController.text) ?? 1;

                          for (final itemName in scannedItems) {
                            final item = ShoppingListItem(
                              id: '${DateTime.now().millisecondsSinceEpoch}_${scannedItems.indexOf(itemName)}',
                              userId: 'user1',
                              name: itemName,
                              category: selectedCategory,
                              quantity: quantity,
                              unit: selectedUnit,
                              estimatedPrice: null,
                              isPurchased: false,
                              addedDate: DateTime.now(),
                              notes: 'Added via camera scan',
                            );

                            ref.read(shoppingListProvider.notifier).addItem(item);
                          }

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${scannedItems.length} item(s) added to shopping list',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        child: const Text('Add All'),
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

  void _showAddItemDialog() {
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
                            userId: 'user1',
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

  void _showEditItemDialog(ShoppingListItem item) {
    final nameController = TextEditingController(text: item.name);
    final quantityController = TextEditingController(text: item.quantity.toString());
    final priceController = TextEditingController(
      text: item.estimatedPrice?.toString() ?? '',
    );
    final notesController = TextEditingController(text: item.notes ?? '');
    String selectedUnit = item.unit;
    String selectedCategory = item.category;

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
                  'Edit Shopping Item',
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

                          final updatedItem = ShoppingListItem(
                            id: item.id,
                            userId: item.userId,
                            name: nameController.text,
                            category: selectedCategory,
                            quantity: double.tryParse(quantityController.text) ?? 1,
                            unit: selectedUnit,
                            estimatedPrice: priceController.text.isNotEmpty
                                ? double.tryParse(priceController.text)
                                : null,
                            isPurchased: item.isPurchased,
                            addedDate: item.addedDate,
                            notes: notesController.text.isNotEmpty
                                ? notesController.text
                                : null,
                          );

                          ref.read(shoppingListProvider.notifier).updateItem(updatedItem);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${updatedItem.name} updated')),
                          );
                        },
                        child: const Text('Save Changes'),
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
