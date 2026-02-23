import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_data.dart';

void main() {
  group('Statistik Periode Response', () {
    test('should parse statistik correctly', () {
      final data = TestData.statistikPeriodeResponse();
      expect(data['hadir'], 20);
      expect(data['terlambat'], 2);
      expect(data['izin'], 1);
      expect(data['alpha'], 0);
    });

    test('should include lembur count', () {
      final data = TestData.statistikPeriodeResponse();
      expect(data['lembur'], 3);
    });

    test('should have all attendance categories', () {
      final data = TestData.statistikPeriodeResponse();
      final keys = ['hadir', 'terlambat', 'izin', 'alpha', 'lembur', 'sakit', 'cuti'];
      for (final key in keys) {
        expect(data.containsKey(key), true, reason: 'Missing key: $key');
      }
    });
  });
}
