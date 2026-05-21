import 'package:flutter/material.dart';

import 'auth/login_page.dart';
import 'core/app_colors.dart';
import 'core/firebase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LexiGo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.background,
        canvasColor: AppColors.background,
        cardColor: AppColors.surface,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {'/login': (_) => const LoginPage()},
    );
  }
}
