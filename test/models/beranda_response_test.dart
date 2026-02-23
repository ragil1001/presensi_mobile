import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_data.dart';

void main() {
  group('Beranda Response', () {
    test('should parse beranda data correctly', () {
      final data = TestData.berandaResponse();
      expect(data['karyawan']['nama_lengkap'], 'Test Karyawan');
      expect(data['shift_hari_ini']['kode_shift'], 'P');
      expect(data['statistik']['hadir'], 20);
    });

    test('should have presensi hari ini section', () {
      final data = TestData.berandaResponse();
      expect(data.containsKey('presensi_hari_ini'), true);
      expect(data['presensi_hari_ini']['masuk'], isNull);
    });

    test('should have shift info', () {
      final data = TestData.berandaResponse();
      final shift = data['shift_hari_ini'];
      expect(shift['jam_masuk'], '07:00');
      expect(shift['jam_pulang'], '15:00');
    });

    test('should have statistics', () {
      final data = TestData.berandaResponse();
      final stats = data['statistik'];
      expect(stats['hadir'], isA<int>());
      expect(stats['terlambat'], isA<int>());
      expect(stats['izin'], isA<int>());
      expect(stats['alpha'], isA<int>());
    });
  });
}
