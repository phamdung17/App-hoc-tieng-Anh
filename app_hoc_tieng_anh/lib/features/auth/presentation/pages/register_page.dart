import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _termsController = ValueNotifier<bool>(false);
  final _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      sendTimeout: AppConfig.sendTimeout,
      headers: const {'Content-Type': 'application/json'},
    ),
  );

  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _termsController.dispose();
    _dio.close();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'display_name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        },
      );

      if (!mounted) return;
      context.go(AppRoutes.verifyEmail, extra: _emailController.text.trim());
    } on DioException catch (error) {
      if (!mounted) return;
      _showMessage(_messageForDioError(error));
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

    if (code == 'EMAIL_ALREADY_REGISTERED' || response?.statusCode == 409) {
      return 'Email này đã được đăng ký.';
    }
    if (response?.statusCode == 422) {
      return 'Thông tin chưa hợp lệ. Kiểm tra lại email và mật khẩu.';
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'Không kết nối được máy chủ. Hãy kiểm tra địa chỉ API và thử lại.';
    }
    return 'Không thể tạo tài khoản lúc này. Vui lòng thử lại.';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
    if (password.length < 8) return 'Mật khẩu cần có ít nhất 8 ký tự.';
    if (!RegExp(r'[A-Z]').hasMatch(password) ||
        !RegExp(r'[a-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password)) {
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
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBrand(),
                    const SizedBox(height: 8),
                    _buildModeSelector(),
                    const SizedBox(height: 8),
                    _buildHeading(),
                    const SizedBox(height: 8),
                    _buildForm(),
                    const SizedBox(height: 8),
                    _buildSubmitButton(),
                    const SizedBox(height: 8),
                    _buildDivider(),
                    const SizedBox(height: 8),
                    _buildSocialButtons(),
                    const SizedBox(height: 8),
                    _buildLoginPrompt(),
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
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border.all(color: AppColors.outline, width: 1.25),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _ModeTab(
            label: 'Đăng nhập',
            selected: false,
            onTap: () => context.go(AppRoutes.auth),
          ),
          _ModeTab(label: 'Đăng ký', selected: true, onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lưu trọn hành trình học',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 6),
        Text(
          'Tạo tài khoản để lưu tiến độ và học tiếp cùng LingoUp mỗi ngày.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
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
          _buildFieldLabel('Họ và tên'),
          const SizedBox(height: 4),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              hint: 'Nguyễn Minh Anh',
              icon: 'assets/images/auth/icon_user.svg',
            ),
            validator: (value) => (value?.trim().isEmpty ?? true)
                ? 'Vui lòng nhập họ và tên.'
                : null,
          ),
          const SizedBox(height: 8),
          _buildFieldLabel('Email'),
          const SizedBox(height: 4),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: _inputDecoration(
              hint: 'ban@vidu.com',
              icon: 'assets/images/auth/icon_register_mail.svg',
            ),
            validator: _validateEmail,
          ),
          const SizedBox(height: 8),
          _buildFieldLabel('Mật khẩu'),
          const SizedBox(height: 4),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            decoration: _inputDecoration(
              hint: 'Tối thiểu 8 ký tự',
              icon: 'assets/images/auth/icon_register_lock.svg',
              suffix: IconButton(
                tooltip: _obscurePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: const _AssetIcon(
                  'assets/images/auth/icon_register_eye.svg',
                ),
              ),
            ),
            validator: _validatePassword,
          ),
          const SizedBox(height: 8),
          _buildFieldLabel('Xác nhận mật khẩu'),
          const SizedBox(height: 4),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmation,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            decoration: _inputDecoration(
              hint: 'Nhập lại mật khẩu',
              icon: 'assets/images/auth/icon_shield_check.svg',
              suffix: IconButton(
                tooltip: _obscureConfirmation ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                onPressed: () => setState(
                  () => _obscureConfirmation = !_obscureConfirmation,
                ),
                icon: const _AssetIcon(
                  'assets/images/auth/icon_register_eye_confirm.svg',
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng xác nhận mật khẩu.';
              }
              if (value != _passwordController.text) {
                return 'Mật khẩu nhập lại chưa khớp.';
              }
              return null;
            },
          ),
          const SizedBox(height: 2),
          ValueListenableBuilder<bool>(
            valueListenable: _termsController,
            builder: (context, accepted, _) => FormField<bool>(
              initialValue: accepted,
              validator: (_) => _termsController.value
                  ? null
                  : 'Vui lòng đồng ý với điều khoản để tiếp tục.',
              builder: (field) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {
                      _termsController.value = !_termsController.value;
                      field.didChange(_termsController.value);
                    },
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 24,
                          child: Checkbox(
                            value: accepted,
                            onChanged: (value) {
                              _termsController.value = value ?? false;
                              field.didChange(_termsController.value);
                            },
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            side: const BorderSide(
                              color: AppColors.textSecondary,
                              width: 1,
                            ),
                            activeColor: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Tôi đồng ý với Điều khoản sử dụng và Chính sách bảo mật.',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (field.hasError)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        field.errorText!,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.error),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required String icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      prefixIcon: _AssetIcon(icon, color: AppColors.primaryDark),
      prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 44),
      suffixIcon: suffix,
      suffixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 44),
    );
  }

  Widget _buildFieldLabel(String label) => Text(
    label,
    style: Theme.of(context).textTheme.bodySmall
        ?.copyWith(fontSize: 12, height: 1.25, color: AppColors.textPrimary),
  );

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textPrimary,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('Đăng ký'),
                  SizedBox(width: 8),
                  _AssetIcon(
                    'assets/images/auth/icon_register_arrow.svg',
                    width: 19,
                    height: 19,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDivider() => Row(
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

  Widget _buildSocialButtons() => Column(
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
        onTap: () => _showMessage('Đăng nhập Google chưa được cấu hình.'),
      ),
      const SizedBox(height: 8),
      _SocialButton(
        label: 'Tiếp tục với Apple',
        icon: const _AssetIcon(
          'assets/images/auth/icon_register_apple.svg',
          width: 19,
          height: 19,
        ),
        onTap: () => _showMessage('Đăng nhập Apple chưa được cấu hình.'),
      ),
    ],
  );

  Widget _buildLoginPrompt() => Center(
    child: Wrap(
      alignment: WrapAlignment.center,
      children: [
        Text(
          'Đã có tài khoản? ',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        GestureDetector(
          onTap: () => context.go(AppRoutes.auth),
          child: Text(
            'Đăng nhập',
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
  Widget build(BuildContext context) => Expanded(
    child: Material(
      color: selected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    ),
  );
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
    'icon_user.svg' => LucideIcons.userRound,
    'icon_register_mail.svg' => LucideIcons.mail,
    'icon_register_lock.svg' => LucideIcons.lockKeyhole,
    'icon_register_eye.svg' ||
    'icon_register_eye_confirm.svg' => LucideIcons.eye,
    'icon_shield_check.svg' => LucideIcons.shieldCheck,
    'icon_register_arrow.svg' => LucideIcons.arrowRight,
    'icon_register_apple.svg' => LucideIcons.apple,
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
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 48,
    child: OutlinedButton.icon(
      onPressed: onTap,
      icon: icon,
      label: Text(label),
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
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
