import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Tipe error yang bisa ditangani UI
enum AppExceptionType {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  validation,
  rateLimit,
  server,
  unknown,
}

/// Model error terpusat — semua DioException dikonversi ke AppException
/// sehingga UI hanya menerima pesan yang user-friendly (Bahasa Indonesia).
class AppException implements Exception {
  final AppExceptionType type;
  final String userMessage;
  final String? debugMessage;
  final int? statusCode;
  final String? serverMessage;
  final Map<String, List<String>>? validationErrors;

  const AppException({
    required this.type,
    required this.userMessage,
    this.debugMessage,
    this.statusCode,
    this.serverMessage,
    this.validationErrors,
  });

  /// Apakah error ini bisa di-retry oleh user
  bool get isRetryable =>
      type == AppExceptionType.network ||
      type == AppExceptionType.timeout ||
      type == AppExceptionType.server;

  /// Icon sesuai tipe error
  IconData get icon {
    switch (type) {
      case AppExceptionType.network:
        return Icons.wifi_off_rounded;
      case AppExceptionType.timeout:
        return Icons.timer_off_rounded;
      case AppExceptionType.unauthorized:
        return Icons.lock_outline_rounded;
      case AppExceptionType.forbidden:
        return Icons.block_rounded;
      case AppExceptionType.notFound:
        return Icons.search_off_rounded;
      case AppExceptionType.server:
        return Icons.cloud_off_rounded;
      case AppExceptionType.validation:
        return Icons.edit_off_rounded;
      case AppExceptionType.rateLimit:
        return Icons.hourglass_top_rounded;
      case AppExceptionType.unknown:
        return Icons.error_outline_rounded;
    }
  }

  /// Konversi DioException → AppException
  factory AppException.fromDioException(DioException e) {
    // Timeout
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return AppException(
        type: AppExceptionType.timeout,
        userMessage: 'Koneksi timeout. Periksa jaringan Anda dan coba lagi.',
        debugMessage: 'DioTimeout: ${e.type} – ${e.message}',
      );
    }

    // Connection error (no internet, DNS, etc.)
    if (e.type == DioExceptionType.connectionError) {
      return AppException(
        type: AppExceptionType.network,
        userMessage:
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
        debugMessage: 'ConnectionError: ${e.message}',
      );
    }

    // HTTP response errors
    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;
    final serverMsg =
        (responseData is Map) ? responseData['message']?.toString() : null;

    if (statusCode == 401) {
      return AppException(
        type: AppExceptionType.unauthorized,
        userMessage:
            serverMsg ?? 'Sesi Anda telah berakhir. Silakan login kembali.',
        statusCode: 401,
        serverMessage: serverMsg,
        debugMessage: '401 Unauthorized: $serverMsg',
      );
    }

    if (statusCode == 403) {
      return AppException(
        type: AppExceptionType.forbidden,
        userMessage: serverMsg ?? 'Akses ditolak. Perangkat tidak terdaftar.',
        statusCode: 403,
        serverMessage: serverMsg,
        debugMessage: '403 Forbidden: $serverMsg',
      );
    }

    if (statusCode == 404) {
      return AppException(
        type: AppExceptionType.notFound,
        userMessage: 'Data yang diminta tidak ditemukan.',
        statusCode: 404,
        serverMessage: serverMsg,
        debugMessage: '404 NotFound: ${e.requestOptions.path}',
      );
    }

    if (statusCode == 422) {
      Map<String, List<String>>? valErrors;
      String displayMsg = 'Data tidak valid. Periksa kembali formulir Anda.';

      if (responseData is Map && responseData['errors'] != null) {
        final rawErrors = responseData['errors'] as Map;
        valErrors = rawErrors.map((key, value) {
          final list = (value is List)
              ? value.map((e) => e.toString()).toList()
              : [value.toString()];
          return MapEntry(key.toString(), list);
        });
        final firstError = valErrors.values.first;
        if (firstError.isNotEmpty) {
          displayMsg = firstError.first;
        }
      } else if (serverMsg != null) {
        displayMsg = serverMsg;
      }

      return AppException(
        type: AppExceptionType.validation,
        userMessage: displayMsg,
        statusCode: 422,
        serverMessage: serverMsg,
        validationErrors: valErrors,
        debugMessage: '422 Validation: $displayMsg',
      );
    }

    if (statusCode == 429) {
      return AppException(
        type: AppExceptionType.rateLimit,
        userMessage:
            'Terlalu banyak percobaan. Silakan tunggu beberapa saat.',
        statusCode: 429,
        debugMessage: '429 RateLimit',
      );
    }

    if (statusCode != null && statusCode >= 500) {
      return AppException(
        type: AppExceptionType.server,
        userMessage:
            'Server sedang mengalami gangguan. Silakan coba lagi nanti.',
        statusCode: statusCode,
        serverMessage: serverMsg,
        debugMessage: '$statusCode Server: $serverMsg',
      );
    }

    return AppException(
      type: AppExceptionType.unknown,
      userMessage: serverMsg ?? 'Terjadi kesalahan. Silakan coba lagi.',
      statusCode: statusCode,
      debugMessage: 'Unknown DioException: ${e.message}',
    );
  }

  /// Konversi dari exception apapun
  factory AppException.fromException(dynamic e) {
    if (e is AppException) return e;
    if (e is DioException) return AppException.fromDioException(e);
    return AppException(
      type: AppExceptionType.unknown,
      userMessage: 'Terjadi kesalahan. Silakan coba lagi.',
      debugMessage: e.toString(),
    );
  }

  @override
  String toString() => 'AppException($type): $userMessage';
}
