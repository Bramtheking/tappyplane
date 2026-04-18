import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

class LeaderboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService;

  LeaderboardService(this._authService);

  Future<void> submitScore(int score, String playerName) async {
    if (!_authService.isSignedIn) return;

    final user = _authService.currentUser!;
    
    // Update user's high score
    final userDoc = _firestore.collection('users').doc(user.uid);
    final userData = await userDoc.get();
    final currentHigh = userData.data()?['highScore'] ?? 0;
    
    if (score > currentHigh) {
      await userDoc.update({'highScore': score});
    }

    // Add to leaderboard
    await _firestore.collection('leaderboard').add({
      'userId': user.uid,
      'playerName': playerName,
      'email': user.email,
      'score': score,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<LeaderboardEntry>> getTopScores({int limit = 50}) {
    return _firestore
        .collection('leaderboard')
        .orderBy('score', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return LeaderboardEntry(
          playerName: data['playerName'] ?? 'Anonymous',
          score: data['score'] ?? 0,
          timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
        );
      }).toList();
    });
  }

  Stream<List<LeaderboardEntry>> getPersonalBest() {
    if (!_authService.isSignedIn) {
      return Stream.value([]);
    }

    return _firestore
        .collection('leaderboard')
        .where('userId', isEqualTo: _authService.currentUser!.uid)
        .orderBy('score', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return LeaderboardEntry(
          playerName: data['playerName'] ?? 'You',
          score: data['score'] ?? 0,
          timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
        );
      }).toList();
    });
  }
}

class LeaderboardEntry {
  final String playerName;
  final int score;
  final DateTime? timestamp;

  LeaderboardEntry({
    required this.playerName,
    required this.score,
    this.timestamp,
  });
}
