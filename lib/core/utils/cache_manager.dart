import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Kelas bantuan untuk menyimpan informasi file dan tanggal modifikasinya
class FileWithDate {
  final String path;
  final DateTime modifiedDate;
  
  FileWithDate(this.path, this.modifiedDate);
}

class CacheManager {
  static const maxCacheSize = 5 * 1024 * 1024; // 5MB maksimum
  
  /// Membersihkan cache yang lebih tua dari jumlah hari yang ditentukan
  static Future<void> clearOldCache({int daysToKeep = 7}) async {
    try {
      final directory = await getTemporaryDirectory();
      final now = DateTime.now();
      
      await for (FileSystemEntity entity in directory.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          if (now.difference(stat.modified) > Duration(days: daysToKeep)) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      print('Error clearing old cache: $e');
    }
  }
  
  /// Menghitung ukuran cache saat ini
  static Future<int> getCurrentCacheSize() async {
    try {
      final directory = await getTemporaryDirectory();
      int total = 0;
      
      await for (FileSystemEntity entity in directory.list()) {
        if (entity is File) {
          total += await entity.length();
        }
      }
      
      return total;
    } catch (e) {
      print('Error getting cache size: $e');
      return 0;
    }
  }
  
  /// Membersihkan cache jika melebihi batas maksimum
  static Future<void> manageCacheSize() async {
    try {
      final currentSize = await getCurrentCacheSize();
      
      if (currentSize > maxCacheSize) {
        // Jika cache melebihi batas, hapus setengah dari file-file tertua
        final directory = await getTemporaryDirectory();
        List<FileWithDate> files = [];
        
        await for (FileSystemEntity entity in directory.list()) {
          if (entity is File) {
            final stat = await entity.stat();
            files.add(FileWithDate(entity.path, stat.modified));
          }
        }
        
        // Urutkan berdasarkan waktu modifikasi (terlama dulu)
        files.sort((a, b) => a.modifiedDate.compareTo(b.modifiedDate));
        
        // Hapus setengah dari file-file tertua
        final filesToDelete = files.length ~/ 2;
        for (int i = 0; i < filesToDelete; i++) {
          try {
            final file = File(files[i].path);
            await file.delete();
          } catch (e) {
            print('Error deleting file: ${e.toString()}');
          }
        }
      }
    } catch (e) {
      print('Error managing cache size: $e');
    }
  }
  
  /// Membersihkan semua cache
  static Future<void> clearAllCache() async {
    try {
      final directory = await getTemporaryDirectory();
      
      await for (FileSystemEntity entity in directory.list()) {
        if (entity is File) {
          try {
            await entity.delete();
          } catch (e) {
            print('Error deleting file: ${e.toString()}');
          }
        }
      }
    } catch (e) {
      print('Error clearing all cache: $e');
    }
  }
}