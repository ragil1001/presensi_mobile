import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_data.dart';

void main() {
  group('Login Response', () {
    test('should parse login response correctly', () {
      final data = TestData.loginResponse();
      expect(data['token'], isNotEmpty);
      expect(data['user']['karyawan_id'], 1);
      expect(data['user']['nik'], 'K001');
      expect(data['user']['nama_lengkap'], 'Test Karyawan');
    });

    test('should contain required fields', () {
      final data = TestData.loginResponse();
      expect(data.containsKey('token'), true);
      expect(data.containsKey('user'), true);
      expect(data['user'].containsKey('karyawan_id'), true);
      expect(data['user'].containsKey('nik'), true);
    });
  });
}
