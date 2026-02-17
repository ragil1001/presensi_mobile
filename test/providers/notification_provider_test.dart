import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_mobile/providers/notification_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock flutter_secure_storage method channel to prevent MissingPluginException
  // when onFcmMessageReceived triggers loadNotifications -> ApiClient interceptor
  const storageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(storageChannel, (MethodCall methodCall) async {
    if (methodCall.method == 'read') return null;
    if (methodCall.method == 'readAll') return <String, String>{};
    return null;
  });

  group('NotificationProvider', () {
    late NotificationProvider provider;

    setUp(() {
      provider = NotificationProvider();
    });

    group('initial state', () {
      test('isLoading is false', () {
        expect(provider.isLoading, isFalse);
      });

      test('isLoadingMore is false', () {
        expect(provider.isLoadingMore, isFalse);
      });

      test('errorMessage is null', () {
        expect(provider.errorMessage, isNull);
      });

      test('errorType is null', () {
        expect(provider.errorType, isNull);
      });

      test('notifications is empty list', () {
        expect(provider.notifications, isEmpty);
      });

      test('unreadCount is 0', () {
        expect(provider.unreadCount, 0);
      });

      test('hasMore is false', () {
        expect(provider.hasMore, isFalse);
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

      test('notifies listeners exactly once', () {
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        provider.clearError();

        expect(notifyCount, 1);
      });
    });

    group('clear', () {
      test('resets all notification state', () {
        provider.clear();

        expect(provider.notifications, isEmpty);
        expect(provider.unreadCount, 0);
        expect(provider.hasMore, isFalse);
        expect(provider.errorMessage, isNull);
        expect(provider.errorType, isNull);
      });

      test('notifies listeners exactly once', () {
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        provider.clear();

        expect(notifyCount, 1);
      });
    });

    group('onFcmMessageReceived', () {
      test('increments unreadCount by 1', () {
        expect(provider.unreadCount, 0);

        provider.onFcmMessageReceived();

        expect(provider.unreadCount, 1);
      });

      test('increments unreadCount cumulatively on multiple calls', () {
        provider.onFcmMessageReceived();
        provider.onFcmMessageReceived();
        provider.onFcmMessageReceived();

        expect(provider.unreadCount, 3);
      });

      test('notifies listeners', () {
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        provider.onFcmMessageReceived();

        // onFcmMessageReceived calls notifyListeners() directly,
        // then also triggers loadNotifications() which notifies again.
        // At minimum, 1 notification should occur synchronously.
        expect(notifyCount, greaterThanOrEqualTo(1));
      });
    });

    group('state consistency', () {
      test('clear after onFcmMessageReceived resets unreadCount', () {
        provider.onFcmMessageReceived();
        provider.onFcmMessageReceived();
        expect(provider.unreadCount, 2);

        provider.clear();
        expect(provider.unreadCount, 0);
      });

      test('clearError does not affect unreadCount', () {
        provider.onFcmMessageReceived();
        expect(provider.unreadCount, 1);

        provider.clearError();
        expect(provider.unreadCount, 1);
      });

      test('clearError does not affect notifications list', () {
        provider.clearError();
        expect(provider.notifications, isEmpty);
      });
    });
  });
}
