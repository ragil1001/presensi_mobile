// lib/data/models/pengajuan_izin_model.dart
import 'dart:math';
import 'package:flutter/foundation.dart';

class PengajuanIzin {
  final int id;
  final int? kategoriIzinId;
  final String kategoriIzin;
  final String? subKategoriIzin;
  final String deskripsiIzin;
  final int? durasiOtomatis;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final int durasiHari;
  final String? keterangan;
  final String? fileUrl; // minio storage path (not a full URL)
  final String status;
  final String statusText;
  final String? catatanAdmin;
  final DateTime? diprosesPada;
  final String? diprosesOleh;
  final DateTime createdAt;

  PengajuanIzin({
    required this.id,
    this.kategoriIzinId,
    required this.kategoriIzin,
    this.subKategoriIzin,
    required this.deskripsiIzin,
    this.durasiOtomatis,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.durasiHari,
    this.keterangan,
    this.fileUrl,
    required this.status,
    required this.statusText,
    this.catatanAdmin,
    this.diprosesPada,
    this.diprosesOleh,
    required this.createdAt,
  });

  factory PengajuanIzin.fromJson(Map<String, dynamic> json) {
    String? getStringOrNull(dynamic value) {
      if (value == null) return null;
      if (value is String) return value.isEmpty ? null : value;
      return value.toString();
    }

    return PengajuanIzin(
      id: json['id'] as int,
      kategoriIzinId: json['kategori_izin_id'] as int?,
      kategoriIzin: getStringOrNull(json['kategori_izin']) ?? 'izin',
      subKategoriIzin: getStringOrNull(json['sub_kategori_izin']),
      deskripsiIzin: getStringOrNull(json['deskripsi_izin']) ?? 'Izin',
      durasiOtomatis: json['durasi_otomatis'] as int?,
      tanggalMulai: DateTime.parse(json['tanggal_mulai'] as String),
      tanggalSelesai: DateTime.parse(json['tanggal_selesai'] as String),
      durasiHari: json['durasi_hari'] as int? ?? 0,
      keterangan: getStringOrNull(json['keterangan']),
      fileUrl: getStringOrNull(json['file_url']),
      status: getStringOrNull(json['status']) ?? 'pending',
      statusText: getStringOrNull(json['status_text']) ?? 'Pending',
      catatanAdmin: getStringOrNull(json['catatan_admin']),
      diprosesPada: json['diproses_pada'] != null
          ? DateTime.parse(json['diproses_pada'] as String)
          : null,
      diprosesOleh: getStringOrNull(json['diproses_oleh']),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isPending => status == 'pending';
  bool get isDisetujui => status == 'disetujui';
  bool get isDitolak => status == 'ditolak';
  bool get isDibatalkan => status == 'dibatalkan';
  bool get canEdit => isPending;
  bool get canDelete => isPending;
  bool get canCancel => isDisetujui;

  bool get isSakit => kategoriIzin == 'sakit';
  bool get isIzin => kategoriIzin == 'izin';
  bool get isCutiTahunan => kategoriIzin == 'cuti_tahunan';
  bool get isCutiKhusus => kategoriIzin == 'cuti_khusus';

  bool get hasFile => fileUrl != null && fileUrl!.isNotEmpty;

  String get kategoriLabel {
    switch (kategoriIzin) {
      case 'sakit':
        return 'Sakit';
      case 'izin':
        return 'Izin';
      case 'cuti_tahunan':
        return 'Cuti Tahunan';
      case 'cuti_khusus':
        return 'Cuti Khusus';
      default:
        final parts = deskripsiIzin.split(' - ');
        return parts.first;
    }
  }
}

class KategoriIzin {
  final int? id;
  final String value;
  final String label;
  final String kode;
  final bool hasSubKategori;
  final bool butuhDokumen;
  final int? jumlahHari;
  final int? maxHari;
  final int? sisaCuti;
  final String deskripsi;
  final List<SubKategoriCutiKhusus> subKategoriItems;

  KategoriIzin({
    this.id,
    required this.value,
    required this.label,
    required this.kode,
    required this.hasSubKategori,
    required this.butuhDokumen,
    this.jumlahHari,
    this.maxHari,
    this.sisaCuti,
    required this.deskripsi,
    this.subKategoriItems = const [],
  });

  factory KategoriIzin.fromJson(Map<String, dynamic> json) {
    try {
      return KategoriIzin(
        id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
        value: json['value']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
        kode: json['kode']?.toString() ?? '',
        hasSubKategori: json['has_sub_kategori'] == true,
        butuhDokumen: json['butuh_dokumen'] == true,
        maxHari: json['max_hari'] != null
            ? int.tryParse(json['max_hari'].toString())
            : null,
        sisaCuti: json['sisa_cuti'] != null
            ? int.tryParse(json['sisa_cuti'].toString())
            : null,
        deskripsi: json['deskripsi']?.toString() ?? '',
      );
    } catch (e) {
      debugPrint('Error parsing KategoriIzin: $e');
      debugPrint('   JSON: $json');
      rethrow;
    }
  }

  /// Parse from the backend /mobile/izin-kategori grouped response
  factory KategoriIzin.fromApiJson(Map<String, dynamic> json) {
    final kategoriKey = json['kategori_key'] as String? ?? '';
    final kategoriName = json['kategori'] as String? ?? '';
    final subKategoriList = (json['sub_kategori'] as List<dynamic>?) ?? [];

    String kode;
    switch (kategoriKey) {
      case 'sakit':
        kode = 'S';
        break;
      case 'izin':
        kode = 'I';
        break;
      case 'cuti_tahunan':
        kode = 'CT';
        break;
      case 'cuti_khusus':
        kode = 'CK';
        break;
      default:
        kode = kategoriKey
            .substring(0, min(2, kategoriKey.length))
            .toUpperCase();
    }

    return KategoriIzin(
      id: json['id'] as int?,
      value: kategoriKey,
      label: kategoriName,
      kode: kode,
      hasSubKategori: subKategoriList.isNotEmpty,
      butuhDokumen: true,
      jumlahHari: json['jumlah_hari'] as int?,
      deskripsi: kategoriName,
      subKategoriItems: subKategoriList
          .map(
            (s) =>
                SubKategoriCutiKhusus.fromApiJson(s as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class SubKategoriCutiKhusus {
  final int? id;
  final String value;
  final String label;
  final int durasiHari;
  final String deskripsi;

  SubKategoriCutiKhusus({
    this.id,
    required this.value,
    required this.label,
    required this.durasiHari,
    required this.deskripsi,
  });

  factory SubKategoriCutiKhusus.fromJson(Map<String, dynamic> json) {
    return SubKategoriCutiKhusus(
      id: json['id'] as int?,
      value: json['value'] ?? '',
      label: json['label'] ?? '',
      durasiHari: json['durasi_hari'] ?? 0,
      deskripsi: json['deskripsi'] ?? '',
    );
  }

  /// Parse from the backend /mobile/izin-kategori sub_kategori item
  factory SubKategoriCutiKhusus.fromApiJson(Map<String, dynamic> json) {
    final id = json['id'] as int;
    final label = json['label'] as String? ?? '';
    return SubKategoriCutiKhusus(
      id: id,
      value: id.toString(),
      label: label,
      durasiHari: json['jumlah_hari'] as int? ?? 0,
      deskripsi: label,
    );
  }
}
