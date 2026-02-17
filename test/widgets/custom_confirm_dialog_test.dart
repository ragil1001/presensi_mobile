import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_mobile/core/widgets/custom_confirm_dialog.dart';

void main() {
  /// Helper to pump the dialog widget inside a MaterialApp with proper sizing.
  Widget buildDialog({
    String title = 'Test Title',
    String message = 'Test Message',
    String confirmText = 'OK',
    String cancelText = 'Batal',
    IconData? icon,
    Color? iconColor,
    bool isDestructive = false,
    bool showCancel = true,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: CustomConfirmDialog(
          title: title,
          message: message,
          confirmText: confirmText,
          cancelText: cancelText,
          icon: icon,
          iconColor: iconColor,
          isDestructive: isDestructive,
          showCancel: showCancel,
          onConfirm: onConfirm,
          onCancel: onCancel,
        ),
      ),
    );
  }

  group('CustomConfirmDialog', () {
    testWidgets('renders title and message text', (tester) async {
      await tester.pumpWidget(buildDialog(
        title: 'Konfirmasi',
        message: 'Apakah Anda yakin?',
      ));

      expect(find.text('Konfirmasi'), findsOneWidget);
      expect(find.text('Apakah Anda yakin?'), findsOneWidget);
    });

    testWidgets('shows confirm and cancel buttons by default',
        (tester) async {
      await tester.pumpWidget(buildDialog());

      // Default confirmText is 'OK', cancelText is 'Batal'
      expect(find.text('OK'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('hides cancel button when showCancel is false',
        (tester) async {
      await tester.pumpWidget(buildDialog(showCancel: false));

      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.text('Batal'), findsNothing);
      // Confirm button should still be present
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('uses custom confirmText and cancelText', (tester) async {
      await tester.pumpWidget(buildDialog(
        confirmText: 'Hapus',
        cancelText: 'Kembali',
      ));

      expect(find.text('Hapus'), findsOneWidget);
      expect(find.text('Kembali'), findsOneWidget);
    });

    testWidgets(
        'shows warning_amber_rounded icon when isDestructive is true',
        (tester) async {
      await tester.pumpWidget(buildDialog(isDestructive: true));

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('confirm button calls onConfirm and pops dialog',
        (tester) async {
      bool confirmCalled = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => CustomConfirmDialog(
                    title: 'Title',
                    message: 'Message',
                    onConfirm: () {
                      confirmCalled = true;
                    },
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      // Open the dialog
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // The dialog should be visible
      expect(find.text('Title'), findsOneWidget);

      // Tap the confirm button ('OK')
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(confirmCalled, isTrue);
      // Dialog should be dismissed
      expect(find.text('Title'), findsNothing);
    });

    testWidgets('cancel button calls onCancel and pops dialog',
        (tester) async {
      bool cancelCalled = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => CustomConfirmDialog(
                    title: 'Title',
                    message: 'Message',
                    onCancel: () {
                      cancelCalled = true;
                    },
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      // Open the dialog
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Title'), findsOneWidget);

      // Tap the cancel button ('Batal')
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(cancelCalled, isTrue);
      // Dialog should be dismissed
      expect(find.text('Title'), findsNothing);
    });

    testWidgets('custom icon is displayed when provided', (tester) async {
      await tester.pumpWidget(buildDialog(
        icon: Icons.info_outline_rounded,
      ));

      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
      // Default icons should not appear
      expect(find.byIcon(Icons.help_outline_rounded), findsNothing);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets(
        'default icon is help_outline_rounded when not destructive',
        (tester) async {
      await tester.pumpWidget(buildDialog(isDestructive: false));

      expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);
    });
  });
}
