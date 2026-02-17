import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_mobile/core/widgets/shimmer_loading.dart';

void main() {
  group('ShimmerLoading', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerLoading(
              child: SizedBox(width: 100, height: 20),
            ),
          ),
        ),
      );

      // The child SizedBox should be present in the tree
      expect(find.byType(SizedBox), findsWidgets);
      expect(find.byType(ShimmerLoading), findsOneWidget);
    });

    testWidgets('uses ShaderMask in widget tree', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerLoading(
              child: SizedBox(width: 100, height: 20),
            ),
          ),
        ),
      );

      // ShimmerLoading builds an AnimatedBuilder wrapping a ShaderMask
      expect(find.byType(ShaderMask), findsOneWidget);
    });
  });

  group('ShimmerBox', () {
    testWidgets('renders with specified width and height', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerBox(width: 200, height: 50),
          ),
        ),
      );

      expect(find.byType(ShimmerBox), findsOneWidget);

      // Verify the underlying Container has the correct size
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ShimmerBox),
          matching: find.byType(Container),
        ),
      );
      expect(container.constraints?.maxWidth, 200);
      expect(container.constraints?.maxHeight, 50);
    });

    testWidgets('uses default borderRadius of 8.0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerBox(width: 100, height: 20),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ShimmerBox),
          matching: find.byType(Container),
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(8.0));
    });

    testWidgets('renders with custom borderRadius', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerBox(width: 100, height: 20, borderRadius: 16.0),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ShimmerBox),
          matching: find.byType(Container),
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(16.0));
    });
  });

  group('ShimmerLoading with ShimmerBox', () {
    testWidgets('wrapping ShimmerBox renders correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerLoading(
              child: ShimmerBox(width: 150, height: 30),
            ),
          ),
        ),
      );

      expect(find.byType(ShimmerLoading), findsOneWidget);
      expect(find.byType(ShimmerBox), findsOneWidget);
      expect(find.byType(ShaderMask), findsOneWidget);
    });
  });
}
