import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_mobile/data/models/karyawan_model.dart';
import 'package:presensi_mobile/data/models/jabatan_model.dart';

void main() {
  group('Jabatan (from jabatan_model)', () {
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

    test('fromJson handles null values with defaults', () {
      final json = <String, dynamic>{};
      final jabatan = Jabatan.fromJson(json);

      expect(jabatan.id, equals(0));
      expect(jabatan.nama, equals(''));
    });

    test('toJson produces correct map', () {
      final jabatan = Jabatan(id: 3, nama: 'Supervisor');
      final json = jabatan.toJson();

      expect(json['id'], equals(3));
      expect(json['nama_jabatan'], equals('Supervisor'));
    });
  });

  group('Penempatan', () {
    test('fromJson creates instance correctly', () {
      final json = {'id': 1, 'nama_project': 'Project Alpha'};
      final penempatan = Penempatan.fromJson(json);

      expect(penempatan.id, equals(1));
      expect(penempatan.namaProject, equals('Project Alpha'));
    });

    test('fromJson handles null values with defaults', () {
      final json = <String, dynamic>{};
      final penempatan = Penempatan.fromJson(json);

      expect(penempatan.id, equals(0));
      expect(penempatan.namaProject, equals(''));
    });

    test('toJson produces correct map', () {
      final penempatan = Penempatan(id: 5, namaProject: 'Project Beta');
      final json = penempatan.toJson();

      expect(json['id'], equals(5));
      expect(json['nama_project'], equals('Project Beta'));
    });
  });

  group('Formasi', () {
    test('fromJson creates instance correctly', () {
      final json = {'id': 1, 'nama_formasi': 'Formasi A'};
      final formasi = Formasi.fromJson(json);

      expect(formasi.id, equals(1));
      expect(formasi.namaFormasi, equals('Formasi A'));
    });

    test('fromJson handles null values with defaults', () {
      final json = <String, dynamic>{};
      final formasi = Formasi.fromJson(json);

      expect(formasi.id, equals(0));
      expect(formasi.namaFormasi, equals(''));
    });

    test('toJson produces correct map', () {
      final formasi = Formasi(id: 2, namaFormasi: 'Formasi B');
      final json = formasi.toJson();

      expect(json['id'], equals(2));
      expect(json['nama_formasi'], equals('Formasi B'));
    });
  });

  group('UnitKerja', () {
    test('fromJson creates instance correctly', () {
      final json = {'id': 1, 'nama_unit': 'Unit X'};
      final unitKerja = UnitKerja.fromJson(json);

      expect(unitKerja.id, equals(1));
      expect(unitKerja.namaUnit, equals('Unit X'));
    });

    test('fromJson handles null values with defaults', () {
      final json = <String, dynamic>{};
      final unitKerja = UnitKerja.fromJson(json);

      expect(unitKerja.id, equals(0));
      expect(unitKerja.namaUnit, equals(''));
    });

    test('toJson produces correct map', () {
      final unitKerja = UnitKerja(id: 3, namaUnit: 'Unit Y');
      final json = unitKerja.toJson();

      expect(json['id'], equals(3));
      expect(json['nama_unit'], equals('Unit Y'));
    });
  });

  group('Karyawan', () {
    test('fromJson creates instance correctly with all fields', () {
      final json = {
        'id': 10,
        'karyawan_id': 1,
        'nik': 'EMP001',
        'nama': 'John Doe',
        'username': 'johndoe',
        'no_telepon': '081234567890',
        'jenis_kelamin': 'L',
        'tanggal_lahir': '1990-05-15',
        'status': 'AKTIF',
        'jabatan': {'id': 1, 'nama_jabatan': 'Staff'},
        'penempatan': {'id': 1, 'nama_project': 'Project Alpha'},
        'formasi': {'id': 1, 'nama_formasi': 'Formasi A'},
        'unit_kerja': {'id': 1, 'nama_unit': 'Unit X'},
      };

      final karyawan = Karyawan.fromJson(json);

      expect(karyawan.id, equals(1));
      expect(karyawan.accountId, equals(10));
      expect(karyawan.nik, equals('EMP001'));
      expect(karyawan.nama, equals('John Doe'));
      expect(karyawan.username, equals('johndoe'));
      expect(karyawan.noTelepon, equals('081234567890'));
      expect(karyawan.jenisKelamin, equals('L'));
      expect(karyawan.tanggalLahir, equals('1990-05-15'));
      expect(karyawan.status, equals('AKTIF'));
      expect(karyawan.jabatan, isNotNull);
      expect(karyawan.jabatan!.id, equals(1));
      expect(karyawan.jabatan!.nama, equals('Staff'));
      expect(karyawan.penempatan, isNotNull);
      expect(karyawan.penempatan!.namaProject, equals('Project Alpha'));
      expect(karyawan.formasi, isNotNull);
      expect(karyawan.formasi!.namaFormasi, equals('Formasi A'));
      expect(karyawan.unitKerja, isNotNull);
      expect(karyawan.unitKerja!.namaUnit, equals('Unit X'));
    });

    test('fromJson uses karyawan_id for id when both present', () {
      final json = {
        'id': 10,
        'karyawan_id': 5,
        'nik': '',
        'nama': '',
        'username': '',
        'no_telepon': '',
        'jenis_kelamin': '',
        'status': '',
      };

      final karyawan = Karyawan.fromJson(json);

      expect(karyawan.id, equals(5));
      expect(karyawan.accountId, equals(10));
    });

    test('fromJson falls back to id when karyawan_id is missing', () {
      final json = {
        'id': 10,
        'nik': '',
        'nama': '',
        'username': '',
        'no_telepon': '',
        'jenis_kelamin': '',
        'status': '',
      };

      final karyawan = Karyawan.fromJson(json);

      expect(karyawan.id, equals(10));
      expect(karyawan.accountId, equals(10));
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 1,
        'nik': 'EMP002',
        'nama': 'Jane Doe',
        'username': 'janedoe',
        'no_telepon': '081234567891',
        'jenis_kelamin': 'P',
        'tanggal_lahir': null,
        'status': 'AKTIF',
        'jabatan': null,
        'penempatan': null,
        'formasi': null,
        'unit_kerja': null,
      };

      final karyawan = Karyawan.fromJson(json);

      expect(karyawan.tanggalLahir, isNull);
      expect(karyawan.jabatan, isNull);
      expect(karyawan.penempatan, isNull);
      expect(karyawan.formasi, isNull);
      expect(karyawan.unitKerja, isNull);
    });

    test('fromJson handles non-Map nested fields gracefully', () {
      final json = {
        'id': 1,
        'nik': 'EMP003',
        'nama': 'Test',
        'username': 'test',
        'no_telepon': '0000',
        'jenis_kelamin': 'L',
        'status': 'AKTIF',
        'jabatan': 'not a map',
        'penempatan': 123,
        'formasi': true,
        'unit_kerja': [],
      };

      final karyawan = Karyawan.fromJson(json);

      expect(karyawan.jabatan, isNull);
      expect(karyawan.penempatan, isNull);
      expect(karyawan.formasi, isNull);
      expect(karyawan.unitKerja, isNull);
    });

    test('jenisKelaminText returns Laki-laki for L', () {
      final karyawan = Karyawan(
        id: 1,
        accountId: 1,
        nik: 'EMP001',
        nama: 'Test',
        username: 'test',
        noTelepon: '000',
        jenisKelamin: 'L',
        status: 'AKTIF',
      );

      expect(karyawan.jenisKelaminText, equals('Laki-laki'));
    });

    test('jenisKelaminText returns Perempuan for P', () {
      final karyawan = Karyawan(
        id: 2,
        accountId: 2,
        nik: 'EMP002',
        nama: 'Test',
        username: 'test',
        noTelepon: '000',
        jenisKelamin: 'P',
        status: 'AKTIF',
      );

      expect(karyawan.jenisKelaminText, equals('Perempuan'));
    });

    test('jenisKelaminText returns Perempuan for non-L value', () {
      final karyawan = Karyawan(
        id: 3,
        accountId: 3,
        nik: 'EMP003',
        nama: 'Test',
        username: 'test',
        noTelepon: '000',
        jenisKelamin: '',
        status: 'AKTIF',
      );

      expect(karyawan.jenisKelaminText, equals('Perempuan'));
    });

    test('formattedTanggalLahir returns formatted date', () {
      final karyawan = Karyawan(
        id: 1,
        accountId: 1,
        nik: 'EMP001',
        nama: 'Test',
        username: 'test',
        noTelepon: '000',
        jenisKelamin: 'L',
        tanggalLahir: '1990-05-15',
        status: 'AKTIF',
      );

      expect(karyawan.formattedTanggalLahir, equals('15 Mei 1990'));
    });

    test('formattedTanggalLahir returns dash for null tanggalLahir', () {
      final karyawan = Karyawan(
        id: 1,
        accountId: 1,
        nik: 'EMP001',
        nama: 'Test',
        username: 'test',
        noTelepon: '000',
        jenisKelamin: 'L',
        tanggalLahir: null,
        status: 'AKTIF',
      );

      expect(karyawan.formattedTanggalLahir, equals('-'));
    });

    test('formattedTanggalLahir returns dash for empty tanggalLahir', () {
      final karyawan = Karyawan(
        id: 1,
        accountId: 1,
        nik: 'EMP001',
        nama: 'Test',
        username: 'test',
        noTelepon: '000',
        jenisKelamin: 'L',
        tanggalLahir: '',
        status: 'AKTIF',
      );

      expect(karyawan.formattedTanggalLahir, equals('-'));
    });

    test('formattedTanggalLahir returns raw value for invalid date', () {
      final karyawan = Karyawan(
        id: 1,
        accountId: 1,
        nik: 'EMP001',
        nama: 'Test',
        username: 'test',
        noTelepon: '000',
        jenisKelamin: 'L',
        tanggalLahir: 'not-a-date',
        status: 'AKTIF',
      );

      expect(karyawan.formattedTanggalLahir, equals('not-a-date'));
    });

    test('toJson produces correct map', () {
      final karyawan = Karyawan(
        id: 1,
        accountId: 10,
        nik: 'EMP001',
        nama: 'John Doe',
        username: 'johndoe',
        noTelepon: '081234567890',
        jenisKelamin: 'L',
        tanggalLahir: '1990-05-15',
        status: 'AKTIF',
        jabatan: Jabatan(id: 1, nama: 'Staff'),
        penempatan: Penempatan(id: 1, namaProject: 'Project Alpha'),
        formasi: Formasi(id: 1, namaFormasi: 'Formasi A'),
        unitKerja: UnitKerja(id: 1, namaUnit: 'Unit X'),
      );

      final json = karyawan.toJson();

      expect(json['id'], equals(10));
      expect(json['karyawan_id'], equals(1));
      expect(json['nik'], equals('EMP001'));
      expect(json['nama'], equals('John Doe'));
      expect(json['username'], equals('johndoe'));
      expect(json['no_telepon'], equals('081234567890'));
      expect(json['jenis_kelamin'], equals('L'));
      expect(json['tanggal_lahir'], equals('1990-05-15'));
      expect(json['status'], equals('AKTIF'));
      expect(json['jabatan'], isNotNull);
      expect(json['penempatan'], isNotNull);
      expect(json['formasi'], isNotNull);
      expect(json['unit_kerja'], isNotNull);
    });

    test('toJson handles null nested objects', () {
      final karyawan = Karyawan(
        id: 1,
        accountId: 10,
        nik: 'EMP001',
        nama: 'John Doe',
        username: 'johndoe',
        noTelepon: '081234567890',
        jenisKelamin: 'L',
        status: 'AKTIF',
      );

      final json = karyawan.toJson();

      expect(json['jabatan'], isNull);
      expect(json['penempatan'], isNull);
      expect(json['formasi'], isNull);
      expect(json['unit_kerja'], isNull);
    });
  });
}
