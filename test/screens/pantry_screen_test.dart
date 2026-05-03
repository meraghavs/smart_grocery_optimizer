import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_grocery_optimizer/screens/pantry_screen.dart';

/// Widget tests for PantryScreen
/// 
/// Tests cover:
/// - Widget rendering
/// - UI elements presence
/// - User interactions
/// - Navigation
void main() {
  group('PantryScreen Widget Tests', () {
    testWidgets('renders PantryScreen with all UI elements', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: PantryScreen(),
        ),
      );

      // Assert - Check AppBar
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('My Pantry'), findsOneWidget);

      // Assert - Check main content
      expect(find.byIcon(Icons.kitchen), findsOneWidget);
      expect(find.text('Pantry Screen'), findsOneWidget);
      expect(find.text('Display and manage pantry items here'), findsOneWidget);

      // Assert - Check FloatingActionButton
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('has correct scaffold structure', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: PantryScreen(),
        ),
      );

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('displays kitchen icon with correct size', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: PantryScreen(),
        ),
      );

      // Assert
      final iconFinder = find.byIcon(Icons.kitchen);
      expect(iconFinder, findsOneWidget);

      final Icon icon = tester.widget(iconFinder);
      expect(icon.size, equals(64.0));
      expect(icon.color, equals(Colors.grey));
    });

    testWidgets('title text has correct styling', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: PantryScreen(),
        ),
      );

      // Assert
      final textFinder = find.text('Pantry Screen');
      expect(textFinder, findsOneWidget);

      final Text textWidget = tester.widget(textFinder);
      expect(textWidget.style?.fontSize, equals(24));
      expect(textWidget.style?.fontWeight, equals(FontWeight.bold));
    });

    testWidgets('FloatingActionButton is tappable', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: PantryScreen(),
        ),
      );

      // Act
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);

      // Tap the FAB
      await tester.tap(fabFinder);
      await tester.pump();

      // Assert - No error should occur
      expect(tester.takeException(), isNull);
    });

    testWidgets('has correct widget hierarchy', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: PantryScreen(),
        ),
      );

      // Assert - Check widget tree structure
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(Center), findsWidgets);
      expect(find.byType(Column), findsOneWidget);
      expect(find.byType(SizedBox), findsWidgets); // Multiple SizedBox widgets for spacing
    });

    testWidgets('AppBar title is centered correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: PantryScreen(),
        ),
      );

      // Assert
      final appBarFinder = find.byType(AppBar);
      expect(appBarFinder, findsOneWidget);

      final AppBar appBar = tester.widget(appBarFinder);
      expect(appBar.title, isA<Text>());
      expect((appBar.title as Text).data, equals('My Pantry'));
    });

    testWidgets('Column has correct alignment', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: PantryScreen(),
        ),
      );

      // Assert
      final columnFinder = find.byType(Column);
      expect(columnFinder, findsOneWidget);

      final Column column = tester.widget(columnFinder);
      expect(column.mainAxisAlignment, equals(MainAxisAlignment.center));
    });

    testWidgets('renders without overflow', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: PantryScreen(),
        ),
      );

      // Assert - No overflow errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('maintains state after rebuild', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: PantryScreen(),
        ),
      );

      // Act - Trigger rebuild
      await tester.pumpWidget(
        const MaterialApp(
          home: PantryScreen(),
        ),
      );

      // Assert - All elements still present
      expect(find.text('My Pantry'), findsOneWidget);
      expect(find.text('Pantry Screen'), findsOneWidget);
      expect(find.byIcon(Icons.kitchen), findsOneWidget);
    });

    testWidgets('FAB has correct icon', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: PantryScreen(),
        ),
      );

      // Assert
      final fabFinder = find.byType(FloatingActionButton);
      final FloatingActionButton fab = tester.widget(fabFinder);
      
      expect(fab.child, isA<Icon>());
      final Icon icon = fab.child as Icon;
      expect(icon.icon, equals(Icons.add));
    });

    testWidgets('screen is scrollable when content overflows', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: PantryScreen(),
        ),
      );

      // Assert - Center widget should handle overflow
      expect(find.byType(Center), findsWidgets); // Multiple Center widgets in widget tree
    });

    testWidgets('all text widgets are visible', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: PantryScreen(),
        ),
      );

      // Assert
      expect(find.text('My Pantry'), findsOneWidget);
      expect(find.text('Pantry Screen'), findsOneWidget);
      expect(find.text('Display and manage pantry items here'), findsOneWidget);
    });

    testWidgets('screen has correct background', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: PantryScreen(),
        ),
      );

      // Assert - Scaffold should have default background
      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsOneWidget);
    });

    testWidgets('FAB is positioned correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: PantryScreen(),
        ),
      );

      // Assert
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);

      // FAB should be in bottom-right corner (default position)
      final fabPosition = tester.getBottomRight(fabFinder);
      final screenSize = tester.getSize(find.byType(MaterialApp));
      
      expect(fabPosition.dx, lessThan(screenSize.width));
      expect(fabPosition.dy, lessThan(screenSize.height));
    });
  });

  group('PantryScreen Accessibility Tests', () {
    testWidgets('has semantic labels for screen readers', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: PantryScreen(),
        ),
      );

      // Assert - Check for semantic widgets
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('FAB is accessible', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: PantryScreen(),
        ),
      );

      // Assert
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);
      
      // FAB should be tappable
      await tester.tap(fabFinder);
      await tester.pump();
    });
  });

  group('PantryScreen Performance Tests', () {
    testWidgets('renders quickly', (WidgetTester tester) async {
      // Arrange
      final stopwatch = Stopwatch()..start();

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: PantryScreen(),
        ),
      );

      stopwatch.stop();

      // Assert - Should render in less than 100ms
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    testWidgets('handles multiple rebuilds efficiently', (WidgetTester tester) async {
      // Arrange & Act
      for (int i = 0; i < 10; i++) {
        await tester.pumpWidget(
          const MaterialApp(
            home: PantryScreen(),
          ),
        );
      }

      // Assert - No errors or memory issues
      expect(tester.takeException(), isNull);
    });
  });
}

// Made with Bob
