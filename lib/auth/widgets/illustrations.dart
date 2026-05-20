import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class RocketIllustration extends StatelessWidget {
  const RocketIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: RocketPainter());
  }
}

class MoonIllustration extends StatelessWidget {
  const MoonIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: MoonPainter());
  }
}

class RocketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cloudPaint = Paint()..color = AppColors.surface;
    final bluePaint = Paint()..color = const Color(0xFF75C9F1);
    final darkBluePaint = Paint()..color = const Color(0xFF147FD0);
    final orangePaint = Paint()..color = const Color(0xFFFF9837);
    final yellowPaint = Paint()..color = const Color(0xFFFFE66D);
    final windowPaint = Paint()..color = const Color(0xFFB9EAFF);

    canvas.drawCircle(
      Offset(size.width * 0.42, size.height * 0.80),
      92,
      bluePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.82),
      78,
      bluePaint,
    );
    _drawStars(canvas, size, yellowPaint);

    canvas.save();
    canvas.translate(size.width * 0.45, size.height * 0.43);
    canvas.rotate(-math.pi / 4.6);

    final body = Path()
      ..moveTo(0, -78)
      ..cubicTo(44, -58, 58, 30, 0, 82)
      ..cubicTo(-58, 30, -44, -58, 0, -78);
    canvas.drawPath(body, Paint()..color = AppColors.surfaceSoft);
    canvas.drawPath(
      body,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    canvas.drawCircle(const Offset(0, -28), 20, darkBluePaint);
    canvas.drawCircle(const Offset(0, -28), 11, windowPaint);

    final finLeft = Path()
      ..moveTo(-36, 28)
      ..lineTo(-76, 58)
      ..lineTo(-30, 72)
      ..close();
    final finRight = Path()
      ..moveTo(36, 28)
      ..lineTo(76, 58)
      ..lineTo(30, 72)
      ..close();
    canvas.drawPath(finLeft, darkBluePaint);
    canvas.drawPath(finRight, darkBluePaint);

    final fire = Path()
      ..moveTo(-18, 70)
      ..quadraticBezierTo(0, 126, 18, 70)
      ..quadraticBezierTo(0, 88, -18, 70);
    canvas.drawPath(fire, orangePaint);
    canvas.restore();

    _drawClouds(canvas, size, cloudPaint);
  }

  void _drawStars(Canvas canvas, Size size, Paint paint) {
    for (final point in [
      Offset(size.width * 0.28, size.height * 0.45),
      Offset(size.width * 0.34, size.height * 0.34),
      Offset(size.width * 0.61, size.height * 0.52),
      Offset(size.width * 0.68, size.height * 0.40),
    ]) {
      _drawSparkle(canvas, point, 7, paint);
    }
  }

  void _drawClouds(Canvas canvas, Size size, Paint paint) {
    final baseY = size.height * 0.80;
    final circles = [
      Offset(-20, baseY + 22),
      Offset(28, baseY + 2),
      Offset(82, baseY + 28),
      Offset(138, baseY + 4),
      Offset(205, baseY + 42),
      Offset(268, baseY + 14),
      Offset(335, baseY + 36),
      Offset(size.width + 20, baseY + 6),
    ];
    for (final center in circles) {
      canvas.drawCircle(center, 48, paint);
    }
    canvas.drawRect(Rect.fromLTWH(0, baseY + 32, size.width, 90), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MoonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bluePaint = Paint()..color = const Color(0xFF75C9F1);
    final cloudPaint = Paint()..color = AppColors.surface;
    final yellowPaint = Paint()..color = const Color(0xFFFFE66D);
    const faceColor = Color(0xFFB96F6F);

    canvas.drawCircle(
      Offset(size.width * 0.55, size.height * 0.64),
      98,
      bluePaint,
    );
    _drawSparkle(
      canvas,
      Offset(size.width * 0.30, size.height * 0.44),
      9,
      yellowPaint,
    );
    _drawSparkle(
      canvas,
      Offset(size.width * 0.76, size.height * 0.39),
      7,
      yellowPaint,
    );
    _drawSparkle(
      canvas,
      Offset(size.width * 0.70, size.height * 0.58),
      10,
      yellowPaint,
    );
    _drawSparkle(
      canvas,
      Offset(size.width * 0.40, size.height * 0.57),
      6,
      yellowPaint,
    );

    final moon = Path()
      ..moveTo(size.width * 0.50, size.height * 0.34)
      ..cubicTo(
        size.width * 0.74,
        size.height * 0.42,
        size.width * 0.78,
        size.height * 0.72,
        size.width * 0.56,
        size.height * 0.80,
      )
      ..cubicTo(
        size.width * 0.66,
        size.height * 0.62,
        size.width * 0.58,
        size.height * 0.45,
        size.width * 0.50,
        size.height * 0.34,
      );
    canvas.drawPath(moon, yellowPaint);

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.56, size.height * 0.60),
        width: 20,
        height: 12,
      ),
      0,
      math.pi,
      false,
      Paint()
        ..color = faceColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      Offset(size.width * 0.50, size.height * 0.58),
      3,
      Paint()..color = faceColor,
    );
    canvas.drawCircle(
      Offset(size.width * 0.63, size.height * 0.57),
      3,
      Paint()..color = faceColor,
    );

    final baseY = size.height * 0.78;
    for (final center in [
      Offset(-12, baseY + 8),
      Offset(38, baseY + 24),
      Offset(92, baseY + 4),
      Offset(154, baseY + 30),
      Offset(218, baseY + 6),
      Offset(282, baseY + 28),
      Offset(size.width + 18, baseY + 10),
    ]) {
      canvas.drawCircle(center, 50, cloudPaint);
    }
    canvas.drawRect(Rect.fromLTWH(0, baseY + 34, size.width, 90), cloudPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void _drawSparkle(Canvas canvas, Offset center, double radius, Paint paint) {
  final path = Path()
    ..moveTo(center.dx, center.dy - radius)
    ..lineTo(center.dx + radius * 0.35, center.dy - radius * 0.35)
    ..lineTo(center.dx + radius, center.dy)
    ..lineTo(center.dx + radius * 0.35, center.dy + radius * 0.35)
    ..lineTo(center.dx, center.dy + radius)
    ..lineTo(center.dx - radius * 0.35, center.dy + radius * 0.35)
    ..lineTo(center.dx - radius, center.dy)
    ..lineTo(center.dx - radius * 0.35, center.dy - radius * 0.35)
    ..close();
  canvas.drawPath(path, paint);
}
