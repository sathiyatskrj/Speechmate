import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speechmate/screens/emotional_splash_screen.dart';
import 'package:speechmate/screens/app_language_select.dart';
import 'package:speechmate/screens/onboarding_screen.dart';
import 'package:speechmate/screens/asset_download_screen.dart';
import 'package:speechmate/core/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:speechmate/services/database_manager.dart';
import 'package:speechmate/core/app_strings.dart';
import 'package:speechmate/services/crash_reporter.dart';
import 'package:speechmate/services/analytics_service.dart';
import 'package:speechmate/services/notification_service.dart';
import 'package:speechmate/services/sound_service.dart';
import 'package:speechmate/services/delta_update_service.dart';
import 'package:path_provider/path_provider.dart';

/// Current data version — bump this when lexicon files change
/// so the DB re-seeds on upgrade instead of every cold start.
const String _dataVersion = '1.4.9';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Global error handler to catch unhandled Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    CrashReporter.log(details.exceptionAsString(), stack: details.stack);
  };

  // Catch errors outside the Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformError: $error');
    CrashReporter.log('$error', stack: stack);
    return true;
  };

  // Init crash reporter
  try {
    final dir = await getApplicationSupportDirectory();
    await CrashReporter.init(dir.path);
  } catch (_) {}

  // Init offline analytics
  try {
    await AnalyticsService.instance.init();
    await AnalyticsService.instance.trackEvent('app_open');
  } catch (_) {}

  // Init offline push notifications (Feature 3)
  try {
    final notif = NotificationService();
    await notif.init();
  } catch (e) {
    debugPrint('[main] Offline notification init failed: $e');
  }

  // Init Pavlovian sound cues (xylophone dings, chimes, etc.)
  try {
    await SoundService.instance.init();
  } catch (e) {
    debugPrint('[main] Sound service init failed: $e');
  }

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

  // P1-05: Version-hash seed check — only re-seed when data version changes
  final prefs = await SharedPreferences.getInstance();
  final lastSeedVersion = prefs.getString('last_seed_version') ?? '';
  final needsSeed = lastSeedVersion != _dataVersion;

  // Database initialization
  try {
      await DatabaseManager.instance.database;

      if (needsSeed) {
        debugPrint('[main] Data version changed ($lastSeedVersion → $_dataVersion), re-seeding...');
        await DatabaseManager.instance.seedExtraFromJson('phrases', 'assets/data/dictionary_phrases.json', (item) {
          final audio = item['audio'];
          return {
            'english': item['english']?.toString() ?? '',
            'nicobarese': item['nicobarese']?.toString() ?? '',
            'text': item['text']?.toString() ?? '',
            'audio_category': audio is Map ? (audio['category']?.toString() ?? '') : '',
            'audio_file': audio is Map ? (audio['file']?.toString() ?? '') : '',
          };
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

        await prefs.setString('last_seed_version', _dataVersion);
        debugPrint('[main] Seed complete for $_dataVersion.');
      } else {
        debugPrint('[main] Data already seeded for $_dataVersion, skipping.');
      }
      
      // Auto-check and apply delta updates on app launch (Feature 8)
      try {
        await DeltaUpdateService.checkAndApplyUpdates();
      } catch (e) {
        debugPrint('[main] Delta updates check failed: $e');
      }
  } catch (e) {
      debugPrint("Database init failed: $e");
  }

  await AppStrings.load();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Check if user has seen onboarding
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

  runApp(ProviderScope(
    child: MyApp(showOnboarding: !hasSeenOnboarding),
  ));
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;
  const MyApp({super.key, this.showOnboarding = false});

  @override
  Widget build(BuildContext context) {
    // Route: Splash → Onboarding (first time) → Asset Download → Language Selection
    final Widget destination = showOnboarding
        ? const OnboardingScreen(nextScreen: AssetDownloadScreen(nextScreen: LanguageSelectionScreen()))
        : const AssetDownloadScreen(nextScreen: LanguageSelectionScreen());

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
      home: EmotionalSplashScreen(nextScreen: destination),
    );
  }
}
