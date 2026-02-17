import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_mobile/data/models/project_model.dart';

void main() {
  group('ProjectShift', () {
    test('fromJson creates instance correctly', () {
      final json = {
        'id': 1,
        'kode': 'P',
        'waktu_mulai': '06:00',
        'waktu_selesai': '14:00',
      };

      final shift = ProjectShift.fromJson(json);

      expect(shift.id, equals(1));
      expect(shift.kode, equals('P'));
      expect(shift.waktuMulai, equals('06:00'));
      expect(shift.waktuSelesai, equals('14:00'));
    });

    test('fromJson handles null values with defaults', () {
      final json = <String, dynamic>{};
      final shift = ProjectShift.fromJson(json);

      expect(shift.id, equals(0));
      expect(shift.kode, equals(''));
      expect(shift.waktuMulai, equals(''));
      expect(shift.waktuSelesai, equals(''));
    });
  });

  group('ProjectLokasi', () {
    test('fromJson creates instance correctly', () {
      final json = {
        'nama': 'Office Building A',
        'latitude': -6.200000,
        'longitude': 106.816666,
      };

      final lokasi = ProjectLokasi.fromJson(json);

      expect(lokasi.nama, equals('Office Building A'));
      expect(lokasi.latitude, closeTo(-6.2, 0.001));
      expect(lokasi.longitude, closeTo(106.816666, 0.001));
    });

    test('fromJson handles integer coordinates', () {
      final json = {
        'nama': 'Office',
        'latitude': -6,
        'longitude': 107,
      };

      final lokasi = ProjectLokasi.fromJson(json);

      expect(lokasi.latitude, equals(-6.0));
      expect(lokasi.longitude, equals(107.0));
    });

    test('fromJson handles null values with defaults', () {
      final json = <String, dynamic>{};
      final lokasi = ProjectLokasi.fromJson(json);

      expect(lokasi.nama, equals(''));
      expect(lokasi.latitude, equals(0.0));
      expect(lokasi.longitude, equals(0.0));
    });
  });

  group('Project', () {
    test('fromJson creates instance correctly with all fields', () {
      final json = {
        'id': 1,
        'nama': 'Project Alpha',
        'bagian': 'Cleaning',
        'lokasi': {
          'nama': 'Office Building A',
          'latitude': -6.200000,
          'longitude': 106.816666,
        },
        'radius': 100,
        'waktu_toleransi': 15,
        'tanggal_assign': '2025-01-01',
        'shifts': [
          {
            'id': 1,
            'kode': 'P',
            'waktu_mulai': '06:00',
            'waktu_selesai': '14:00',
          },
          {
            'id': 2,
            'kode': 'S',
            'waktu_mulai': '14:00',
            'waktu_selesai': '22:00',
          },
          {
            'id': 3,
            'kode': 'M',
            'waktu_mulai': '22:00',
            'waktu_selesai': '06:00',
          },
        ],
      };

      final project = Project.fromJson(json);

      expect(project.id, equals(1));
      expect(project.nama, equals('Project Alpha'));
      expect(project.bagian, equals('Cleaning'));
      expect(project.lokasi, isNotNull);
      expect(project.lokasi!.nama, equals('Office Building A'));
      expect(project.lokasi!.latitude, closeTo(-6.2, 0.001));
      expect(project.lokasi!.longitude, closeTo(106.816666, 0.001));
      expect(project.radius, equals(100));
      expect(project.waktuToleransi, equals(15));
      expect(project.tanggalAssign, equals('2025-01-01'));
      expect(project.shifts.length, equals(3));
      expect(project.shifts[0].kode, equals('P'));
      expect(project.shifts[1].kode, equals('S'));
      expect(project.shifts[2].kode, equals('M'));
    });

    test('fromJson handles null lokasi', () {
      final json = {
        'id': 1,
        'nama': 'Project Beta',
        'bagian': 'Security',
        'lokasi': null,
        'radius': 50,
        'waktu_toleransi': 10,
        'tanggal_assign': '2025-02-01',
        'shifts': [],
      };

      final project = Project.fromJson(json);

      expect(project.lokasi, isNull);
    });

    test('fromJson handles non-Map lokasi gracefully', () {
      final json = {
        'id': 1,
        'nama': 'Project Gamma',
        'bagian': 'IT',
        'lokasi': 'not a map',
        'radius': 50,
        'waktu_toleransi': 10,
        'tanggal_assign': '2025-03-01',
        'shifts': [],
      };

      final project = Project.fromJson(json);

      expect(project.lokasi, isNull);
    });

    test('fromJson handles null shifts', () {
      final json = {
        'id': 1,
        'nama': 'Project Delta',
        'bagian': 'Parking',
        'lokasi': null,
        'radius': 80,
        'waktu_toleransi': 5,
        'tanggal_assign': '2025-04-01',
        'shifts': null,
      };

      final project = Project.fromJson(json);

      expect(project.shifts, isEmpty);
    });

    test('fromJson handles non-List shifts gracefully', () {
      final json = {
        'id': 1,
        'nama': 'Project Epsilon',
        'bagian': 'Maintenance',
        'lokasi': null,
        'radius': 60,
        'waktu_toleransi': 10,
        'tanggal_assign': '2025-05-01',
        'shifts': 'not a list',
      };

      final project = Project.fromJson(json);

      expect(project.shifts, isEmpty);
    });

    test('fromJson handles null values with defaults', () {
      final json = <String, dynamic>{};
      final project = Project.fromJson(json);

      expect(project.id, equals(0));
      expect(project.nama, equals(''));
      expect(project.bagian, equals(''));
      expect(project.lokasi, isNull);
      expect(project.radius, equals(0));
      expect(project.waktuToleransi, equals(0));
      expect(project.tanggalAssign, equals(''));
      expect(project.shifts, isEmpty);
    });

    test('fromJson creates project with single shift', () {
      final json = {
        'id': 2,
        'nama': 'Small Project',
        'bagian': 'Cleaning',
        'lokasi': {
          'nama': 'Mall XYZ',
          'latitude': -6.5,
          'longitude': 106.9,
        },
        'radius': 200,
        'waktu_toleransi': 30,
        'tanggal_assign': '2025-01-15',
        'shifts': [
          {
            'id': 10,
            'kode': 'FULL',
            'waktu_mulai': '08:00',
            'waktu_selesai': '17:00',
          },
        ],
      };

      final project = Project.fromJson(json);

      expect(project.shifts.length, equals(1));
      expect(project.shifts[0].id, equals(10));
      expect(project.shifts[0].kode, equals('FULL'));
      expect(project.shifts[0].waktuMulai, equals('08:00'));
      expect(project.shifts[0].waktuSelesai, equals('17:00'));
    });
  });
}
