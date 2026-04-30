/// Application configuration for build modes and feature flags.
///
/// Controls which features are visible in the app.
/// Use `--dart-define` flags at build time to override defaults:
///   flutter build apk --dart-define=LEAN_MODE=true --dart-define=DEV_MODE=false
class AppConfig {
  AppConfig._();

  /// When true, hides experimental/secondary screens from the student dashboard.
  /// Only shows core learning features: Word Categories, Games, AR Scanner.
  /// Set to false to reveal all features (Community, AI Setup, Beta Chat, etc.)
  static const bool devMode = bool.fromEnvironment('DEV_MODE', defaultValue: false);

  /// When true, builds a lightweight APK (<50MB) without Whisper or heavy NLP.
  /// Suitable for low-end Android devices (2GB RAM, Android 8+).
  /// When false, includes full Whisper STT + Neural Engine pipeline.
  static const bool isLeanMode = bool.fromEnvironment('LEAN_MODE', defaultValue: true);

  /// Whether the Whisper speech-to-text engine is available.
  static const bool hasWhisper = !isLeanMode;

  /// Maximum APK target size in MB for lean mode.
  static const int leanTargetSizeMB = 50;

  /// Screens hidden from the student dashboard unless devMode is true.
  static const List<String> devOnlyScreenKeys = [
    'community',
    'aiSetup',
    'betaChat',
    'voiceVault',
    'dialectHeatmap',
    'memoryPalace',
  ];
}
