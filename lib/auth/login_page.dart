import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../home/admin_home_page.dart';
import '../home/user_home_page.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';
import 'services/auth_service.dart';
import 'widgets/auth_button.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/auth_switch_text.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/auth_title.dart';
import 'widgets/illustrations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    var didNavigate = false;

    try {
      final user = await AuthService.instance.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      final destination = user.isAdmin
          ? AdminHomePage(user: user)
          : UserHomePage(user: user);

      didNavigate = true;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => destination));
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
      illustration: const MoonIllustration(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthTitle('Đăng Nhập'),
            const SizedBox(height: 32),
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
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordPage(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
                child: const Text('Quên mật khẩu?'),
              ),
            ),
            AuthButton(
              text: _isLoading ? 'Đang đăng nhập...' : 'Đăng Nhập',
              onPressed: _isLoading ? () {} : _login,
            ),
            const SizedBox(height: 22),
            AuthSwitchText(
              text: 'Chưa có tài khoản?',
              actionText: 'Đăng ký ngay',
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const RegisterPage()));
              },
            ),
          ],
        ),
      ),
    );
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
    if ((value ?? '').isEmpty) {
      return 'Vui lòng nhập mật khẩu.';
    }
    return null;
  }
}
