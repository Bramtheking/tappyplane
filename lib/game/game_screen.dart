import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../utils/score_manager.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  // Game state
  bool _isPlaying = false;
  bool _isGameOver = false;
  int _score = 0;
  Timer? _timer;

  // Plane physics
  double _planeY = 0;
  double _planeVelocity = 0;
  final double _gravity = 0.6; // Flutter runs at ~60fps, 20ms tick
  final double _jumpForce = -9.0;
  final double _maxVelocity = 12.0;
  
  // Obstacles (pipes)
  final List<Obstacle> _obstacles = [];
  final double _obstacleSpeed = 4.0;
  final double _gapSize = 250;
  final double _obstacleWidth = 60;
  
  // Environment
  double _bgOffset = 0;
  double _groundOffset = 0;
  
  void _startGame() {
    setState(() {
      _isPlaying = true;
      _isGameOver = false;
      _score = 0;
      _planeY = 0;
      _planeVelocity = 0;
      _obstacles.clear();
      _bgOffset = 0;
      _groundOffset = 0;
    });

    _timer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      _updateGame();
    });
  }

  void _tap() {
    if (_isGameOver) return;
    if (!_isPlaying) {
      _startGame();
    }
    setState(() {
      _planeVelocity = _jumpForce;
    });
  }

  void _updateGame() {
    final size = MediaQuery.of(context).size;
    
    setState(() {
      // 1. Update Physics
      _planeVelocity += _gravity;
      if (_planeVelocity > _maxVelocity) _planeVelocity = _maxVelocity;
      _planeY += _planeVelocity;

      // 2. Update Environment
      _bgOffset -= 0.5; // Parallax slow
      _groundOffset -= _obstacleSpeed;

      // 3. Update Obstacles
      for (var obs in _obstacles) {
        obs.x -= _obstacleSpeed;
      }

      // Add new obstacle
      if (_obstacles.isEmpty || _obstacles.last.x < size.width - 250) {
        final randomY = math.Random().nextDouble() * (size.height * 0.4) - (size.height * 0.2);
        _obstacles.add(Obstacle(x: size.width, gapY: randomY));
      }

      // Remove off-screen obstacles & Count Score
      if (_obstacles.isNotEmpty && _obstacles.first.x < -_obstacleWidth) {
        _obstacles.removeAt(0);
      }
      for (var obs in _obstacles) {
        if (!obs.passed && obs.x + _obstacleWidth < size.width / 2 - 20) {
          obs.passed = true;
          _score++;
        }
      }

      // 4. Check Collisions
      _checkCollisions(size);
    });
  }

  void _checkCollisions(Size size) {
    // Plane hitbox (simplified)
    const planeW = 80.0;
    const planeH = 40.0;
    final rPlane = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 + _planeY),
      width: planeW,
      height: planeH,
    );

    // Floor collision
    final groundY = size.height * 0.88;
    if (rPlane.bottom >= groundY) {
      _gameOver();
      return;
    }
    
    // Ceiling collision
    if (rPlane.top <= 0) {
      _gameOver();
      return;
    }

    // Obstacle collision
    for (var obs in _obstacles) {
      final rTop = Rect.fromLTWH(obs.x, 0, _obstacleWidth, size.height / 2 + obs.gapY - _gapSize / 2);
      final rBottom = Rect.fromLTWH(obs.x, size.height / 2 + obs.gapY + _gapSize / 2, _obstacleWidth, size.height);

      if (rPlane.overlaps(rTop) || rPlane.overlaps(rBottom)) {
        _gameOver();
        return;
      }
    }
  }

  Future<void> _gameOver() async {
    _timer?.cancel();
    setState(() {
      _isPlaying = false;
      _isGameOver = true;
    });
    
    final isNewHigh = await ScoreManager.saveScore(_score);
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameOverDialog(score: _score, isNewHigh: isNewHigh, onRestart: () {
        Navigator.of(context).pop();
        _startGame();
      }, onHome: () {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _tap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            return Stack(
              children: [
                // Environment rendering
                CustomPaint(
                  size: size,
                  painter: GameEnvironmentPainter(
                    bgOffset: _bgOffset,
                    groundOffset: _groundOffset,
                    obstacles: _obstacles,
                    obstacleWidth: _obstacleWidth,
                    gapSize: _gapSize,
                  ),
                ),

                // Plane
                Positioned(
                  left: size.width / 2 - 40,
                  top: size.height / 2 + _planeY - 20,
                  child: Transform.rotate(
                    angle: _planeVelocity * 0.05, // Tilt based on velocity
                    child: const CustomPaint(
                      painter: PlanePainter(),
                      size: Size(80, 40),
                    ),
                  ),
                ),

                // Score
                if (_isPlaying || _isGameOver)
                  Positioned(
                    top: 60,
                    left: 0, right: 0,
                    child: Text(
                      '$_score',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0,2))],
                      ),
                    ),
                  ),

                // Start prompt
                if (!_isPlaying && !_isGameOver)
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'TAP TO FLY',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 8)],
                      ),
                    ),
                  ),
              ],
            );
          }
        ),
      ),
    );
  }
}

class Obstacle {
  double x;
  double gapY;
  bool passed = false;
  Obstacle({required this.x, required this.gapY});
}

class GameEnvironmentPainter extends CustomPainter {
  final double bgOffset;
  final double groundOffset;
  final List<Obstacle> obstacles;
  final double obstacleWidth;
  final double gapSize;

  GameEnvironmentPainter({
    required this.bgOffset,
    required this.groundOffset,
    required this.obstacles,
    required this.obstacleWidth,
    required this.gapSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Sky
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF0D1B4B), Color(0xFF1565C0), Color(0xFF42A5F5), Color(0xFF80DEEA)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    // 2. Obstacles (Pipes/Towers)
    final pipePaint = Paint()..color = const Color(0xFF2E7D32); // Dark green
    final pipeHighlight = Paint()..color = const Color(0xFF4CAF50);
    final pipeCap = Paint()..color = const Color(0xFF1B5E20);

    for (var obs in obstacles) {
      final centerX = obs.x + obstacleWidth / 2;
      
      // Top Pipe
      final topHeight = size.height / 2 + obs.gapY - gapSize / 2;
      final rectTop = Rect.fromLTWH(obs.x, 0, obstacleWidth, topHeight);
      canvas.drawRect(rectTop, pipePaint);
      canvas.drawRect(Rect.fromLTWH(obs.x + 5, 0, 10, topHeight), pipeHighlight);
      // Top pipe cap
      canvas.drawRect(Rect.fromLTWH(obs.x - 4, topHeight - 20, obstacleWidth + 8, 20), pipeCap);
      canvas.drawRect(Rect.fromLTWH(obs.x, topHeight - 20, 10, 20), pipeHighlight);

      // Bottom Pipe
      final bottomY = size.height / 2 + obs.gapY + gapSize / 2;
      final bottomHeight = size.height - bottomY;
      final rectBottom = Rect.fromLTWH(obs.x, bottomY, obstacleWidth, bottomHeight);
      canvas.drawRect(rectBottom, pipePaint);
      canvas.drawRect(Rect.fromLTWH(obs.x + 5, bottomY, 10, bottomHeight), pipeHighlight);
      // Bottom pipe cap
      canvas.drawRect(Rect.fromLTWH(obs.x - 4, bottomY, obstacleWidth + 8, 20), pipeCap);
      canvas.drawRect(Rect.fromLTWH(obs.x, bottomY, 10, 20), pipeHighlight);
    }

    // 3. Ground
    final groundY = size.height * 0.88;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, groundY, size.width, size.height - groundY));
    
    // Draw base ground
    canvas.drawRect(Rect.fromLTWH(0, groundY, size.width, size.height - groundY),
      Paint()..color = const Color(0xFF8D6E63));
    
    // Draw scrolling stripes effect
    final stripeW = 40.0;
    final ox = groundOffset % (stripeW * 2);
    for (double i = ox - stripeW * 2; i < size.width + stripeW; i += stripeW * 2) {
      canvas.drawRect(Rect.fromLTWH(i, groundY, stripeW, size.height - groundY),
        Paint()..color = const Color(0xFFA1887F));
    }
    
    // Top grass layer
    canvas.drawRect(Rect.fromLTWH(0, groundY, size.width, 24), Paint()..color = const Color(0xFF558B2F));
    canvas.drawRect(Rect.fromLTWH(0, groundY, size.width, 6), Paint()..color = const Color(0xFF7CB342));
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(GameEnvironmentPainter old) => true; // Always repaint for 60fps
}

class GameOverDialog extends StatelessWidget {
  final int score;
  final bool isNewHigh;
  final VoidCallback onRestart;
  final VoidCallback onHome;

  const GameOverDialog({super.key, required this.score, required this.isNewHigh, required this.onRestart, required this.onHome});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('GAME OVER', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
              const SizedBox(height: 20),
              if (isNewHigh)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFFFCC00), borderRadius: BorderRadius.circular(10)),
                  child: const Text('NEW HIGH SCORE!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              const SizedBox(height: 10),
              Text('SCORE: $score', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Color(0xFF424242))),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Btn(icon: Icons.home_rounded, color: Colors.blueGrey, onTap: onHome),
                  _Btn(icon: Icons.replay_rounded, color: const Color(0xFF4CAF50), onTap: onRestart, isLarge: true),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isLarge;

  const _Btn({required this.icon, required this.color, required this.onTap, this.isLarge = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isLarge ? 16 : 12),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Icon(icon, color: Colors.white, size: isLarge ? 36 : 24),
      ),
    );
  }
}
