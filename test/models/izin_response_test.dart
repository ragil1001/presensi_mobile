import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_data.dart';

void main() {
  group('Izin List Response', () {
    test('should parse izin list correctly', () {
      final data = TestData.izinListResponse();
      expect(data['data'], isA<List>());
      expect(data['data'].length, 2);
    });

    test('should have pending and approved items', () {
      final data = TestData.izinListResponse();
      final statuses = (data['data'] as List).map((e) => e['status']).toSet();
      expect(statuses.contains('pending'), true);
      expect(statuses.contains('disetujui'), true);
    });

    test('should have date range', () {
      final data = TestData.izinListResponse();
      final first = data['data'][0];
      expect(first['tanggal_mulai'], isNotNull);
      expect(first['tanggal_selesai'], isNotNull);
    });

    test('should have kategori', () {
      final data = TestData.izinListResponse();
      final first = data['data'][0];
      expect(first['kategori'], 'Sakit');
    });
  });
}
