import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_mobile/providers/presensi_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PresensiProvider', () {
    late PresensiProvider provider;

    setUp(() {
      provider = PresensiProvider();
    });

    group('initial state', () {
      test('isLoading is false', () {
        expect(provider.isLoading, isFalse);
      });

      test('isLoadingStatistik is false', () {
        expect(provider.isLoadingStatistik, isFalse);
      });

      test('isLoadingHistory is false', () {
        expect(provider.isLoadingHistory, isFalse);
      });

      test('isSubmitting is false', () {
        expect(provider.isSubmitting, isFalse);
      });

      test('presensiData is null', () {
        expect(provider.presensiData, isNull);
      });

      test('errorMessage is null', () {
        expect(provider.errorMessage, isNull);
      });

      test('errorMessageStatistik is null', () {
        expect(provider.errorMessageStatistik, isNull);
      });

      test('errorMessageHistory is null', () {
        expect(provider.errorMessageHistory, isNull);
      });

      test('submitError is null', () {
        expect(provider.submitError, isNull);
      });

      test('statistikPeriode is null', () {
        expect(provider.statistikPeriode, isNull);
      });

      test('historyItems is empty list', () {
        expect(provider.historyItems, isA<List>());
        expect(provider.historyItems, isEmpty);
      });

      test('historyHasMore is false', () {
        expect(provider.historyHasMore, isFalse);
      });

      test('historyTotal is 0', () {
        expect(provider.historyTotal, equals(0));
      });

      test('historyFilter is "semua"', () {
        expect(provider.historyFilter, equals('semua'));
      });

      test('historyKaryawan is empty map', () {
        expect(provider.historyKaryawan, isA<Map>());
        expect(provider.historyKaryawan, isEmpty);
      });

      test('historyProject is empty map', () {
        expect(provider.historyProject, isA<Map>());
        expect(provider.historyProject, isEmpty);
      });

      test('enabledIzinCategories is empty when presensiData is null', () {
        expect(provider.enabledIzinCategories, isA<List<String>>());
        expect(provider.enabledIzinCategories, isEmpty);
      });

      test('enabledSubKategoriIzin is empty when presensiData is null', () {
        expect(provider.enabledSubKategoriIzin, isA<List<String>>());
        expect(provider.enabledSubKategoriIzin, isEmpty);
      });
    });

    group('clearError', () {
      test('sets errorMessage to null', () {
        provider.clearError();
        expect(provider.errorMessage, isNull);
      });

      test('sets errorMessageStatistik to null', () {
        provider.clearError();
        expect(provider.errorMessageStatistik, isNull);
      });

      test('sets errorMessageHistory to null', () {
        provider.clearError();
        expect(provider.errorMessageHistory, isNull);
      });

      test('does not clear submitError (only cleared by submit methods)', () {
        // clearError() resets errorMessage, errorMessageStatistik, and
        // errorMessageHistory, but _submitError is only reset when a new
        // submit call begins. Since we have no error, submitError stays null.
        provider.clearError();
        expect(provider.submitError, isNull);
      });

      test('notifies listeners when called', () {
        int notifyCount = 0;
        provider.addListener(() {
          notifyCount++;
        });

        provider.clearError();

        expect(notifyCount, equals(1));
      });

      test('does not change loading states', () {
        provider.clearError();
        expect(provider.isLoading, isFalse);
        expect(provider.isLoadingStatistik, isFalse);
        expect(provider.isLoadingHistory, isFalse);
        expect(provider.isSubmitting, isFalse);
      });

      test('does not change presensiData', () {
        provider.clearError();
        expect(provider.presensiData, isNull);
      });

      test('does not change history data', () {
        provider.clearError();
        expect(provider.historyItems, isEmpty);
        expect(provider.historyHasMore, isFalse);
      });

      test('can be called multiple times without error', () {
        provider.clearError();
        provider.clearError();
        provider.clearError();

        expect(provider.errorMessage, isNull);
        expect(provider.errorMessageStatistik, isNull);
        expect(provider.errorMessageHistory, isNull);
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
        expect(callCount, equals(1));
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
