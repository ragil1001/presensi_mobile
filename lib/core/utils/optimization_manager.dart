import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:presensi_mobile/core/constants/api_config.dart';
import 'package:presensi_mobile/core/platform/platform_io.dart';
import '../utils/cache_manager.dart';
import '../utils/image_optimizer.dart';

class OptimizationManager {
  static const String _lastCacheClearKey = 'last_cache_clear_epoch_day';
  static const String _lastCacheVersionKey = 'last_cache_version';

  /// Menginisialisasi pengelolaan optimasi saat aplikasi dimulai
  static Future<void> initialize() async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();

    // Saat versi berubah, pastikan cache lama versi sebelumnya dipangkas.
    await _enforceCachePolicyForAppVersion(prefs);

    // Membersihkan cache lama jika belum dilakukan hari ini.
    await _clearCacheIfNeeded(prefs);

    // Menjalankan manajemen ukuran cache
    await CacheManager.manageCacheSize();
  }

  static Future<void> _enforceCachePolicyForAppVersion(
    SharedPreferences prefs,
  ) async {
    try {
      final lastVersion = prefs.getString(_lastCacheVersionKey);
      if (lastVersion == ApiConfig.appVersion) return;

      await CacheManager.clearOldCache(daysToKeep: 0);
      await CacheManager.manageCacheSize();
      await prefs.setString(_lastCacheVersionKey, ApiConfig.appVersion);
    } catch (e) {
      debugPrint('Error enforcing cache version policy: $e');
    }
  }

  /// Memeriksa apakah perlu membersihkan cache hari ini
  static Future<void> _clearCacheIfNeeded(SharedPreferences prefs) async {
    try {
      final now = DateTime.now().toUtc();
      final today = now.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
      final lastClearDay = prefs.getInt(_lastCacheClearKey) ?? 0;

      if (today != lastClearDay) {
        // Jika hari ini berbeda dari hari terakhir pembersihan, lakukan pembersihan
        await CacheManager.clearOldCache(daysToKeep: ApiConfig.cacheRetentionDays);
        await prefs.setInt(_lastCacheClearKey, today);
      }
    } catch (e) {
      debugPrint('Error checking cache clear status: $e');
    }
  }

  /// Mengompresi gambar sebelum upload atau simpan lokal
  static Future<File?> optimizeImage(File imageFile) async {
    if (kIsWeb) return imageFile;
    try {
      // Kompresi gambar dengan kualitas 70 untuk mengurangi ukuran
      final optimizedFile = await ImageOptimizer.compressImage(
        imageFile,
        quality: 70,
      );

      if (optimizedFile != null) {
        // Bandingkan ukuran sebelum dan sesudah kompresi
        final originalSize = await imageFile.length();
        final optimizedSize = await optimizedFile.length();

        if (kDebugMode) {
          final savings = originalSize - optimizedSize;
          final savingsPercent = originalSize > 0 ? (savings / originalSize * 100) : 0;
          debugPrint('Image optimization: ${savingsPercent.toStringAsFixed(1)}% savings (${savings ~/ 1024} KB)');
        }

        return optimizedFile;
      }

      return imageFile; // Kembalikan file asli jika kompresi gagal
    } catch (e) {
      debugPrint('Error optimizing image: $e');
      return imageFile; // Kembalikan file asli jika terjadi error
    }
  }

  /// Mendapatkan statistik penggunaan penyimpanan
  static Future<Map<String, dynamic>> getStorageStats() async {
    if (kIsWeb) {
      return {'cache_size': 0, 'app_documents_size': 0, 'total_app_size_estimate': 0};
    }
    try {
      final cacheSize = await CacheManager.getCurrentCacheSize();
      final appDocDir = await getApplicationDocumentsDirectory();
      final appDirSize = await _getDirectorySize(appDocDir);

      return {
        'cache_size': cacheSize,
        'app_documents_size': appDirSize,
        'total_app_size_estimate': cacheSize + appDirSize,
      };
    } catch (e) {
      debugPrint('Error getting storage stats: $e');
      return {
        'cache_size': 0,
        'app_documents_size': 0,
        'total_app_size_estimate': 0,
      };
    }
  }

  /// Menghitung ukuran direktori
  static Future<int> _getDirectorySize(dynamic directory) async {
    int total = 0;

    if (await directory.exists()) {
      await for (final entity in directory.list(recursive: true)) {
        total += ((await entity.stat()).size as int);
      }
    }

    return total;
  }
}
