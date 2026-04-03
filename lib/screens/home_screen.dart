import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/score_manager.dart';
import '../game/game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _planeController;
  late AnimationController _pulseController;
  late Animation<double> _planeY;
  late Animation<double> _pulse;
  int _highScore = 0;

  @override
  void initState() {
    super.initState();
    _loadScore();

    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat();
    _planeController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

    _planeY = Tween<double>(begin: -18, end: 18).animate(
      CurvedAnimation(parent: _planeController, curve: Curves.easeInOut),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadScore() async {
    final s = await ScoreManager.getHighScore();
    if (mounted) setState(() => _highScore = s);
  }

  @override
  void dispose() {
    _bgController.dispose();
    _planeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _play() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const GameScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    ).then((_) => _loadScore());
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: GestureDetector(
        onTap: _play,
        child: AnimatedBuilder(
          animation: Listenable.merge([_bgController, _planeController, _pulseController]),
          builder: (context, _) {
            return CustomPaint(
              painter: _HomeBgPainter(_bgController.value),
              child: SizedBox.expand(
                child: Stack(
                  children: [
                    // Animated plane bobbing
                    Positioned(
                      left: size.width * 0.5 - 60,
                      top: size.height * 0.38 + _planeY.value,
                      child: CustomPaint(
                        painter: PlanePainter(tilt: _planeY.value * 0.004),
                        size: const Size(120, 56),
                      ),
                    ),

                    // Title
                    Positioned(
                      top: size.height * 0.1,
                      left: 0, right: 0,
                      child: Column(children: [
                        ShaderMask(
                          shaderCallback: (r) => const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                          ).createShader(r),
                          child: const Text('TAPPY', textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 64, fontWeight: FontWeight.w900,
                              color: Colors.white, letterSpacing: 10,
                              shadows: [Shadow(color: Colors.black38, blurRadius: 12, offset: Offset(2,4))]),
                          ),
                        ),
                        ShaderMask(
                          shaderCallback: (r) => const LinearGradient(
                            colors: [Color(0xFF00E5FF), Color(0xFF1565C0)],
                          ).createShader(r),
                          child: const Text('PLANE ✈', textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 58, fontWeight: FontWeight.w900,
                              color: Colors.white, letterSpacing: 8,
                              shadows: [Shadow(color: Colors.black38, blurRadius: 10, offset: Offset(2,4))]),
                          ),
                        ),
                      ]),
                    ),

                    // Play button
                    Positioned(
                      bottom: size.height * 0.26,
                      left: 40, right: 40,
                      child: Transform.scale(
                        scale: _pulse.value,
                        child: GestureDetector(
                          onTap: _play,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF6F00), Color(0xFFFF9800)],
                              ),
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: [BoxShadow(
                                color: const Color(0xFFFF9800).withOpacity(0.55),
                                blurRadius: 24, offset: const Offset(0, 8),
                              )],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 32),
                                SizedBox(width: 10),
                                Text('TAP TO FLY!', style: TextStyle(
                                  color: Colors.white, fontSize: 22,
                                  fontWeight: FontWeight.bold, letterSpacing: 2,
                                )),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // High score
                    if (_highScore > 0)
                      Positioned(
                        bottom: size.height * 0.16,
                        left: 0, right: 0,
                        child: Column(children: [
                          const Text('🏆  BEST', textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFFFFD700), fontSize: 13,
                              fontWeight: FontWeight.bold, letterSpacing: 4)),
                          Text('$_highScore', textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 40,
                              fontWeight: FontWeight.bold,
                              shadows: [Shadow(color: Colors.black38, blurRadius: 6)])),
                        ]),
                      ),

                    // Hint
                    Positioned(
                      bottom: 36, left: 0, right: 0,
                      child: Text('TAP ANYWHERE TO START',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withOpacity(0.55),
                          fontSize: 12, letterSpacing: 3)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Background painter ─────────────────────────────────
class _HomeBgPainter extends CustomPainter {
  final double t;
  _HomeBgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Sky gradient
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0D1B4B), Color(0xFF1565C0), Color(0xFF42A5F5), Color(0xFF80DEEA)],
        stops: [0.0, 0.35, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    // Sun glow
    final sunX = size.width * 0.75;
    final sunY = size.height * 0.18;
    canvas.drawCircle(Offset(sunX, sunY), 60,
      Paint()..color = const Color(0xFFFFD54F).withOpacity(0.18)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40));
    canvas.drawCircle(Offset(sunX, sunY), 32,
      Paint()..color = const Color(0xFFFFE082).withOpacity(0.7));
    canvas.drawCircle(Offset(sunX, sunY), 22,
      Paint()..color = const Color(0xFFFFF8E1));

    // Clouds
    final cloudOffsets = [
      Offset((0.05 + t * 0.25) % 1.1, 0.22),
      Offset((0.35 + t * 0.18) % 1.1, 0.32),
      Offset((0.6 + t * 0.22) % 1.1, 0.18),
      Offset((0.8 + t * 0.15) % 1.1, 0.28),
    ];
    final cloudSizes = [130.0, 100.0, 120.0, 90.0];
    for (int i = 0; i < cloudOffsets.length; i++) {
      _drawCloud(canvas, size,
        Offset(cloudOffsets[i].dx * size.width - 60, cloudOffsets[i].dy * size.height),
        cloudSizes[i]);
    }

    // Ground strip
    final groundY = size.height * 0.88;
    final groundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [const Color(0xFF388E3C), const Color(0xFF1B5E20)],
      ).createShader(Rect.fromLTWH(0, groundY, size.width, size.height - groundY));
    canvas.drawRect(Rect.fromLTWH(0, groundY, size.width, size.height - groundY), groundPaint);

    // Ground top edge highlight
    canvas.drawLine(Offset(0, groundY), Offset(size.width, groundY),
      Paint()..color = const Color(0xFF66BB6A)..strokeWidth = 3);
  }

  void _drawCloud(Canvas canvas, Size size, Offset pos, double w) {
    final h = w * 0.4;
    final p = Paint()..color = Colors.white.withOpacity(0.85);
    canvas.drawOval(Rect.fromCenter(center: Offset(pos.dx + w * 0.5, pos.dy + h * 0.6), width: w, height: h), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(pos.dx + w * 0.35, pos.dy + h * 0.35), width: w * 0.6, height: h * 0.7), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(pos.dx + w * 0.65, pos.dy + h * 0.4), width: w * 0.5, height: h * 0.65), p);
  }

  @override
  bool shouldRepaint(_HomeBgPainter old) => old.t != t;
}

// ── Plane painter (shared) ─────────────────────────────
class PlanePainter extends CustomPainter {
  final double tilt;
  const PlanePainter({this.tilt = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(tilt);
    canvas.translate(-size.width / 2, -size.height / 2);

    final w = size.width;
    final h = size.height;

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.85), width: w * 0.7, height: h * 0.18),
      Paint()..color = Colors.black.withOpacity(0.15)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Main wing (blue)
    final wingPaint = Paint()..color = const Color(0xFF1565C0);
    final wingPath = Path()
      ..moveTo(w * 0.58, h * 0.62)
      ..lineTo(w * 0.34, h * 0.62)
      ..lineTo(w * 0.14, h * 1.08)
      ..lineTo(w * 0.52, h * 0.88)
      ..close();
    canvas.drawPath(wingPath, wingPaint);

    // Wing highlight
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.55, h * 0.62)
        ..lineTo(w * 0.38, h * 0.62)
        ..lineTo(w * 0.24, h * 0.92)
        ..lineTo(w * 0.5, h * 0.85)
        ..close(),
      Paint()..color = const Color(0xFF1E88E5),
    );

    // Fuselage body
    final bodyPath = Path()
      ..moveTo(w * 0.08, h * 0.5)
      ..quadraticBezierTo(w * 0.12, h * 0.18, w * 0.45, h * 0.28)
      ..lineTo(w * 0.82, h * 0.36)
      ..lineTo(w * 0.97, h * 0.5)
      ..lineTo(w * 0.82, h * 0.64)
      ..lineTo(w * 0.45, h * 0.72)
      ..quadraticBezierTo(w * 0.12, h * 0.82, w * 0.08, h * 0.5)
      ..close();

    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, const Color(0xFFE3F2FD)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Tail vertical fin
    final tailV = Path()
      ..moveTo(w * 0.12, h * 0.38)
      ..lineTo(w * 0.2, h * 0.38)
      ..lineTo(w * 0.24, h * 0.0)
      ..lineTo(w * 0.1, h * 0.22)
      ..close();
    canvas.drawPath(tailV, Paint()..color = const Color(0xFFE53935));

    // Tail horizontal fin
    final tailH = Path()
      ..moveTo(w * 0.1, h * 0.56)
      ..lineTo(w * 0.24, h * 0.56)
      ..lineTo(w * 0.28, h * 0.8)
      ..lineTo(w * 0.08, h * 0.76)
      ..close();
    canvas.drawPath(tailH, Paint()..color = const Color(0xFF1565C0));

    // Nose stripe (red)
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.82, h * 0.36)
        ..lineTo(w * 0.97, h * 0.5)
        ..lineTo(w * 0.82, h * 0.64)
        ..lineTo(w * 0.78, h * 0.62)
        ..lineTo(w * 0.92, h * 0.5)
        ..lineTo(w * 0.78, h * 0.38)
        ..close(),
      Paint()..color = const Color(0xFFE53935),
    );

    // Windows
    final winPaint = Paint()..color = const Color(0xFF81D4FA);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.71, h * 0.42), width: w * 0.09, height: h * 0.2), winPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.60, h * 0.39), width: w * 0.08, height: h * 0.18), winPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.50, h * 0.37), width: w * 0.07, height: h * 0.16), winPaint);

    // Window shine
    final shine = Paint()..color = Colors.white.withOpacity(0.6);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.705, h * 0.395), width: w * 0.04, height: h * 0.09), shine);

    // Body outline
    canvas.drawPath(bodyPath, Paint()
      ..color = const Color(0xFFBBBBBB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);

    canvas.restore();
  }

  @override
  bool shouldRepaint(PlanePainter old) => old.tilt != tilt;
}
