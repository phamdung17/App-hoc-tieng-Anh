import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/app_api.dart';
import '../../../../core/theme/app_theme.dart';

class PasswordRecoveryPage extends StatefulWidget {
  const PasswordRecoveryPage({super.key, this.token});
  final String? token;
  @override
  State<PasswordRecoveryPage> createState() => _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends State<PasswordRecoveryPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _sent = false;
  bool get _resetMode => widget.token?.isNotEmpty == true;
  final _dio = AppApi.instance.dio;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await _dio.post(
        _resetMode ? '/auth/reset-password' : '/auth/forgot-password',
        data: _resetMode
            ? {'token': widget.token, 'password': _password.text}
            : {'email': _email.text.trim()},
      );
      if (mounted) setState(() => _sent = true);
    } on DioException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.response?.statusCode == 404
                  ? 'Máy chủ hiện chưa hỗ trợ chức năng đặt lại mật khẩu.'
                  : 'Không thể xử lý yêu cầu. Vui lòng thử lại.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: Text(_resetMode ? 'Đặt lại mật khẩu' : 'Quên mật khẩu'),
    ),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  _sent ? LucideIcons.mailCheck : LucideIcons.lockKeyhole,
                  size: 56,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  _sent
                      ? 'Đã gửi yêu cầu'
                      : (_resetMode
                            ? 'Tạo mật khẩu mới'
                            : 'Khôi phục tài khoản'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  _sent
                      ? 'Nếu tài khoản tồn tại, bạn sẽ nhận được hướng dẫn qua email.'
                      : (_resetMode
                            ? 'Nhập mật khẩu mới cho tài khoản của bạn.'
                            : 'Nhập email đăng ký để nhận hướng dẫn đặt lại mật khẩu.'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (!_sent && !_resetMode)
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(LucideIcons.mail),
                    ),
                    validator: (v) =>
                        (v == null ||
                            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(v.trim()))
                        ? 'Nhập email hợp lệ.'
                        : null,
                  ),
                if (!_sent && _resetMode) ...[
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu mới',
                      prefixIcon: Icon(LucideIcons.lockKeyhole),
                    ),
                    validator: (v) => (v == null || v.length < 8)
                        ? 'Mật khẩu cần ít nhất 8 ký tự.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirm,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nhập lại mật khẩu',
                    ),
                    validator: (v) => v != _password.text
                        ? 'Mật khẩu nhập lại chưa khớp.'
                        : null,
                  ),
                ],
                const SizedBox(height: 18),
                if (!_sent)
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const CircularProgressIndicator()
                        : Text(
                            _resetMode ? 'LƯU MẬT KHẨU MỚI' : 'GỬI HƯỚNG DẪN',
                          ),
                  ),
                TextButton(
                  onPressed: () => context.go('/auth'),
                  child: const Text('Quay lại đăng nhập'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
