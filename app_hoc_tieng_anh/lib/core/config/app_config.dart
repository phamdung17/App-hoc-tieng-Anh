// lib/core/config/app_config.dart
//
// Cấu hình môi trường: base URL backend, timeout, v.v.
// KHÔNG đặt secrets ở đây — token lưu trong flutter_secure_storage.

class AppConfig {
  AppConfig._();

  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'LingoUp',
  );

  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  // Must point to the FastAPI API root. Override for a physical device or
  // deployment with --dart-define=API_BASE_URL=https://example.com/api/v1.
  // Android emulator: 10.0.2.2 points to the host machine's localhost.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  // Dio timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Keep client upload validation aligned with the backend's 5 MiB limit.
  static const int maxImageSizeBytes = 5 * 1024 * 1024;
}
