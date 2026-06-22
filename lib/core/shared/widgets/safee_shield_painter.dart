import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

/// Custom painter that faithfully reproduces the SAFEE MEET shield SVG icon.
class SafeeMeetShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    // Coordinate space mirrors the original 100×110 SVG viewBox.
    final scaleX = w / 100;
    final scaleY = h / 110;

    // ── Left half (red) ─────────────────────────────────────────────────
    final leftHalf = Path()
      ..moveTo(50 * scaleX, 6 * scaleY)
      ..lineTo(14 * scaleX, 18 * scaleY)
      ..lineTo(14 * scaleX, 52 * scaleY)
      ..cubicTo(
        14 * scaleX, 74 * scaleY,
        30 * scaleX, 92 * scaleY,
        50 * scaleX, 99 * scaleY,
      )
      ..close();
    canvas.drawPath(leftHalf, Paint()..color = AppColors.primary);

    // ── Right half (black) ───────────────────────────────────────────────
    final rightHalf = Path()
      ..moveTo(50 * scaleX, 6 * scaleY)
      ..lineTo(86 * scaleX, 18 * scaleY)
      ..lineTo(86 * scaleX, 52 * scaleY)
      ..cubicTo(
        86 * scaleX, 74 * scaleY,
        70 * scaleX, 92 * scaleY,
        50 * scaleX, 99 * scaleY,
      )
      ..close();
    canvas.drawPath(rightHalf, Paint()..color = const Color(0xFF111111));

    // ── Inner left face (lighter red, 25% opacity) ───────────────────────
    final innerLeft = Path()
      ..moveTo(50 * scaleX, 14 * scaleY)
      ..lineTo(20 * scaleX, 24 * scaleY)
      ..lineTo(20 * scaleX, 52 * scaleY)
      ..cubicTo(
        20 * scaleX, 70 * scaleY,
        33 * scaleX, 85 * scaleY,
        50 * scaleX, 92 * scaleY,
      )
      ..close();
    canvas.drawPath(
      innerLeft,
      Paint()..color = AppColors.primaryLight.withOpacity(0.25),
    );

    // ── Inner right face (lighter black, 25% opacity) ────────────────────
    final innerRight = Path()
      ..moveTo(50 * scaleX, 14 * scaleY)
      ..lineTo(80 * scaleX, 24 * scaleY)
      ..lineTo(80 * scaleX, 52 * scaleY)
      ..cubicTo(
        80 * scaleX, 70 * scaleY,
        67 * scaleX, 85 * scaleY,
        50 * scaleX, 92 * scaleY,
      )
      ..close();
    canvas.drawPath(
      innerRight,
      Paint()..color = const Color(0xFF333333).withOpacity(0.25),
    );

    // ── Left person head ─────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(31 * scaleX, 32 * scaleY),
      6.5 * scaleX,
      Paint()..color = AppColors.primary,
    );

    // ── Left person torso / arm ──────────────────────────────────────────
    final leftTorso = Path()
      ..moveTo(22 * scaleX, 58 * scaleY)
      ..quadraticBezierTo(
        24 * scaleX, 44 * scaleY,
        31 * scaleX, 41 * scaleY,
      )
      ..quadraticBezierTo(
        36 * scaleX, 39 * scaleY,
        40 * scaleX, 44 * scaleY,
      )
      ..lineTo(50 * scaleX, 53 * scaleY);
    canvas.drawPath(
      leftTorso,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.5 * scaleX
        ..strokeCap = StrokeCap.round,
    );

    // ── Right person head ────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(69 * scaleX, 32 * scaleY),
      6.5 * scaleX,
      Paint()..color = const Color(0xFF111111),
    );

    // ── Right person torso ───────────────────────────────────────────────
    final rightTorso = Path()
      ..moveTo(78 * scaleX, 58 * scaleY)
      ..quadraticBezierTo(
        76 * scaleX, 44 * scaleY,
        69 * scaleX, 41 * scaleY,
      )
      ..quadraticBezierTo(
        64 * scaleX, 39 * scaleY,
        60 * scaleX, 44 * scaleY,
      )
      ..lineTo(50 * scaleX, 53 * scaleY);
    canvas.drawPath(
      rightTorso,
      Paint()
        ..color = const Color(0xFF111111)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.5 * scaleX
        ..strokeCap = StrokeCap.round,
    );

    // ── Handshake (red layer) ────────────────────────────────────────────
    final handshake = Path()
      ..moveTo(44 * scaleX, 53 * scaleY)
      ..cubicTo(
        46 * scaleX, 51 * scaleY,
        48 * scaleX, 51 * scaleY,
        50 * scaleX, 53 * scaleY,
      )
      ..cubicTo(
        52 * scaleX, 55 * scaleY,
        54 * scaleX, 55 * scaleY,
        56 * scaleX, 53 * scaleY,
      );
    canvas.drawPath(
      handshake,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * scaleX
        ..strokeCap = StrokeCap.round,
    );

    // ── Clasped hands ellipse ────────────────────────────────────────────
    canvas.save();
    canvas.translate(50 * scaleX, 53 * scaleY);
    canvas.scale(1.0, 5 / 7.0);
    canvas.drawCircle(Offset.zero, 7 * scaleX, Paint()..color = AppColors.primary);
    canvas.restore();
    canvas.save();
    canvas.translate(50 * scaleX, 53 * scaleY);
    canvas.scale(1.0, 5 / 7.0);
    canvas.drawCircle(
      Offset.zero,
      7 * scaleX,
      Paint()..color = const Color(0xFF111111).withOpacity(0.45),
    );
    canvas.restore();

    // ── Mini verification shield ─────────────────────────────────────────
    final miniShield = Path()
      ..moveTo(50 * scaleX, 18 * scaleY)
      ..lineTo(42 * scaleX, 21 * scaleY)
      ..lineTo(42 * scaleX, 28 * scaleY)
      ..cubicTo(
        42 * scaleX, 33 * scaleY,
        45.5 * scaleX, 37 * scaleY,
        50 * scaleX, 38.5 * scaleY,
      )
      ..cubicTo(
        54.5 * scaleX, 37 * scaleY,
        58 * scaleX, 33 * scaleY,
        58 * scaleX, 28 * scaleY,
      )
      ..lineTo(58 * scaleX, 21 * scaleY)
      ..close();
    canvas.drawPath(miniShield, Paint()..color = AppColors.primary);

    // ── Checkmark inside mini shield ─────────────────────────────────────
    final checkmark = Path()
      ..moveTo(45.5 * scaleX, 28.5 * scaleY)
      ..lineTo(48.5 * scaleX, 31.5 * scaleY)
      ..lineTo(54.5 * scaleX, 24.5 * scaleY);
    canvas.drawPath(
      checkmark,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 * scaleX
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SafeeMeetShieldIcon extends StatelessWidget {
  final double size;
  const SafeeMeetShieldIcon({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: SafeeMeetShieldPainter(),
        size: Size(size, size * (110 / 100)),
      );
}
