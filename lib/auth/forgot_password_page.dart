import 'package:flutter/material.dart';

import 'services/auth_service.dart';
import 'widgets/auth_button.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/auth_title.dart';
import 'widgets/illustrations.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _otpSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final otp = await AuthService.instance.sendResetOtp(
        _emailController.text,
      );
      if (!mounted) {
        return;
      }

      setState(() => _otpSent = true);
      _showMessage(
        'Mã OTP demo của bạn là $otp. Khi nối backend email, mã này sẽ được gửi vào email.',
      );
    } on AuthException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    var didNavigate = false;

    try {
      await AuthService.instance.resetPassword(
        email: _emailController.text,
        otp: _otpController.text,
        newPassword: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      _showMessage('Đổi mật khẩu thành công. Bạn có thể đăng nhập lại.');
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
      illustration: const MoonIllustration(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthTitle('Quên Mật Khẩu'),
            const SizedBox(height: 28),
            AuthTextField(
              controller: _emailController,
              icon: Icons.email,
              hintText: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),
            if (_otpSent) ...[
              const SizedBox(height: 12),
              AuthTextField(
                controller: _otpController,
                icon: Icons.verified,
                hintText: 'Mã OTP',
                keyboardType: TextInputType.number,
                validator: _validateOtp,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _passwordController,
                icon: Icons.lock,
                hintText: 'Mật khẩu mới',
                obscureText: true,
                validator: _validatePassword,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _confirmPasswordController,
                icon: Icons.lock,
                hintText: 'Xác nhận mật khẩu mới',
                obscureText: true,
                validator: _validateConfirmPassword,
              ),
            ],
            const SizedBox(height: 22),
            AuthButton(
              text: _isLoading
                  ? 'Đang xử lý...'
                  : (_otpSent ? 'Đặt Lại Mật Khẩu' : 'Gửi OTP'),
              onPressed: _isLoading
                  ? () {}
                  : (_otpSent ? _resetPassword : _sendOtp),
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

  String? _validateOtp(String? value) {
    final otp = value?.trim() ?? '';
    if (!_otpSent) {
      return null;
    }
    if (otp.length != 6) {
      return 'OTP phải gồm 6 số.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (!_otpSent) {
      return null;
    }
    if (password.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự.';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (!_otpSent) {
      return null;
    }
    if (value != _passwordController.text) {
      return 'Mật khẩu xác nhận không khớp.';
    }
    return null;
  }
}
