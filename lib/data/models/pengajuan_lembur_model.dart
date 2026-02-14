// lib/data/models/pengajuan_lembur_model.dart
import 'package:flutter/foundation.dart';

class PengajuanLembur {
  final int id;
  final DateTime tanggal;
  final String kodeHari;
  final String kodeHariText;
  final String? jamMulai;
  final String? jamSelesai;
  final String? fileSklUrl; // MinIO storage path (not a full URL)
  final String? keteranganKaryawan;
  final String status;
  final String statusText;
  final String? catatanAdmin;
  final DateTime? diprosesPada;
  final String? diprosesOleh;
  final DateTime createdAt;

  PengajuanLembur({
    required this.id,
    required this.tanggal,
    required this.kodeHari,
    required this.kodeHariText,
    this.jamMulai,
    this.jamSelesai,
    this.fileSklUrl,
    this.keteranganKaryawan,
    required this.status,
    required this.statusText,
    this.catatanAdmin,
    this.diprosesPada,
    this.diprosesOleh,
    required this.createdAt,
  });

  factory PengajuanLembur.fromJson(Map<String, dynamic> json) {
    try {
      String? getStringOrNull(dynamic value) {
        if (value == null) return null;
        if (value is String) return value.isEmpty ? null : value;
        return value.toString();
      }

      return PengajuanLembur(
        id: json['id'] as int,
        tanggal: DateTime.parse(json['tanggal'] as String),
        kodeHari: getStringOrNull(json['kode_hari']) ?? 'K',
        kodeHariText:
            getStringOrNull(json['kode_hari_text']) ?? 'Hari Kerja',
        jamMulai: getStringOrNull(json['jam_mulai']),
        jamSelesai: getStringOrNull(json['jam_selesai']),
        fileSklUrl: getStringOrNull(json['file_skl_url']),
        keteranganKaryawan: getStringOrNull(json['keterangan_karyawan']),
        status: getStringOrNull(json['status']) ?? 'pending',
        statusText: getStringOrNull(json['status_text']) ?? 'Pending',
        catatanAdmin: getStringOrNull(json['catatan_admin']),
        diprosesPada: json['diproses_pada'] != null
            ? DateTime.parse(json['diproses_pada'] as String)
            : null,
        diprosesOleh: getStringOrNull(json['diproses_oleh']),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
    } catch (e) {
      debugPrint('Error parsing PengajuanLembur: $e');
      debugPrint('JSON data: $json');
      rethrow;
    }
  }

  bool get isPending => status == 'pending';
  bool get isDisetujui => status == 'disetujui';
  bool get isDitolak => status == 'ditolak';
  bool get isDibatalkan => status == 'dibatalkan';
  bool get canEdit => isPending;
  bool get canDelete => isPending;
  bool get canCancel => isDisetujui;

  bool get isHariLibur => kodeHari == 'L';
  bool get isHariKerja => kodeHari == 'K';
  bool get hasFile => fileSklUrl != null && fileSklUrl!.isNotEmpty;
}
