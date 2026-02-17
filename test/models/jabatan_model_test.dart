import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_mobile/data/models/jabatan_model.dart';

void main() {
  group('Jabatan', () {
    test('fromJson creates instance correctly with nama_jabatan', () {
      final json = {'id': 1, 'nama_jabatan': 'Manager'};
      final jabatan = Jabatan.fromJson(json);

      expect(jabatan.id, equals(1));
      expect(jabatan.nama, equals('Manager'));
    });

    test('fromJson creates instance correctly with nama fallback', () {
      final json = {'id': 2, 'nama': 'Staff'};
      final jabatan = Jabatan.fromJson(json);

      expect(jabatan.id, equals(2));
      expect(jabatan.nama, equals('Staff'));
    });

    test('fromJson prefers nama_jabatan over nama', () {
      final json = {'id': 3, 'nama_jabatan': 'Supervisor', 'nama': 'Staff'};
      final jabatan = Jabatan.fromJson(json);

      expect(jabatan.nama, equals('Supervisor'));
    });

    test('fromJson handles null values with defaults', () {
      final json = <String, dynamic>{};
      final jabatan = Jabatan.fromJson(json);

      expect(jabatan.id, equals(0));
      expect(jabatan.nama, equals(''));
    });

    test('fromJson handles null id', () {
      final json = {'id': null, 'nama_jabatan': 'Test'};
      final jabatan = Jabatan.fromJson(json);

      expect(jabatan.id, equals(0));
    });

    test('fromJson handles null nama_jabatan and null nama', () {
      final json = {'id': 1, 'nama_jabatan': null, 'nama': null};
      final jabatan = Jabatan.fromJson(json);

      expect(jabatan.nama, equals(''));
    });

    test('toJson produces correct map', () {
      final jabatan = Jabatan(id: 5, nama: 'Koordinator');
      final json = jabatan.toJson();

      expect(json['id'], equals(5));
      expect(json['nama_jabatan'], equals('Koordinator'));
    });

    test('toJson does not include nama key', () {
      final jabatan = Jabatan(id: 1, nama: 'Test');
      final json = jabatan.toJson();

      expect(json.containsKey('nama_jabatan'), isTrue);
      expect(json.containsKey('nama'), isFalse);
    });

    test('fromJson then toJson roundtrip preserves data', () {
      final originalJson = {'id': 10, 'nama_jabatan': 'Director'};
      final jabatan = Jabatan.fromJson(originalJson);
      final outputJson = jabatan.toJson();

      expect(outputJson['id'], equals(originalJson['id']));
      expect(outputJson['nama_jabatan'], equals(originalJson['nama_jabatan']));
    });
  });
}
