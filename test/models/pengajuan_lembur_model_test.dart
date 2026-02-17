import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_mobile/data/models/pengajuan_lembur_model.dart';

void main() {
  group('PengajuanLembur', () {
    Map<String, dynamic> createFullJson({
      String status = 'pending',
      String? fileSklUrl,
    }) {
      return {
        'id': 1,
        'tanggal': '2025-01-20',
        'kode_hari': 'K',
        'kode_hari_text': 'Hari Kerja',
        'jam_mulai': '18:00',
        'jam_selesai': '21:00',
        'file_skl_url': fileSklUrl,
        'keterangan_karyawan': 'Extra work needed',
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
        'tanggal': '2025-01-20',
        'kode_hari': 'K',
        'kode_hari_text': 'Hari Kerja',
        'jam_mulai': '18:00',
        'jam_selesai': '21:00',
        'file_skl_url': 'https://example.com/skl.pdf',
        'keterangan_karyawan': 'Extra work needed',
        'status': 'pending',
        'status_text': 'Menunggu',
        'catatan_admin': 'Approved by manager',
        'diproses_pada': '2025-01-21T10:00:00.000Z',
        'diproses_oleh': 'Admin',
        'created_at': '2025-01-19T08:00:00.000Z',
      };

      final lembur = PengajuanLembur.fromJson(json);

      expect(lembur.id, equals(1));
      expect(lembur.tanggal, equals(DateTime.parse('2025-01-20')));
      expect(lembur.kodeHari, equals('K'));
      expect(lembur.kodeHariText, equals('Hari Kerja'));
      expect(lembur.jamMulai, equals('18:00'));
      expect(lembur.jamSelesai, equals('21:00'));
      expect(lembur.fileSklUrl, equals('https://example.com/skl.pdf'));
      expect(lembur.keteranganKaryawan, equals('Extra work needed'));
      expect(lembur.status, equals('pending'));
      expect(lembur.statusText, equals('Menunggu'));
      expect(lembur.catatanAdmin, equals('Approved by manager'));
      expect(lembur.diprosesPada, equals(DateTime.parse('2025-01-21T10:00:00.000Z')));
      expect(lembur.diprosesOleh, equals('Admin'));
      expect(lembur.createdAt, equals(DateTime.parse('2025-01-19T08:00:00.000Z')));
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 2,
        'tanggal': '2025-01-22',
        'kode_hari': 'L',
        'kode_hari_text': 'Hari Libur',
        'jam_mulai': null,
        'jam_selesai': null,
        'file_skl_url': null,
        'keterangan_karyawan': null,
        'status': 'pending',
        'status_text': 'Pending',
        'catatan_admin': null,
        'diproses_pada': null,
        'diproses_oleh': null,
        'created_at': '2025-01-19T08:00:00.000Z',
      };

      final lembur = PengajuanLembur.fromJson(json);

      expect(lembur.jamMulai, isNull);
      expect(lembur.jamSelesai, isNull);
      expect(lembur.fileSklUrl, isNull);
      expect(lembur.keteranganKaryawan, isNull);
      expect(lembur.catatanAdmin, isNull);
      expect(lembur.diprosesPada, isNull);
      expect(lembur.diprosesOleh, isNull);
    });

    test('fromJson handles empty string as null for optional strings', () {
      final json = {
        'id': 3,
        'tanggal': '2025-01-23',
        'kode_hari': 'K',
        'kode_hari_text': 'Hari Kerja',
        'jam_mulai': '',
        'jam_selesai': '',
        'file_skl_url': '',
        'keterangan_karyawan': '',
        'status': 'pending',
        'status_text': 'Pending',
        'catatan_admin': '',
        'diproses_pada': null,
        'diproses_oleh': '',
        'created_at': '2025-01-19T08:00:00.000Z',
      };

      final lembur = PengajuanLembur.fromJson(json);

      expect(lembur.jamMulai, isNull);
      expect(lembur.jamSelesai, isNull);
      expect(lembur.fileSklUrl, isNull);
      expect(lembur.keteranganKaryawan, isNull);
      expect(lembur.catatanAdmin, isNull);
      expect(lembur.diprosesOleh, isNull);
    });

    test('isPending returns true when status is pending', () {
      final lembur = PengajuanLembur.fromJson(createFullJson(status: 'pending'));
      expect(lembur.isPending, isTrue);
    });

    test('isPending returns false when status is not pending', () {
      final lembur = PengajuanLembur.fromJson(createFullJson(status: 'disetujui'));
      expect(lembur.isPending, isFalse);
    });

    test('isDisetujui returns true when status is disetujui', () {
      final lembur = PengajuanLembur.fromJson(createFullJson(status: 'disetujui'));
      expect(lembur.isDisetujui, isTrue);
    });

    test('isDisetujui returns false when status is not disetujui', () {
      final lembur = PengajuanLembur.fromJson(createFullJson(status: 'pending'));
      expect(lembur.isDisetujui, isFalse);
    });

    test('isDitolak returns true when status is ditolak', () {
      final lembur = PengajuanLembur.fromJson(createFullJson(status: 'ditolak'));
      expect(lembur.isDitolak, isTrue);
    });

    test('isDibatalkan returns true when status is dibatalkan', () {
      final lembur = PengajuanLembur.fromJson(createFullJson(status: 'dibatalkan'));
      expect(lembur.isDibatalkan, isTrue);
    });

    test('canEdit returns true when status is pending', () {
      final lembur = PengajuanLembur.fromJson(createFullJson(status: 'pending'));
      expect(lembur.canEdit, isTrue);
    });

    test('canEdit returns false when status is not pending', () {
      final lembur = PengajuanLembur.fromJson(createFullJson(status: 'disetujui'));
      expect(lembur.canEdit, isFalse);
    });

    test('canDelete returns true when status is pending', () {
      final lembur = PengajuanLembur.fromJson(createFullJson(status: 'pending'));
      expect(lembur.canDelete, isTrue);
    });

    test('canDelete returns false when status is not pending', () {
      final lembur = PengajuanLembur.fromJson(createFullJson(status: 'ditolak'));
      expect(lembur.canDelete, isFalse);
    });

    test('canCancel returns true when status is disetujui', () {
      final lembur = PengajuanLembur.fromJson(createFullJson(status: 'disetujui'));
      expect(lembur.canCancel, isTrue);
    });

    test('canCancel returns false when status is not disetujui', () {
      final lembur = PengajuanLembur.fromJson(createFullJson(status: 'pending'));
      expect(lembur.canCancel, isFalse);
    });

    test('hasFile returns true when fileSklUrl is not null and not empty', () {
      final lembur = PengajuanLembur.fromJson(
        createFullJson(fileSklUrl: 'https://example.com/skl.pdf'),
      );
      expect(lembur.hasFile, isTrue);
    });

    test('hasFile returns false when fileSklUrl is null', () {
      final lembur = PengajuanLembur.fromJson(createFullJson(fileSklUrl: null));
      expect(lembur.hasFile, isFalse);
    });

    test('isHariLibur returns true when kodeHari is L', () {
      final json = createFullJson();
      json['kode_hari'] = 'L';
      final lembur = PengajuanLembur.fromJson(json);
      expect(lembur.isHariLibur, isTrue);
      expect(lembur.isHariKerja, isFalse);
    });

    test('isHariKerja returns true when kodeHari is K', () {
      final json = createFullJson();
      json['kode_hari'] = 'K';
      final lembur = PengajuanLembur.fromJson(json);
      expect(lembur.isHariKerja, isTrue);
      expect(lembur.isHariLibur, isFalse);
    });

    test('fromJson defaults kode_hari to K when null', () {
      final json = createFullJson();
      json['kode_hari'] = null;
      final lembur = PengajuanLembur.fromJson(json);
      expect(lembur.kodeHari, equals('K'));
      expect(lembur.kodeHariText, equals('Hari Kerja'));
    });
  });
}
