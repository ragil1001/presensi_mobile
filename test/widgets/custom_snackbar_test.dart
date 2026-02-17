import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_mobile/core/widgets/custom_snackbar.dart';

void main() {
  // Helper that builds a minimal MaterialApp with a button to trigger
  // a snackbar.  MaterialApp provides the Overlay required by the
  // CustomSnackbar implementation.
  Widget buildApp(void Function(BuildContext) onPressed) {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => onPressed(context),
                child: const Text('Trigger'),
              ),
            ),
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------------
  // 1. showSuccess displays "Berhasil" title and message
  // ------------------------------------------------------------------
  testWidgets('showSuccess displays "Berhasil" title and message',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildApp((ctx) {
      CustomSnackbar.showSuccess(ctx, 'Operasi berhasil');
    }));

    await tester.tap(find.text('Trigger'));
    await tester.pumpAndSettle();

    expect(find.text('Berhasil'), findsOneWidget);
    expect(find.text('Operasi berhasil'), findsOneWidget);

    // Advance past the 3-second Future.delayed timer to avoid "Timer still pending"
    await tester.pump(const Duration(seconds: 4));
  });

  // ------------------------------------------------------------------
  // 2. showError displays "Gagal" title and message
  // ------------------------------------------------------------------
  testWidgets('showError displays "Gagal" title and message',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildApp((ctx) {
      CustomSnackbar.showError(ctx, 'Terjadi kesalahan');
    }));

    await tester.tap(find.text('Trigger'));
    await tester.pumpAndSettle();

    expect(find.text('Gagal'), findsOneWidget);
    expect(find.text('Terjadi kesalahan'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
  });

  // ------------------------------------------------------------------
  // 3. showWarning displays "Peringatan" title and message
  // ------------------------------------------------------------------
  testWidgets('showWarning displays "Peringatan" title and message',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildApp((ctx) {
      CustomSnackbar.showWarning(ctx, 'Harap perhatikan');
    }));

    await tester.tap(find.text('Trigger'));
    await tester.pumpAndSettle();

    expect(find.text('Peringatan'), findsOneWidget);
    expect(find.text('Harap perhatikan'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
  });

  // ------------------------------------------------------------------
  // 4. showInfo displays "Informasi" title and message
  // ------------------------------------------------------------------
  testWidgets('showInfo displays "Informasi" title and message',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildApp((ctx) {
      CustomSnackbar.showInfo(ctx, 'Ini informasi');
    }));

    await tester.tap(find.text('Trigger'));
    await tester.pumpAndSettle();

    expect(find.text('Informasi'), findsOneWidget);
    expect(find.text('Ini informasi'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
  });

  // ------------------------------------------------------------------
  // 5. Close button dismisses the snackbar
  // ------------------------------------------------------------------
  testWidgets('Close button dismisses the snackbar',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildApp((ctx) {
      CustomSnackbar.showSuccess(ctx, 'Dismiss me');
    }));

    // Show the snackbar
    await tester.tap(find.text('Trigger'));
    await tester.pumpAndSettle();

    // Verify it is visible
    expect(find.text('Berhasil'), findsOneWidget);
    expect(find.text('Dismiss me'), findsOneWidget);

    // Tap the close icon (Icons.close) to dismiss
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Verify the snackbar has been removed
    expect(find.text('Berhasil'), findsNothing);
    expect(find.text('Dismiss me'), findsNothing);

    // Advance past the 3-second Future.delayed timer
    await tester.pump(const Duration(seconds: 4));
  });

  // ------------------------------------------------------------------
  // 6. SnackbarType enum has exactly 4 values
  // ------------------------------------------------------------------
  test('SnackbarType enum has 4 values', () {
    expect(SnackbarType.values.length, 4);
    expect(SnackbarType.values, contains(SnackbarType.success));
    expect(SnackbarType.values, contains(SnackbarType.error));
    expect(SnackbarType.values, contains(SnackbarType.warning));
    expect(SnackbarType.values, contains(SnackbarType.info));
  });
}
