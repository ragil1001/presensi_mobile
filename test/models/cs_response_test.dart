import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_data.dart';

void main() {
  group('CS Beranda Response', () {
    test('should parse CS beranda data', () {
      final data = TestData.csBerandaResponse();
      expect(data['karyawan']['nama_lengkap'], 'CS Worker');
    });

    test('should have area info', () {
      final data = TestData.csBerandaResponse();
      expect(data['area_hari_ini']['nama_area'], 'Lobby');
    });

    test('should have task summary', () {
      final data = TestData.csBerandaResponse();
      final summary = data['tasks_summary'];
      expect(summary['total'], 5);
      expect(summary['completed'], 2);
      expect(summary['remaining'], 3);
    });
  });

  group('CS Areas Response', () {
    test('should parse areas list', () {
      final data = TestData.csAreasResponse();
      expect(data['data'], isA<List>());
      expect(data['data'].length, 3);
    });
  });

  group('CS Tasks Response', () {
    test('should parse tasks list', () {
      final data = TestData.csTasksResponse();
      expect(data['data'], isA<List>());
      expect(data['data'].length, 2);
    });

    test('should have completed and pending tasks', () {
      final data = TestData.csTasksResponse();
      final statuses = (data['data'] as List).map((t) => t['status']).toSet();
      expect(statuses.contains('BELUM'), true);
      expect(statuses.contains('SELESAI'), true);
    });

    test('completed task should have photos', () {
      final data = TestData.csTasksResponse();
      final completed = (data['data'] as List).firstWhere((t) => t['status'] == 'SELESAI');
      expect(completed['foto_sebelum'], isNotNull);
      expect(completed['foto_sesudah'], isNotNull);
    });
  });
}
