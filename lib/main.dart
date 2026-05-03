import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_grocery_optimizer/screens/pantry_screen.dart';
import 'package:smart_grocery_optimizer/screens/shopping_list_screen.dart';
import 'package:smart_grocery_optimizer/screens/recipe_screen.dart';
import 'package:smart_grocery_optimizer/screens/budget_screen.dart';

/// Main entry point for Smart Grocery Optimizer
///
/// Initializes:
/// - Firebase for backend services (optional for development)
/// - Riverpod for state management
/// - App routes and navigation
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (optional - will continue without it for development)
  try {
    await Firebase.initializeApp();
    debugPrint('✓ Firebase initialized successfully');
  } catch (e) {
    debugPrint('⚠ Firebase initialization failed: $e');
    debugPrint('⚠ App will run without Firebase features');
    debugPrint('⚠ To enable Firebase, add google-services.json to android/app/');
  }
  
  runApp(
    const ProviderScope(
      child: SmartGroceryOptimizerApp(),
    ),
  );
}

/// Root application widget
class SmartGroceryOptimizerApp extends StatelessWidget {
  const SmartGroceryOptimizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Grocery Optimizer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const MainNavigationScreen(),
      routes: {
        '/pantry': (context) => const PantryScreen(),
        '/shopping-list': (context) => const ShoppingListScreen(),
        '/recipes': (context) => const RecipeScreen(),
        '/budget': (context) => const BudgetScreen(),
      },
    );
  }
}

/// Main navigation screen with bottom navigation bar
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    PantryScreen(),
    RecipeScreen(),
    ShoppingListScreen(),
    BudgetScreen(),
  ];

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.kitchen_outlined),
      selectedIcon: Icon(Icons.kitchen),
      label: 'Pantry',
    ),
    NavigationDestination(
      icon: Icon(Icons.restaurant_menu_outlined),
      selectedIcon: Icon(Icons.restaurant_menu),
      label: 'Recipes',
    ),
    NavigationDestination(
      icon: Icon(Icons.shopping_cart_outlined),
      selectedIcon: Icon(Icons.shopping_cart),
      label: 'Shopping',
    ),
    NavigationDestination(
      icon: Icon(Icons.account_balance_wallet_outlined),
      selectedIcon: Icon(Icons.account_balance_wallet),
      label: 'Budget',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: _destinations,
      ),
    );
  }
}

// Made with Bob
