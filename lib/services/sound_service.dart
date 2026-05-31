import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// SOUND SERVICE — Pavlovian Audio Cue Engine
// Zero-latency singleton with pre-pooled AudioPlayer instances.
// Uses existing audioplayers dependency. No new packages required.
//
// Usage:
//   await SoundService.instance.init();
//   SoundService.instance.play(SoundCue.xpGain);
// ============================================================================

/// All available sound cues in the app.
enum SoundCue {
  xpGain,          // Bright xylophone ascending two-note
  streakIncrement, // Warm chime with slight reverb
  levelUp,         // Triumphant 3-note fanfare
  correctAnswer,   // Single bright "ding"
  wrongAnswer,     // Soft descending two-tone
  feedPet,         // Playful chomp/pop
  buttonTap,       // Soft haptic click
  achievement,     // Sparkle cascade
}

class SoundService {
  // ── Singleton ──
  static final SoundService _instance = SoundService._internal();
  static SoundService get instance => _instance;
  SoundService._internal();

  bool _initialized = false;
  bool _muted = false;

  static const String _keyMuted = 'sound_muted';

  // Pre-pooled players for zero-latency playback.
  // Each cue gets its own player so overlapping sounds don't cut each other.
  final Map<SoundCue, AudioPlayer> _players = {};

  // Asset paths (relative to assets/ — audioplayers uses AssetSource).
  static const Map<SoundCue, String> _assetPaths = {
    SoundCue.xpGain:          'sounds/xp_gain.mp3',
    SoundCue.streakIncrement: 'sounds/streak_increment.mp3',
    SoundCue.levelUp:         'sounds/level_up.mp3',
    SoundCue.correctAnswer:   'sounds/correct_answer.mp3',
    SoundCue.wrongAnswer:     'sounds/wrong_answer.mp3',
    SoundCue.feedPet:         'sounds/feed_pet.mp3',
    SoundCue.buttonTap:       'sounds/button_tap.mp3',
    SoundCue.achievement:     'sounds/achievement.mp3',
  };

  // Volume levels per cue (some should be quieter than others).
  static const Map<SoundCue, double> _volumes = {
    SoundCue.xpGain:          0.6,
    SoundCue.streakIncrement: 0.5,
    SoundCue.levelUp:         0.8,
    SoundCue.correctAnswer:   0.5,
    SoundCue.wrongAnswer:     0.3,
    SoundCue.feedPet:         0.5,
    SoundCue.buttonTap:       0.2,
    SoundCue.achievement:     0.7,
  };

  /// Whether sounds are currently muted.
  bool get isMuted => _muted;

  /// Initialize the sound service. Safe to call multiple times.
  /// Pre-loads all audio assets into player pools for instant playback.
  Future<void> init() async {
    if (_initialized) return;

    try {
      // Load mute preference
      final prefs = await SharedPreferences.getInstance();
      _muted = prefs.getBool(_keyMuted) ?? false;

      // Pre-create players for each cue
      for (final cue in SoundCue.values) {
        final player = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setVolume(_volumes[cue] ?? 0.5);

        // Pre-load the asset source so first play is instant
        try {
          await player.setSource(AssetSource(_assetPaths[cue]!));
        } catch (e) {
          debugPrint('[SoundService] Pre-load warning for ${cue.name}: $e');
        }

        _players[cue] = player;
      }

      _initialized = true;
      debugPrint('[SoundService] Initialized with ${_players.length} cues. Muted: $_muted');
    } catch (e) {
      debugPrint('[SoundService] Init error: $e');
    }
  }

  /// Play a sound cue. If muted or not initialized, this is a no-op.
  void play(SoundCue cue) {
    if (!_initialized || _muted) return;

    try {
      final player = _players[cue];
      if (player == null) return;

      // Stop any in-progress playback, seek to start, and play
      player.stop().then((_) {
        player.seek(Duration.zero).then((_) {
          player.resume();
        });
      });
    } catch (e) {
      debugPrint('[SoundService] Play error for ${cue.name}: $e');
    }
  }

  /// Toggle mute state. Persists to SharedPreferences.
  Future<void> toggleMute() async {
    _muted = !_muted;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyMuted, _muted);
      debugPrint('[SoundService] Muted: $_muted');
    } catch (e) {
      debugPrint('[SoundService] Mute toggle error: $e');
    }
  }

  /// Set mute state explicitly.
  Future<void> setMuted(bool value) async {
    _muted = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyMuted, value);
    } catch (e) {
      debugPrint('[SoundService] Set mute error: $e');
    }
  }

  /// Dispose all players. Call on app termination if needed.
  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
    _players.clear();
    _initialized = false;
  }
}
