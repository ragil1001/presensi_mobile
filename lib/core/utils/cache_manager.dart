import 'package:flutter/foundation.dart' show kIsWeb;
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
    if (kIsWeb) return;
    try {
      final directory = await getTemporaryDirectory();
      final now = DateTime.now();

      await for (final entity in directory.list()) {
        final stat = await entity.stat();
        if (now.difference(stat.modified) > Duration(days: daysToKeep)) {
          await entity.delete();
        }
      }
    } catch (e) {
      print('Error clearing old cache: $e');
    }
  }

  /// Menghitung ukuran cache saat ini
  static Future<int> getCurrentCacheSize() async {
    if (kIsWeb) return 0;
    try {
      final directory = await getTemporaryDirectory();
      int total = 0;

      await for (final entity in directory.list()) {
        total += (await entity.stat()).size;
      }

      return total;
    } catch (e) {
      print('Error getting cache size: $e');
      return 0;
    }
  }

  /// Membersihkan cache jika melebihi batas maksimum
  static Future<void> manageCacheSize() async {
    if (kIsWeb) return;
    try {
      final currentSize = await getCurrentCacheSize();

      if (currentSize > maxCacheSize) {
        final directory = await getTemporaryDirectory();
        List<FileWithDate> files = [];

        await for (final entity in directory.list()) {
          final stat = await entity.stat();
          files.add(FileWithDate(entity.path, stat.modified));
        }

        // Urutkan berdasarkan waktu modifikasi (terlama dulu)
        files.sort((a, b) => a.modifiedDate.compareTo(b.modifiedDate));

        // Hapus setengah dari file-file tertua
        final filesToDelete = files.length ~/ 2;
        for (int i = 0; i < filesToDelete; i++) {
          try {
            await (await directory.list().firstWhere((e) => e.path == files[i].path)).delete();
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
    if (kIsWeb) return;
    try {
      final directory = await getTemporaryDirectory();

      await for (final entity in directory.list()) {
        try {
          await entity.delete();
        } catch (e) {
          print('Error deleting file: ${e.toString()}');
        }
      }
    } catch (e) {
      print('Error clearing all cache: $e');
    }
  }
}
