import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:do_an/auth/models/app_user.dart';
import 'package:do_an/auth/services/auth_service.dart';
import 'package:do_an/auth/services/user_database.dart';

void main() {
  test('register, login, role check, and password reset work', () async {
    final databaseFile = File(
      '${Directory.systemTemp.path}/lexigo_auth_test_${DateTime.now().microsecondsSinceEpoch}.json',
    );
    final authService = AuthService(
      userDatabase: UserDatabase(databaseFile: databaseFile),
    );

    final registeredUser = await authService.register(
      fullName: 'Nguyen Van A',
      email: 'USER_${DateTime.now().microsecondsSinceEpoch}@lexigo.com',
      password: '123456',
    );

    expect(registeredUser.role, UserRole.user);

    final loggedInUser = await authService.login(
      email: registeredUser.email,
      password: '123456',
    );

    expect(loggedInUser.email, registeredUser.email);
    expect(loggedInUser.isAdmin, isFalse);

    final admin = await authService.login(
      email: 'admin@lexigo.com',
      password: 'admin123',
    );

    expect(admin.isAdmin, isTrue);

    final defaultLearner = await authService.login(
      email: 'vu78903@gmail.com',
      password: 'anhvu123',
    );

    expect(defaultLearner.fullName, 'Anh Vu');
    expect(defaultLearner.isAdmin, isFalse);

    final otp = await authService.sendResetOtp(registeredUser.email);
    await authService.resetPassword(
      email: registeredUser.email,
      otp: otp,
      newPassword: 'new123456',
    );

    final userAfterReset = await authService.login(
      email: registeredUser.email,
      password: 'new123456',
    );

    expect(userAfterReset.id, registeredUser.id);
  });
}
