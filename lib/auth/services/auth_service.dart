import '../models/app_user.dart';
import 'otp_service.dart';
import 'user_database.dart';

class AuthService {
  AuthService({UserDatabase? userDatabase, OtpService? otpService})
    : _userDatabase = userDatabase ?? UserDatabase(),
      _otpService = otpService ?? OtpService();

  static final AuthService instance = AuthService();

  final UserDatabase _userDatabase;
  final OtpService _otpService;

  Future<AppUser> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final existingUser = await _userDatabase.findByEmail(normalizedEmail);

    if (existingUser != null) {
      throw AuthException('Email này đã được đăng ký.');
    }

    final user = AppUser(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      fullName: fullName.trim(),
      email: normalizedEmail,
      password: password,
      role: UserRole.user,
      totalExp: 0,
      isActive: true,
      createdAt: DateTime.now(),
      currentStreak: 0,
      lastStudyDate: null,
    );

    await _userDatabase.insertUser(user);
    return user;
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final user = await _userDatabase.findByEmail(email);

    if (user == null || user.password != password) {
      throw AuthException('Email hoặc mật khẩu không đúng.');
    }

    if (!user.isActive) {
      throw AuthException('Tài khoản này đang bị khóa.');
    }

    return user;
  }

  Future<String> sendResetOtp(String email) async {
    final user = await _userDatabase.findByEmail(email);

    if (user == null) {
      throw AuthException('Không tìm thấy tài khoản với email này.');
    }

    return _otpService.createOtp(email);
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final isValidOtp = _otpService.verifyOtp(email: email, otp: otp);
    if (!isValidOtp) {
      throw AuthException('Mã OTP không đúng hoặc đã hết hạn.');
    }

    final user = await _userDatabase.findByEmail(email);
    if (user == null) {
      throw AuthException('Không tìm thấy tài khoản với email này.');
    }

    await _userDatabase.updateUser(user.copyWith(password: newPassword));
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
