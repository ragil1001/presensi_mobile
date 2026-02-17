import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_mobile/providers/izin_provider.dart';
import 'package:presensi_mobile/data/models/pengajuan_izin_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IzinProvider', () {
    late IzinProvider provider;

    setUp(() {
      provider = IzinProvider();
    });

    group('initial state', () {
      test('state is IzinState.initial', () {
        expect(provider.state, equals(IzinState.initial));
      });

      test('izinList is empty', () {
        expect(provider.izinList, isA<List>());
        expect(provider.izinList, isEmpty);
      });

      test('kategoriList is empty', () {
        expect(provider.kategoriList, isA<List>());
        expect(provider.kategoriList, isEmpty);
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

      test('subKategoriList is empty when kategoriList is empty', () {
        expect(provider.subKategoriList, isA<List>());
        expect(provider.subKategoriList, isEmpty);
      });

      test('filtered lists are all empty initially', () {
        expect(provider.pengajuanList, isEmpty);
        expect(provider.disetujuiList, isEmpty);
        expect(provider.ditolakList, isEmpty);
        expect(provider.dibatalkanList, isEmpty);
      });
    });

    group('IzinState enum', () {
      test('IzinState.initial exists', () {
        expect(IzinState.initial, isNotNull);
      });

      test('IzinState.loading exists', () {
        expect(IzinState.loading, isNotNull);
      });

      test('IzinState.loaded exists', () {
        expect(IzinState.loaded, isNotNull);
      });

      test('IzinState.error exists', () {
        expect(IzinState.error, isNotNull);
      });

      test('IzinState has exactly 4 values', () {
        expect(IzinState.values.length, equals(4));
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

      test('does not change izinList', () {
        provider.clearError();
        expect(provider.izinList, isEmpty);
      });

      test('does not change kategoriList', () {
        provider.clearError();
        expect(provider.kategoriList, isEmpty);
      });

      test('does not change loading states', () {
        provider.clearError();
        expect(provider.isLoading, isFalse);
        expect(provider.isSubmitting, isFalse);
      });

      test('can be called multiple times without error', () {
        provider.clearError();
        provider.clearError();
        provider.clearError();

        expect(provider.errorMessage, isNull);
        expect(provider.errorType, isNull);
      });
    });

    group('hitungTanggalSelesai', () {
      test('returns correct date for 1 day duration', () {
        final tanggalMulai = DateTime(2026, 1, 15);
        final result = provider.hitungTanggalSelesai(
          tanggalMulai: tanggalMulai,
          jumlahHari: 1,
        );

        // 1 day means same day (tanggalMulai + 0 days)
        expect(result, equals(DateTime(2026, 1, 15)));
      });

      test('returns correct date for 3 day duration', () {
        final tanggalMulai = DateTime(2026, 1, 15);
        final result = provider.hitungTanggalSelesai(
          tanggalMulai: tanggalMulai,
          jumlahHari: 3,
        );

        // 3 days: Jan 15 + 2 days = Jan 17
        expect(result, equals(DateTime(2026, 1, 17)));
      });

      test('returns correct date for 7 day duration', () {
        final tanggalMulai = DateTime(2026, 2, 1);
        final result = provider.hitungTanggalSelesai(
          tanggalMulai: tanggalMulai,
          jumlahHari: 7,
        );

        // 7 days: Feb 1 + 6 days = Feb 7
        expect(result, equals(DateTime(2026, 2, 7)));
      });

      test('returns null when jumlahHari is 0', () {
        final tanggalMulai = DateTime(2026, 1, 15);
        final result = provider.hitungTanggalSelesai(
          tanggalMulai: tanggalMulai,
          jumlahHari: 0,
        );

        expect(result, isNull);
      });

      test('returns null when jumlahHari is negative', () {
        final tanggalMulai = DateTime(2026, 1, 15);
        final result = provider.hitungTanggalSelesai(
          tanggalMulai: tanggalMulai,
          jumlahHari: -1,
        );

        expect(result, isNull);
      });

      test('handles month boundary correctly', () {
        final tanggalMulai = DateTime(2026, 1, 30);
        final result = provider.hitungTanggalSelesai(
          tanggalMulai: tanggalMulai,
          jumlahHari: 5,
        );

        // Jan 30 + 4 days = Feb 3
        expect(result, equals(DateTime(2026, 2, 3)));
      });

      test('handles year boundary correctly', () {
        final tanggalMulai = DateTime(2025, 12, 30);
        final result = provider.hitungTanggalSelesai(
          tanggalMulai: tanggalMulai,
          jumlahHari: 5,
        );

        // Dec 30 + 4 days = Jan 3
        expect(result, equals(DateTime(2026, 1, 3)));
      });

      test('handles leap year February correctly', () {
        // 2028 is a leap year
        final tanggalMulai = DateTime(2028, 2, 27);
        final result = provider.hitungTanggalSelesai(
          tanggalMulai: tanggalMulai,
          jumlahHari: 3,
        );

        // Feb 27 + 2 days = Feb 29 (leap year)
        expect(result, equals(DateTime(2028, 2, 29)));
      });
    });

    group('resolveKategoriIzinId', () {
      test('returns kategori.id when hasSubKategori is false', () {
        final kategori = KategoriIzin(
          id: 5,
          value: 'sakit',
          label: 'Sakit',
          kode: 'S',
          hasSubKategori: false,
          butuhDokumen: true,
          deskripsi: 'Sakit',
        );

        final result = provider.resolveKategoriIzinId(kategori, null);
        expect(result, equals(5));
      });

      test('returns subKategori.id when hasSubKategori is true and subKategori is provided', () {
        final kategori = KategoriIzin(
          id: 10,
          value: 'cuti_khusus',
          label: 'Cuti Khusus',
          kode: 'CK',
          hasSubKategori: true,
          butuhDokumen: true,
          deskripsi: 'Cuti Khusus',
        );

        final subKategori = SubKategoriCutiKhusus(
          id: 42,
          value: '42',
          label: 'Menikah',
          durasiHari: 3,
          deskripsi: 'Menikah',
        );

        final result = provider.resolveKategoriIzinId(kategori, subKategori);
        expect(result, equals(42));
      });

      test('returns kategori.id when hasSubKategori is true but subKategori is null', () {
        final kategori = KategoriIzin(
          id: 10,
          value: 'cuti_khusus',
          label: 'Cuti Khusus',
          kode: 'CK',
          hasSubKategori: true,
          butuhDokumen: true,
          deskripsi: 'Cuti Khusus',
        );

        final result = provider.resolveKategoriIzinId(kategori, null);
        expect(result, equals(10));
      });

      test('returns null when kategori.id is null and hasSubKategori is false', () {
        final kategori = KategoriIzin(
          id: null,
          value: 'test',
          label: 'Test',
          kode: 'T',
          hasSubKategori: false,
          butuhDokumen: false,
          deskripsi: 'Test',
        );

        final result = provider.resolveKategoriIzinId(kategori, null);
        expect(result, isNull);
      });

      test('returns subKategori.id even when kategori.id is null if hasSubKategori is true', () {
        final kategori = KategoriIzin(
          id: null,
          value: 'cuti_khusus',
          label: 'Cuti Khusus',
          kode: 'CK',
          hasSubKategori: true,
          butuhDokumen: true,
          deskripsi: 'Cuti Khusus',
        );

        final subKategori = SubKategoriCutiKhusus(
          id: 7,
          value: '7',
          label: 'Menikah',
          durasiHari: 3,
          deskripsi: 'Menikah',
        );

        final result = provider.resolveKategoriIzinId(kategori, subKategori);
        expect(result, equals(7));
      });
    });

    group('getSubKategoriFor', () {
      test('returns empty list when kategoriList is empty', () {
        final result = provider.getSubKategoriFor('cuti_khusus');
        expect(result, isEmpty);
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
