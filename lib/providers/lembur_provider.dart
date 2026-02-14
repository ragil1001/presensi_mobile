import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/error/app_exception.dart';
import '../core/network/api_client.dart';
import '../data/models/pengajuan_lembur_model.dart';

enum LemburState { initial, loading, loaded, error }

class LemburProvider with ChangeNotifier {
  LemburState _state = LemburState.initial;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _errorType;

  // Pagination
  int _currentPage = 1;
  int _lastPage = 1;
  final int _perPage = 20;
  bool _hasMore = false;
  bool _isLoadingMore = false;

  // Data
  List<PengajuanLembur> _lemburList = [];

  final ApiClient _apiClient = ApiClient();

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

  Future<void> loadLemburList({String status = 'semua'}) async {
    _isLoading = true;
    _state = LemburState.loading;
    _errorMessage = null;
    _errorType = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(
        '/mobile/lembur',
        queryParameters: {
          'status': status,
          'page': 1,
          'per_page': _perPage,
        },
      );

      final data = response.data;
      final List<dynamic> items = data['data'] ?? [];

      _lemburList =
          items.map((json) => PengajuanLembur.fromJson(json)).toList();
      _currentPage = data['current_page'] ?? 1;
      _lastPage = data['last_page'] ?? 1;
      _hasMore = _currentPage < _lastPage;
      _state = LemburState.loaded;
    } on DioException catch (e) {
      final appEx = e.error is AppException ? e.error as AppException : AppException.fromDioException(e);
      _state = LemburState.error;
      _errorMessage = appEx.userMessage;
      _errorType = 'network';
    } catch (e) {
      _state = LemburState.error;
      _errorMessage = AppException.fromException(e).userMessage;
      _errorType = 'network';
      debugPrint('Error loading lembur list: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPengajuan() async {
    await loadLemburList();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(
        '/mobile/lembur',
        queryParameters: {
          'status': 'semua',
          'page': _currentPage + 1,
          'per_page': _perPage,
        },
      );

      final data = response.data;
      final List<dynamic> items = data['data'] ?? [];

      _lemburList.addAll(
        items.map((json) => PengajuanLembur.fromJson(json)).toList(),
      );
      _currentPage = data['current_page'] ?? _currentPage;
      _lastPage = data['last_page'] ?? _lastPage;
      _hasMore = _currentPage < _lastPage;
    } on DioException catch (e) {
      final appEx = e.error is AppException ? e.error as AppException : AppException.fromDioException(e);
      debugPrint('Error loading more lembur: ${appEx.userMessage}');
    } catch (e) {
      debugPrint('Error loading more lembur: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<PengajuanLembur?> getLemburDetail(int id) async {
    try {
      final response = await _apiClient.dio.get('/mobile/lembur/$id');
      final data = response.data['data'];
      if (data != null) {
        return PengajuanLembur.fromJson(data);
      }
      return null;
    } on DioException catch (e) {
      final appEx = e.error is AppException ? e.error as AppException : AppException.fromDioException(e);
      debugPrint('Error loading lembur detail: ${appEx.userMessage}');
      _errorMessage = appEx.userMessage;
      return null;
    } catch (e) {
      debugPrint('Error loading lembur detail: $e');
      _errorMessage = AppException.fromException(e).userMessage;
      return null;
    }
  }

  Future<PengajuanLembur?> getDetail(int id) async => getLemburDetail(id);

  /// Submit new lembur request
  Future<bool> ajukanLembur({
    required DateTime tanggal,
    required String jamMulai,
    required String jamSelesai,
    required String jenisLembur,
    required File fileSkl,
    String? keterangan,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final formData = FormData.fromMap({
        'tanggal_lembur':
            '${tanggal.year}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}',
        'jam_mulai': jamMulai,
        'jam_selesai': jamSelesai,
        'jenis_lembur': jenisLembur,
        if (keterangan != null && keterangan.isNotEmpty)
          'keterangan': keterangan,
        'file_skl': await MultipartFile.fromFile(
          fileSkl.path,
          filename: fileSkl.path.split('/').last,
        ),
      });

      await _apiClient.dio.post(
        '/mobile/lembur',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      await loadLemburList();
      return true;
    } on DioException catch (e) {
      final appEx = e.error is AppException ? e.error as AppException : AppException.fromDioException(e);
      _errorMessage = appEx.userMessage;
      debugPrint('Error submitting lembur: $e');
      return false;
    } catch (e) {
      _errorMessage = AppException.fromException(e).userMessage;
      debugPrint('Error submitting lembur: $e');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Update existing lembur (only when status is PENDING)
  Future<bool> updateLembur({
    required int id,
    required DateTime tanggal,
    required String jamMulai,
    required String jamSelesai,
    required String jenisLembur,
    File? fileSkl,
    String? keterangan,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final map = <String, dynamic>{
        'tanggal_lembur':
            '${tanggal.year}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}',
        'jam_mulai': jamMulai,
        'jam_selesai': jamSelesai,
        'jenis_lembur': jenisLembur,
        'keterangan': keterangan ?? '',
      };

      if (fileSkl != null) {
        map['file_skl'] = await MultipartFile.fromFile(
          fileSkl.path,
          filename: fileSkl.path.split('/').last,
        );
      }

      final formData = FormData.fromMap(map);

      await _apiClient.dio.post(
        '/mobile/lembur/$id',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      await loadLemburList();
      return true;
    } on DioException catch (e) {
      final appEx = e.error is AppException ? e.error as AppException : AppException.fromDioException(e);
      _errorMessage = appEx.userMessage;
      debugPrint('Error updating lembur: $e');
      return false;
    } catch (e) {
      _errorMessage = AppException.fromException(e).userMessage;
      debugPrint('Error updating lembur: $e');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Delete lembur (only when status is PENDING)
  Future<bool> hapusPengajuan(int id) async {
    _errorMessage = null;

    try {
      await _apiClient.dio.delete('/mobile/lembur/$id');
      _lemburList.removeWhere((l) => l.id == id);
      notifyListeners();
      return true;
    } on DioException catch (e) {
      final appEx = e.error is AppException ? e.error as AppException : AppException.fromDioException(e);
      _errorMessage = appEx.userMessage;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = AppException.fromException(e).userMessage;
      notifyListeners();
      return false;
    }
  }

  /// Cancel lembur (only when status is DISETUJUI -> sets to DIBATALKAN)
  Future<bool> batalkanPengajuan(int id) async {
    _errorMessage = null;

    try {
      await _apiClient.dio.post('/mobile/lembur/$id/batalkan');
      await loadLemburList();
      return true;
    } on DioException catch (e) {
      final appEx = e.error is AppException ? e.error as AppException : AppException.fromDioException(e);
      _errorMessage = appEx.userMessage;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = AppException.fromException(e).userMessage;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    _errorType = null;
    notifyListeners();
  }
}
