import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_mobile/providers/lembur_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LemburProvider', () {
    late LemburProvider provider;

    setUp(() {
      provider = LemburProvider();
    });

    group('initial state', () {
      test('state is LemburState.initial', () {
        expect(provider.state, equals(LemburState.initial));
      });

      test('lemburList is empty', () {
        expect(provider.lemburList, isA<List>());
        expect(provider.lemburList, isEmpty);
      });

      test('isLoading is false', () {
        expect(provider.isLoading, isFalse);
      });

      test('isSubmitting is false', () {
        expect(provider.isSubmitting, isFalse);
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

      test('filtered lists are all empty initially', () {
        expect(provider.pengajuanList, isEmpty);
        expect(provider.disetujuiList, isEmpty);
        expect(provider.ditolakList, isEmpty);
        expect(provider.dibatalkanList, isEmpty);
      });
    });

    group('LemburState enum', () {
      test('LemburState.initial exists', () {
        expect(LemburState.initial, isNotNull);
      });

      test('LemburState.loading exists', () {
        expect(LemburState.loading, isNotNull);
      });

      test('LemburState.loaded exists', () {
        expect(LemburState.loaded, isNotNull);
      });

      test('LemburState.error exists', () {
        expect(LemburState.error, isNotNull);
      });

      test('LemburState has exactly 4 values', () {
        expect(LemburState.values.length, equals(4));
      });

      test('LemburState values are in expected order', () {
        expect(LemburState.values, equals([
          LemburState.initial,
          LemburState.loading,
          LemburState.loaded,
          LemburState.error,
        ]));
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

      test('does not change state', () {
        final stateBefore = provider.state;
        provider.clearError();
        expect(provider.state, equals(stateBefore));
      });

      test('does not change lemburList', () {
        provider.clearError();
        expect(provider.lemburList, isEmpty);
      });

      test('does not change loading states', () {
        provider.clearError();
        expect(provider.isLoading, isFalse);
        expect(provider.isSubmitting, isFalse);
        expect(provider.isLoadingMore, isFalse);
      });

      test('does not change hasMore', () {
        provider.clearError();
        expect(provider.hasMore, isFalse);
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
