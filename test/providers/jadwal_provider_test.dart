import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_mobile/providers/jadwal_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JadwalProvider', () {
    late JadwalProvider provider;

    setUp(() {
      provider = JadwalProvider();
    });

    group('initial state', () {
      test('isLoading is false', () {
        expect(provider.isLoading, isFalse);
      });

      test('errorMessage is null', () {
        expect(provider.errorMessage, isNull);
      });

      test('jadwalBulan is null', () {
        expect(provider.jadwalBulan, isNull);
      });
    });

    group('clearError', () {
      test('sets errorMessage to null', () {
        provider.clearError();
        expect(provider.errorMessage, isNull);
      });

      test('notifies listeners when called', () {
        int notifyCount = 0;
        provider.addListener(() {
          notifyCount++;
        });

        provider.clearError();

        expect(notifyCount, equals(1));
      });

      test('does not change isLoading', () {
        provider.clearError();
        expect(provider.isLoading, isFalse);
      });

      test('does not change jadwalBulan', () {
        provider.clearError();
        expect(provider.jadwalBulan, isNull);
      });

      test('can be called multiple times without error', () {
        provider.clearError();
        provider.clearError();
        provider.clearError();

        expect(provider.errorMessage, isNull);
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
