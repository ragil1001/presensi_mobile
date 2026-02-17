import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_mobile/providers/connectivity_provider.dart';

void main() {
  // Required for connectivity_plus platform channel handling in tests.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectivityProvider', () {
    late ConnectivityProvider provider;

    setUp(() {
      provider = ConnectivityProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    group('initial state', () {
      test('isOnline defaults to true', () {
        // The field _isOnline is initialized to true before _init() runs
        // asynchronously, so the synchronous default is true.
        expect(provider.isOnline, isTrue);
      });

      test('wasOffline defaults to false', () {
        expect(provider.wasOffline, isFalse);
      });
    });

    group('clearWasOffline', () {
      test('sets wasOffline to false', () {
        provider.clearWasOffline();
        expect(provider.wasOffline, isFalse);
      });
    });

    group('state consistency', () {
      test('clearWasOffline does not affect isOnline', () {
        final onlineBefore = provider.isOnline;
        provider.clearWasOffline();
        expect(provider.isOnline, onlineBefore);
      });

      test('calling clearWasOffline multiple times is safe', () {
        provider.clearWasOffline();
        provider.clearWasOffline();
        provider.clearWasOffline();
        expect(provider.wasOffline, isFalse);
      });
    });
  });
}
