import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:speechmate/widgets/background.dart';

class AuthScreen extends StatefulWidget {
  final Widget nextScreen;
  const AuthScreen({super.key, required this.nextScreen});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      // Correct v7.x API: Use authenticate() instead of signIn()
      // Note: In some versions it might be signIn() on the instance, but let's try the singleton pattern.
      // Actually, if it says "no unnamed constructor", it's likely static.
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
      
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; // User canceled
      }

      final auth = googleUser.authentication;
      final clientAuth = await googleUser.authorizationClient.authorizeScopes(['email', 'profile']);

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: clientAuth.accessToken,
        idToken: auth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => widget.nextScreen));
      }
    } catch (e) {
      debugPrint("Error signing in with Google: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to sign in: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInAnonymously() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInAnonymously();
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => widget.nextScreen));
      }
    } catch (e) {
      debugPrint("Error signing in anonymously: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to sign in anonymously: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Background(
        colors: const [Color(0xFF89f7fe), Color(0xFF66a6ff)],
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.language, size: 100, color: Colors.white),
                  const SizedBox(height: 24),
                  const Text(
                    "Welcome to SpeechMate",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Sign in to save your progress, contribute to the community, and master Nicobarese across all your devices.",
                    style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  
                  if (_isLoading)
                    const CircularProgressIndicator(color: Colors.white)
                  else ...[
                    ElevatedButton.icon(
                      onPressed: _signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      icon: Image.asset('assets/icons/logo_main.png', height: 24, errorBuilder: (context, error, stackTrace) => const Icon(Icons.login)), // Fallback if logo not found
                      label: const Text("Continue with Google", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _signInAnonymously,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text("Skip & Play as Guest", style: TextStyle(fontSize: 16, decoration: TextDecoration.underline)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
