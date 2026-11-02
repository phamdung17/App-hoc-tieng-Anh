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
  }

  static final AppApi instance = AppApi._();
  static const storage = FlutterSecureStorage();
  static const accessTokenKey = 'access_token';
  static const refreshTokenKey = 'refresh_token';

  late final Dio dio;

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
