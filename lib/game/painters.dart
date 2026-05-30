import 'package:flutter/material.dart';
import 'dart:math' as math;

class PlanePainter extends CustomPainter {
  final double tilt;
  final double animationValue;
  
  const PlanePainter({this.tilt = 0.0, this.animationValue = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(tilt);
    canvas.translate(-size.width / 2, -size.height / 2);

    final w = size.width;
    final h = size.height;

    // Propeller (spinning)
    final propAngle = animationValue * 2 * math.pi * 4;
    canvas.save();
    canvas.translate(w * 0.95, h * 0.5);
    canvas.rotate(propAngle);
    final propPaint = Paint()..color = Colors.black26..strokeWidth = 2;
    canvas.drawLine(const Offset(0, -8), const Offset(0, 8), propPaint);
    canvas.drawLine(const Offset(-8, 0), const Offset(8, 0), propPaint);
    canvas.restore();

    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFFF5F5F5), const Color(0xFFBDBDBD)],
      ).createShader(Rect.fromLTWH(w * 0.1, h * 0.2, w * 0.8, h * 0.6));

    final bodyPath = Path()
      ..moveTo(w * 0.1, h * 0.5)
      ..quadraticBezierTo(w * 0.15, h * 0.2, w * 0.5, h * 0.3)
      ..lineTo(w * 0.8, h * 0.4)
      ..lineTo(w * 0.95, h * 0.5)
      ..lineTo(w * 0.8, h * 0.6)
      ..lineTo(w * 0.5, h * 0.7)
      ..quadraticBezierTo(w * 0.15, h * 0.8, w * 0.1, h * 0.5)
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);

    final wingOffset = math.sin(animationValue * 2 * math.pi) * 2;
    final wingPaint = Paint()..color = const Color(0xFF1976D2);
    final wingPath = Path()
      ..moveTo(w * 0.4, h * 0.5)
      ..lineTo(w * 0.2, h * 0.9 + wingOffset)
      ..lineTo(w * 0.5, h * 0.9 + wingOffset)
      ..lineTo(w * 0.6, h * 0.5)
      ..close();
    canvas.drawPath(wingPath, wingPaint);
    
    final tailPath = Path()
      ..moveTo(w * 0.15, h * 0.4)
      ..lineTo(w * 0.05, h * 0.1)
      ..lineTo(w * 0.2, h * 0.1)
      ..lineTo(w * 0.25, h * 0.4)
      ..close();
    canvas.drawPath(tailPath, Paint()..color = const Color(0xFFD32F2F));

    final cockpitPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.lightBlueAccent, Colors.blue],
      ).createShader(Rect.fromLTWH(w * 0.6, h * 0.35, w * 0.2, h * 0.15));
    canvas.drawOval(Rect.fromLTWH(w * 0.6, h * 0.38, w * 0.18, h * 0.12), cockpitPaint);
    
    canvas.drawOval(
      Rect.fromLTWH(w * 0.65, h * 0.39, w * 0.06, h * 0.04),
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );

    final rivetPaint = Paint()..color = Colors.black26;
    canvas.drawCircle(Offset(w * 0.4, h * 0.4), 1, rivetPaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.45), 1, rivetPaint);
    canvas.drawCircle(Offset(w * 0.3, h * 0.55), 1, rivetPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(PlanePainter old) => old.tilt != tilt || old.animationValue != animationValue;
}

class FishPainter extends CustomPainter {
  final double animationValue;
  
  const FishPainter({this.animationValue = 0.0});
  
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final tailWag = math.sin(animationValue * 2 * math.pi * 2) * 0.15;

    final bodyPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.orange[400]!, Colors.orange[800]!],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    
    final bodyPath = Path()
      ..moveTo(w * 0.15, h * 0.5)
      ..quadraticBezierTo(w * 0.4, h * 0.1, w * 0.8, h * 0.5)
      ..quadraticBezierTo(w * 0.4, h * 0.9, w * 0.15, h * 0.5)
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);

    final finPaint = Paint()..color = Colors.orange[900]!;
    final finWave = math.sin(animationValue * 2 * math.pi) * 0.05;
    
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.4, h * (0.25 + finWave))
        ..quadraticBezierTo(w * 0.5, h * finWave, w * 0.6, h * (0.3 + finWave))
        ..close(),
      finPaint,
    );
    
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.4, h * (0.75 - finWave))
        ..quadraticBezierTo(w * 0.5, h * (1 - finWave), w * 0.6, h * (0.7 - finWave))
        ..close(),
      finPaint,
    );

    canvas.save();
    canvas.translate(w * 0.15, h * 0.5);
    canvas.rotate(tailWag);
    canvas.translate(-w * 0.15, -h * 0.5);
    
    final tailPath = Path()
      ..moveTo(w * 0.15, h * 0.5)
      ..lineTo(0, h * 0.2)
      ..quadraticBezierTo(w * 0.1, h * 0.5, 0, h * 0.8)
      ..close();
    canvas.drawPath(tailPath, finPaint);
    canvas.restore();

    final eyeSize = animationValue % 0.5 < 0.05 ? 2.0 : 4.0;
    canvas.drawCircle(Offset(w * 0.65, h * 0.4), eyeSize, Paint()..color = Colors.white);
    if (eyeSize > 2) {
      canvas.drawCircle(Offset(w * 0.68, h * 0.4), 2, Paint()..color = Colors.black);
    }

    final scalePaint = Paint()..color = Colors.white24..style = PaintingStyle.stroke..strokeWidth = 1;
    for (int i = 0; i < 3; i++) {
      canvas.drawArc(Rect.fromLTWH(w * 0.3 + i * 10, h * 0.4, 10, 10), 0, 3, false, scalePaint);
    }
    
    for (int i = 0; i < 2; i++) {
      final bubbleOpacity = (math.sin(animationValue * 2 * math.pi + i) * 0.5 + 0.5);
      final bubbleX = w * 0.85 + (animationValue * 20 + i * 10) % 15;
      final bubbleY = h * 0.3 + i * 0.2 * h;
      canvas.drawCircle(
        Offset(bubbleX, bubbleY),
        2,
        Paint()..color = Colors.white.withValues(alpha: bubbleOpacity * 0.6),
      );
    }
  }
  
  @override
  bool shouldRepaint(FishPainter old) => old.animationValue != animationValue;
}

class RocketPainter extends CustomPainter {
  final double animationValue;
  
  const RocketPainter({this.animationValue = 0.0});
  
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bodyPaint = Paint()..shader = LinearGradient(colors: [Colors.grey[200]!, Colors.grey[400]!]).createShader(Rect.fromLTWH(0, 0, w, h));
    final finPaint = Paint()..color = const Color(0xFFD32F2F);

    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(1.57);
    canvas.translate(-h / 2, -w / 2);

    final rw = h;
    final rh = w;

    final path = Path()
      ..moveTo(rw * 0.5, 0)
      ..quadraticBezierTo(rw * 0.8, rh * 0.4, rw * 0.8, rh * 0.8)
      ..lineTo(rw * 0.2, rh * 0.8)
      ..quadraticBezierTo(rw * 0.2, rh * 0.4, rw * 0.5, 0)
      ..close();
    canvas.drawPath(path, bodyPaint);

    final windowGlow = 0.15 + math.sin(animationValue * 2 * math.pi) * 0.05;
    canvas.drawCircle(Offset(rw * 0.5, rh * 0.4), rw * windowGlow, Paint()..color = Colors.blueAccent);
    canvas.drawCircle(Offset(rw * 0.5, rh * 0.4), rw * 0.12, Paint()..color = Colors.lightBlueAccent);

    canvas.drawPath(Path()..moveTo(rw * 0.2, rh * 0.6)..lineTo(0, rh)..lineTo(rw * 0.3, rh * 0.8)..close(), finPaint);
    canvas.drawPath(Path()..moveTo(rw * 0.8, rh * 0.6)..lineTo(rw, rh)..lineTo(rw * 0.7, rh * 0.8)..close(), finPaint);

    final flameIntensity = 0.8 + math.sin(animationValue * 2 * math.pi * 3) * 0.4;
    final flame1 = Path()
      ..moveTo(rw * 0.3, rh * 0.8)
      ..lineTo(rw * 0.5, rh * (0.8 + 0.4 * flameIntensity))
      ..lineTo(rw * 0.7, rh * 0.8)
      ..close();
    canvas.drawPath(flame1, Paint()..color = Colors.orangeAccent);
    
    final flame2 = Path()
      ..moveTo(rw * 0.35, rh * 0.8)
      ..lineTo(rw * 0.5, rh * (0.8 + 0.3 * flameIntensity))
      ..lineTo(rw * 0.65, rh * 0.8)
      ..close();
    canvas.drawPath(flame2, Paint()..color = Colors.yellowAccent);

    canvas.restore();
  }
  
  @override
  bool shouldRepaint(RocketPainter old) => old.animationValue != animationValue;
}

class HeliPainter extends CustomPainter {
  final double animationValue;
  
  const HeliPainter({this.animationValue = 0.0});
  
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final tailRotorAngle = animationValue * 2 * math.pi * 6;
    canvas.save();
    canvas.translate(w * 0.15, h * 0.4);
    canvas.rotate(tailRotorAngle);
    canvas.drawLine(const Offset(0, -6), const Offset(0, 6), Paint()..color = Colors.black38..strokeWidth = 2);
    canvas.restore();

    canvas.drawRect(Rect.fromLTWH(w * 0.1, h * 0.45, w * 0.4, h * 0.1), Paint()..color = Colors.green[700]!);
    canvas.drawCircle(Offset(w * 0.15, h * 0.4), h * 0.15, Paint()..color = Colors.grey[400]!);

    final path = Path()
      ..moveTo(w * 0.4, h * 0.2)
      ..lineTo(w * 0.8, h * 0.2)
      ..quadraticBezierTo(w, h * 0.2, w, h * 0.5)
      ..quadraticBezierTo(w, h * 0.8, w * 0.8, h * 0.8)
      ..lineTo(w * 0.4, h * 0.8)
      ..quadraticBezierTo(w * 0.3, h * 0.8, w * 0.3, h * 0.5)
      ..quadraticBezierTo(w * 0.3, h * 0.2, w * 0.4, h * 0.2)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.green[600]!);

    final glass = Path()
      ..moveTo(w * 0.7, h * 0.25)
      ..lineTo(w * 0.85, h * 0.25)
      ..quadraticBezierTo(w * 0.95, h * 0.25, w * 0.95, h * 0.5)
      ..lineTo(w * 0.7, h * 0.5)
      ..close();
    canvas.drawPath(glass, Paint()..color = Colors.lightBlueAccent.withValues(alpha: 0.8));

    final rotorAngle = animationValue * 2 * math.pi * 8;
    canvas.save();
    canvas.translate(w * 0.6, h * 0.05);
    canvas.rotate(rotorAngle);
    
    final rotorPaint = Paint()..color = Colors.grey[800]!.withValues(alpha: 0.3)..strokeWidth = 2;
    canvas.drawLine(const Offset(-35, 0), const Offset(35, 0), rotorPaint);
    canvas.drawLine(const Offset(0, -35), const Offset(0, 35), rotorPaint);
    canvas.restore();

    canvas.drawRect(Rect.fromCenter(center: Offset(w * 0.6, h * 0.15), width: w * 0.1, height: h * 0.1), Paint()..color = Colors.grey[700]!);
    canvas.drawLine(Offset(w * 0.4, h * 0.95), Offset(w * 0.8, h * 0.95), Paint()..color = Colors.grey[800]!..strokeWidth = 3..strokeCap = StrokeCap.round);
  }
  
  @override
  bool shouldRepaint(HeliPainter old) => old.animationValue != animationValue;
}

class UfoPainter extends CustomPainter {
  final double animationValue;
  
  const UfoPainter({this.animationValue = 0.0});
  
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final wobble = math.sin(animationValue * 2 * math.pi) * 2;

    canvas.save();
    canvas.translate(0, wobble);

    final domePaint = Paint()..shader = RadialGradient(colors: [Colors.cyanAccent, Colors.blue]).createShader(Rect.fromCircle(center: Offset(w * 0.5, h * 0.4), radius: h * 0.3));
    canvas.drawArc(Rect.fromCenter(center: Offset(w * 0.5, h * 0.45), width: w * 0.5, height: h * 0.6), 3.14159, 3.14159, false, domePaint);

    final bodyPaint = Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.grey[400]!, Colors.grey[800]!]).createShader(Rect.fromCenter(center: Offset(w * 0.5, h * 0.6), width: w, height: h * 0.4));
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.5), width: w * 0.9, height: h * 0.4), bodyPaint);

    final lightColor = [Colors.redAccent, Colors.greenAccent, Colors.yellowAccent, Colors.purpleAccent];
    for (int i = 0; i < 4; i++) {
      double dx = w * 0.2 + (w * 0.6) * (i / 3);
      double dy = h * 0.6 + (i == 1 || i == 2 ? h * 0.05 : 0);
      
      final lightIntensity = (math.sin(animationValue * 2 * math.pi * 2 + i * 1.5) * 0.5 + 0.5);
      canvas.drawCircle(
        Offset(dx, dy),
        h * 0.08,
        Paint()..color = lightColor[i].withValues(alpha: lightIntensity * 0.8)..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4),
      );
      canvas.drawCircle(Offset(dx, dy), h * 0.04, Paint()..color = Colors.white.withValues(alpha: lightIntensity));
    }

    if (animationValue % 1.0 < 0.3) {
      final beamOpacity = (animationValue % 1.0) / 0.3;
      final beamPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.cyanAccent.withValues(alpha: beamOpacity * 0.3),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(w * 0.3, h * 0.6, w * 0.4, h * 0.4));
      canvas.drawRect(Rect.fromLTWH(w * 0.3, h * 0.6, w * 0.4, h * 0.4), beamPaint);
    }

    canvas.restore();
  }
  
  @override
  bool shouldRepaint(UfoPainter old) => old.animationValue != animationValue;
}
