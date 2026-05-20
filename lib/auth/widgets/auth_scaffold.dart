import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.child,
    required this.illustration,
    super.key,
  });

  final Widget child;
  final Widget illustration;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.28,
                width: double.infinity,
                child: illustration,
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 190),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
