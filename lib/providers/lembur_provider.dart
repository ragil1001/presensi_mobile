import 'dart:io';
import 'package:flutter/foundation.dart';
import '../data/models/pengajuan_lembur_model.dart';

enum LemburState { initial, loading, loaded, error }

class LemburProvider with ChangeNotifier {
  LemburState _state = LemburState.loaded;
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
  final List<PengajuanLembur> _lemburList = [
    PengajuanLembur(
      id: 1,
      tanggal: DateTime(2026, 2, 8),
      kodeHari: 'K',
      kodeHariText: 'Hari Kerja',
      jamMulai: '18:00',
      jamSelesai: '21:00',
      keteranganKaryawan: 'Deadline project modul A',
      status: 'disetujui',
      statusText: 'Disetujui',
      catatanAdmin: 'Approved',
      diprosesPada: DateTime(2026, 2, 8, 10, 0),
      diprosesOleh: 'Admin',
      createdAt: DateTime(2026, 2, 7, 16, 0),
    ),
    PengajuanLembur(
      id: 2,
      tanggal: DateTime(2026, 2, 15),
      kodeHari: 'L',
      kodeHariText: 'Hari Libur',
      jamMulai: '08:00',
      jamSelesai: '17:00',
      keteranganKaryawan: 'Maintenance server',
      status: 'pending',
      statusText: 'Pending',
      createdAt: DateTime(2026, 2, 14, 9, 0),
    ),
    PengajuanLembur(
      id: 3,
      tanggal: DateTime(2026, 1, 25),
      kodeHari: 'K',
      kodeHariText: 'Hari Kerja',
      jamMulai: '18:00',
      jamSelesai: '20:00',
      keteranganKaryawan: 'Finishing laporan bulanan',
      status: 'ditolak',
      statusText: 'Ditolak',
      catatanAdmin: 'Lembur tidak diperlukan',
      diprosesPada: DateTime(2026, 1, 25, 12, 0),
      diprosesOleh: 'Admin',
      createdAt: DateTime(2026, 1, 24, 15, 0),
    ),
  ];

  LemburState get state => _state;
  List<PengajuanLembur> get lemburList => _lemburList;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  String? get errorType => _errorType;

  // Filtered lists by status
  List<PengajuanLembur> get pengajuanList =>
      _lemburList.where((l) => l.status == 'pending').toList();
  List<PengajuanLembur> get disetujuiList =>
      _lemburList.where((l) => l.status == 'disetujui').toList();
  List<PengajuanLembur> get ditolakList =>
      _lemburList.where((l) => l.status == 'ditolak').toList();
  List<PengajuanLembur> get dibatalkanList =>
      _lemburList.where((l) => l.status == 'dibatalkan').toList();

  // TODO: Implement with real backend
  Future<void> loadLemburList() async {
    _currentPage = 1;
    _hasMore = false;
    _state = LemburState.loaded;
  }

  Future<void> loadPengajuan() async {
    _currentPage = 1;
    _hasMore = false;
    _state = LemburState.loaded;
  }

  /// Load next page of data. Call from ScrollController listener.
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      // TODO: Replace with API call:
      // final response = await api.getLemburList(page: _currentPage + 1, perPage: _perPage);
      // _lemburList.addAll(response.data);
      // _hasMore = response.hasMore;
      // _currentPage++;
      await Future.delayed(const Duration(milliseconds: 500));
      _hasMore = false;
    } catch (e) {
      // Handle error silently for load-more
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<PengajuanLembur?> getLemburDetail(int id) async {
    try {
      return _lemburList.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<PengajuanLembur?> getDetail(int id) async => getLemburDetail(id);

  Future<bool> submitLembur(Map<String, dynamic> data) async => true;

  Future<bool> ajukanLembur({
    required DateTime tanggal,
    required File fileSkl,
    required String jamMulai,
    required String jamSelesai,
    String? keterangan,
  }) async => true;

  Future<bool> cancelLembur(int id) async => true;
  Future<bool> batalkanPengajuan(int id) async => true;
  Future<bool> hapusPengajuan(int id) async => true;

  void clearError() {
    _errorMessage = null;
    _errorType = null;
    notifyListeners();
  }
}
