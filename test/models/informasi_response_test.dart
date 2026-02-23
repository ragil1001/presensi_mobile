import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_data.dart';

void main() {
  group('Informasi Response', () {
    test('should parse informasi list', () {
      final data = TestData.informasiListResponse();
      expect(data['data'], isA<List>());
      expect(data['data'].length, 1);
    });

    test('should have judul and isi', () {
      final data = TestData.informasiListResponse();
      final first = data['data'][0];
      expect(first['judul'], 'Pengumuman Test');
      expect(first['isi'], isNotEmpty);
    });

    test('should track read status', () {
      final data = TestData.informasiListResponse();
      final first = data['data'][0];
      expect(first['is_read'], false);
    });
  });
}
