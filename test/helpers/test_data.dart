import 'package:flutter_test/flutter_test.dart';

/// Sample JSON data for testing model deserialization

Map<String, dynamic> sampleKaryawanJson() => {
  'id': 1,
  'account_id': 10,
  'nik': 'EMP001',
  'nama': 'John Doe',
  'username': 'johndoe',
  'no_telepon': '081234567890',
  'jenis_kelamin': 'L',
  'tanggal_lahir': '1990-05-15',
  'status': 'AKTIF',
  'jabatan': {'id': 1, 'nama': 'Staff'},
  'penempatan': {'id': 1, 'nama_project': 'Project Alpha'},
  'formasi': {'id': 1, 'nama_formasi': 'Formasi A'},
  'unit_kerja': {'id': 1, 'nama_unit': 'Unit X'},
};

Map<String, dynamic> sampleNotificationJson() => {
  'id': 1,
  'type': 'izin_approved',
  'title': 'Leave Approved',
  'body': 'Your leave request has been approved',
  'data': {'pengajuan_izin_id': 5},
  'is_read': false,
  'read_at': null,
  'time_ago': '5 minutes ago',
  'created_at': '2025-01-15T10:00:00.000Z',
};

Map<String, dynamic> sampleInformasiJson() => {
  'id': 1,
  'informasi_id': 10,
  'judul': 'Important Announcement',
  'konten': 'Full content here',
  'konten_preview': 'Full content...',
  'has_file': true,
  'file_name': 'document.pdf',
  'file_type': 'pdf',
  'file_url': 'https://example.com/file.pdf',
  'file_size_formatted': '1.5 MB',
  'is_read': false,
  'read_at': null,
  'dikirim_at': '2025-01-15T10:00:00.000Z',
  'time_ago': '2 hours ago',
  'created_by': 'Admin',
  'created_at': '2025-01-15T10:00:00.000Z',
};

Map<String, dynamic> samplePengajuanIzinJson() => {
  'id': 1,
  'kategori_izin_id': 2,
  'kategori_izin': 'Sakit',
  'sub_kategori_izin': null,
  'deskripsi_izin': 'Sick leave',
  'durasi_otomatis': null,
  'tanggal_mulai': '2025-01-20',
  'tanggal_selesai': '2025-01-21',
  'durasi_hari': 2,
  'keterangan': 'Feeling unwell',
  'file_url': null,
  'status': 'PENDING',
  'status_text': 'Menunggu',
  'catatan_admin': null,
  'diproses_pada': null,
  'diproses_oleh': null,
  'created_at': '2025-01-19T08:00:00.000Z',
};

Map<String, dynamic> samplePengajuanLemburJson() => {
  'id': 1,
  'tanggal': '2025-01-20',
  'kode_hari': 'KERJA',
  'kode_hari_text': 'Hari Kerja',
  'jam_mulai': '18:00',
  'jam_selesai': '21:00',
  'file_skl_url': null,
  'keterangan_karyawan': 'Extra work needed',
  'status': 'PENDING',
  'status_text': 'Menunggu',
  'catatan_admin': null,
  'diproses_pada': null,
  'diproses_oleh': null,
  'created_at': '2025-01-19T08:00:00.000Z',
};

Map<String, dynamic> sampleJadwalHarianJson() => {
  'id': 1,
  'tanggal': '2025-01-20',
  'hari': 'Senin',
  'tanggal_format': '20 Jan',
  'bulan_format': 'Januari',
  'tahun': '2025',
  'shift_code': 'P',
  'waktu_mulai': '06:00',
  'waktu_selesai': '14:00',
  'is_libur': false,
  'is_weekend': false,
  'is_ditukar': false,
  'tukar_shift_info': null,
};

Map<String, dynamic> sampleTukarShiftJson() => {
  'id': 1,
  'status': 'PENDING',
  'jenis': 'TUKAR',
  'tanggal_request': '2025-01-20',
  'shift_saya': {
    'jadwal_id': 10,
    'tanggal': '2025-01-25',
    'hari': 'Sabtu',
    'shift_code': 'P',
    'waktu_mulai': '06:00',
    'waktu_selesai': '14:00',
    'waktu': '06:00 - 14:00',
  },
  'shift_diminta': {
    'jadwal_id': 20,
    'tanggal': '2025-01-26',
    'hari': 'Minggu',
    'shift_code': 'S',
    'waktu_mulai': '14:00',
    'waktu_selesai': '22:00',
    'waktu': '14:00 - 22:00',
  },
  'karyawan_tujuan': {
    'id': 2,
    'nama': 'Jane Smith',
    'nik': 'EMP002',
    'no_telp': '081234567891',
    'divisi': 'Cleaning',
    'jabatan': 'Staff',
  },
  'catatan': 'Need to swap shifts',
  'alasan_penolakan': null,
  'tanggal_diproses': null,
};
