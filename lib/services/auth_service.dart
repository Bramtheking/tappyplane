import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const List<String> adminEmails = [
    'cgichuru47@gmail.com',
    'bramwela8@gmail.com',
  ];

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => _auth.currentUser != null;
  bool get isAdmin => adminEmails.contains(_auth.currentUser?.email);

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      // Create user profile if first time
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserProfile(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  Future<void> _createUserProfile(User user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'displayName': user.displayName ?? '',
      'photoURL': user.photoURL ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'name': '',
      'age': 0,
      'highScore': 0,
      'totalCoins': 0,
      'unlockedCharacters': ['airplane'],
      'unlockedAreas': ['classic'],
      'isAdmin': adminEmails.contains(user.email),
    });
  }

  Future<void> updateUserProfile({String? name, int? age}) async {
    if (!isSignedIn) return;
    
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (age != null) updates['age'] = age;
    
    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(currentUser!.uid).update(updates);
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    if (!isSignedIn) return null;
    
    final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
    return doc.data();
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
