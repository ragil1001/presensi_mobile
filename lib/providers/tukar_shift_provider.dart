import 'package:flutter/foundation.dart';
import '../data/models/tukar_shift_model.dart';

class TukarShiftProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _isLoadingShifts = false;
  bool _isLoadingKaryawan = false;
  bool _isSubmitting = false;

  String? _errorMessage;
  String? _errorMessageShifts;
  String? _errorMessageKaryawan;

  // Pagination
  int _currentPage = 1;
  final int _perPage = 15;
  bool _hasMore = false;
  bool _isLoadingMore = false;

  // Dummy data
  final List<TukarShiftRequest> _requests = [
    TukarShiftRequest(
      id: 1,
      status: 'pending',
      jenis: 'saya',
      tanggalRequest: DateTime(2026, 2, 10),
      shiftSaya: ShiftInfo(
        jadwalId: 101,
        tanggal: DateTime(2026, 2, 12),
        hari: 'Kamis',
        shiftCode: 'P1',
        waktuMulai: '08:00',
        waktuSelesai: '17:00',
      ),
      shiftDiminta: ShiftInfo(
        jadwalId: 102,
        tanggal: DateTime(2026, 2, 12),
        hari: 'Kamis',
        shiftCode: 'P2',
        waktuMulai: '14:00',
        waktuSelesai: '22:00',
      ),
      karyawanTujuan: KaryawanTujuan(
        id: 2,
        nama: 'Budi Santoso',
        nik: '00002',
        noTelp: '08123456780',
        divisi: 'IT',
        jabatan: 'Staff',
      ),
      catatan: 'Ada keperluan pagi hari',
    ),
    TukarShiftRequest(
      id: 2,
      status: 'disetujui',
      jenis: 'orang_lain',
      tanggalRequest: DateTime(2026, 2, 5),
      shiftSaya: ShiftInfo(
        jadwalId: 103,
        tanggal: DateTime(2026, 2, 7),
        hari: 'Sabtu',
        shiftCode: 'P2',
        waktuMulai: '14:00',
        waktuSelesai: '22:00',
      ),
      shiftDiminta: ShiftInfo(
        jadwalId: 104,
        tanggal: DateTime(2026, 2, 7),
        hari: 'Sabtu',
        shiftCode: 'P1',
        waktuMulai: '08:00',
        waktuSelesai: '17:00',
      ),
      karyawanTujuan: KaryawanTujuan(
        id: 3,
        nama: 'Siti Rahayu',
        nik: '00003',
        noTelp: '08123456781',
        divisi: 'HR',
        jabatan: 'Staff',
      ),
      tanggalDiproses: DateTime(2026, 2, 6),
    ),
  ];

  final List<JadwalShift> _availableShifts = [
    JadwalShift(
      id: 201,
      tanggal: DateTime(2026, 2, 15),
      hari: 'Minggu',
      shiftCode: 'P1',
      waktuMulai: '08:00',
      waktuSelesai: '17:00',
      isLibur: false,
    ),
    JadwalShift(
      id: 202,
      tanggal: DateTime(2026, 2, 16),
      hari: 'Senin',
      shiftCode: 'P2',
      waktuMulai: '14:00',
      waktuSelesai: '22:00',
      isLibur: false,
    ),
  ];

  final List<KaryawanWithShift> _karyawanList = [
    KaryawanWithShift(
      id: 2,
      nama: 'Budi Santoso',
      nik: '00002',
      noTelp: '08123456780',
      divisi: 'IT',
      jabatan: 'Staff',
      shift: ShiftInfo(
        jadwalId: 301,
        tanggal: DateTime(2026, 2, 15),
        hari: 'Minggu',
        shiftCode: 'P2',
        waktuMulai: '14:00',
        waktuSelesai: '22:00',
      ),
    ),
    KaryawanWithShift(
      id: 3,
      nama: 'Siti Rahayu',
      nik: '00003',
      noTelp: '08123456781',
      divisi: 'HR',
      jabatan: 'Staff',
      shift: ShiftInfo(
        jadwalId: 302,
        tanggal: DateTime(2026, 2, 15),
        hari: 'Minggu',
        shiftCode: 'P1',
        waktuMulai: '08:00',
        waktuSelesai: '17:00',
      ),
    ),
  ];

  List<TukarShiftRequest> get requests => _requests;
  List<JadwalShift> get availableShifts => _availableShifts;
  List<KaryawanWithShift> get karyawanList => _karyawanList;

  bool get isLoading => _isLoading;
  bool get isLoadingShifts => _isLoadingShifts;
  bool get isLoadingKaryawan => _isLoadingKaryawan;
  bool get isSubmitting => _isSubmitting;

  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  String? get errorMessage => _errorMessage;
  String? get errorMessageShifts => _errorMessageShifts;
  String? get errorMessageKaryawan => _errorMessageKaryawan;

  // TODO: Implement with real backend
  Future<void> loadTukarShiftRequests({
    String? status,
    String? jenis,
    String? startDate,
    String? endDate,
  }) async {
    _currentPage = 1;
    _hasMore = false;
    // Data already initialized
  }

  /// Load next page of data. Call from ScrollController listener.
  Future<void> loadMore({
    String? status,
    String? jenis,
    String? startDate,
    String? endDate,
  }) async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      // TODO: Replace with API call:
      // final response = await api.getTukarShiftRequests(
      //   page: _currentPage + 1, perPage: _perPage,
      //   status: status, jenis: jenis, ...
      // );
      // _requests.addAll(response.data);
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

  Future<void> loadAvailableShifts({String? startDate, String? endDate}) async {
    // Data already initialized
  }

  Future<void> loadKaryawanWithShift({
    required String tanggal,
    String? search,
  }) async {
    // Data already initialized
  }

  Future<bool> submitTukarShift({
    required int jadwalPemintaId,
    required int jadwalTargetId,
    String? catatan,
  }) async => true;

  Future<bool> prosesTukarShift({
    required int id,
    required String action,
    String? alasanPenolakan,
  }) async => true;

  Future<bool> cancelTukarShift(int id) async => true;

  Future<void> refreshRequests({
    String? status,
    String? jenis,
    String? startDate,
    String? endDate,
  }) async {
    await loadTukarShiftRequests(
      status: status,
      jenis: jenis,
      startDate: startDate,
      endDate: endDate,
    );
  }

  void clear() {
    _errorMessage = null;
    _errorMessageShifts = null;
    _errorMessageKaryawan = null;
    _isLoading = false;
    _isLoadingShifts = false;
    _isLoadingKaryawan = false;
    _isSubmitting = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _errorMessageShifts = null;
    _errorMessageKaryawan = null;
    notifyListeners();
  }

  void clearAvailableShifts() {
    notifyListeners();
  }

  void clearKaryawanList() {
    notifyListeners();
  }
}
