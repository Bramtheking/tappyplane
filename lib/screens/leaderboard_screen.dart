import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/leaderboard_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  late LeaderboardService _leaderboardService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _leaderboardService = LeaderboardService(_authService);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1B4B), Color(0xFF1565C0), Color(0xFF42A5F5)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'LEADERBOARD',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.amber,
                labelColor: Colors.amber,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'GLOBAL'),
                  Tab(text: 'MY BEST'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGlobalLeaderboard(),
                    _buildPersonalBest(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalLeaderboard() {
    return StreamBuilder<List<LeaderboardEntry>>(
      stream: _leaderboardService.getTopScores(limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No scores yet!\nBe the first to submit.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          );
        }

        final entries = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return _buildLeaderboardTile(entry, index + 1);
          },
        );
      },
    );
  }

  Widget _buildPersonalBest() {
    if (!_authService.isSignedIn) {
      return const Center(
        child: Text(
          'Sign in to track your scores',
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
      );
    }

    return StreamBuilder<List<LeaderboardEntry>>(
      stream: _leaderboardService.getPersonalBest(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No scores submitted yet',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          );
        }

        final entries = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return _buildLeaderboardTile(entry, index + 1, isPersonal: true);
          },
        );
      },
    );
  }

  Widget _buildLeaderboardTile(LeaderboardEntry entry, int rank, {bool isPersonal = false}) {
    Color rankColor = Colors.white;
    IconData? medal;

    if (!isPersonal) {
      if (rank == 1) {
        rankColor = const Color(0xFFFFD700);
        medal = Icons.emoji_events;
      } else if (rank == 2) {
        rankColor = const Color(0xFFC0C0C0);
        medal = Icons.emoji_events;
      } else if (rank == 3) {
        rankColor = const Color(0xFFCD7F32);
        medal = Icons.emoji_events;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rank <= 3 && !isPersonal ? rankColor : Colors.white24,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: medal != null
                ? Icon(medal, color: rankColor, size: 32)
                : Text(
                    '#$rank',
                    style: TextStyle(
                      color: rankColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              entry.playerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${entry.score}',
            style: TextStyle(
              color: rankColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
