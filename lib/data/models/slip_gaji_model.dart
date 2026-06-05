// lib/data/models/slip_gaji_model.dart

/// Item daftar slip gaji yang tersedia (per periode + project) untuk karyawan.
class SlipGajiPeriode {
  final int id;
  final int projectId;
  final int tahun;
  final int bulan;
  final String? namaProject;

  SlipGajiPeriode({
    required this.id,
    required this.projectId,
    required this.tahun,
    required this.bulan,
    this.namaProject,
  });

  factory SlipGajiPeriode.fromJson(Map<String, dynamic> json) {
    return SlipGajiPeriode(
      id: json['id'] as int,
      projectId: json['project_id'] as int? ?? 0,
      tahun: json['tahun'] as int,
      bulan: json['bulan'] as int,
      namaProject: (json['project'] is Map)
          ? (json['project']['nama_project'] as String?)
          : null,
    );
  }

  /// "Mei 2026" — label bulan dalam Bahasa Indonesia.
  String get periodeLabel {
    const namaBulan = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final idx = bulan.clamp(1, 12);
    return '${namaBulan[idx]} $tahun';
  }
}

/// Komponen pendapatan / potongan / beban dari payroll_detail.
/// Sumber JSONB di backend: `komponen_pendapatan`, `komponen_potongan`, `komponen_beban`.
class SlipGajiKomponen {
  final String kode;
  final String nama;
  final double nilai;

  SlipGajiKomponen({
    required this.kode,
    required this.nama,
    required this.nilai,
  });

  factory SlipGajiKomponen.fromJson(Map<String, dynamic> json) {
    final rawKode = (json['kode'] ?? json['code'] ?? '').toString();
    final rawNama = (json['nama'] ?? json['name'] ?? '').toString();
    return SlipGajiKomponen(
      kode: rawKode,
      nama: rawNama.isNotEmpty ? rawNama : _humanizeKode(rawKode),
      nilai: _toDouble(json['nilai'] ?? json['value'] ?? 0),
    );
  }

  /// Ubah kode teknis dengan underscore (mis. "BPJS_KESEHATAN_KARYAWAN")
  /// menjadi label manusiawi untuk ditampilkan ke karyawan.
  static String _humanizeKode(String kode) {
    if (kode.isEmpty) return '-';

    // Mapping khusus untuk kode-kode yang memang punya istilah tetap.
    const mapping = <String, String>{
      'BPJS_KESEHATAN_KARYAWAN': 'BPJS Kesehatan',
      'BPJS_KESEHATAN_PERUSAHAAN': 'BPJS Kesehatan (Perusahaan)',
      'BPJS_JHT_KARYAWAN': 'BPJS Jaminan Hari Tua',
      'BPJS_JHT_PERUSAHAAN': 'BPJS Jaminan Hari Tua (Perusahaan)',
      'BPJS_JP_KARYAWAN': 'BPJS Jaminan Pensiun',
      'BPJS_JP_PERUSAHAAN': 'BPJS Jaminan Pensiun (Perusahaan)',
      'BPJS_JKK_PERUSAHAAN': 'BPJS Jaminan Kecelakaan Kerja',
      'BPJS_JKM_PERUSAHAAN': 'BPJS Jaminan Kematian',
      'GAJI_POKOK': 'Gaji Pokok',
      'UANG_MAKAN': 'Uang Makan',
      'UANG_TRANSPORT': 'Uang Transport',
      'UPAH_LEMBUR': 'Upah Lembur',
      'POTONGAN_TERLAMBAT': 'Potongan Terlambat',
      'POTONGAN_MANGKIR': 'Potongan Mangkir',
      'POTONGAN_PULANG_AWAL': 'Potongan Pulang Awal',
      'POTONGAN_IZIN': 'Potongan Izin',
      'POTONGAN_CUTI': 'Potongan Cuti',
      'PINJAMAN': 'Pinjaman',
      'TABUNGAN': 'Tabungan',
    };

    if (mapping.containsKey(kode)) return mapping[kode]!;

    // Fallback umum: pisahkan underscore + Title Case tiap kata.
    return kode
        .split('_')
        .where((s) => s.isNotEmpty)
        .map((s) => s.length == 1
            ? s.toUpperCase()
            : s[0].toUpperCase() + s.substring(1).toLowerCase())
        .join(' ');
  }
}

/// Detail slip gaji per periode untuk karyawan login.
class SlipGajiDetail {
  final SlipGajiPeriode periode;

  // Header info
  final double gajiPokokDipakai;
  final String? gajiPokokLingkup;

  // Komponen
  final List<SlipGajiKomponen> pendapatan;
  final List<SlipGajiKomponen> potongan;
  final List<SlipGajiKomponen> beban;

  // Total
  final double totalPendapatan;
  final double totalPotongan;
  final double thp;
  final double totalBebanPerusahaan;
  final bool minThpCapTerjadi;

  // Optional summary presensi (JSONB di backend, bentuk bisa beda-beda).
  final Map<String, dynamic>? presensiSummary;

  SlipGajiDetail({
    required this.periode,
    required this.gajiPokokDipakai,
    this.gajiPokokLingkup,
    required this.pendapatan,
    required this.potongan,
    required this.beban,
    required this.totalPendapatan,
    required this.totalPotongan,
    required this.thp,
    required this.totalBebanPerusahaan,
    required this.minThpCapTerjadi,
    this.presensiSummary,
  });

  factory SlipGajiDetail.fromJson(Map<String, dynamic> json) {
    final periodeJson = (json['periode'] ?? const {}) as Map<String, dynamic>;
    final detailJson = (json['detail'] ?? const {}) as Map<String, dynamic>;

    List<SlipGajiKomponen> parseList(dynamic raw) {
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map(SlipGajiKomponen.fromJson)
            .toList();
      }
      if (raw is Map) {
        // Map<kode, nilai> fallback (kalau format lain).
        return raw.entries
            .map(
              (e) => SlipGajiKomponen(
                kode: e.key.toString(),
                nama: e.key.toString(),
                nilai: _toDouble(e.value),
              ),
            )
            .toList();
      }
      return const [];
    }

    return SlipGajiDetail(
      periode: SlipGajiPeriode.fromJson(periodeJson),
      gajiPokokDipakai: _toDouble(detailJson['gaji_pokok_dipakai']),
      gajiPokokLingkup: detailJson['gaji_pokok_lingkup'] as String?,
      pendapatan: parseList(detailJson['komponen_pendapatan']),
      potongan: parseList(detailJson['komponen_potongan']),
      beban: parseList(detailJson['komponen_beban']),
      totalPendapatan: _toDouble(detailJson['total_pendapatan']),
      totalPotongan: _toDouble(detailJson['total_potongan']),
      thp: _toDouble(detailJson['thp']),
      totalBebanPerusahaan: _toDouble(detailJson['total_beban_perusahaan']),
      minThpCapTerjadi: detailJson['min_thp_cap_terjadi'] == true,
      presensiSummary:
          (detailJson['presensi_summary'] is Map<String, dynamic>)
          ? detailJson['presensi_summary'] as Map<String, dynamic>
          : null,
    );
  }
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}
