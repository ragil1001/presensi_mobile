import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/patrol_models.dart';

class PatrolHistoryProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<PatrolSession> _sessions = [];
  PatrolSession? _sessionDetail;
  List<PatrolScan> _scans = [];
  bool _isLoading = false;
  String? _error;

  List<PatrolSession> get sessions => _sessions;
  PatrolSession? get sessionDetail => _sessionDetail;
  List<PatrolScan> get scans => _scans;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSessions(int bulan, int tahun) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiClient.dio.get(
        '/mobile/patrol/sessions',
        queryParameters: {'bulan': bulan, 'tahun': tahun},
      );
      final data = response.data;
      if (data['success'] == true) {
        _sessions = (data['data'] as List)
            .map((e) => PatrolSession.fromJson(e))
            .toList();
      }
    } on DioException catch (e) {
      _error =
          e.response?.data?['message']?.toString() ?? 'Gagal memuat riwayat';
    } catch (e) {
      _error = 'Terjadi kesalahan';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSessionDetail(int sessionId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiClient.dio
          .get('/mobile/patrol/sessions/$sessionId/detail');
      final data = response.data;
      if (data['success'] == true) {
        _sessionDetail = PatrolSession.fromJson(data['data']);
        _scans = (data['data']['scans'] as List?)
                ?.map((e) => PatrolScan.fromJson(e))
                .toList() ??
            [];
      }
    } on DioException catch (e) {
      _error = e.response?.data?['message']?.toString() ??
          'Gagal memuat detail sesi';
    } catch (e) {
      _error = 'Terjadi kesalahan';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearDetail() {
    _sessionDetail = null;
    _scans = [];
    notifyListeners();
  }

  void reset() {
    _sessions = [];
    _sessionDetail = null;
    _scans = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
