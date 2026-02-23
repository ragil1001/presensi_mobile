import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_data.dart';

void main() {
  group('Lembur List Response', () {
    test('should parse lembur list correctly', () {
      final data = TestData.lemburListResponse();
      expect(data['data'], isA<List>());
      expect(data['data'].length, 1);
    });

    test('should have time range', () {
      final data = TestData.lemburListResponse();
      final first = data['data'][0];
      expect(first['jam_mulai'], '15:00');
      expect(first['jam_selesai'], '18:00');
    });

    test('should have jenis lembur', () {
      final data = TestData.lemburListResponse();
      final first = data['data'][0];
      expect(first['kode_hari'], 'K');
      expect(first['kode_hari_text'], 'Hari Kerja');
    });

    test('should have status', () {
      final data = TestData.lemburListResponse();
      final first = data['data'][0];
      expect(first['status'], 'pending');
      expect(first['status_text'], 'Menunggu');
    });
  });
}
