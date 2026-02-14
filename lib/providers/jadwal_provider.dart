import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/error/app_exception.dart';
import '../core/network/api_client.dart';
import '../data/models/jadwal_model.dart';

class JadwalProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  JadwalBulan? _jadwalBulan;

  final ApiClient _apiClient = ApiClient();

  JadwalBulan? get jadwalBulan => _jadwalBulan;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadJadwalBulan(String bulan) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(
        '/mobile/jadwal',
        queryParameters: {'bulan': bulan},
      );

      if (response.statusCode == 200 && response.data != null) {
        _jadwalBulan = JadwalBulan.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        _errorMessage = null;
      }
    } on DioException catch (e) {
      final appEx = e.error is AppException ? e.error as AppException : AppException.fromDioException(e);
      _errorMessage = appEx.userMessage;
    } catch (e) {
      debugPrint('Error loading jadwal: $e');
      _errorMessage = AppException.fromException(e).userMessage;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshJadwalBulan(String bulan) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(
        '/mobile/jadwal',
        queryParameters: {'bulan': bulan},
      );

      if (response.statusCode == 200 && response.data != null) {
        _jadwalBulan = JadwalBulan.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        _errorMessage = null;
      }
    } on DioException catch (e) {
      final appEx = e.error is AppException ? e.error as AppException : AppException.fromDioException(e);
      _errorMessage = appEx.userMessage;
    } catch (e) {
      debugPrint('Error refreshing jadwal: $e');
      _errorMessage = AppException.fromException(e).userMessage;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
