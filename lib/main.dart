import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speechmate/screens/app_language_select.dart';
import 'package:speechmate/screens/languages.dart';
import 'package:flutter/services.dart';
import 'package:speechmate/screens/emotional_splash_screen.dart';
import 'package:speechmate/core/app_theme.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:speechmate/features/gamification/gamification_service.dart';
import 'package:speechmate/services/database_manager.dart';

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

  try {
      await GamificationService.initialize();
  } catch (e) {
      debugPrint("Gamification init failed: $e");
  }

  try {
      await DatabaseManager.instance.database;
      await DatabaseManager.instance.seedExtraFromJson('phrases', 'assets/data/dictionary_phrases.json', (item) => {
        'english': item['english']?.toString() ?? '',
        'nicobarese': item['nicobarese']?.toString() ?? '',
        'text': item['text']?.toString() ?? '',
      });
      await DatabaseManager.instance.seedExtraFromJson('dialects', 'assets/data/dictionary_dialects.json', (item) => {
        'english': item['english']?.toString() ?? '',
        'car': item['car']?.toString() ?? '',
        'central': item['central']?.toString() ?? '',
        'coast': item['coast']?.toString() ?? '',
        'teressa': item['teressa']?.toString() ?? '',
        'chowra': item['chowra']?.toString() ?? '',
      });
  } catch (e) {
      debugPrint("Database init failed: $e");
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

    Widget targetScreen = internalScreen;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SpeechMate - Nicobarese Language Learning',
      theme: isTeacher ? AppTheme.teacherTheme : AppTheme.studentTheme,
      home: hasSeenSplash ? targetScreen : EmotionalSplashScreen(nextScreen: targetScreen),
    );
  }
}
