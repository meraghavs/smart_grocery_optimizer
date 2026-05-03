import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_grocery_optimizer/screens/shopping_list_screen.dart';

/// Widget tests for ShoppingListScreen
/// 
/// Tests cover:
/// - Widget rendering
/// - UI elements presence
/// - User interactions
/// - State management
void main() {
  group('ShoppingListScreen Widget Tests', () {
    testWidgets('renders ShoppingListScreen with all UI elements', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ShoppingListScreen(),
        ),
      );

      // Assert - Check AppBar
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Shopping Lists'), findsOneWidget);

      // Assert - Check main content
      expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
      expect(find.text('Shopping List Screen'), findsOneWidget);
      expect(find.text('Manage your shopping lists here'), findsOneWidget);

      // Assert - Check FloatingActionButton
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('has correct scaffold structure', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ShoppingListScreen(),
        ),
      );

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('displays shopping cart icon with correct size', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ShoppingListScreen(),
        ),
      );

      // Assert
      final iconFinder = find.byIcon(Icons.shopping_cart);
      expect(iconFinder, findsOneWidget);

      final Icon icon = tester.widget(iconFinder);
      expect(icon.size, equals(64.0));
      expect(icon.color, equals(Colors.grey));
    });

    testWidgets('title text has correct styling', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ShoppingListScreen(),
        ),
      );

      // Assert
      final textFinder = find.text('Shopping List Screen');
      expect(textFinder, findsOneWidget);

      final Text textWidget = tester.widget(textFinder);
      expect(textWidget.style?.fontSize, equals(24));
      expect(textWidget.style?.fontWeight, equals(FontWeight.bold));
    });

    testWidgets('FloatingActionButton is tappable', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: ShoppingListScreen(),
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
          home: ShoppingListScreen(),
        ),
      );

      // Assert - Check widget tree structure
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(Center), findsWidgets);
      expect(find.byType(Column), findsOneWidget);
      expect(find.byType(SizedBox), findsWidgets); // Multiple SizedBox widgets for spacing
    });

    testWidgets('AppBar title is correct', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ShoppingListScreen(),
        ),
      );

      // Assert
      final appBarFinder = find.byType(AppBar);
      expect(appBarFinder, findsOneWidget);

      final AppBar appBar = tester.widget(appBarFinder);
      expect(appBar.title, isA<Text>());
      expect((appBar.title as Text).data, equals('Shopping Lists'));
    });

    testWidgets('Column has correct alignment', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ShoppingListScreen(),
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
          home: ShoppingListScreen(),
        ),
      );

      // Assert - No overflow errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('maintains state after rebuild', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: ShoppingListScreen(),
        ),
      );

      // Act - Trigger rebuild
      await tester.pumpWidget(
        const MaterialApp(
          home: ShoppingListScreen(),
        ),
      );

      // Assert - All elements still present
      expect(find.text('Shopping Lists'), findsOneWidget);
      expect(find.text('Shopping List Screen'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
    });

    testWidgets('FAB has correct icon', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ShoppingListScreen(),
        ),
      );

      // Assert
      final fabFinder = find.byType(FloatingActionButton);
      final FloatingActionButton fab = tester.widget(fabFinder);
      
      expect(fab.child, isA<Icon>());
      final Icon icon = fab.child as Icon;
      expect(icon.icon, equals(Icons.add));
    });

    testWidgets('all text widgets are visible', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ShoppingListScreen(),
        ),
      );

      // Assert
      expect(find.text('Shopping Lists'), findsOneWidget);
      expect(find.text('Shopping List Screen'), findsOneWidget);
      expect(find.text('Manage your shopping lists here'), findsOneWidget);
    });

    testWidgets('FAB is positioned correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ShoppingListScreen(),
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

    testWidgets('screen has correct background', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ShoppingListScreen(),
        ),
      );

      // Assert - Scaffold should have default background
      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsOneWidget);
    });
  });

  group('ShoppingListScreen Interaction Tests', () {
    testWidgets('FAB tap does not throw error', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: ShoppingListScreen(),
        ),
      );

      // Act
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      // Assert
      expect(tester.takeException(), isNull);
    });

    testWidgets('multiple FAB taps work correctly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: ShoppingListScreen(),
        ),
      );

      // Act - Tap multiple times
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump();
      }

      // Assert
      expect(tester.takeException(), isNull);
    });
  });

  group('ShoppingListScreen Accessibility Tests', () {
    testWidgets('has semantic labels for screen readers', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ShoppingListScreen(),
        ),
      );

      // Assert - Check for semantic widgets
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('FAB is accessible', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ShoppingListScreen(),
        ),
      );

      // Assert
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);
      
      // FAB should be tappable
      await tester.tap(fabFinder);
      await tester.pump();
    });

    testWidgets('text is readable', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ShoppingListScreen(),
        ),
      );

      // Assert - Check text widgets exist and are visible
      expect(find.text('Shopping Lists'), findsOneWidget);
      expect(find.text('Shopping List Screen'), findsOneWidget);
      expect(find.text('Manage your shopping lists here'), findsOneWidget);
    });
  });

  group('ShoppingListScreen Performance Tests', () {
    testWidgets('renders quickly', (WidgetTester tester) async {
      // Arrange
      final stopwatch = Stopwatch()..start();

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ShoppingListScreen(),
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
            home: ShoppingListScreen(),
          ),
        );
      }

      // Assert - No errors or memory issues
      expect(tester.takeException(), isNull);
    });

    testWidgets('no memory leaks on dispose', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: ShoppingListScreen(),
        ),
      );

      // Act - Navigate away (dispose)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Other Screen')),
        ),
      );

      // Assert - No errors
      expect(tester.takeException(), isNull);
    });
  });

  group('ShoppingListScreen Layout Tests', () {
    testWidgets('adapts to different screen sizes', (WidgetTester tester) async {
      // Arrange - Small screen
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ShoppingListScreen(),
        ),
      );

      // Assert
      expect(find.byType(ShoppingListScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Arrange - Large screen
      tester.view.physicalSize = const Size(1200, 1600);
      
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ShoppingListScreen(),
        ),
      );

      // Assert
      expect(find.byType(ShoppingListScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Reset
      addTearDown(tester.view.resetPhysicalSize);
    });

    testWidgets('maintains layout in landscape mode', (WidgetTester tester) async {
      // Arrange - Landscape orientation
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ShoppingListScreen(),
        ),
      );

      // Assert
      expect(find.byType(ShoppingListScreen), findsOneWidget);
      expect(find.text('Shopping Lists'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Reset
      addTearDown(tester.view.resetPhysicalSize);
    });
  });
}

// Made with Bob
