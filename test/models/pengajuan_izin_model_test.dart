import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_mobile/data/models/pengajuan_izin_model.dart';

void main() {
  group('PengajuanIzin', () {
    Map<String, dynamic> createFullJson({
      String status = 'pending',
      String? fileUrl,
    }) {
      return {
        'id': 1,
        'kategori_izin_id': 2,
        'kategori_izin': 'sakit',
        'sub_kategori_izin': null,
        'deskripsi_izin': 'Sakit - Demam',
        'durasi_otomatis': null,
        'tanggal_mulai': '2025-01-20',
        'tanggal_selesai': '2025-01-21',
        'durasi_hari': 2,
        'keterangan': 'Feeling unwell',
        'file_url': fileUrl,
        'status': status,
        'status_text': 'Pending',
        'catatan_admin': null,
        'diproses_pada': null,
        'diproses_oleh': null,
        'created_at': '2025-01-19T08:00:00.000Z',
      };
    }

    test('fromJson creates instance correctly with all fields', () {
      final json = {
        'id': 1,
        'kategori_izin_id': 2,
        'kategori_izin': 'sakit',
        'sub_kategori_izin': 'demam',
        'deskripsi_izin': 'Sakit - Demam',
        'durasi_otomatis': 3,
        'tanggal_mulai': '2025-01-20',
        'tanggal_selesai': '2025-01-22',
        'durasi_hari': 3,
        'keterangan': 'High fever',
        'file_url': 'https://example.com/surat_dokter.pdf',
        'status': 'pending',
        'status_text': 'Menunggu',
        'catatan_admin': 'Noted',
        'diproses_pada': '2025-01-21T10:00:00.000Z',
        'diproses_oleh': 'Admin',
        'created_at': '2025-01-19T08:00:00.000Z',
      };

      final izin = PengajuanIzin.fromJson(json);

      expect(izin.id, equals(1));
      expect(izin.kategoriIzinId, equals(2));
      expect(izin.kategoriIzin, equals('sakit'));
      expect(izin.subKategoriIzin, equals('demam'));
      expect(izin.deskripsiIzin, equals('Sakit - Demam'));
      expect(izin.durasiOtomatis, equals(3));
      expect(izin.tanggalMulai, equals(DateTime.parse('2025-01-20')));
      expect(izin.tanggalSelesai, equals(DateTime.parse('2025-01-22')));
      expect(izin.durasiHari, equals(3));
      expect(izin.keterangan, equals('High fever'));
      expect(izin.fileUrl, equals('https://example.com/surat_dokter.pdf'));
      expect(izin.status, equals('pending'));
      expect(izin.statusText, equals('Menunggu'));
      expect(izin.catatanAdmin, equals('Noted'));
      expect(izin.diprosesPada, equals(DateTime.parse('2025-01-21T10:00:00.000Z')));
      expect(izin.diprosesOleh, equals('Admin'));
      expect(izin.createdAt, equals(DateTime.parse('2025-01-19T08:00:00.000Z')));
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 1,
        'kategori_izin_id': null,
        'kategori_izin': 'izin',
        'sub_kategori_izin': null,
        'deskripsi_izin': 'Izin',
        'durasi_otomatis': null,
        'tanggal_mulai': '2025-01-20',
        'tanggal_selesai': '2025-01-20',
        'durasi_hari': 1,
        'keterangan': null,
        'file_url': null,
        'status': 'pending',
        'status_text': 'Pending',
        'catatan_admin': null,
        'diproses_pada': null,
        'diproses_oleh': null,
        'created_at': '2025-01-19T08:00:00.000Z',
      };

      final izin = PengajuanIzin.fromJson(json);

      expect(izin.kategoriIzinId, isNull);
      expect(izin.subKategoriIzin, isNull);
      expect(izin.durasiOtomatis, isNull);
      expect(izin.keterangan, isNull);
      expect(izin.fileUrl, isNull);
      expect(izin.catatanAdmin, isNull);
      expect(izin.diprosesPada, isNull);
      expect(izin.diprosesOleh, isNull);
    });

    test('fromJson handles empty string as null for optional strings', () {
      final json = {
        'id': 1,
        'kategori_izin': '',
        'deskripsi_izin': '',
        'tanggal_mulai': '2025-01-20',
        'tanggal_selesai': '2025-01-20',
        'durasi_hari': 1,
        'keterangan': '',
        'file_url': '',
        'status': '',
        'status_text': '',
        'created_at': '2025-01-19T08:00:00.000Z',
      };

      final izin = PengajuanIzin.fromJson(json);

      // Empty strings become null via getStringOrNull, so defaults apply
      expect(izin.kategoriIzin, equals('izin'));
      expect(izin.deskripsiIzin, equals('Izin'));
      expect(izin.keterangan, isNull);
      expect(izin.fileUrl, isNull);
      expect(izin.status, equals('pending'));
      expect(izin.statusText, equals('Pending'));
    });

    test('isPending returns true when status is pending', () {
      final izin = PengajuanIzin.fromJson(createFullJson(status: 'pending'));
      expect(izin.isPending, isTrue);
    });

    test('isPending returns false when status is not pending', () {
      final izin = PengajuanIzin.fromJson(createFullJson(status: 'disetujui'));
      expect(izin.isPending, isFalse);
    });

    test('isDisetujui returns true when status is disetujui', () {
      final izin = PengajuanIzin.fromJson(createFullJson(status: 'disetujui'));
      expect(izin.isDisetujui, isTrue);
    });

    test('isDitolak returns true when status is ditolak', () {
      final izin = PengajuanIzin.fromJson(createFullJson(status: 'ditolak'));
      expect(izin.isDitolak, isTrue);
    });

    test('isDibatalkan returns true when status is dibatalkan', () {
      final izin = PengajuanIzin.fromJson(createFullJson(status: 'dibatalkan'));
      expect(izin.isDibatalkan, isTrue);
    });

    test('canEdit returns true when status is pending', () {
      final izin = PengajuanIzin.fromJson(createFullJson(status: 'pending'));
      expect(izin.canEdit, isTrue);
    });

    test('canEdit returns false when status is not pending', () {
      final izin = PengajuanIzin.fromJson(createFullJson(status: 'disetujui'));
      expect(izin.canEdit, isFalse);
    });

    test('canDelete returns true when status is pending', () {
      final izin = PengajuanIzin.fromJson(createFullJson(status: 'pending'));
      expect(izin.canDelete, isTrue);
    });

    test('canDelete returns false when status is not pending', () {
      final izin = PengajuanIzin.fromJson(createFullJson(status: 'ditolak'));
      expect(izin.canDelete, isFalse);
    });

    test('canCancel returns true when status is disetujui', () {
      final izin = PengajuanIzin.fromJson(createFullJson(status: 'disetujui'));
      expect(izin.canCancel, isTrue);
    });

    test('canCancel returns false when status is not disetujui', () {
      final izin = PengajuanIzin.fromJson(createFullJson(status: 'pending'));
      expect(izin.canCancel, isFalse);
    });

    test('hasFile returns true when fileUrl is not null and not empty', () {
      final izin = PengajuanIzin.fromJson(
        createFullJson(fileUrl: 'https://example.com/file.pdf'),
      );
      expect(izin.hasFile, isTrue);
    });

    test('hasFile returns false when fileUrl is null', () {
      final izin = PengajuanIzin.fromJson(createFullJson(fileUrl: null));
      expect(izin.hasFile, isFalse);
    });

    test('isSakit returns true for sakit category', () {
      final json = createFullJson();
      json['kategori_izin'] = 'sakit';
      final izin = PengajuanIzin.fromJson(json);
      expect(izin.isSakit, isTrue);
      expect(izin.isIzin, isFalse);
    });

    test('isIzin returns true for izin category', () {
      final json = createFullJson();
      json['kategori_izin'] = 'izin';
      final izin = PengajuanIzin.fromJson(json);
      expect(izin.isIzin, isTrue);
      expect(izin.isSakit, isFalse);
    });

    test('isCutiTahunan returns true for cuti_tahunan category', () {
      final json = createFullJson();
      json['kategori_izin'] = 'cuti_tahunan';
      final izin = PengajuanIzin.fromJson(json);
      expect(izin.isCutiTahunan, isTrue);
    });

    test('isCutiKhusus returns true for cuti_khusus category', () {
      final json = createFullJson();
      json['kategori_izin'] = 'cuti_khusus';
      final izin = PengajuanIzin.fromJson(json);
      expect(izin.isCutiKhusus, isTrue);
    });

    test('kategoriLabel returns correct label for sakit', () {
      final json = createFullJson();
      json['kategori_izin'] = 'sakit';
      final izin = PengajuanIzin.fromJson(json);
      expect(izin.kategoriLabel, equals('Sakit'));
    });

    test('kategoriLabel returns correct label for izin', () {
      final json = createFullJson();
      json['kategori_izin'] = 'izin';
      final izin = PengajuanIzin.fromJson(json);
      expect(izin.kategoriLabel, equals('Izin'));
    });

    test('kategoriLabel returns correct label for cuti_tahunan', () {
      final json = createFullJson();
      json['kategori_izin'] = 'cuti_tahunan';
      final izin = PengajuanIzin.fromJson(json);
      expect(izin.kategoriLabel, equals('Cuti Tahunan'));
    });

    test('kategoriLabel returns correct label for cuti_khusus', () {
      final json = createFullJson();
      json['kategori_izin'] = 'cuti_khusus';
      final izin = PengajuanIzin.fromJson(json);
      expect(izin.kategoriLabel, equals('Cuti Khusus'));
    });

    test('kategoriLabel uses deskripsiIzin parts for unknown category', () {
      final json = createFullJson();
      json['kategori_izin'] = 'other';
      json['deskripsi_izin'] = 'Special - Leave';
      final izin = PengajuanIzin.fromJson(json);
      expect(izin.kategoriLabel, equals('Special'));
    });
  });

  group('KategoriIzin', () {
    test('fromJson creates instance correctly', () {
      final json = {
        'id': '1',
        'value': 'sakit',
        'label': 'Sakit',
        'kode': 'S',
        'has_sub_kategori': false,
        'butuh_dokumen': true,
        'max_hari': '30',
        'sisa_cuti': '12',
        'deskripsi': 'Izin sakit',
      };

      final kategori = KategoriIzin.fromJson(json);

      expect(kategori.id, equals(1));
      expect(kategori.value, equals('sakit'));
      expect(kategori.label, equals('Sakit'));
      expect(kategori.kode, equals('S'));
      expect(kategori.hasSubKategori, isFalse);
      expect(kategori.butuhDokumen, isTrue);
      expect(kategori.maxHari, equals(30));
      expect(kategori.sisaCuti, equals(12));
      expect(kategori.deskripsi, equals('Izin sakit'));
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'value': 'izin',
        'label': 'Izin',
        'kode': 'I',
        'has_sub_kategori': false,
        'butuh_dokumen': false,
        'deskripsi': 'Izin biasa',
      };

      final kategori = KategoriIzin.fromJson(json);

      expect(kategori.id, isNull);
      expect(kategori.maxHari, isNull);
      expect(kategori.sisaCuti, isNull);
    });

    test('fromJson handles boolean-like values for has_sub_kategori', () {
      final json = {
        'value': 'cuti_khusus',
        'label': 'Cuti Khusus',
        'kode': 'CK',
        'has_sub_kategori': true,
        'butuh_dokumen': true,
        'deskripsi': 'Cuti Khusus',
      };

      final kategori = KategoriIzin.fromJson(json);
      expect(kategori.hasSubKategori, isTrue);
    });

    test('fromJson defaults boolean fields to false when not true', () {
      final json = {
        'value': 'izin',
        'label': 'Izin',
        'kode': 'I',
        'has_sub_kategori': 'yes',
        'butuh_dokumen': 0,
        'deskripsi': '',
      };

      final kategori = KategoriIzin.fromJson(json);
      expect(kategori.hasSubKategori, isFalse);
      expect(kategori.butuhDokumen, isFalse);
    });

    test('fromJson handles empty json with defaults', () {
      final json = <String, dynamic>{};
      final kategori = KategoriIzin.fromJson(json);

      expect(kategori.id, isNull);
      expect(kategori.value, equals(''));
      expect(kategori.label, equals(''));
      expect(kategori.kode, equals(''));
      expect(kategori.hasSubKategori, isFalse);
      expect(kategori.butuhDokumen, isFalse);
      expect(kategori.deskripsi, equals(''));
    });

    test('fromApiJson creates instance correctly for sakit', () {
      final json = {
        'kategori_key': 'sakit',
        'kategori': 'Sakit',
        'sub_kategori': [],
      };

      final kategori = KategoriIzin.fromApiJson(json);

      expect(kategori.value, equals('sakit'));
      expect(kategori.label, equals('Sakit'));
      expect(kategori.kode, equals('S'));
      expect(kategori.hasSubKategori, isFalse);
      expect(kategori.subKategoriItems, isEmpty);
    });

    test('fromApiJson creates instance correctly for izin', () {
      final json = {
        'kategori_key': 'izin',
        'kategori': 'Izin',
        'sub_kategori': [],
      };

      final kategori = KategoriIzin.fromApiJson(json);
      expect(kategori.kode, equals('I'));
    });

    test('fromApiJson creates instance correctly for cuti_tahunan', () {
      final json = {
        'kategori_key': 'cuti_tahunan',
        'kategori': 'Cuti Tahunan',
        'sub_kategori': [],
      };

      final kategori = KategoriIzin.fromApiJson(json);
      expect(kategori.kode, equals('CT'));
    });

    test('fromApiJson creates instance correctly for cuti_khusus with sub_kategori', () {
      final json = {
        'kategori_key': 'cuti_khusus',
        'kategori': 'Cuti Khusus',
        'sub_kategori': [
          {'id': 1, 'label': 'Menikah', 'jumlah_hari': 3},
          {'id': 2, 'label': 'Melahirkan', 'jumlah_hari': 90},
        ],
      };

      final kategori = KategoriIzin.fromApiJson(json);

      expect(kategori.kode, equals('CK'));
      expect(kategori.hasSubKategori, isTrue);
      expect(kategori.subKategoriItems.length, equals(2));
      expect(kategori.subKategoriItems[0].label, equals('Menikah'));
      expect(kategori.subKategoriItems[0].durasiHari, equals(3));
      expect(kategori.subKategoriItems[1].label, equals('Melahirkan'));
      expect(kategori.subKategoriItems[1].durasiHari, equals(90));
    });

    test('fromApiJson handles unknown kategori_key', () {
      final json = {
        'kategori_key': 'dinas_luar',
        'kategori': 'Dinas Luar',
        'sub_kategori': [],
      };

      final kategori = KategoriIzin.fromApiJson(json);
      expect(kategori.kode, equals('DI'));
    });
  });

  group('SubKategoriCutiKhusus', () {
    test('fromJson creates instance correctly', () {
      final json = {
        'id': 1,
        'value': 'menikah',
        'label': 'Menikah',
        'durasi_hari': 3,
        'deskripsi': 'Cuti menikah',
      };

      final sub = SubKategoriCutiKhusus.fromJson(json);

      expect(sub.id, equals(1));
      expect(sub.value, equals('menikah'));
      expect(sub.label, equals('Menikah'));
      expect(sub.durasiHari, equals(3));
      expect(sub.deskripsi, equals('Cuti menikah'));
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'value': 'test',
        'label': 'Test',
        'durasi_hari': 1,
        'deskripsi': 'Test desc',
      };

      final sub = SubKategoriCutiKhusus.fromJson(json);
      expect(sub.id, isNull);
    });

    test('fromJson handles empty json with defaults', () {
      final json = <String, dynamic>{};
      final sub = SubKategoriCutiKhusus.fromJson(json);

      expect(sub.id, isNull);
      expect(sub.value, equals(''));
      expect(sub.label, equals(''));
      expect(sub.durasiHari, equals(0));
      expect(sub.deskripsi, equals(''));
    });

    test('fromApiJson creates instance correctly', () {
      final json = {
        'id': 5,
        'label': 'Khitanan Anak',
        'jumlah_hari': 2,
      };

      final sub = SubKategoriCutiKhusus.fromApiJson(json);

      expect(sub.id, equals(5));
      expect(sub.value, equals('5'));
      expect(sub.label, equals('Khitanan Anak'));
      expect(sub.durasiHari, equals(2));
      expect(sub.deskripsi, equals('Khitanan Anak'));
    });

    test('fromApiJson handles null jumlah_hari', () {
      final json = {
        'id': 6,
        'label': 'Other',
      };

      final sub = SubKategoriCutiKhusus.fromApiJson(json);
      expect(sub.durasiHari, equals(0));
    });
  });
}
