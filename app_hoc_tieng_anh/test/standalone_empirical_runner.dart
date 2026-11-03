// Standalone empirical test runner for AppApi and Learning logic

class AppConfig {
  static const String apiV1Prefix = '/api/v1';

  static String cleanBaseUrl(String url) {
    var cleaned = url.trim();
    while (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    if (cleaned.endsWith('/api/v1')) {
      cleaned = cleaned.substring(0, cleaned.length - '/api/v1'.length);
    }
    while (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    return cleaned;
  }
}

class AppApi {
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

  static String resolveUrl(String path, {String? customBaseUrl}) {
    final base = AppConfig.cleanBaseUrl(customBaseUrl ?? 'http://10.0.2.2:8000');
    final normPath = normalizePath(path);
    if (normPath.startsWith('http://') || normPath.startsWith('https://')) {
      return normPath;
    }
    return '$base$normPath';
  }
}

void assertTrue(bool condition, String message) {
  if (!condition) {
    throw Exception('FAILED: $message');
  }
}

void assertEquals(dynamic actual, dynamic expected, String message) {
  if (actual != expected) {
    throw Exception('FAILED: $message - Expected: "$expected", Got: "$actual"');
  }
}

void main() {
  print('=== STARTING EMPIRICAL CHALLENGE TESTS ===');

  // Test 1: Standard relative path with leading slash
  assertEquals(AppApi.normalizePath('/auth/login'), '/api/v1/auth/login', 'T1: /auth/login normalization');
  assertEquals(AppApi.resolveUrl('/auth/login'), 'http://10.0.2.2:8000/api/v1/auth/login', 'T1: /auth/login resolve');

  // Test 2: Relative path without leading slash
  assertEquals(AppApi.normalizePath('auth/login'), '/api/v1/auth/login', 'T2: auth/login normalization');
  assertEquals(AppApi.resolveUrl('auth/login'), 'http://10.0.2.2:8000/api/v1/auth/login', 'T2: auth/login resolve');

  // Test 3: Already prefixed with /api/v1
  assertEquals(AppApi.normalizePath('/api/v1/auth/login'), '/api/v1/auth/login', 'T3: /api/v1/auth/login normalization');
  assertEquals(AppApi.resolveUrl('/api/v1/auth/login'), 'http://10.0.2.2:8000/api/v1/auth/login', 'T3: /api/v1/auth/login resolve');

  // Test 4: Already prefixed without leading slash
  assertEquals(AppApi.normalizePath('api/v1/auth/login'), '/api/v1/auth/login', 'T4: api/v1/auth/login normalization');
  assertEquals(AppApi.resolveUrl('api/v1/auth/login'), 'http://10.0.2.2:8000/api/v1/auth/login', 'T4: api/v1/auth/login resolve');

  // Test 5: External URLs
  assertEquals(AppApi.normalizePath('http://external.com'), 'http://external.com', 'T5: external http');
  assertEquals(AppApi.normalizePath('https://external.com/api/test'), 'https://external.com/api/test', 'T5: external https');
  assertEquals(AppApi.resolveUrl('http://external.com'), 'http://external.com', 'T5: external http resolve');

  // Test 6: Edge case ///auth
  final normSlash = AppApi.normalizePath('///auth');
  assertTrue(normSlash.startsWith('/api/v1'), 'T6: ///auth starts with /api/v1');
  assertEquals(AppApi.resolveUrl('///auth'), 'http://10.0.2.2:8000/api/v1///auth', 'T6: ///auth resolve');

  // Test 7: Query strings
  assertEquals(
    AppApi.normalizePath('/auth/login?redirect=%2Fdashboard&ref=promo_2026'),
    '/api/v1/auth/login?redirect=%2Fdashboard&ref=promo_2026',
    'T7: query string preserved',
  );
  assertEquals(
    AppApi.resolveUrl('/vocab/daily?category=business&level=b2'),
    'http://10.0.2.2:8000/api/v1/vocab/daily?category=business&level=b2',
    'T7: query string resolveUrl',
  );

  // Test 8: Dirty base URL combinations
  final dirtyBases = [
    'http://10.0.2.2:8000/',
    'http://10.0.2.2:8000///',
    'http://10.0.2.2:8000/api/v1',
    'http://10.0.2.2:8000/api/v1/',
    'http://10.0.2.2:8000/api/v1///',
  ];
  for (final b in dirtyBases) {
    assertEquals(AppApi.resolveUrl('/auth/login', customBaseUrl: b), 'http://10.0.2.2:8000/api/v1/auth/login', 'T8: dirtyBase: $b');
  }

  // Test 9: /health preserved
  assertEquals(AppApi.normalizePath('/health'), '/health', 'T9: /health');
  assertEquals(AppApi.normalizePath('health'), '/health', 'T9: health');
  assertEquals(AppApi.resolveUrl('/health'), 'http://10.0.2.2:8000/health', 'T9: /health resolve');

  // Test 10: Learning UUID regex test
  final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
  assertTrue(uuidRegex.hasMatch('550e8400-e29b-41d4-a716-446655440000'), 'T10: valid UUID');
  assertTrue(!uuidRegex.hasMatch('unit1_lesson1'), 'T10: mock id unit1_lesson1');
  assertTrue(!uuidRegex.hasMatch(''), 'T10: empty id');

  print('=== ALL 10 EMPIRICAL CHALLENGE TESTS PASSED SUCCESSFULLY! ===');
}
