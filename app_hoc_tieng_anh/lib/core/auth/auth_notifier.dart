// lib/core/auth/auth_notifier.dart
//
// Quản lý trạng thái xác thực toàn cục bằng Riverpod.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Trạng thái xác thực của user.
enum AuthState {
  unknown,         // chưa kiểm tra (đang load)
  authenticated,   // đã đăng nhập tài khoản thật
  guest,           // đang dùng thử ở chế độ khách
  unauthenticated, // chưa đăng nhập
}

class AuthNotifier extends Notifier<AuthState> {
  static const _storage = FlutterSecureStorage();

  @override
  AuthState build() {
    // Kiểm tra token ngay khi provider được khởi tạo.
    _checkAuth();
    return AuthState.unknown;
  }

  Future<void> _checkAuth() async {
    final token = await _storage.read(key: 'access_token');
    if (token != null && token.isNotEmpty) {
      state = AuthState.authenticated;
      return;
    }
    final isGuest = await _storage.read(key: 'is_guest');
    if (isGuest == 'true') {
      state = AuthState.guest;
      return;
    }
    state = AuthState.unauthenticated;
  }

  /// Gọi sau khi đăng nhập thành công để cập nhật trạng thái.
  Future<void> signIn() async {
    await _storage.delete(key: 'is_guest');
    state = AuthState.authenticated;
  }

  /// Kích hoạt chế độ khách (Guest mode).
  Future<void> signInAsGuest() async {
    await _storage.write(key: 'is_guest', value: 'true');
    state = AuthState.guest;
  }

  /// Xóa token và chuyển trạng thái về unauthenticated.
  Future<void> signOut() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'is_guest');
    state = AuthState.unauthenticated;
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

// ── RouterRefreshNotifier ────────────────────────────────────────────────────
//
// Cầu nối giữa Riverpod (AuthNotifier) và GoRouter (refreshListenable).
// GoRouter lắng nghe ChangeNotifier này để kích hoạt lại redirect mỗi khi
// AuthState thay đổi.

class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(this._ref) {
    // Theo dõi authNotifierProvider và notify GoRouter khi state đổi.
    _ref.listen<AuthState>(
      authNotifierProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref _ref;
}
