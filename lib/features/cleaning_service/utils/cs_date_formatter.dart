class CsDateFormatter {
  static const _days = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
  ];
  static const _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  /// "2025-02-18" -> "Selasa, 18 Februari 2025"
  static String formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${_days[date.weekday - 1]}, ${date.day} ${_months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  /// "2025-02-18 14:30" -> "Selasa, 18 Februari 2025 14:30"
  static String formatDateTime(String dateTimeStr) {
    try {
      final date = DateTime.parse(dateTimeStr);
      final time =
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      return '${_days[date.weekday - 1]}, ${date.day} ${_months[date.month - 1]} ${date.year} $time';
    } catch (_) {
      return dateTimeStr;
    }
  }
}
