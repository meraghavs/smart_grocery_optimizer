import 'package:flutter/material.dart';

/// Recipe Screen
/// 
/// Displays recipe recommendations based on expiring ingredients
/// Features:
/// - Recipe search by ingredients
/// - Recipe details view
/// - Expiry-aware recipe suggestions
class RecipeScreen extends StatelessWidget {
  const RecipeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.restaurant_menu,
              size: 100,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            const Text(
              'Recipe Finder',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Find recipes based on your expiring ingredients',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement recipe search
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Recipe search coming soon!'),
                  ),
                );
              },
              icon: const Icon(Icons.search),
              label: const Text('Search Recipes'),
            ),
          ],
        ),
      ),
    );
  }
}

// Made with Bob
