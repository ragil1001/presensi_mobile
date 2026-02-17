import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_mobile/providers/tukar_shift_provider.dart';

void main() {
  group('TukarShiftProvider', () {
    late TukarShiftProvider provider;

    setUp(() {
      provider = TukarShiftProvider();
    });

    group('initial state', () {
      test('isLoading is false', () {
        expect(provider.isLoading, isFalse);
      });

      test('isLoadingShifts is false', () {
        expect(provider.isLoadingShifts, isFalse);
      });

      test('isLoadingKaryawan is false', () {
        expect(provider.isLoadingKaryawan, isFalse);
      });

      test('isSubmitting is false', () {
        expect(provider.isSubmitting, isFalse);
      });

      test('isLoadingMore is false', () {
        expect(provider.isLoadingMore, isFalse);
      });

      test('requests is empty list', () {
        expect(provider.requests, isEmpty);
      });

      test('availableShifts is empty list', () {
        expect(provider.availableShifts, isEmpty);
      });

      test('karyawanList is empty list', () {
        expect(provider.karyawanList, isEmpty);
      });

      test('hasMore is false', () {
        expect(provider.hasMore, isFalse);
      });

      test('errorMessage is null', () {
        expect(provider.errorMessage, isNull);
      });

      test('errorMessageShifts is null', () {
        expect(provider.errorMessageShifts, isNull);
      });

      test('errorMessageKaryawan is null', () {
        expect(provider.errorMessageKaryawan, isNull);
      });
    });

    group('clearError', () {
      test('sets all error messages to null', () {
        // clearError should reset all error fields and notify listeners
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        provider.clearError();

        expect(provider.errorMessage, isNull);
        expect(provider.errorMessageShifts, isNull);
        expect(provider.errorMessageKaryawan, isNull);
        expect(notifyCount, 1);
      });
    });

    group('clear', () {
      test('resets all state to initial values', () {
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        provider.clear();

        expect(provider.requests, isEmpty);
        expect(provider.availableShifts, isEmpty);
        expect(provider.karyawanList, isEmpty);
        expect(provider.errorMessage, isNull);
        expect(provider.errorMessageShifts, isNull);
        expect(provider.errorMessageKaryawan, isNull);
        expect(provider.isLoading, isFalse);
        expect(provider.isLoadingShifts, isFalse);
        expect(provider.isLoadingKaryawan, isFalse);
        expect(provider.isSubmitting, isFalse);
        expect(notifyCount, 1);
      });
    });

    group('clearAvailableShifts', () {
      test('clears available shifts list and notifies listeners', () {
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        provider.clearAvailableShifts();

        expect(provider.availableShifts, isEmpty);
        expect(notifyCount, 1);
      });
    });

    group('clearKaryawanList', () {
      test('clears karyawan list and notifies listeners', () {
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        provider.clearKaryawanList();

        expect(provider.karyawanList, isEmpty);
        expect(notifyCount, 1);
      });
    });

    group('notifyListeners', () {
      test('clearError notifies listeners exactly once', () {
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        provider.clearError();
        expect(notifyCount, 1);
      });

      test('clear notifies listeners exactly once', () {
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        provider.clear();
        expect(notifyCount, 1);
      });

      test('clearAvailableShifts notifies listeners exactly once', () {
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        provider.clearAvailableShifts();
        expect(notifyCount, 1);
      });

      test('clearKaryawanList notifies listeners exactly once', () {
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        provider.clearKaryawanList();
        expect(notifyCount, 1);
      });
    });
  });
}
