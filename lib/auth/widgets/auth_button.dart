import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class AuthButton extends StatelessWidget {
  const AuthButton({required this.text, required this.onPressed, super.key});

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        child: Text(text),
      ),
    );
  }
}
