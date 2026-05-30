import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../core/firebase_service.dart';
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

  static const _firebaseOperationTimeout = Duration(seconds: 10);
  static const _firestoreSetupMessage =
      'Cloud Firestore chưa được bật cho project này. Vào Firebase Console > Firestore Database > Create database, tạo database rồi chạy lại app.';

  Future<AppUser> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (FirebaseService.isEnabled) {
      return _registerWithFirebase(
        fullName: fullName,
        email: email,
        password: password,
      );
    }

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
    if (FirebaseService.isEnabled) {
      return _loginWithFirebase(email: email, password: password);
    }

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
    if (FirebaseService.isEnabled) {
      try {
        await firebase_auth.FirebaseAuth.instance.sendPasswordResetEmail(
          email: email.trim().toLowerCase(),
        );
        await FirebaseService.logEvent('password_reset_email_sent');
        return '';
      } on firebase_auth.FirebaseAuthException catch (error) {
        throw AuthException(_friendlyFirebaseAuthError(error));
      }
    }

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
    if (FirebaseService.isEnabled) {
      throw const AuthException(
        'Firebase đã gửi link đổi mật khẩu vào email. Hãy mở email để đặt lại mật khẩu.',
      );
    }

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

  Future<AppUser> _registerWithFirebase({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    try {
      final credential = await firebase_auth.FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: normalizedEmail,
            password: password,
          );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthException('Không tạo được tài khoản Firebase.');
      }

      await firebaseUser.updateDisplayName(fullName.trim());
      final user = AppUser(
        id: firebaseUser.uid,
        fullName: fullName.trim(),
        email: normalizedEmail,
        password: '',
        role: normalizedEmail == 'admin@lexigo.com'
            ? UserRole.admin
            : UserRole.user,
        totalExp: 0,
        isActive: true,
        createdAt: DateTime.now(),
        currentStreak: 0,
        lastStudyDate: null,
      );
      await _runFirebaseOperation(
        FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .set(user.toJson()),
      );
      await FirebaseService.logEvent('sign_up_email');
      return user;
    } on firebase_auth.FirebaseAuthException catch (error) {
      throw AuthException(_friendlyFirebaseAuthError(error));
    }
  }

  Future<AppUser> _loginWithFirebase({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    try {
      final credential = await firebase_auth.FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: normalizedEmail,
            password: password,
          );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthException('Không đăng nhập được Firebase.');
      }

      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid);
      final snapshot = await _runFirebaseOperation(userDoc.get());
      final user = snapshot.exists
          ? AppUser.fromJson(snapshot.data()!)
          : AppUser(
              id: firebaseUser.uid,
              fullName:
                  firebaseUser.displayName ?? normalizedEmail.split('@').first,
              email: normalizedEmail,
              password: '',
              role: normalizedEmail == 'admin@lexigo.com'
                  ? UserRole.admin
                  : UserRole.user,
              totalExp: 0,
              isActive: true,
              createdAt: DateTime.now(),
              currentStreak: 0,
              lastStudyDate: null,
            );

      if (!snapshot.exists) {
        await _runFirebaseOperation(userDoc.set(user.toJson()));
      }
      await _saveFcmToken(userDoc);
      if (!user.isActive) {
        await firebase_auth.FirebaseAuth.instance.signOut();
        throw const AuthException('Tài khoản này đang bị khóa.');
      }
      await FirebaseService.logEvent(
        'login_email',
        parameters: {'role': user.role.name},
      );
      return user;
    } on firebase_auth.FirebaseAuthException catch (error) {
      final defaultUser = await _tryCreateDefaultFirebaseUser(
        email: normalizedEmail,
        password: password,
        signInError: error,
      );
      if (defaultUser != null) {
        return defaultUser;
      }
      throw AuthException(_friendlyFirebaseAuthError(error));
    }
  }

  Future<AppUser?> _tryCreateDefaultFirebaseUser({
    required String email,
    required String password,
    required firebase_auth.FirebaseAuthException signInError,
  }) async {
    if (!_canCreateMissingDefaultUser(signInError)) {
      return null;
    }

    AppUser? defaultUser;
    for (final user in UserDatabase.defaultUsers()) {
      if (user.email.toLowerCase() == email && user.password == password) {
        defaultUser = user;
        break;
      }
    }

    if (defaultUser == null) {
      return null;
    }

    try {
      final credential = await firebase_auth.FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthException('Không tạo được tài khoản Firebase.');
      }

      await firebaseUser.updateDisplayName(defaultUser.fullName);
      final firebaseProfile = defaultUser.copyWith(
        id: firebaseUser.uid,
        password: '',
      );
      await _runFirebaseOperation(
        FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .set(firebaseProfile.toJson(), SetOptions(merge: true)),
      );
      await FirebaseService.logEvent(
        'seed_default_user',
        parameters: {'role': firebaseProfile.role.name},
      );
      return firebaseProfile;
    } on firebase_auth.FirebaseAuthException catch (error) {
      throw AuthException(_friendlyFirebaseAuthError(error));
    }
  }

  bool _canCreateMissingDefaultUser(firebase_auth.FirebaseAuthException error) {
    return switch (error.code) {
      'user-not-found' || 'invalid-credential' => true,
      _ => false,
    };
  }

  Future<void> _saveFcmToken(
    DocumentReference<Map<String, dynamic>> userDoc,
  ) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken().timeout(
        _firebaseOperationTimeout,
      );
      if (fcmToken != null) {
        await _runFirebaseOperation(
          userDoc.set({'fcmToken': fcmToken}, SetOptions(merge: true)),
        );
      }
    } on Object {
      // FCM token is useful, but it should not block login.
    }
  }

  Future<T> _runFirebaseOperation<T>(Future<T> operation) async {
    try {
      return await operation.timeout(_firebaseOperationTimeout);
    } on TimeoutException {
      throw const AuthException(_firestoreSetupMessage);
    } on FirebaseException catch (error) {
      if (_isFirestoreSetupError(error)) {
        throw const AuthException(_firestoreSetupMessage);
      }
      throw AuthException(error.message ?? 'Lỗi Firebase: ${error.code}.');
    }
  }

  bool _isFirestoreSetupError(FirebaseException error) {
    final message = error.message?.toLowerCase() ?? '';
    return error.plugin == 'cloud_firestore' &&
        (error.code == 'permission-denied' ||
            error.code == 'unavailable' ||
            message.contains('firestore api') ||
            message.contains('disabled') ||
            message.contains('permission_denied'));
  }

  String _friendlyFirebaseAuthError(firebase_auth.FirebaseAuthException error) {
    if (_isFirebaseAuthConfigurationError(error)) {
      return 'Firebase Authentication chưa bật Email/Password. Vào Firebase Console > Authentication > Sign-in method > Email/Password và bật lên, rồi chạy lại app.';
    }

    return switch (error.code) {
      'email-already-in-use' => 'Email này đã được đăng ký.',
      'invalid-email' => 'Email không hợp lệ.',
      'weak-password' => 'Mật khẩu quá yếu.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'Email hoặc mật khẩu không đúng.',
      'network-request-failed' => 'Không có kết nối mạng.',
      _ => error.message ?? 'Lỗi Firebase Authentication.',
    };
  }

  bool _isFirebaseAuthConfigurationError(
    firebase_auth.FirebaseAuthException error,
  ) {
    final message = error.message?.toUpperCase() ?? '';
    return error.code == 'configuration-not-found' ||
        message.contains('CONFIGURATION_NOT_FOUND');
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
