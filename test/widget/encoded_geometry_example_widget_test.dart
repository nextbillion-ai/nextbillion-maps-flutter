import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Simplified mock widget for testing UI components
class MockEncodedGeometryExample extends StatefulWidget {
  const MockEncodedGeometryExample({Key? key}) : super(key: key);

  @override
  State<MockEncodedGeometryExample> createState() => _MockEncodedGeometryExampleState();
}

class _MockEncodedGeometryExampleState extends State<MockEncodedGeometryExample> {
  bool _hasLine = false;
  final List<Widget> _markers = [];

  void _addEncodedLine() {
    setState(() {
      _hasLine = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Added encoded line with markers"),
      backgroundColor: Colors.blue,
      duration: Duration(seconds: 1),
    ));
  }

  void _updateEncodedLine() {
    if (!_hasLine) return;
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Updated line color to green"),
      backgroundColor: Colors.green,
      duration: Duration(seconds: 1),
    ));
  }

  void _clearLines() {
    setState(() {
      _hasLine = false;
      _markers.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Cleared all lines and markers"),
      backgroundColor: Colors.orange,
      duration: Duration(seconds: 1),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Encoded Geometry Test'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status: ${_hasLine ? "Line Added" : "No Line"}',
                  key: const Key('status_text'),
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.w500,
                    color: _hasLine ? Colors.green : Colors.grey,
                  ),
                ),
                Text(
                  'Markers: ${_markers.length}',
                  key: const Key('markers_text'),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.grey[200],
              child: const Center(
                child: Text('Map Placeholder'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            key: const Key('add_button'),
            onPressed: _hasLine ? null : _addEncodedLine,
            heroTag: "encoded",
            backgroundColor: _hasLine ? Colors.grey : Colors.red,
            child: const Icon(Icons.timeline, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            key: const Key('update_button'),
            onPressed: _hasLine ? _updateEncodedLine : null,
            heroTag: "update",
            backgroundColor: _hasLine ? Colors.purple : Colors.grey,
            child: const Icon(Icons.update, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            key: const Key('clear_button'),
            onPressed: _clearLines,
            heroTag: "clear",
            backgroundColor: Colors.orange,
            child: const Icon(Icons.clear, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

void main() {
  group('Encoded Geometry Example Widget Tests', () {
    testWidgets('should display encoded geometry example page', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockEncodedGeometryExample(),
        ),
      );

      // Verify the page is displayed
      expect(find.text('Encoded Geometry Test'), findsOneWidget);
      expect(find.byKey(const Key('status_text')), findsOneWidget);
      expect(find.byKey(const Key('markers_text')), findsOneWidget);
      expect(find.text('Status: No Line'), findsOneWidget);
      expect(find.text('Markers: 0'), findsOneWidget);
      
      // Verify floating action buttons
      expect(find.byKey(const Key('add_button')), findsOneWidget);
      expect(find.byKey(const Key('update_button')), findsOneWidget);
      expect(find.byKey(const Key('clear_button')), findsOneWidget);
    });

    testWidgets('should update status when add button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockEncodedGeometryExample(),
        ),
      );

      // Initial state
      expect(find.text('Status: No Line'), findsOneWidget);

      // Tap the add button
      await tester.tap(find.byKey(const Key('add_button')));
      await tester.pump();

      // Verify status is updated
      expect(find.text('Status: Line Added'), findsOneWidget);
    });

    testWidgets('should show success message after adding line', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockEncodedGeometryExample(),
        ),
      );

      // Tap the add button
      await tester.tap(find.byKey(const Key('add_button')));
      await tester.pump();

      // Verify success message appears
      expect(find.text('Added encoded line with markers'), findsOneWidget);
    });

    testWidgets('should allow update when line exists', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockEncodedGeometryExample(),
        ),
      );

      // First add a line
      await tester.tap(find.byKey(const Key('add_button')));
      await tester.pump();
      expect(find.text('Status: Line Added'), findsOneWidget);

      // Then update the line (should not change status but should work)
      await tester.tap(find.byKey(const Key('update_button')));
      await tester.pump();

      // Status should remain the same
      expect(find.text('Status: Line Added'), findsOneWidget);
    });

    testWidgets('should reset status when clear button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockEncodedGeometryExample(),
        ),
      );

      // Add a line first
      await tester.tap(find.byKey(const Key('add_button')));
      await tester.pump();
      expect(find.text('Status: Line Added'), findsOneWidget);

      // Clear lines
      await tester.tap(find.byKey(const Key('clear_button')));
      await tester.pump();

      // Verify status is reset
      expect(find.text('Status: No Line'), findsOneWidget);
    });

    testWidgets('should disable add button when line exists', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockEncodedGeometryExample(),
        ),
      );

      // Add a line
      await tester.tap(find.byKey(const Key('add_button')));
      await tester.pump();

      // Verify add button is disabled
      final addButton = tester.widget<FloatingActionButton>(find.byKey(const Key('add_button')));
      expect(addButton.onPressed, isNull);
      expect(addButton.backgroundColor, equals(Colors.grey));
    });

    testWidgets('should disable update button when no line exists', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockEncodedGeometryExample(),
        ),
      );

      // Verify update button is disabled initially
      final updateButton = tester.widget<FloatingActionButton>(find.byKey(const Key('update_button')));
      expect(updateButton.onPressed, isNull);
      expect(updateButton.backgroundColor, equals(Colors.grey));
    });

    testWidgets('should enable update button when line exists', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockEncodedGeometryExample(),
        ),
      );

      // Add a line
      await tester.tap(find.byKey(const Key('add_button')));
      await tester.pump();

      // Verify update button is enabled
      final updateButton = tester.widget<FloatingActionButton>(find.byKey(const Key('update_button')));
      expect(updateButton.onPressed, isNotNull);
      expect(updateButton.backgroundColor, equals(Colors.purple));
    });

    testWidgets('should always enable clear button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockEncodedGeometryExample(),
        ),
      );

      // Verify clear button is always enabled
      final clearButton = tester.widget<FloatingActionButton>(find.byKey(const Key('clear_button')));
      expect(clearButton.onPressed, isNotNull);
      expect(clearButton.backgroundColor, equals(Colors.orange));
    });

    testWidgets('should maintain state consistency throughout operations', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockEncodedGeometryExample(),
        ),
      );

      // Initial state
      expect(find.text('Status: No Line'), findsOneWidget);
      expect(find.text('Markers: 0'), findsOneWidget);

      // Add line
      await tester.tap(find.byKey(const Key('add_button')));
      await tester.pump();

      // State after adding
      expect(find.text('Status: Line Added'), findsOneWidget);

      // Clear lines
      await tester.tap(find.byKey(const Key('clear_button')));
      await tester.pump();

      // State after clearing
      expect(find.text('Status: No Line'), findsOneWidget);
      expect(find.text('Markers: 0'), findsOneWidget);
    });

    testWidgets('should not allow update when no line exists', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockEncodedGeometryExample(),
        ),
      );

      // Try to tap update button when no line exists
      await tester.tap(find.byKey(const Key('update_button')));
      await tester.pump();

      // Should not show update message
      expect(find.text('Updated line color to green'), findsNothing);
      expect(find.text('Status: No Line'), findsOneWidget);
    });

    testWidgets('should handle multiple operations correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockEncodedGeometryExample(),
        ),
      );

      // Add line
      await tester.tap(find.byKey(const Key('add_button')));
      await tester.pump();
      expect(find.text('Status: Line Added'), findsOneWidget);

      // Update line
      await tester.tap(find.byKey(const Key('update_button')));
      await tester.pump();
      expect(find.text('Status: Line Added'), findsOneWidget); // Status should remain

      // Clear lines
      await tester.tap(find.byKey(const Key('clear_button')));
      await tester.pump();
      expect(find.text('Status: No Line'), findsOneWidget);

      // Add line again
      await tester.tap(find.byKey(const Key('add_button')));
      await tester.pump();
      expect(find.text('Status: Line Added'), findsOneWidget);
    });
  });

  group('Encoded Geometry Button State Tests', () {
    testWidgets('should have correct button states initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockEncodedGeometryExample(),
        ),
      );

      // Check initial button states
      final addButton = tester.widget<FloatingActionButton>(find.byKey(const Key('add_button')));
      final updateButton = tester.widget<FloatingActionButton>(find.byKey(const Key('update_button')));
      final clearButton = tester.widget<FloatingActionButton>(find.byKey(const Key('clear_button')));

      expect(addButton.onPressed, isNotNull); // Add should be enabled
      expect(addButton.backgroundColor, equals(Colors.red));

      expect(updateButton.onPressed, isNull); // Update should be disabled
      expect(updateButton.backgroundColor, equals(Colors.grey));

      expect(clearButton.onPressed, isNotNull); // Clear should always be enabled
      expect(clearButton.backgroundColor, equals(Colors.orange));
    });

    testWidgets('should have correct button states after adding line', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockEncodedGeometryExample(),
        ),
      );

      // Add a line
      await tester.tap(find.byKey(const Key('add_button')));
      await tester.pump();

      // Check button states after adding
      final addButton = tester.widget<FloatingActionButton>(find.byKey(const Key('add_button')));
      final updateButton = tester.widget<FloatingActionButton>(find.byKey(const Key('update_button')));
      final clearButton = tester.widget<FloatingActionButton>(find.byKey(const Key('clear_button')));

      expect(addButton.onPressed, isNull); // Add should be disabled
      expect(addButton.backgroundColor, equals(Colors.grey));

      expect(updateButton.onPressed, isNotNull); // Update should be enabled
      expect(updateButton.backgroundColor, equals(Colors.purple));

      expect(clearButton.onPressed, isNotNull); // Clear should always be enabled
      expect(clearButton.backgroundColor, equals(Colors.orange));
    });
  });
}