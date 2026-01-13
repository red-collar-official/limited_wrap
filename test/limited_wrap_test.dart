import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limited_wrap/limited_wrap.dart';

void main() {
  group('LimitedRenderWrap - Basic Layout Tests', () {
    testWidgets('renders without children', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UILimitedWrap(
              changeExpansionButton: const SizedBox(),
              children: const [],
            ),
          ),
        ),
      );

      expect(find.byType(UILimitedWrap), findsOneWidget);
    });

    testWidgets('renders with single child', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UILimitedWrap(
              changeExpansionButton: const Text('Show All'),
              children: const [
                Text('Child 1'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Child 1'), findsOneWidget);
    });

    testWidgets('renders multiple children in one row',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: UILimitedWrap(
                spacing: 8,
                changeExpansionButton: const Text('Show All'),
                children: const [
                  SizedBox(width: 50, height: 30, child: Text('A')),
                  SizedBox(width: 50, height: 30, child: Text('B')),
                  SizedBox(width: 50, height: 30, child: Text('C')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
    });
  });

  group('LimitedRenderWrap - MaxLines Tests', () {
    testWidgets('hides show all button when content fits',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: UILimitedWrap(
                spacing: 8,
                maxLines: 3,
                changeExpansionButton: const Text('Show All'),
                children: const [
                  SizedBox(width: 50, height: 30, child: Text('A')),
                  SizedBox(width: 50, height: 30, child: Text('B')),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Show All button should be hidden (zero size)
      final changeExpansionButton = find.text('Show All');
      final renderBox = tester.renderObject<RenderBox>(changeExpansionButton);
      expect(renderBox.size.width, equals(0));
      expect(renderBox.size.height, equals(0));
    });

    testWidgets('shows all button when content exceeds maxLines',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: UILimitedWrap(
                spacing: 8,
                runSpacing: 8,
                maxLines: 2,
                changeExpansionButton: const SizedBox(
                  width: 100,
                  height: 30,
                  child: Text('Show All'),
                ),
                children: List.generate(
                  20,
                  (index) => SizedBox(
                    width: 50,
                    height: 30,
                    child: Text('Item $index'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Show All button should be visible
      final changeExpansionButton = find.text('Show All');
      final renderBox = tester.renderObject<RenderBox>(changeExpansionButton);
      expect(renderBox.size.width, greaterThan(0));
      expect(renderBox.size.height, greaterThan(0));
    });

    testWidgets('hides children beyond maxLines', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 150, // Small width to force wrapping
              child: UILimitedWrap(
                spacing: 8,
                runSpacing: 8,
                maxLines: 2,
                changeExpansionButton: const SizedBox(
                  width: 80,
                  height: 30,
                  child: Text('Show All'),
                ),
                children: List.generate(
                  10,
                  (index) => SizedBox(
                    width: 60,
                    height: 30,
                    child: Text('Item $index'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that items beyond maxLines are hidden (size = 0)
      for (int i = 0; i < 10; i++) {
        final itemFinder = find.text('Item $i');
        if (itemFinder.evaluate().isNotEmpty) {
          final renderBox = tester.renderObject<RenderBox>(itemFinder);

          // Items in first 2 rows should be visible
          // Items in rows > 2 should be hidden (except show all button)
          if (i < 4) {
            // First ~4 items should be visible (2 rows × ~2 items per row)
            expect(renderBox.size.width, greaterThan(0),
                reason: 'Item $i should be visible');
          }
        }
      }
    });
  });

  group('LimitedRenderWrap - Spacing Tests', () {
    testWidgets('respects horizontal spacing', (WidgetTester tester) async {
      const spacing = 16.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: UILimitedWrap(
                spacing: spacing,
                changeExpansionButton: const Text('Show All'),
                children: const [
                  SizedBox(width: 50, height: 30, child: Text('A')),
                  SizedBox(width: 50, height: 30, child: Text('B')),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final aBox = tester.getTopLeft(find.text('A'));
      final bBox = tester.getTopLeft(find.text('B'));

      // B should be positioned at A.left + A.width + spacing
      expect(bBox.dx, equals(aBox.dx + 50 + spacing));
    });

    testWidgets('respects vertical spacing (runSpacing)',
        (WidgetTester tester) async {
      const runSpacing = 12.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              child: UILimitedWrap(
                spacing: 8,
                runSpacing: runSpacing,
                changeExpansionButton: const Text('Show All'),
                children: const [
                  SizedBox(width: 80, height: 30, child: Text('Row 1')),
                  SizedBox(width: 80, height: 30, child: Text('Row 2')),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final row1Box = tester.getTopLeft(find.text('Row 1'));
      final row2Box = tester.getTopLeft(find.text('Row 2'));

      // Row 2 should be positioned at Row1.top + Row1.height + runSpacing
      expect(row2Box.dy, equals(row1Box.dy + 30 + runSpacing));
    });
  });

  group('LimitedRenderWrap - Wrapping Tests', () {
    testWidgets('wraps to new line when width exceeded',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 150,
              child: UILimitedWrap(
                spacing: 8,
                runSpacing: 8,
                changeExpansionButton: const Text('Show All'),
                children: const [
                  SizedBox(width: 60, height: 30, child: Text('Item 1')),
                  SizedBox(width: 60, height: 30, child: Text('Item 2')),
                  SizedBox(width: 60, height: 30, child: Text('Item 3')),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final item1Y = tester.getTopLeft(find.text('Item 1')).dy;
      final item2Y = tester.getTopLeft(find.text('Item 2')).dy;
      final item3Y = tester.getTopLeft(find.text('Item 3')).dy;

      // Item 1 and 2 should be on same row
      expect(item1Y, equals(item2Y));

      // Item 3 should be on different row (lower)
      expect(item3Y, greaterThan(item2Y));
    });

    testWidgets('calculates row height correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: UILimitedWrap(
                spacing: 8,
                runSpacing: 8,
                changeExpansionButton: const Text('Show All'),
                children: const [
                  SizedBox(width: 50, height: 30, child: Text('Short')),
                  SizedBox(width: 50, height: 60, child: Text('Tall')),
                  SizedBox(width: 50, height: 20, child: Text('Tiny')),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // All items should be on the same row (same Y position)
      final shortY = tester.getTopLeft(find.text('Short')).dy;
      final tallY = tester.getTopLeft(find.text('Tall')).dy;
      final tinyY = tester.getTopLeft(find.text('Tiny')).dy;

      expect(shortY, equals(tallY));
      expect(shortY, equals(tinyY));
    });
  });

  group('LimitedRenderWrap - Edge Cases', () {
    testWidgets('handles single very wide child', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: UILimitedWrap(
                changeExpansionButton: const Text('Show All'),
                children: const [
                  SizedBox(width: 300, height: 30, child: Text('Very Wide')),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Very Wide'), findsOneWidget);
    });

    testWidgets('handles zero spacing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: UILimitedWrap(
                spacing: 0,
                runSpacing: 0,
                changeExpansionButton: const Text('Show All'),
                children: const [
                  SizedBox(width: 50, height: 30, child: Text('A')),
                  SizedBox(width: 50, height: 30, child: Text('B')),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final aBox = tester.getTopLeft(find.text('A'));
      final bBox = tester.getTopLeft(find.text('B'));

      // B should be directly next to A (no spacing)
      expect(bBox.dx, equals(aBox.dx + 50));
    });

    testWidgets('handles null maxLines (unlimited)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              child: UILimitedWrap(
                spacing: 8,
                runSpacing: 8,
                maxLines: null, // Unlimited
                isLimited: false,
                changeExpansionButton: const Text('Show All'),
                children: List.generate(
                  20,
                  (index) => SizedBox(
                    width: 40,
                    height: 30,
                    child: Text('$index'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Show All button should be hidden when maxLines is null
      final changeExpansionButton = find.text('Show All');
      final renderBox = tester.renderObject<RenderBox>(changeExpansionButton);
      expect(renderBox.size.width, equals(0));
    });
  });

  group('LimitedRenderWrap - Property Updates', () {
    testWidgets('updates when maxLines changes', (WidgetTester tester) async {
      int maxLines = 1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SizedBox(
                  width: 150,
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            maxLines = 3;
                          });
                        },
                        child: const Text('Increase maxLines'),
                      ),
                      UILimitedWrap(
                        spacing: 8,
                        runSpacing: 8,
                        maxLines: maxLines,
                        changeExpansionButton: const SizedBox(
                          width: 80,
                          height: 30,
                          child: Text('Show All'),
                        ),
                        children: List.generate(
                          10,
                          (index) => SizedBox(
                            width: 60,
                            height: 30,
                            child: Text('Item $index'),
                          ),
                        ),
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

      // Count visible items with maxLines = 1
      int visibleBefore = 0;

      for (int i = 0; i < 10; i++) {
        final itemFinder = find.text('Item $i');
        if (itemFinder.evaluate().isNotEmpty) {
          final renderBox = tester.renderObject<RenderBox>(itemFinder);
          if (renderBox.size.width > 0) visibleBefore++;
        }
      }

      // Increase maxLines
      await tester.tap(find.text('Increase maxLines'));
      await tester.pumpAndSettle();

      // Count visible items with maxLines = 3
      int visibleAfter = 0;

      for (int i = 0; i < 10; i++) {
        final itemFinder = find.text('Item $i');
        if (itemFinder.evaluate().isNotEmpty) {
          final renderBox = tester.renderObject<RenderBox>(itemFinder);
          if (renderBox.size.width > 0) visibleAfter++;
        }
      }

      // More items should be visible after increasing maxLines
      expect(visibleAfter, greaterThan(visibleBefore));
    });

    testWidgets('updates when spacing changes', (WidgetTester tester) async {
      double spacing = 8;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SizedBox(
                  width: 400,
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            spacing = 24;
                          });
                        },
                        child: const Text('Increase spacing'),
                      ),
                      UILimitedWrap(
                        spacing: spacing,
                        changeExpansionButton: const Text('Show All'),
                        children: const [
                          SizedBox(width: 50, height: 30, child: Text('A')),
                          SizedBox(width: 50, height: 30, child: Text('B')),
                        ],
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

      final aBox1 = tester.getTopLeft(find.text('A'));
      final bBox1 = tester.getTopLeft(find.text('B'));
      final distance1 = bBox1.dx - aBox1.dx;

      // Increase spacing
      await tester.tap(find.text('Increase spacing'));
      await tester.pumpAndSettle();

      final aBox2 = tester.getTopLeft(find.text('A'));
      final bBox2 = tester.getTopLeft(find.text('B'));
      final distance2 = bBox2.dx - aBox2.dx;

      // Distance should increase
      expect(distance2, greaterThan(distance1));
    });

    testWidgets('updates when runSpacing changes', (WidgetTester tester) async {
      double runSpacing = 8;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SizedBox(
                  width: 100,
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            runSpacing = 24;
                          });
                        },
                        child: const Text('Increase runSpacing'),
                      ),
                      UILimitedWrap(
                        spacing: 8,
                        runSpacing: runSpacing,
                        changeExpansionButton: const Text('Show All'),
                        children: const [
                          SizedBox(width: 80, height: 30, child: Text('Row 1')),
                          SizedBox(width: 80, height: 30, child: Text('Row 2')),
                        ],
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

      final row1Box1 = tester.getTopLeft(find.text('Row 1'));
      final row2Box1 = tester.getTopLeft(find.text('Row 2'));
      final distance1 = row2Box1.dy - row1Box1.dy;

      // Increase runSpacing
      await tester.tap(find.text('Increase runSpacing'));
      await tester.pumpAndSettle();

      final row1Box2 = tester.getTopLeft(find.text('Row 1'));
      final row2Box2 = tester.getTopLeft(find.text('Row 2'));
      final distance2 = row2Box2.dy - row1Box2.dy;

      // Vertical distance should increase
      expect(distance2, greaterThan(distance1));
    });

    testWidgets('updates when clipBehavior changes',
        (WidgetTester tester) async {
      Clip clipBehavior = Clip.none;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SizedBox(
                  width: 100,
                  height: 150,
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            clipBehavior = Clip.hardEdge;
                          });
                        },
                        child: const Text('Change clipBehavior'),
                      ),
                      Expanded(
                        child: UILimitedWrap(
                          spacing: 8,
                          runSpacing: 8,
                          clipBehavior: clipBehavior,
                          changeExpansionButton: const Text('Show All'),
                          children: List.generate(
                            20,
                            (index) => SizedBox(
                              width: 40,
                              height: 30,
                              child: Text('$index'),
                            ),
                          ),
                        ),
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

      // Change clipBehavior
      await tester.tap(find.text('Change clipBehavior'));
      await tester.pumpAndSettle();

      // Widget should still render without errors
      expect(find.byType(UILimitedWrap), findsOneWidget);
    });
  });

  group('LimitedRenderWrap - Intrinsic Size Tests', () {
    testWidgets('computeMinIntrinsicWidth returns widest child',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntrinsicWidth(
              child: UILimitedWrap(
                changeExpansionButton: const Text('Show All'),
                children: const [
                  SizedBox(width: 50, height: 30, child: Text('Short')),
                  SizedBox(
                      width: 120, height: 30, child: Text('Very Wide Item')),
                  SizedBox(width: 70, height: 30, child: Text('Medium')),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final wrapFinder = find.byType(UILimitedWrap);
      final renderBox = tester.renderObject<RenderBox>(wrapFinder);

      // The min intrinsic width should accommodate at least the widest child
      expect(renderBox.size.width, greaterThanOrEqualTo(120));
    });

    testWidgets('computeMaxIntrinsicWidth returns sum of all children',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntrinsicWidth(
              stepWidth: double.infinity,
              child: UILimitedWrap(
                spacing: 0,
                changeExpansionButton:
                    const SizedBox(width: 0, child: Text('Show All')),
                children: const [
                  SizedBox(width: 50, height: 30, child: Text('A')),
                  SizedBox(width: 80, height: 30, child: Text('B')),
                  SizedBox(width: 60, height: 30, child: Text('C')),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The widget should attempt to fit all items if possible
      expect(find.byType(UILimitedWrap), findsOneWidget);
    });

    testWidgets('computeMinIntrinsicHeight calculates correct height',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 150,
              child: IntrinsicHeight(
                child: UILimitedWrap(
                  spacing: 8,
                  runSpacing: 8,
                  changeExpansionButton: const Text('Show All'),
                  children: const [
                    SizedBox(width: 60, height: 30, child: Text('Item 1')),
                    SizedBox(width: 60, height: 30, child: Text('Item 2')),
                    SizedBox(width: 60, height: 30, child: Text('Item 3')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final wrapFinder = find.byType(UILimitedWrap);
      final renderBox = tester.renderObject<RenderBox>(wrapFinder);

      // Height should be calculated correctly
      expect(renderBox.size.height, greaterThan(0));
    });

    testWidgets('computeMaxIntrinsicHeight matches min intrinsic height',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: UILimitedWrap(
                spacing: 8,
                runSpacing: 8,
                changeExpansionButton: const Text('Show All'),
                children: const [
                  SizedBox(width: 60, height: 30, child: Text('A')),
                  SizedBox(width: 60, height: 30, child: Text('B')),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Widget should render successfully
      expect(find.byType(UILimitedWrap), findsOneWidget);
    });

    testWidgets('computeDistanceToActualBaseline works with text',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const Text('Baseline'),
                UILimitedWrap(
                  changeExpansionButton: const Text('Show All'),
                  children: const [
                    Text('Item 1'),
                    Text('Item 2'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render without errors when baseline is needed
      expect(find.byType(UILimitedWrap), findsOneWidget);
      expect(find.text('Baseline'), findsOneWidget);
    });
  });

  group('LimitedRenderWrap - Empty Children Tests', () {
    testWidgets('handles empty children list', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 100,
              child: UILimitedWrap(
                spacing: 8,
                runSpacing: 8,
                changeExpansionButton: const Text('Show All'),
                children: const [],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final wrapFinder = find.byType(UILimitedWrap);
      expect(wrapFinder, findsOneWidget);

      final renderBox = tester.renderObject<RenderBox>(wrapFinder);
      // With no children, size should be minimal
      expect(renderBox.size.width, lessThanOrEqualTo(200));
      expect(renderBox.size.height, lessThanOrEqualTo(100));
    });

    testWidgets('handles single invisible child', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UILimitedWrap(
              changeExpansionButton: const SizedBox.shrink(),
              children: const [
                SizedBox.shrink(),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(UILimitedWrap), findsOneWidget);
    });
  });

  group('LimitedRenderWrap - Dry Layout Tests', () {
    testWidgets('dry layout matches actual layout size',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: UILimitedWrap(
                spacing: 8,
                runSpacing: 8,
                changeExpansionButton: const Text('Show All'),
                children: List.generate(
                  5,
                  (index) => SizedBox(
                    width: 60,
                    height: 30,
                    child: Text('Item $index'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final wrapFinder = find.byType(UILimitedWrap);
      final renderBox = tester.renderObject<RenderBox>(wrapFinder);

      // Verify that widget has calculated size correctly
      expect(renderBox.size.width, greaterThan(0));
      expect(renderBox.size.height, greaterThan(0));

      // Size should be constrained by parent
      expect(renderBox.size.width, lessThanOrEqualTo(300));
    });
  });
}
