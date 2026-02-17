import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:presensi_mobile/providers/auth_provider.dart';
import 'package:presensi_mobile/features/auth/pages/login_page.dart';

// --------------------------------------------------------------------------
// Fake AuthProvider that satisfies `Consumer<AuthProvider>` and
// `Provider.of<AuthProvider>` without touching ApiClient, FlutterSecureStorage
// or Firebase (none of those platform channels exist in the test runner).
//
// `noSuchMethod` returns null for any member we did not explicitly override,
// avoiding the need to stub every single getter/method on the real class.
// --------------------------------------------------------------------------
class FakeAuthProvider with ChangeNotifier implements AuthProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  // ---- Members actually accessed during LoginPage build / initState ----

  @override
  String? get errorMessage => null;

  @override
  String? get errorType => null;

  @override
  void clearError() {}

  @override
  Future<String?> getRememberedUsername() async => null;

  @override
  Future<bool> shouldRemember() async => false;

  @override
  Future<bool> login(
    String username,
    String password, {
    bool rememberMe = false,
  }) async {
    return false;
  }
}

// --------------------------------------------------------------------------
// Helper that wraps LoginPage with the minimum provider / MaterialApp shell.
// --------------------------------------------------------------------------
Widget buildLoginPage() {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: FakeAuthProvider(),
    child: const MaterialApp(home: LoginPage()),
  );
}

void main() {
  // ------------------------------------------------------------------
  // 1. Renders login title
  // ------------------------------------------------------------------
  testWidgets('Renders login page with title text "Selamat Datang"',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildLoginPage());
    await tester.pumpAndSettle();

    expect(find.text('Selamat Datang'), findsOneWidget);
  });

  // ------------------------------------------------------------------
  // 2. Renders subtitle
  // ------------------------------------------------------------------
  testWidgets('Renders subtitle "Silakan login untuk melanjutkan"',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildLoginPage());
    await tester.pumpAndSettle();

    expect(find.text('Silakan login untuk melanjutkan'), findsOneWidget);
  });

  // ------------------------------------------------------------------
  // 3. Renders username and password fields with hint texts
  // ------------------------------------------------------------------
  testWidgets('Renders username and password text fields with hints',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildLoginPage());
    await tester.pumpAndSettle();

    // Label texts rendered above the fields
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    // Hint texts inside the TextFormFields
    expect(find.text('Masukkan username'), findsOneWidget);
    expect(find.text('Masukkan password'), findsOneWidget);

    // Two TextFormFields are present
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  // ------------------------------------------------------------------
  // 4. Renders "Ingat Saya" checkbox text
  // ------------------------------------------------------------------
  testWidgets('Renders "Ingat Saya" checkbox text',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildLoginPage());
    await tester.pumpAndSettle();

    expect(find.text('Ingat Saya'), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);
  });

  // ------------------------------------------------------------------
  // 5. Renders LOGIN button text
  // ------------------------------------------------------------------
  testWidgets('Renders LOGIN button text', (WidgetTester tester) async {
    await tester.pumpWidget(buildLoginPage());
    await tester.pumpAndSettle();

    expect(find.text('LOGIN'), findsOneWidget);
  });

  // ------------------------------------------------------------------
  // 6. Username validation error when empty and form submitted
  // ------------------------------------------------------------------
  testWidgets('Shows username validation error when empty and form submitted',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildLoginPage());
    await tester.pumpAndSettle();

    // Scroll LOGIN button into view before tapping (page is taller than 800x600 viewport)
    await tester.ensureVisible(find.text('LOGIN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('LOGIN'));
    await tester.pumpAndSettle();

    expect(find.text('Username tidak boleh kosong'), findsOneWidget);
  });

  // ------------------------------------------------------------------
  // 7. Password required error when empty
  // ------------------------------------------------------------------
  testWidgets('Shows password required error when empty',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildLoginPage());
    await tester.pumpAndSettle();

    // Fill in username so only the password error appears
    await tester.enterText(find.byType(TextFormField).at(0), 'testuser');
    await tester.pump();

    // Scroll LOGIN button into view before tapping
    await tester.ensureVisible(find.text('LOGIN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('LOGIN'));
    await tester.pumpAndSettle();

    expect(find.text('Password tidak boleh kosong'), findsOneWidget);
  });

  // ------------------------------------------------------------------
  // 8. Password min length error when less than 8 characters
  // ------------------------------------------------------------------
  testWidgets('Shows password min length error when less than 8 chars',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildLoginPage());
    await tester.pumpAndSettle();

    // Fill in username
    await tester.enterText(find.byType(TextFormField).at(0), 'testuser');
    await tester.pump();

    // Fill in a short password (less than 8 characters)
    await tester.enterText(find.byType(TextFormField).at(1), 'abc');
    await tester.pump();

    // Scroll LOGIN button into view before tapping
    await tester.ensureVisible(find.text('LOGIN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('LOGIN'));
    await tester.pumpAndSettle();

    expect(find.text('Password minimal 8 karakter'), findsOneWidget);
  });

  // ------------------------------------------------------------------
  // 9. Password field obscures text by default
  // ------------------------------------------------------------------
  testWidgets('Password field obscures text by default',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildLoginPage());
    await tester.pumpAndSettle();

    // The second TextFormField is the password field.
    // Fetch its internal EditableText and verify obscureText is true.
    final passwordEditableText = tester.widget<EditableText>(
      find.descendant(
        of: find.byType(TextFormField).at(1),
        matching: find.byType(EditableText),
      ),
    );

    expect(passwordEditableText.obscureText, isTrue);
  });

  // ------------------------------------------------------------------
  // 10. Password visibility toggling works
  // ------------------------------------------------------------------
  testWidgets('Password visibility toggling works',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildLoginPage());
    await tester.pumpAndSettle();

    // Initially the password is obscured -> visibility_off icon is shown
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    expect(find.byIcon(Icons.visibility_outlined), findsNothing);

    // Scroll toggle icon into view before tapping
    await tester.ensureVisible(find.byIcon(Icons.visibility_off_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pumpAndSettle();

    // Now the password is visible -> visibility icon is shown
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);

    // Scroll toggle icon into view before tapping
    await tester.ensureVisible(find.byIcon(Icons.visibility_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pumpAndSettle();

    // Back to obscured
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    expect(find.byIcon(Icons.visibility_outlined), findsNothing);
  });
}
