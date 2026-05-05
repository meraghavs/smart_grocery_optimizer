import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_grocery_optimizer/models/grocery_item.dart';
import 'package:smart_grocery_optimizer/providers/pantry_provider.dart';
import 'package:smart_grocery_optimizer/providers/shopping_list_provider.dart';
import 'package:smart_grocery_optimizer/screens/scanner_screen.dart';

/// Pantry management screen
/// 
/// Displays all pantry items with features:
/// - List/grid view of items
/// - Filter by category and expiry date
/// - Search functionality
/// - Add/edit/delete items
/// - Scan new items

class PantryScreen extends ConsumerStatefulWidget {
  const PantryScreen({super.key});

  @override
  ConsumerState<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends ConsumerState<PantryScreen> {
  @override
  Widget build(BuildContext context) {
    final pantryItems = ref.watch(pantryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pantry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: pantryItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.kitchen, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No items in pantry',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first item',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
             itemCount: pantryItems.length,
             padding: const EdgeInsets.all(8),
             itemBuilder: (context, index) {
               final item = pantryItems[index];
               final daysUntilExpiry = item.expiryDate.difference(DateTime.now()).inDays;
               final isExpiringSoon = daysUntilExpiry <= 7;
               
               return Dismissible(
                 key: Key(item.id),
                 direction: DismissDirection.startToEnd,
                 background: Container(
                   alignment: Alignment.centerLeft,
                   padding: const EdgeInsets.only(left: 20),
                   color: Colors.green,
                   child: const Row(
                     children: [
                       Icon(Icons.shopping_cart, color: Colors.white),
                       SizedBox(width: 8),
                       Text(
                         'Move to Shopping List',
                         style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                       ),
                     ],
                   ),
                 ),
                 onDismissed: (direction) async {
                   await _moveToShoppingList(item);
                 },
                 child: Card(
                   margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                   child: InkWell(
                     onLongPress: () => _showContextMenu(context, item),
                     child: ListTile(
                       leading: CircleAvatar(
                         backgroundColor: isExpiringSoon ? Colors.orange : Colors.green,
                         child: Text(
                           item.name[0].toUpperCase(),
                           style: const TextStyle(color: Colors.white),
                         ),
                       ),
                       title: Text(item.name),
                       subtitle: Text(
                         '${item.quantity} ${item.unit} • Expires in $daysUntilExpiry days',
                         style: TextStyle(
                           color: isExpiringSoon ? Colors.orange : null,
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
                               ref.read(pantryProvider.notifier).removeItem(item.id);
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'camera_fab',
            onPressed: _openScanner,
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'add_fab',
            onPressed: _showAddItemDialog,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
 }

 /// Move item to shopping list with undo option
 Future<bool> _moveToShoppingList(GroceryItem item) async {
   final shoppingItem = await ref.read(pantryProvider.notifier).moveToShoppingList(item.id);
   
   if (shoppingItem != null && mounted) {
     // Wait a moment for Firestore to propagate
     await Future.delayed(const Duration(milliseconds: 500));
     
     // Reload shopping list to show the new item
     await ref.read(shoppingListProvider.notifier).reloadAfterTransfer();
     
     // Show snackbar with undo
     if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(
         content: Text('${item.name} moved to Shopping List'),
         backgroundColor: Colors.green,
         action: SnackBarAction(
           label: 'Undo',
           textColor: Colors.white,
           onPressed: () async {
             // Undo: move back to pantry
             final pantryItem = await ref.read(shoppingListProvider.notifier).moveToPantry(item.id);
             if (pantryItem != null) {
               await Future.delayed(const Duration(milliseconds: 500));
               await ref.read(pantryProvider.notifier).reloadAfterTransfer();
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
  void _showContextMenu(BuildContext context, GroceryItem item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.shopping_cart, color: Colors.green),
              title: const Text('Move to Shopping List'),
              onTap: () {
                Navigator.pop(context);
                _moveToShoppingList(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.kitchen, color: Colors.grey),
              title: const Text('Move to Pantry'),
              enabled: false,
              subtitle: const Text('Already in pantry'),
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
                ref.read(pantryProvider.notifier).removeItem(item.id);
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

  /// Open scanner and show detected items in bottom sheet
  Future<void> _openScanner() async {
    final detectedItems = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );

    if (detectedItems != null && detectedItems.isNotEmpty && mounted) {
      _showDetectedItemsBottomSheet(detectedItems);
    }
  }

  /// Show bottom sheet with detected items and checkboxes
  void _showDetectedItemsBottomSheet(List<String> detectedItems) {
    final selectedItems = <String, bool>{
      for (var item in detectedItems) item: true,
    };

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text(
                    'Detected Items',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        final allSelected = selectedItems.values.every((v) => v);
                        for (var key in selectedItems.keys) {
                          selectedItems[key] = !allSelected;
                        }
                      });
                    },
                    child: Text(
                      selectedItems.values.every((v) => v)
                          ? 'Deselect All'
                          : 'Select All',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Select items to add to your pantry:',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: detectedItems.length,
                  itemBuilder: (context, index) {
                    final item = detectedItems[index];
                    return CheckboxListTile(
                      title: Text(item),
                      value: selectedItems[item] ?? false,
                      onChanged: (value) {
                        setState(() {
                          selectedItems[item] = value ?? false;
                        });
                      },
                      secondary: const Icon(Icons.shopping_basket),
                    );
                  },
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
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text(
                        'Add ${selectedItems.values.where((v) => v).length} Items',
                      ),
                      onPressed: () {
                        final itemsToAdd = selectedItems.entries
                            .where((entry) => entry.value)
                            .map((entry) => entry.key)
                            .toList();

                        if (itemsToAdd.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select at least one item'),
                            ),
                          );
                          return;
                        }

                        // Add items to pantry with default values
                        for (var itemName in itemsToAdd) {
                          final item = GroceryItem(
                            id: DateTime.now().millisecondsSinceEpoch.toString() +
                                itemName.hashCode.toString(),
                            userId: 'user1', // TODO: Get from auth
                            name: itemName,
                            category: 'Other',
                            quantity: 1,
                            unit: 'pcs',
                            expiryDate: DateTime.now().add(const Duration(days: 7)),
                            purchaseDate: DateTime.now(),
                            price: 0,
                          );
                          ref.read(pantryProvider.notifier).addItem(item);
                        }

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${itemsToAdd.length} items added to pantry'),
                            action: SnackBarAction(
                              label: 'View',
                              onPressed: () {},
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final priceController = TextEditingController();
    String selectedUnit = 'pcs';
    String selectedCategory = 'Other';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

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
                  'Add Pantry Item',
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
                    labelText: 'Price',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Expiry Date'),
                  subtitle: Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
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
                          if (nameController.text.isEmpty ||
                              quantityController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill in all required fields'),
                              ),
                            );
                            return;
                          }

                          final item = GroceryItem(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            userId: 'user1', // TODO: Get from auth
                            name: nameController.text,
                            category: selectedCategory,
                            quantity: int.tryParse(quantityController.text) ?? 1,
                            unit: selectedUnit,
                            expiryDate: selectedDate,
                            purchaseDate: DateTime.now(),
                            price: double.tryParse(priceController.text) ?? 0,
                          );

                          ref.read(pantryProvider.notifier).addItem(item);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${item.name} added to pantry')),
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

  void _showEditItemDialog(GroceryItem item) {
    final nameController = TextEditingController(text: item.name);
    final quantityController = TextEditingController(text: item.quantity.toString());
    final priceController = TextEditingController(text: item.price.toString());
    String selectedUnit = item.unit;
    String selectedCategory = item.category;
    DateTime selectedDate = item.expiryDate;

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
                    const Icon(Icons.edit, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
                      'Edit Pantry Item',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
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
                    labelText: 'Price',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Expiry Date'),
                  subtitle: Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
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
                          if (nameController.text.isEmpty ||
                              quantityController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill in all required fields'),
                              ),
                            );
                            return;
                          }

                          final updatedItem = GroceryItem(
                            id: item.id,
                            userId: item.userId,
                            name: nameController.text,
                            category: selectedCategory,
                            quantity: int.tryParse(quantityController.text) ?? 1,
                            unit: selectedUnit,
                            expiryDate: selectedDate,
                            purchaseDate: item.purchaseDate,
                            price: double.tryParse(priceController.text) ?? 0,
                          );

                          ref.read(pantryProvider.notifier).updateItem(updatedItem);
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
