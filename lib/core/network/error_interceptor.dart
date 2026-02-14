import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../error/app_exception.dart';
import '../widgets/force_logout_dialog.dart';
import '../../main.dart';

/// Interceptor Dio terpusat yang:
/// 1. Mengkonversi semua DioException → AppException
/// 2. Menangani 401 (force-logout) secara global dengan dialog alasan
class ErrorInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;
  static bool _isHandlingLogout = false;

  ErrorInterceptor(this._secureStorage);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final appException = AppException.fromDioException(err);

    // 401 pada endpoint yang ter-autentikasi → force logout
    if (err.response?.statusCode == 401) {
      final path = err.requestOptions.path;
      // Jangan force-logout untuk endpoint login (401 = salah password)
      if (!path.contains('/mobile/login')) {
        await _handleForceLogout(appException);
      }
    }

    // Pass error yang sudah di-wrap AppException ke provider
    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: appException,
        message: err.message,
      ),
    );
  }

  Future<void> _handleForceLogout(AppException exception) async {
    if (_isHandlingLogout) return;
    _isHandlingLogout = true;

    try {
      // Hapus stored auth
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'user_data');

      // Tentukan alasan logout
      final reason = _getLogoutReason(exception.serverMessage);

      // Tampilkan dialog via navigatorKey global
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black54,
          builder: (ctx) => ForceLogoutDialog(reason: reason),
        );
      }

      // Navigate ke login
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    } finally {
      _isHandlingLogout = false;
    }
  }

  /// Parse server message untuk menentukan alasan logout yang user-friendly
  String _getLogoutReason(String? serverMessage) {
    if (serverMessage == null || serverMessage.isEmpty) {
      return 'Sesi Anda telah berakhir. Silakan login kembali.';
    }

    final lower = serverMessage.toLowerCase();

    if (lower.contains('device') || lower.contains('perangkat')) {
      return 'Akun Anda telah login di perangkat lain. Anda otomatis keluar dari perangkat ini.';
    }
    if (lower.contains('password') || lower.contains('kata sandi')) {
      return 'Password Anda telah diubah. Silakan login dengan password baru.';
    }
    if (lower.contains('expired') ||
        lower.contains('kedaluwarsa') ||
        lower.contains('berakhir')) {
      return 'Sesi Anda telah berakhir. Silakan login kembali.';
    }
    if (lower.contains('disabled') ||
        lower.contains('nonaktif') ||
        lower.contains('dinonaktifkan')) {
      return 'Akun Anda telah dinonaktifkan. Hubungi admin untuk informasi lebih lanjut.';
    }

    // Fallback: gunakan server message jika cukup pendek, atau pesan generik
    if (serverMessage.length < 120) return serverMessage;
    return 'Sesi Anda telah berakhir. Silakan login kembali.';
  }
}
