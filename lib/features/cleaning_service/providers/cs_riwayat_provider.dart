import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/error/app_exception.dart';
import '../utils/safe_change_notifier.dart';
import '../data/models/cs_riwayat_model.dart';
import '../data/models/cs_cleaning_task_model.dart';

class CsRiwayatProvider with ChangeNotifier, SafeChangeNotifier {
  bool _isLoading = false;
  AppException? _error;
  RiwayatResponse? _riwayat;
  TaskListResponse? _riwayatDetail;

  final ApiClient _apiClient = ApiClient();

  bool get isLoading => _isLoading;
  AppException? get error => _error;
  String? get errorMessage => _error?.userMessage;
  RiwayatResponse? get riwayat => _riwayat;
  TaskListResponse? get riwayatDetail => _riwayatDetail;

  Future<void> loadRiwayat(int bulan, int tahun) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get('/mobile/cs/riwayat',
          queryParameters: {
            'bulan': bulan,
            'tahun': tahun,
          });
      _riwayat = RiwayatResponse.fromJson(response.data['data']);
      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _error = e.error is AppException
          ? e.error as AppException
          : AppException.fromDioException(e);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = AppException.fromException(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRiwayatDetail(String tanggal) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get('/mobile/cs/riwayat/$tanggal');
      _riwayatDetail = TaskListResponse.fromJson(response.data['data']);
      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _error = e.error is AppException
          ? e.error as AppException
          : AppException.fromDioException(e);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = AppException.fromException(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearDetail() {
    _riwayatDetail = null;
    notifyListeners();
  }

  void reset() {
    _riwayat = null;
    _riwayatDetail = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
