import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_mobile/data/models/presensi_model.dart';

void main() {
  group('StatistikPresensi', () {
    test('fromJson creates instance correctly', () {
      final json = {'hadir': 20, 'izin': 3, 'alpa': 1};
      final statistik = StatistikPresensi.fromJson(json);

      expect(statistik.hadir, equals(20));
      expect(statistik.izin, equals(3));
      expect(statistik.alpa, equals(1));
    });

    test('fromJson handles null values with defaults', () {
      final json = <String, dynamic>{};
      final statistik = StatistikPresensi.fromJson(json);

      expect(statistik.hadir, equals(0));
      expect(statistik.izin, equals(0));
      expect(statistik.alpa, equals(0));
    });
  });

  group('PresensiHariIni', () {
    test('fromJson creates instance correctly with all fields', () {
      final json = {
        'waktu_masuk': '07:30',
        'waktu_pulang': '16:00',
        'status_masuk': 'Tepat Waktu',
        'status_pulang': 'Tepat Waktu',
        'is_alpa': false,
      };
      final presensi = PresensiHariIni.fromJson(json);

      expect(presensi.waktuMasuk, equals('07:30'));
      expect(presensi.waktuPulang, equals('16:00'));
      expect(presensi.statusMasuk, equals('Tepat Waktu'));
      expect(presensi.statusPulang, equals('Tepat Waktu'));
      expect(presensi.isAlpa, isFalse);
    });

    test('fromJson handles null optional fields', () {
      final json = <String, dynamic>{};
      final presensi = PresensiHariIni.fromJson(json);

      expect(presensi.waktuMasuk, isNull);
      expect(presensi.waktuPulang, isNull);
      expect(presensi.statusMasuk, isNull);
      expect(presensi.statusPulang, isNull);
      expect(presensi.isAlpa, isFalse);
    });

    test('fromJson handles is_alpa true', () {
      final json = {'is_alpa': true};
      final presensi = PresensiHariIni.fromJson(json);

      expect(presensi.isAlpa, isTrue);
    });
  });

  group('JadwalHariIni', () {
    test('fromJson creates instance correctly', () {
      final json = {
        'shift_code': 'P',
        'waktu_mulai': '06:00',
        'waktu_selesai': '14:00',
        'is_libur': false,
      };
      final jadwal = JadwalHariIni.fromJson(json);

      expect(jadwal.shiftCode, equals('P'));
      expect(jadwal.waktuMulai, equals('06:00'));
      expect(jadwal.waktuSelesai, equals('14:00'));
      expect(jadwal.isLibur, isFalse);
    });

    test('fromJson handles libur shift', () {
      final json = {
        'shift_code': 'L',
        'waktu_mulai': null,
        'waktu_selesai': null,
        'is_libur': true,
      };
      final jadwal = JadwalHariIni.fromJson(json);

      expect(jadwal.shiftCode, equals('L'));
      expect(jadwal.waktuMulai, isNull);
      expect(jadwal.waktuSelesai, isNull);
      expect(jadwal.isLibur, isTrue);
    });

    test('fromJson handles null values with defaults', () {
      final json = <String, dynamic>{};
      final jadwal = JadwalHariIni.fromJson(json);

      expect(jadwal.shiftCode, equals(''));
      expect(jadwal.isLibur, isFalse);
    });
  });

  group('ProjectInfo', () {
    test('fromJson creates instance correctly', () {
      final json = {
        'id': 1,
        'nama': 'Project Alpha',
        'tanggal_mulai': '2025-01-01',
        'waktu_toleransi': 15,
      };
      final projectInfo = ProjectInfo.fromJson(json);

      expect(projectInfo.id, equals(1));
      expect(projectInfo.nama, equals('Project Alpha'));
      expect(projectInfo.tanggalMulai, equals('2025-01-01'));
      expect(projectInfo.waktuToleransi, equals(15));
    });

    test('fromJson handles null values with defaults', () {
      final json = <String, dynamic>{};
      final projectInfo = ProjectInfo.fromJson(json);

      expect(projectInfo.id, equals(0));
      expect(projectInfo.nama, equals(''));
      expect(projectInfo.tanggalMulai, equals(''));
      expect(projectInfo.waktuToleransi, equals(0));
    });
  });

  group('MonthInfo', () {
    test('fromJson creates instance correctly', () {
      final json = {
        'bulan': '2025-01',
        'bulan_display': 'Januari 2025',
        'start_date': '2025-01-01',
        'end_date': '2025-01-31',
      };
      final monthInfo = MonthInfo.fromJson(json);

      expect(monthInfo.bulan, equals('2025-01'));
      expect(monthInfo.bulanDisplay, equals('Januari 2025'));
      expect(monthInfo.startDate, equals('2025-01-01'));
      expect(monthInfo.endDate, equals('2025-01-31'));
    });

    test('fromJson handles null values with defaults', () {
      final json = <String, dynamic>{};
      final monthInfo = MonthInfo.fromJson(json);

      expect(monthInfo.bulan, equals(''));
      expect(monthInfo.bulanDisplay, equals(''));
      expect(monthInfo.startDate, equals(''));
      expect(monthInfo.endDate, equals(''));
    });
  });

  group('PeriodInfo (presensi)', () {
    test('fromJson creates instance correctly', () {
      final json = {
        'start_date': '2025-01-01',
        'end_date': '2025-01-31',
        'bulan': '2025-01',
        'bulan_display': 'Januari 2025',
        'is_current_period': true,
      };
      final periodInfo = PeriodInfo.fromJson(json);

      expect(periodInfo.startDate, equals('2025-01-01'));
      expect(periodInfo.endDate, equals('2025-01-31'));
      expect(periodInfo.bulan, equals('2025-01'));
      expect(periodInfo.bulanDisplay, equals('Januari 2025'));
      expect(periodInfo.isCurrentPeriod, isTrue);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'start_date': '2025-01-01',
        'end_date': '2025-01-31',
        'bulan': '2025-01',
      };
      final periodInfo = PeriodInfo.fromJson(json);

      expect(periodInfo.bulanDisplay, isNull);
      expect(periodInfo.isCurrentPeriod, isNull);
    });

    test('fromJson handles empty json with defaults', () {
      final json = <String, dynamic>{};
      final periodInfo = PeriodInfo.fromJson(json);

      expect(periodInfo.startDate, equals(''));
      expect(periodInfo.endDate, equals(''));
      expect(periodInfo.bulan, equals(''));
    });
  });

  group('StatistikPeriode', () {
    test('fromJson creates instance correctly', () {
      final json = {
        'hadir': 20,
        'izin': 2,
        'alpa': 1,
        'libur': 4,
        'sakit': 1,
        'cuti': 0,
        'lembur': 3,
        'lembur_pending': 1,
        'terlambat': 2,
        'pulang_cepat': 0,
        'tidak_presensi_pulang': 1,
        'period_info': {
          'start_date': '2025-01-01',
          'end_date': '2025-01-31',
          'bulan': '2025-01',
        },
      };
      final statistik = StatistikPeriode.fromJson(json);

      expect(statistik.hadir, equals(20));
      expect(statistik.izin, equals(2));
      expect(statistik.alpa, equals(1));
      expect(statistik.libur, equals(4));
      expect(statistik.sakit, equals(1));
      expect(statistik.cuti, equals(0));
      expect(statistik.lembur, equals(3));
      expect(statistik.lemburPending, equals(1));
      expect(statistik.terlambat, equals(2));
      expect(statistik.pulangCepat, equals(0));
      expect(statistik.tidakPresensiPulang, equals(1));
      expect(statistik.periodInfo.startDate, equals('2025-01-01'));
    });

    test('fromJson handles null values with defaults', () {
      final json = <String, dynamic>{};
      final statistik = StatistikPeriode.fromJson(json);

      expect(statistik.hadir, equals(0));
      expect(statistik.izin, equals(0));
      expect(statistik.alpa, equals(0));
      expect(statistik.libur, equals(0));
      expect(statistik.sakit, equals(0));
      expect(statistik.cuti, equals(0));
      expect(statistik.lembur, equals(0));
      expect(statistik.lemburPending, equals(0));
      expect(statistik.terlambat, equals(0));
      expect(statistik.pulangCepat, equals(0));
      expect(statistik.tidakPresensiPulang, equals(0));
    });
  });

  group('ShiftInfo (presensi)', () {
    test('fromJson creates instance correctly', () {
      final json = {
        'kode': 'P',
        'waktu_mulai': '06:00',
        'waktu_selesai': '14:00',
      };
      final shiftInfo = ShiftInfo.fromJson(json);

      expect(shiftInfo.kode, equals('P'));
      expect(shiftInfo.waktuMulai, equals('06:00'));
      expect(shiftInfo.waktuSelesai, equals('14:00'));
    });

    test('fromJson handles null optional fields', () {
      final json = {'kode': 'L'};
      final shiftInfo = ShiftInfo.fromJson(json);

      expect(shiftInfo.kode, equals('L'));
      expect(shiftInfo.waktuMulai, isNull);
      expect(shiftInfo.waktuSelesai, isNull);
    });

    test('fromJson handles empty json with defaults', () {
      final json = <String, dynamic>{};
      final shiftInfo = ShiftInfo.fromJson(json);

      expect(shiftInfo.kode, equals(''));
    });
  });

  group('PresensiDetail', () {
    test('fromJson creates instance correctly', () {
      final json = {
        'waktu': '07:30:00',
        'foto': 'https://example.com/photo.jpg',
        'latitude': '-6.200000',
        'longitude': '106.816666',
        'keterangan': 'On time',
      };
      final detail = PresensiDetail.fromJson(json);

      expect(detail.waktu, equals('07:30:00'));
      expect(detail.foto, equals('https://example.com/photo.jpg'));
      expect(detail.latitude, closeTo(-6.2, 0.001));
      expect(detail.longitude, closeTo(106.816666, 0.001));
      expect(detail.keterangan, equals('On time'));
    });

    test('fromJson handles numeric latitude/longitude', () {
      final json = {
        'latitude': -6.2,
        'longitude': 106.8,
      };
      final detail = PresensiDetail.fromJson(json);

      expect(detail.latitude, closeTo(-6.2, 0.001));
      expect(detail.longitude, closeTo(106.8, 0.001));
    });

    test('fromJson handles null fields', () {
      final json = <String, dynamic>{};
      final detail = PresensiDetail.fromJson(json);

      expect(detail.waktu, isNull);
      expect(detail.foto, isNull);
      expect(detail.latitude, isNull);
      expect(detail.longitude, isNull);
      expect(detail.keterangan, isNull);
    });
  });

  group('HistoryItem', () {
    test('fromJson creates instance correctly with all fields', () {
      final json = {
        'tanggal': '2025-01-15',
        'hari': 'Rabu',
        'status': 'hadir',
        'status_display': 'Hadir',
        'badge': ['Terlambat', 'Pulang Cepat'],
        'masuk': '07:30',
        'pulang': '15:30',
        'is_clickable': true,
        'shift': {
          'kode': 'P',
          'waktu_mulai': '06:00',
          'waktu_selesai': '14:00',
        },
        'presensi_masuk': {
          'waktu': '07:30',
          'foto': 'photo_masuk.jpg',
          'latitude': '-6.2',
          'longitude': '106.8',
          'keterangan': null,
        },
        'presensi_pulang': {
          'waktu': '15:30',
          'foto': 'photo_pulang.jpg',
          'latitude': '-6.2',
          'longitude': '106.8',
          'keterangan': null,
        },
      };
      final item = HistoryItem.fromJson(json);

      expect(item.tanggal, equals('2025-01-15'));
      expect(item.hari, equals('Rabu'));
      expect(item.status, equals('hadir'));
      expect(item.statusDisplay, equals('Hadir'));
      expect(item.badge, equals(['Terlambat', 'Pulang Cepat']));
      expect(item.masuk, equals('07:30'));
      expect(item.pulang, equals('15:30'));
      expect(item.isClickable, isTrue);
      expect(item.shift, isNotNull);
      expect(item.shift!.kode, equals('P'));
      expect(item.presensiMasuk, isNotNull);
      expect(item.presensiMasuk!.waktu, equals('07:30'));
      expect(item.presensiPulang, isNotNull);
      expect(item.presensiPulang!.waktu, equals('15:30'));
    });

    test('fromJson handles empty badge list', () {
      final json = {
        'tanggal': '2025-01-15',
        'hari': 'Rabu',
        'status': 'hadir',
        'status_display': 'Hadir',
        'badge': [],
        'masuk': '07:00',
        'pulang': '15:00',
        'is_clickable': true,
      };
      final item = HistoryItem.fromJson(json);

      expect(item.badge, isEmpty);
    });

    test('fromJson handles null badge list', () {
      final json = {
        'tanggal': '2025-01-15',
        'hari': 'Rabu',
        'status': 'libur',
        'status_display': 'Libur',
        'badge': null,
        'masuk': '-',
        'pulang': '-',
        'is_clickable': false,
      };
      final item = HistoryItem.fromJson(json);

      expect(item.badge, isEmpty);
    });

    test('fromJson handles null nested objects', () {
      final json = {
        'tanggal': '2025-01-15',
        'hari': 'Rabu',
        'status': 'alpa',
        'status_display': 'Alpa',
        'badge': [],
        'masuk': '-',
        'pulang': '-',
        'is_clickable': false,
        'shift': null,
        'presensi_masuk': null,
        'presensi_pulang': null,
      };
      final item = HistoryItem.fromJson(json);

      expect(item.shift, isNull);
      expect(item.presensiMasuk, isNull);
      expect(item.presensiPulang, isNull);
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};
      final item = HistoryItem.fromJson(json);

      expect(item.tanggal, equals(''));
      expect(item.hari, equals(''));
      expect(item.status, equals(''));
      expect(item.statusDisplay, equals(''));
      expect(item.badge, isEmpty);
      expect(item.masuk, equals('-'));
      expect(item.pulang, equals('-'));
      expect(item.isClickable, isFalse);
    });
  });

  group('PresensiData', () {
    test('fromJson creates instance correctly with all nested objects', () {
      final json = {
        'statistik': {'hadir': 20, 'izin': 2, 'alpa': 1},
        'presensi_hari_ini': {
          'waktu_masuk': '07:30',
          'waktu_pulang': null,
          'status_masuk': 'Tepat Waktu',
          'status_pulang': null,
          'is_alpa': false,
        },
        'jadwal_hari_ini': {
          'shift_code': 'P',
          'waktu_mulai': '06:00',
          'waktu_selesai': '14:00',
          'is_libur': false,
        },
        'project_info': {
          'id': 1,
          'nama': 'Project Alpha',
          'tanggal_mulai': '2025-01-01',
          'waktu_toleransi': 15,
        },
        'period_info': {
          'start_date': '2025-01-01',
          'end_date': '2025-01-31',
          'bulan': '2025-01',
        },
        'month_info': {
          'bulan': '2025-01',
          'bulan_display': 'Januari 2025',
          'start_date': '2025-01-01',
          'end_date': '2025-01-31',
        },
        'enabled_izin_categories': ['sakit', 'izin', 'cuti_tahunan'],
        'enabled_sub_kategori_izin': ['cuti_menikah', 'cuti_melahirkan'],
      };

      final data = PresensiData.fromJson(json);

      expect(data.statistik.hadir, equals(20));
      expect(data.statistik.izin, equals(2));
      expect(data.statistik.alpa, equals(1));
      expect(data.presensiHariIni, isNotNull);
      expect(data.presensiHariIni!.waktuMasuk, equals('07:30'));
      expect(data.jadwalHariIni, isNotNull);
      expect(data.jadwalHariIni!.shiftCode, equals('P'));
      expect(data.projectInfo, isNotNull);
      expect(data.projectInfo!.nama, equals('Project Alpha'));
      expect(data.periodInfo, isNotNull);
      expect(data.periodInfo!.startDate, equals('2025-01-01'));
      expect(data.monthInfo, isNotNull);
      expect(data.monthInfo!.bulanDisplay, equals('Januari 2025'));
      expect(data.enabledIzinCategories, equals(['sakit', 'izin', 'cuti_tahunan']));
      expect(data.enabledSubKategoriIzin, equals(['cuti_menikah', 'cuti_melahirkan']));
    });

    test('fromJson handles null nested objects', () {
      final json = {
        'statistik': {'hadir': 0, 'izin': 0, 'alpa': 0},
        'presensi_hari_ini': null,
        'jadwal_hari_ini': null,
        'project_info': null,
        'period_info': null,
        'month_info': null,
        'enabled_izin_categories': null,
        'enabled_sub_kategori_izin': null,
      };

      final data = PresensiData.fromJson(json);

      expect(data.presensiHariIni, isNull);
      expect(data.jadwalHariIni, isNull);
      expect(data.projectInfo, isNull);
      expect(data.periodInfo, isNull);
      expect(data.monthInfo, isNull);
      expect(data.enabledIzinCategories, isEmpty);
      expect(data.enabledSubKategoriIzin, isEmpty);
    });

    test('fromJson handles missing statistik with empty map', () {
      final json = <String, dynamic>{};
      final data = PresensiData.fromJson(json);

      expect(data.statistik.hadir, equals(0));
      expect(data.statistik.izin, equals(0));
      expect(data.statistik.alpa, equals(0));
    });

    test('fromJson parses enabled categories from mixed list', () {
      final json = <String, dynamic>{
        'statistik': <String, dynamic>{},
        'enabled_izin_categories': ['sakit', 123, true],
        'enabled_sub_kategori_izin': [1, 2, 'cuti'],
      };

      final data = PresensiData.fromJson(json);

      expect(data.enabledIzinCategories, equals(['sakit', '123', 'true']));
      expect(data.enabledSubKategoriIzin, equals(['1', '2', 'cuti']));
    });
  });
}
