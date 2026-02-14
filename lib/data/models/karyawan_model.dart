import 'jabatan_model.dart';

class Penempatan {
  final int id;
  final String namaProject;

  Penempatan({required this.id, required this.namaProject});

  factory Penempatan.fromJson(Map<String, dynamic> json) {
    return Penempatan(
      id: json['id'] ?? 0,
      namaProject: json['nama_project'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nama_project': namaProject};
  }
}

class Formasi {
  final int id;
  final String namaFormasi;

  Formasi({required this.id, required this.namaFormasi});

  factory Formasi.fromJson(Map<String, dynamic> json) {
    return Formasi(
      id: json['id'] ?? 0,
      namaFormasi: json['nama_formasi'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nama_formasi': namaFormasi};
  }
}

class UnitKerja {
  final int id;
  final String namaUnit;

  UnitKerja({required this.id, required this.namaUnit});

  factory UnitKerja.fromJson(Map<String, dynamic> json) {
    return UnitKerja(
      id: json['id'] ?? 0,
      namaUnit: json['nama_unit'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nama_unit': namaUnit};
  }
}

class Karyawan {
  final int id;
  final int accountId;
  final String nik;
  final String nama;
  final String username;
  final String noTelepon;
  final String jenisKelamin;
  final String? tanggalLahir;
  final String status;
  final Jabatan? jabatan;
  final Penempatan? penempatan;
  final Formasi? formasi;
  final UnitKerja? unitKerja;

  Karyawan({
    required this.id,
    required this.accountId,
    required this.nik,
    required this.nama,
    required this.username,
    required this.noTelepon,
    required this.jenisKelamin,
    this.tanggalLahir,
    required this.status,
    this.jabatan,
    this.penempatan,
    this.formasi,
    this.unitKerja,
  });

  factory Karyawan.fromJson(Map<String, dynamic> json) {
    return Karyawan(
      id: json['karyawan_id'] ?? json['id'] ?? 0,
      accountId: json['id'] ?? 0,
      nik: json['nik'] ?? '',
      nama: json['nama'] ?? '',
      username: json['username'] ?? '',
      noTelepon: json['no_telepon'] ?? '',
      jenisKelamin: json['jenis_kelamin'] ?? '',
      tanggalLahir: json['tanggal_lahir'],
      status: json['status'] ?? '',
      jabatan: json['jabatan'] != null && json['jabatan'] is Map
          ? Jabatan.fromJson(json['jabatan'] as Map<String, dynamic>)
          : null,
      penempatan: json['penempatan'] != null && json['penempatan'] is Map
          ? Penempatan.fromJson(json['penempatan'] as Map<String, dynamic>)
          : null,
      formasi: json['formasi'] != null && json['formasi'] is Map
          ? Formasi.fromJson(json['formasi'] as Map<String, dynamic>)
          : null,
      unitKerja: json['unit_kerja'] != null && json['unit_kerja'] is Map
          ? UnitKerja.fromJson(json['unit_kerja'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': accountId,
      'karyawan_id': id,
      'nik': nik,
      'nama': nama,
      'username': username,
      'no_telepon': noTelepon,
      'jenis_kelamin': jenisKelamin,
      'tanggal_lahir': tanggalLahir,
      'status': status,
      'jabatan': jabatan?.toJson(),
      'penempatan': penempatan?.toJson(),
      'formasi': formasi?.toJson(),
      'unit_kerja': unitKerja?.toJson(),
    };
  }

  String get jenisKelaminText =>
      jenisKelamin == 'L' ? 'Laki-laki' : 'Perempuan';

  String get formattedTanggalLahir {
    if (tanggalLahir == null || tanggalLahir!.isEmpty) return '-';
    try {
      final date = DateTime.parse(tanggalLahir!);
      final months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return tanggalLahir!;
    }
  }
}
