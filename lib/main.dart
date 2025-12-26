import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speechmate/screens/app_language_select.dart';
import 'package:speechmate/screens/languages.dart';
import 'package:flutter/services.dart';
import 'package:speechmate/screens/emotional_splash_screen.dart';
import 'package:speechmate/widgets/instant_popup_transition.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final languageSelected = prefs.getBool('language_selected') ?? false;

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(MyApp(languageSelected: languageSelected));
}

class MyApp extends StatelessWidget {
  final bool languageSelected;

  const MyApp({super.key, required this.languageSelected});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {TargetPlatform.android: NoTransition()},
        ),
      ),
      home: EmotionalSplashScreen(
        nextScreen: languageSelected
            ? const Languages()
            : const LanguageSelectionScreen(),
      ),
    );
  }
}
