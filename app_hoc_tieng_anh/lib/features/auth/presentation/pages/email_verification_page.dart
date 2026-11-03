import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/router.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/app_api.dart';
import '../../../../core/theme/app_theme.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key, this.email, this.token});

  final String? email;
  final String? token;

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _dio = AppApi.instance.dio;

  bool _isBusy = false;
  bool _isVerified = false;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email ?? '');
    final token = widget.token?.trim();
    if (token != null && token.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _verifyToken(token));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _verifyToken(String token) async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
      _infoMessage = null;
    });
    try {
      await _dio.post<void>('/auth/verify-email', data: {'token': token});
      if (!mounted) return;
      setState(() => _isVerified = true);
    } on DioException catch (error) {
      if (!mounted) return;
      final status = error.response?.statusCode;
      if (status == 409) {
        setState(() => _isVerified = true);
      } else {
        setState(() {
          _errorMessage = status == 400
              ? 'Liên kết xác minh không hợp lệ hoặc đã hết hạn. Hãy yêu cầu gửi lại email.'
              : 'Chưa thể xác minh email. Kiểm tra kết nối rồi thử lại.';
        });
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _resendEmail() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isBusy = true;
      _errorMessage = null;
      _infoMessage = null;
    });
    try {
      await _dio.post<void>(
        '/auth/resend-verify',
        data: {'email': _emailController.text.trim()},
      );
      if (!mounted) return;
      setState(() {
        _infoMessage = 'Yêu cầu đã được tiếp nhận. Nếu email này có tài khoản chưa xác minh, hệ thống sẽ gửi hướng dẫn xác minh.';
      });
    } on DioException catch (error) {
      if (!mounted) return;
      final status = error.response?.statusCode;
      setState(() {
        _errorMessage = status == 429
            ? 'Bạn vừa yêu cầu gửi lại email. Hãy đợi một chút rồi thử lại.'
            : 'Không gửi được yêu cầu lúc này. Vui lòng thử lại.';
      });
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Nhập email để gửi lại hướng dẫn.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Email chưa đúng định dạng.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final verified = _isVerified;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          tooltip: 'Quay lại',
          onPressed: () => context.go(AppRoutes.auth),
          icon: const Icon(LucideIcons.arrowLeft),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  _StatusIllustration(verified: verified, isBusy: _isBusy),
                  const SizedBox(height: 28),
                  Text(
                    verified ? 'Email đã xác minh!' : 'Xác minh email của bạn',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    verified
                        ? 'Tài khoản đã sẵn sàng. Đăng nhập để tiếp tục hành trình học cùng LingoUp.'
                        : 'Mở liên kết xác minh trong email để hoàn tất tạo tài khoản.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (!verified) ...[
                    const SizedBox(height: 28),
                    _emailCard(),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 14),
                      _MessageBanner(message: _errorMessage!, isError: true),
                    ],
                    if (_infoMessage != null) ...[
                      const SizedBox(height: 14),
                      _MessageBanner(message: _infoMessage!, isError: false),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _isBusy ? null : _resendEmail,
                        icon: _isBusy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(LucideIcons.refreshCw, size: 19),
                        label: Text(
                          _isBusy ? 'Đang xử lý...' : 'Gửi lại email xác minh',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Bạn chưa nhận được email? Hãy kiểm tra thư mục spam hoặc gửi lại yêu cầu.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppRadii.card),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            LucideIcons.circleCheck,
                            color: AppColors.primaryDark,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Email của bạn đã được xác minh an toàn.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 52,
                    child: verified
                        ? ElevatedButton(
                            onPressed: () => context.go(AppRoutes.auth),
                            child: const Text('Đến đăng nhập'),
                          )
                        : OutlinedButton(
                            onPressed: () => context.go(AppRoutes.auth),
                            child: const Text('Quay lại đăng nhập'),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emailCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.divider),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Địa chỉ email',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              onFieldSubmitted: (_) => _resendEmail(),
              decoration: const InputDecoration(
                prefixIcon: Icon(LucideIcons.mail, size: 20),
                hintText: 'ban@vidu.com',
              ),
              validator: _validateEmail,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusIllustration extends StatelessWidget {
  const _StatusIllustration({required this.verified, required this.isBusy});
  final bool verified;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final color = verified ? AppColors.primary : AppColors.coral;
    return Center(
      child: Container(
        width: 112,
        height: 112,
        decoration: BoxDecoration(
          color: verified ? AppColors.primaryLight : const Color(0xFFFFE5DC),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.outline, width: 1.5),
          boxShadow: const [
            BoxShadow(color: AppColors.outline, offset: Offset(3, 3)),
          ],
        ),
        child: Center(
          child: isBusy
              ? const SizedBox.square(
                  dimension: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.primaryDark,
                  ),
                )
              : Icon(
                  verified ? LucideIcons.mailCheck : LucideIcons.mail,
                  size: 50,
                  color: color,
                ),
        ),
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.message, required this.isError});
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.error : AppColors.primaryDark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? LucideIcons.circleAlert : LucideIcons.circleCheck,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, height: 1.4, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
