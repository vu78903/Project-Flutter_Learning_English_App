import 'package:flutter_test/flutter_test.dart';

import 'package:do_an/main.dart';

void main() {
  testWidgets('Login page can navigate to register page', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Đăng Nhập'), findsWidgets);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);

    await tester.tap(find.text('Đăng ký ngay'));
    await tester.pumpAndSettle();

    expect(find.text('Đăng Ký'), findsWidgets);
    expect(find.text('Họ và tên'), findsOneWidget);
    expect(find.text('Xác nhận mật khẩu'), findsOneWidget);
  });
}
