import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_mobile/providers/informasi_provider.dart';

void main() {
  group('InformasiProvider', () {
    late InformasiProvider provider;

    setUp(() {
      provider = InformasiProvider();
    });

    group('initial state', () {
      test('state is InformasiState.initial', () {
        expect(provider.state, InformasiState.initial);
      });

      test('informasiList is empty', () {
        expect(provider.informasiList, isEmpty);
      });

      test('unreadCount is 0', () {
        expect(provider.unreadCount, 0);
      });

      test('isLoading is false', () {
        expect(provider.isLoading, isFalse);
      });

      test('isLoadingMore is false', () {
        expect(provider.isLoadingMore, isFalse);
      });

      test('hasMore is false', () {
        expect(provider.hasMore, isFalse);
      });

      test('errorMessage is null', () {
        expect(provider.errorMessage, isNull);
      });

      test('errorType is null', () {
        expect(provider.errorType, isNull);
      });
    });

    group('InformasiState enum', () {
      test('has initial value', () {
        expect(InformasiState.initial, isNotNull);
      });

      test('has loading value', () {
        expect(InformasiState.loading, isNotNull);
      });

      test('has loaded value', () {
        expect(InformasiState.loaded, isNotNull);
      });

      test('has error value', () {
        expect(InformasiState.error, isNotNull);
      });

      test('all enum values are distinct', () {
        final values = InformasiState.values;
        expect(values.length, 4);
        expect(values.toSet().length, 4);
      });
    });

    group('isLoading derived getter', () {
      test('returns false when state is initial', () {
        expect(provider.state, InformasiState.initial);
        expect(provider.isLoading, isFalse);
      });
    });

    group('unreadList and readList derived getters', () {
      test('unreadList is empty when informasiList is empty', () {
        expect(provider.unreadList, isEmpty);
      });

      test('readList is empty when informasiList is empty', () {
        expect(provider.readList, isEmpty);
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
      test('resets state to InformasiState.initial', () {
        provider.clear();
        expect(provider.state, InformasiState.initial);
      });

      test('resets informasiList to empty', () {
        provider.clear();
        expect(provider.informasiList, isEmpty);
      });

      test('resets unreadCount to 0', () {
        provider.clear();
        expect(provider.unreadCount, 0);
      });

      test('resets hasMore to false', () {
        provider.clear();
        expect(provider.hasMore, isFalse);
      });

      test('resets errorMessage to null', () {
        provider.clear();
        expect(provider.errorMessage, isNull);
      });

      test('resets errorType to null', () {
        provider.clear();
        expect(provider.errorType, isNull);
      });

      test('resets isLoadingMore to false (via isLoadingMore getter)', () {
        provider.clear();
        expect(provider.isLoadingMore, isFalse);
      });

      test('notifies listeners exactly once', () {
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        provider.clear();

        expect(notifyCount, 1);
      });
    });

    group('state consistency', () {
      test('clearError does not change state enum', () {
        expect(provider.state, InformasiState.initial);
        provider.clearError();
        expect(provider.state, InformasiState.initial);
      });

      test('clearError does not affect unreadCount', () {
        expect(provider.unreadCount, 0);
        provider.clearError();
        expect(provider.unreadCount, 0);
      });

      test('clear resets everything to match a fresh instance', () {
        provider.clear();

        final fresh = InformasiProvider();
        expect(provider.state, fresh.state);
        expect(provider.informasiList.length, fresh.informasiList.length);
        expect(provider.unreadCount, fresh.unreadCount);
        expect(provider.hasMore, fresh.hasMore);
        expect(provider.isLoadingMore, fresh.isLoadingMore);
        expect(provider.errorMessage, fresh.errorMessage);
        expect(provider.errorType, fresh.errorType);
      });
    });
  });
}
