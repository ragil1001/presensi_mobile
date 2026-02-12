import 'dart:io';
import 'package:flutter/foundation.dart';
import '../data/models/pengajuan_izin_model.dart';

enum IzinState { initial, loading, loaded, error }

class IzinProvider with ChangeNotifier {
  IzinState _state = IzinState.loaded;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _errorType;

  // Pagination
  int _currentPage = 1;
  final int _perPage = 15;
  bool _hasMore = false;
  bool _isLoadingMore = false;

  // Dummy data
  final List<PengajuanIzin> _izinList = [
    PengajuanIzin(
      id: 1,
      kategoriIzin: 'sakit',
      deskripsiIzin: 'Sakit',
      tanggalMulai: DateTime(2026, 2, 5),
      tanggalSelesai: DateTime(2026, 2, 6),
      durasiHari: 2,
      keterangan: 'Demam tinggi',
      status: 'disetujui',
      statusText: 'Disetujui',
      catatanAdmin: 'Semoga lekas sembuh',
      diprosesPada: DateTime(2026, 2, 5, 10, 30),
      diprosesOleh: 'Admin',
      createdAt: DateTime(2026, 2, 4, 8, 0),
    ),
    PengajuanIzin(
      id: 2,
      kategoriIzin: 'izin',
      deskripsiIzin: 'Izin',
      tanggalMulai: DateTime(2026, 2, 10),
      tanggalSelesai: DateTime(2026, 2, 10),
      durasiHari: 1,
      keterangan: 'Urusan keluarga',
      status: 'pending',
      statusText: 'Pending',
      createdAt: DateTime(2026, 2, 9, 14, 0),
    ),
    PengajuanIzin(
      id: 3,
      kategoriIzin: 'cuti_tahunan',
      deskripsiIzin: 'Cuti Tahunan',
      tanggalMulai: DateTime(2026, 1, 20),
      tanggalSelesai: DateTime(2026, 1, 22),
      durasiHari: 3,
      keterangan: 'Liburan keluarga',
      status: 'ditolak',
      statusText: 'Ditolak',
      catatanAdmin: 'Jadwal bentrok dengan deadline project',
      diprosesPada: DateTime(2026, 1, 19, 16, 0),
      diprosesOleh: 'Admin',
      createdAt: DateTime(2026, 1, 18, 9, 0),
    ),
    PengajuanIzin(
      id: 4,
      kategoriIzin: 'cuti_khusus',
      subKategoriIzin: 'menikah',
      deskripsiIzin: 'Cuti Khusus - Menikah',
      durasiOtomatis: 3,
      tanggalMulai: DateTime(2026, 3, 1),
      tanggalSelesai: DateTime(2026, 3, 3),
      durasiHari: 3,
      keterangan: 'Pernikahan',
      status: 'dibatalkan',
      statusText: 'Dibatalkan',
      createdAt: DateTime(2026, 2, 1, 10, 0),
    ),
  ];

  final List<KategoriIzin> _kategoriList = [
    KategoriIzin(
      value: 'sakit',
      label: 'Sakit',
      kode: 'S',
      hasSubKategori: false,
      butuhDokumen: true,
      deskripsi: 'Izin sakit dengan surat dokter',
    ),
    KategoriIzin(
      value: 'izin',
      label: 'Izin',
      kode: 'I',
      hasSubKategori: false,
      butuhDokumen: false,
      deskripsi: 'Izin tidak masuk kerja',
    ),
    KategoriIzin(
      value: 'cuti_tahunan',
      label: 'Cuti Tahunan',
      kode: 'CT',
      hasSubKategori: false,
      butuhDokumen: false,
      maxHari: 12,
      sisaCuti: 10,
      deskripsi: 'Cuti tahunan karyawan',
    ),
    KategoriIzin(
      value: 'cuti_khusus',
      label: 'Cuti Khusus',
      kode: 'CK',
      hasSubKategori: true,
      butuhDokumen: true,
      deskripsi: 'Cuti khusus sesuai ketentuan',
    ),
  ];

  final List<SubKategoriCutiKhusus> _subKategoriList = [
    SubKategoriCutiKhusus(
      value: 'menikah',
      label: 'Menikah',
      durasiHari: 3,
      deskripsi: 'Karyawan menikah',
    ),
    SubKategoriCutiKhusus(
      value: 'anak_menikah',
      label: 'Anak Menikah',
      durasiHari: 2,
      deskripsi: 'Anak karyawan menikah',
    ),
    SubKategoriCutiKhusus(
      value: 'khitanan_anak',
      label: 'Khitanan Anak',
      durasiHari: 2,
      deskripsi: 'Khitanan anak karyawan',
    ),
    SubKategoriCutiKhusus(
      value: 'keluarga_meninggal',
      label: 'Keluarga Meninggal',
      durasiHari: 2,
      deskripsi: 'Anggota keluarga meninggal dunia',
    ),
  ];

  IzinState get state => _state;
  List<PengajuanIzin> get izinList => _izinList;
  List<KategoriIzin> get kategoriList => _kategoriList;
  List<SubKategoriCutiKhusus> get subKategoriList => _subKategoriList;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  String? get errorType => _errorType;

  // Filtered lists by status
  List<PengajuanIzin> get pengajuanList =>
      _izinList.where((i) => i.status == 'pending').toList();
  List<PengajuanIzin> get disetujuiList =>
      _izinList.where((i) => i.status == 'disetujui').toList();
  List<PengajuanIzin> get ditolakList =>
      _izinList.where((i) => i.status == 'ditolak').toList();
  List<PengajuanIzin> get dibatalkanList =>
      _izinList.where((i) => i.status == 'dibatalkan').toList();

  // TODO: Implement with real backend
  Future<void> loadIzinList() async {
    _currentPage = 1;
    _hasMore = false; // Set true when backend returns more pages
    _state = IzinState.loaded;
  }

  Future<void> loadPengajuan() async {
    _currentPage = 1;
    _hasMore = false;
    _state = IzinState.loaded;
  }

  /// Load next page of data. Call from ScrollController listener.
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      // TODO: Replace with API call:
      // final response = await api.getIzinList(page: _currentPage + 1, perPage: _perPage);
      // _izinList.addAll(response.data);
      // _hasMore = response.hasMore;
      // _currentPage++;
      await Future.delayed(const Duration(milliseconds: 500));
      _hasMore = false; // No more dummy data
    } catch (e) {
      // Handle error silently for load-more
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadKategoriIzin() async {
    // Data already loaded at initialization
  }

  Future<void> loadSubKategoriCutiKhusus() async {
    // Data already loaded at initialization
  }

  Future<PengajuanIzin?> getIzinDetail(int id) async {
    try {
      return _izinList.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<PengajuanIzin?> getDetail(int id) async => getIzinDetail(id);

  Future<bool> submitIzin(Map<String, dynamic> data) async => true;

  Future<bool> ajukanIzin({
    required String kategoriIzin,
    String? subKategoriIzin,
    required DateTime tanggalMulai,
    DateTime? tanggalSelesai,
    String? keterangan,
    File? fileDokumen,
  }) async => true;

  Future<Map<String, dynamic>?> hitungTanggalSelesai({
    required DateTime tanggalMulai,
    required String subKategoriIzin,
  }) async {
    // Find matching sub-category to compute end date
    try {
      final sub = _subKategoriList.firstWhere(
        (s) => s.value == subKategoriIzin,
      );
      final endDate = tanggalMulai.add(Duration(days: sub.durasiHari - 1));
      return {
        'tanggal_selesai':
            '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
      };
    } catch (_) {
      return null;
    }
  }

  Future<bool> cancelIzin(int id) async => true;
  Future<bool> batalkanPengajuan(int id) async => true;
  Future<bool> hapusPengajuan(int id) async => true;

  void clearError() {
    _errorMessage = null;
    _errorType = null;
    notifyListeners();
  }
}
