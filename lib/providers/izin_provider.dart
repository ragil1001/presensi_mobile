import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/error/app_exception.dart';
import '../core/network/api_client.dart';
import '../data/models/pengajuan_izin_model.dart';

enum IzinState { initial, loading, loaded, error }

class IzinProvider with ChangeNotifier {
  IzinState _state = IzinState.initial;
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
  List<PengajuanIzin> _izinList = [];
  List<KategoriIzin> _kategoriList = [];

  final ApiClient _apiClient = ApiClient();

  IzinState get state => _state;
  List<PengajuanIzin> get izinList => _izinList;
  List<KategoriIzin> get kategoriList => _kategoriList;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  String? get errorType => _errorType;

  /// Get sub-kategori list from the selected kategori's nested items
  List<SubKategoriCutiKhusus> get subKategoriList {
    for (final kat in _kategoriList) {
      if (kat.hasSubKategori && kat.subKategoriItems.isNotEmpty) {
        return kat.subKategoriItems;
      }
    }
    return [];
  }

  /// Get sub-kategori for a specific kategori
  List<SubKategoriCutiKhusus> getSubKategoriFor(String kategoriValue) {
    for (final kat in _kategoriList) {
      if (kat.value == kategoriValue) {
        return kat.subKategoriItems;
      }
    }
    return [];
  }

  // Filtered lists by status
  List<PengajuanIzin> get pengajuanList =>
      _izinList.where((i) => i.status == 'pending').toList();
  List<PengajuanIzin> get disetujuiList =>
      _izinList.where((i) => i.status == 'disetujui').toList();
  List<PengajuanIzin> get ditolakList =>
      _izinList.where((i) => i.status == 'ditolak').toList();
  List<PengajuanIzin> get dibatalkanList =>
      _izinList.where((i) => i.status == 'dibatalkan').toList();

  Future<void> loadIzinList({String status = 'semua'}) async {
    _isLoading = true;
    _state = IzinState.loading;
    _errorMessage = null;
    _errorType = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(
        '/mobile/izin',
        queryParameters: {
          'status': status,
          'page': 1,
          'per_page': _perPage,
        },
      );

      final data = response.data;
      final List<dynamic> items = data['data'] ?? [];

      _izinList = items.map((json) => PengajuanIzin.fromJson(json)).toList();
      _currentPage = data['current_page'] ?? 1;
      _lastPage = data['last_page'] ?? 1;
      _hasMore = _currentPage < _lastPage;
      _state = IzinState.loaded;
    } on DioException catch (e) {
      final appEx = e.error is AppException ? e.error as AppException : AppException.fromDioException(e);
      _state = IzinState.error;
      _errorMessage = appEx.userMessage;
      _errorType = 'network';
    } catch (e) {
      _state = IzinState.error;
      _errorMessage = AppException.fromException(e).userMessage;
      _errorType = 'network';
      debugPrint('Error loading izin list: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPengajuan() async {
    await loadIzinList();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(
        '/mobile/izin',
        queryParameters: {
          'status': 'semua',
          'page': _currentPage + 1,
          'per_page': _perPage,
        },
      );

      final data = response.data;
      final List<dynamic> items = data['data'] ?? [];

      _izinList.addAll(
        items.map((json) => PengajuanIzin.fromJson(json)).toList(),
      );
      _currentPage = data['current_page'] ?? _currentPage;
      _lastPage = data['last_page'] ?? _lastPage;
      _hasMore = _currentPage < _lastPage;
    } on DioException catch (e) {
      final appEx = e.error is AppException ? e.error as AppException : AppException.fromDioException(e);
      debugPrint('Error loading more izin: ${appEx.userMessage}');
    } catch (e) {
      debugPrint('Error loading more izin: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Load kategori izin from backend API
  Future<void> loadKategoriIzin() async {
    try {
      final response = await _apiClient.dio.get('/mobile/izin-kategori');
      final List<dynamic> items = response.data['data'] ?? [];

      _kategoriList =
          items.map((json) => KategoriIzin.fromApiJson(json)).toList();
      notifyListeners();
    } on DioException catch (e) {
      final appEx = e.error is AppException ? e.error as AppException : AppException.fromDioException(e);
      debugPrint('Error loading kategori izin: ${appEx.userMessage}');
      _errorMessage = appEx.userMessage;
    } catch (e) {
      debugPrint('Error loading kategori izin: $e');
      _errorMessage = AppException.fromException(e).userMessage;
    }
  }

  Future<PengajuanIzin?> getIzinDetail(int id) async {
    try {
      final response = await _apiClient.dio.get('/mobile/izin/$id');
      final data = response.data['data'];
      if (data != null) {
        return PengajuanIzin.fromJson(data);
      }
      return null;
    } on DioException catch (e) {
      final appEx = e.error is AppException ? e.error as AppException : AppException.fromDioException(e);
      debugPrint('Error loading izin detail: ${appEx.userMessage}');
      _errorMessage = appEx.userMessage;
      return null;
    } catch (e) {
      debugPrint('Error loading izin detail: $e');
      _errorMessage = AppException.fromException(e).userMessage;
      return null;
    }
  }

  Future<PengajuanIzin?> getDetail(int id) async => getIzinDetail(id);

  /// Submit new izin request
  Future<bool> ajukanIzin({
    required int kategoriIzinId,
    required DateTime tanggalMulai,
    required DateTime tanggalSelesai,
    String? keterangan,
    required File fileDokumen,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final formData = FormData.fromMap({
        'kategori_izin_id': kategoriIzinId,
        'tanggal_mulai':
            '${tanggalMulai.year}-${tanggalMulai.month.toString().padLeft(2, '0')}-${tanggalMulai.day.toString().padLeft(2, '0')}',
        'tanggal_selesai':
            '${tanggalSelesai.year}-${tanggalSelesai.month.toString().padLeft(2, '0')}-${tanggalSelesai.day.toString().padLeft(2, '0')}',
        if (keterangan != null && keterangan.isNotEmpty)
          'keterangan': keterangan,
        'file_pendukung': await MultipartFile.fromFile(
          fileDokumen.path,
          filename: fileDokumen.path.split('/').last,
        ),
      });

      await _apiClient.dio.post(
        '/mobile/izin',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      // Reload the list
      await loadIzinList();
      return true;
    } on DioException catch (e) {
      final appEx = e.error is AppException ? e.error as AppException : AppException.fromDioException(e);
      _errorMessage = appEx.userMessage;
      debugPrint('Error submitting izin: $e');
      return false;
    } catch (e) {
      _errorMessage = AppException.fromException(e).userMessage;
      debugPrint('Error submitting izin: $e');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Update existing izin (only when status is PENDING)
  Future<bool> updateIzin({
    required int id,
    required int kategoriIzinId,
    required DateTime tanggalMulai,
    required DateTime tanggalSelesai,
    String? keterangan,
    File? fileDokumen,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final map = <String, dynamic>{
        'kategori_izin_id': kategoriIzinId,
        'tanggal_mulai':
            '${tanggalMulai.year}-${tanggalMulai.month.toString().padLeft(2, '0')}-${tanggalMulai.day.toString().padLeft(2, '0')}',
        'tanggal_selesai':
            '${tanggalSelesai.year}-${tanggalSelesai.month.toString().padLeft(2, '0')}-${tanggalSelesai.day.toString().padLeft(2, '0')}',
        'keterangan': keterangan ?? '',
      };

      if (fileDokumen != null) {
        map['file_pendukung'] = await MultipartFile.fromFile(
          fileDokumen.path,
          filename: fileDokumen.path.split('/').last,
        );
      }

      final formData = FormData.fromMap(map);

      await _apiClient.dio.post(
        '/mobile/izin/$id',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      await loadIzinList();
      return true;
    } on DioException catch (e) {
      final appEx = e.error is AppException ? e.error as AppException : AppException.fromDioException(e);
      _errorMessage = appEx.userMessage;
      debugPrint('Error updating izin: $e');
      return false;
    } catch (e) {
      _errorMessage = AppException.fromException(e).userMessage;
      debugPrint('Error updating izin: $e');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Delete izin (only when status is PENDING)
  Future<bool> hapusPengajuan(int id) async {
    _errorMessage = null;

    try {
      await _apiClient.dio.delete('/mobile/izin/$id');
      _izinList.removeWhere((i) => i.id == id);
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

  /// Cancel izin (only when status is DISETUJUI -> sets to DIBATALKAN)
  Future<bool> batalkanPengajuan(int id) async {
    _errorMessage = null;

    try {
      await _apiClient.dio.post('/mobile/izin/$id/batalkan');
      await loadIzinList();
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

  /// Calculate tanggal selesai based on jumlah_hari from master data
  DateTime? hitungTanggalSelesai({
    required DateTime tanggalMulai,
    required int jumlahHari,
  }) {
    if (jumlahHari <= 0) return null;
    return tanggalMulai.add(Duration(days: jumlahHari - 1));
  }

  /// Resolve the kategori_izin_id for submission
  int? resolveKategoriIzinId(
    KategoriIzin kategori,
    SubKategoriCutiKhusus? subKategori,
  ) {
    if (kategori.hasSubKategori && subKategori != null) {
      return subKategori.id;
    }
    return kategori.id;
  }

  void clearError() {
    _errorMessage = null;
    _errorType = null;
    notifyListeners();
  }
}
