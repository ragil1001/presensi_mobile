import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/api_config.dart';
import '../platform/platform_io.dart';

/// Kelas bantuan untuk menyimpan informasi file dan tanggal modifikasinya
class FileWithDate {
  final String path;
  final DateTime modifiedDate;
  final int sizeBytes;

  const FileWithDate(this.path, this.modifiedDate, this.sizeBytes);
}

class CacheManager {
  static const int maxCacheSize = ApiConfig.maxCacheSize;

  /// Membersihkan cache yang lebih tua dari jumlah hari yang ditentukan
  static Future<void> clearOldCache({int daysToKeep = 7}) async {
    if (kIsWeb) return;
    try {
      final files = await _collectCacheFiles();
      final now = DateTime.now();
      final cutoffDate = now.subtract(Duration(days: daysToKeep));

      for (final file in files) {
        final shouldDelete = daysToKeep <= 0 || file.modifiedDate.isBefore(cutoffDate);
        if (!shouldDelete) continue;
        try {
          final ioFile = File(file.path);
          if (await ioFile.exists()) {
            await ioFile.delete();
          }
        } catch (e) {
          debugPrint('Error deleting old cache file: ${file.path} ($e)');
        }
      }
      await _deleteEmptyDirectories();
    } catch (e) {
      debugPrint('Error clearing old cache: $e');
    }
  }

  /// Menghitung ukuran cache saat ini
  static Future<int> getCurrentCacheSize() async {
    if (kIsWeb) return 0;
    try {
      final files = await _collectCacheFiles();
      return files.fold<int>(0, (sum, file) => sum + file.sizeBytes);
    } catch (e) {
      debugPrint('Error getting cache size: $e');
      return 0;
    }
  }

  /// Membersihkan cache jika melebihi batas maksimum
  static Future<void> manageCacheSize() async {
    if (kIsWeb) return;
    try {
      final files = await _collectCacheFiles();
      int currentSize = files.fold<int>(0, (sum, file) => sum + file.sizeBytes);
      if (currentSize > maxCacheSize) {
        // Urutkan berdasarkan waktu modifikasi (terlama dulu)
        files.sort((a, b) => a.modifiedDate.compareTo(b.modifiedDate));

        // Hapus file tertua sampai ukuran cache berada di bawah batas.
        for (final file in files) {
          if (currentSize <= maxCacheSize) break;
          try {
            final ioFile = File(file.path);
            if (await ioFile.exists()) {
              await ioFile.delete();
              currentSize -= file.sizeBytes;
            }
          } catch (e) {
            debugPrint('Error deleting file: ${e.toString()}');
          }
        }
        await _deleteEmptyDirectories();
      }
    } catch (e) {
      debugPrint('Error managing cache size: $e');
    }
  }

  /// Membersihkan semua cache
  static Future<void> clearAllCache() async {
    if (kIsWeb) return;
    try {
      final directory = await getTemporaryDirectory();
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
      await directory.create(recursive: true);
    } catch (e) {
      debugPrint('Error clearing all cache: $e');
    }
  }

  static Future<List<FileWithDate>> _collectCacheFiles() async {
    final directory = await getTemporaryDirectory();
    if (!await directory.exists()) return const [];

    final files = <FileWithDate>[];
    await for (final entity in directory.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      try {
        final stat = await entity.stat();
        files.add(FileWithDate(entity.path, stat.modified, stat.size));
      } catch (e) {
        debugPrint('Error reading cache file stat: ${entity.path} ($e)');
      }
    }
    return files;
  }

  static Future<void> _deleteEmptyDirectories() async {
    final root = await getTemporaryDirectory();
    if (!await root.exists()) return;

    final dirPaths = <String>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      try {
        if (await FileSystemEntity.isDirectory(entity.path)) {
          dirPaths.add(entity.path);
        }
      } catch (_) {
        // ignore entity that can't be inspected
      }
    }

    // Hapus dari direktori terdalam dulu, root cache tidak dihapus.
    dirPaths.sort((a, b) => b.length.compareTo(a.length));
    for (final path in dirPaths) {
      final dir = Directory(path);
      try {
        if (await dir.exists()) {
          final isEmpty = await dir.list(followLinks: false).isEmpty;
          if (isEmpty) {
            await dir.delete();
          }
        }
      } catch (_) {}
    }
  }
}
