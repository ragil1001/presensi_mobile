class ApiConfig {
  // Change this to your server IP/domain in production
  // For Android emulator use 10.0.2.2, for real device use your PC's local IP
  static const String baseUrl = 'https://api.myprojectsystem.my.id/api/v1';
  // static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

  // Timeouts
  static const int connectTimeout = 15000; // 15 seconds
  static const int receiveTimeout = 15000;

  // App version (update this on each release)
  static const String appVersion = '1.0.0';
  
  // Cache settings
  static const int maxCacheSize = 5 * 1024 * 1024; // 5MB maksimum
  static const int cacheRetentionDays = 7; // Hari retensi cache
}
