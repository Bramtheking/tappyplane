import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  bool _isLoading = false;
  bool _needsProfile = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    
    final result = await _authService.signInWithGoogle();
    
    if (result != null && mounted) {
      final profile = await _authService.getUserProfile();
      
      if (profile?['name'] == '' || profile?['age'] == 0) {
        setState(() {
          _needsProfile = true;
          _isLoading = false;
        });
      } else {
        Navigator.of(context).pop(true);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    final age = int.tryParse(_ageController.text);
    if (age == null || age < 1 || age > 120) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid age')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    await _authService.updateUserProfile(
      name: _nameController.text.trim(),
      age: age,
    );

    if (mounted) {
      Navigator.of(context).pop(true);
    }
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _needsProfile ? _buildProfileForm() : _buildSignInForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.flight_takeoff, size: 80, color: Colors.white),
        const SizedBox(height: 20),
        const Text(
          'TAPPY PLANE',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Sign in to save your progress\nand compete on the leaderboard',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 40),
        _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : ElevatedButton.icon(
                onPressed: _signInWithGoogle,
                icon: Image.asset('assets/google_logo.png', height: 24, errorBuilder: (_, __, ___) => const Icon(Icons.login)),
                label: const Text('Sign in with Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Skip for now', style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }

  Widget _buildProfileForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Complete Your Profile',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 30),
        TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Your Name',
            labelStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white30),
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _ageController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Your Age',
            labelStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white30),
            ),
          ),
        ),
        const SizedBox(height: 30),
        _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Continue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
      ],
    );
  }
}
