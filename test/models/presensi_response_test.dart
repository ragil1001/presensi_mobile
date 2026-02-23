import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_data.dart';

void main() {
  group('Cek Presensi Response', () {
    test('should allow masuk when not yet present', () {
      final data = TestData.cekPresensiResponse(bisaMasuk: true);
      expect(data['bisa_masuk'], true);
      expect(data['bisa_pulang'], false);
      expect(data['presensi_masuk'], isNull);
    });

    test('should allow pulang when already masuk', () {
      final data = TestData.cekPresensiResponse(bisaMasuk: false);
      expect(data['bisa_masuk'], false);
      expect(data['bisa_pulang'], true);
      expect(data['presensi_masuk'], isNotNull);
    });

    test('should include shift info', () {
      final data = TestData.cekPresensiResponse();
      expect(data['shift']['kode_shift'], 'P');
      expect(data['shift']['jam_masuk'], '07:00');
    });
  });

  group('History Presensi Response', () {
    test('should parse history list', () {
      final data = TestData.historyPresensiResponse();
      expect(data['data'], isA<List>());
      expect(data['data'].length, 10);
    });

    test('should have pagination info', () {
      final data = TestData.historyPresensiResponse();
      expect(data['current_page'], 1);
      expect(data['last_page'], 1);
    });

    test('should have status for each entry', () {
      final data = TestData.historyPresensiResponse();
      for (final item in data['data']) {
        expect(item['status_masuk'], isNotNull);
        expect(item['status_pulang'], isNotNull);
      }
    });
  });
}
