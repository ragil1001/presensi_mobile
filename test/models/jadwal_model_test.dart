import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_mobile/data/models/jadwal_model.dart';

void main() {
  group('TukarShiftInfo (jadwal)', () {
    test('fromJson creates instance correctly', () {
      final json = {'id': 1, 'dengan': 'John Doe'};
      final info = TukarShiftInfo.fromJson(json);

      expect(info.id, equals(1));
      expect(info.dengan, equals('John Doe'));
    });

    test('fromJson handles null values with defaults', () {
      final json = <String, dynamic>{};
      final info = TukarShiftInfo.fromJson(json);

      expect(info.id, equals(0));
      expect(info.dengan, equals(''));
    });
  });

  group('JadwalHarian', () {
    test('fromJson creates instance correctly with all fields', () {
      final json = {
        'id': 1,
        'tanggal': '2025-01-20',
        'hari': 'Senin',
        'tanggal_format': '20 Jan',
        'bulan_format': 'Januari',
        'tahun': '2025',
        'shift_code': 'P',
        'waktu_mulai': '06:00',
        'waktu_selesai': '14:00',
        'is_libur': false,
        'is_weekend': false,
        'is_ditukar': false,
        'tukar_shift_info': null,
      };

      final jadwal = JadwalHarian.fromJson(json);

      expect(jadwal.id, equals(1));
      expect(jadwal.tanggal, equals('2025-01-20'));
      expect(jadwal.hari, equals('Senin'));
      expect(jadwal.tanggalFormat, equals('20 Jan'));
      expect(jadwal.bulanFormat, equals('Januari'));
      expect(jadwal.tahun, equals('2025'));
      expect(jadwal.shiftCode, equals('P'));
      expect(jadwal.waktuMulai, equals('06:00'));
      expect(jadwal.waktuSelesai, equals('14:00'));
      expect(jadwal.isLibur, isFalse);
      expect(jadwal.isWeekend, isFalse);
      expect(jadwal.isDitukar, isFalse);
      expect(jadwal.tukarShiftInfo, isNull);
    });

    test('fromJson creates instance for libur shift', () {
      final json = {
        'id': 2,
        'tanggal': '2025-01-26',
        'hari': 'Minggu',
        'tanggal_format': '26 Jan',
        'bulan_format': 'Januari',
        'tahun': '2025',
        'shift_code': 'L',
        'waktu_mulai': null,
        'waktu_selesai': null,
        'is_libur': true,
        'is_weekend': true,
        'is_ditukar': false,
      };

      final jadwal = JadwalHarian.fromJson(json);

      expect(jadwal.shiftCode, equals('L'));
      expect(jadwal.waktuMulai, isNull);
      expect(jadwal.waktuSelesai, isNull);
      expect(jadwal.isLibur, isTrue);
      expect(jadwal.isWeekend, isTrue);
    });

    test('fromJson handles tukar_shift_info when present', () {
      final json = {
        'id': 3,
        'tanggal': '2025-01-22',
        'hari': 'Rabu',
        'tanggal_format': '22 Jan',
        'bulan_format': 'Januari',
        'tahun': '2025',
        'shift_code': 'S',
        'waktu_mulai': '14:00',
        'waktu_selesai': '22:00',
        'is_libur': false,
        'is_weekend': false,
        'is_ditukar': true,
        'tukar_shift_info': {'id': 10, 'dengan': 'Jane Doe'},
      };

      final jadwal = JadwalHarian.fromJson(json);

      expect(jadwal.isDitukar, isTrue);
      expect(jadwal.tukarShiftInfo, isNotNull);
      expect(jadwal.tukarShiftInfo!.id, equals(10));
      expect(jadwal.tukarShiftInfo!.dengan, equals('Jane Doe'));
    });

    test('fromJson handles null values with defaults', () {
      final json = <String, dynamic>{};
      final jadwal = JadwalHarian.fromJson(json);

      expect(jadwal.id, equals(0));
      expect(jadwal.tanggal, equals(''));
      expect(jadwal.hari, equals(''));
      expect(jadwal.tanggalFormat, equals(''));
      expect(jadwal.bulanFormat, equals(''));
      expect(jadwal.tahun, equals(''));
      expect(jadwal.shiftCode, equals(''));
      expect(jadwal.waktuMulai, isNull);
      expect(jadwal.waktuSelesai, isNull);
      expect(jadwal.isLibur, isFalse);
      expect(jadwal.isWeekend, isFalse);
      expect(jadwal.isDitukar, isFalse);
      expect(jadwal.tukarShiftInfo, isNull);
    });
  });

  group('ProjectInfoJadwal', () {
    test('fromJson creates instance correctly', () {
      final json = {
        'id': 1,
        'nama': 'Project Alpha',
        'tanggal_mulai': '2025-01-01',
      };

      final projectInfo = ProjectInfoJadwal.fromJson(json);

      expect(projectInfo.id, equals(1));
      expect(projectInfo.nama, equals('Project Alpha'));
      expect(projectInfo.tanggalMulai, equals('2025-01-01'));
    });

    test('fromJson handles null values with defaults', () {
      final json = <String, dynamic>{};
      final projectInfo = ProjectInfoJadwal.fromJson(json);

      expect(projectInfo.id, equals(0));
      expect(projectInfo.nama, equals(''));
      expect(projectInfo.tanggalMulai, equals(''));
    });
  });

  group('PeriodInfo (jadwal)', () {
    test('fromJson creates instance correctly', () {
      final json = {
        'start_date': '2025-01-01',
        'end_date': '2025-01-31',
        'bulan': '2025-01',
        'bulan_display': 'Januari 2025',
      };

      final periodInfo = PeriodInfo.fromJson(json);

      expect(periodInfo.startDate, equals('2025-01-01'));
      expect(periodInfo.endDate, equals('2025-01-31'));
      expect(periodInfo.bulan, equals('2025-01'));
      expect(periodInfo.bulanDisplay, equals('Januari 2025'));
    });

    test('fromJson handles null values with defaults', () {
      final json = <String, dynamic>{};
      final periodInfo = PeriodInfo.fromJson(json);

      expect(periodInfo.startDate, equals(''));
      expect(periodInfo.endDate, equals(''));
      expect(periodInfo.bulan, equals(''));
      expect(periodInfo.bulanDisplay, equals(''));
    });
  });

  group('JadwalBulan', () {
    test('fromJson creates instance correctly with data list', () {
      final json = {
        'data': [
          {
            'id': 1,
            'tanggal': '2025-01-20',
            'hari': 'Senin',
            'tanggal_format': '20 Jan',
            'bulan_format': 'Januari',
            'tahun': '2025',
            'shift_code': 'P',
            'waktu_mulai': '06:00',
            'waktu_selesai': '14:00',
            'is_libur': false,
            'is_weekend': false,
          },
          {
            'id': 2,
            'tanggal': '2025-01-21',
            'hari': 'Selasa',
            'tanggal_format': '21 Jan',
            'bulan_format': 'Januari',
            'tahun': '2025',
            'shift_code': 'S',
            'waktu_mulai': '14:00',
            'waktu_selesai': '22:00',
            'is_libur': false,
            'is_weekend': false,
          },
        ],
        'period_info': {
          'start_date': '2025-01-01',
          'end_date': '2025-01-31',
          'bulan': '2025-01',
          'bulan_display': 'Januari 2025',
        },
        'project_info': {
          'id': 1,
          'nama': 'Project Alpha',
          'tanggal_mulai': '2025-01-01',
        },
      };

      final jadwalBulan = JadwalBulan.fromJson(json);

      expect(jadwalBulan.jadwals.length, equals(2));
      expect(jadwalBulan.jadwals[0].shiftCode, equals('P'));
      expect(jadwalBulan.jadwals[1].shiftCode, equals('S'));
      expect(jadwalBulan.periodInfo.bulan, equals('2025-01'));
      expect(jadwalBulan.projectInfo.nama, equals('Project Alpha'));
    });

    test('fromJson handles null data list', () {
      final json = <String, dynamic>{
        'data': null,
        'period_info': <String, dynamic>{},
        'project_info': <String, dynamic>{},
      };

      final jadwalBulan = JadwalBulan.fromJson(json);

      expect(jadwalBulan.jadwals, isEmpty);
    });

    test('fromJson handles empty json with defaults', () {
      final json = <String, dynamic>{};
      final jadwalBulan = JadwalBulan.fromJson(json);

      expect(jadwalBulan.jadwals, isEmpty);
      expect(jadwalBulan.periodInfo.startDate, equals(''));
      expect(jadwalBulan.projectInfo.id, equals(0));
    });
  });
}
