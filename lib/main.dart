import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speechmate/screens/emotional_splash_screen.dart';
import 'package:speechmate/screens/app_language_select.dart';
import 'package:speechmate/screens/landing_page.dart';
import 'package:speechmate/core/app_theme.dart';

import 'package:speechmate/services/database_manager.dart';
import 'package:speechmate/core/app_strings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Global error handler to catch unhandled Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  // Catch errors outside the Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformError: $error');
    return true;
  };

  // Global fallback UI for widget build errors
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              const Text("Something went wrong.", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                details.exceptionAsString(),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  };

  // NOTE: Firebase removed for pre-demo offline mode.
  // Will be re-enabled post-proposal with proper authentication.
  // try {
  //     await Firebase.initializeApp();
  //     FirebaseFirestore.instance.settings = const Settings(
  //       persistenceEnabled: true,
  //       cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  //     );
  // } catch (e) {
  //     debugPrint("Firebase init failed: $e");
  // }

  // Database initialization
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
      await DatabaseManager.instance.seedExtraFromJson('ga_dictionary', 'assets/data/dictionary_great_andamanese.json', (item) => {
        'english': item['english']?.toString() ?? '',
        'great_andamanese': item['great_andamanese']?.toString() ?? '',
        'pos': item['pos']?.toString() ?? '',
        'audio': item['audio']?.toString() ?? '',
      });
      await DatabaseManager.instance.seedExtraFromJson('ga_phrases', 'assets/data/phrases_great_andamanese.json', (item) => {
        'english': item['english']?.toString() ?? '',
        'great_andamanese': item['great_andamanese']?.toString() ?? '',
        'audio': item['audio']?.toString() ?? '',
      });
      
      // Seed ALL category word data from JSON files
      final categoryJsonFiles = {
        'words': 'assets/data/dictionary.json',
        'animals': 'assets/data/dictionary_animals.json',
        'family': 'assets/data/dictionary_family.json',
        'magic': 'assets/data/dictionary_magic.json',
        'body_parts': 'assets/data/dictionary_body_parts.json',
        'numbers': 'assets/data/dictionary_numbers.json',
        'nature': 'assets/data/dictionary_nature.json',
        'colors': 'assets/data/dictionary_colors.json',
        'things': 'assets/data/dictionary_things.json',
        'feelings': 'assets/data/dictionary_feelings.json',
      };
      for (final entry in categoryJsonFiles.entries) {
        await DatabaseManager.instance.seedCategoryFromJson(entry.key, entry.value);
      }
  } catch (e) {
      debugPrint("Database init failed: $e");
  }

  await AppStrings.load();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const ProviderScope(
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SpeechMate - Nicobarese Language Learning',
      theme: AppTheme.studentTheme,
      builder: (context, child) {
        // Prevent system text scaling from breaking UI layout on various phones
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child!,
        );
      },
      home: const EmotionalSplashScreen(nextScreen: LanguageSelectionScreen()),
    );
  }
}
