import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/cache_manager.dart';
import '../utils/image_optimizer.dart';

class OptimizationManager {
  static const String _lastCacheClearKey = 'last_cache_clear_date';
  
  /// Menginisialisasi pengelolaan optimasi saat aplikasi dimulai
  static Future<void> initialize() async {
    // Membersihkan cache lama jika belum dilakukan hari ini
    await _clearCacheIfNeeded();
    
    // Menjalankan manajemen ukuran cache
    await CacheManager.manageCacheSize();
  }
  
  /// Memeriksa apakah perlu membersihkan cache hari ini
  static Future<void> _clearCacheIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().day;
      final lastClearDay = prefs.getInt(_lastCacheClearKey) ?? 0;
      
      if (today != lastClearDay) {
        // Jika hari ini berbeda dari hari terakhir pembersihan, lakukan pembersihan
        await CacheManager.clearOldCache(daysToKeep: 7);
        await prefs.setInt(_lastCacheClearKey, today);
      }
    } catch (e) {
      print('Error checking cache clear status: $e');
    }
  }
  
  /// Mengompresi gambar sebelum upload atau simpan lokal
  static Future<File?> optimizeImage(File imageFile) async {
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
          print('Image optimization: ${savingsPercent.toStringAsFixed(1)}% savings (${savings ~/ 1024} KB)');
        }
        
        return optimizedFile;
      }
      
      return imageFile; // Kembalikan file asli jika kompresi gagal
    } catch (e) {
      print('Error optimizing image: $e');
      return imageFile; // Kembalikan file asli jika terjadi error
    }
  }
  
  /// Mendapatkan statistik penggunaan penyimpanan
  static Future<Map<String, dynamic>> getStorageStats() async {
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
      print('Error getting storage stats: $e');
      return {
        'cache_size': 0,
        'app_documents_size': 0,
        'total_app_size_estimate': 0,
      };
    }
  }
  
  /// Menghitung ukuran direktori
  static Future<int> _getDirectorySize(Directory directory) async {
    int total = 0;
    
    if (await directory.exists()) {
      await for (FileSystemEntity entity in directory.list(recursive: true)) {
        if (entity is File) {
          total += await entity.length();
        }
      }
    }
    
    return total;
  }
}