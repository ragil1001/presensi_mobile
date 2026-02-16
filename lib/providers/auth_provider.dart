import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_config.dart';
import '../core/error/app_exception.dart';
import '../data/models/karyawan_model.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider with ChangeNotifier {
  AuthState _state = AuthState.initial;
  String? _errorMessage;
  String? _errorType;
  String? _token;
  Karyawan? _currentUser;

  final ApiClient _apiClient = ApiClient();

  AuthState get state => _state;
  Karyawan? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  String? get errorType => _errorType;
  String? get token => _token;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;

  Future<bool> login(
    String username,
    String password, {
    bool rememberMe = false,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    _errorType = null;
    notifyListeners();

    try {
      final deviceId = await _apiClient.getDeviceId();
      final deviceName = await _apiClient.getDeviceName();

      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint('Error getting FCM token: $e');
      }

      final response = await _apiClient.dio.post('/mobile/login', data: {
        'username': username,
        'password': password,
        'device_id': deviceId ?? 'unknown',
        'device_name': deviceName,
        'app_version': ApiConfig.appVersion,
        'fcm_token': fcmToken,
      });

      final data = response.data['data'];
      final token = data['access_token'] as String;
      final userData = data['user'] as Map<String, dynamic>;

      await _apiClient.saveToken(token);
      await _apiClient.saveUserData(jsonEncode(userData));
      await _apiClient.setRememberMe(rememberMe, rememberMe ? username : null);

      _token = token;
      _currentUser = Karyawan.fromJson(userData);
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      final appEx = e.error is AppException ? e.error as AppException : AppException.fromDioException(e);
      _errorMessage = appEx.userMessage;
      _errorType = appEx.type.name;
      _state = AuthState.error;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      _errorMessage = 'Terjadi kesalahan. Silakan coba lagi.';
      _errorType = 'unknown';
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    // Simpan token sebelum clear, untuk dikirim ke server nanti
    final savedToken = await _apiClient.getToken();

    // Hapus token lokal DULUAN supaya interceptor tahu kita sudah logout
    // jika ada 401 dari request background yang terlambat.
    await _apiClient.clearAuth();
    _token = null;
    _currentUser = null;
    _state = AuthState.unauthenticated;
    notifyListeners();

    // Beritahu server dengan token eksplisit di header (best-effort)
    if (savedToken != null) {
      try {
        await _apiClient.dio.post(
          '/mobile/logout',
          options: Options(
            headers: {'Authorization': 'Bearer $savedToken'},
          ),
        );
      } catch (e) {
        debugPrint('Logout API error (ignored): $e');
      }
    }
  }

  Future<void> initAuth() async {
    final token = await _apiClient.getToken();

    if (token == null) {
      _state = AuthState.unauthenticated;
      return;
    }

    _token = token;

    final userDataJson = await _apiClient.getUserData();
    if (userDataJson != null) {
      try {
        final userData = jsonDecode(userDataJson) as Map<String, dynamic>;
        _currentUser = Karyawan.fromJson(userData);
        _state = AuthState.authenticated;
      } catch (e) {
        debugPrint('Error parsing cached user data: $e');
        await _apiClient.clearAuth();
        _token = null;
        _state = AuthState.unauthenticated;
      }
    } else {
      try {
        await refreshUser();
      } catch (e) {
        await _apiClient.clearAuth();
        _token = null;
        _state = AuthState.unauthenticated;
      }
    }
  }

  Future<void> refreshUser() async {
    try {
      final response = await _apiClient.dio.get('/mobile/me');
      final userData = response.data['data']['user'] as Map<String, dynamic>;

      await _apiClient.saveUserData(jsonEncode(userData));
      _currentUser = Karyawan.fromJson(userData);
      _state = AuthState.authenticated;
      notifyListeners();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _apiClient.clearAuth();
        _token = null;
        _currentUser = null;
        _state = AuthState.unauthenticated;
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _errorMessage = null;
    _errorType = null;

    try {
      await _apiClient.dio.post('/mobile/change-password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': confirmPassword,
      });

      await _apiClient.clearAuth();
      _token = null;
      _currentUser = null;
      _state = AuthState.unauthenticated;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      final appEx = e.error is AppException ? e.error as AppException : AppException.fromDioException(e);
      _errorMessage = appEx.userMessage;
      _errorType = appEx.type.name;
      notifyListeners();
      return false;
    }
  }

  Future<bool> isTokenValid() async {
    final token = await _apiClient.getToken();
    return token != null;
  }

  Future<String?> getRememberedUsername() async {
    return await _apiClient.getRememberedUsername();
  }

  Future<bool> shouldRemember() async {
    return await _apiClient.getRememberMe();
  }

  void clearError() {
    _errorMessage = null;
    _errorType = null;
    notifyListeners();
  }
}
