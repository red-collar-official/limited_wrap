import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limited_wrap/limited_wrap.dart';

void main() {
  group('LimitedWrap - Interactive Widget Tests', () {
    testWidgets('show all button appears when content exceeds maxLines', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 150,
              child: UILimitedWrap(
                spacing: 8,
                runSpacing: 8,
                maxLines: 2,
                changeExpansionButton: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.blue,
                  child: const Text('Show All'),
                ),
                children: List.generate(
                  15,
                  (index) => Container(
                    width: 60,
                    height: 30,
                    color: Colors.red,
                    child: Center(child: Text('$index')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show "Show All" button
      expect(find.text('Show All'), findsOneWidget);

      // Count visible items (items with non-zero size)
      int visibleItems = 0;
      for (int i = 0; i < 15; i++) {
        final itemFinder = find.text('$i');
        if (itemFinder.evaluate().isNotEmpty) {
          final itemBox = tester.renderObject<RenderBox>(itemFinder);
          if (itemBox.size.width > 0 && itemBox.size.height > 0) {
            visibleItems++;
          }
        }
      }

      // Should have hidden some items (not all 15 visible)
      expect(visibleItems, lessThan(15));
      // Should have at least some items visible (more than 0)
      expect(visibleItems, greaterThan(0));
    });

    testWidgets('chip-like items with icons and text',
        (WidgetTester tester) async {
      Widget buildChip(String text) {
        return IntrinsicWidth(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              border: Border.all(color: Colors.blue),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.label, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    text,
                    style: const TextStyle(color: Colors.blue, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400, // Increased width to accommodate chips
              child: UILimitedWrap(
                spacing: 8,
                runSpacing: 8,
                maxLines: 2,
                changeExpansionButton: buildChip('Show All'),
                children: [
                  buildChip('Flutter'),
                  buildChip('Dart'),
                  buildChip('Mobile Dev'),
                  buildChip('UI/UX'),
                  buildChip('Android'),
                  buildChip('iOS'),
                  buildChip('Cross-platform'),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find all text labels
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Dart'), findsOneWidget);

      // Should find icons
      expect(find.byIcon(Icons.label), findsWidgets);
    });

    testWidgets('variable length text items from 1 to 40 chars',
        (WidgetTester tester) async {
      final items = <Widget>[];

      // Generate items with text from 1 to 40 characters (step 5)
      for (int i = 1; i <= 40; i += 5) {
        final text = 'A' * i;
        items.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Colors.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(text, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: UILimitedWrap(
                spacing: 8,
                runSpacing: 8,
                maxLines: 3,
                changeExpansionButton: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.orange,
                  child: const Text('More...'),
                ),
                children: items,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify wrap renders successfully with variable length items
      expect(find.byType(UILimitedWrap), findsOneWidget);

      // Should see the "More..." button since content exceeds maxLines
      expect(find.text('More...'), findsOneWidget);
    });

    testWidgets('handles dynamic content updates', (WidgetTester tester) async {
      List<String> items = ['Item 1', 'Item 2', 'Item 3'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SizedBox(
                  width: 300,
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            items.add('Item ${items.length + 1}');
                          });
                        },
                        child: const Text('Add Item'),
                      ),
                      UILimitedWrap(
                        spacing: 8,
                        runSpacing: 8,
                        maxLines: 2,
                        changeExpansionButton: const Text('Show All'),
                        children: items
                            .map(
                              (item) => Container(
                                padding: const EdgeInsets.all(8),
                                color: Colors.blue,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 4'), findsNothing);

      // Add more items
      await tester.tap(find.text('Add Item'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Item'));
      await tester.pumpAndSettle();

      // New items should be added
      expect(find.text('Item 4'), findsOneWidget);
      expect(find.text('Item 5'), findsOneWidget);
    });

    testWidgets('respects clipBehavior when content overflows',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 100, // Limited height to force overflow
              child: UILimitedWrap(
                spacing: 8,
                runSpacing: 8,
                clipBehavior: Clip.hardEdge,
                changeExpansionButton: const Text('Show All'),
                children: List.generate(
                  50,
                  (index) => Container(
                    width: 60,
                    height: 30,
                    color: Colors.purple,
                    child: Center(child: Text('$index')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Wrap should render despite overflow
      expect(find.byType(UILimitedWrap), findsOneWidget);
    });

    testWidgets('works with different sized containers',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: UILimitedWrap(
                spacing: 8,
                runSpacing: 8,
                maxLines: 2,
                changeExpansionButton: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red,
                  child: const Text('More'),
                ),
                children: [
                  Container(
                    width: 50,
                    height: 30,
                    color: Colors.blue,
                    child: const Center(child: Text('S')),
                  ),
                  Container(
                    width: 120,
                    height: 40,
                    color: Colors.green,
                    child: const Center(child: Text('Medium')),
                  ),
                  Container(
                    width: 80,
                    height: 25,
                    color: Colors.orange,
                    child: const Center(child: Text('Normal')),
                  ),
                  Container(
                    width: 150,
                    height: 50,
                    color: Colors.purple,
                    child: const Center(child: Text('Large Container')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // All different sized items should render
      expect(find.text('S'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);
    });
  });

  group('LimitedWrap - Real World Scenarios', () {
    testWidgets('tag selector with many tags', (WidgetTester tester) async {
      final tags = [
        'Flutter',
        'Dart',
        'Mobile',
        'Android',
        'iOS',
        'Web',
        'Desktop',
        'Material',
        'Cupertino',
        'Widgets',
        'State Management',
        'Provider',
        'BLoC',
        'Riverpod',
        'Animation',
        'UI/UX',
        'Performance',
        'Testing',
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: UILimitedWrap(
                spacing: 8,
                runSpacing: 8,
                maxLines: 3,
                changeExpansionButton: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Show All Tags',
                      style: TextStyle(color: Colors.white)),
                ),
                children: tags.map((tag) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(tag, style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render successfully
      expect(find.byType(UILimitedWrap), findsOneWidget);

      // Should show some tags
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Dart'), findsOneWidget);

      // Should show the "Show All Tags" button
      expect(find.text('Show All Tags'), findsOneWidget);
    });

    testWidgets('search result filters', (WidgetTester tester) async {
      final filters = [
        'Price: Low to High',
        'New',
        'Sale',
        'Free Shipping',
        '4+ Stars',
        'Prime',
        'Brand: Popular',
        'In Stock',
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: UILimitedWrap(
                spacing: 12,
                runSpacing: 12,
                maxLines: 2,
                changeExpansionButton: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('More Filters',
                          style: TextStyle(color: Colors.blue)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, color: Colors.blue),
                    ],
                  ),
                ),
                children: filters.map((filter) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border.all(color: Colors.blue[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(filter),
                        const SizedBox(width: 8),
                        const Icon(Icons.close, size: 16),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('More Filters'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    });
  });
}
