import 'package:flutter/material.dart';
import '../utils/score_manager.dart';
import '../game/game_screen.dart';
import '../game/painters.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';
import 'leaderboard_screen.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _planeController;
  late AnimationController _pulseController;
  late Animation<double> _pulse;
  int _highScore = 0;
  int _totalCoins = 0;
  String _selectedChar = 'airplane';
  List<String> _unlockedChars = ['airplane', 'fish', 'rocket', 'heli', 'ufo'];
  String _selectedArea = 'classic';
  List<String> _unlockedAreas = ['classic', 'night', 'desert', 'synthwave'];
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _refreshData();

    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat();
    _planeController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

    _pulse = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _refreshData() async {
    final s = await ScoreManager.getHighScore();
    final c = await ScoreManager.getCoins();
    final char = await ScoreManager.getSelectedCharacter();
    final area = await ScoreManager.getSelectedArea();
    final unlockedC = await ScoreManager.getUnlockedCharacters();
    final unlockedA = await ScoreManager.getUnlockedAreas();
    if (mounted) {
      setState(() {
        _highScore = s;
        _totalCoins = c;
        _selectedChar = char;
        _unlockedChars = unlockedC;
        _selectedArea = area;
        _unlockedAreas = unlockedA;
      });
    }
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
    ).then((_) => _refreshData());
  }

  void _selectChar(String id, int price) async {
    if (_unlockedChars.contains(id)) {
      await ScoreManager.setSelectedCharacter(id);
      setState(() => _selectedChar = id);
    } else if (_totalCoins >= price) {
      await ScoreManager.spendCoins(price);
      await ScoreManager.unlockCharacter(id);
      await ScoreManager.setSelectedCharacter(id);
      _refreshData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough coins!')));
    }
  }

  void _selectArea(String id, int price) async {
    if (_unlockedAreas.contains(id)) {
      await ScoreManager.setSelectedArea(id);
      setState(() => _selectedArea = id);
    } else if (_totalCoins >= price) {
      await ScoreManager.spendCoins(price);
      await ScoreManager.unlockArea(id);
      await ScoreManager.setSelectedArea(id);
      _refreshData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough coins!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          // Background
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) => CustomPaint(
              painter: _HomeBgPainter(_bgController.value, _selectedArea),
              size: size,
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Coin display
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Auth button
                      GestureDetector(
                        onTap: () async {
                          if (_authService.isSignedIn) {
                            await _authService.signOut();
                            _refreshData();
                          } else {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AuthScreen()),
                            );
                            if (result == true) _refreshData();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _authService.isSignedIn ? Icons.logout : Icons.login,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _authService.isSignedIn ? 'Sign Out' : 'Sign In',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Leaderboard button
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.leaderboard, color: Colors.amber, size: 20),
                              SizedBox(width: 6),
                              Text('Board', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      // Coins
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.stars, color: Colors.amber, size: 24),
                            const SizedBox(width: 8),
                            Text('$_totalCoins', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Title
                const SizedBox(height: 20),
                ShaderMask(
                  shaderCallback: (r) => const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]).createShader(r),
                  child: const Text('TAPPY', style: TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 8)),
                ),
                ShaderMask(
                  shaderCallback: (r) => const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF1565C0)]).createShader(r),
                  child: const Text('PLANE ✈', style: TextStyle(fontSize: 54, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 6)),
                ),

                const Spacer(),

                const Text('CHOOSE CHARACTER', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _charSelector('airplane', const PlanePainter(), 0),
                      const SizedBox(width: 15),
                      _charSelector('fish', const FishPainter(), 0),
                      const SizedBox(width: 15),
                      _charSelector('rocket', const RocketPainter(), 100),
                      const SizedBox(width: 15),
                      _charSelector('heli', const HeliPainter(), 150),
                      const SizedBox(width: 15),
                      _charSelector('ufo', const UfoPainter(), 200),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const Text('CHOOSE AREA', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _areaSelector('classic', 'Classic Sky', 0),
                      const SizedBox(width: 15),
                      _areaSelector('night', 'Night Sky', 50),
                      const SizedBox(width: 15),
                      _areaSelector('desert', 'Desert Oasis', 100),
                      const SizedBox(width: 15),
                      _areaSelector('synthwave', 'Synthwave', 200),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Play Button
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) => Transform.scale(
                    scale: _pulse.value,
                    child: GestureDetector(
                      onTap: _play,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFFF6F00), Color(0xFFFF9800)]),
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [BoxShadow(color: const Color(0xFFFF9800).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: const Text('FLY NOW!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                if (_highScore > 0)
                  Text('BEST: $_highScore', style: const TextStyle(color: Colors.white70, fontSize: 20, fontWeight: FontWeight.bold)),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _charSelector(String id, CustomPainter painter, int price) {
    bool isSelected = _selectedChar == id;
    bool isUnlocked = _unlockedChars.contains(id);

    return GestureDetector(
      onTap: () => _selectChar(id, price),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white.withOpacity(0.2) : Colors.black45,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? Colors.amber : (isUnlocked ? Colors.white24 : Colors.red.withOpacity(0.5)), width: 3),
            ),
            child: CustomPaint(
              painter: painter,
              size: const Size(60, 30),
            ),
          ),
          const SizedBox(height: 5),
          if (!isUnlocked)
            Row(
              children: [
                const Icon(Icons.stars, color: Colors.amber, size: 14),
                const SizedBox(width: 4),
                Text('$price', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            )
          else if (isSelected)
            const Text('SELECTED', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold))
          else
            const Text('OWNED', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _areaSelector(String id, String name, int price) {
    bool isSelected = _selectedArea == id;
    bool isUnlocked = _unlockedAreas.contains(id);

    return GestureDetector(
      onTap: () => _selectArea(id, price),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: id == 'classic' ? [const Color(0xFF1565C0), const Color(0xFF42A5F5)] :
                        id == 'night' ? [const Color(0xFF1A237E), const Color(0xFF311B92)] :
                        id == 'desert' ? [const Color(0xFFBF360C), const Color(0xFFE64A19)] :
                        [const Color(0xFF880E4F), const Color(0xFF4A148C)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? Colors.amber : (isUnlocked ? Colors.white24 : Colors.red.withOpacity(0.5)), width: 3),
            ),
            child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 5),
          if (!isUnlocked)
            Row(
              children: [
                const Icon(Icons.stars, color: Colors.amber, size: 14),
                const SizedBox(width: 4),
                Text('$price', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            )
          else if (isSelected)
            const Text('SELECTED', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold))
          else
            const Text('OWNED', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ── Background painter ─────────────────────────────────
class _HomeBgPainter extends CustomPainter {
  final double t;
  final String area;
  _HomeBgPainter(this.t, this.area);

  @override
  void paint(Canvas canvas, Size size) {
    // Sky gradient
    List<Color> skyColors;
    if (area == 'night') {
      skyColors = [const Color(0xFF090E27), const Color(0xFF1A237E), const Color(0xFF311B92), const Color(0xFF5E35B1)];
    } else if (area == 'desert') {
      skyColors = [const Color(0xFFBF360C), const Color(0xFFD84315), const Color(0xFFE64A19), const Color(0xFFFFCC80)];
    } else if (area == 'synthwave') {
      skyColors = [const Color(0xFF120024), const Color(0xFF4A148C), const Color(0xFF880E4F), const Color(0xFFF50057)];
    } else {
      skyColors = [const Color(0xFF0D1B4B), const Color(0xFF1565C0), const Color(0xFF42A5F5), const Color(0xFF80DEEA)];
    }

    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: skyColors,
        stops: const [0.0, 0.35, 0.7, 1.0],
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
    List<Color> groundColors;
    if (area == 'desert') {
      groundColors = [const Color(0xFFD84315), const Color(0xFFBF360C)];
    } else if (area == 'synthwave') {
      groundColors = [const Color(0xFF880E4F), const Color(0xFF4A148C)];
    } else {
      groundColors = [const Color(0xFF388E3C), const Color(0xFF1B5E20)];
    }

    final groundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: groundColors,
      ).createShader(Rect.fromLTWH(0, groundY, size.width, size.height - groundY));
    canvas.drawRect(Rect.fromLTWH(0, groundY, size.width, size.height - groundY), groundPaint);

    // Ground top edge highlight
    canvas.drawLine(Offset(0, groundY), Offset(size.width, groundY),
      Paint()
        ..color = area == 'synthwave' ? const Color(0xFFF50057) : (area == 'desert' ? const Color(0xFFFFCC80) : const Color(0xFF66BB6A))
        ..strokeWidth = 3);
  }

  void _drawCloud(Canvas canvas, Size size, Offset pos, double w) {
    final h = w * 0.4;
    final p = Paint()..color = Colors.white.withOpacity(0.85);
    canvas.drawOval(Rect.fromCenter(center: Offset(pos.dx + w * 0.5, pos.dy + h * 0.6), width: w, height: h), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(pos.dx + w * 0.35, pos.dy + h * 0.35), width: w * 0.6, height: h * 0.7), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(pos.dx + w * 0.65, pos.dy + h * 0.4), width: w * 0.5, height: h * 0.65), p);
  }

  @override
  bool shouldRepaint(_HomeBgPainter old) => old.t != t || old.area != area;
}

// PlanePainter removed, using the one from painters.dart
