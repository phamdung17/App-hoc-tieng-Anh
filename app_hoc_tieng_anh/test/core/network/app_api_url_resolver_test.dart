// test/core/network/app_api_url_resolver_test.dart
//
// Verification of AppApi URL resolution and path normalization compliant with RFC 3986:
// 1. Adds /api/v1 prefix when missing (both with and without leading slash).
// 2. Prevents double-prefixing when /api/v1 is already present.
// 3. Preserves root system endpoints like /health.
// 4. Preserves absolute URLs without alteration.
// 5. Preserves query parameters and subpaths correctly.

import 'package:flutter_test/flutter_test.dart';
import 'package:app_hoc_tieng_anh/core/config/app_config.dart';
import 'package:app_hoc_tieng_anh/core/network/app_api.dart';

void main() {
  group('AppApi URL Resolver & Path Normalizer (RFC 3986 Compliance)', () {
    const defaultHost = 'http://10.0.2.2:8000';

    test('adds /api/v1 prefix to relative paths with leading slash', () {
      expect(AppApi.normalizePath('/auth/login'), equals('/api/v1/auth/login'));
      expect(AppApi.normalizePath('/learning/paths'), equals('/api/v1/learning/paths'));
      expect(AppApi.normalizePath('/vocab/daily'), equals('/api/v1/vocab/daily'));
    });

    test('adds /api/v1 prefix to relative paths without leading slash', () {
      expect(AppApi.normalizePath('auth/register'), equals('/api/v1/auth/register'));
      expect(AppApi.normalizePath('learning/paths'), equals('/api/v1/learning/paths'));
      expect(AppApi.normalizePath('progress/calendar'), equals('/api/v1/progress/calendar'));
    });

    test('does NOT duplicate /api/v1 when prefix is already present', () {
      expect(AppApi.normalizePath('/api/v1/learning/paths'), equals('/api/v1/learning/paths'));
      expect(AppApi.normalizePath('/api/v1/auth/me'), equals('/api/v1/auth/me'));
      expect(AppApi.normalizePath('/api/v1'), equals('/api/v1'));
      expect(AppApi.normalizePath('api/v1/learning/paths'), equals('/api/v1/learning/paths'));
    });

    test('preserves special root system endpoint /health', () {
      expect(AppApi.normalizePath('/health'), equals('/health'));
      expect(AppApi.normalizePath('health'), equals('/health'));
    });

    test('preserves absolute URLs (http and https)', () {
      expect(
        AppApi.normalizePath('https://api.lingoup.com/v2/oauth'),
        equals('https://api.lingoup.com/v2/oauth'),
      );
      expect(
        AppApi.normalizePath('http://localhost:9000/minio/health'),
        equals('http://localhost:9000/minio/health'),
      );
    });

    test('resolveUrl combines baseUrl and normalized paths with query params', () {
      final resolvedUrl = AppApi.resolveUrl(
        '/vocab?page=1&page_size=20',
        customBaseUrl: defaultHost,
      );
      expect(
        resolvedUrl,
        equals('http://10.0.2.2:8000/api/v1/vocab?page=1&page_size=20'),
      );

      final uri = Uri.parse(resolvedUrl);
      expect(uri.path, equals('/api/v1/vocab'));
      expect(uri.queryParameters['page'], equals('1'));
      expect(uri.queryParameters['page_size'], equals('20'));
    });

    test('resolveUrl cleans dirty base URLs with trailing slashes or /api/v1', () {
      final res1 = AppApi.resolveUrl('/learning/paths', customBaseUrl: 'http://10.0.2.2:8000/');
      expect(res1, equals('http://10.0.2.2:8000/api/v1/learning/paths'));

      final res2 = AppApi.resolveUrl('/learning/paths', customBaseUrl: 'http://10.0.2.2:8000/api/v1');
      expect(res2, equals('http://10.0.2.2:8000/api/v1/learning/paths'));

      final res3 = AppApi.resolveUrl('/learning/paths', customBaseUrl: 'http://10.0.2.2:8000/api/v1/');
      expect(res3, equals('http://10.0.2.2:8000/api/v1/learning/paths'));
    });
  });
}
