import 'package:google_sign_in/google_sign_in.dart';

import '../network/app_api.dart';

/// Dịch vụ đăng nhập qua Google OAuth2.
///
/// Luồng:
///   1. Google Sign-In → lấy idToken.
///   2. Gửi idToken lên backend POST /auth/social/google.
///   3. Backend xác minh với Google, trả access + refresh token.
///   4. Lưu token vào secure storage qua [AppApi].
///
/// Để sử dụng trên Android, cần thêm SHA-1 fingerprint trong Firebase Console
/// và đặt file google-services.json vào android/app/.
/// Trên iOS, cần thêm URL scheme REVERSED_CLIENT_ID vào Info.plist.
class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleAuthService instance = GoogleAuthService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Thực hiện luồng đăng nhập Google và lưu token vào ứng dụng.
  ///
  /// Ném [GoogleAuthException] nếu thất bại.
  Future<void> signIn() async {
    // 1. Mở cửa sổ chọn tài khoản Google
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw const GoogleAuthException('Người dùng đã hủy đăng nhập Google.');
    }

    // 2. Lấy token xác thực
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      throw const GoogleAuthException(
        'Không lấy được idToken từ Google. Kiểm tra cấu hình OAuth.',
      );
    }

    // 3. Gửi idToken lên FastAPI backend
    final response = await AppApi.instance.dio.post<Map<String, dynamic>>(
      '/auth/social/google',
      data: {'id_token': idToken},
    );

    // 4. Lưu access + refresh token
    final tokens = response.data?['tokens'] as Map<String, dynamic>?;
    if (tokens == null) {
      throw const GoogleAuthException('Phản hồi backend không hợp lệ.');
    }
    await AppApi.instance.saveTokens(tokens);
  }

  /// Đăng xuất khỏi phiên Google trên thiết bị.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}

/// Lỗi trong luồng đăng nhập Google.
class GoogleAuthException implements Exception {
  final String message;
  const GoogleAuthException(this.message);

  @override
  String toString() => 'GoogleAuthException: $message';
}

