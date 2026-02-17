import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_mobile/data/models/tukar_shift_model.dart';

void main() {
  group('KaryawanTujuan', () {
    test('fromJson creates instance correctly', () {
      final json = {
        'id': 2,
        'nama': 'Jane Smith',
        'nik': 'EMP002',
        'no_telp': '081234567891',
        'divisi': 'Cleaning',
        'jabatan': 'Staff',
      };

      final karyawan = KaryawanTujuan.fromJson(json);

      expect(karyawan.id, equals(2));
      expect(karyawan.nama, equals('Jane Smith'));
      expect(karyawan.nik, equals('EMP002'));
      expect(karyawan.noTelp, equals('081234567891'));
      expect(karyawan.divisi, equals('Cleaning'));
      expect(karyawan.jabatan, equals('Staff'));
    });

    test('fromJson handles null values with defaults', () {
      final json = <String, dynamic>{};
      final karyawan = KaryawanTujuan.fromJson(json);

      expect(karyawan.id, equals(0));
      expect(karyawan.nama, equals(''));
      expect(karyawan.nik, equals(''));
      expect(karyawan.noTelp, equals(''));
      expect(karyawan.divisi, equals(''));
      expect(karyawan.jabatan, equals(''));
    });

    test('fromJson handles string id by parsing to int', () {
      final json = {
        'id': '15',
        'nama': 'Test',
        'nik': 'EMP015',
        'no_telp': '000',
        'divisi': 'IT',
        'jabatan': 'Dev',
      };

      final karyawan = KaryawanTujuan.fromJson(json);
      expect(karyawan.id, equals(15));
    });

    test('fromJson handles double id by converting to int', () {
      final json = {
        'id': 7.5,
        'nama': 'Test',
        'nik': 'EMP007',
        'no_telp': '000',
        'divisi': 'IT',
        'jabatan': 'Dev',
      };

      final karyawan = KaryawanTujuan.fromJson(json);
      expect(karyawan.id, equals(7));
    });
  });

  group('ShiftInfo (tukar_shift)', () {
    test('fromJson creates instance correctly', () {
      final json = {
        'jadwal_id': 10,
        'tanggal': '2025-01-25',
        'hari': 'Sabtu',
        'shift_code': 'P',
        'waktu_mulai': '06:00',
        'waktu_selesai': '14:00',
        'waktu': '06:00 - 14:00',
      };

      final shiftInfo = ShiftInfo.fromJson(json);

      expect(shiftInfo.jadwalId, equals(10));
      expect(shiftInfo.tanggal, equals(DateTime.parse('2025-01-25')));
      expect(shiftInfo.hari, equals('Sabtu'));
      expect(shiftInfo.shiftCode, equals('P'));
      expect(shiftInfo.waktuMulai, equals('06:00'));
      expect(shiftInfo.waktuSelesai, equals('14:00'));
      expect(shiftInfo.waktu, equals('06:00 - 14:00'));
    });

    test('fromJson uses id fallback when jadwal_id is missing', () {
      final json = {
        'id': 5,
        'tanggal': '2025-01-25',
        'hari': 'Sabtu',
        'shift_code': 'P',
      };

      final shiftInfo = ShiftInfo.fromJson(json);
      expect(shiftInfo.jadwalId, equals(5));
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'jadwal_id': 1,
        'tanggal': '2025-01-25',
        'shift_code': 'L',
      };

      final shiftInfo = ShiftInfo.fromJson(json);

      expect(shiftInfo.waktuMulai, isNull);
      expect(shiftInfo.waktuSelesai, isNull);
      expect(shiftInfo.waktu, isNull);
    });

    test('fromJson handles empty json with defaults', () {
      final json = <String, dynamic>{};
      final shiftInfo = ShiftInfo.fromJson(json);

      expect(shiftInfo.jadwalId, equals(0));
      expect(shiftInfo.hari, equals(''));
      expect(shiftInfo.shiftCode, equals(''));
    });

    test('fromJson handles string jadwal_id', () {
      final json = {
        'jadwal_id': '25',
        'tanggal': '2025-01-25',
        'hari': 'Sabtu',
        'shift_code': 'P',
      };

      final shiftInfo = ShiftInfo.fromJson(json);
      expect(shiftInfo.jadwalId, equals(25));
    });
  });

  group('TukarShiftRequest', () {
    Map<String, dynamic> createFullJson({
      String status = 'pending',
      String jenis = 'saya',
    }) {
      return {
        'id': 1,
        'status': status,
        'jenis': jenis,
        'tanggal_request': '2025-01-20',
        'shift_saya': {
          'jadwal_id': 10,
          'tanggal': '2025-01-25',
          'hari': 'Sabtu',
          'shift_code': 'P',
          'waktu_mulai': '06:00',
          'waktu_selesai': '14:00',
          'waktu': '06:00 - 14:00',
        },
        'shift_diminta': {
          'jadwal_id': 20,
          'tanggal': '2025-01-26',
          'hari': 'Minggu',
          'shift_code': 'S',
          'waktu_mulai': '14:00',
          'waktu_selesai': '22:00',
          'waktu': '14:00 - 22:00',
        },
        'karyawan_tujuan': {
          'id': 2,
          'nama': 'Jane Smith',
          'nik': 'EMP002',
          'no_telp': '081234567891',
          'divisi': 'Cleaning',
          'jabatan': 'Staff',
        },
        'catatan': 'Need to swap shifts',
        'alasan_penolakan': null,
        'tanggal_diproses': null,
      };
    }

    test('fromJson creates instance correctly with all fields', () {
      final json = createFullJson();
      json['alasan_penolakan'] = 'Not approved';
      json['tanggal_diproses'] = '2025-01-22T10:00:00.000Z';

      final request = TukarShiftRequest.fromJson(json);

      expect(request.id, equals(1));
      expect(request.status, equals('pending'));
      expect(request.jenis, equals('saya'));
      expect(request.tanggalRequest, equals(DateTime.parse('2025-01-20')));
      expect(request.shiftSaya.jadwalId, equals(10));
      expect(request.shiftSaya.shiftCode, equals('P'));
      expect(request.shiftDiminta.jadwalId, equals(20));
      expect(request.shiftDiminta.shiftCode, equals('S'));
      expect(request.karyawanTujuan.nama, equals('Jane Smith'));
      expect(request.catatan, equals('Need to swap shifts'));
      expect(request.alasanPenolakan, equals('Not approved'));
      expect(request.tanggalDiproses, equals(DateTime.parse('2025-01-22T10:00:00.000Z')));
    });

    test('fromJson handles null optional fields', () {
      final json = createFullJson();
      final request = TukarShiftRequest.fromJson(json);

      expect(request.alasanPenolakan, isNull);
      expect(request.tanggalDiproses, isNull);
    });

    test('fromJson handles missing nested objects with empty maps', () {
      final json = {
        'id': 1,
        'status': 'pending',
        'jenis': 'saya',
        'tanggal_request': '2025-01-20',
        'shift_saya': null,
        'shift_diminta': null,
        'karyawan_tujuan': null,
      };

      final request = TukarShiftRequest.fromJson(json);

      // Should not throw; uses empty map fallback
      expect(request.shiftSaya.jadwalId, equals(0));
      expect(request.shiftDiminta.jadwalId, equals(0));
      expect(request.karyawanTujuan.id, equals(0));
    });

    test('isPending returns true when status is pending', () {
      final request = TukarShiftRequest.fromJson(createFullJson(status: 'pending'));
      expect(request.isPending, isTrue);
    });

    test('isPending returns false when status is not pending', () {
      final request = TukarShiftRequest.fromJson(createFullJson(status: 'disetujui'));
      expect(request.isPending, isFalse);
    });

    test('isDisetujui returns true when status is disetujui', () {
      final request = TukarShiftRequest.fromJson(createFullJson(status: 'disetujui'));
      expect(request.isDisetujui, isTrue);
    });

    test('isDisetujui returns false when status is not disetujui', () {
      final request = TukarShiftRequest.fromJson(createFullJson(status: 'pending'));
      expect(request.isDisetujui, isFalse);
    });

    test('canDelete returns true when pending and jenis is saya', () {
      final request = TukarShiftRequest.fromJson(
        createFullJson(status: 'pending', jenis: 'saya'),
      );
      expect(request.canDelete, isTrue);
    });

    test('canDelete returns false when not pending', () {
      final request = TukarShiftRequest.fromJson(
        createFullJson(status: 'disetujui', jenis: 'saya'),
      );
      expect(request.canDelete, isFalse);
    });

    test('canDelete returns false when jenis is not saya', () {
      final request = TukarShiftRequest.fromJson(
        createFullJson(status: 'pending', jenis: 'orang_lain'),
      );
      expect(request.canDelete, isFalse);
    });

    test('canCancel returns true when disetujui and jenis is saya', () {
      final request = TukarShiftRequest.fromJson(
        createFullJson(status: 'disetujui', jenis: 'saya'),
      );
      expect(request.canCancel, isTrue);
    });

    test('canCancel returns false when not disetujui', () {
      final request = TukarShiftRequest.fromJson(
        createFullJson(status: 'pending', jenis: 'saya'),
      );
      expect(request.canCancel, isFalse);
    });

    test('canCancel returns false when jenis is not saya', () {
      final request = TukarShiftRequest.fromJson(
        createFullJson(status: 'disetujui', jenis: 'orang_lain'),
      );
      expect(request.canCancel, isFalse);
    });
  });

  group('JadwalShift', () {
    test('fromJson creates instance correctly', () {
      final json = {
        'id': 1,
        'tanggal': '2025-01-25',
        'hari': 'Sabtu',
        'shift_code': 'P',
        'waktu_mulai': '06:00',
        'waktu_selesai': '14:00',
        'is_libur': false,
      };

      final jadwal = JadwalShift.fromJson(json);

      expect(jadwal.id, equals(1));
      expect(jadwal.tanggal, equals(DateTime.parse('2025-01-25')));
      expect(jadwal.hari, equals('Sabtu'));
      expect(jadwal.shiftCode, equals('P'));
      expect(jadwal.waktuMulai, equals('06:00'));
      expect(jadwal.waktuSelesai, equals('14:00'));
      expect(jadwal.isLibur, isFalse);
    });

    test('fromJson uses jadwal_id fallback when id is missing', () {
      final json = {
        'jadwal_id': 42,
        'tanggal': '2025-01-25',
        'hari': 'Sabtu',
        'shift_code': 'P',
        'is_libur': false,
      };

      final jadwal = JadwalShift.fromJson(json);
      expect(jadwal.id, equals(42));
    });

    test('fromJson detects libur from is_libur true', () {
      final json = {
        'id': 1,
        'tanggal': '2025-01-26',
        'hari': 'Minggu',
        'shift_code': 'L',
        'is_libur': true,
      };

      final jadwal = JadwalShift.fromJson(json);
      expect(jadwal.isLibur, isTrue);
    });

    test('fromJson detects libur from is_libur integer 1', () {
      final json = {
        'id': 1,
        'tanggal': '2025-01-26',
        'hari': 'Minggu',
        'shift_code': 'X',
        'is_libur': 1,
      };

      final jadwal = JadwalShift.fromJson(json);
      expect(jadwal.isLibur, isTrue);
    });

    test('fromJson detects libur from is_libur string true', () {
      final json = {
        'id': 1,
        'tanggal': '2025-01-26',
        'hari': 'Minggu',
        'shift_code': 'X',
        'is_libur': 'true',
      };

      final jadwal = JadwalShift.fromJson(json);
      expect(jadwal.isLibur, isTrue);
    });

    test('fromJson detects libur from shift_code L', () {
      final json = {
        'id': 1,
        'tanggal': '2025-01-26',
        'hari': 'Minggu',
        'shift_code': 'L',
        'is_libur': false,
      };

      final jadwal = JadwalShift.fromJson(json);
      expect(jadwal.isLibur, isTrue);
    });

    test('fromJson handles string id', () {
      final json = {
        'id': '99',
        'tanggal': '2025-01-25',
        'hari': 'Sabtu',
        'shift_code': 'P',
        'is_libur': false,
      };

      final jadwal = JadwalShift.fromJson(json);
      expect(jadwal.id, equals(99));
    });

    test('toString returns correct format', () {
      final jadwal = JadwalShift(
        id: 1,
        tanggal: DateTime.parse('2025-01-25'),
        hari: 'Sabtu',
        shiftCode: 'P',
        isLibur: false,
      );

      final str = jadwal.toString();
      expect(str, contains('JadwalShift'));
      expect(str, contains('id: 1'));
      expect(str, contains('hari: Sabtu'));
      expect(str, contains('shiftCode: P'));
    });
  });

  group('KaryawanWithShift', () {
    test('fromJson creates instance correctly', () {
      final json = {
        'id': 2,
        'nama': 'Jane Smith',
        'nik': 'EMP002',
        'no_telp': '081234567891',
        'divisi': 'Cleaning',
        'jabatan': 'Staff',
        'shift': {
          'jadwal_id': 10,
          'tanggal': '2025-01-25',
          'hari': 'Sabtu',
          'shift_code': 'P',
          'waktu_mulai': '06:00',
          'waktu_selesai': '14:00',
        },
      };

      final karyawan = KaryawanWithShift.fromJson(json);

      expect(karyawan.id, equals(2));
      expect(karyawan.nama, equals('Jane Smith'));
      expect(karyawan.nik, equals('EMP002'));
      expect(karyawan.noTelp, equals('081234567891'));
      expect(karyawan.divisi, equals('Cleaning'));
      expect(karyawan.jabatan, equals('Staff'));
      expect(karyawan.shift.jadwalId, equals(10));
      expect(karyawan.shift.shiftCode, equals('P'));
    });

    test('fromJson handles null shift with empty map fallback', () {
      final json = {
        'id': 3,
        'nama': 'Test',
        'nik': 'EMP003',
        'no_telp': '000',
        'divisi': 'IT',
        'jabatan': 'Dev',
        'shift': null,
      };

      final karyawan = KaryawanWithShift.fromJson(json);

      expect(karyawan.shift.jadwalId, equals(0));
      expect(karyawan.shift.shiftCode, equals(''));
    });

    test('fromJson handles string id', () {
      final json = <String, dynamic>{
        'id': '50',
        'nama': 'Test',
        'nik': 'EMP050',
        'no_telp': '000',
        'divisi': 'IT',
        'jabatan': 'Dev',
        'shift': <String, dynamic>{},
      };

      final karyawan = KaryawanWithShift.fromJson(json);
      expect(karyawan.id, equals(50));
    });

    test('fromJson handles null values with defaults', () {
      final json = <String, dynamic>{};
      final karyawan = KaryawanWithShift.fromJson(json);

      expect(karyawan.id, equals(0));
      expect(karyawan.nama, equals(''));
      expect(karyawan.nik, equals(''));
      expect(karyawan.noTelp, equals(''));
      expect(karyawan.divisi, equals(''));
      expect(karyawan.jabatan, equals(''));
    });
  });
}
