import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../constants/api_config.dart';
import '../services/gps_security/device_integrity_checker.dart';
import '../services/gps_security/models.dart';
import 'error_interceptor.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _deviceId;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(milliseconds: ApiConfig.connectTimeout),
        receiveTimeout: const Duration(milliseconds: ApiConfig.receiveTimeout),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Attach auth token
          final token = await _secureStorage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Attach device ID for device binding
          final deviceId = await getDeviceId();
          if (deviceId != null) {
            options.headers['X-Device-Id'] = deviceId;
          }

          handler.next(options);
        },
      ),
    );

    // Error interceptor terpusat: konversi error + handle 401 force-logout
    dio.interceptors.add(ErrorInterceptor(_secureStorage));
  }

  /// Get or generate a persistent device ID
  Future<String?> getDeviceId() async {
    if (_deviceId != null) return _deviceId;

    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        _deviceId = android.id; // Unique Android ID
      } else if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        _deviceId = ios.identifierForVendor;
      }
    } catch (e) {
      debugPrint('Error getting device ID: $e');
    }

    return _deviceId;
  }

  /// Collect a full [DeviceFingerprint] for security payloads.
  Future<DeviceFingerprint> getDeviceFingerprint() async {
    return DeviceIntegrityChecker.collectFingerprint();
  }

  /// Get device name for display
  Future<String> getDeviceName() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        return '${android.brand} ${android.model}';
      } else if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        return ios.utsname.machine;
      }
    } catch (e) {
      debugPrint('Error getting device name: $e');
    }
    return 'Unknown Device';
  }

  /// Save auth token securely
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: 'access_token', value: token);
  }

  /// Read auth token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'access_token');
  }

  /// Clear all auth data
  Future<void> clearAuth() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'user_data');
  }

  /// Save user data as JSON string
  Future<void> saveUserData(String jsonString) async {
    await _secureStorage.write(key: 'user_data', value: jsonString);
  }

  /// Read user data JSON string
  Future<String?> getUserData() async {
    return await _secureStorage.read(key: 'user_data');
  }

  /// Save/read remember me preference
  Future<void> setRememberMe(bool value, String? username) async {
    await _secureStorage.write(
      key: 'remember_me',
      value: value.toString(),
    );
    if (value && username != null) {
      await _secureStorage.write(key: 'remembered_username', value: username);
    } else {
      await _secureStorage.delete(key: 'remembered_username');
    }
  }

  Future<bool> getRememberMe() async {
    final value = await _secureStorage.read(key: 'remember_me');
    return value == 'true';
  }

  Future<String?> getRememberedUsername() async {
    return await _secureStorage.read(key: 'remembered_username');
  }
}
