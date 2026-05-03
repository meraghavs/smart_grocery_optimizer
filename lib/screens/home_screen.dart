import 'package:flutter/material.dart';

/// Home/Dashboard screen
/// 
/// Main screen showing:
/// - Quick stats
/// - Expiring items alerts
/// - Recent activity
/// - Quick actions
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // TODO: Import other screens
  // final List<Widget> _screens = [
  //   DashboardTab(),
  //   PantryScreen(),
  //   RecipeScreen(),
  //   ShoppingListScreen(),
  //   BudgetScreen(),
  // ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Grocery Optimizer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // TODO: Navigate to profile
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Home Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Welcome to Smart Grocery Optimizer'),
            const SizedBox(height: 24),
            // TODO: Implement dashboard widgets
            // TODO: Add expiry alerts
            // TODO: Add quick stats
            // TODO: Add quick actions
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: 'Pantry'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Recipes'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Shopping'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Budget'),
        ],
      ),
    );
  }
}
