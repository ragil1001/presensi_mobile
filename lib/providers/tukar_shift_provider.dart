import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/error/app_exception.dart';
import '../core/network/api_client.dart';
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
  int _lastPage = 1;
  final int _perPage = 20;
  bool _hasMore = false;
  bool _isLoadingMore = false;

  // Data
  List<TukarShiftRequest> _requests = [];
  List<JadwalShift> _availableShifts = [];
  List<KaryawanWithShift> _karyawanList = [];

  final ApiClient _apiClient = ApiClient();

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

  /// Load tukar shift requests (both as pengaju and target)
  Future<void> loadTukarShiftRequests({
    String? status,
    String? jenis,
    String? startDate,
    String? endDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _currentPage = 1;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(
        '/mobile/tukar-shift',
        queryParameters: {
          'status': status ?? 'semua',
          if (jenis != null) 'jenis': jenis,
          'page': 1,
          'per_page': _perPage,
        },
      );

      final data = response.data;
      final List<dynamic> items = data['data'] ?? [];

      _requests =
          items.map((json) => TukarShiftRequest.fromJson(json)).toList();
      _currentPage = data['current_page'] ?? 1;
      _lastPage = data['last_page'] ?? 1;
      _hasMore = _currentPage < _lastPage;
    } on DioException catch (e) {
      final appEx = e.error is AppException
          ? e.error as AppException
          : AppException.fromDioException(e);
      _errorMessage = appEx.userMessage;
    } catch (e) {
      _errorMessage = AppException.fromException(e).userMessage;
      debugPrint('Error loading tukar shift requests: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load next page of requests
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
      final response = await _apiClient.dio.get(
        '/mobile/tukar-shift',
        queryParameters: {
          'status': status ?? 'semua',
          if (jenis != null) 'jenis': jenis,
          'page': _currentPage + 1,
          'per_page': _perPage,
        },
      );

      final data = response.data;
      final List<dynamic> items = data['data'] ?? [];

      _requests.addAll(
        items.map((json) => TukarShiftRequest.fromJson(json)).toList(),
      );
      _currentPage = data['current_page'] ?? _currentPage;
      _lastPage = data['last_page'] ?? _lastPage;
      _hasMore = _currentPage < _lastPage;
    } on DioException catch (e) {
      final appEx = e.error is AppException
          ? e.error as AppException
          : AppException.fromDioException(e);
      debugPrint('Error loading more tukar shift: ${appEx.userMessage}');
    } catch (e) {
      debugPrint('Error loading more tukar shift: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Get detail of a single tukar shift request
  Future<TukarShiftRequest?> getDetail(int id) async {
    try {
      final response = await _apiClient.dio.get('/mobile/tukar-shift/$id');
      final data = response.data['data'];
      if (data != null) {
        return TukarShiftRequest.fromJson(data);
      }
      return null;
    } on DioException catch (e) {
      final appEx = e.error is AppException
          ? e.error as AppException
          : AppException.fromDioException(e);
      _errorMessage = appEx.userMessage;
      debugPrint('Error loading tukar shift detail: ${appEx.userMessage}');
      return null;
    } catch (e) {
      _errorMessage = AppException.fromException(e).userMessage;
      debugPrint('Error loading tukar shift detail: $e');
      return null;
    }
  }

  /// Load current user's available shifts for selection
  Future<void> loadAvailableShifts({
    String? startDate,
    String? endDate,
  }) async {
    _isLoadingShifts = true;
    _errorMessageShifts = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(
        '/mobile/tukar-shift/jadwal-saya',
        queryParameters: {
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
        },
      );

      final List<dynamic> items = response.data['data'] ?? [];
      _availableShifts =
          items.map((json) => JadwalShift.fromJson(json)).toList();
    } on DioException catch (e) {
      final appEx = e.error is AppException
          ? e.error as AppException
          : AppException.fromDioException(e);
      _errorMessageShifts = appEx.userMessage;
    } catch (e) {
      _errorMessageShifts = AppException.fromException(e).userMessage;
      debugPrint('Error loading available shifts: $e');
    } finally {
      _isLoadingShifts = false;
      notifyListeners();
    }
  }

  /// Load other employees with their shifts on a specific date
  Future<void> loadKaryawanWithShift({
    required String tanggal,
    String? search,
  }) async {
    _isLoadingKaryawan = true;
    _errorMessageKaryawan = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(
        '/mobile/tukar-shift/karyawan-shift',
        queryParameters: {
          'tanggal': tanggal,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      final List<dynamic> items = response.data['data'] ?? [];
      _karyawanList =
          items.map((json) => KaryawanWithShift.fromJson(json)).toList();
    } on DioException catch (e) {
      final appEx = e.error is AppException
          ? e.error as AppException
          : AppException.fromDioException(e);
      _errorMessageKaryawan = appEx.userMessage;
    } catch (e) {
      _errorMessageKaryawan = AppException.fromException(e).userMessage;
      debugPrint('Error loading karyawan with shift: $e');
    } finally {
      _isLoadingKaryawan = false;
      notifyListeners();
    }
  }

  /// Submit a new tukar shift request
  Future<bool> submitTukarShift({
    required int jadwalPemintaId,
    required int jadwalTargetId,
    String? catatan,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.dio.post(
        '/mobile/tukar-shift',
        data: {
          'jadwal_peminta_id': jadwalPemintaId,
          'jadwal_target_id': jadwalTargetId,
          if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
        },
      );

      return true;
    } on DioException catch (e) {
      final appEx = e.error is AppException
          ? e.error as AppException
          : AppException.fromDioException(e);
      _errorMessage = appEx.userMessage;
      return false;
    } catch (e) {
      _errorMessage = AppException.fromException(e).userMessage;
      debugPrint('Error submitting tukar shift: $e');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Process a tukar shift request (terima/tolak)
  Future<bool> prosesTukarShift({
    required int id,
    required String action,
    String? alasanPenolakan,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.dio.post(
        '/mobile/tukar-shift/$id/$action',
        data: {
          if (alasanPenolakan != null && alasanPenolakan.isNotEmpty)
            'catatan': alasanPenolakan,
        },
      );

      return true;
    } on DioException catch (e) {
      final appEx = e.error is AppException
          ? e.error as AppException
          : AppException.fromDioException(e);
      _errorMessage = appEx.userMessage;
      return false;
    } catch (e) {
      _errorMessage = AppException.fromException(e).userMessage;
      debugPrint('Error processing tukar shift: $e');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Cancel own tukar shift request (only when approved/diterima)
  Future<bool> cancelTukarShift(int id) async {
    _errorMessage = null;

    try {
      await _apiClient.dio.post('/mobile/tukar-shift/$id/batalkan');
      return true;
    } on DioException catch (e) {
      final appEx = e.error is AppException
          ? e.error as AppException
          : AppException.fromDioException(e);
      _errorMessage = appEx.userMessage;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = AppException.fromException(e).userMessage;
      notifyListeners();
      return false;
    }
  }

  /// Delete own tukar shift request (only when pending/diajukan)
  Future<bool> hapusTukarShift(int id) async {
    _errorMessage = null;

    try {
      await _apiClient.dio.delete('/mobile/tukar-shift/$id');
      _requests.removeWhere((r) => r.id == id);
      notifyListeners();
      return true;
    } on DioException catch (e) {
      final appEx = e.error is AppException
          ? e.error as AppException
          : AppException.fromDioException(e);
      _errorMessage = appEx.userMessage;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = AppException.fromException(e).userMessage;
      notifyListeners();
      return false;
    }
  }

  /// Refresh requests with same filters
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
    _requests = [];
    _availableShifts = [];
    _karyawanList = [];
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
    _availableShifts = [];
    notifyListeners();
  }

  void clearKaryawanList() {
    _karyawanList = [];
    notifyListeners();
  }
}
