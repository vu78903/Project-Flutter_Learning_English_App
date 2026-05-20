import 'package:flutter/material.dart';

class SocialButton extends StatelessWidget {
  const SocialButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onPressed,
    super.key,
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      elevation: 5,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 64,
          height: 64,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: label == 'f' ? 44 : 34,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
