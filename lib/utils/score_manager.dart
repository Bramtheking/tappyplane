import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScoreManager {
  static const String _scoreKey = 'high_score';
  static const String _coinsKey = 'total_coins';
  static const String _unlockedKey = 'unlocked_characters';
  static const String _selectedCharKey = 'selected_character';
  static const String _unlockedAreaKey = 'unlocked_areas';
  static const String _selectedAreaKey = 'selected_area';

  static const List<String> adminEmails = [
    'cgichuru47@gmail.com',
    'bramwela8@gmail.com',
  ];

  static bool get isAdmin {
    final email = FirebaseAuth.instance.currentUser?.email;
    return email != null && adminEmails.contains(email);
  }

  static Future<int> getHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_scoreKey) ?? 0;
  }

  static Future<bool> saveScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_scoreKey) ?? 0;
    if (score > current) {
      await prefs.setInt(_scoreKey, score);
      
      // Sync to Firebase if signed in
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'highScore': score});
        } catch (e) {
          print('Error syncing score: $e');
        }
      }
      
      return true;
    }
    return false;
  }

  static Future<int> getCoins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_coinsKey) ?? 0;
  }

  static Future<void> addCoins(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_coinsKey) ?? 0;
    await prefs.setInt(_coinsKey, current + amount);
  }

  static Future<void> spendCoins(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_coinsKey) ?? 0;
    if (current >= amount) {
      await prefs.setInt(_coinsKey, current - amount);
    }
  }

  static Future<List<String>> getUnlockedCharacters() async {
    // Admins get everything
    if (isAdmin) {
      return ['airplane', 'fish', 'rocket', 'heli', 'ufo'];
    }
    
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_unlockedKey) ?? ['airplane'];
  }

  static Future<void> unlockCharacter(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_unlockedKey) ?? ['airplane'];
    if (!current.contains(id)) {
      current.add(id);
      await prefs.setStringList(_unlockedKey, current);
    }
  }

  static Future<String> getSelectedCharacter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedCharKey) ?? 'airplane';
  }

  static Future<void> setSelectedCharacter(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedCharKey, id);
  }

  static Future<List<String>> getUnlockedAreas() async {
    // Admins get everything
    if (isAdmin) {
      return ['classic', 'night', 'desert', 'synthwave'];
    }
    
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_unlockedAreaKey) ?? ['classic'];
  }

  static Future<void> unlockArea(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_unlockedAreaKey) ?? ['classic'];
    if (!current.contains(id)) {
      current.add(id);
      await prefs.setStringList(_unlockedAreaKey, current);
    }
  }

  static Future<String> getSelectedArea() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedAreaKey) ?? 'classic';
  }

  static Future<void> setSelectedArea(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedAreaKey, id);
  }
}

