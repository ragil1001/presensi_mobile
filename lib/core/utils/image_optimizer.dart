import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageOptimizer {
  /// Mengompresi gambar dengan pengaturan optimal untuk mengurangi ukuran file
  static Future<File?> compressImage(File file, {int quality = 70}) async {
    try {
      // Menentukan dimensi maksimum berdasarkan kebutuhan aplikasi
      final maxWidth = 1024;
      final maxHeight = 768;
      
      final result = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: maxWidth,
        minHeight: maxHeight,
        quality: quality, // Menggunakan kualitas 70 untuk keseimbangan antara ukuran dan kualitas
        rotate: 0,
      );
      
      if (result != null) {
        // Menyimpan hasil kompresi ke file baru
        final compressedFile = File('${file.path}.compressed.jpg');
        await compressedFile.writeAsBytes(result);
        return compressedFile;
      }
      
      return null;
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }

  /// Menghitung ukuran file dalam bytes
  static Future<int> getFileSize(File file) async {
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// Mendapatkan statistik kompresi
  static Future<Map<String, dynamic>> getCompressionStats(File original, File? compressed) async {
    final originalSize = await getFileSize(original);
    final compressedSize = compressed != null ? await getFileSize(compressed) : 0;
    
    final savings = originalSize - compressedSize;
    final savingsPercent = originalSize > 0 ? (savings / originalSize * 100) : 0;
    
    return {
      'original_size': originalSize,
      'compressed_size': compressedSize,
      'savings_bytes': savings,
      'savings_percent': savingsPercent,
    };
  }
}