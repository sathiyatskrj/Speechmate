import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speechmate/screens/app_language_select.dart';
import 'package:speechmate/screens/languages.dart';
import 'package:flutter/services.dart';
import 'package:speechmate/screens/emotional_splash_screen.dart';
import 'package:speechmate/core/app_theme.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speechmate/screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Global error handler to catch unhandled Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  try {
      await Firebase.initializeApp();
      // Enable Firestore offline persistence
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
  } catch (e) {
      // If firebase fails (e.g. no google-services.json), we don't want to crash the whole app startup
      debugPrint("Firebase init failed: $e");
  }

  final prefs = await SharedPreferences.getInstance();
  final languageSelected = prefs.getBool('language_selected') ?? false;
  final isTeacher = prefs.getBool('is_teacher') ?? false;
  final hasSeenSplash = prefs.getBool('has_seen_splash') ?? false;

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(MyApp(
    languageSelected: languageSelected, 
    isTeacher: isTeacher,
    hasSeenSplash: hasSeenSplash,
  ));
}

class MyApp extends StatelessWidget {
  final bool languageSelected;
  final bool isTeacher;
  final bool hasSeenSplash;

  const MyApp({
    super.key, 
    required this.languageSelected, 
    this.isTeacher = false,
    this.hasSeenSplash = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget internalScreen = languageSelected
            ? const Languages()
            : const LanguageSelectionScreen();

    // Avoid using FirebaseAuth if initialization failed.
    Widget targetScreen = internalScreen;
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        targetScreen = AuthScreen(nextScreen: internalScreen);
      }
    } catch (_) {}

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SpeechMate - Nicobarese Language Learning',
      theme: isTeacher ? AppTheme.teacherTheme : AppTheme.studentTheme,
      home: hasSeenSplash ? targetScreen : EmotionalSplashScreen(nextScreen: targetScreen),
    );
  }
}
