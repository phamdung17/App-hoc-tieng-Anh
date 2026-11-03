import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_config.dart';

/// Shared authenticated API client for the FastAPI `/api/v1` endpoints.
class AppApi {
  AppApi._() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        sendTimeout: AppConfig.sendTimeout,
        headers: const {'Accept': 'application/json'},
      ),
    );

    // ── 0. URL Normalization interceptor: đảm bảo tiền tố /api/v1 ──────────
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.path = normalizePath(options.path);
          handler.next(options);
        },
      ),
    );

    // ── 1. Auth interceptor: đính kèm access_token vào mỗi request ──────────
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read(key: accessTokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

    // ── 2. Token refresh interceptor: tự động làm mới token khi gặp 401 ─────
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onError: (DioException err, ErrorInterceptorHandler handler) async {
          // Chỉ xử lý 401 và không phải từ chính endpoint /auth/refresh
          if (err.response?.statusCode == 401 &&
              !(err.requestOptions.path.contains('/auth/refresh'))) {
            try {
              final refreshToken = await storage.read(key: refreshTokenKey);
              if (refreshToken == null) {
                await clearTokens();
                handler.reject(err);
                return;
              }

              // Gọi refresh bằng Dio riêng để không kích hoạt lại interceptor này
              final refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
              final refreshResp = await refreshDio.post(
                normalizePath('/auth/refresh'),
                data: {'refresh_token': refreshToken},
              );

              final newAccess = refreshResp.data['access_token'] as String;
              final newRefresh = refreshResp.data['refresh_token'] as String;
              await storage.write(key: accessTokenKey, value: newAccess);
              await storage.write(key: refreshTokenKey, value: newRefresh);

              // Retry request ban đầu với token mới
              err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
              final retryResponse = await dio.fetch(err.requestOptions);
              handler.resolve(retryResponse);
            } catch (_) {
              await clearTokens();
              handler.reject(err);
            }
            return;
          }
          handler.next(err);
        },
      ),
    );
  }

  static final AppApi instance = AppApi._();
  static const storage = FlutterSecureStorage();
  static const accessTokenKey = 'access_token';
  static const refreshTokenKey = 'refresh_token';

  late final Dio dio;

  /// Chuẩn hóa đường dẫn endpoint:
  /// - Giữ nguyên URL tuyệt đối (http:// hoặc https://)
  /// - Giữ nguyên các endpoint đặc biệt ở root nếu có (ví dụ '/health')
  /// - Đảm bảo tiền tố /api/v1 luôn xuất hiện đúng 1 lần duy nhất, không trùng lặp
  static String normalizePath(String path) {
    final trimmed = path.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';

    if (cleanPath == '/health') {
      return cleanPath;
    }

    if (cleanPath.startsWith('/api/v1/') || cleanPath == '/api/v1') {
      return cleanPath;
    }

    return '/api/v1$cleanPath';
  }

  /// Trả về URL đầy đủ đã phân giải chính xác theo RFC 3986
  static String resolveUrl(String path, {String? customBaseUrl}) {
    final base = AppConfig.cleanBaseUrl(customBaseUrl ?? AppConfig.baseUrl);
    final normPath = normalizePath(path);
    if (normPath.startsWith('http://') || normPath.startsWith('https://')) {
      return normPath;
    }
    return '$base$normPath';
  }

  Future<void> saveTokens(Map<String, dynamic> tokens) async {
    final access = tokens['access_token'] as String?;
    final refresh = tokens['refresh_token'] as String?;
    if (access == null || refresh == null) {
      throw const FormatException('Phản hồi xác thực thiếu token.');
    }
    await storage.write(key: accessTokenKey, value: access);
    await storage.write(key: refreshTokenKey, value: refresh);
  }

  Future<void> clearTokens() async {
    await storage.delete(key: accessTokenKey);
    await storage.delete(key: refreshTokenKey);
  }
}
