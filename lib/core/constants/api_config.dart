class ApiConfig {
  // Change this to your server IP/domain in production
  // For Android emulator use 10.0.2.2, for real device use your PC's local IP
  static const String baseUrl = 'https://api.qmssystem.app/api/v1';
  // static const String baseUrl = 'http://10.0.2.2:80/api/v1'; // Android emulator
  // static const String baseUrl = 'http://10.161.195.254:80/api/v1'; // Real device (WiFi IP)

  // Timeouts
  static const int connectTimeout = 15000; // 15 seconds
  static const int receiveTimeout = 15000;

  // App version (update this on each release)
  static const String appVersion = '2.0.0';
  
  // Cache settings
  static const int maxCacheSize = 768 * 1024; // 768KB maksimum (mobile)
  static const int cacheRetentionDays = 2; // Hari retensi cache
}
