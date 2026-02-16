class PresensiData {
  final StatistikPresensi statistik;
  final PresensiHariIni? presensiHariIni;
  final JadwalHariIni? jadwalHariIni;
  final ProjectInfo? projectInfo;
  final PeriodInfo? periodInfo;
  final MonthInfo? monthInfo;
  final List<String> enabledIzinCategories;
  final List<String> enabledSubKategoriIzin;

  PresensiData({
    required this.statistik,
    this.presensiHariIni,
    this.jadwalHariIni,
    this.projectInfo,
    this.periodInfo,
    this.monthInfo,
    this.enabledIzinCategories = const [],
    this.enabledSubKategoriIzin = const [],
  });

  factory PresensiData.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return [];
    }

    return PresensiData(
      statistik: StatistikPresensi.fromJson(json['statistik'] ?? {}),
      presensiHariIni: json['presensi_hari_ini'] != null
          ? PresensiHariIni.fromJson(json['presensi_hari_ini'])
          : null,
      jadwalHariIni: json['jadwal_hari_ini'] != null
          ? JadwalHariIni.fromJson(json['jadwal_hari_ini'])
          : null,
      projectInfo: json['project_info'] != null
          ? ProjectInfo.fromJson(json['project_info'])
          : null,
      periodInfo: json['period_info'] != null
          ? PeriodInfo.fromJson(json['period_info'])
          : null,
      monthInfo:
          json['month_info'] !=
              null // ✅ NEW
          ? MonthInfo.fromJson(json['month_info'])
          : null,
      enabledIzinCategories: parseStringList(json['enabled_izin_categories']),
      enabledSubKategoriIzin: parseStringList(
        json['enabled_sub_kategori_izin'],
      ),
    );
  }
}

class MonthInfo {
  final String bulan;
  final String bulanDisplay;
  final String startDate;
  final String endDate;

  MonthInfo({
    required this.bulan,
    required this.bulanDisplay,
    required this.startDate,
    required this.endDate,
  });

  factory MonthInfo.fromJson(Map<String, dynamic> json) {
    return MonthInfo(
      bulan: json['bulan'] ?? '',
      bulanDisplay: json['bulan_display'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
    );
  }
}

class StatistikPresensi {
  final int hadir;
  final int izin;
  final int alpa;

  StatistikPresensi({
    required this.hadir,
    required this.izin,
    required this.alpa,
  });

  factory StatistikPresensi.fromJson(Map<String, dynamic> json) {
    return StatistikPresensi(
      hadir: json['hadir'] ?? 0,
      izin: json['izin'] ?? 0,
      alpa: json['alpa'] ?? 0,
    );
  }
}

class PresensiHariIni {
  final String? waktuMasuk;
  final String? waktuPulang;
  final String? statusMasuk;
  final String? statusPulang;
  final bool isAlpa;

  PresensiHariIni({
    this.waktuMasuk,
    this.waktuPulang,
    this.statusMasuk,
    this.statusPulang,
    this.isAlpa = false,
  });

  factory PresensiHariIni.fromJson(Map<String, dynamic> json) {
    return PresensiHariIni(
      waktuMasuk: json['waktu_masuk'],
      waktuPulang: json['waktu_pulang'],
      statusMasuk: json['status_masuk'],
      statusPulang: json['status_pulang'],
      isAlpa: json['is_alpa'] ?? false,
    );
  }
}

class JadwalHariIni {
  final String shiftCode;
  final String? waktuMulai;
  final String? waktuSelesai;
  final bool isLibur;

  JadwalHariIni({
    required this.shiftCode,
    this.waktuMulai,
    this.waktuSelesai,
    required this.isLibur,
  });

  factory JadwalHariIni.fromJson(Map<String, dynamic> json) {
    return JadwalHariIni(
      shiftCode: json['shift_code'] ?? '',
      waktuMulai: json['waktu_mulai'],
      waktuSelesai: json['waktu_selesai'],
      isLibur: json['is_libur'] ?? false,
    );
  }
}

class StatistikPeriode {
  final int hadir;
  final int izin;
  final int alpa;
  final int libur;
  final int sakit;
  final int cuti;
  final int lembur;
  final int lemburPending;
  final int terlambat;
  final int pulangCepat;
  final int tidakPresensiPulang;
  final PeriodInfo periodInfo;

  StatistikPeriode({
    required this.hadir,
    required this.izin,
    required this.alpa,
    required this.libur,
    required this.sakit,
    required this.cuti,
    required this.lembur,
    required this.lemburPending,
    required this.terlambat,
    required this.pulangCepat,
    required this.tidakPresensiPulang,
    required this.periodInfo,
  });

  factory StatistikPeriode.fromJson(Map<String, dynamic> json) {
    return StatistikPeriode(
      hadir: json['hadir'] ?? 0,
      izin: json['izin'] ?? 0,
      alpa: json['alpa'] ?? 0,
      libur: json['libur'] ?? 0,
      sakit: json['sakit'] ?? 0,
      cuti: json['cuti'] ?? 0,
      lembur: json['lembur'] ?? 0,
      lemburPending: json['lembur_pending'] ?? 0,
      terlambat: json['terlambat'] ?? 0,
      pulangCepat: json['pulang_cepat'] ?? 0,
      tidakPresensiPulang: json['tidak_presensi_pulang'] ?? 0,
      periodInfo: PeriodInfo.fromJson(json['period_info'] ?? {}),
    );
  }
}

class PeriodInfo {
  final String startDate;
  final String endDate;
  final String bulan;
  final String? bulanDisplay;
  final bool? isCurrentPeriod; // ✅ NEW

  PeriodInfo({
    required this.startDate,
    required this.endDate,
    required this.bulan,
    this.bulanDisplay,
    this.isCurrentPeriod,
  });

  factory PeriodInfo.fromJson(Map<String, dynamic> json) {
    return PeriodInfo(
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      bulan: json['bulan'] ?? '',
      bulanDisplay: json['bulan_display'],
      isCurrentPeriod: json['is_current_period'], // ✅ NEW
    );
  }
}

class ProjectInfo {
  final int id;
  final String nama;
  final String tanggalMulai;
  final int waktuToleransi;

  ProjectInfo({
    required this.id,
    required this.nama,
    required this.tanggalMulai,
    this.waktuToleransi = 0,
  });

  factory ProjectInfo.fromJson(Map<String, dynamic> json) {
    return ProjectInfo(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
      tanggalMulai: json['tanggal_mulai'] ?? '',
      waktuToleransi: json['waktu_toleransi'] ?? 0,
    );
  }
}

class HistoryItem {
  final String tanggal;
  final String hari;
  final String status;
  final String statusDisplay;
  final List<String> badge;
  final String masuk;
  final String pulang;
  final bool isClickable;
  final ShiftInfo? shift;
  final PresensiDetail? presensiMasuk;
  final PresensiDetail? presensiPulang;

  HistoryItem({
    required this.tanggal,
    required this.hari,
    required this.status,
    required this.statusDisplay,
    required this.badge,
    required this.masuk,
    required this.pulang,
    required this.isClickable,
    this.shift,
    this.presensiMasuk,
    this.presensiPulang,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      tanggal: json['tanggal'] ?? '',
      hari: json['hari'] ?? '',
      status: json['status'] ?? '',
      statusDisplay: json['status_display'] ?? '',
      badge:
          (json['badge'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      masuk: json['masuk'] ?? '-',
      pulang: json['pulang'] ?? '-',
      isClickable: json['is_clickable'] ?? false,
      shift: json['shift'] != null ? ShiftInfo.fromJson(json['shift']) : null,
      presensiMasuk: json['presensi_masuk'] != null
          ? PresensiDetail.fromJson(json['presensi_masuk'])
          : null,
      presensiPulang: json['presensi_pulang'] != null
          ? PresensiDetail.fromJson(json['presensi_pulang'])
          : null,
    );
  }
}

class ShiftInfo {
  final String kode;
  final String? waktuMulai;
  final String? waktuSelesai;

  ShiftInfo({required this.kode, this.waktuMulai, this.waktuSelesai});

  factory ShiftInfo.fromJson(Map<String, dynamic> json) {
    return ShiftInfo(
      kode: json['kode'] ?? '',
      waktuMulai: json['waktu_mulai'],
      waktuSelesai: json['waktu_selesai'],
    );
  }
}

class PresensiDetail {
  final String? waktu;
  final String? foto;
  final double? latitude;
  final double? longitude;
  final String? keterangan;

  PresensiDetail({
    this.waktu,
    this.foto,
    this.latitude,
    this.longitude,
    this.keterangan,
  });

  factory PresensiDetail.fromJson(Map<String, dynamic> json) {
    return PresensiDetail(
      waktu: json['waktu'],
      foto: json['foto'],
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      keterangan: json['keterangan'],
    );
  }
}
