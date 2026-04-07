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

  String _friendlyError(dynamic e, String fallback) {
    if (e is DioException) {
      if (e.response?.statusCode == 422) {
        final errors = e.response?.data?['errors'];
        if (errors is Map) {
          final first = (errors.values.first as List?)?.first;
          if (first != null) return first.toString();
        }
      }
      if (e.response?.data?['message'] != null) {
        return e.response!.data['message'].toString();
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Koneksi timeout. Periksa jaringan Anda.';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Tidak dapat terhubung ke server.';
      }
    }
    return fallback;
  }

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
        } else {
          _activeSession = null;
          _checkpoints = [];
        }
      }
    } catch (e) {
      _error = _friendlyError(e, 'Gagal memuat konfigurasi. Silakan coba lagi.');
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
      _error = data['message']?.toString() ?? 'Gagal memulai patroli.';
    } catch (e) {
      _error = _friendlyError(e, 'Gagal memulai patroli. Silakan coba lagi.');
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
      _error = response.data['message']?.toString() ??
          'Gagal menyelesaikan patroli.';
    } catch (e) {
      _error =
          _friendlyError(e, 'Gagal menyelesaikan patroli. Silakan coba lagi.');
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
      _error = response.data['message']?.toString() ??
          'Gagal membatalkan patroli.';
    } catch (e) {
      _error =
          _friendlyError(e, 'Gagal membatalkan patroli. Silakan coba lagi.');
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

  /// Validate QR code locally against loaded checkpoint data.
  /// Returns instantly without network call.
  QrValidationResult validateQrCode(String qrCode) {
    if (_activeSession == null || !_activeSession!.isBerlangsung) {
      return QrValidationResult(false, 'Tidak ada sesi patroli aktif.');
    }

    // Find checkpoint matching this QR code
    final matching = _checkpoints.where((cp) => cp.qrCode == qrCode).toList();
    if (matching.isEmpty) {
      return QrValidationResult(
          false, 'QR Code tidak dikenali atau bukan milik konfigurasi ini.');
    }

    final checkpoint = matching.first;

    if (!checkpoint.isAktif) {
      return QrValidationResult(
          false, 'Checkpoint "${checkpoint.nama}" sedang dinonaktifkan.');
    }

    // Resolve config
    final config = _activeSession!.config ??
        (_configs.isNotEmpty
            ? _configs.firstWhere(
                (c) => c.id == _activeSession!.configId,
                orElse: () => _configs.first,
              )
            : null);

    // Check duplicate scan (STRICT / CUSTOM modes)
    if (config != null && !config.isFree && checkpoint.sudahScan) {
      return QrValidationResult(false,
          'Checkpoint "${checkpoint.nama}" sudah dipindai pada sesi ini.');
    }

    // Check order for STRICT mode
    if (config != null && config.isStrict) {
      final sorted = List<CheckpointProgress>.from(
          _checkpoints.where((cp) => cp.isAktif))
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

      for (final cp in sorted) {
        if (cp.id == checkpoint.id) break;
        if (cp.isWajib && !cp.sudahScan) {
          return QrValidationResult(false,
              'Pindai tidak sesuai urutan. Harap pindai "${cp.nama}" terlebih dahulu.');
        }
      }
    }

    return QrValidationResult(true, null, checkpoint);
  }
}
