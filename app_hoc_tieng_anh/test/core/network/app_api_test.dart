import 'package:flutter_test/flutter_test.dart';
import 'package:app_hoc_tieng_anh/core/config/app_config.dart';
import 'package:app_hoc_tieng_anh/core/network/app_api.dart';

void main() {
  group('AppConfig URL Cleaning Tests', () {
    test('cleanBaseUrl removes trailing slash', () {
      expect(AppConfig.cleanBaseUrl('http://10.0.2.2:8000/'), 'http://10.0.2.2:8000');
      expect(AppConfig.cleanBaseUrl('http://10.0.2.2:8000///'), 'http://10.0.2.2:8000');
    });

    test('cleanBaseUrl removes trailing /api/v1', () {
      expect(AppConfig.cleanBaseUrl('http://10.0.2.2:8000/api/v1'), 'http://10.0.2.2:8000');
      expect(AppConfig.cleanBaseUrl('http://10.0.2.2:8000/api/v1/'), 'http://10.0.2.2:8000');
    });

    test('cleanBaseUrl preserves clean host root', () {
      expect(AppConfig.cleanBaseUrl('http://10.0.2.2:8000'), 'http://10.0.2.2:8000');
      expect(AppConfig.cleanBaseUrl('https://api.lingoup.com'), 'https://api.lingoup.com');
    });

    test('baseUrl default is host root', () {
      expect(AppConfig.baseUrl, 'http://10.0.2.2:8000');
    });
  });

  group('AppApi URL Resolver & Path Normalizer Tests', () {
    test('normalizes relative path with leading slash', () {
      expect(AppApi.normalizePath('/auth/login'), '/api/v1/auth/login');
      expect(AppApi.normalizePath('/learning/paths'), '/api/v1/learning/paths');
    });

    test('normalizes path without leading slash', () {
      expect(AppApi.normalizePath('auth/login'), '/api/v1/auth/login');
      expect(AppApi.normalizePath('learning/paths'), '/api/v1/learning/paths');
    });

    test('preserves existing /api/v1 without duplication', () {
      expect(AppApi.normalizePath('/api/v1/learning/paths'), '/api/v1/learning/paths');
      expect(AppApi.normalizePath('/api/v1'), '/api/v1');
    });

    test('preserves /health endpoint at root', () {
      expect(AppApi.normalizePath('/health'), '/health');
      expect(AppApi.normalizePath('health'), '/health');
    });

    test('preserves absolute URLs', () {
      expect(AppApi.normalizePath('https://example.com/oauth'), 'https://example.com/oauth');
      expect(AppApi.normalizePath('http://localhost:9000/custom'), 'http://localhost:9000/custom');
    });

    test('resolveUrl combines clean base and normalized path', () {
      expect(
        AppApi.resolveUrl('/auth/login', customBaseUrl: 'http://10.0.2.2:8000/api/v1/'),
        'http://10.0.2.2:8000/api/v1/auth/login',
      );
      expect(
        AppApi.resolveUrl('https://example.com/data'),
        'https://example.com/data',
      );
    });
  });
}
