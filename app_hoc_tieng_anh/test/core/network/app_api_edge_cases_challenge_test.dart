// test/core/network/app_api_edge_cases_challenge_test.dart
//
// Empirical Challenger: Stress-testing AppApi URL resolution and path normalization.
// Edge cases tested:
// - /api/v1/auth/login
// - auth/login
// - /auth/login
// - http://external.com & https://external.com
// - ///auth (multiple leading slashes)
// - Query strings (?redirect=/dashboard&key=val)
// - Ensuring leading slashes don't cause 404s and /api/v1 is never duplicated

import 'package:flutter_test/flutter_test.dart';
import 'package:app_hoc_tieng_anh/core/config/app_config.dart';
import 'package:app_hoc_tieng_anh/core/network/app_api.dart';

void main() {
  group('AppApi URL Resolution Empirical Challenge', () {
    const defaultHost = 'http://10.0.2.2:8000';

    test('Case 1: Standard relative path with leading slash /auth/login', () {
      final normalized = AppApi.normalizePath('/auth/login');
      expect(normalized, equals('/api/v1/auth/login'));
      final resolved = AppApi.resolveUrl('/auth/login', customBaseUrl: defaultHost);
      expect(resolved, equals('http://10.0.2.2:8000/api/v1/auth/login'));
      expect(resolved.contains('/api/v1/api/v1'), isFalse);
    });

    test('Case 2: Relative path without leading slash auth/login', () {
      final normalized = AppApi.normalizePath('auth/login');
      expect(normalized, equals('/api/v1/auth/login'));
      final resolved = AppApi.resolveUrl('auth/login', customBaseUrl: defaultHost);
      expect(resolved, equals('http://10.0.2.2:8000/api/v1/auth/login'));
    });

    test('Case 3: Already prefixed path /api/v1/auth/login is never duplicated', () {
      final normalized = AppApi.normalizePath('/api/v1/auth/login');
      expect(normalized, equals('/api/v1/auth/login'));
      final resolved = AppApi.resolveUrl('/api/v1/auth/login', customBaseUrl: defaultHost);
      expect(resolved, equals('http://10.0.2.2:8000/api/v1/auth/login'));
      expect(resolved.contains('/api/v1/api/v1'), isFalse);
    });

    test('Case 4: Already prefixed without leading slash api/v1/auth/login', () {
      final normalized = AppApi.normalizePath('api/v1/auth/login');
      expect(normalized, equals('/api/v1/auth/login'));
      final resolved = AppApi.resolveUrl('api/v1/auth/login', customBaseUrl: defaultHost);
      expect(resolved, equals('http://10.0.2.2:8000/api/v1/auth/login'));
    });

    test('Case 5: Absolute HTTP and HTTPS external URLs remain untouched', () {
      expect(AppApi.normalizePath('http://external.com'), equals('http://external.com'));
      expect(AppApi.normalizePath('http://external.com/api/test'), equals('http://external.com/api/test'));
      expect(AppApi.normalizePath('https://external.com/v2/items?page=1'), equals('https://external.com/v2/items?page=1'));

      final resolvedHttp = AppApi.resolveUrl('http://external.com', customBaseUrl: defaultHost);
      expect(resolvedHttp, equals('http://external.com'));

      final resolvedHttps = AppApi.resolveUrl('https://external.com/data', customBaseUrl: defaultHost);
      expect(resolvedHttps, equals('https://external.com/data'));
    });

    test('Case 6: Leading slashes edge case ///auth', () {
      final normalized = AppApi.normalizePath('///auth');
      // Normalize should prepend /api/v1 and not crash
      expect(normalized.startsWith('/api/v1'), isTrue);
      final resolved = AppApi.resolveUrl('///auth', customBaseUrl: defaultHost);
      expect(resolved.startsWith('http://10.0.2.2:8000/api/v1'), isTrue);
    });

    test('Case 7: Query strings preservation with various path structures', () {
      final q1 = AppApi.normalizePath('/auth/login?redirect=%2Fdashboard&ref=promo_2026');
      expect(q1, equals('/api/v1/auth/login?redirect=%2Fdashboard&ref=promo_2026'));

      final q2 = AppApi.normalizePath('learning/lessons/42?include_exercises=true&limit=10');
      expect(q2, equals('/api/v1/learning/lessons/42?include_exercises=true&limit=10'));

      final q3 = AppApi.normalizePath('/api/v1/vocab/search?q=hello&lang=en');
      expect(q3, equals('/api/v1/vocab/search?q=hello&lang=en'));

      final resolvedQ = AppApi.resolveUrl(
        '/vocab/daily?category=business&level=b2',
        customBaseUrl: defaultHost,
      );
      expect(
        resolvedQ,
        equals('http://10.0.2.2:8000/api/v1/vocab/daily?category=business&level=b2'),
      );
      final uri = Uri.parse(resolvedQ);
      expect(uri.queryParameters['category'], equals('business'));
      expect(uri.queryParameters['level'], equals('b2'));
    });

    test('Case 8: Dirty base URL combinations do not create double /api/v1', () {
      final dirtyBases = [
        'http://10.0.2.2:8000/',
        'http://10.0.2.2:8000///',
        'http://10.0.2.2:8000/api/v1',
        'http://10.0.2.2:8000/api/v1/',
        'http://10.0.2.2:8000/api/v1///',
      ];

      for (final dirtyBase in dirtyBases) {
        final res = AppApi.resolveUrl('/auth/login', customBaseUrl: dirtyBase);
        expect(res, equals('http://10.0.2.2:8000/api/v1/auth/login'),
            reason: 'Failed for dirtyBase: $dirtyBase');
      }
    });

    test('Case 9: Preserves special endpoints like /health without /api/v1 injection', () {
      expect(AppApi.normalizePath('/health'), equals('/health'));
      expect(AppApi.normalizePath('health'), equals('/health'));
      expect(AppApi.resolveUrl('/health', customBaseUrl: defaultHost),
          equals('http://10.0.2.2:8000/health'));
    });
  });
}
