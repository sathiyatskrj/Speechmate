import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  /// 🔊 Play from asset path string
  Future<void> playAsset(String assetPath) async {
    await _player.stop();

    // Remove "assets/" because AssetSource assumes assets/
    final cleanPath = assetPath.replaceFirst('assets/', '');

    await _player.play(AssetSource(cleanPath));
  }

  /// 🔊 Play audio from JSON
  /// Supports:
  /// "audio": "assets/audio/numbers/one.mp3"
  Future<void> playFromJson(dynamic audio) async {
    if (audio == null) return;

    if (audio is String) {
      await playAsset(audio);
    }
  }
}
