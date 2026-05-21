# do_an

A new Flutter project.

## Cấu hình Owl Alpha

Chức năng nói chuyện với AI dùng Owl Alpha qua OpenRouter.

Chạy app kèm API key:

```sh
flutter run --dart-define=OPENROUTER_API_KEY=sk-or-v1-your-key
```

Nếu muốn đổi model OpenRouter khác:

```sh
flutter run \
  --dart-define=OPENROUTER_API_KEY=sk-or-v1-your-key \
  --dart-define=OPENROUTER_MODEL=openrouter/owl-alpha
```

## Cấu hình Firebase

Project đã có code tích hợp Firebase Auth, Firestore, Storage, Analytics,
Cloud Messaging và Remote Config. Nếu chưa có `firebase_options.dart` thật,
app sẽ tự fallback về dữ liệu local để không bị crash.

Các bước hoàn tất Firebase:

1. Vào Firebase Console và tạo/bật Firebase project.
2. Bật Authentication bằng Email/Password.
3. Tạo Cloud Firestore database.
4. Bật Firebase Storage.
5. Bật Analytics, Cloud Messaging và Remote Config nếu Firebase yêu cầu.
6. Trong thư mục project chạy:

```sh
flutterfire configure
```

7. Chọn Android/iOS/Web tùy nền tảng cần demo.
8. Chạy lại:

```sh
flutter pub get
flutter run
```

Ghi chú phân quyền:

- Tài khoản `admin@lexigo.com` khi đăng ký bằng Firebase sẽ được gán role admin.
- Các tài khoản khác mặc định là user.
- Có thể chỉnh role trực tiếp trong Firestore tại collection `users`.

Remote Config keys đang dùng:

- `intermediate_exp`
- `advanced_exp`
- `diamond_exp`
- `speaking_short_reward`
- `speaking_medium_reward`
- `speaking_long_reward`
- `topic_word_reward`

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
