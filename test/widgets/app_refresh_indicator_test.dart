import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_mobile/core/widgets/app_refresh_indicator.dart';

void main() {
  // Helper to build a minimal app with AppRefreshIndicator.
  // RefreshIndicator requires a scrollable child, so we use a ListView.
  Widget buildApp({
    Future<void> Function()? onRefresh,
    Widget? childContent,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: AppRefreshIndicator(
          onRefresh: onRefresh ?? () async {},
          child: ListView(
            children: [childContent ?? const Text('Test Content')],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // 1. Renders child widget
  // ------------------------------------------------------------------
  testWidgets('Renders the child widget passed to AppRefreshIndicator',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildApp(
      childContent: const Text('Hello World'),
    ));

    expect(find.text('Hello World'), findsOneWidget);
  });

  // ------------------------------------------------------------------
  // 2. Contains a RefreshIndicator
  // ------------------------------------------------------------------
  testWidgets('Contains a RefreshIndicator widget',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildApp());

    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  // ------------------------------------------------------------------
  // 3. Child is accessible and visible
  // ------------------------------------------------------------------
  testWidgets('Child content is accessible and visible in the tree',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildApp(
      childContent: const Icon(Icons.star, key: Key('star-icon')),
    ));

    expect(find.byKey(const Key('star-icon')), findsOneWidget);
    expect(find.byIcon(Icons.star), findsOneWidget);
  });

  // ------------------------------------------------------------------
  // 4. RefreshIndicator has correct styling properties
  // ------------------------------------------------------------------
  testWidgets('RefreshIndicator has correct strokeWidth and displacement',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildApp());

    final refreshIndicator = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator),
    );

    expect(refreshIndicator.strokeWidth, 2.5);
    expect(refreshIndicator.displacement, 40);
    expect(refreshIndicator.backgroundColor, Colors.white);
  });
}
