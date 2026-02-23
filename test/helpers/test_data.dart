/// Mock data factory for tests
class TestData {
  static Map<String, dynamic> loginResponse() => {
    'token': 'test-token-12345',
    'user': {
      'id': 1,
      'karyawan_id': 1,
      'nik': 'K001',
      'nama_lengkap': 'Test Karyawan',
      'jabatan': 'Staff',
      'project': 'Test Project',
    },
  };

  static Map<String, dynamic> berandaResponse() => {
    'karyawan': {
      'id': 1,
      'nik': 'K001',
      'nama_lengkap': 'Test Karyawan',
      'jabatan': 'Staff',
      'project_nama': 'Test Project',
    },
    'shift_hari_ini': {
      'kode_shift': 'P',
      'jam_masuk': '07:00',
      'jam_pulang': '15:00',
    },
    'presensi_hari_ini': {
      'masuk': null,
      'pulang': null,
    },
    'statistik': {
      'hadir': 20,
      'terlambat': 2,
      'izin': 1,
      'alpha': 0,
    },
  };

  static Map<String, dynamic> jadwalResponse() => {
    'data': List.generate(30, (i) {
      final date = DateTime.now().subtract(Duration(days: 15 - i));
      return {
        'id': i + 1,
        'tanggal': date.toIso8601String().substring(0, 10),
        'shift': {'kode_shift': i % 7 == 0 ? null : 'P', 'jam_masuk': '07:00', 'jam_pulang': '15:00'},
        'is_off': i % 7 == 0,
      };
    }),
  };

  static Map<String, dynamic> cekPresensiResponse({bool bisaMasuk = true}) => {
    'bisa_masuk': bisaMasuk,
    'bisa_pulang': !bisaMasuk,
    'shift': {
      'kode_shift': 'P',
      'jam_masuk': '07:00',
      'jam_pulang': '15:00',
    },
    'presensi_masuk': bisaMasuk ? null : {
      'waktu_presensi': '07:05:00',
      'status': 'HADIR',
    },
  };

  static Map<String, dynamic> historyPresensiResponse() => {
    'data': List.generate(10, (i) {
      final date = DateTime.now().subtract(Duration(days: i));
      return {
        'id': i + 1,
        'tanggal': date.toIso8601String().substring(0, 10),
        'shift': 'P',
        'jam_masuk': '07:0${i % 10}',
        'jam_pulang': '15:0${i % 10}',
        'status_masuk': 'HADIR',
        'status_pulang': 'HADIR',
      };
    }),
    'current_page': 1,
    'last_page': 1,
  };

  static Map<String, dynamic> izinListResponse() => {
    'data': [
      {
        'id': 1,
        'kategori': 'Sakit',
        'tanggal_mulai': '2026-02-20',
        'tanggal_selesai': '2026-02-20',
        'status': 'pending',
        'status_text': 'Menunggu',
        'keterangan': 'Sakit flu',
      },
      {
        'id': 2,
        'kategori': 'Cuti',
        'tanggal_mulai': '2026-02-15',
        'tanggal_selesai': '2026-02-16',
        'status': 'disetujui',
        'status_text': 'Disetujui',
        'keterangan': 'Cuti tahunan',
      },
    ],
    'current_page': 1,
    'last_page': 1,
  };

  static Map<String, dynamic> lemburListResponse() => {
    'data': [
      {
        'id': 1,
        'tanggal': '2026-02-20',
        'kode_hari': 'K',
        'kode_hari_text': 'Hari Kerja',
        'jam_mulai': '15:00',
        'jam_selesai': '18:00',
        'status': 'pending',
        'status_text': 'Menunggu',
      },
    ],
    'current_page': 1,
    'last_page': 1,
  };

  static Map<String, dynamic> tukarShiftListResponse() => {
    'data': [
      {
        'id': 1,
        'tanggal_pengaju': '2026-02-20',
        'shift_pengaju': 'P',
        'tanggal_penerima': '2026-02-21',
        'shift_penerima': 'S',
        'status': 'PENDING',
        'nama_pengaju': 'Karyawan A',
        'nama_penerima': 'Karyawan B',
      },
    ],
    'current_page': 1,
    'last_page': 1,
  };

  static Map<String, dynamic> informasiListResponse() => {
    'data': [
      {
        'id': 1,
        'judul': 'Pengumuman Test',
        'isi': 'Isi pengumuman test',
        'created_at': '2026-02-20 10:00:00',
        'is_read': false,
      },
    ],
    'current_page': 1,
    'last_page': 1,
  };

  static Map<String, dynamic> statistikPeriodeResponse() => {
    'hadir': 20,
    'terlambat': 2,
    'izin': 1,
    'alpha': 0,
    'lembur': 3,
    'sakit': 1,
    'cuti': 0,
  };

  static Map<String, dynamic> csBerandaResponse() => {
    'karyawan': {
      'id': 1,
      'nik': 'CS001',
      'nama_lengkap': 'CS Worker',
    },
    'area_hari_ini': {
      'id': 1,
      'nama_area': 'Lobby',
      'nama_sub_area': 'Lantai 1',
    },
    'tasks_summary': {
      'total': 5,
      'completed': 2,
      'remaining': 3,
    },
  };

  static Map<String, dynamic> csAreasResponse() => {
    'data': [
      {'id': 1, 'nama_area': 'Lobby', 'nama_sub_area': 'Lantai 1'},
      {'id': 2, 'nama_area': 'Toilet', 'nama_sub_area': 'Lantai 1'},
      {'id': 3, 'nama_area': 'Lobby', 'nama_sub_area': 'Lantai 2'},
    ],
  };

  static Map<String, dynamic> csTasksResponse() => {
    'data': [
      {
        'id': 1,
        'nama_task': 'Sapu lantai',
        'status': 'BELUM',
        'foto_sebelum': null,
        'foto_sesudah': null,
      },
      {
        'id': 2,
        'nama_task': 'Pel lantai',
        'status': 'SELESAI',
        'foto_sebelum': 'path/foto1.jpg',
        'foto_sesudah': 'path/foto2.jpg',
      },
    ],
  };
}
