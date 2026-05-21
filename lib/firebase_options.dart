import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Firebase web chưa được cấu hình. Hãy chạy flutterfire configure.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError(
          'Firebase Android chưa được cấu hình. Hãy chạy flutterfire configure.',
        );
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'Firebase iOS chưa được cấu hình. Hãy chạy flutterfire configure.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'Firebase macOS chưa được cấu hình. Hãy chạy flutterfire configure.',
        );
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError('Firebase chưa hỗ trợ nền tảng này trong app.');
    }
  }
}
