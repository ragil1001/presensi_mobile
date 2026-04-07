import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:exif/exif.dart';
import 'package:intl/intl.dart';

/// Result of photo metadata validation
class PhotoValidationResult {
  final bool isValid;
  final String? errorMessage;
  final DateTime? photoDateTime;
  final DateTime? shiftEndDeadline;

  const PhotoValidationResult({
    required this.isValid,
    this.errorMessage,
    this.photoDateTime,
    this.shiftEndDeadline,
  });

  factory PhotoValidationResult.valid({DateTime? photoDateTime}) {
    return PhotoValidationResult(isValid: true, photoDateTime: photoDateTime);
  }

  factory PhotoValidationResult.invalid({
    required String message,
    DateTime? photoDateTime,
    DateTime? shiftEndDeadline,
  }) {
    return PhotoValidationResult(
      isValid: false,
      errorMessage: message,
      photoDateTime: photoDateTime,
      shiftEndDeadline: shiftEndDeadline,
    );
  }
}

/// Utility to read photo metadata and validate photo timestamps
class PhotoMetadataValidator {
  PhotoMetadataValidator._();

  /// Indonesia timezone offset (WIB = UTC+7)
  static const Duration indonesiaOffset = Duration(hours: 7);

  /// Maximum allowed time after shift ends (24 hours)
  static const Duration maxAllowedDelay = Duration(hours: 24);

  /// Read the date/time when photo was taken from EXIF metadata
  static Future<DateTime?> readPhotoDateTime(Uint8List bytes) async {
    try {
      final tags = await readExifFromBytes(bytes);
      if (tags.isEmpty) return null;

      // Try DateTimeOriginal first (when photo was actually taken)
      DateTime? dateTime = _parseExifDateTime(tags['EXIF DateTimeOriginal']);

      // Fallback to DateTimeDigitized
      dateTime ??= _parseExifDateTime(tags['EXIF DateTimeDigitized']);

      // Fallback to DateTime (modification time)
      dateTime ??= _parseExifDateTime(tags['Image DateTime']);

      return dateTime;
    } catch (e) {
      debugPrint('Error reading EXIF: $e');
      return null;
    }
  }

  /// Parse EXIF datetime string (format: "YYYY:MM:DD HH:MM:SS")
  static DateTime? _parseExifDateTime(IfdTag? tag) {
    if (tag == null) return null;
    final value = tag.printable;
    if (value.isEmpty || value == '0000:00:00 00:00:00') return null;

    try {
      // EXIF format: "2024:01:15 14:30:25"
      final parts = value.split(' ');
      if (parts.length != 2) return null;

      final dateParts = parts[0].split(':');
      final timeParts = parts[1].split(':');

      if (dateParts.length != 3 || timeParts.length != 3) return null;

      return DateTime(
        int.parse(dateParts[0]), // year
        int.parse(dateParts[1]), // month
        int.parse(dateParts[2]), // day
        int.parse(timeParts[0]), // hour
        int.parse(timeParts[1]), // minute
        int.parse(timeParts[2]), // second
      );
    } catch (e) {
      debugPrint('Error parsing EXIF datetime: $e');
      return null;
    }
  }

  /// Validate if photo is within allowed time after shift ends
  /// 
  /// [photoBytes] - Photo file bytes to read EXIF from
  /// [taskDate] - Date of the task (format: "YYYY-MM-DD" or "DD-MM-YYYY")
  /// [shiftEndTime] - Shift end time (format: "HH:MM" or "HH:MM:SS")
  /// 
  /// Returns validation result with details
  static Future<PhotoValidationResult> validatePhotoTime({
    required Uint8List photoBytes,
    required String taskDate,
    required String shiftEndTime,
  }) async {
    // Read photo timestamp from EXIF
    final photoDateTime = await readPhotoDateTime(photoBytes);

    // If no EXIF data, reject - likely screenshot/downloaded/stripped
    if (photoDateTime == null) {
      return PhotoValidationResult.invalid(
        message: 'Foto ini tidak memiliki metadata waktu pengambilan.\n\n'
            'Kemungkinan penyebab:\n'
            '• Screenshot\n'
            '• Foto dari internet/download\n'
            '• Foto dari WhatsApp/Telegram\n'
            '• Foto yang sudah diedit\n\n'
            'Silakan gunakan kamera untuk mengambil foto langsung.',
      );
    }

    // Parse shift end datetime
    final shiftEndDateTime = _parseShiftEndDateTime(taskDate, shiftEndTime);
    if (shiftEndDateTime == null) {
      debugPrint('Could not parse shift end time - allowing upload');
      return PhotoValidationResult.valid(photoDateTime: photoDateTime);
    }

    // Calculate deadline (shift end + 24 hours)
    final deadline = shiftEndDateTime.add(maxAllowedDelay);

    // Check if photo was taken after deadline
    if (photoDateTime.isAfter(deadline)) {
      final dateFormat = DateFormat('dd MMM yyyy HH:mm', 'id_ID');
      return PhotoValidationResult.invalid(
        message: 'Foto ini diambil pada ${dateFormat.format(photoDateTime)}, '
            'yang sudah lebih dari 24 jam setelah shift berakhir '
            '(${dateFormat.format(shiftEndDateTime)}).\n\n'
            'Batas waktu upload: ${dateFormat.format(deadline)}',
        photoDateTime: photoDateTime,
        shiftEndDeadline: deadline,
      );
    }

    return PhotoValidationResult.valid(photoDateTime: photoDateTime);
  }

  /// Parse task date and shift end time into DateTime
  static DateTime? _parseShiftEndDateTime(String taskDate, String shiftEndTime) {
    try {
      // Try parsing date in different formats
      DateTime? date;

      // Try YYYY-MM-DD format
      if (taskDate.contains('-') && taskDate.split('-')[0].length == 4) {
        date = DateTime.tryParse(taskDate);
      }

      // Try DD-MM-YYYY format
      if (date == null && taskDate.contains('-')) {
        final parts = taskDate.split('-');
        if (parts.length == 3) {
          date = DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}');
        }
      }

      // Try DD/MM/YYYY format
      if (date == null && taskDate.contains('/')) {
        final parts = taskDate.split('/');
        if (parts.length == 3) {
          date = DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}');
        }
      }

      if (date == null) return null;

      // Parse time (HH:MM or HH:MM:SS)
      final timeParts = shiftEndTime.split(':');
      if (timeParts.length < 2) return null;

      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;

      return DateTime(date.year, date.month, date.day, hour, minute, second);
    } catch (e) {
      debugPrint('Error parsing shift end datetime: $e');
      return null;
    }
  }
}
