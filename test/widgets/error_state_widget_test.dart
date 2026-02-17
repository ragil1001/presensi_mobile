import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_mobile/core/widgets/error_state_widget.dart';

void main() {
  /// Helper to pump ErrorStateWidget inside a MaterialApp with sufficient size.
  Widget buildWidget({
    String message = 'Terjadi kesalahan',
    IconData icon = Icons.error_outline_rounded,
    VoidCallback? onRetry,
    String retryText = 'Coba Lagi',
    bool compact = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 600,
          child: ErrorStateWidget(
            message: message,
            icon: icon,
            onRetry: onRetry,
            retryText: retryText,
            compact: compact,
          ),
        ),
      ),
    );
  }

  group('ErrorStateWidget - Full mode', () {
    testWidgets('renders message text', (tester) async {
      await tester.pumpWidget(buildWidget(
        message: 'Gagal memuat data',
      ));

      expect(find.text('Gagal memuat data'), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry is provided',
        (tester) async {
      await tester.pumpWidget(buildWidget(
        onRetry: () {},
      ));

      // ElevatedButton.icon() may create a subclass; use byWidgetPredicate
      expect(find.byWidgetPredicate((w) => w is ElevatedButton), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    });

    testWidgets('hides retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(buildWidget(
        onRetry: null,
      ));

      expect(find.byWidgetPredicate((w) => w is ElevatedButton), findsNothing);
      expect(find.text('Coba Lagi'), findsNothing);
    });

    testWidgets('retry button calls onRetry when tapped', (tester) async {
      bool retryCalled = false;

      await tester.pumpWidget(buildWidget(
        onRetry: () {
          retryCalled = true;
        },
      ));

      await tester.tap(find.text('Coba Lagi'));
      await tester.pump();

      expect(retryCalled, isTrue);
    });

    testWidgets('displays custom icon when provided', (tester) async {
      await tester.pumpWidget(buildWidget(
        icon: Icons.wifi_off_rounded,
      ));

      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    });
  });

  group('ErrorStateWidget - Compact mode', () {
    testWidgets('renders in compact layout', (tester) async {
      await tester.pumpWidget(buildWidget(
        message: 'Error kompak',
        compact: true,
      ));

      expect(find.text('Error kompak'), findsOneWidget);
      // Compact mode should not use Center as its root
      // It uses a Container directly
      expect(find.byType(ErrorStateWidget), findsOneWidget);
    });

    testWidgets('shows retry TextButton when onRetry is provided',
        (tester) async {
      await tester.pumpWidget(buildWidget(
        compact: true,
        onRetry: () {},
      ));

      // TextButton.icon() may create a subclass; use byWidgetPredicate
      expect(find.byWidgetPredicate((w) => w is TextButton), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    });

    testWidgets('hides retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(buildWidget(
        compact: true,
        onRetry: null,
      ));

      expect(find.byWidgetPredicate((w) => w is TextButton), findsNothing);
      expect(find.byWidgetPredicate((w) => w is ElevatedButton), findsNothing);
    });
  });

  group('ErrorStateWidget - retryText', () {
    testWidgets('default retryText is Coba Lagi', (tester) async {
      await tester.pumpWidget(buildWidget(
        onRetry: () {},
      ));

      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets('custom retryText is displayed', (tester) async {
      await tester.pumpWidget(buildWidget(
        onRetry: () {},
        retryText: 'Muat Ulang',
      ));

      expect(find.text('Muat Ulang'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsNothing);
    });
  });
}
