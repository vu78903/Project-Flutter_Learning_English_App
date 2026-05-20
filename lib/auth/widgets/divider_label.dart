import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class DividerLabel extends StatelessWidget {
  const DividerLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.stroke, thickness: 1.5)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.stroke, thickness: 1.5)),
      ],
    );
  }
}
