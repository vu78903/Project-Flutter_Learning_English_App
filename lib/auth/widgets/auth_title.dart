import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class AuthTitle extends StatelessWidget {
  const AuthTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 28,
        fontWeight: FontWeight.w900,
        height: 1.1,
      ),
    );
  }
}
