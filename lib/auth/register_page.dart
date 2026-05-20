import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import 'services/auth_service.dart';
import 'widgets/auth_button.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/auth_switch_text.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/auth_title.dart';
import 'widgets/illustrations.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool agreed = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!agreed) {
      _showMessage('Bạn cần đồng ý với Điều khoản & Điều kiện.');
      return;
    }

    setState(() => _isLoading = true);
    var didNavigate = false;

    try {
      await AuthService.instance.register(
        fullName: _fullNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      _showMessage('Đăng ký thành công. Vui lòng đăng nhập.');
      didNavigate = true;
      Navigator.of(context).pop();
    } on AuthException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    } finally {
      if (mounted && !didNavigate) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      illustration: const RocketIllustration(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthTitle('Đăng Ký'),
            const SizedBox(height: 28),
            AuthTextField(
              controller: _fullNameController,
              icon: Icons.person,
              hintText: 'Họ và tên',
              validator: _validateFullName,
            ),
            const SizedBox(height: 12),
            AuthTextField(
              controller: _emailController,
              icon: Icons.email,
              hintText: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),
            const SizedBox(height: 12),
            AuthTextField(
              controller: _passwordController,
              icon: Icons.lock,
              hintText: 'Mật khẩu',
              obscureText: true,
              validator: _validatePassword,
            ),
            const SizedBox(height: 12),
            AuthTextField(
              controller: _confirmPasswordController,
              icon: Icons.lock,
              hintText: 'Xác nhận mật khẩu',
              obscureText: true,
              validator: _validateConfirmPassword,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                SizedBox(
                  width: 30,
                  height: 30,
                  child: Checkbox(
                    value: agreed,
                    activeColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.stroke, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (value) {
                      setState(() => agreed = value ?? false);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(text: 'Tôi đồng ý với '),
                        TextSpan(
                          text: 'Điều khoản & Điều kiện',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            AuthButton(
              text: _isLoading ? 'Đang đăng ký...' : 'Đăng Ký',
              onPressed: _isLoading ? () {} : _register,
            ),
            const SizedBox(height: 16),
            AuthSwitchText(
              text: 'Bạn đã có tài khoản?',
              actionText: 'Đăng nhập',
              onPressed: () {
                Navigator.of(context).maybePop();
              },
            ),
          ],
        ),
      ),
    );
  }

  String? _validateFullName(String? value) {
    if ((value?.trim() ?? '').length < 2) {
      return 'Vui lòng nhập họ và tên.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Vui lòng nhập email.';
    }
    if (!email.contains('@') || !email.contains('.')) {
      return 'Email không hợp lệ.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự.';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'Mật khẩu xác nhận không khớp.';
    }
    return null;
  }
}
