import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_data.dart';

void main() {
  group('Jadwal Response', () {
    test('should parse jadwal list correctly', () {
      final data = TestData.jadwalResponse();
      expect(data['data'], isA<List>());
      expect(data['data'].length, 30);
    });

    test('should have off days', () {
      final data = TestData.jadwalResponse();
      final offDays = (data['data'] as List).where((j) => j['is_off'] == true);
      expect(offDays.isNotEmpty, true);
    });

    test('should have shift data for non-off days', () {
      final data = TestData.jadwalResponse();
      final workDays = (data['data'] as List).where((j) => j['is_off'] == false);
      for (final day in workDays) {
        expect(day['shift'], isNotNull);
        expect(day['shift']['kode_shift'], isNotNull);
      }
    });
  });
}
