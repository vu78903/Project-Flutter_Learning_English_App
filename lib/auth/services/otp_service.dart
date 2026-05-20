import 'dart:math';

class OtpService {
  final Map<String, _OtpRecord> _otpRecords = {};
  final Random _random = Random();

  String createOtp(String email) {
    final otp = (100000 + _random.nextInt(900000)).toString();
    _otpRecords[email.trim().toLowerCase()] = _OtpRecord(
      code: otp,
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
    );
    return otp;
  }

  bool verifyOtp({required String email, required String otp}) {
    final record = _otpRecords[email.trim().toLowerCase()];
    if (record == null) {
      return false;
    }

    final isValid =
        record.code == otp.trim() && DateTime.now().isBefore(record.expiresAt);
    if (isValid) {
      _otpRecords.remove(email.trim().toLowerCase());
    }

    return isValid;
  }
}

class _OtpRecord {
  const _OtpRecord({required this.code, required this.expiresAt});

  final String code;
  final DateTime expiresAt;
}
