import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/auth/google_auth_service.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/app_api.dart';
import '../../../../core/theme/app_theme.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  static const _secureStorage = FlutterSecureStorage();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dio = AppApi.instance.dio;

  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _setMode(bool isLogin) {
    if (_isLogin == isLogin) return;
    setState(() {
      _isLogin = isLogin;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _isLogin ? '/auth/login' : '/auth/register',
        data: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          if (!_isLogin) 'display_name': _nameController.text.trim(),
        },
      );

      final tokens = response.data?['tokens'] as Map<String, dynamic>?;
      final accessToken = tokens?['access_token'] as String?;
      final refreshToken = tokens?['refresh_token'] as String?;
      if (accessToken == null || refreshToken == null) {
        throw const FormatException('Phản hồi đăng nhập không hợp lệ.');
      }

      if (!mounted) return;

      await _secureStorage.write(key: 'access_token', value: accessToken);
      await _secureStorage.write(key: 'refresh_token', value: refreshToken);
      if (!mounted) return;
      await ref.read(authNotifierProvider.notifier).signIn();
      if (!mounted) return;
      context.go(AppRoutes.learning);
    } on DioException catch (error) {
      if (!mounted) return;
      _showMessage(_messageForDioError(error));
    } on FormatException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Không thể hoàn tất thao tác. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _messageForDioError(DioException error) {
    final response = error.response;
    final detail = response?.data is Map<String, dynamic>
        ? (response!.data as Map<String, dynamic>)['detail']
        : null;
    final code = detail is Map<String, dynamic> ? detail['code'] : null;

    if (code == 'INVALID_CREDENTIALS' || response?.statusCode == 401) {
      return 'Email hoặc mật khẩu chưa chính xác.';
    }
    if (code == 'EMAIL_ALREADY_REGISTERED' || response?.statusCode == 409) {
      return 'Email này đã được đăng ký.';
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'Không kết nối được máy chủ. Hãy kiểm tra địa chỉ API và thử lại.';
    }
    return 'Máy chủ đang bận. Vui lòng thử lại sau.';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openForgotPasswordDialog() async {
    final controller = TextEditingController(
      text: _emailController.text.trim(),
    );
    final formKey = GlobalKey<FormState>();
    final shouldSend = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.textPrimary.withValues(alpha: 0.5),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: 342,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border.all(color: AppColors.outline, width: 1.5),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: AppColors.outline, offset: Offset(3, 3)),
            ],
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        border: Border.all(
                          color: AppColors.outline,
                          width: 1.25,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        LucideIcons.mail,
                        size: 20,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      tooltip: 'Đóng',
                      constraints: const BoxConstraints.tightFor(
                        width: 32,
                        height: 32,
                      ),
                      padding: EdgeInsets.zero,
                      icon: const Icon(LucideIcons.x, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Quên mật khẩu?',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontSize: 23, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nhập email đã đăng ký. LingoUp sẽ gửi liên kết để bạn đặt lại mật khẩu.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 14),
                _buildFieldLabel('Email'),
                const SizedBox(height: 7),
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    hintText: 'ban@vidu.com',
                    prefixIcon: _AssetIcon('assets/images/auth/icon_mail.svg'),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.of(dialogContext).pop(true);
                      }
                    },
                    child: const Text('Gửi liên kết đặt lại'),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      minimumSize: const Size(0, 32),
                    ),
                    child: const Text('Hủy'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    controller.dispose();

    if (!mounted || shouldSend != true) return;
    _showMessage(
      'Chức năng gửi liên kết đặt lại mật khẩu chưa có API trên máy chủ.',
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Vui lòng nhập email.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Email chưa đúng định dạng.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Vui lòng nhập mật khẩu.';
    if (!_isLogin && password.length < 8) {
      return 'Mật khẩu cần có ít nhất 8 ký tự.';
    }
    if (!_isLogin &&
        (!RegExp(r'[A-Z]').hasMatch(password) ||
            !RegExp(r'[a-z]').hasMatch(password) ||
            !RegExp(r'\d').hasMatch(password))) {
      return 'Cần có chữ hoa, chữ thường và chữ số.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.background,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 36,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBrand(),
                    const SizedBox(height: 10),
                    _buildModeSelector(),
                    const SizedBox(height: 10),
                    _buildIllustration(),
                    const SizedBox(height: 10),
                    _buildGreeting(),
                    const SizedBox(height: 10),
                    _buildForm(),
                    const SizedBox(height: 12),
                    _buildSubmitButton(),
                    const SizedBox(height: 10),
                    _buildDivider(),
                    const SizedBox(height: 10),
                    _buildSocialButtons(),
                    const SizedBox(height: 10),
                    _buildSignUpPrompt(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrand() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary,
            border: Border.all(color: AppColors.outline, width: 1.5),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: AppColors.outline, offset: Offset(3, 3)),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            'L',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: AppColors.textPrimary,
            ),
            children: const [
              TextSpan(text: 'Lingo'),
              TextSpan(
                text: 'Up',
                style: TextStyle(color: AppColors.coral),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelector() {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border.all(color: AppColors.outline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _ModeTab(
            label: 'Đăng nhập',
            selected: _isLogin,
            onTap: () => _setMode(true),
          ),
          _ModeTab(
            label: 'Đăng ký',
            selected: !_isLogin,
            onTap: () => context.go(AppRoutes.register),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration() {
    return Container(
      height: 80,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border.all(color: AppColors.outline, width: 1.5),
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: const [
          BoxShadow(color: AppColors.outline, offset: Offset(3, 3)),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/auth/login_illustration.png',
            fit: BoxFit.cover,
          ),
          Positioned(
            left: 16,
            top: 16,
            child: SvgPicture.asset(
              'assets/images/auth/decoration_dot_1.svg',
              width: 10,
              height: 10,
              excludeFromSemantics: true,
            ),
          ),
          Positioned(
            right: 20,
            bottom: 12,
            child: SvgPicture.asset(
              'assets/images/auth/decoration_dot_2.svg',
              width: 8,
              height: 8,
              excludeFromSemantics: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isLogin ? 'Lưu trọn hành trình học' : 'Bắt đầu hành trình học',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 6),
        Text(
          _isLogin
              ? 'Đăng nhập để lưu tiến độ và tiếp tục hành trình cùng LingoUp nhé.'
              : 'Tạo tài khoản để lưu tiến độ và học cùng LingoUp nhé.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isLogin) ...[
            _buildFieldLabel('Tên hiển thị'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'Tên của bạn'),
              validator: (value) =>
                  (value?.trim().isEmpty ?? true) ? 'Vui lòng nhập tên.' : null,
            ),
            const SizedBox(height: 12),
          ],
          _buildFieldLabel('Email'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              hintText: 'ban@vidu.com',
              prefixIcon: _AssetIcon('assets/images/auth/icon_mail.svg'),
            ),
            validator: _validateEmail,
          ),
          const SizedBox(height: 12),
          _buildFieldLabel('Mật khẩu'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: _isLogin
                ? const [AutofillHints.password]
                : const [AutofillHints.newPassword],
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'Nhập mật khẩu',
              prefixIcon: const _AssetIcon('assets/images/auth/icon_lock.svg'),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: _AssetIcon(
                  'assets/images/auth/icon_eye.svg',
                  color: _obscurePassword
                      ? AppColors.textSecondary
                      : AppColors.primaryDark,
                ),
              ),
            ),
            validator: _validatePassword,
          ),
          if (_isLogin)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push(AppRoutes.forgotPassword),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Quên mật khẩu?'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) => Text(
    label,
    style: Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: AppColors.textPrimary, height: 1.2),
  );

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textPrimary,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_isLogin ? 'Đăng nhập' : 'Tạo tài khoản'),
                  const SizedBox(width: 8),
                  const _AssetIcon(
                    'assets/images/auth/icon_arrow_right.svg',
                    width: 19,
                    height: 19,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'hoặc tiếp tục với',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isSubmitting = true);
    try {
      await GoogleAuthService.instance.signIn();
      if (!mounted) return;
      await ref.read(authNotifierProvider.notifier).signIn();
      if (!mounted) return;
      context.go(AppRoutes.learning);
    } on GoogleAuthException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Đăng nhập Google thất bại. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildSocialButtons() {
    return Column(
      children: [
        _SocialButton(
          label: 'Tiếp tục với Google',
          icon: const Text(
            'G',
            style: TextStyle(
              color: Color(0xFF4285F4),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          onTap: _isSubmitting ? () {} : _signInWithGoogle,
        ),
        const SizedBox(height: 8),
        _SocialButton(
          label: 'Tiếp tục với Apple',
          icon: const _AssetIcon(
            'assets/images/auth/icon_apple.svg',
            width: 19,
            height: 19,
          ),
          onTap: () => _showMessage('Đăng nhập Apple chưa được cấu hình.'),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton.icon(
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signInAsGuest();
              if (mounted) context.go(AppRoutes.learning);
            },
            icon: const Icon(LucideIcons.rocket, color: AppColors.primaryDark),
            label: const Text(
              'Trải nghiệm ngay (Chế độ Khách)',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpPrompt() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          Text(
            _isLogin ? 'Chưa có tài khoản? ' : 'Đã có tài khoản? ',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          GestureDetector(
            onTap: () =>
                context.go(_isLogin ? AppRoutes.register : AppRoutes.auth),
            child: Text(
              _isLogin ? 'Đăng ký ngay' : 'Đăng nhập',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

class _AssetIcon extends StatelessWidget {
  const _AssetIcon(this.asset, {this.width = 19, this.height = 19, this.color});

  final String asset;
  final double width;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      Icon(_icon, size: width, color: color ?? AppColors.primaryDark);

  IconData get _icon => switch (asset.split('/').last) {
    'icon_mail.svg' || 'icon_register_mail.svg' => LucideIcons.mail,
    'icon_lock.svg' => LucideIcons.lockKeyhole,
    'icon_eye.svg' => LucideIcons.eye,
    'icon_arrow_right.svg' => LucideIcons.arrowRight,
    'icon_apple.svg' || 'icon_register_apple.svg' => LucideIcons.apple,
    _ => LucideIcons.circleHelp,
  };
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: icon,
        label: Text(label),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.outline, width: 1.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
          textStyle: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
