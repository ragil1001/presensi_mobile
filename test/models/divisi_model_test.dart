import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_mobile/data/models/divisi_model.dart';

void main() {
  group('Divisi', () {
    test('fromJson creates instance correctly', () {
      final json = {'id': 1, 'nama': 'Cleaning'};
      final divisi = Divisi.fromJson(json);

      expect(divisi.id, equals(1));
      expect(divisi.nama, equals('Cleaning'));
    });

    test('fromJson handles different divisi names', () {
      final testCases = [
        {'id': 1, 'nama': 'Cleaning'},
        {'id': 2, 'nama': 'Security'},
        {'id': 3, 'nama': 'Parking'},
        {'id': 4, 'nama': 'Maintenance'},
      ];

      for (final json in testCases) {
        final divisi = Divisi.fromJson(json);
        expect(divisi.id, equals(json['id']));
        expect(divisi.nama, equals(json['nama']));
      }
    });

    test('fromJson handles null values with defaults', () {
      final json = <String, dynamic>{};
      final divisi = Divisi.fromJson(json);

      expect(divisi.id, equals(0));
      expect(divisi.nama, equals(''));
    });

    test('fromJson handles null id', () {
      final json = {'id': null, 'nama': 'IT'};
      final divisi = Divisi.fromJson(json);

      expect(divisi.id, equals(0));
    });

    test('fromJson handles null nama', () {
      final json = {'id': 1, 'nama': null};
      final divisi = Divisi.fromJson(json);

      expect(divisi.nama, equals(''));
    });

    test('fromJson handles empty nama', () {
      final json = {'id': 1, 'nama': ''};
      final divisi = Divisi.fromJson(json);

      expect(divisi.nama, equals(''));
    });

    test('constructor creates instance directly', () {
      final divisi = Divisi(id: 10, nama: 'Finance');

      expect(divisi.id, equals(10));
      expect(divisi.nama, equals('Finance'));
    });
  });
}
