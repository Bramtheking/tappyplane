import 'dart:async';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/score_manager.dart';
import '../services/auth_service.dart';
import '../services/leaderboard_service.dart';
import 'painters.dart';

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
  int _sessionCoins = 0;
  Timer? _timer;
  String _selectedCharacter = 'airplane';
  String _selectedArea = 'classic';

  // Audio players
  late AudioPlayer _sfxPlayer;
  late AudioPlayer _bgmPlayer;

  // Plane physics
  double _planeY = 0;
  double _planeVelocity = 0;
  final double _gravity = 0.6;
  final double _jumpForce = -9.0;
  final double _maxVelocity = 12.0;

  // Obstacles (pipes)
  final List<Obstacle> _obstacles = [];
  final double _obstacleSpeed = 4.0;
  double _gapSize = 250;
  final double _obstacleWidth = 60;

  // Coins
  final List<Coin> _coins = [];
  
  // Environment
  double _bgOffset = 0;
  double _groundOffset = 0;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadCharacter();
    _sfxPlayer = AudioPlayer();
    _bgmPlayer = AudioPlayer();
    _bgmPlayer.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> _loadCharacter() async {
    final c = await ScoreManager.getSelectedCharacter();
    final a = await ScoreManager.getSelectedArea();
    setState(() {
      _selectedCharacter = c;
      _selectedArea = a;
    });
  }

  void _playSound(String name) async {
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('sounds/$name.mp3'));
    } catch (_) {}
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _isGameOver = false;
      _score = 0;
      _sessionCoins = 0;
      _planeY = 0;
      _planeVelocity = 0;
      _obstacles.clear();
      _coins.clear();
      _bgOffset = 0;
      _groundOffset = 0;
      _gapSize = 250;
    });

    try {
      _bgmPlayer.play(AssetSource('sounds/music.mp3'));
    } catch (_) {}

    _timer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      _updateGame();
    });
  }

  void _tap() {
    if (_isGameOver) return;
    if (!_isPlaying) {
      _startGame();
    }
    _playSound('jump');
    setState(() {
      _planeVelocity = _jumpForce;
    });
  }

  void _updateGame() {
    final size = MediaQuery.of(context).size;
    final random = math.Random();
    
    setState(() {
      // 1. Update Physics
      _planeVelocity += _gravity;
      if (_planeVelocity > _maxVelocity) _planeVelocity = _maxVelocity;
      _planeY += _planeVelocity;

      // 2. Update Environment
      _bgOffset -= 0.5;
      _groundOffset -= _obstacleSpeed;

      // 3. Update Obstacles
      for (var obs in _obstacles) {
        obs.x -= _obstacleSpeed;
        if (_score >= 50) {
          obs.gapY += obs.moveDir * 1.5;
          if (obs.gapY > size.height * 0.25 || obs.gapY < -size.height * 0.25) {
            obs.moveDir *= -1;
          }
        }
      }

      // Add new obstacle
      if (_obstacles.isEmpty || _obstacles.last.x < size.width - 250) {
        final randomY = random.nextDouble() * (size.height * 0.4) - (size.height * 0.2);
        _obstacles.add(Obstacle(x: size.width, gapY: randomY, moveDir: random.nextBool() ? 1.0 : -1.0));

        if (random.nextDouble() < 0.4) {
          _coins.add(Coin(x: size.width + 125, y: randomY));
        }
      }

      // 4. Update Coins
      for (var coin in _coins) {
        coin.x -= _obstacleSpeed;
      }

      // 5. Cleanup
      if (_obstacles.isNotEmpty && _obstacles.first.x < -_obstacleWidth) {
        _obstacles.removeAt(0);
      }
      if (_coins.isNotEmpty && _coins.first.x < -50) {
        _coins.removeAt(0);
      }

      // 6. Score
      for (var obs in _obstacles) {
        if (!obs.passed && obs.x + _obstacleWidth < size.width / 2 - 20) {
          obs.passed = true;
          _score++;
          if (_score < 100 && _gapSize > 180) {
            _gapSize -= 0.5;
          }
        }
      }

      // 7. Check Collisions
      _checkCollisions(size);
    });
  }

  void _checkCollisions(Size size) {
    const planeW = 80.0;
    const planeH = 40.0;
    final rPlane = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 + _planeY),
      width: planeW * 0.7,
      height: planeH * 0.7,
    );

    // Floor collision
    final groundY = size.height * 0.88;
    if (rPlane.bottom >= groundY || rPlane.top <= 0) {
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

    // Coin collection
    for (var i = _coins.length - 1; i >= 0; i--) {
      final coin = _coins[i];
      final rCoin = Rect.fromCircle(center: Offset(coin.x, size.height / 2 + coin.y), radius: 15);
      if (rPlane.overlaps(rCoin)) {
        _coins.removeAt(i);
        _sessionCoins++;
        ScoreManager.addCoins(1);
        _playSound('coin');
      }
    }
  }

  Future<void> _gameOver() async {
    _timer?.cancel();
    _bgmPlayer.stop();
    _playSound('dead');
    setState(() {
      _isPlaying = false;
      _isGameOver = true;
    });
    
    final isNewHigh = await ScoreManager.saveScore(_score);
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameOverDialog(
        score: _score, 
        coins: _sessionCoins,
        isNewHigh: isNewHigh, 
        onRestart: () {
          Navigator.of(context).pop();
          _startGame();
        }, onHome: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        }
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ensure focus for keyboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_focusNode.hasFocus) _focusNode.requestFocus();
    });

    return Scaffold(
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
            _tap();
          }
        },
        child: GestureDetector(
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
                      coins: _coins,
                      obstacleWidth: _obstacleWidth,
                      gapSize: _gapSize,
                      score: _score,
                      selectedArea: _selectedArea,
                    ),
                  ),

                  // Plane
                  Positioned(
                    left: size.width / 2 - 40,
                    top: size.height / 2 + _planeY - 20,
                    child: Transform.rotate(
                      angle: _planeVelocity * 0.05, 
                      child: _buildCharacter(),
                    ),
                  ),

                  // Score & Coins
                  if (_isPlaying || _isGameOver) ...[
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
                    Positioned(
                      top: 60,
                      right: 20,
                      child: Row(
                        children: [
                          const Icon(Icons.stars, color: Colors.amber, size: 28),
                          const SizedBox(width: 5),
                          Text('$_sessionCoins', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    )
                  ],

                  // Start prompt
                  if (!_isPlaying && !_isGameOver)
                    Align(
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'TAP OR SPACE TO FLY',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 8)],
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text('GOAL: SCORE 50+ FOR MOVING PILLARS', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          const Text('GOAL: SCORE 70+ FOR COLOR SHIFTS', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                    ),
                ],
              );
            }
          ),
        ),
      ),
    );
  }

  Widget _buildCharacter() {
    CustomPainter painter;
    switch (_selectedCharacter) {
      case 'fish': painter = const FishPainter(); break;
      case 'rocket': painter = const RocketPainter(); break;
      case 'heli': painter = const HeliPainter(); break;
      case 'ufo': painter = const UfoPainter(); break;
      default: painter = PlanePainter(tilt: _planeVelocity * 0.05);
    }
    return CustomPaint(
      painter: painter,
      size: const Size(80, 40),
    );
  }
}

class Obstacle {
  double x;
  double gapY;
  double moveDir;
  bool passed = false;
  Obstacle({required this.x, required this.gapY, required this.moveDir});
}

class Coin {
  double x;
  double y;
  Coin({required this.x, required this.y});
}

class GameEnvironmentPainter extends CustomPainter {
  final double bgOffset;
  final double groundOffset;
  final List<Obstacle> obstacles;
  final List<Coin> coins;
  final double obstacleWidth;
  final double gapSize;
  final int score;
  final String selectedArea;

  GameEnvironmentPainter({
    required this.bgOffset,
    required this.groundOffset,
    required this.obstacles,
    required this.coins,
    required this.obstacleWidth,
    required this.gapSize,
    required this.score,
    required this.selectedArea,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Sky / Background Color Shifts
    Color topCol;
    Color midCol1;
    Color midCol2;
    Color botCol;

    if (selectedArea == 'night') {
      topCol = const Color(0xFF090E27);
      midCol1 = const Color(0xFF1A237E);
      midCol2 = const Color(0xFF311B92);
      botCol = const Color(0xFF5E35B1);
    } else if (selectedArea == 'desert') {
      topCol = const Color(0xFFBF360C);
      midCol1 = const Color(0xFFD84315);
      midCol2 = const Color(0xFFE64A19);
      botCol = const Color(0xFFFFCC80);
    } else if (selectedArea == 'synthwave') {
      topCol = const Color(0xFF120024);
      midCol1 = const Color(0xFF4A148C);
      midCol2 = const Color(0xFF880E4F);
      botCol = const Color(0xFFF50057);
    } else { // classic
      topCol = const Color(0xFF0D1B4B);
      midCol1 = const Color(0xFF1565C0);
      midCol2 = const Color(0xFF42A5F5);
      botCol = const Color(0xFF80DEEA);
    }

    // Background changes at 70, then every 100 (170, 270, 370, etc.)
    if (score >= 70) {
      int shiftIndex;
      
      if (score < 170) {
        shiftIndex = 0; // 70-169
      } else {
        // 170, 270, 370, etc. -> index 1, 2, 3...
        shiftIndex = ((score - 70) ~/ 100) % 15;
      }

      final palettes = [
        [const Color(0xFF1A237E), const Color(0xFF311B92), const Color(0xFF4527A0), const Color(0xFF5E35B1)], // 70
        [const Color(0xFF1B5E20), const Color(0xFF2E7D32), const Color(0xFF388E3C), const Color(0xFF4CAF50)], // 170
        [const Color(0xFF4E342E), const Color(0xFF5D4037), const Color(0xFF6D4C41), const Color(0xFF795548)], // 270
        [const Color(0xFF212121), const Color(0xFF424242), const Color(0xFF616161), const Color(0xFF757575)], // 370
        [const Color(0xFFBF360C), const Color(0xFFD84315), const Color(0xFFE64A19), const Color(0xFFF4511E)], // 470
        [const Color(0xFF4A148C), const Color(0xFF6A1B9A), const Color(0xFF7B1FA2), const Color(0xFF8E24AA)], // 570
        [const Color(0xFF006064), const Color(0xFF00838F), const Color(0xFF0097A7), const Color(0xFF00ACC1)], // 670
        [const Color(0xFF311B92), const Color(0xFF4527A0), const Color(0xFF512DA8), const Color(0xFF5E35B1)], // 770
        [const Color(0xFFE65100), const Color(0xFFEF6C00), const Color(0xFFF57C00), const Color(0xFFFB8C00)], // 870
        [const Color(0xFF01579B), const Color(0xFF0277BD), const Color(0xFF0288D1), const Color(0xFF039BE5)], // 970
        [const Color(0xFF121212), const Color(0xFF1E1E1E), const Color(0xFF2C2C2C), const Color(0xFF383838)], // 1070
        [const Color(0xFF004D40), const Color(0xFF00695C), const Color(0xFF00796B), const Color(0xFF00897B)], // 1170
        [const Color(0xFF311B92), const Color(0xFF01579B), const Color(0xFF006064), const Color(0xFF1B5E20)], // 1270
        [const Color(0xFF1A237E), const Color(0xFF4A148C), const Color(0xFF880E4F), const Color(0xFFB71C1C)], // 1370
        [const Color(0xFF000000), const Color(0xFF1A237E), const Color(0xFF0D47A1), const Color(0xFF01579B)], // 1470+
      ];

      topCol = palettes[shiftIndex][0];
      midCol1 = palettes[shiftIndex][1];
      midCol2 = palettes[shiftIndex][2];
      botCol = palettes[shiftIndex][3];
    }

    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [topCol, midCol1, midCol2, botCol],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    // 2. Stars (Parallax for depth) - draw stars if night or synthwave, or deep sky shift
    if (selectedArea == 'night' || selectedArea == 'synthwave' || (score >= 100 && botCol.computeLuminance() < 0.2)) {
      final starPaint = Paint()..color = Colors.white.withOpacity(0.5);
      for (int i = 0; i < 30; i++) {
        final x = (math.sin(i * 100) * 1000 + bgOffset * 2) % size.width;
        final y = (math.cos(i * 200) * 1000) % size.height;
        canvas.drawCircle(Offset(x, y), i % 3 == 0 ? 2.0 : 1.0, starPaint);
      }
    }

    // 3. Ground
    final groundY = size.height * 0.88;

    Color groundDirt;
    Color groundStripes;
    Color grassTop;
    Color grassBottom;

    if (selectedArea == 'desert') {
      groundDirt = const Color(0xFFD84315);
      groundStripes = const Color(0xFFBF360C);
      grassTop = const Color(0xFFFFCC80);
      grassBottom = const Color(0xFFFFB74D);
    } else if (selectedArea == 'synthwave') {
      groundDirt = const Color(0xFF4A148C);
      groundStripes = const Color(0xFF311B92);
      grassTop = const Color(0xFFF50057);
      grassBottom = const Color(0xFFC51162);
    } else if (selectedArea == 'night') {
      groundDirt = const Color(0xFF3E2723);
      groundStripes = const Color(0xFF212121);
      grassTop = const Color(0xFF1B5E20);
      grassBottom = const Color(0xFF003300);
    } else { // classic
      groundDirt = const Color(0xFF8D6E63);
      groundStripes = const Color(0xFFA1887F);
      grassTop = const Color(0xFF558B2F);
      grassBottom = const Color(0xFF7CB342);
    }

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, groundY, size.width, size.height - groundY));
    canvas.drawRect(Rect.fromLTWH(0, groundY, size.width, size.height - groundY), Paint()..color = groundDirt);
    
    final stripeW = 40.0;
    final ox = groundOffset % (stripeW * 2);
    for (double i = ox - stripeW * 2; i < size.width + stripeW; i += stripeW * 2) {
      canvas.drawRect(Rect.fromLTWH(i, groundY, stripeW, size.height - groundY), Paint()..color = groundStripes);
    }
    
    canvas.drawRect(Rect.fromLTWH(0, groundY, size.width, 24), Paint()..color = grassTop);
    canvas.drawRect(Rect.fromLTWH(0, groundY, size.width, 6), Paint()..color = grassBottom);
    canvas.restore();
    
    // 4. Obstacles
    for (var obs in obstacles) {
      _drawPipe(canvas, Rect.fromLTWH(obs.x, 0, obstacleWidth, size.height / 2 + obs.gapY - gapSize / 2), true);
      _drawPipe(canvas, Rect.fromLTWH(obs.x, size.height / 2 + obs.gapY + gapSize / 2, obstacleWidth, size.height), false);
    }

    // 5. Coins
    for (var coin in coins) {
      final center = Offset(coin.x, size.height / 2 + coin.y);
      _drawCoin(canvas, center);
    }
  }

  void _drawPipe(Canvas canvas, Rect rect, bool isTop) {
    List<Color> pipeColors;
    List<Color> capColors;

    if (selectedArea == 'synthwave') {
      pipeColors = [const Color(0xFF6A1B9A), const Color(0xFFAB47BC), const Color(0xFF4A148C)];
      capColors = [const Color(0xFF4A148C), const Color(0xFF8E24AA), const Color(0xFF4A148C)];
    } else if (selectedArea == 'desert') {
      pipeColors = [const Color(0xFFE65100), const Color(0xFFFF9800), const Color(0xFFBF360C)];
      capColors = [const Color(0xFFBF360C), const Color(0xFFF57C00), const Color(0xFFBF360C)];
    } else if (selectedArea == 'night') {
      pipeColors = [const Color(0xFF37474F), const Color(0xFF78909C), const Color(0xFF263238)];
      capColors = [const Color(0xFF263238), const Color(0xFF546E7A), const Color(0xFF263238)];
    } else { // classic
      pipeColors = [const Color(0xFF2E7D32), const Color(0xFF4CAF50), const Color(0xFF1B5E20)];
      capColors = [const Color(0xFF1B5E20), const Color(0xFF388E3C), const Color(0xFF1B5E20)];
    }

    final bodyPaint = Paint()
      ..shader = LinearGradient(
        colors: pipeColors,
      ).createShader(rect);
    
    // Smooth rounded pipe
    final rRect = RRect.fromRectAndCorners(
      rect, 
      bottomLeft: isTop ? const Radius.circular(8) : Radius.zero,
      bottomRight: isTop ? const Radius.circular(8) : Radius.zero,
      topLeft: isTop ? Radius.zero : const Radius.circular(8),
      topRight: isTop ? Radius.zero : const Radius.circular(8),
    );
    canvas.drawRRect(rRect, bodyPaint);

    // Decorative Lines (Rivets/Panels)
    final linePaint = Paint()..color = Colors.black12..strokeWidth = 2;
    for (double i = rect.left + 15; i < rect.right; i += 20) {
      canvas.drawLine(Offset(i, rect.top), Offset(i, rect.bottom), linePaint);
    }

    // Cap
    final capRect = isTop 
        ? Rect.fromLTWH(rect.left - 4, rect.bottom - 25, rect.width + 8, 25) 
        : Rect.fromLTWH(rect.left - 4, rect.top, rect.width + 8, 25);
    
    final capPaint = Paint()
      ..shader = LinearGradient(
        colors: capColors,
      ).createShader(capRect);
    
    canvas.drawRRect(RRect.fromRectAndRadius(capRect, const Radius.circular(4)), capPaint);
    
    // Cap Detail
    canvas.drawRRect(
      RRect.fromRectAndRadius(capRect, const Radius.circular(4)), 
      Paint()..color = Colors.black26..style = PaintingStyle.stroke..strokeWidth = 1
    );
  }

  void _drawCoin(Canvas canvas, Offset center) {
    final paint = Paint()
      ..shader = const RadialGradient(
        colors: [Colors.amber, Colors.orange],
      ).createShader(Rect.fromCircle(center: center, radius: 15));
    
    canvas.drawCircle(center, 15, paint);
    
    // Embossed star/symbol
    final starPaint = Paint()..color = Colors.white.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.drawCircle(center, 10, starPaint);
    
    // Shine effect
    final shinePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white.withOpacity(0.8), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center.translate(-5, -5), radius: 10));
    canvas.drawCircle(center, 12, shinePaint);

    // Outer glow
    canvas.drawCircle(center, 18, Paint()..color = Colors.amber.withOpacity(0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
  }

  @override
  bool shouldRepaint(GameEnvironmentPainter old) => true;
}

class GameOverDialog extends StatefulWidget {
  final int score;
  final int coins;
  final bool isNewHigh;
  final VoidCallback onRestart;
  final VoidCallback onHome;

  const GameOverDialog({
    super.key,
    required this.score,
    required this.coins,
    required this.isNewHigh,
    required this.onRestart,
    required this.onHome,
  });

  @override
  State<GameOverDialog> createState() => _GameOverDialogState();
}

class _GameOverDialogState extends State<GameOverDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  final AuthService _authService = AuthService();
  late LeaderboardService _leaderboardService;
  final _nameController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _leaderboardService = LeaderboardService(_authService);
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // Pre-fill name if signed in
    if (_authService.isSignedIn) {
      _authService.getUserProfile().then((profile) {
        if (profile != null && mounted) {
          _nameController.text = profile['name'] ?? '';
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitToLeaderboard() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    await _leaderboardService.submitScore(widget.score, _nameController.text.trim());

    if (mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Score submitted to leaderboard!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A237E), Color(0xFF0D47A1), Color(0xFF01579B)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Game Over Title
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: const Text(
                      'GAME OVER',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        letterSpacing: 3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // New High Score Badge
                  if (widget.isNewHigh) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.emoji_events, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'NEW HIGH SCORE!',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Score Display
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'SCORE',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.score}',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.stars, color: Colors.amber, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              '+${widget.coins} COINS',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Leaderboard Submission
                  if (_authService.isSignedIn) ...[
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Your Name',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white30),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitToLeaderboard,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.leaderboard),
                        label: Text(_isSubmitting ? 'Submitting...' : 'Submit to Leaderboard'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _GameBtn(
                        icon: Icons.home_rounded,
                        label: 'Home',
                        color: Colors.blueGrey,
                        onTap: widget.onHome,
                      ),
                      _GameBtn(
                        icon: Icons.replay_rounded,
                        label: 'Retry',
                        color: Colors.green,
                        onTap: widget.onRestart,
                        isLarge: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GameBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isLarge;

  const _GameBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isLarge ? 18 : 14),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: isLarge ? 36 : 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Removed redundant painters, moved to painters.dart
