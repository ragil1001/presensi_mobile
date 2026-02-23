import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/error/app_exception.dart';
import '../utils/safe_change_notifier.dart';
import '../data/models/cs_jadwal_model.dart';

class CsBerandaProvider with ChangeNotifier, SafeChangeNotifier {
  bool _isLoading = false;
  AppException? _error;
  CsJadwalHariIni? _jadwal;
  bool _shiftAvailable = false;
  int _totalTasks = 0;
  int _completedTasks = 0;

  final ApiClient _apiClient = ApiClient();

  bool get isLoading => _isLoading;
  AppException? get error => _error;
  String? get errorMessage => _error?.userMessage;
  CsJadwalHariIni? get jadwal => _jadwal;
  bool get shiftAvailable => _shiftAvailable;
  int get totalTasks => _totalTasks;
  int get completedTasks => _completedTasks;
  bool get hasJadwal => _jadwal != null;
  bool get hasTasks => _totalTasks > 0;

  Future<void> loadBeranda() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get('/mobile/cs/beranda');
      final data = response.data['data'];

      _jadwal = data['jadwal'] != null
          ? CsJadwalHariIni.fromJson(data['jadwal'])
          : null;
      _shiftAvailable = data['shift_available'] as bool? ?? false;

      final taskStats = data['task_stats'] as Map<String, dynamic>?;
      _totalTasks = taskStats?['total_tasks'] as int? ?? 0;
      _completedTasks = taskStats?['completed_tasks'] as int? ?? 0;

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

  void reset() {
    _jadwal = null;
    _shiftAvailable = false;
    _totalTasks = 0;
    _completedTasks = 0;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
