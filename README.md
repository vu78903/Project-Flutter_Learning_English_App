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

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
