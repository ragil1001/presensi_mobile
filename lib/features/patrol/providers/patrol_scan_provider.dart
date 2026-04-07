import 'package:presensi_mobile/core/platform/platform_io.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/patrol_models.dart';

class PatrolScanProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isUploading = false;
  PatrolScan? _lastScan;
  String? _error;
  String? _successMessage;

  bool get isUploading => _isUploading;
  PatrolScan? get lastScan => _lastScan;
  String? get error => _error;
  String? get successMessage => _successMessage;

  String _friendlyError(dynamic e) {
    if (e is DioException) {
      if (e.response?.statusCode == 422) {
        final errors = e.response?.data?['errors'];
        if (errors is Map) {
          final first = (errors.values.first as List?)?.first;
          if (first != null) return first.toString();
        }
        return e.response?.data?['message']?.toString() ??
            'Data yang dikirim tidak valid.';
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
      return 'Terjadi kesalahan jaringan. Silakan coba lagi.';
    }
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }

  Future<bool> submitScan({
    required String qrCode,
    String? deskripsi,
    double? latitude,
    double? longitude,
    double? accuracy,
    required List<File> fotos,
  }) async {
    _isUploading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();
    try {
      final formData = FormData.fromMap({
        'qr_code': qrCode,
        if (deskripsi != null && deskripsi.isNotEmpty) 'deskripsi': deskripsi,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (accuracy != null) 'akurasi_gps': accuracy,
      });
      for (var i = 0; i < fotos.length; i++) {
        formData.files.add(MapEntry(
          'foto[$i]',
          await MultipartFile.fromFile(
            fotos[i].path,
            filename: fotos[i].path.split('/').last,
          ),
        ));
      }
      final response = await _apiClient.dio.post(
        '/mobile/patrol/scan',
        data: formData,
      );
      final data = response.data;
      if (data['success'] == true) {
        _lastScan = PatrolScan.fromJson(data['data']);
        _successMessage = data['message'] ?? 'Scan berhasil';
        _isUploading = false;
        notifyListeners();
        return true;
      }
      _error = data['message']?.toString() ?? 'Gagal mengirim scan.';
    } catch (e) {
      _error = _friendlyError(e);
    }
    _isUploading = false;
    notifyListeners();
    return false;
  }

  Future<bool> submitReport({
    required String description,
    String? lantai,
    double? latitude,
    double? longitude,
    double? accuracy,
    required List<File> fotos,
  }) async {
    _isUploading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();
    try {
      final formData = FormData.fromMap({
        'laporan_insidental': description,
        if (lantai != null && lantai.isNotEmpty) 'lantai': lantai,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (accuracy != null) 'akurasi_gps': accuracy,
      });
      for (var i = 0; i < fotos.length; i++) {
        formData.files.add(MapEntry(
          'foto[$i]',
          await MultipartFile.fromFile(
            fotos[i].path,
            filename: fotos[i].path.split('/').last,
          ),
        ));
      }
      final response = await _apiClient.dio.post(
        '/mobile/patrol/scan',
        data: formData,
      );
      final data = response.data;
      if (data['success'] == true) {
        _lastScan = PatrolScan.fromJson(data['data']);
        _successMessage = data['message'] ?? 'Laporan berhasil dikirim';
        _isUploading = false;
        notifyListeners();
        return true;
      }
      _error = data['message']?.toString() ?? 'Gagal mengirim laporan.';
    } catch (e) {
      _error = _friendlyError(e);
    }
    _isUploading = false;
    notifyListeners();
    return false;
  }

  void clearMessages() {
    _error = null;
    _successMessage = null;
    _lastScan = null;
    notifyListeners();
  }

  void reset() {
    _isUploading = false;
    _lastScan = null;
    _error = null;
    _successMessage = null;
    notifyListeners();
  }
}
