class PatrolConfig {
  final int id;
  final String namaKonfigurasi;
  final String modeUrutan;
  final int? durasiPatroliMenit;
  final int? intervalScanDetik;
  final String? projectNama;
  final int checkpointsCount;

  PatrolConfig({
    required this.id,
    required this.namaKonfigurasi,
    required this.modeUrutan,
    this.durasiPatroliMenit,
    this.intervalScanDetik,
    this.projectNama,
    this.checkpointsCount = 0,
  });

  factory PatrolConfig.fromJson(Map<String, dynamic> json) {
    return PatrolConfig(
      id: json['id'] ?? 0,
      namaKonfigurasi: json['nama_konfigurasi'] ?? '',
      modeUrutan: json['mode_urutan'] ?? 'FREE',
      durasiPatroliMenit: json['durasi_patroli_menit'],
      intervalScanDetik: json['interval_scan_detik'],
      projectNama: json['project']?['nama_project'],
      checkpointsCount:
          json['checkpoints_count'] ?? json['active_checkpoints_count'] ?? 0,
    );
  }

  bool get isStrict => modeUrutan == 'STRICT';
  bool get isCustom => modeUrutan == 'CUSTOM';
  bool get isFree => modeUrutan == 'FREE';
  bool get isOrdered => isStrict || isCustom;

  String get modeLabel {
    switch (modeUrutan) {
      case 'STRICT':
        return 'Strict (Urut, 1x per sesi)';
      case 'CUSTOM':
        return 'Custom (Urut, berkali-kali)';
      case 'FREE':
        return 'Bebas';
      default:
        return modeUrutan;
    }
  }
}

class PatrolSession {
  final int id;
  final int configId;
  final String? configNama;
  final String? projectNama;
  final String? modeUrutan;
  final String tanggal;
  final String? waktuMulai;
  final String? waktuSelesai;
  final String status;
  final int totalCheckpointScan;
  final String? catatan;
  final int? scansCount;
  final PatrolConfig? config;

  PatrolSession({
    required this.id,
    required this.configId,
    this.configNama,
    this.projectNama,
    this.modeUrutan,
    required this.tanggal,
    this.waktuMulai,
    this.waktuSelesai,
    required this.status,
    this.totalCheckpointScan = 0,
    this.catatan,
    this.scansCount,
    this.config,
  });

  factory PatrolSession.fromJson(Map<String, dynamic> json) {
    final config = json['config'] != null
        ? PatrolConfig.fromJson(json['config'])
        : null;
    return PatrolSession(
      id: json['id'] ?? 0,
      configId: json['config_id'] ?? 0,
      configNama: config?.namaKonfigurasi ?? json['config_nama'],
      projectNama: config?.projectNama,
      modeUrutan: config?.modeUrutan,
      tanggal: json['tanggal'] ?? '',
      waktuMulai: json['waktu_mulai'],
      waktuSelesai: json['waktu_selesai'],
      status: json['status'] ?? '',
      totalCheckpointScan: json['total_checkpoint_scan'] ?? 0,
      catatan: json['catatan'],
      scansCount: json['scans_count'],
      config: config,
    );
  }

  bool get isBerlangsung => status == 'BERLANGSUNG';
  bool get isSelesai => status == 'SELESAI';
  bool get isDibatalkan => status == 'DIBATALKAN';
}

class CheckpointProgress {
  final int id;
  final String nama;
  final String? deskripsi;
  final String? lantai;
  final int orderIndex;
  final bool isWajib;
  final bool isAktif;
  final double? latitude;
  final double? longitude;
  final double? radiusMeter;
  final bool sudahScan;

  CheckpointProgress({
    required this.id,
    required this.nama,
    this.deskripsi,
    this.lantai,
    this.orderIndex = 0,
    this.isWajib = false,
    this.isAktif = true,
    this.latitude,
    this.longitude,
    this.radiusMeter,
    this.sudahScan = false,
  });

  factory CheckpointProgress.fromJson(Map<String, dynamic> json) {
    return CheckpointProgress(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
      deskripsi: json['deskripsi'],
      lantai: json['lantai'],
      orderIndex: json['order_index'] ?? 0,
      isWajib: json['is_wajib'] ?? false,
      isAktif: json['is_aktif'] ?? true,
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      radiusMeter: json['radius_meter'] != null
          ? double.tryParse(json['radius_meter'].toString())
          : null,
      sudahScan: json['sudah_scan'] ?? false,
    );
  }
}

class PatrolScan {
  final int id;
  final int sessionId;
  final int? checkpointId;
  final String? checkpointNama;
  final String? checkpointLantai;
  final String tipe;
  final String? waktuScan;
  final double? latitude;
  final double? longitude;
  final double? jarakDariCheckpoint;
  final bool isGpsAnomali;
  final String? deskripsi;
  final List<PatrolFoto> fotos;

  PatrolScan({
    required this.id,
    required this.sessionId,
    this.checkpointId,
    this.checkpointNama,
    this.checkpointLantai,
    required this.tipe,
    this.waktuScan,
    this.latitude,
    this.longitude,
    this.jarakDariCheckpoint,
    this.isGpsAnomali = false,
    this.deskripsi,
    this.fotos = const [],
  });

  factory PatrolScan.fromJson(Map<String, dynamic> json) {
    return PatrolScan(
      id: json['id'] ?? 0,
      sessionId: json['session_id'] ?? 0,
      checkpointId: json['checkpoint_id'],
      checkpointNama: json['checkpoint']?['nama'],
      checkpointLantai: json['checkpoint']?['lantai'],
      tipe: json['tipe'] ?? '',
      waktuScan: json['waktu_scan'],
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      jarakDariCheckpoint: json['jarak_dari_checkpoint'] != null
          ? double.tryParse(json['jarak_dari_checkpoint'].toString())
          : null,
      isGpsAnomali: json['is_gps_anomali'] ?? false,
      deskripsi: json['deskripsi'],
      fotos: (json['fotos'] as List<dynamic>?)
              ?.map((f) => PatrolFoto.fromJson(f))
              .toList() ??
          [],
    );
  }

  bool get isQrScan => tipe == 'QR_SCAN';
  bool get isLaporanInsidental => tipe == 'LAPORAN_INSIDENTAL';
}

class PatrolFoto {
  final int id;
  final String? filePath;
  final String? fileName;

  PatrolFoto({required this.id, this.filePath, this.fileName});

  factory PatrolFoto.fromJson(Map<String, dynamic> json) {
    return PatrolFoto(
      id: json['id'] ?? 0,
      filePath: json['file_path'],
      fileName: json['file_name'],
    );
  }
}
