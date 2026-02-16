import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import '../core/error/app_exception.dart';
import '../core/network/api_client.dart';
import '../core/services/gps_security/models.dart';
import '../data/models/presensi_model.dart';

class PresensiProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _isLoadingStatistik = false;
  bool _isLoadingHistory = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _errorMessageStatistik;
  String? _errorMessageHistory;
  String? _submitError;

  PresensiData? _presensiData;
  StatistikPeriode? _statistikPeriode;
  Future<void>? _loadPresensiDataFuture;

  // History data
  List<HistoryItem> _historyItems = [];
  bool _historyHasMore = false;
  int _historyPage = 1;
  int _historyTotal = 0;
  String _historyFilter = 'semua';
  Map<String, dynamic> _historyKaryawan = {};
  Map<String, dynamic> _historyProject = {};

  final ApiClient _apiClient = ApiClient();

  PresensiData? get presensiData => _presensiData;
  StatistikPeriode? get statistikPeriode => _statistikPeriode;
  bool get isLoading => _isLoading;
  bool get isLoadingStatistik => _isLoadingStatistik;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get errorMessageStatistik => _errorMessageStatistik;
  String? get errorMessageHistory => _errorMessageHistory;
  String? get submitError => _submitError;

  // History getters
  List<HistoryItem> get historyItems => _historyItems;
  bool get historyHasMore => _historyHasMore;
  int get historyTotal => _historyTotal;
  String get historyFilter => _historyFilter;
  Map<String, dynamic> get historyKaryawan => _historyKaryawan;
  Map<String, dynamic> get historyProject => _historyProject;

  List<String> get enabledIzinCategories {
    return _presensiData?.enabledIzinCategories ?? [];
  }

  List<String> get enabledSubKategoriIzin {
    return _presensiData?.enabledSubKategoriIzin ?? [];
  }

  Future<void> loadPresensiData() {
    if (_isLoading && _loadPresensiDataFuture != null) {
      return _loadPresensiDataFuture!;
    }

    _loadPresensiDataFuture = _doLoadPresensiData();
    return _loadPresensiDataFuture!;
  }

  Future<void> _doLoadPresensiData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get('/mobile/beranda');

      if (response.statusCode == 200 && response.data != null) {
        _presensiData = PresensiData.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        _errorMessage = null;
      }
    } on DioException catch (e) {
      final appEx = e.error is AppException ? e.error as AppException : AppException.fromDioException(e);
      _errorMessage = appEx.userMessage;
    } catch (e) {
      debugPrint('Error loading beranda: $e');
      _errorMessage = 'Terjadi kesalahan saat memuat data.';
    } finally {
      _isLoading = false;
      _loadPresensiDataFuture = null;
      notifyListeners();
    }
  }

  Future<void> refreshPresensiData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get('/mobile/beranda');

      if (response.statusCode == 200 && response.data != null) {
        _presensiData = PresensiData.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        _errorMessage = null;
      }
    } on DioException catch (e) {
      final appEx = e.error is AppException ? e.error as AppException : AppException.fromDioException(e);
      _errorMessage = appEx.userMessage;
    } catch (e) {
      debugPrint('Error refreshing beranda: $e');
      _errorMessage = 'Terjadi kesalahan saat memuat data.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStatistikPeriode(String bulan) async {
    if (_isLoadingStatistik) return;

    _isLoadingStatistik = true;
    _statistikPeriode = null;
    _errorMessageStatistik = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(
        '/mobile/statistik-periode',
        queryParameters: {'bulan': bulan},
      );

      if (response.statusCode == 200 && response.data != null) {
        _statistikPeriode = StatistikPeriode.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        _errorMessageStatistik = null;
      } else {
        _errorMessageStatistik = 'Gagal memuat statistik.';
      }
    } on DioException catch (e) {
      final appEx = e.error is AppException ? e.error as AppException : AppException.fromDioException(e);
      _errorMessageStatistik = appEx.userMessage;
    } catch (e) {
      _errorMessageStatistik = 'Terjadi kesalahan saat memuat statistik.';
    } finally {
      _isLoadingStatistik = false;
      notifyListeners();
    }
  }

  Future<void> refreshStatistikPeriode(String bulan) async {
    await loadStatistikPeriode(bulan);
  }

  // ── History Methods ──

  Future<void> loadHistoryPresensi({
    String filter = 'semua',
    String? startDate,
    String? endDate,
    bool refresh = false,
  }) async {
    if (_isLoadingHistory && !refresh) return;

    if (refresh || filter != _historyFilter) {
      _historyItems = [];
      _historyPage = 1;
      _historyHasMore = false;
      _historyFilter = filter;
    }

    _isLoadingHistory = true;
    _errorMessageHistory = null;
    notifyListeners();

    try {
      final params = <String, dynamic>{
        'filter': filter,
        'page': _historyPage,
        'per_page': 20,
      };
      if (startDate != null) params['start_date'] = startDate;
      if (endDate != null) params['end_date'] = endDate;

      debugPrint('[History] Loading page=${_historyPage} filter=$filter');
      final response = await _apiClient.dio.get(
        '/mobile/history-presensi',
        queryParameters: params,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final items = (data['data'] as List<dynamic>)
            .map((e) => HistoryItem.fromJson(e as Map<String, dynamic>))
            .toList();

        _historyItems.addAll(items);
        _historyHasMore = data['has_more'] ?? false;
        _historyTotal = data['total'] ?? 0;
        _historyPage++;
        _errorMessageHistory = null;

        if (data['karyawan'] != null) {
          _historyKaryawan = Map<String, dynamic>.from(data['karyawan']);
        }
        if (data['project'] != null) {
          _historyProject = Map<String, dynamic>.from(data['project']);
        }
        debugPrint(
          '[History] Loaded ${items.length} items, total=$_historyTotal, hasMore=$_historyHasMore',
        );
      }
    } on DioException catch (e) {
      final appEx = e.error is AppException ? e.error as AppException : AppException.fromDioException(e);
      _errorMessageHistory = appEx.userMessage;
    } catch (e) {
      debugPrint('[History] Error: $e');
      _errorMessageHistory = 'Terjadi kesalahan saat memuat history.';
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreHistory() async {
    if (!_historyHasMore || _isLoadingHistory) return;
    await loadHistoryPresensi(filter: _historyFilter);
  }

  // ── Cek Presensi ──

  Future<Map<String, dynamic>?> cekPresensi() async {
    try {
      final response = await _apiClient.dio.get('/mobile/cek-presensi');

      if (response.statusCode == 200 && response.data != null) {
        return Map<String, dynamic>.from(response.data['data']);
      }
      return null;
    } on DioException catch (e) {
      final appEx = e.error is AppException
          ? e.error as AppException
          : AppException.fromDioException(e);
      throw appEx;
    }
  }

  // ── Submit Presensi ──

  Future<Map<String, dynamic>?> submitPresensi({
    required String jenis,
    required int jadwalId,
    required double latitude,
    required double longitude,
    required File foto,
    SecurityPayload? securityPayload,
  }) async {
    if (_isSubmitting) return null;

    _isSubmitting = true;
    _submitError = null;
    notifyListeners();

    try {
      final fileName = 'presensi_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final formData = FormData.fromMap({
        'jenis': jenis,
        'jadwal_id': jadwalId,
        'latitude': latitude,
        'longitude': longitude,
        'foto': await MultipartFile.fromFile(
          foto.path,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        ),
        if (securityPayload != null) ...securityPayload.toFormFields(),
      });

      final response = await _apiClient.dio.post(
        '/mobile/submit-presensi',
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 201 && response.data != null) {
        _submitError = null;
        return Map<String, dynamic>.from(response.data['data'] ?? {});
      }
      return null;
    } on DioException catch (e) {
      final appEx = e.error is AppException
          ? e.error as AppException
          : AppException.fromDioException(e);
      _submitError = appEx.userMessage;
      throw appEx;
    } catch (e) {
      debugPrint('Error submitting presensi: $e');
      _submitError = 'Gagal menyimpan presensi.';
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    _errorMessageStatistik = null;
    _errorMessageHistory = null;
    notifyListeners();
  }
}
