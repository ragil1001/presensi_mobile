import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_mobile/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthProvider', () {
    late AuthProvider provider;

    setUp(() {
      provider = AuthProvider();
    });

    group('initial state', () {
      test('state is AuthState.initial', () {
        expect(provider.state, equals(AuthState.initial));
      });

      test('currentUser is null', () {
        expect(provider.currentUser, isNull);
      });

      test('token is null', () {
        expect(provider.token, isNull);
      });

      test('errorMessage is null', () {
        expect(provider.errorMessage, isNull);
      });

      test('errorType is null', () {
        expect(provider.errorType, isNull);
      });

      test('isLoading is false', () {
        expect(provider.isLoading, isFalse);
      });

      test('isAuthenticated is false', () {
        expect(provider.isAuthenticated, isFalse);
      });
    });

    group('AuthState enum', () {
      test('AuthState.initial exists', () {
        expect(AuthState.initial, isNotNull);
      });

      test('AuthState.loading exists', () {
        expect(AuthState.loading, isNotNull);
      });

      test('AuthState.authenticated exists', () {
        expect(AuthState.authenticated, isNotNull);
      });

      test('AuthState.unauthenticated exists', () {
        expect(AuthState.unauthenticated, isNotNull);
      });

      test('AuthState.error exists', () {
        expect(AuthState.error, isNotNull);
      });

      test('AuthState has exactly 5 values', () {
        expect(AuthState.values.length, equals(5));
      });

      test('AuthState values are in expected order', () {
        expect(AuthState.values, equals([
          AuthState.initial,
          AuthState.loading,
          AuthState.authenticated,
          AuthState.unauthenticated,
          AuthState.error,
        ]));
      });
    });

    group('isAuthenticated getter', () {
      test('returns false when state is initial', () {
        // Initial state is AuthState.initial
        expect(provider.state, equals(AuthState.initial));
        expect(provider.isAuthenticated, isFalse);
      });

      test('returns false for all non-authenticated states', () {
        // We can only test the initial state without API calls.
        // The getter is defined as: _state == AuthState.authenticated
        // Since initial state is AuthState.initial, isAuthenticated is false.
        expect(provider.state, isNot(equals(AuthState.authenticated)));
        expect(provider.isAuthenticated, isFalse);
      });

      test('isAuthenticated mirrors state == AuthState.authenticated', () {
        // Verify the relationship: isAuthenticated should be equivalent to
        // state == AuthState.authenticated
        final isAuth = provider.isAuthenticated;
        final stateCheck = provider.state == AuthState.authenticated;
        expect(isAuth, equals(stateCheck));
      });
    });

    group('isLoading getter', () {
      test('returns false when state is initial', () {
        expect(provider.state, equals(AuthState.initial));
        expect(provider.isLoading, isFalse);
      });

      test('isLoading mirrors state == AuthState.loading', () {
        final isLoad = provider.isLoading;
        final stateCheck = provider.state == AuthState.loading;
        expect(isLoad, equals(stateCheck));
      });
    });

    group('clearError', () {
      test('sets errorMessage to null', () {
        provider.clearError();
        expect(provider.errorMessage, isNull);
      });

      test('sets errorType to null', () {
        provider.clearError();
        expect(provider.errorType, isNull);
      });

      test('notifies listeners when called', () {
        int notifyCount = 0;
        provider.addListener(() {
          notifyCount++;
        });

        provider.clearError();

        expect(notifyCount, equals(1));
      });

      test('does not change auth state when clearing error', () {
        final stateBefore = provider.state;
        provider.clearError();
        expect(provider.state, equals(stateBefore));
      });

      test('does not change token when clearing error', () {
        final tokenBefore = provider.token;
        provider.clearError();
        expect(provider.token, equals(tokenBefore));
      });

      test('does not change currentUser when clearing error', () {
        final userBefore = provider.currentUser;
        provider.clearError();
        expect(provider.currentUser, equals(userBefore));
      });

      test('can be called multiple times without error', () {
        provider.clearError();
        provider.clearError();
        provider.clearError();

        expect(provider.errorMessage, isNull);
        expect(provider.errorType, isNull);
      });
    });

    group('listener notifications', () {
      test('supports adding a listener', () {
        bool listenerCalled = false;
        provider.addListener(() {
          listenerCalled = true;
        });

        provider.clearError();
        expect(listenerCalled, isTrue);
      });

      test('supports removing a listener', () {
        int callCount = 0;
        void listener() {
          callCount++;
        }

        provider.addListener(listener);
        provider.clearError();
        expect(callCount, equals(1));

        provider.removeListener(listener);
        provider.clearError();
        expect(callCount, equals(1)); // Should not increment after removal
      });

      test('notifies multiple listeners', () {
        int listener1Count = 0;
        int listener2Count = 0;

        provider.addListener(() {
          listener1Count++;
        });
        provider.addListener(() {
          listener2Count++;
        });

        provider.clearError();

        expect(listener1Count, equals(1));
        expect(listener2Count, equals(1));
      });
    });
  });
}
