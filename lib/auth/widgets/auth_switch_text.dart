import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class AuthSwitchText extends StatelessWidget {
  const AuthSwitchText({
    required this.text,
    required this.actionText,
    required this.onPressed,
    super.key,
  });

  final String text;
  final String actionText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '$text ',
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        InkWell(
          onTap: onPressed,
          child: Text(
            actionText,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
