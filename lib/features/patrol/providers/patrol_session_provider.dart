import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/patrol_models.dart';

class PatrolSessionProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<PatrolConfig> _configs = [];
  PatrolSession? _activeSession;
  List<CheckpointProgress> _checkpoints = [];
  bool _isLoading = false;
  bool _isStarting = false;
  bool _isEnding = false;
  String? _error;

  List<PatrolConfig> get configs => _configs;
  PatrolSession? get activeSession => _activeSession;
  List<CheckpointProgress> get checkpoints => _checkpoints;
  bool get isLoading => _isLoading;
  bool get isStarting => _isStarting;
  bool get isEnding => _isEnding;
  String? get error => _error;
  bool get hasActiveSession =>
      _activeSession != null && _activeSession!.isBerlangsung;

  CheckpointProgress? get nextCheckpoint {
    if (_activeSession == null || _checkpoints.isEmpty) return null;
    final config = _activeSession!.config ??
        (_configs.isNotEmpty
            ? _configs.firstWhere(
                (c) => c.id == _activeSession!.configId,
                orElse: () => _configs.first,
              )
            : null);
    if (config != null && config.isFree) return null;
    try {
      return _checkpoints.where((cp) => !cp.sudahScan && cp.isAktif).first;
    } catch (_) {
      return null;
    }
  }

  int get scannedCount => _checkpoints.where((cp) => cp.sudahScan).length;
  int get totalCheckpoints => _checkpoints.where((cp) => cp.isAktif).length;

  Future<void> loadConfigs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiClient.dio.get('/mobile/patrol/configs');
      final data = response.data;
      if (data['success'] == true) {
        _configs = (data['data'] as List)
            .map((e) => PatrolConfig.fromJson(e))
            .toList();

        // Check for active session
        if (data['active_session'] != null) {
          _activeSession = PatrolSession.fromJson(data['active_session']);
          await loadProgress(_activeSession!.id);
        }
      }
    } on DioException catch (e) {
      _error = e.response?.data?['message']?.toString() ??
          'Gagal memuat konfigurasi';
    } catch (e) {
      _error = 'Terjadi kesalahan';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> startSession(int configId) async {
    _isStarting = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiClient.dio.post(
        '/mobile/patrol/session/start',
        data: {'config_id': configId},
      );
      final data = response.data;
      if (data['success'] == true) {
        _activeSession = PatrolSession.fromJson(data['data']['session']);
        if (data['data']['checkpoints'] != null) {
          _checkpoints = (data['data']['checkpoints'] as List)
              .map((e) => CheckpointProgress.fromJson(e))
              .toList();
        }
        _isStarting = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      _error = e.response?.data?['message']?.toString() ??
          'Gagal memulai patroli';
    } catch (e) {
      _error = 'Terjadi kesalahan';
    }
    _isStarting = false;
    notifyListeners();
    return false;
  }

  Future<bool> endSession(int sessionId, {String? catatan}) async {
    _isEnding = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiClient.dio.post(
        '/mobile/patrol/session/$sessionId/end',
        data: {'catatan': catatan},
      );
      if (response.data['success'] == true) {
        _activeSession = null;
        _checkpoints = [];
        _isEnding = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      _error = e.response?.data?['message']?.toString() ??
          'Gagal menyelesaikan patroli';
    } catch (e) {
      _error = 'Terjadi kesalahan';
    }
    _isEnding = false;
    notifyListeners();
    return false;
  }

  Future<bool> cancelSession(int sessionId, {String? alasan}) async {
    _isEnding = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiClient.dio.post(
        '/mobile/patrol/session/$sessionId/cancel',
        data: {'alasan': alasan},
      );
      if (response.data['success'] == true) {
        _activeSession = null;
        _checkpoints = [];
        _isEnding = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      _error = e.response?.data?['message']?.toString() ??
          'Gagal membatalkan patroli';
    } catch (e) {
      _error = 'Terjadi kesalahan';
    }
    _isEnding = false;
    notifyListeners();
    return false;
  }

  Future<void> loadProgress(int sessionId) async {
    try {
      final response = await _apiClient.dio
          .get('/mobile/patrol/session/$sessionId/progress');
      final data = response.data;
      if (data['success'] == true) {
        _activeSession = PatrolSession.fromJson(data['data']['session']);
        _checkpoints = (data['data']['progress'] as List)
            .map((e) => CheckpointProgress.fromJson(e))
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> refreshProgress() async {
    if (_activeSession == null) return;
    await loadProgress(_activeSession!.id);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _configs = [];
    _activeSession = null;
    _checkpoints = [];
    _isLoading = false;
    _isStarting = false;
    _isEnding = false;
    _error = null;
    notifyListeners();
  }
}
