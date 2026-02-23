import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_data.dart';

void main() {
  group('Tukar Shift Response', () {
    test('should parse tukar shift list', () {
      final data = TestData.tukarShiftListResponse();
      expect(data['data'], isA<List>());
      expect(data['data'].length, 1);
    });

    test('should have pengaju and penerima data', () {
      final data = TestData.tukarShiftListResponse();
      final first = data['data'][0];
      expect(first['nama_pengaju'], isNotNull);
      expect(first['nama_penerima'], isNotNull);
      expect(first['tanggal_pengaju'], isNotNull);
      expect(first['tanggal_penerima'], isNotNull);
    });

    test('should have shift codes', () {
      final data = TestData.tukarShiftListResponse();
      final first = data['data'][0];
      expect(first['shift_pengaju'], 'P');
      expect(first['shift_penerima'], 'S');
    });
  });
}
